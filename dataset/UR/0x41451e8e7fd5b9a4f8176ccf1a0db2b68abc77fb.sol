 

pragma solidity ^0.4.21;

 

contract FART {
     
     
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyNonFounders() {
        require(!foundingFARTers_[msg.sender]);
        _;
    }
    
     
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    
     
    modifier areWeLive(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
         
        if( onlyFounders && ((totalEthereumBalance() - _amountOfEthereum) <= preLiveTeamFoundersMaxPurchase_ )){
            require(
                 
                foundingFARTers_[_customerAddress] == true &&
                
                 
                (contractQuotaToGoLive_[_customerAddress] + _amountOfEthereum) <= preLiveIndividualFoundersMaxPurchase_
                
            );
            
             
            contractQuotaToGoLive_[_customerAddress] = SafeMath.add(contractQuotaToGoLive_[_customerAddress], _amountOfEthereum);
        
             
            _;
        } else {
             
            onlyFounders = false;
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
    
    
     
    string public name = "FART";
    string public symbol = "FART";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 7;  
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
     
    uint256 public referralLinkMinimum = 20e18; 
    
     
    mapping(address => bool) internal foundingFARTers_;
    uint256 constant internal preLiveIndividualFoundersMaxPurchase_ = 2 ether;  
    uint256 constant internal preLiveTeamFoundersMaxPurchase_ = 1 ether;  
    
    
    
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal contractQuotaToGoLive_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
     
    mapping(bytes32 => bool) public administrators;
    
     
    bool public onlyFounders = true;
    


     
     
    function FART()
        public
    {
        
         
        
        
         
         
        foundingFARTers_[0x7e474fe5Cfb720804860215f407111183cbc2f85] = true;  
    }
    
     
     
    function buy(address _referredBy, address _charity)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy, _charity);
    }
    
     
    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0, 0x0);
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
        
         
        uint256 _tokens = purchaseTokens(_dividends, 0x0, 0x0);
        
         
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
     
    function eject()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens, 0x0);
        
         
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
    
 
    
     
    function sell(uint256 _amountOfTokens, address _charity)
        onlyTokenHolders()  
        onlyNonFounders()  
        public {
             
            address _customerAddress = msg.sender;
            require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
            uint256 _tokens = _amountOfTokens;
            uint256 _ethereum = tokensToEthereum_(_tokens);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
            uint256 _charityDividends = 0;
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            
            if(_charity != 0x0000000000000000000000000000000000000000 && _charity != _customerAddress) 
            {     _charityDividends = SafeMath.div(_dividends, 3);  
                 _dividends = SafeMath.sub(_dividends, _charityDividends);  
            }
           
             
            tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
            tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
            
             
            int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
            payoutsTo_[_customerAddress] -= _updatedPayouts;       
            
             
            if (tokenSupply_ > 0) {
                 
                profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
            }
            
             
            emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
            if(_charityDividends > 0) {
                 
                _charity.transfer(_charityDividends);
            }
        }
    
    
     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyTokenHolders()  
        onlyNonFounders()  
        public
        returns(bool) {
        
             
            address _customerAddress = msg.sender;
            
             
             
             
            require(!onlyFounders && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
            
             
            if(myDividends(true) > 0) withdraw();
    
             
            tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
            tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
            
             
            emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
            
             
            return true;
           
        }
    
     
     
    function totalEthereumBalance()
        public
        view
        returns(uint) {
        return address (this).balance;
    }
    
     
    function totalSupply()
        public
        view
        returns(uint256) {
        return tokenSupply_;
    }
    
     
    function myTokens()
        public
        view
        returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
      
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
     
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
     
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256) {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
     
    function sellPrice() 
        public 
        view 
        returns(uint256) {
         
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
        returns(uint256) {
         
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
        returns(uint256) {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }
    
     
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
     
     function purchaseTokens(uint256 _incomingEthereum, address _referredBy, address _charity)
        areWeLive(_incomingEthereum)
        internal
        returns(uint256) {
         
       
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(SafeMath.sub(_undividedDividends, _referralBonus), _referralBonus);   
        uint256 _amountOfTokens = ethereumToTokens_(SafeMath.sub(_incomingEthereum, _undividedDividends));
        uint256 _fee = _dividends * magnitude;
        bool charity = false;
 
         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != msg.sender &&
            
             
             
            tokenBalanceLedger_[_referredBy] >= referralLinkMinimum
        ){
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
             
             
            _dividends = SafeMath.add(_dividends, SafeMath.div(_undividedDividends, 3));
            _fee = _dividends * magnitude;
        }
        
         
        if(
             
            _charity != 0x0000000000000000000000000000000000000000 &&

             
            _charity != msg.sender 
        ){
             
            charity = true;
          
            
            
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
        
        
         
        emit onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy);
        if(charity) {
          
        _charity.transfer(_referralBonus);
        }
        
        return _amountOfTokens;
    }
    

     
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256) {
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
        returns(uint256) {

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