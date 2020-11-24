 

pragma solidity ^0.4.24;

 


contract RabbitHub {
  using SafeMath for uint;
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }

    modifier notContract() {
      require (msg.sender == tx.origin);
      _;
    }

     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }


     
     
     
    modifier antiEarlyWhale(uint256 _amountOfEthereum){

        if(this.balance <= 50 ether) {
           
          require(tx.gasprice <= 50000000000 wei);
        }

         
         
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                 
                ambassadors_[msg.sender] == true &&

                 
                (ambassadorAccumulatedQuota_[msg.sender] + _amountOfEthereum) <= ambassadorMaxPurchase_

            );

             
            ambassadorAccumulatedQuota_[msg.sender] = SafeMath.add(ambassadorAccumulatedQuota_[msg.sender], _amountOfEthereum);
        }

        if(this.balance >= 50 ether) {
           
          botPhase = false;
        }

        _;

    }

     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
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

     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens,
        bytes data
    );


     
    string public name = "Rabbit Hub";
    string public symbol = "Carrot";
    uint8 constant public decimals = 18;
    uint8 constant internal buyDividendFee_ = 19;  
    uint8 constant internal sellDividendFee_ = 15;  
    uint8 constant internal bankRollFee_ = 1;  
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;

     
     
    address constant public giveEthBankRollAddress = 0x6cd532ffdd1ad3a57c3e7ee43dc1dca75ace901b;
    uint256 public totalEthBankrollReceived;  
    uint256 public totalEthBankrollCollected;  

     
    uint256 public stakingRequirement = 10e18;

     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 0.6 ether;
    uint256 constant internal ambassadorQuota_ = 3 ether;
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => address) internal referralOf_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    mapping(address => bool) internal alreadyBought;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

     
    mapping(address => bool) public administrators;

     
    bool public onlyAmbassadors = true;
    bool public botPhase;



     
     
    constructor()
        public
    {
        administrators[0x93B5b8E5AeFd9197305408df1F824B0E58229fD0] = true;
        administrators[0xAAa2792AC2A60c694a87Cec7516E8CdFE85B0463] = true;
        administrators[0xE5131Cd7222209D40cdDaE9e95113fC2075918a5] = true;

        ambassadors_[0x93B5b8E5AeFd9197305408df1F824B0E58229fD0] = true;
        ambassadors_[0xAAa2792AC2A60c694a87Cec7516E8CdFE85B0463] = true;
        ambassadors_[0xE5131Cd7222209D40cdDaE9e95113fC2075918a5] = true;
        ambassadors_[0xEbE8a13C450eC5Fe388B53E88f44eD56933C15bc] = true;
        ambassadors_[0x2df5671C284d185032f7c2Ffb1A6067eD4d32413] = true;
    }

     
    modifier antiBot(bytes32 _seed) {
      if(botPhase) {
        require(keccak256(keccak256(msg.sender)) == keccak256(_seed));
      }
      _;
    }

     
    function buy(address _referredBy, bytes32 _seed)
        antiBot(_seed)
        public
        payable
        returns(uint256)
    {
        purchaseInternal(msg.value, _referredBy);
    }

     
    function()
        payable
        public
    {
         
        if(botPhase) {
          revert();
        } else {
          purchaseInternal(msg.value, 0x0);
        }

    }

     
    function payBankRoll() payable public {
      uint256 ethToPay = SafeMath.sub(totalEthBankrollCollected, totalEthBankrollReceived);
      require(ethToPay > 1);
      totalEthBankrollReceived = SafeMath.add(totalEthBankrollReceived, ethToPay);
      if(!giveEthBankRollAddress.call.value(ethToPay).gas(400000)()) {
         totalEthBankrollReceived = SafeMath.sub(totalEthBankrollReceived, ethToPay);
      }
    }

     
    function reinvest()
        onlyStronghands()
        public
    {
         
        uint256 _dividends = myDividends(false);  

         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

         
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

     
    function exit()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);

         
        withdraw();
    }

     
    function withdraw()
        onlyStronghands()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);  

         
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        _customerAddress.transfer(_dividends);

         
        emit onWithdraw(_customerAddress, _dividends);
    }

     
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);

        uint256 _dividends =SafeMath.div(SafeMath.mul(_ethereum, sellDividendFee_), 100);  
         uint256 _bankRollPayout = SafeMath.div(SafeMath.mul(_ethereum, bankRollFee_), 100);

         
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _bankRollPayout);

         
        totalEthBankrollCollected = SafeMath.add(totalEthBankrollCollected, _bankRollPayout);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }


     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
         
        require(!isContract(_toAddress));
         
        address _customerAddress = msg.sender;

         
         
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if(myDividends(true) > 0) withdraw();

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);


         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

         
        return true;
    }

     
    function transfer(address _toAddress, uint256 _amountOfTokens, bytes _data)
        onlyBagholders()
        public
        returns(bool)
    {
         
        require(isContract(_toAddress));
         
        address _customerAddress = msg.sender;

         
         
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if(myDividends(true) > 0) withdraw();

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        ERC223ReceivingContract _contract = ERC223ReceivingContract(_toAddress);
        _contract.tokenFallback(msg.sender, _amountOfTokens, _data);


         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens, _data);

         
        return true;
    }

     
     
    function openTheRabbitHole()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
        botPhase = true;
    }

     
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }

     
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
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


     
     
     function totalEthereumBalance()
         public
         view
         returns(uint)
     {
         return this.balance;
     }

     
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }

     
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

     
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

     
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

     
    function sellPrice()
        public
        view
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, sellDividendFee_), 100);
            uint256 _bankRollPayout = SafeMath.div(SafeMath.mul(_ethereum, bankRollFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _bankRollPayout);
            return _taxedEthereum;
        }
    }

     
    function buyPrice()
        public
        view
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, buyDividendFee_), 100);
            uint256 _bankRollPayout = SafeMath.div(SafeMath.mul(_ethereum, bankRollFee_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _bankRollPayout);
            return _taxedEthereum;
        }
    }

     
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, buyDividendFee_), 100);
        uint256 _bankRollPayout = SafeMath.div(SafeMath.mul(_ethereumToSpend, bankRollFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _bankRollPayout);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

     
    function calculateEthereumReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, sellDividendFee_), 100);
        uint256 _bankRollPayout = SafeMath.div(SafeMath.mul(_ethereum, bankRollFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _bankRollPayout);
        return _taxedEthereum;
    }

     
    function etherToSendBankRoll()
        public
        view
        returns(uint256) {
        return SafeMath.sub(totalEthBankrollCollected, totalEthBankrollReceived);
    }

     
    function isContract(address _addr) private returns (bool) {
      uint length;
      assembly {
        length := extcodesize(_addr)
      }
      return length > 0;
    }


     

     
    function purchaseInternal(uint256 _incomingEthereum, address _referredBy)
      notContract() 
      internal
      returns(uint256) {

      uint256 purchaseEthereum = _incomingEthereum;
      uint256 excess;
      if(purchaseEthereum > 1 ether) {  
          if (SafeMath.sub(address(this).balance, purchaseEthereum) <= 75 ether) {  
              purchaseEthereum = 1 ether;
              excess = SafeMath.sub(_incomingEthereum, purchaseEthereum);
          }
      }

      if (excess > 0) {
        msg.sender.transfer(excess);
      }

      purchaseTokens(purchaseEthereum, _referredBy);
    }


    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {

         
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, buyDividendFee_), 100);  
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_incomingEthereum, 15), 100);  
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends), SafeMath.div(SafeMath.mul(_incomingEthereum, bankRollFee_), 100));

        totalEthBankrollCollected = SafeMath.add(totalEthBankrollCollected, SafeMath.div(SafeMath.mul(_incomingEthereum, bankRollFee_), 100));

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != msg.sender &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement &&

            referralOf_[msg.sender] == 0x0000000000000000000000000000000000000000 &&

            alreadyBought[msg.sender] == false
        ){
            referralOf_[msg.sender] = _referredBy;

             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], SafeMath.div(SafeMath.mul(_incomingEthereum, 10), 100));  

            address tier2 = referralOf_[_referredBy];

            if (tier2 != 0x0000000000000000000000000000000000000000 && tokenBalanceLedger_[tier2] >= stakingRequirement) {
                referralBalance_[tier2] = SafeMath.add(referralBalance_[tier2], SafeMath.div(_referralBonus, 3));  
            }
            else {
                _dividends = SafeMath.add(_dividends, SafeMath.div(_referralBonus, 3));
                _fee = _dividends * magnitude;
            }

        } else {
             
             
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

         
        if(tokenSupply_ > 0){

             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

             
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[msg.sender] = SafeMath.add(tokenBalanceLedger_[msg.sender], _amountOfTokens);

         
         
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[msg.sender] += _updatedPayouts;
        alreadyBought[msg.sender] = true;

         
        emit onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

         
        function ethereumToTokens_(uint256 _ethereum)
            internal
            view
            returns(uint256)
        {
            uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
            uint256 _tokensReceived =
             (
                (
                     
                    SafeMath.sub(
                        (sqrt
                            (
                                (_tokenPriceInitial**2)
                                +
                                (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                                +
                                (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                                +
                                (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                            )
                        ), _tokenPriceInitial
                    )
                )/(tokenPriceIncremental_)
            )-(tokenSupply_)
            ;

            return _tokensReceived;
        }

         
         function tokensToEthereum_(uint256 _tokens)
            internal
            view
            returns(uint256)
        {

            uint256 tokens_ = (_tokens + 1e18);
            uint256 _tokenSupply = (tokenSupply_ + 1e18);
            uint256 _etherReceived =
            (
                 
                SafeMath.sub(
                    (
                        (
                            (
                                tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                            )-tokenPriceIncremental_
                        )*(tokens_ - 1e18)
                    ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
                )
            /1e18);
            return _etherReceived;
        }




         
         
        function sqrt(uint x) internal pure returns (uint y) {
            uint z = (x + 1) / 2;
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


      contract ERC223ReceivingContract {
       
       function tokenFallback(address _from, uint _value, bytes _data);
}