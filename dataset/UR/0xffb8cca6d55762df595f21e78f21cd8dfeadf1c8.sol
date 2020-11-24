 

pragma solidity ^0.4.25;

 


 
contract AcceptsEIF {
    ProofofEIF public tokenContract;

    constructor(address _tokenContract) public {
        tokenContract = ProofofEIF(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}


contract ProofofEIF {

     

    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }
    
    modifier notGasbag() {
      require(tx.gasprice <= 200000000000);  
      _;
    }

    modifier notContract() {
      require (msg.sender == tx.origin);

      _;
    }
    
    
        
    modifier antiEarlyWhale {
        if (isPremine()) {  
          require(ambassadors_[msg.sender] && msg.value <= premineLimit);
         
          ambassadors_[msg.sender]=false;
        }
        else require (isStarted());
        _;
    }
    
    
    
     
     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }    
    
     
    mapping(address => bool) public administrators;
     
    mapping(address => bool) public ambassadors_;

     

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint timestamp,
        uint256 price
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event onReferralUse(
        address indexed referrer,
        uint8  indexed level,
        uint256 ethereumCollected,
        address indexed customerAddress,
        uint256 timestamp
    );



    string public name = "Proof of EIF";
    string public symbol = "EIF";
    uint8 constant public decimals = 18;
    uint8 constant internal entryFee_ = 15;
    
     
    uint8 constant internal startExitFee_ = 48;

     
    uint8 constant internal finalExitFee_ = 8;

     
    uint256 constant internal exitFeeFallDuration_ = 30 days;
    
     
    uint256 public startTime = 0;  
    mapping(address => uint256) internal bonusBalance_;
    uint256 public depositCount_;
    uint8 constant internal fundEIF_ = 5;  
    
     
    uint256 public maxEarlyStake = 2.5 ether;
    uint256 public whaleBalanceLimit = 75 ether;
    uint256 public premineLimit = 1 ether;
    uint256 public ambassadorCount = 1;
    
     
    address public PoEIF;
    
     
    address public giveEthFundAddress = 0x35027a992A3c232Dd7A350bb75004aD8567561B2;
    uint256 public totalEthFundRecieved;  
    uint256 public totalEthFundCollected;  
    
    
    uint8 constant internal maxReferralFee_ = 10;  
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2 ** 64;
    uint256 public stakingRequirement = 50e18;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    
     
    mapping(address => bool) public canAcceptTokens_;  

    mapping(address => address) public stickyRef;
    
     

   constructor () public {
     PoEIF = msg.sender;
      
     ambassadors_[PoEIF] = true;
     administrators[PoEIF] = true;
   }    
    

    function buy(address _referredBy) notGasbag antiEarlyWhale public payable {
        purchaseInternal(msg.value, _referredBy);
    }

    function() payable notGasbag antiEarlyWhale public {
        purchaseInternal(msg.value, 0x0);
    }
    
 
 
     function updateFundAddress(address _newAddress)
        onlyAdministrator()
        public
    {
        giveEthFundAddress = _newAddress;
    }
    
    function payFund() public {
        uint256 ethToPay = SafeMath.sub(totalEthFundCollected, totalEthFundRecieved);
        require(ethToPay > 0);
        totalEthFundRecieved = SafeMath.add(totalEthFundRecieved, ethToPay);
        if(!giveEthFundAddress.call.value(ethToPay)()) {
            revert();
        }
    }

  
    function donateDivs() payable public {
        require(msg.value > 10000 wei && tokenSupply_ > 0);

        uint256 _dividends = msg.value;
         
        profitPerShare_ += (_dividends * magnitude / tokenSupply_);
    } 

     
    function setStartTime(uint256 _startTime) onlyAdministrator public {
        if (address(this).balance < 10 ether ) {
            startTime = _startTime; 
             
            if (!isPremine()) {depositCount_ = 0; ambassadorCount = 1; ambassadors_[PoEIF] = true;}
        }
    }
    
     
    function isPremine() public view returns (bool) {
      return depositCount_ < ambassadorCount;
    }

     
    function isStarted() public view returns (bool) {
      return startTime!=0 && now > startTime;
    }    

    function reinvest() onlyStronghands public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyStronghands public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyBagholders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundEIF_), 100);
         
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);

         
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
         
        address _customerAddress = msg.sender;

         
         
         
        require(!isPremine() && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if(myDividends(true) > 0) withdraw();

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);


         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }


  
    function transferAndCall(address _to, uint256 _value, bytes _data) external returns (bool) {
      require(_to != address(0));
      require(canAcceptTokens_[_to] == true);  
      require(transfer(_to, _value));  

      if (isContract(_to)) {
        AcceptsEIF receiver = AcceptsEIF(_to);
        require(receiver.tokenFallback(msg.sender, _value, _data));
      }

      return true;
    }

     
     function isContract(address _addr) private constant returns (bool is_contract) {
        
       uint length;
       assembly { length := extcodesize(_addr) }
       return length > 0;
     }

     
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }
    
      
    function setEarlyLimits(uint256 _whaleBalanceLimit, uint256 _maxEarlyStake, uint256 _premineLimit)
        onlyAdministrator()
        public
    {
        whaleBalanceLimit = _whaleBalanceLimit;
        maxEarlyStake = _maxEarlyStake;
        premineLimit = _premineLimit;
    }
    

     
    function setCanAcceptTokens(address _address, bool _value)
      onlyAdministrator()
      public
    {
      canAcceptTokens_[_address] = _value;
    }

     
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

     
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

   
  function addAmbassador(address addr) onlyAdministrator public returns(bool success) {
    if (!ambassadors_[addr] && isPremine()) {
      ambassadors_[addr] = true;
      ambassadorCount += 1;
      success = true;
    }
  }


   
  function removeAmbassador(address addr) onlyAdministrator public returns(bool success) {
    if (ambassadors_[addr]) {
      ambassadors_[addr] = false;
      ambassadorCount -= 1;
      success = true;
    }
  }
  
     
  function addAdministrator(address addr) onlyAdministrator public returns(bool success) {
    if (!administrators[addr]) {
      administrators[addr] = true;
      success = true;
    }
  }


   
  function removeAdministrator(address addr) onlyAdministrator public returns(bool success) {
    if (administrators[addr] && msg.sender==PoEIF) {
      administrators[addr] = false;
      success = true;
    }
  }


    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (uint256) {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundEIF_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
        }
    }

    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundEIF_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _fundPayout);

            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereumToSpend, fundEIF_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _fundPayout);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundEIF_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
        return _taxedEthereum;
    }

    function exitFee() public view returns (uint8) {
        if (startTime==0 || now < startTime){
           return startExitFee_;
        }
        
        uint256 secondsPassed = now - startTime;
        if (secondsPassed >= exitFeeFallDuration_) {
            return finalExitFee_;
        }
        uint8 totalChange = startExitFee_ - finalExitFee_;
        uint8 currentChange = uint8(totalChange * secondsPassed / exitFeeFallDuration_);
        uint8 currentFee = startExitFee_- currentChange;
        return currentFee;
    }
     

     
    function purchaseInternal(uint256 _incomingEthereum, address _referredBy)
      internal
      notContract()  
      returns(uint256) {

      uint256 purchaseEthereum = _incomingEthereum;
      uint256 excess;
      if(purchaseEthereum > maxEarlyStake ) {  
          if (SafeMath.sub(address(this).balance, purchaseEthereum) <= whaleBalanceLimit) {  
              purchaseEthereum = maxEarlyStake;
              excess = SafeMath.sub(_incomingEthereum, purchaseEthereum);
          }
      }
    
      if (excess > 0) {
        msg.sender.transfer(excess);
      }
    
      purchaseTokens(purchaseEthereum, _referredBy);
    }

    function handleReferrals(address _referredBy, uint _referralBonus, uint _undividedDividends) internal returns (uint){
        uint _dividends = _undividedDividends;
        address _level1Referrer = stickyRef[msg.sender];
        
        if (_level1Referrer == address(0x0)){
            _level1Referrer = _referredBy;
        }
         
        if(
             
            _level1Referrer != 0x0000000000000000000000000000000000000000 &&

             
            _level1Referrer != msg.sender &&

             
             
            tokenBalanceLedger_[_level1Referrer] >= stakingRequirement
        ){
             
            if (stickyRef[msg.sender] == address(0x0)){
                stickyRef[msg.sender] = _level1Referrer;
            }

             
            uint256 ethereumCollected =  _referralBonus/2;
            referralBalance_[_level1Referrer] = SafeMath.add(referralBalance_[_level1Referrer], ethereumCollected);
            _dividends = SafeMath.sub(_dividends, ethereumCollected);
            emit onReferralUse(_level1Referrer, 1, ethereumCollected, msg.sender, now);

            address _level2Referrer = stickyRef[_level1Referrer];

            if (_level2Referrer != address(0x0) && tokenBalanceLedger_[_level2Referrer] >= stakingRequirement){
                 
                ethereumCollected =  (_referralBonus*3)/10;
                referralBalance_[_level2Referrer] = SafeMath.add(referralBalance_[_level2Referrer], ethereumCollected);
                _dividends = SafeMath.sub(_dividends, ethereumCollected);
                emit onReferralUse(_level2Referrer, 2, ethereumCollected, _level1Referrer, now);
                address _level3Referrer = stickyRef[_level2Referrer];

                if (_level3Referrer != address(0x0) && tokenBalanceLedger_[_level3Referrer] >= stakingRequirement){
                     
                    ethereumCollected =  (_referralBonus*2)/10;
                    referralBalance_[_level3Referrer] = SafeMath.add(referralBalance_[_level3Referrer], ethereumCollected);
                    _dividends = SafeMath.sub(_dividends, ethereumCollected);
                    emit onReferralUse(_level3Referrer, 3, ethereumCollected, _level2Referrer, now);
                }
            }
        }
        return _dividends;
    }

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_incomingEthereum, maxReferralFee_), 100);
        uint256 _dividends = handleReferrals(_referredBy, _referralBonus, _undividedDividends);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, fundEIF_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends), _fundPayout);
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);
        
        
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());
         
        depositCount_++;
        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
            (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                (_tokenPriceInitial ** 2)
                                +
                                (2 * (tokenPriceIncremental_ * 1e18) * (_ethereum * 1e18))
                                +
                                ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
                                +
                                (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
                            )
                        ), _tokenPriceInitial
                    )
                ) / (tokenPriceIncremental_)
            ) - (tokenSupply_);

        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
            (
                SafeMath.sub(
                    (
                        (
                            (
                                tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                            ) - tokenPriceIncremental_
                        ) * (tokens_ - 1e18)
                    ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
                )
                / 1e18);

        return _etherReceived;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}