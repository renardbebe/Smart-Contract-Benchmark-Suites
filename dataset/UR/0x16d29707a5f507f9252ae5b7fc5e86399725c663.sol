 

pragma solidity ^0.4.24;


 
 
 
 
contract MZBoss {
     
     
    modifier transferCheck(uint256 _amountOfTokens) {
        address _customerAddress = msg.sender;
        require((_amountOfTokens > 0) && (_amountOfTokens <= tokenBalanceLedger_[_customerAddress]));
        _;
    }
    
     
    modifier onlyStronghands() {
        address _customerAddress = msg.sender;
        require(dividendsOf(_customerAddress) > 0);
        _;
    }
    
     
    modifier enoughToreinvest() {
        address _customerAddress = msg.sender;
        uint256 priceForOne = (tokenPriceInitial_*100)/85;
        require((dividendsOf(_customerAddress) >= priceForOne) && (_tokenLeft >= calculateTokensReceived(dividendsOf(_customerAddress))));
        _; 
    } 
    
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress] == true);
        _;
    }
    
     
    modifier enoughToBuytoken (){
        uint256 _amountOfEthereum = msg.value;
        uint256 priceForOne = (tokenPriceInitial_*100)/85;
        require((_amountOfEthereum >= priceForOne) && (_tokenLeft >= calculateTokensReceived(_amountOfEthereum)));
        _; 
    } 
    
     
    
    event OnTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensBought,
        uint256 tokenSupplyUpdate,
        uint256 tokenLeftUpdate
    );
    
    event OnTokenSell(
        address indexed customerAddress,
        uint256 tokensSold,
        uint256 ethereumEarned,
        uint256 tokenSupplyUpdate,
        uint256 tokenLeftUpdate
    );
    
    event OnReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensBought,
        uint256 tokenSupplyUpdate,
        uint256 tokenLeftUpdate
    );
    
    event OnWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    
     
    event OnTotalProfitPot(
        uint256 _totalProfitPot
    );
    
     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
     
    string public name = "Mizhen";
    string public symbol = "MZBoss";
    uint256 constant public totalToken = 21000000e18;  
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;  
    uint8 constant internal toCommunity_ = 5;  
    uint256 constant internal tokenPriceInitial_ = 5e15;  
    uint256 constant internal magnitude = 1e18;  

    
     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 1e19;
    uint256 constant internal ambassadorQuota_ = 1e19;
    
     
    mapping(address => bool) public exchangeAddress_;
    
    
     
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;

    uint256 public tokenSupply_ = 0;  
    uint256 public _tokenLeft = 21000000e18;
    uint256 public totalEthereumBalance1 = 0;
    uint256 public profitPerShare_ = 0 ;

    uint256 public _totalProfitPot = 0;
    address constant internal _communityAddress = 0x43e8587aCcE957629C9FD2185dD700dcDdE1dD1E;
    
     
    mapping(address => bool) public administrators;
    
     
    bool public onlyAmbassadors = true;


     
     
    constructor ()
        public
    
    {
         
        administrators[0x6dAd1d9D24674bC9199237F93beb6E25b55Ec763] = true;

         
        ambassadors_[0x64BFD8F0F51569AEbeBE6AD2a1418462bCBeD842] = true;
    }
    
    function purchaseTokens()  
        enoughToBuytoken ()
        public
        payable
    {
           address _customerAddress = msg.sender;
           uint256 _amountOfEthereum = msg.value;
        
         
        if( onlyAmbassadors && (SafeMath.sub(totalEthereumBalance(), _amountOfEthereum) < ambassadorQuota_ )){ 
            require(
                 
                (ambassadors_[_customerAddress] == true) &&
                
                 
                (SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum) <= ambassadorMaxPurchase_)
            );
            
             
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
            
            totalEthereumBalance1 = SafeMath.add(totalEthereumBalance1, _amountOfEthereum);
            uint256 _amountOfTokens = ethereumToTokens_(_amountOfEthereum); 
            
            tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
            
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens); 
            
            _tokenLeft = SafeMath.sub(totalToken, tokenSupply_); 
            
            emit OnTokenPurchase(_customerAddress, _amountOfEthereum, _amountOfTokens, tokenSupply_, _tokenLeft);
         
        } 
        
        else {
             
            onlyAmbassadors = false;
            
            purchaseTokensAfter(_amountOfEthereum); 
                
        }
        
    }
    
     
    function potDistribution()
        public
        payable
    {
         
        require(msg.value > 0);
        uint256 _incomingEthereum = msg.value;
        if(tokenSupply_ > 0){
            
             
            uint256 profitPerSharePot_ = SafeMath.mul(_incomingEthereum, magnitude) / (tokenSupply_);
            
             
            profitPerShare_ = SafeMath.add(profitPerShare_, profitPerSharePot_);
            
        } else {
             
            payoutsTo_[_communityAddress] -=  (int256) (_incomingEthereum);
            
        }
        
         
        _totalProfitPot = SafeMath.add(_incomingEthereum, _totalProfitPot); 
    }
    
     
    function reinvest()
        enoughToreinvest()
        public
    {
        
         
        address _customerAddress = msg.sender;
        
         
        uint256 _dividends = dividendsOf(_customerAddress); 
        
        uint256 priceForOne = (tokenPriceInitial_*100)/85;
        
         
        if (_dividends >= priceForOne) { 
        
         
        purchaseTokensAfter(_dividends);
            
        payoutsTo_[_customerAddress] +=  (int256) (_dividends);
        
        }
        
    }
    
     
    function withdraw()
        onlyStronghands()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = dividendsOf(_customerAddress); 
        
         
        payoutsTo_[_customerAddress] +=  (int256) (_dividends);

        
         
        _customerAddress.transfer(_dividends);
        
         
        emit OnWithdraw(_customerAddress, _dividends);
    }
    
     
    function sell(uint256 _amountOfTokens)
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, 0);  
        
        require((tokenBalanceLedger_[_customerAddress] >= _amountOfTokens) && ( totalEthereumBalance1 >= _taxedEthereum ) && (_amountOfTokens > 0));
        
         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        totalEthereumBalance1 = SafeMath.sub(totalEthereumBalance1, _taxedEthereum);
        
         
        int256 _updatedPayouts = (int256) (SafeMath.add(SafeMath.mul(profitPerShare_, _tokens)/magnitude, _taxedEthereum));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        _tokenLeft = SafeMath.sub(totalToken, tokenSupply_);
        
         
        emit OnTokenSell(_customerAddress, _tokens, _taxedEthereum, tokenSupply_, _tokenLeft);
    }
    
     
    function transfer(uint256 _amountOfTokens, address _toAddress)
        transferCheck(_amountOfTokens)
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;

         
        if(dividendsOf(_customerAddress) > 0) withdraw();

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        
         
        payoutsTo_[_customerAddress] -= (int256) (SafeMath.mul(profitPerShare_ , _amountOfTokens)/magnitude);
        payoutsTo_[_toAddress] += (int256) (SafeMath.mul(profitPerShare_ , _amountOfTokens)/magnitude);
        
         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        
         
        return true;
       
    }

    
     
     
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
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
        return address(this).balance;
    }
    
     
    function tokenSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
    
     
    function balanceOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    
     
    function payoutsTo(address _customerAddress)
        public
        view
        returns(int256)
    {
        return payoutsTo_[_customerAddress];
    }
    
     
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
     
    function dividendsOf(address _customerAddress)
        public 
        view
        returns(uint256)
    {
        
        uint256 _TokensEther = tokenBalanceLedger_[_customerAddress];
        
        if ((int256(SafeMath.mul(profitPerShare_, _TokensEther)/magnitude) - payoutsTo_[_customerAddress]) > 0 )
           return uint256(int256(SafeMath.mul(profitPerShare_, _TokensEther)/magnitude) - payoutsTo_[_customerAddress]);  
        else 
           return 0;
    }

    
     
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        pure 
        returns(uint256)
    {
        uint256 _dividends = SafeMath.mul(_ethereumToSpend, dividendFee_) / 100;
        uint256 _communityDistribution = SafeMath.mul(_ethereumToSpend, toCommunity_) / 100;
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, SafeMath.add(_communityDistribution,_dividends));
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }
    
     
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        pure 
        returns(uint256)
    {
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, 0);  
        return _taxedEthereum;
    }
    

     
    function purchaseTokensAfter(uint256 _incomingEthereum) 
        private
    {
         
        address _customerAddress = msg.sender;
        
         
        uint256 _dividends = SafeMath.mul(_incomingEthereum, dividendFee_) / 100; 
        
         
        uint256 _communityDistribution = SafeMath.mul(_incomingEthereum, toCommunity_) / 100;
        
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, SafeMath.add(_communityDistribution, _dividends));
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum); 

         
         
        require((_amountOfTokens >= 1e18) && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_)); 

        
         
         
        
        if (tokenSupply_ == 0){
            
            uint256 profitPerShareNew_ = 0;
        }else{
            
            profitPerShareNew_ = SafeMath.mul(_dividends, magnitude) / (tokenSupply_); 
        } 
        
         
        profitPerShare_ = SafeMath.add(profitPerShare_, profitPerShareNew_); 
        
         
        uint256 _dividendsAssumed = SafeMath.div(SafeMath.mul(profitPerShare_, _amountOfTokens), magnitude);
            
         
         
        uint256 _dividendsExtra = _dividendsAssumed;
        
        
         
        payoutsTo_[_customerAddress] += (int256) (_dividendsExtra);
            
         
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens); 
            
        _tokenLeft = SafeMath.sub(totalToken, tokenSupply_);
        totalEthereumBalance1 = SafeMath.add(totalEthereumBalance1, _taxedEthereum);
        
         
        _communityAddress.transfer(_communityDistribution);
        
         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
         
        emit OnTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, tokenSupply_, _tokenLeft);
    }

     
    function ethereumToTokens_(uint256 _ethereum)
        internal
        pure
        returns(uint256)
    {
        require (_ethereum > 0);
        uint256 _tokenPriceInitial = tokenPriceInitial_;
        
        uint256 _tokensReceived = SafeMath.mul(_ethereum, magnitude) / _tokenPriceInitial;
                    
        return _tokensReceived;
    }
    
     
     function tokensToEthereum_(uint256 _tokens)
        internal
        pure
        returns(uint256)
    {   
        uint256 tokens_ = _tokens;
        
        uint256 _etherReceived = SafeMath.mul (tokenPriceInitial_, tokens_) / magnitude;
            
        return _etherReceived;
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