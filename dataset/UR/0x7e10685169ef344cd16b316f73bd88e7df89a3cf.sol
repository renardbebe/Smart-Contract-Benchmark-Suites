 

pragma solidity ^0.4.24;

 

 
library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

 

 


contract Hourglass {
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    
     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
         
        require(administrators[msg.sender], "must in administrators");
        _;
    }
    
    
    modifier ceilingNotReached() {
        require(okamiCurrentPurchase_ < okamiTotalPurchase_);
        _;
    }  

    modifier isActivated() {
        require(activated == true, "its not ready yet"); 
        _;
    }

    modifier isInICO() {
        require(inICO == true, "its not in ICO."); 
        _;
    }

    modifier isNotInICO() {
        require(inICO == false, "its not in ICO."); 
        _;
    }

     
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);
        
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
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
    
    
     
    string public name = "OkamiPK";
    string public symbol = "OPK";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    uint256 constant internal tokenPriceInitial_ =  0.0007 ether;  
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    uint256 constant public icoPrice_ = 0.002 ether; 
     
    uint256 public stakingRequirement = 100e18;
    
     

     
    uint256 constant public okamiMinPurchase_ = 5 ether;
    uint256 constant public okamiMaxPurchase_ = 10 ether;
    uint256 constant public okamiTotalPurchase_ = 500 ether;
    
    mapping(address => uint256) internal okamis_;
    uint256 public okamiCurrentPurchase_ = 0;
    
    bool public inICO = false;
    bool public activated = false;
    
    
     
     
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_;
    mapping(address => int256) public payoutsTo_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
     
    mapping(address => bool) public administrators;
    
     
     
    mapping(address => uint256) public okamiFunds_;

     
     
    constructor()
        public
    {
         
         
         
         
        administrators[0x00A32C09c8962AEc444ABde1991469eD0a9ccAf7] = true;
        administrators[0x00aBBff93b10Ece374B14abb70c4e588BA1F799F] = true;
                    
         
        uint256 count = SafeMath.mul(SafeMath.div(10**18, icoPrice_), 10**18);

        tokenBalanceLedger_[0x0a3Ed0E874b4E0f7243937cD0545bFEcBa0f4548] = 50*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 50*count);

        tokenBalanceLedger_[0x00c9d3bd82fEa0464DC284Ca870A76eE7386C63d] = 30*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 30*count);

        tokenBalanceLedger_[0x00De30E1A0E82750ea1f96f6D27e112f5c8A352D] = 10*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 10*count);

        tokenBalanceLedger_[0x0070349db8EF73DeF5A1Aa838B7d81FD0742867b] = 4*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 4*count);

         
        tokenBalanceLedger_[0x26042eb2f06D419093313ae2486fb40167Ba349C] = 1*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 1*count);
        tokenBalanceLedger_[0x8d60d529c435e2A4c67FD233c49C3F174AfC72A8] = 1*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 1*count);
        tokenBalanceLedger_[0xF9f24b9a5FcFf3542Ae3361c394AD951a8C0B3e1] = 1*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 1*count);
        tokenBalanceLedger_[0x9ca974f2c49d68bd5958978e81151e6831290f57] = 1*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 1*count);
        tokenBalanceLedger_[0xf22978ed49631b68409a16afa8e123674115011e] = 1*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 1*count);
        tokenBalanceLedger_[0x00b22a1D6CFF93831Cf2842993eFBB2181ad78de] = 1*count;
        tokenSupply_ = SafeMath.add(tokenSupply_, 1*count);

    }
    
    function activate()
        onlyAdministrator()
        public
    {

         
        require(activated == false, "already activated");
        
         
        activated = true;
        
        inICO = true;
    }

    function endICO()
        onlyAdministrator()
        public
    {

         
        require(inICO == true, "must true before");
        
        inICO = false;
        
    }


     
    function buy(address _referredBy)
        isActivated()
        isHuman()
        public
        payable
        returns(uint256)
    {
        if( inICO){
            purchaseTokensInICO(msg.value, _referredBy);
        }else{
            purchaseTokens(msg.value, _referredBy);
        }
    }
    
     
    function()
        isActivated()
        isHuman()
        payable
        public
    {
        if( inICO){
            purchaseTokensInICO(msg.value, 0x0);
        }else{
            purchaseTokens(msg.value, 0x0);
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
        isNotInICO()
        onlyBagholders()
        public
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
         
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
        isNotInICO()
        onlyBagholders()
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;
        
         
         
         
        require(!inICO && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
         
        if(myDividends(true) > 0) withdraw();
        
         
         
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
  
         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        
         
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        
         
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        
         
        return true;
       
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
    
    
    function purchaseTokensInICO(uint256 _incomingEthereum, address _referredBy)
        isInICO()
        ceilingNotReached()
        internal
        returns(uint256)
    {   
        address _customerAddress = msg.sender;
        uint256 _oldFundETH = okamiFunds_[_customerAddress];

        require(_incomingEthereum > 0, "no money");
        require( (_oldFundETH >= okamiMinPurchase_) || _incomingEthereum >= okamiMinPurchase_, "min 5 eth");
        require(SafeMath.add(_oldFundETH, _incomingEthereum) <= okamiMaxPurchase_, "max 10 eth");

        uint256 _newFundETH = _incomingEthereum;
        if( SafeMath.add(_newFundETH, okamiCurrentPurchase_) > okamiTotalPurchase_){
            _newFundETH = SafeMath.sub(okamiTotalPurchase_, okamiCurrentPurchase_);
            msg.sender.transfer(SafeMath.sub(_incomingEthereum, _newFundETH));
        }

        uint256 _amountOfTokens =  SafeMath.mul(SafeMath.div(_newFundETH, icoPrice_), 10**18);

         
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        okamiFunds_[_customerAddress]  = SafeMath.add(okamiFunds_[_customerAddress], _newFundETH);
        okamiCurrentPurchase_ = SafeMath.add(okamiCurrentPurchase_, _newFundETH);

        if( okamiCurrentPurchase_ >= okamiTotalPurchase_){
            inICO = false;
        }

         
        emit onTokenPurchase(_customerAddress, _newFundETH, _amountOfTokens, _referredBy);
        
    }


     
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        isNotInICO()
        internal
        returns(uint256)
    {
         
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _customerAddress &&
            
             
             
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
        
         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
         
         
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
         
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        
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