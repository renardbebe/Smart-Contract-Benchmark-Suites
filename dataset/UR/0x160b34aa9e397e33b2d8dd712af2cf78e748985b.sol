 

pragma solidity ^0.4.24;


contract apexPlatinum {

     

     
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }

     
    modifier notGasbag() {
      require(tx.gasprice < 200999999999);
      _;
    }

     
    modifier antiEarlyWhale {
        if (address(this).balance  -msg.value < whaleBalanceLimit){
          require(msg.value <= maxEarlyStake);
        }
        if (depositCount_ == 0){
          require(ambassadors_[msg.sender] && msg.value == 0.5 ether);
        }else
        if (depositCount_ < 6){
          require(ambassadors_[msg.sender] && msg.value == 0.3 ether);
        }else
        if (depositCount_ == 6 || depositCount_==7){
          require(ambassadors_[msg.sender] && msg.value == 0.51 ether);
        }
        _;
    }

     
    modifier isControlled() {
      require(isPremine() || isStarted());
      _;
    }

     

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


     

    string public name = "apex Platinum";
    string public symbol = "AXP";
    uint8 constant public decimals = 18;

     
    uint8 constant internal entryFee_ = 12;

     
    uint8 constant internal startExitFee_ = 48;

     
    uint8 constant internal finalExitFee_ = 12;

     
    uint256 constant internal exitFeeFallDuration_ = 7 days;

     
    uint8 constant internal refferalFee_ = 12;

     
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;

    uint256 constant internal magnitude = 2 ** 64;

     
    uint256 public stakingRequirement = 100e18;

     
    uint256 public maxEarlyStake = 2.5 ether;
    uint256 public whaleBalanceLimit = 75 ether;

     
    address public apex;

     
    uint256 public startTime = 0;  

    

     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => uint256) internal bonusBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public depositCount_;

    mapping(address => bool) internal ambassadors_;

     

   constructor () public {

      
     ambassadors_[msg.sender]=true;
      
     ambassadors_[0xAD171996c9B9d7a188133057b7Bd2563edd02b14]=true;
      
     ambassadors_[0x28B98FAEAe05Cb2cAcEc36d09Bdf3d19dD1F799e]=true;
      
     ambassadors_[0xD3FF623172d6B143C607d8771936E2c05DEEf9D0]=true;
      
     ambassadors_[0xB32435C63151527AFDdF82BE9Edd88f37f7413D3]=true;
      
     ambassadors_[0xab73e01ba3a8009d682726b752c11b1e9722f059]=true;
      
     ambassadors_[0x09cCd3b1d672aA8552CdD9807F5AEeFeAC1c21A9]=true;
      
     ambassadors_[0xc7F15d0238d207e19cce6bd6C0B85f343896F046]=true;

     apex = msg.sender;
   }

     

     
    function setStartTime(uint256 _startTime) public {
      require(msg.sender==apex && !isStarted() && now < _startTime);
      startTime = _startTime;
    }

     
    function buy(address _referredBy) antiEarlyWhale notGasbag isControlled public payable  returns (uint256) {
        purchaseTokens(msg.value, _referredBy , msg.sender);
    }

     
    function buyFor(address _referredBy, address _customerAddress) antiEarlyWhale notGasbag isControlled public payable returns (uint256) {
        purchaseTokens(msg.value, _referredBy , _customerAddress);
    }

     
    function() antiEarlyWhale notGasbag isControlled payable public {
        purchaseTokens(msg.value, 0x0 , msg.sender);
    }

     
    function reinvest() onlyStronghands public {
         
        uint256 _dividends = myDividends(false);  

         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        uint256 _tokens = purchaseTokens(_dividends, 0x0 , _customerAddress);

         
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
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

         
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

         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if (myDividends(true) > 0) {
            withdraw();
        }

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

         
        return true;
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
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

     
    function buyPrice() public view returns (uint256) {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

     
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

     
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }

     
    function calculateUntaxedEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
         
         
        return _ethereum;
    }


     
    function exitFee() public view returns (uint8) {
        if (startTime==0){
           return startExitFee_;
        }
        if ( now < startTime) {
          return 0;
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

     
    function isPremine() public view returns (bool) {
      return depositCount_<=7;
    }

     
    function isStarted() public view returns (bool) {
      return startTime!=0 && now > startTime;
    }

     

     
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy , address _customerAddress) internal returns (uint256) {
         
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

         
         
         
         
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

         
        if (
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _customerAddress &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
             
             
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

         
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