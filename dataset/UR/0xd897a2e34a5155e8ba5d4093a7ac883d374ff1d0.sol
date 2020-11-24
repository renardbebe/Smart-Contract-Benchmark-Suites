 

pragma solidity ^0.4.20;
 
 
 
contract IronHandsCommerce {
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
     
    modifier onlyStronghands() {
        require(myDividends() > 0);
        _;
    }
    
     
    modifier onlyTarifed() {
        address _customerAddress = msg.sender;
        require(tarif[_customerAddress] != 0);
        _;
    }
    
     
    modifier noContracts {
        require(msg.sender == tx.origin);
        _;
    }
    
     
    modifier isStarted {
        require(now >= disableTime);
        _;
    }
    
     
     
     
     
     
     
     
     
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
 
 
     
     
     
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
         
        if(administrators[msg.sender] == true) {
            _;
        }
         
        else {
             
             
            if( onlyAmbassadors ){
                require(
                     
                    ambassadors_[_customerAddress] == true &&
     
                     
                    (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
     
                );
     
                 
                ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
     
                 
                _;
            }
            else {
                _;
            }
        }
    }
 
 
     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted
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
    
 
 
     
    string public name = "IronHandsCommerce";
    string public symbol = "IHC";
    uint8 constant public decimals = 18;
    mapping(address => uint256) internal tarif;  
    uint256 constant internal tarifMin = 5;
    uint256 constant internal tarifMax = 45;
    uint256 constant internal tarifDiff = 50;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 0.1 ether;
    uint256 constant internal timeToStart = 300 seconds;
    uint256 public disableTime = 0;
    
    
    
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
 
     
    mapping(address => bool) public administrators;
 
     
    bool public onlyAmbassadors = true;
 
 
 
     
     
    constructor()
        public
    {
         
        administrators[0xc124DB59B549792e05Ab3562314eD370b90F7D42] = true;
    }
 
     
    function buy(uint256 newTarif)
        noContracts()
        isStarted()
        public
        payable
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        require(newTarif >= tarifMin && newTarif <= tarifMax);
        if(myTokens() == 0) {
            tarif[_customerAddress] = newTarif;
        }
        purchaseTokens(msg.value);
    }
 
     
    function()
        noContracts()
        isStarted()
        payable
        public
    {
        address _customerAddress = msg.sender;
        if(myTokens() == 0) {
            tarif[_customerAddress] = 25;
        }
        purchaseTokens(msg.value);
    }
    
     
    function reinvest()
        noContracts()
        isStarted()
        onlyStronghands()
        public
    {
         
        uint256 _dividends = myDividends();
 
         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
 
         
        uint256 _tokens = purchaseTokens(_dividends);
 
         
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
 
     
    function exit()
        noContracts()
        isStarted()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
 
         
        withdraw();
    }
 
     
    function withdraw()
        noContracts()
        isStarted()
        onlyStronghands()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
 
         
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
 
         
        _customerAddress.transfer(_dividends);
 
         
        emit onWithdraw(_customerAddress, _dividends);
    }
 
     
    function sell(uint256 _amountOfTokens)
        noContracts()
        isStarted()
        onlyBagholders()
        public
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 dividendFee_ = SafeMath.sub(tarifDiff, tarif[_customerAddress]);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
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
 
     
     
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
        disableTime = now + timeToStart;
    }
    
     
    function addAmbassador(address _identifier)
        onlyAdministrator()
        public
    {
        ambassadors_[_identifier] = true;
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
        return dividendsOf(_customerAddress);
    }
    
     
    function myTarif()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return tarifOf(_customerAddress);
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
    
     
    function tarifOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tarif[_customerAddress];
    }
 
     
    function sellPrice()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
         
        if(tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 dividendFee_ = SafeMath.sub(tarifDiff, tarif[_customerAddress]);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
 
     
    function buyPrice()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 dividendFee_ = tarif[_customerAddress];
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
 
     
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        uint256 dividendFee_ = tarif[_customerAddress];
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
 
        return _amountOfTokens;
    }
 
     
    function calculateEthereumReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 dividendFee_ = SafeMath.sub(tarifDiff, tarif[_customerAddress]);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
 
 
     
    function purchaseTokens(uint256 _incomingEthereum)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
         
        address _customerAddress = msg.sender;
        uint256 dividendFee_ = tarif[_customerAddress];
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _dividends = _undividedDividends;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
         
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
 
         
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens);
 
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