 

pragma solidity ^0.4.23;



contract Rocket {
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
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
    
    bool onlyAmbassadors = true;
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 0.5 ether;
    uint256 constant internal ambassadorQuota_ = 20 ether;
        
    
    
     
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
    
    
     
    string public name = "Rocket";
    string public symbol = "RCKT";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 5;  
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
     
    uint256 public stakingRequirement = 100e18;
     

    
    uint256 public Timer;
    uint16 constant public JackpotTimer = 30 minutes;
    address public Jackpot;
    uint256 public JackpotAmount;
    
    uint8 constant JackpotCut = 4;  
    uint8 constant JackpotPay = 80;  
    uint16 constant JackpotMinBuyin = 1000;  
    uint256 constant JackpotMinBuyingConst = 10 finney; 
    uint256 constant MaxBuyInMin = 1 ether;
    uint8 constant MaxBuyInCut = 10;  
    

    



    
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
     
    mapping(address => bool) public administrators;
    
 
    


     
     
    constructor()
        public
        payable
    {
         

        administrators[msg.sender] = true;
        ambassadors_[msg.sender]=true;
        ambassadors_[0x8CA47715Be8AC08aF165a628Ab8111bB3FeF38f1]=true;
        ambassadors_[0xbAB0308B1CBf9d66f0171581556807b08B3f5860]=true;
        ambassadors_[0x69FE700236B3F5A32A878c1c1243169C6851d25B]=true;
        ambassadors_[0x703b16787180a94c2f9f2510F08eDB59Aa899568]=true;
        ambassadors_[0x05f2c11996d73288AbE8a31d8b593a693FF2E5D8]=true;
        ambassadors_[0xe2C28fe6279F882B432d79436fc85131bbD8e369]=true;
        
        buy(0x0);
    }
    
    function donateJackpot() public payable{
        JackpotAmount = JackpotAmount + msg.value;
    }
    
     
     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        require(msg.value <= GetMaxBuyIn());

        purchaseTokens(msg.value, _referredBy);
    }
    
     
    function()
        payable
        public
    {
        require(msg.value <= GetMaxBuyIn());

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
        uint256 _undividedDividends = SafeMath.div(_ethereum, dividendFee_);

        uint256 _jackpotAmount = SafeMath.div(_undividedDividends, JackpotCut);
        JackpotAmount = SafeMath.add(JackpotAmount,  _jackpotAmount);
        uint256 _dividends = SafeMath.sub(_undividedDividends,_jackpotAmount);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _undividedDividends);
        
         
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
         
        address _customerAddress = msg.sender;
        
         
         
         
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
         
        if(myDividends(true) > 0) withdraw();

         
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
    
    function GetJackpotMin() public view returns (uint){
        uint Ret = SafeMath.div(totalEthereumBalance(),(JackpotMinBuyin));
        if (Ret < JackpotMinBuyingConst){
            return JackpotMinBuyingConst;
        }
        return Ret;
    }
    
    function GetMaxBuyIn() public view returns (uint){
        uint Ret = SafeMath.div(totalEthereumBalance(),(MaxBuyInCut));
        if (Ret < MaxBuyInMin){
            return MaxBuyInMin;
        }
        return Ret;
    }

    
     
     
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
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
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
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
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
     
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
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
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    function PayJackpot() public{
        if (block.timestamp > Timer && Jackpot != address(0x0)){
            uint256 pay = (SafeMath.div(SafeMath.mul(JackpotAmount, JackpotPay), 100));
            referralBalance_[Jackpot] += pay; 
            Jackpot = address(0x0);
            JackpotAmount = SafeMath.sub(JackpotAmount, (uint256) (pay));
        }
    }
    
     
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        internal
        antiEarlyWhale(_incomingEthereum)
        returns(uint256)
    {
      
        if (block.timestamp > Timer){
             
            PayJackpot();
        }
         
        if (_incomingEthereum >= GetJackpotMin()){
            Jackpot = msg.sender;
            Timer = block.timestamp + JackpotTimer;
        }
         

        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);

        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        if ((_referredBy != 0x0000000000000000000000000000000000000000 && _referredBy != msg.sender && tokenBalanceLedger_[_referredBy] >= stakingRequirement)){
            
        }
        else{
            _referralBonus = 0;
        }
        uint256 _jackpotAmount = SafeMath.div(SafeMath.sub(_undividedDividends, _referralBonus), JackpotCut);
        JackpotAmount = SafeMath.add(JackpotAmount,  _jackpotAmount);
        uint256 _dividends = SafeMath.sub(SafeMath.sub(_undividedDividends, _referralBonus),_jackpotAmount);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
         
        if(
             (_referredBy != 0x0000000000000000000000000000000000000000 && _referredBy != msg.sender && tokenBalanceLedger_[_referredBy] >= stakingRequirement)
        ){
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
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