 

pragma solidity ^0.4.20;


contract AcceptsEighterbank {
    Eightherbank public tokenContract;

    function AcceptsEighterbank(address _tokenContract) public {
        tokenContract = Eightherbank(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract Eightherbank {
     
     
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
        require(msg.sender == owner);
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
    
    
     
    address public owner;
    string public name = "8therbank";
    string public symbol = "8TH";
    uint8  public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    uint8 constant internal transferFee_ = 5;
    uint8 constant internal refferalFee_ = 33;
    uint256 constant internal tokenPriceInitial_ = 0.00005556 ether;
     
    uint256 constant internal magnitude = 2**64;
    
     
    uint256 public stakingRequirement = 1800e18;
    
     
    address internal serverFeeAddress = msg.sender;

     
    address internal partnerFeeAddress = 0xdde972dc6B0fBE22B575a1066eF038fd7A60Fd98;
    
     
    address internal promoFeeAddress = 0xE377f23F3C2238FE9EB59776549Ec785CbF42e1b;
    
     
    address internal devFeeAddress = msg.sender;

    
     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 1 ether;
    uint256 constant internal ambassadorQuota_ = 100 ether;
    
    
    
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    
     
    bool public onlyAmbassadors = true;
    
     
     
    uint ACTIVATION_TIME = 1574013600;
    
     
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
    if (now >= ACTIVATION_TIME) {
            onlyAmbassadors = false;
        }
         
         
        if(onlyAmbassadors){
            require(
                 
                (ambassadors_[msg.sender] == true &&
                
                 
                (ambassadorAccumulatedQuota_[msg.sender] + _amountOfEthereum) <= ambassadorMaxPurchase_)
                
            );
            
             
            ambassadorAccumulatedQuota_[msg.sender] = SafeMath.add(ambassadorAccumulatedQuota_[msg.sender], _amountOfEthereum);
        
             
            _;
        }else{
            onlyAmbassadors=false;
            _;
        }
        
    }
    
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
     
    mapping(bytes32 => bool) public administrators;
    
     
    mapping(address => bool) public canAcceptTokens_;
    


     
     
    function Eightherbank()
        public
    {
         
        owner = msg.sender;
        name = "8therbank";
        symbol = "8TH";
        decimals = 18;

         
         

        ambassadors_[0x60bc6fa49588bbB9e3273E1fc421f383393E2fc3] = true;  
        ambassadors_[0x074F21a36217d7615d0202faA926aEFEBB5a9999] = true;  
        ambassadors_[0xEe54D208f62368B4efFe176CB548A317dcAe963F] = true;  
        ambassadors_[0x843f2C19bc6df9E32B482E2F9ad6C078001088b1] = true;  
        ambassadors_[0xE377f23F3C2238FE9EB59776549Ec785CbF42e1b] = true;  
        ambassadors_[0xACa4E2730b57dA82476D6d1fA2a85A8f686F108b] = true;  
        ambassadors_[0x24B23bB643082026227e945C7833B81426057b10] = true;  
        ambassadors_[0x5138240E96360ad64010C27eB0c685A8b2eDE4F2] = true;  
        ambassadors_[0xAFC1a5cB605bBd1aa5F6415458BC45cD7554d08b] = true;  
        ambassadors_[0xAA7A7C2DECB180f68F11E975e6D92B5Dc06083A6] = true;  
        ambassadors_[0x73018870D10173ae6F71Cac3047ED3b6d175F274] = true;  
        ambassadors_[0x53e1eB6a53d9354d43155f76861C5a2AC80ef361] = true;  
        ambassadors_[0xCdB84A89BB3D2ad99a39AfAd0068DC11B8280FbC] = true;  
        ambassadors_[0xF1018aCEAd986C97BccffaC40246D701E7b6C58b] = true;  
        ambassadors_[0x340570F0fe147f60C259753A7491059eB6526c2D] = true;  
        ambassadors_[0xbE57E8Cde352a6a55B103f826AC8c324aCD68aDf] = true;  
        ambassadors_[0x05aF7f355E914197FB3548c7Ab67887dD187D808] = true;  
        ambassadors_[0x190A2409fc6434483D4c2CAb804E75e3Bc5ebFa6] = true;  
        ambassadors_[0x52DC007F9D85c4949AF4Db4E7863e48f7f4Fe93D] = true;  
        ambassadors_[0x92421097F5a6b24B45e94A5297e220622DCdbd5a] = true;  

    }
    
     
   function buyFor(address _customerAddress, address _referredBy) public payable returns (uint256) {
        return purchaseTokens(_customerAddress, msg.value, _referredBy );
    }
     
     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.sender, msg.value, _referredBy); 
    }
    
     
    function()
        payable
        public
    {
        purchaseTokens(msg.sender, msg.value, 0x0);
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
        
         
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends, 0x0);
        
         
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
	    uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
         
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
        
         
         
        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
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
    
    	     
    function transferAndCall(address _to, uint256 _value, bytes _data) external returns (bool) {
      require(_to != address(0));
      require(canAcceptTokens_[_to] == true);  
      require(transfer(_to, _value));  
      if (isContract(_to)) {
        AcceptsEighterbank receiver = AcceptsEighterbank(_to);
        require(receiver.tokenFallback(msg.sender, _value, _data));
      }
      return true;
    }
     
     function isContract(address _addr) private constant returns (bool is_contract) {
        
       uint length;
       assembly { length := extcodesize(_addr) }
       return length > 0;
     }
    
     
     
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
    }
    
     
    function changePartner(address _partnerAddress) public{
        require(owner==msg.sender);
        partnerFeeAddress=_partnerAddress;
    }
    
   
  function changePromoter(address _promotorAddress) public{
        require(owner==msg.sender);
        promoFeeAddress=_promotorAddress;
    }
    
   
  function changeDev(address _devAddress) public{
        require(owner==msg.sender);
        devFeeAddress=_devAddress;
    }
    
     
    function setAdministrator(address newowner)
        onlyAdministrator()
        public
    {
        owner = newowner;
    }
    
     
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }
    
         
    function setCanAcceptTokens(address _address, bool _value)
      onlyAdministrator()
      public
    {
      canAcceptTokens_[_address] = _value;
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
        returns(string)
    {
            return "0.00005";
    }
    
     
    function buyPrice() 
        public 
        view 
        returns(string)
    {
        return "0.00005556";
    }
    
     
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
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
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
     
        function purchaseTokens(address _customerAddress, uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
         

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        
         
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));  
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));  
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 200));  
        _taxedEthereum = SafeMath.sub(_taxedEthereum, SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 200));  
        
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
        
         
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        
         
        serverFeeAddress.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));  
        partnerFeeAddress.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 100));  
        promoFeeAddress.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 200));  
        devFeeAddress.transfer(SafeMath.div(SafeMath.mul(_incomingEthereum, 1), 200));  
        
        return _amountOfTokens;
    }

     
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        return (_ethereum * 20000);
    }

     
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
        return (_tokens / 20000);
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