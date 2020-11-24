 

 

 

pragma solidity ^0.4.20;

contract CxxMain {
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }


    modifier checkExchangeOpen(uint256 _amountOfEthereum){
        if( exchangeClosed ){
            require(isInHelloCXX_[msg.sender]);
            isInHelloCXX_[msg.sender] = false;
            helloCount = SafeMath.sub(helloCount,1);
            if(helloCount == 0){
              exchangeClosed = false;
            }
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


     
    string public name = "CXX Token";
    string public symbol = "CXX";
    uint8 constant public decimals = 18;
    uint8 constant internal buyFee_ = 3; 
    uint8 constant internal sellFee_ = 3; 
    uint8 constant internal transferFee_ = 10;
    uint8 constant internal roiFee_ = 3;  
    uint8 constant internal roiRate_ = 50;  
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    uint256 internal tokenSupply_ = 0;
    uint256 internal helloCount = 0;
    uint256 internal profitPerShare_;

    uint256 public stakingRequirement = 50 ether;
    uint256 public totalTradingVolume = 0;
    uint256 public totalDividends = 0;
    uint256 public roiPool = 0;

    uint256 public checkinCount = 0;

    address internal devAddress_;

    

    struct ReferralData {
        address affFrom;
        uint256 tierInvest1Sum;
        uint256 tierInvest2Sum;
        uint256 tierInvest3Sum;
        uint256 affCount1Sum;  
        uint256 affCount2Sum;
        uint256 affCount3Sum;
    }
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => bool) internal isInHelloCXX_;

    mapping(address => ReferralData) public referralData;

    bool public exchangeClosed = true;



     
     
    function CxxToken()
        public
    {
        devAddress_ = 0xEE4207bE83685C94640d2fFb0961F71c2fC4fC4F;
    }

    function dailyCheckin()
      public
    {
      checkinCount = SafeMath.add(checkinCount,1);
    }

    function distributedRoi() public {
      require(msg.sender == devAddress_);

      uint256 dailyInterest = SafeMath.div(roiPool, roiRate_);   
      roiPool = SafeMath.sub(roiPool,dailyInterest);
      roiDistribution(dailyInterest, 0x0);
    }


     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        totalTradingVolume = SafeMath.add(totalTradingVolume,msg.value);
        purchaseTokens(msg.value, _referredBy);
    }

     
    function()
        payable
        public
    {
        totalTradingVolume = SafeMath.add(totalTradingVolume,msg.value);
        purchaseTokens(msg.value, 0x0);
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

         
         totalTradingVolume = SafeMath.add(totalTradingVolume,_dividends);
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

         
        onReinvestment(_customerAddress, _dividends, _tokens);
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

         
        onWithdraw(_customerAddress, _dividends);
    }

     
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, sellFee_);
        uint256 _roiPool = SafeMath.div(SafeMath.mul(_ethereum,roiFee_), 100);  
                roiPool = SafeMath.add(roiPool,_roiPool);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        _dividends =  SafeMath.sub(_dividends, _roiPool);
        totalDividends = SafeMath.add(totalDividends,_dividends);
         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;
        totalTradingVolume = SafeMath.add(totalTradingVolume,_ethereum);
         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }


     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;

        require(!exchangeClosed && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if(myDividends(true) > 0) withdraw();

        uint256 _tokenFee = SafeMath.div(_amountOfTokens, transferFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
        totalDividends = SafeMath.add(totalDividends,_dividends);
         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

         
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

         
        Transfer(_customerAddress, _toAddress, _taxedTokens);

         
        return true;

    }

     

    function disableInitialStage()
        public
    {
        require(msg.sender == devAddress_);
        exchangeClosed = false;
    }

    function setStakingRequirement(uint256 _amountOfTokens)
        public
    {
        require(msg.sender == devAddress_);
        stakingRequirement = _amountOfTokens;
    }

    function helloCXX(address _address, bool _status,uint8 _count)
      public
    {
      require(msg.sender == devAddress_);
      isInHelloCXX_[_address] = _status;
      helloCount = _count;
    }


     
     
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return this.balance;
    }

    function isOwner()
      public
      view
      returns(bool)
    {
      return msg.sender == devAddress_;
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
            uint256 _dividends = SafeMath.div(_ethereum, sellFee_);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
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
            uint256 _dividends = SafeMath.div(_ethereum, buyFee_);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    function roiDistribution(uint256 _incomingEthereum, address _referredBy) internal returns (uint256) {
      address _customerAddress = msg.sender;
      uint256 _undividedDividends = SafeMath.div(_incomingEthereum, buyFee_);  
      uint256 _referralBonus = SafeMath.div(_incomingEthereum, 10);  
      uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
      uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
      uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
      uint256 _fee = _dividends * magnitude;

      totalDividends = SafeMath.add(totalDividends,_undividedDividends);
      totalTradingVolume = SafeMath.add(totalTradingVolume,_incomingEthereum);

      require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

      distributeReferral(msg.sender, _referralBonus,_incomingEthereum);

      if(tokenSupply_ > 0){
          tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
          profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
          _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

      } else {
          tokenSupply_ = _amountOfTokens;
      }

      tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

      int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
      payoutsTo_[_customerAddress] += _updatedPayouts;

      onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);

      return _amountOfTokens;
   }

     
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, buyFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
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
        uint256 _dividends = SafeMath.div(_ethereum, sellFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }

     
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        checkExchangeOpen(_incomingEthereum)
        internal
        returns(uint256)
    {
         
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, buyFee_);  
        uint256 _referralBonus = SafeMath.div(_incomingEthereum, 10);  
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _roiPool = SafeMath.mul(_incomingEthereum,roiFee_);  
                _roiPool = SafeMath.div(_roiPool,100);
                _dividends =  SafeMath.sub(_dividends, _roiPool);
                roiPool = SafeMath.add(roiPool,_roiPool);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

         
        totalDividends = SafeMath.add(totalDividends,_undividedDividends);

         
        if(referralData[msg.sender].affFrom == address(0)){
          registerUser(msg.sender, _referredBy);
        }

        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        distributeReferral(msg.sender, _referralBonus,_incomingEthereum);

        if(tokenSupply_ > 0){
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

         
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

    function registerUser(address _msgSender, address _affFrom)
      internal
    {
        ReferralData storage _referralData = referralData[_msgSender];
        if(_affFrom != _msgSender){
          _referralData.affFrom = _affFrom;
        }
        else{
          _referralData.affFrom = devAddress_;
        }

        address _affAddr1 = _referralData.affFrom;
        address _affAddr2 = referralData[_affAddr1].affFrom;
        address _affAddr3 = referralData[_affAddr2].affFrom;

        referralData[_affAddr1].affCount1Sum = SafeMath.add(referralData[_affAddr1].affCount1Sum,1);
        referralData[_affAddr2].affCount2Sum = SafeMath.add(referralData[_affAddr2].affCount2Sum,1);
        referralData[_affAddr3].affCount3Sum = SafeMath.add(referralData[_affAddr3].affCount3Sum,1);

    }


    function distributeReferral(address _msgSender, uint256 _allaff,uint256 _incomingEthereum)
        internal
    {

        ReferralData storage _referralData = referralData[_msgSender];
        address _affAddr1 = _referralData.affFrom;
        address _affAddr2 = referralData[_affAddr1].affFrom;
        address _affAddr3 = referralData[_affAddr2].affFrom;
        uint256 _affRewards = 0;
        uint256 _affSent = _allaff;

        if (_affAddr1 != address(0) && tokenBalanceLedger_[_affAddr1] >= stakingRequirement) {
            _affRewards = SafeMath.div(SafeMath.mul(_allaff,5),10);
            _affSent = SafeMath.sub(_affSent,_affRewards);
            referralBalance_[_affAddr1] = SafeMath.add(referralBalance_[_affAddr1], _affRewards);
        }

        if (_affAddr2 != address(0) && tokenBalanceLedger_[_affAddr1] >= stakingRequirement) {
            _affRewards = SafeMath.div(SafeMath.mul(_allaff,3),10);
            _affSent = SafeMath.sub(_affSent,_affRewards);
            referralBalance_[_affAddr2] = SafeMath.add(referralBalance_[_affAddr2], _affRewards);
        }

        if (_affAddr3 != address(0) && tokenBalanceLedger_[_affAddr1] >= stakingRequirement) {
            _affRewards = SafeMath.div(SafeMath.mul(_allaff,2),10);
            _affSent = SafeMath.sub(_affSent,_affRewards);
            referralBalance_[_affAddr3] = SafeMath.add(referralBalance_[_affAddr3], _affRewards);
        }

        if(_affSent > 0 ){
            referralBalance_[devAddress_] = SafeMath.add(referralBalance_[devAddress_], _affSent);
        }

        referralData[_affAddr1].tierInvest1Sum = SafeMath.add(referralData[_affAddr1].tierInvest1Sum,_incomingEthereum);
        referralData[_affAddr2].tierInvest2Sum = SafeMath.add(referralData[_affAddr2].tierInvest2Sum,_incomingEthereum);
        referralData[_affAddr3].tierInvest3Sum = SafeMath.add(referralData[_affAddr3].tierInvest3Sum,_incomingEthereum);
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