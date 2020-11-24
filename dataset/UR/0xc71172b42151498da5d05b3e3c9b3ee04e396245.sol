 

pragma solidity ^0.4.25;

contract AcceptsHodlFund {
    HodlFund public tokenContract;

    constructor(address _tokenContract) public {
        tokenContract = HodlFund(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract HodlFund {
     
     
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
        require(administrator == _customerAddress);
        _;
    }
    
     
     
     
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
         
         
        if( onlyAmbassadors && 
			((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ ) &&
			now < ACTIVATION_TIME)
		{
            require(
                 
                ambassadors_[_customerAddress] == true &&
                
                 
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
                
            );
            
             
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
        
        } else {
             
			 
			if (onlyAmbassadors) {
				onlyAmbassadors = false;
			}
        }
		
		_;
    }
	
	 
	 
	 
	modifier ambassAntiPumpAndDump() {
		
		 
		if (now <= antiPumpAndDumpEnd_) {
			address _customerAddress = msg.sender;
			
			 
			require(!ambassadors_[_customerAddress]);
		}
	
		 
		_;
	}
	
	 
	 
	modifier ambassOnlyToAmbass(address _to) {
		
		 
		if (now <= antiPumpAndDumpEnd_){
			address _from = msg.sender;
			
			 
			if (ambassadors_[_from]) {
				
				 
				 
				if (_from != lendingAddress_) {
					 
					require(ambassadors_[_to], "As ambassador you should know better :P");
				}
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
    
    
     
    string public name = "Crypto Hodl Fund";
    string public symbol = "HODL";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 15;	 
	uint8 constant internal fundFee_ = 1; 		 
	uint8 constant internal referralBonus_ = 5;
    uint256 constant internal tokenPriceInitial_ =     0.000000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000008 ether;
    uint256 constant internal magnitude = 2**64;	
    
     
    uint256 public stakingRequirement = 20e18;
    
     
    uint256 constant internal ambassadorMaxPurchase_ = 2 ether;
    uint256 constant internal ambassadorQuota_ = 20 ether;
	
	 
	uint256 constant internal antiPumpAndDumpTime_ = 90 days;								 
	uint256 constant public antiPumpAndDumpEnd_ = ACTIVATION_TIME + antiPumpAndDumpTime_;	 
	uint256 constant internal ACTIVATION_TIME = 1541966400;
	
	 
    bool public onlyAmbassadors = true;
    
    
    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
	mapping(address => address) internal lastRef_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
     
    address internal administrator;
	
	 
	address internal lendingAddress_;
	
	 
    address public fundAddress_;
    uint256 internal totalEthFundReceived; 		 
    uint256 internal totalEthFundCollected; 	 
	
	 
	mapping(address => bool) internal ambassadors_;
	
	 
    mapping(address => bool) public canAcceptTokens_;  


     
     
    constructor()
        public
    {
         
        administrator = 0xA38B4C3377F476c04B338A34Ab0AEff9b1Bc8F31;
		fundAddress_ = 0x58fe62D4ccD4339B32Ea49879DC48BdEa87eD6bF;
		lendingAddress_ = 0xa7a4b8a7eb3f92fa8e9f4bbad1bd63fc105e9e29;
        
		ambassadors_[lendingAddress_] 							 = true;	 
		ambassadors_[fundAddress_]								 = true;	 
		
		 
		lastRef_[lendingAddress_] = fundAddress_;
    }
    
     
     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
		require(tx.gasprice <= 0.05 szabo);
		address _lastRef = handleLastRef(_referredBy);
		purchaseInternal(msg.value, _lastRef);
    }
    
     
    function()
        payable
        external
    {
		require(tx.gasprice <= 0.05 szabo);
		address lastRef = handleLastRef(address(0));	 
		purchaseInternal(msg.value, lastRef);
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
        
         
		address _lastRef = handleLastRef(address(0));	 
        uint256 _tokens = purchaseInternal(_dividends, _lastRef);
        
         
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
        onlyBagholders()
		ambassAntiPumpAndDump()
        public
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);				 
		uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);					 
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);	 
		
		 
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);
        
         
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
        onlyBagholders()
		ambassOnlyToAmbass(_toAddress)
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;
        
         
         
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
         
        if(myDividends(true) > 0) withdraw();

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
		
		 
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);
        
         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        
         
        return true;
    }
	
	 
    function transferAndCall(address _to, uint256 _value, bytes _data)
		external
		returns (bool) 
	{
		require(_to != address(0));
		require(canAcceptTokens_[_to] == true); 	 
		require(transfer(_to, _value)); 			 

		if (isContract(_to)) {
			AcceptsHodlFund receiver = AcceptsHodlFund(_to);
			require(receiver.tokenFallback(msg.sender, _value, _data));
		}

		return true;
    }

     
     function isContract(address _addr) 
		private 
		constant 
		returns (bool is_contract) 
	{
		 
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
	
	 
    function payFund()
		public 
	{
		uint256 ethToPay = SafeMath.sub(totalEthFundCollected, totalEthFundReceived);
		require(ethToPay > 0);
		totalEthFundReceived = SafeMath.add(totalEthFundReceived, ethToPay);
      
		if(!fundAddress_.call.value(ethToPay).gas(400000)()) {
			totalEthFundReceived = SafeMath.sub(totalEthFundReceived, ethToPay);
		}
    }
    
     
    function setAdministrator(address _identifier)
        onlyAdministrator()
        public
    {
        administrator = _identifier;
    }
	
	 
    function setCanAcceptTokens(address _address)
      onlyAdministrator()
      public
    {
      canAcceptTokens_[_address] = true;
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
	
	 
	function myLastRef(address _addr)
		public
		view
		returns(address)
	{
		return lastRef_[_addr];
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
			uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, SafeMath.add(_dividends, _fundPayout));     
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
            uint256 _taxedEthereum = SafeMath.div(SafeMath.mul(_ethereum, 100), 80);  
            return _taxedEthereum;
        }
    }
    
     
    function calculateTokensReceived(uint256 _weiToSpend)
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_weiToSpend, dividendFee_), 100);			 
		uint256 _fundPayout = SafeMath.div(SafeMath.mul(_weiToSpend, fundFee_), 100);				 
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_weiToSpend, _dividends), _fundPayout);  
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return SafeMath.div(_amountOfTokens, 1e18);
    }
    
     
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);				 
		uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);					 
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);	 
        return _taxedEthereum;
    }
	
	 
    function etherToSendFund()
        public
        view
        returns(uint256)
	{
        return SafeMath.sub(totalEthFundCollected, totalEthFundReceived);
    }
    
    
     
	function handleLastRef(address _ref)
		internal 
		returns(address)
	{
		address _customerAddress = msg.sender;			 
		address _lastRef = lastRef_[_customerAddress];	 
		
		 
		if (_ref == _customerAddress) {
			return _lastRef;
		}
		
		 
		if (_ref == address(0)) {
			return _lastRef;
		} else {
			 
			if (_ref != _lastRef) {
				lastRef_[_customerAddress] = _ref;	 
				return _ref;						 
			} else {
				return _lastRef;					 
			}
		}
	}
	
	 
    function purchaseInternal(uint256 _incomingEthereum, address _referredBy)
		internal
		returns(uint256)
	{
		address _customerAddress = msg.sender;
		uint256 _purchaseEthereum = _incomingEthereum;
		uint256 _excess = 0;

		 
		if(_purchaseEthereum > 2 ether) {  
			if (SafeMath.sub(totalEthereumBalance(), _purchaseEthereum) < 100 ether) {  
				_purchaseEthereum = 2 ether;
				_excess = SafeMath.sub(_incomingEthereum, _purchaseEthereum);
			}
		}

		 
		purchaseTokens(_purchaseEthereum, _referredBy);

		 
		if (_excess > 0) {
			_customerAddress.transfer(_excess);
		}
    }
	
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
         
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);				 
		uint256 _fundPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, fundFee_), 100);							 
		uint256 _referralPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, referralBonus_), 100);				 
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralPayout);									 
         
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);
		
		 
        uint256 _amountOfTokens = ethereumToTokens_(SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends), _fundPayout));
        uint256 _fee = _dividends * magnitude;
 
         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _customerAddress &&
            
             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralPayout);
        } else {
             
             
            _dividends = SafeMath.add(_dividends, _referralPayout);
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
        uint256 _tokensReceived = 
		(
			 
			SafeMath.sub(
				(sqrt
					(
						(tokenPriceInitial_)**2 * 10**36
						+
						(tokenPriceInitial_) * (tokenPriceIncremental_) * 10**36
						+
						25 * (tokenPriceIncremental_)**2 * 10**34
						+
						(tokenPriceIncremental_)**2 * (tokenSupply_)**2
						+
						2 * (tokenPriceIncremental_) * (tokenPriceInitial_) * (tokenSupply_) * 10**18
						+
						(tokenPriceIncremental_)**2 * (tokenSupply_) * 10**18
						+
						2 * (tokenPriceIncremental_) * (_ethereum) * 10**36
					)
				), ((tokenPriceInitial_)* 10**18 + 5 * (tokenPriceIncremental_) * 10**17)
			) / (tokenPriceIncremental_)
        ) - (tokenSupply_)
        ;
  
        return _tokensReceived;
    }
    
     
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {
        uint256 _etherReceived =
        (
             
            SafeMath.sub(
                (
					((tokenPriceIncremental_) * (_tokens) * (tokenSupply_)) / 1e18
                    +
                    (tokenPriceInitial_) * (_tokens)
                    +
                    ((tokenPriceIncremental_) * (_tokens)) / 2        
                ), (
					((tokenPriceIncremental_) * (_tokens**2)) / 2
				) / 1e18
			)
        ) / 1e18
		;
        
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