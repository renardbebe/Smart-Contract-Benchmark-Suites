 

pragma solidity ^0.4.25;

 

contract AcceptsExchange {
    redalert public tokenContract;

    function AcceptsExchange(address _tokenContract) public {
        tokenContract = redalert(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
    function tokenFallbackExpanded(address _from, uint256 _value, bytes _data, address _sender, address _referrer) external returns (bool);
}

contract redalert {
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyStronghands() {
        require(myDividends(true) > 0 || ownerAccounts[msg.sender] > 0);
         
        _;
    }
    
      modifier notContract() {
      require (msg.sender == tx.origin);
      _;
    }

    modifier allowPlayer(){
        
        require(boolAllowPlayer);
        _;
    }

     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
    
    modifier onlyActive(){
        require(boolContractActive);
        _;
    }

     modifier onlyCardActive(){
        require(boolCardActive);
        _;
    }

    
     
     
     
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
         
         
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                 
                (ambassadors_[_customerAddress] == true &&
                
                 
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_) ||

                (_customerAddress == dev)
                
            );
            
             
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
        
             
            _;
        } else {
             
            onlyAmbassadors = false;
            _;    
        }
        
    }
    
     

    event onCardBuy(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 card,
        uint256 newPrice,
        uint256 halfLifeTime
    );

    event onInsuranceChange(
        address customerAddress,
        uint256 card,
        uint256 insuranceAmount
    );

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
    
        
    event Halflife(
        address customerAddress,
        uint card,
        uint price,
        uint newBlockTime,
        uint insurancePay,
        uint cardInsurance
    );
    
     
    string public name = "RedAlert";
    string public symbol = "REDS";
    uint8 constant public decimals = 18;
    uint256 constant internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000001 ether;
    uint256 constant internal magnitude = 2**64;
    
     
    uint256 public stakingRequirement = 100e18;
    
     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 3 ether;
    uint256 constant internal ambassadorQuota_ = 100 ether;
    
    address dev;

    uint public nextAvailableCard;

    address add2 = 0x0;

    uint public totalCardValue = 0;

    uint public totalCardInsurance = 0;

    bool public boolAllowPlayer = false;

     
    struct DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

     
    mapping(uint => address) internal cardOwner;
    mapping(uint => uint) public cardPrice;
    mapping(uint => uint) public basePrice;
    mapping(uint => uint) internal cardPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalCardDivs;
    mapping(uint => uint) internal totalCardDivsETH;
    mapping(uint => string) internal cardName;
    mapping(uint => uint) internal cardInsurance;

    uint public cardInsuranceAccount;

    uint cardPriceIncrement = 1250;    
   
    uint totalDivsProduced;

     
    uint public ownerDivRate = 450;      
    uint public distDivRate = 400;       
    uint public devDivRate = 50;         
    uint public insuranceDivRate = 50;   
    uint public yieldDivRate = 50;       
    uint public referralRate = 50;       
    
    mapping(uint => uint) internal cardBlockNumber;

    uint public halfLifeTime = 5900;             
    uint public halfLifeRate = 970;              
    uint public halfLifeReductionRate = 970;     


    uint public halfLifeClear = 1230;      
    uint public halfLifeAlert = 100;      

    bool public allowHalfLife = true;   

    bool public allowReferral = false;   

    uint public insurancePayoutRate = 50;  

    uint8 public dividendFee_ = 150;            

    uint8 public dividendFeeBuyClear_ = 150;
    uint8 public dividendFeeSellClear_ = 200;

    uint8 public dividendFeeBuyAlert_ = 150;
    uint8 public dividendFeeSellAlert_ = 200;

    uint8 public cardInsuranceFeeRate_ = 25;     
    uint8 public yieldDividendFeeRate_ = 25;     

     

    uint public maxCards = 50;

    bool public boolContractActive = false;
    bool public boolCardActive = false;

     
    mapping(address => bool) public administrators;
    
     
    bool public onlyAmbassadors = true;

       
    mapping(address => bool) public canAcceptTokens_;  

    uint public alertTime1 = 0;
    uint public alertTime2 = 8;
    uint public alertTime3 = 16;

    uint public lastHour = 0;

    bool public boolAlertStatus = false;



     
     
    function redalert()
    public
    {
        allowHalfLife = true;
        allowReferral = false;

         
        administrators[msg.sender] = true;

        dev = msg.sender;

        ambassadors_[dev] = true;
        ambassadors_[0x96762288ebb2560a19F8eAdAaa2012504F64278B] = true;
        ambassadors_[0x5145A296e1bB9d4Cf468d6d97d7B6D15700f39EF] = true;
        ambassadors_[0xE74b1ea522B9d558C8e8719c3b1C4A9050b531CA] = true;
        ambassadors_[0xb62A0AC2338C227748E3Ce16d137C6282c9870cF] = true;
        ambassadors_[0x836e5abac615b371efce0ab399c22a04c1db5ecf] = true;
        ambassadors_[0xAe3dC7FA07F9dD030fa56C027E90998eD9Fe9D61] = true;
        ambassadors_[0x38602d1446fe063444B04C3CA5eCDe0cbA104240] = true;
        ambassadors_[0x3825c8BA07166f34cE9a2cD1e08A68b105c82cB9] = true;
        ambassadors_[0xa6662191F558e4C611c8f14b50c784EDA9Ace98d] = true;
        ambassadors_[0xC697BE0b5b82284391A878B226e2f9AfC6B94710] = true;
        ambassadors_[0x03Ba7aC9fa34E2550dE27B33Cb7eBc8d2618A263] = true;
        ambassadors_[0x79562dcCFAad8871E2eC1C37172Cb1ce969b04Fd] = true;
        
        ambassadors_[0x41fe3738b503cbafd01c1fd8dd66b7fe6ec11b01] = true;
        ambassadors_[0x96762288ebb2560a19f8eadaaa2012504f64278b] = true;
        ambassadors_[0xc29a6dd21801e58566df9f003b7011e30724543e] = true;
        ambassadors_[0xc63ea85cc823c440319013d4b30e19b66466642d] = true;
        ambassadors_[0xc6f827796a2e1937fd7f97c4e0a4906c476794f6] = true;
        ambassadors_[0xe74b1ea522b9d558c8e8719c3b1c4a9050b531ca] = true;
        ambassadors_[0x6b90d498062140c607d03fd642377eeaa325703e] = true;
        ambassadors_[0x5f1088110edcba27fc206cdcc326b413b5867361] = true;
        ambassadors_[0xc92fd0e554b12eb10f584819eec2394a9a6f3d1d] = true;
        ambassadors_[0xb62a0ac2338c227748e3ce16d137c6282c9870cf] = true;
        ambassadors_[0x3f6c42409da6faf117095131168949ab81d5947d] = true;
        ambassadors_[0xd54c47b3165508fb5418dbdec59a0d2448eeb3d7] = true;
        ambassadors_[0x285d366834afaa8628226e65913e0dd1aa26b1f8] = true;
        ambassadors_[0x285d366834afaa8628226e65913e0dd1aa26b1f8] = true;
        ambassadors_[0x5f5996f9e1960655d6fc00b945fef90672370d9f] = true;
        ambassadors_[0x3825c8ba07166f34ce9a2cd1e08a68b105c82cb9] = true;
        ambassadors_[0x7f3e05b4f258e1c15a0ef49894cffa1d89ceb9d3] = true;
        ambassadors_[0x3191acf877495e5f4e619ec722f6f38839182660] = true;
        ambassadors_[0x14f981ec7b0f59df6e1c56502e272298f221d763] = true;
        ambassadors_[0xae817ec70d8b621bb58a047e63c31445f79e20dc] = true;
        ambassadors_[0xc43af3becac9c810384b69cf061f2d7ec73105c4] = true;
        ambassadors_[0x0743469569ed5cc44a51216a1bf5ad7e7f90f40e] = true;
        ambassadors_[0xff6a4d0ed374ba955048664d6ef5448c6cd1d56a] = true;
        ambassadors_[0x62358a483311b3de29ae987b990e19de6259fa9c] = true;
        ambassadors_[0xa0fea1bcfa32713afdb73b9908f6cb055022e95f] = true;
        ambassadors_[0xb2af816608e1a4d0fb12b81028f32bac76256eba] = true;
        ambassadors_[0x977193d601b364f38ab1a832dbaef69ca7833992] = true;
        ambassadors_[0xed3547f0ed028361685b39cd139aa841df6629ab] = true;
        ambassadors_[0xe40ff298079493cba637d92089e3d1db403974cb] = true;
        ambassadors_[0xae3dc7fa07f9dd030fa56c027e90998ed9fe9d61] = true;
        ambassadors_[0x2dd35e7a6f5fcc28d146c04be641f969f6d1e403] = true;
        ambassadors_[0x2afe21ec5114339922d38546a3be7a0b871d3a0d] = true;
        ambassadors_[0x6696fee394bb224d0154ea6b58737dca827e1960] = true;
        ambassadors_[0xccdf159b1340a35c3567b669c836a88070051314] = true;
        ambassadors_[0x1c3416a34c86f9ddcd05c7828bf5693308d19e0b] = true;
        ambassadors_[0x846dedb19b105edafac2c9410fa2b5e73b596a14] = true;
        ambassadors_[0x3e9294f9b01bc0bcb91413112c75c3225c65d0b3] = true;
        ambassadors_[0x3a5ce61c74343dde474bad4210cccf1dac7b1934] = true;
        ambassadors_[0x38e123f89a7576b2942010ad1f468cc0ea8f9f4b] = true;
        ambassadors_[0xdcd8bad894035b5c554ad450ca84ae6be0b73122] = true;
        ambassadors_[0xcfab320d4379a84fe3736eccf56b09916e35097b] = true;
        ambassadors_[0x12f53c1d7caea0b41010a0e53d89c801ed579b5a] = true;
        ambassadors_[0x5145a296e1bb9d4cf468d6d97d7b6d15700f39ef] = true;
        ambassadors_[0xac707a1b4396a309f4ad01e3da4be607bbf14089] = true;
        ambassadors_[0x38602d1446fe063444b04c3ca5ecde0cba104240] = true;
        ambassadors_[0xc951d3463ebba4e9ec8ddfe1f42bc5895c46ec8f] = true;
        ambassadors_[0x69e566a65d00ad5987359db9b3ced7e1cfe9ac69] = true;
        ambassadors_[0x533b14f6d04ed3c63a68d5e80b7b1f6204fb4213] = true;
        ambassadors_[0x5fa0b03bee5b4e6643a1762df718c0a4a7c1842f] = true;
        ambassadors_[0xb74d5f0a81ce99ac1857133e489bc2b4954935ff] = true;
        ambassadors_[0xc371117e0adfafe2a3b7b6ba71b7c0352ca7789d] = true;
        ambassadors_[0xcade49e583bc226f19894458f8e2051289f1ac85] = true;
        ambassadors_[0xe3fc95aba6655619db88b523ab487d5273db484f] = true;
        ambassadors_[0x22e4d1433377a2a18452e74fd4ba9eea01824f7d] = true;
        ambassadors_[0x32ae5eff81881a9a70fcacada5bb1925cabca508] = true;
        ambassadors_[0xb864d177c291368b52a63a95eeff36e3731303c1] = true;
        ambassadors_[0x46091f77b224576e224796de5c50e8120ad7d764] = true;
        ambassadors_[0xc6407dd687a179aa11781b8a1e416bd0515923c2] = true;
        ambassadors_[0x2502ce06dcb61ddf5136171768dfc08d41db0a75] = true;
        ambassadors_[0x6b80ca9c66cdcecc39893993df117082cc32bb16] = true;
        ambassadors_[0xa511ddba25ffd74f19a400fa581a15b5044855ce] = true;
        ambassadors_[0xce81d90ae52d34588a95db59b89948c8fec487ce] = true;
        ambassadors_[0x6d60dbf559bbf0969002f19979cad909c2644dad] = true;
        ambassadors_[0x45101255a2bcad3175e6fda4020a9b77e6353a9a] = true;
        ambassadors_[0xe9078d7539e5eac3b47801a6ecea8a9ec8f59375] = true;
        ambassadors_[0x41a21b264f9ebf6cf571d4543a5b3ab1c6bed98c] = true;
        ambassadors_[0x471e8d970c30e61403186b6f245364ae790d14c3] = true;
        ambassadors_[0x6eb7f74ff7f57f7ba45ca71712bccef0588d8f0d] = true;
        ambassadors_[0xe6d6bc079d76dc70fcec5de84721c7b0074d164b] = true;
        ambassadors_[0x3ec5972c2177a08fd5e5f606f19ab262d28ceffe] = true;
        ambassadors_[0x108b87a18877104e07bd870af70dfc2487447262] = true;
        ambassadors_[0x3129354440e4639d2b809ca03d4ccc6277ac8167] = true;
        ambassadors_[0x21572b6a855ee8b1392ed1003ecf3474fa83de3e] = true;
        ambassadors_[0x75ab98f33a7a60c4953cb907747b498e0ee8edf7] = true;
        ambassadors_[0x0fe6967f9a5bb235fc74a63e3f3fc5853c55c083] = true;
        ambassadors_[0x49545640b9f3266d13cce842b298d450c0f8d776] = true;
        ambassadors_[0x9327128ead2495f60d41d3933825ffd8080d4d42] = true;
        ambassadors_[0x82b4e53a7d6bf6c72cc57f8d70dae90a34f0870f] = true;
        ambassadors_[0xb74d5f0a81ce99ac1857133e489bc2b4954935ff] = true;
        ambassadors_[0x3749d556c167dd73d536a6faaf0bb4ace8f7dab9] = true;
        ambassadors_[0x3039f6857071692b540d9e1e759a0add93af3fed] = true;
        ambassadors_[0xb74d5f0a81ce99ac1857133e489bc2b4954935ff] = true;
     
        
        nextAvailableCard = 13;

        cardOwner[1] = dev;
        cardPrice[1] = 5 ether;
        basePrice[1] = cardPrice[1];
        cardPreviousPrice[1] = 0;

        cardOwner[2] = dev;
        cardPrice[2] = 4 ether;
        basePrice[2] = cardPrice[2];
        cardPreviousPrice[2] = 0;

        cardOwner[3] = dev;
        cardPrice[3] = 3 ether;
        basePrice[3] = cardPrice[3];
        cardPreviousPrice[3] = 0;

        cardOwner[4] = dev;
        cardPrice[4] = 2 ether;
        basePrice[4] = cardPrice[4];
        cardPreviousPrice[4] = 0;

        cardOwner[5] = dev;
        cardPrice[5] = 1.5 ether;
        basePrice[5] = cardPrice[5];
        cardPreviousPrice[5] = 0;

        cardOwner[6] = dev;
        cardPrice[6] = 1 ether;
        basePrice[6] = cardPrice[6];
        cardPreviousPrice[6] = 0;

        cardOwner[7] = dev;
        cardPrice[7] = 0.9 ether;
        basePrice[7] = cardPrice[7];
        cardPreviousPrice[7] = 0;

        cardOwner[8] = dev;
        cardPrice[8] = 0.7 ether;
        basePrice[8] = cardPrice[8];
        cardPreviousPrice[8] = 0;

        cardOwner[9] = 0xAe3dC7FA07F9dD030fa56C027E90998eD9Fe9D61;
        cardPrice[9] = 0.5 ether;
        basePrice[9] = cardPrice[9];
        cardPreviousPrice[9] = 0;

        cardOwner[10] = dev;
        cardPrice[10] = 0.4 ether;
        basePrice[10] = cardPrice[10];
        cardPreviousPrice[10] = 0;

        cardOwner[11] = dev;
        cardPrice[11] = 0.2 ether;
        basePrice[11] = cardPrice[11];
        cardPreviousPrice[11] = 0;

        cardOwner[12] = dev;
        cardPrice[12] = 0.1 ether;
        basePrice[12] = cardPrice[12];
        cardPreviousPrice[12] = 0;

        getTotalCardValue();

    }
    
     
     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }
    
     
    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
    }
    
     
    function reinvest()
        onlyStronghands()
        public
    {
         
        uint256 _dividends = myDividends(false);  
        
         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
         
        _dividends += referralBalance_[_customerAddress] + ownerAccounts[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        ownerAccounts[_customerAddress] = 0;
        
         
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        
         
        onReinvestment(_customerAddress, _dividends, _tokens);
        checkHalfLife();
    }
    
     
    function exit()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
         
        withdraw();
        checkHalfLife();
    }

     
    function withdraw()
        onlyStronghands()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);  
        
         
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
         
        _dividends += referralBalance_[_customerAddress] + ownerAccounts[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        ownerAccounts[_customerAddress] = 0;
        
         
        _customerAddress.transfer(_dividends);
        
         
        onWithdraw(_customerAddress, _dividends);
        checkHalfLife();
    }
    
     
    function sell(uint256 _amountOfTokens)
    
        onlyBagholders()
        public
    {
         
        uint8 localDivFee = 200;
        lastHour = getHour(block.timestamp);
        if (getHour(block.timestamp) == alertTime1 || getHour(block.timestamp) == alertTime2 || getHour(block.timestamp) == alertTime3){
            boolAlertStatus = true;
            localDivFee = dividendFeeBuyAlert_;
        }else{
            boolAlertStatus = false;
            localDivFee = dividendFeeBuyClear_;
        }

        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, localDivFee),1000);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        checkHalfLife();
        
         
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    
     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;

        uint8 localDivFee = 200;
        lastHour = getHour(block.timestamp);
        if (getHour(block.timestamp) == alertTime1 || getHour(block.timestamp) == alertTime2 || getHour(block.timestamp) == alertTime3){
            boolAlertStatus = true;
            localDivFee = dividendFeeBuyAlert_;
        }else{
            boolAlertStatus = false;
            localDivFee = dividendFeeBuyClear_;
        }

        if (msg.sender == dev){    
            localDivFee = 0;
        }

        
         
         
         
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
         
        if(myDividends(true) > 0) withdraw();
        
         
         
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, localDivFee),1000);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
  
         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        
         
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        
         
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        checkHalfLife();
        
         
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

    function setAllowHalfLife(bool _allow)
        onlyAdministrator()
        public
    {
        allowHalfLife = _allow;
    
    }

    function setAllowReferral(bool _allow)
        onlyAdministrator()
        public
    {
        allowReferral = _allow;   
    
    }

     
    function setFeeRates(uint8 _newDivRate, uint8 _yieldDivFee, uint8 _newCardFee)
        onlyAdministrator()
        public
    {
        require(_newDivRate <= 250);   
        require(_yieldDivFee <= 50);   
        require(_newCardFee <= 50);    

        dividendFee_ = _newDivRate;
        yieldDividendFeeRate_ = _yieldDivFee;
        cardInsuranceFeeRate_ = _newCardFee;
    }

     
    function setExchangeRates(uint8 _newBuyAlert, uint8 _newBuyClear, uint8 _newSellAlert, uint8 _newSellClear)
        onlyAdministrator()
        public
    {
        require(_newBuyAlert <= 400);    
        require(_newBuyClear <= 400);    
        require(_newSellAlert <= 400);   
        require(_newSellClear <= 400);   

        dividendFeeBuyClear_ = _newBuyClear;
        dividendFeeSellClear_ = _newSellClear;
        dividendFeeBuyAlert_ = _newBuyAlert;
        dividendFeeSellAlert_ = _newSellAlert;

    }

         
    function setInsurancePayout(uint8 _newRate)
        onlyAdministrator()
        public
    {
        require(_newRate <= 200);
        insurancePayoutRate = _newRate;
    }

    
     
    function setAlertTimes(uint _newAlert1, uint _newAlert2, uint _newAlert3)
        onlyAdministrator()
        public
    {
        alertTime1 = _newAlert1;
        alertTime2 = _newAlert2;
        alertTime3 = _newAlert3;
    }

       
    function setHalfLifePeriods(uint _alert, uint _clear)
        onlyAdministrator()
        public
    {
        halfLifeAlert = _alert;
        halfLifeClear = _clear;
    }
    
     
    function setContractActive(bool _status)
        onlyAdministrator()
        public
    {
        boolContractActive = _status;
    }

     
    function setCardActive(bool _status)
        onlyAdministrator()
        public
    {
        boolCardActive = _status;
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

    
    function setMaxCards(uint _card)  
        onlyAdministrator()
        public
    {
        maxCards = _card;
    }

    function setHalfLifeTime(uint _time)
        onlyAdministrator()
        public
    {
        halfLifeTime = _time;
    }

    function setHalfLifeRate(uint _rate)
        onlyAdministrator()
        public
    {
        halfLifeRate = _rate;
    }

    function addNewCard(uint _price) 
        onlyAdministrator()
        public
    {
        require(nextAvailableCard < maxCards);
        cardPrice[nextAvailableCard] = _price;
        basePrice[nextAvailableCard] = cardPrice[nextAvailableCard];
        cardOwner[nextAvailableCard] = dev;
        totalCardDivs[nextAvailableCard] = 0;
        cardPreviousPrice[nextAvailableCard] = 0;
        nextAvailableCard = nextAvailableCard + 1;
        getTotalCardValue();
        
    }


    function addAmbassador(address _newAmbassador) 
        onlyAdministrator()
        public
    {
        ambassadors_[_newAmbassador] = true;
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

    function myCardDividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return ownerAccounts[_customerAddress];
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
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_  ),1000);
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
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_  ),1000);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
     
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_  ),1000);
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
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_  ),1000);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
     

    function getTotalCardValue()
    internal
    view
    {
        uint counter = 1;
        uint _totalVal = 0;

        while (counter < nextAvailableCard) { 

            _totalVal = SafeMath.add(_totalVal,cardPrice[counter]);
                
            counter = counter + 1;
        } 
        totalCardValue = _totalVal;
            
    }

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        onlyActive()
        internal
        returns(uint256)
    {
         

         
        uint8 localDivFee = 200;

        lastHour = getHour(block.timestamp);
        if (getHour(block.timestamp) == alertTime1 || getHour(block.timestamp) == alertTime2 || getHour(block.timestamp) == alertTime3){
            boolAlertStatus = true;
            localDivFee = dividendFeeBuyAlert_;
        }else{
            boolAlertStatus = false;
            localDivFee = dividendFeeBuyClear_;
        }

        cardInsuranceAccount = SafeMath.add(cardInsuranceAccount, SafeMath.div(SafeMath.mul(_incomingEthereum, cardInsuranceFeeRate_), 1000));
         
        distributeYield(SafeMath.div(SafeMath.mul(_incomingEthereum,yieldDividendFeeRate_),1000));
        
        _incomingEthereum = SafeMath.sub(_incomingEthereum,SafeMath.div(SafeMath.mul(_incomingEthereum, cardInsuranceFeeRate_ + yieldDividendFeeRate_), 1000));

        uint256 _referralBonus = SafeMath.div(SafeMath.div(SafeMath.mul(_incomingEthereum, localDivFee  ),1000), 3);
        uint256 _dividends = SafeMath.sub(SafeMath.div(SafeMath.mul(_incomingEthereum, localDivFee  ),1000), _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, localDivFee),1000));
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        

 
         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != msg.sender &&
            
             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
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

        
        distributeInsurance();
        checkHalfLife();
        
         
        onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }



    function buyCard(uint _card, address _referrer)
        public
        payable
        onlyCardActive()
    {
        require(_card <= nextAvailableCard);
        require(_card > 0);
        require(msg.value >= cardPrice[_card]);
       
        cardBlockNumber[_card] = block.number;    


          
        uint _baseDividends = msg.value - cardPreviousPrice[_card];
        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

         
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends,ownerDivRate),1000);
        _ownerDividends = SafeMath.add(_ownerDividends,cardPreviousPrice[_card]);   
        uint _insuranceDividends = SafeMath.div(SafeMath.mul(_baseDividends,insuranceDivRate),1000);


         
        uint _exchangeDivs = SafeMath.div(SafeMath.mul(_baseDividends, yieldDivRate),1000);
        profitPerShare_ += (_exchangeDivs * magnitude / (tokenSupply_));

        totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card],_ownerDividends);
        
        cardInsuranceAccount = SafeMath.add(cardInsuranceAccount, _insuranceDividends);
            
        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends,distDivRate),1000);

        if (allowReferral && (_referrer != msg.sender) && (_referrer != 0x0000000000000000000000000000000000000000)) {
                
            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends,referralRate),1000);
            _distDividends = SafeMath.sub(_distDividends,_referralDividends);
            ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer],_referralDividends);
        }
            
        distributeYield(_distDividends);

         
        address _previousOwner = cardOwner[_card];
        address _newOwner = msg.sender;

        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner],_ownerDividends);
        ownerAccounts[dev] = SafeMath.add(ownerAccounts[dev],SafeMath.div(SafeMath.mul(_baseDividends,devDivRate),1000));

        cardOwner[_card] = _newOwner;

         
        cardPreviousPrice[_card] = msg.value;
        cardPrice[_card] = SafeMath.div(SafeMath.mul(msg.value,cardPriceIncrement),1000);
  
        getTotalCardValue();
        distributeInsurance();
        checkHalfLife();

        emit onCardBuy(msg.sender, msg.value, _card, SafeMath.div(SafeMath.mul(msg.value,cardPriceIncrement),1000), halfLifeTime + block.number);
     
    }


    function distributeInsurance() internal
    {
        uint counter = 1;
        uint _cardDistAmount = cardInsuranceAccount;
        cardInsuranceAccount = 0;
        uint tempInsurance = 0;

        while (counter < nextAvailableCard) { 
  
            uint _distAmountLocal = SafeMath.div(SafeMath.mul(_cardDistAmount, cardPrice[counter]),totalCardValue);
            
            cardInsurance[counter] = SafeMath.add(cardInsurance[counter], _distAmountLocal);
            tempInsurance = tempInsurance + cardInsurance[counter];
            emit onInsuranceChange(0x0, counter, cardInsurance[counter]);
    
            counter = counter + 1;
        } 
        totalCardInsurance = tempInsurance;
    }


    function distributeYield(uint _distDividends) internal
     
    {
        uint counter = 1;
        uint currentBlock = block.number;
        uint insurancePayout = 0;

        while (counter < nextAvailableCard) { 

            uint _distAmountLocal = SafeMath.div(SafeMath.mul(_distDividends, cardPrice[counter]),totalCardValue);
            ownerAccounts[cardOwner[counter]] = SafeMath.add(ownerAccounts[cardOwner[counter]],_distAmountLocal);
            totalCardDivs[counter] = SafeMath.add(totalCardDivs[counter],_distAmountLocal);

            counter = counter + 1;
        } 
        getTotalCardValue();
        checkHalfLife();
    }

    function extCheckHalfLife() 
    public
    {
        bool _boolDev = (msg.sender == dev);
        if (_boolDev || boolAllowPlayer){
            checkHalfLife();
        }
    }


    function checkHalfLife() 
    internal
    
     
    {

        uint localHalfLifeTime = 120;
         
         
        lastHour = getHour(block.timestamp);
        if (getHour(block.timestamp) == alertTime1 || getHour(block.timestamp) == alertTime2 || getHour(block.timestamp) == alertTime3){
            boolAlertStatus = true;
            localHalfLifeTime = halfLifeAlert;
        }else{
            boolAlertStatus = false;
            localHalfLifeTime = halfLifeClear;
        }




        uint counter = 1;
        uint currentBlock = block.number;
        uint insurancePayout = 0;
        uint tempInsurance = 0;

        while (counter < nextAvailableCard) { 

             
            if (allowHalfLife) {

                if (cardPrice[counter] > basePrice[counter]) {
                    uint _life = SafeMath.sub(currentBlock, cardBlockNumber[counter]);

                    if (_life > localHalfLifeTime) {
                    
                        cardBlockNumber[counter] = currentBlock;   
                        if (SafeMath.div(SafeMath.mul(cardPrice[counter], halfLifeRate),1000) < basePrice[counter]){
                            
                            cardPrice[counter] = basePrice[counter];
                            insurancePayout = SafeMath.div(SafeMath.mul(cardInsurance[counter],insurancePayoutRate),1000);
                            cardInsurance[counter] = SafeMath.sub(cardInsurance[counter],insurancePayout);
                            ownerAccounts[cardOwner[counter]] = SafeMath.add(ownerAccounts[cardOwner[counter]], insurancePayout);
                            cardPreviousPrice[counter] = SafeMath.div(SafeMath.mul(cardPrice[counter],halfLifeReductionRate),1000);
                            
                        }else{

                            cardPrice[counter] = SafeMath.div(SafeMath.mul(cardPrice[counter], halfLifeRate),1000);  
                            cardPreviousPrice[counter] = SafeMath.div(SafeMath.mul(cardPreviousPrice[counter],halfLifeReductionRate),1000);
                            insurancePayout = SafeMath.div(SafeMath.mul(cardInsurance[counter],insurancePayoutRate),1000);
                            cardInsurance[counter] = SafeMath.sub(cardInsurance[counter],insurancePayout);
                            ownerAccounts[cardOwner[counter]] = SafeMath.add(ownerAccounts[cardOwner[counter]], insurancePayout);

                        }
                        emit onInsuranceChange(0x0, counter, cardInsurance[counter]);
                        emit Halflife(cardOwner[counter], counter, cardPrice[counter], localHalfLifeTime + block.number, insurancePayout, cardInsurance[counter]);

                    }
                     
                    
                }
               
            }
            
            tempInsurance = tempInsurance + cardInsurance[counter];
            counter = counter + 1;
        } 
        totalCardInsurance = tempInsurance;
        getTotalCardValue();

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


    function getCardPrice(uint _card)
        public
        view
        returns(uint)
    {
        require(_card <= nextAvailableCard);
        return cardPrice[_card];
    }

   function getCardInsurance(uint _card)
        public
        view
        returns(uint)
    {
        require(_card <= nextAvailableCard);
        return cardInsurance[_card];
    }


    function getCardOwner(uint _card)
        public
        view
        returns(address)
    {
        require(_card <= nextAvailableCard);
        return cardOwner[_card];
    }

    function gettotalCardDivs(uint _card)
        public
        view
        returns(uint)
    {
        require(_card <= nextAvailableCard);
        return totalCardDivs[_card];
    }

    function getTotalDivsProduced()
        public
        view
        returns(uint)
    {
     
        return totalDivsProduced;
    }
    
    
     
     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function isLeapYear(uint16 year) constant returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

    function parseTimestamp(uint timestamp) internal returns (DateTime dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        dt.year = ORIGIN_YEAR;

         
        while (true) {
                if (isLeapYear(dt.year)) {
                        buf = LEAP_YEAR_IN_SECONDS;
                }
                else {
                        buf = YEAR_IN_SECONDS;
                }

                if (secondsAccountedFor + buf > timestamp) {
                        break;
                }
                dt.year += 1;
                secondsAccountedFor += buf;
        }

         
        uint8[12] monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(dt.year)) {
                monthDayCounts[1] = 29;
        }
        else {
                monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        uint secondsInMonth;
        for (i = 0; i < monthDayCounts.length; i++) {
            secondsInMonth = DAY_IN_SECONDS * monthDayCounts[i];
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i + 1;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

         
        for (i = 0; i < monthDayCounts[dt.month - 1]; i++) {
                if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                        dt.day = i + 1;
                        break;
                }
                secondsAccountedFor += DAY_IN_SECONDS;
        }

         
                for (i = 0; i < 24; i++) {
                        if (HOUR_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.hour = i;
                                break;
                        }
                        secondsAccountedFor += HOUR_IN_SECONDS;
                }

         
        for (i = 0; i < 60; i++) {
                if (MINUTE_IN_SECONDS + secondsAccountedFor > timestamp) {
                        dt.minute = i;
                        break;
                }
                secondsAccountedFor += MINUTE_IN_SECONDS;
        }

        if (timestamp - secondsAccountedFor > 60) {
                __throw();
        }

         
        dt.second = uint8(timestamp - secondsAccountedFor);

          
        buf = timestamp / DAY_IN_SECONDS;
        dt.weekday = uint8((buf + 3) % 7);
        }

        function getYear(uint timestamp) constant returns (uint16) {
                return parseTimestamp(timestamp).year;
        }

        function getMonth(uint timestamp) constant returns (uint16) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) constant returns (uint16) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) constant returns (uint16) {
                return parseTimestamp(timestamp).hour;
        }

        function getMinute(uint timestamp) constant returns (uint16) {
                return parseTimestamp(timestamp).minute;
        }

        function getSecond(uint timestamp) constant returns (uint16) {
                return parseTimestamp(timestamp).second;
        }

        function getWeekday(uint timestamp) constant returns (uint8) {
                return parseTimestamp(timestamp).weekday;
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) constant returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) constant returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) constant returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) constant returns (uint timestamp) {
                uint16 i;

                 
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                 
                uint8[12] monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                 
                timestamp += DAY_IN_SECONDS * (day - 1);

                 
                timestamp += HOUR_IN_SECONDS * (hour);

                 
                timestamp += MINUTE_IN_SECONDS * (minute);

                 
                timestamp += second;

                return timestamp;
        }

        function __throw() {
                uint[] arst;
                arst[1];
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