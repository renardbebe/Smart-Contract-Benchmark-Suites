 

pragma solidity ^0.4.21;

 

contract Hourglass {
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyStronghands() {
        require(myDividends() > 0);
        _;
    }

     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }


     
     
     
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;

         
         
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                 
                ambassadors_[_customerAddress] == true &&

                 
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_

            );

             
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);

             
            _;
        } else {
             
            onlyAmbassadors = false;
            _;
        }

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


     
    string public name = "BeNOW";
    string public symbol = "NOW";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 20;
    uint8 constant internal developerFee_ = 2;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;

    address constant public developerFundAddress = 0xc22388e302ac17c7a2b87a9a3e7325febd4e2458;
    uint256 public totalDevelopmentFundBalance;
    uint256 public totalDevelopmentFundEarned;
    
    bool firstBuy = true;

     
    uint256 public stakingRequirement = 100e18;

     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 3 ether;
    uint256 constant internal ambassadorQuota_ = 40 ether;
    
     
    mapping(address => address) internal savedReferrals_;
    
     
    mapping(address => uint256) internal totalEarned_;



    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

     
    mapping(address => bool) public administrators;

     
    bool public onlyAmbassadors = true;

     
     
    function Hourglass()
        public
    {
         
        administrators[developerFundAddress] = true;

        ambassadors_[0xA36f907BE1FBf75e2495Cc87F8f4D201c1b634Af] = true;
        ambassadors_[0x5Ec92834A6bc25Fe70DE9483F6F4B1051fcc0C96] = true;
        ambassadors_[0xe8B1C589e86DEf7563aD43BebDDB7B1677beC9A9] = true;
        ambassadors_[0x4da6fc68499FB3753e77DD6871F2A0e4DC02fEbE] = true;
        ambassadors_[0x8E2a227eC573dd2Ef11c5B0B7985cb3d9ADf06b3] = true;
        ambassadors_[0xD795b28e43a14d395DDF608eaC6906018e3AF0fC] = true;
        ambassadors_[0xD01167b13444E3A75c415d644C832Ab8FC3fc742] = true;
        ambassadors_[0x46091f77b224576E224796de5c50e8120Ad7D764] = true;
        ambassadors_[0x871A93B4046545CCff4F1e41EedFC52A6acCbc42] = true;
        ambassadors_[0xcbbcf632C87D3dF7342642525Cc5F30090E390a6] = true;
        ambassadors_[0x025fb7cad32448571150de24ac254fe8d9c10c50] = true;
        ambassadors_[0xe196F7c242dE1F42B10c262558712e6268834008] = true;
        ambassadors_[0x4ffe17a2a72bc7422cb176bc71c04ee6d87ce329] = true;
        ambassadors_[0x867e1996C36f57545C365B33edd48923873792F6] = true;
        ambassadors_[0x1ef88e2858fb1052180e2a372d94f24bcb8cc5b0] = true;
        ambassadors_[0x642e0Ce9AE8c0D8007e0ACAF82C8D716FF8c74c1] = true;
        ambassadors_[0x26d8627dbFF586A3B769f34DaAd6085Ef13B2978] = true;
        ambassadors_[0x9abcf6b5ae277c1a4a14f3db48c89b59d831dc8f] = true;
        ambassadors_[0x847c5b4024C19547BCa7EFD503EbbB97f500f4C0] = true;
        ambassadors_[0x19e361e3CF55bAD433Ed107997728849b172a139] = true;
        ambassadors_[0x008ca4F1bA79D1A265617c6206d7884ee8108a78] = true;
        ambassadors_[0xE7F53CE9421670AC2f11C5035E6f6f13d9829aa6] = true;
        ambassadors_[0x63913b8B5C6438f23c986aD6FdF103523B17fb90] = true;
        ambassadors_[0x43593BCFC24301da0763ED18845A120FaEC1EAfE] = true;
        ambassadors_[0x87A7e71D145187eE9aAdc86954d39cf0e9446751] = true;
        ambassadors_[0x7c76A64AC61D1eeaFE2B8AF6F7f0a6a1890418F3] = true;
        ambassadors_[0xb0eF8673E22849bB45B3c97226C11a33394eEec1] = true;
        ambassadors_[0xc585ca6a9B9C0d99457B401f8e2FD12048713cbc] = true;
        
    }


     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        
        require(msg.value >= .1 ether);
        
        if(savedReferrals_[msg.sender] == 0x0000000000000000000000000000000000000000){
            savedReferrals_[msg.sender] = _referredBy;
        }else{
            _referredBy = savedReferrals_[msg.sender];
        }
        
        purchaseTokens(msg.value, savedReferrals_[msg.sender]);
    }

     
    function()
        payable
        public
    {
        purchaseTokens(msg.value, savedReferrals_[msg.sender]);
    }

     
    function reinvest()
        onlyStronghands()
        public
    {
         
        uint256 _dividends = myDividends();  

         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        uint256 _tokens = purchaseTokensWithoutDevelopmentFund(_dividends, savedReferrals_[msg.sender]);

         
        onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
     
    function reinvestAffiliate()
        public
    {
        
        require(referralBalance_[msg.sender] > 0);
        
         
        uint256 _dividends = referralBalance_[msg.sender];
        referralBalance_[msg.sender] = 0;
        
        address _customerAddress = msg.sender;

         
        uint256 _tokens = purchaseTokensWithoutDevelopmentFund(_dividends, savedReferrals_[msg.sender]);

         
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
    
      
     function getSavedReferral(address customer) public view returns (address) {
         return savedReferrals_[customer];
     }
     
       
     function getTotalComission(address customer) public view returns (uint256) {
         return totalEarned_[customer];
     }
     
       
     function getDevelopmentFundBalance() public view returns (uint256) {
         return totalDevelopmentFundBalance;
     }
     
       
     function getTotalDevelopmentFundEarned() public view returns (uint256) {
         return totalDevelopmentFundEarned;
     }
     
       
     function getReferralBalance() public view returns (uint256) {
         return referralBalance_[msg.sender];
     }
    
     
       
     function withdrawTotalDevEarned() public {
         require(msg.sender == developerFundAddress);
         developerFundAddress.transfer(totalDevelopmentFundBalance);
         totalDevelopmentFundBalance = 0;
     }

     
    function withdraw()
        onlyStronghands()
        public
    {
        
        require(!onlyAmbassadors);
        
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();  

         
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _customerAddress.transfer(_dividends);

         
        onWithdraw(_customerAddress, _dividends);
    }
    
     
    function withdrawAffiliateRewards()
        onlyStronghands()
        public
    {
        
        require(!onlyAmbassadors);
        
         
        address _customerAddress = msg.sender;
        uint256 _dividends = referralBalance_[_customerAddress];
        
        referralBalance_[_customerAddress] = 0;
        
         
        _customerAddress.transfer(_dividends);
        
         
        onWithdraw(_customerAddress, _dividends);
    }

     
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        
        require(_amountOfTokens >= 40 && !onlyAmbassadors);
        
        if(ambassadors_[msg.sender] == true){
            require(1529260200 < now);
        }
        
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);

        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _devFund = SafeMath.div(SafeMath.mul(_ethereum, developerFee_), 100);

        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _devFund);

        totalDevelopmentFundBalance = SafeMath.add(totalDevelopmentFundBalance, _devFund);
        totalDevelopmentFundEarned = SafeMath.add(totalDevelopmentFundEarned, _devFund);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
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
        
        if(ambassadors_[msg.sender] == true){
            require(1529260200 < now);
        }
        
         
        address _customerAddress = msg.sender;

         
         
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if(myDividends() > 0) withdraw();

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);


         
        Transfer(_customerAddress, _toAddress, _amountOfTokens);

         
        return true;
    }

     
     
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
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

     
    function myDividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress) ;
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
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _devFund = SafeMath.div(SafeMath.mul(_ethereum, developerFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _devFund);
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
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _devFund = SafeMath.div(SafeMath.mul(_ethereum, developerFee_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _devFund);
            return _taxedEthereum;
        }
    }

     
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_), 100);
        uint256 _devFund = SafeMath.div(SafeMath.mul(_ethereumToSpend, developerFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _devFund);
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
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _devFund = SafeMath.div(SafeMath.mul(_ethereum, developerFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _devFund);
        return _taxedEthereum;
    }

     

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
        
        if(firstBuy == true){
            require(msg.sender == 0xc585ca6a9B9C0d99457B401f8e2FD12048713cbc);
            firstBuy = false;
        }
        
         
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 5);
        uint256 _devFund = SafeMath.div(SafeMath.mul(_incomingEthereum, developerFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends), _devFund);

        totalDevelopmentFundBalance = SafeMath.add(totalDevelopmentFundBalance, _devFund);
        totalDevelopmentFundEarned = SafeMath.add(totalDevelopmentFundEarned, _devFund);

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != msg.sender &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
            
             
            totalEarned_[_referredBy] = SafeMath.add(totalEarned_[_referredBy], _referralBonus);
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

         
        onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }
    
    function purchaseTokensWithoutDevelopmentFund(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
         
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 5);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != msg.sender &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
            
             
            totalEarned_[_referredBy] = SafeMath.add(totalEarned_[_referredBy], _referralBonus);
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

         
        onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy);

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