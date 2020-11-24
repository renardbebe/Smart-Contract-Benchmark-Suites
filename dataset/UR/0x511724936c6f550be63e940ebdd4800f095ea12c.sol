 

pragma solidity ^0.4.21;

 

contract AcceptsExchange {
    cryptowars public tokenContract;

    function AcceptsExchange(address _tokenContract) public {
        tokenContract = cryptowars(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
    function tokenFallbackExpanded(address _from, uint256 _value, bytes _data, address _sender, address _referrer) external returns (bool);
}

contract cryptowars {
     
     
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
    
     
    string public name = "CryptoWars";
    string public symbol = "JEDI";
    uint8 constant public decimals = 18;
    uint256 constant internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000001 ether;
    uint256 constant internal magnitude = 2**64;
    
     
    uint256 public stakingRequirement = 100e18;
    
     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 3 ether;
    uint256 constant internal ambassadorQuota_ = 20 ether;
    
    address dev;

    uint nextAvailableCard;

    address add2 = 0x0;

    uint public totalCardValue = 0;

    uint public totalCardInsurance = 0;

    bool public boolAllowPlayer = false;
    
    
    
     
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

     
    uint public ownerDivRate = 500;
    uint public distDivRate = 400;
    uint public devDivRate = 50;
    uint public insuranceDivRate = 50;
    uint public referralRate = 50;
    



    mapping(uint => uint) internal cardBlockNumber;

    uint public halfLifeTime = 5900;             
    uint public halfLifeRate = 900;              
    uint public halfLifeReductionRate = 667;     

    bool public allowHalfLife = true;   

    bool public allowReferral = false;   

    uint public insurancePayoutRate = 250;  

   
    address inv1 = 0x387E7E1580BbE37a06d847985faD20f353bBeB1b;
    address inv2 = 0xD87fA3D0cF18fD2C14Aa34BcdeaF252Bf4d56644;
    address inv3 = 0xc4166D533336cf49b85b3897D7315F5bB60E420b;


    uint8 public dividendFee_ = 200;  
    uint8 public cardInsuranceFeeRate_ = 20; 
    uint8 public investorFeeRate_ = 10; 

    uint public maxCards = 50;

    bool public boolContractActive = false;
    bool public boolCardActive = false;

     
    mapping(address => bool) public administrators;
    
     
    bool public onlyAmbassadors = true;

       
    mapping(address => bool) public canAcceptTokens_;  


     
     
    function cryptowars()
        public
    {
        allowHalfLife = true;
        allowReferral = false;

         
        administrators[msg.sender] = true;

        dev = msg.sender;

        ambassadors_[dev] = true;
        ambassadors_[inv1] = true;
        ambassadors_[inv2] = true;
        ambassadors_[inv3] = true;

        ambassadors_[0x96762288ebb2560a19F8eAdAaa2012504F64278B] = true;
        ambassadors_[0x5145A296e1bB9d4Cf468d6d97d7B6D15700f39EF] = true;
        ambassadors_[0xE74b1ea522B9d558C8e8719c3b1C4A9050b531CA] = true;
        ambassadors_[0xb62A0AC2338C227748E3Ce16d137C6282c9870cF] = true;
        ambassadors_[0x836e5abac615b371efce0ab399c22a04c1db5ecf] = true;
        ambassadors_[0xAe3dC7FA07F9dD030fa56C027E90998eD9Fe9D61] = true;
        ambassadors_[0x38602d1446fe063444B04C3CA5eCDe0cbA104240] = true;
        ambassadors_[0x3825c8BA07166f34cE9a2cD1e08A68b105c82cB9] = true;
        ambassadors_[0xa6662191F558e4C611c8f14b50c784EDA9Ace98d] = true;
        

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

        cardOwner[6] = 0xb62A0AC2338C227748E3Ce16d137C6282c9870cF;
        cardPrice[6] = 1 ether;
        basePrice[6] = cardPrice[6];
        cardPreviousPrice[6] = 0;

        cardOwner[7] = 0x96762288ebb2560a19f8eadaaa2012504f64278b;
        cardPrice[7] = 0.8 ether;
        basePrice[7] = cardPrice[7];
        cardPreviousPrice[7] = 0;

        cardOwner[8] = 0x836e5abac615b371efce0ab399c22a04c1db5ecf;
        cardPrice[8] = 0.6 ether;
        basePrice[8] = cardPrice[8];
        cardPreviousPrice[8] = 0;

        cardOwner[9] = 0xAe3dC7FA07F9dD030fa56C027E90998eD9Fe9D61;
        cardPrice[9] = 0.4 ether;
        basePrice[9] = cardPrice[9];
        cardPreviousPrice[9] = 0;

        cardOwner[10] = dev;
        cardPrice[10] = 0.2 ether;
        basePrice[10] = cardPrice[10];
        cardPreviousPrice[10] = 0;

        cardOwner[11] = dev;
        cardPrice[11] = 0.1 ether;
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
        
         
        _dividends += referralBalance_[_customerAddress] + ownerAccounts[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        ownerAccounts[_customerAddress] = 0;
        
         
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
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_),1000);
        
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
        
         
         
         
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
         
        if(myDividends(true) > 0) withdraw();
        
         
         
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, dividendFee_),1000);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
  
         
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
    {
        allowHalfLife = _allow;
    
    }

    function setAllowReferral(bool _allow)
        onlyAdministrator()
    {
        allowReferral = _allow;
    
    }

    function setInv1(address _newInvestorAddress)
        onlyAdministrator()
        public
    {
        inv1 = _newInvestorAddress;
    }

    function setInv2(address _newInvestorAddress)
        onlyAdministrator()
        public
    {
        inv2 = _newInvestorAddress;
    }

    function setInv3(address _newInvestorAddress)
        onlyAdministrator()
        public
    {
        inv3 = _newInvestorAddress;
    }

     
    function setFeeRates(uint8 _newDivRate, uint8 _newInvestorFee, uint8 _newCardFee)
        onlyAdministrator()
        public
    {
        require(_newDivRate <= 250);
        require(_newInvestorFee + _newCardFee <= 50);   

        dividendFee_ = _newDivRate;
        investorFeeRate_ = _newInvestorFee;
        cardInsuranceFeeRate_ = _newCardFee;
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
    
    
     


    function getNextAvailableCard()
        public
        view
        returns(uint)
    {
        return nextAvailableCard;
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
         

        cardInsuranceAccount = SafeMath.add(cardInsuranceAccount, SafeMath.div(SafeMath.mul(_incomingEthereum, cardInsuranceFeeRate_), 1000));
        ownerAccounts[inv1] = SafeMath.add(ownerAccounts[inv1] , SafeMath.div(SafeMath.mul(_incomingEthereum, investorFeeRate_), 1000));
        ownerAccounts[inv2] = SafeMath.add(ownerAccounts[inv2] , SafeMath.div(SafeMath.mul(_incomingEthereum, investorFeeRate_), 1000));
        ownerAccounts[inv3] = SafeMath.add(ownerAccounts[inv3] , SafeMath.div(SafeMath.mul(_incomingEthereum, investorFeeRate_), 1000));


        _incomingEthereum = SafeMath.sub(_incomingEthereum,SafeMath.div(SafeMath.mul(_incomingEthereum, cardInsuranceFeeRate_), 1000) + SafeMath.div(SafeMath.mul(_incomingEthereum, investorFeeRate_), 1000)*3);

      
        uint256 _referralBonus = SafeMath.div(SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_  ),1000), 3);
        uint256 _dividends = SafeMath.sub(SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_  ),1000), _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_  ),1000));
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

        uint counter = 1;
        uint currentBlock = block.number;
        uint insurancePayout = 0;
        uint tempInsurance = 0;

        while (counter < nextAvailableCard) { 

             
            if (allowHalfLife) {

                if (cardPrice[counter] > basePrice[counter]) {
                    uint _life = SafeMath.sub(currentBlock, cardBlockNumber[counter]);

                    if (_life > halfLifeTime) {
                    
                        cardBlockNumber[counter] = currentBlock;   
                        if (SafeMath.div(SafeMath.mul(cardPrice[counter], halfLifeRate),1000) < basePrice[counter]){
                            
                            cardPrice[counter] = basePrice[counter];
                            insurancePayout = SafeMath.div(SafeMath.mul(cardInsurance[counter],insurancePayoutRate),1000);
                            cardInsurance[counter] = SafeMath.sub(cardInsurance[counter],insurancePayout);
                            ownerAccounts[cardOwner[counter]] = SafeMath.add(ownerAccounts[cardOwner[counter]], insurancePayout);
                            
                        }else{

                            cardPrice[counter] = SafeMath.div(SafeMath.mul(cardPrice[counter], halfLifeRate),1000);  
                            cardPreviousPrice[counter] = SafeMath.div(SafeMath.mul(cardPrice[counter],halfLifeReductionRate),1000);

                            insurancePayout = SafeMath.div(SafeMath.mul(cardInsurance[counter],insurancePayoutRate),1000);
                            cardInsurance[counter] = SafeMath.sub(cardInsurance[counter],insurancePayout);
                            ownerAccounts[cardOwner[counter]] = SafeMath.add(ownerAccounts[cardOwner[counter]], insurancePayout);

                        }
                        emit onInsuranceChange(0x0, counter, cardInsurance[counter]);
                        emit Halflife(cardOwner[counter], counter, cardPrice[counter], halfLifeTime + block.number, insurancePayout, cardInsurance[counter]);

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