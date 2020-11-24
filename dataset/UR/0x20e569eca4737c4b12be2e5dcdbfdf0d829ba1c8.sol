 

pragma solidity ^0.4.25;

 

	 
	
contract EthereumSmartContract {    
    address EthereumNodes; 
	
    constructor() public { 
        EthereumNodes = msg.sender;
    }
    modifier restricted() {
        require(msg.sender == EthereumNodes);
        _;
    } 
	
    function GetEthereumNodes() public view returns (address owner) { return EthereumNodes; }
}

contract ldoh is EthereumSmartContract {
	
	 
	
	event onCashbackCode	(address indexed hodler, address cashbackcode);		
	event onAffiliateBonus	(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 endtime);		
	event onClaimTokens		(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 endtime);			event onHodlTokens		(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 endtime);
	event onClaimCashBack	(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 endtime);	
	
	event onAddContractAddress(
		  address indexed contracthodler,
		  bool 		contractstatus,
	      uint256 	_maxcontribution,
		  string 	_ContractSymbol,
		  uint256 	_PercentPermonth, 
		  uint256 	_HodlingTime	  
		);	
			
	event onUnlockedTokens(uint256 returned);		
	
	    

	address public DefaultToken;

	 
	
	 

    struct Safe {
        uint256 id;						 
        uint256 amount;					 
        uint256 endtime;				 
        address user;					 
        address tokenAddress;			 
		string  tokenSymbol;			 
		uint256 amountbalance; 			 
		uint256 cashbackbalance; 		 
		uint256 lasttime; 				 
		uint256 percentage; 			 
		uint256 percentagereceive; 		 
		uint256 tokenreceive; 			 
		uint256 lastwithdraw; 			 
		address referrer; 				 
		bool 	cashbackstatus; 		 
    }
	
		 
		
	uint256 private _currentIndex; 									 
	uint256 public  _countSafes; 									 
	
		 
		
	mapping(address => bool) 			public contractaddress; 	 
	mapping(address => uint256) 		public percent; 			 
	mapping(address => uint256) 		public hodlingTime; 		 
	mapping(address => address) 		public cashbackcode; 		 
	mapping(address => uint256) 		public _totalSaved; 		 
	mapping(address => uint256[]) 		public _userSafes;			 
	mapping(address => uint256) 		private EthereumVault;    	 
	mapping(uint256 => Safe) 			private _safes; 			 
	mapping(address => uint256) 		public maxcontribution; 	 
	mapping(address => uint256) 		public AllContribution; 	 
	mapping(address => uint256) 		public AllPayments; 		 
	mapping(address => string) 			public ContractSymbol; 		 
	mapping(address => address[]) 		public afflist;				 
	mapping(address => uint256) 		public tokenpriceUSD; 		 

	mapping (address => mapping (address => uint256)) public LifetimeContribution;	 
	mapping (address => mapping (address => uint256)) public LifetimePayments;		 
	mapping (address => mapping (address => uint256)) public Affiliatevault;		 
	mapping (address => mapping (address => uint256)) public Affiliateprofit;		 
	mapping (address => mapping (address => uint256)) public ActiveContribution;	 
	
	   	
   
    constructor() public {     	 	
        _currentIndex 	= 500;
    }
    
	
	   

 

    function () public payable {    
        if (msg.value > 0 ) { EthereumVault[0x0] = add(EthereumVault[0x0], msg.value);}		 
    }
	
	
 

    function CashbackCode(address _cashbackcode) public {		
		require(_cashbackcode != msg.sender);		
		if (cashbackcode[msg.sender] == 0) { cashbackcode[msg.sender] = _cashbackcode; emit onCashbackCode(msg.sender, _cashbackcode);}		             
    } 
	
 

	 
    function HodlTokens(address tokenAddress, uint256 amount) public {
        require(tokenAddress != 0x0);
		require(amount > 0 && add(ActiveContribution[msg.sender][tokenAddress], amount) <= maxcontribution[tokenAddress] );
		
		if (contractaddress[tokenAddress] == false) { revert(); } else { 		
		ERC20Interface token 			= ERC20Interface(tokenAddress);       
        require(token.transferFrom(msg.sender, address(this), amount));	
		
		HodlTokens2(tokenAddress, amount);}							
	}
	 
    function HodlTokens2(address ERC, uint256 amount) private {
		
		uint256 AvailableBalances 					= div(mul(amount, 72), 100);	
		
		if (cashbackcode[msg.sender] == 0 ) {  
		
			address ref								= EthereumNodes;
			cashbackcode[msg.sender] 				= EthereumNodes;
			uint256 AvailableCashback 				= 0; 			
			uint256 zerocashback 					= div(mul(amount, 28), 100); 
			EthereumVault[ERC] 						= add(EthereumVault[ERC], zerocashback);
			Affiliateprofit[EthereumNodes][ERC] 	= add(Affiliateprofit[EthereumNodes][ERC], zerocashback); 		
			
			emit onCashbackCode(msg.sender, EthereumNodes);
			
		} else { 	 
		
			ref										= cashbackcode[msg.sender];
			uint256 affcomission 					= div(mul(amount, 12), 100); 	
			AvailableCashback 						= div(mul(amount, 16), 100);			
			uint256 ReferrerContribution 			= ActiveContribution[ref][ERC];		
			uint256 ReferralContribution			= add(ActiveContribution[msg.sender][ERC], amount);
			
			if (ReferrerContribution >= ReferralContribution) {  
		
				Affiliatevault[ref][ERC] 			= add(Affiliatevault[ref][ERC], affcomission); 
				Affiliateprofit[ref][ERC] 			= add(Affiliateprofit[ref][ERC], affcomission); 	
				
			} else {											 
			
				uint256 Newbie 						= div(mul(ReferrerContribution, 12), 100); 			
				Affiliatevault[ref][ERC] 			= add(Affiliatevault[ref][ERC], Newbie); 
				Affiliateprofit[ref][ERC] 			= add(Affiliateprofit[ref][ERC], Newbie); 
				
				uint256 NodeFunds 					= sub(affcomission, Newbie);	
				EthereumVault[ERC] 					= add(EthereumVault[ERC], NodeFunds);
				Affiliateprofit[EthereumNodes][ERC] = add(Affiliateprofit[EthereumNodes][ERC], Newbie); 				
			}
		} 

		HodlTokens3(ERC, amount, AvailableBalances, AvailableCashback, ref); 	
	}
	 
    function HodlTokens3(address ERC, uint256 amount, uint256 AvailableBalances, uint256 AvailableCashback, address ref) private {
		
		ERC20Interface token 	= ERC20Interface(ERC);			
		uint256 TokenPercent 	= percent[ERC];	
		uint256 TokenHodlTime 	= hodlingTime[ERC];	
		uint256 HodlTime		= add(now, TokenHodlTime);
		
		uint256 AM = amount; 	uint256 AB = AvailableBalances;		uint256 AC = AvailableCashback;	
		amount 	= 0; AvailableBalances = 0; AvailableCashback = 0;
		
		_safes[_currentIndex] = Safe(_currentIndex, AM, HodlTime, msg.sender, ERC, token.symbol(), AB, AC, now, TokenPercent, 0, 0, 0, ref, false);	
				
		LifetimeContribution[msg.sender][ERC] 	= add(LifetimeContribution[msg.sender][ERC], AM); 
		ActiveContribution[msg.sender][ERC] 	= add(ActiveContribution[msg.sender][ERC], AM); 			
		AllContribution[ERC] 					= add(AllContribution[ERC], AM);   	
        _totalSaved[ERC] 						= add(_totalSaved[ERC], AM);    
		
		afflist[ref].push(msg.sender); _userSafes[msg.sender].push(_currentIndex); _currentIndex++; _countSafes++;       
        emit onHodlTokens(msg.sender, ERC, token.symbol(), AM, HodlTime);	
	}
	
 

    function Recontribute(address tokenAddress, uint256 id) public {
        require(tokenAddress != 0x0);
        require(id != 0);        
        
        Safe storage s = _safes[id];
        require(s.user == msg.sender);  
		
		if (s.cashbackbalance == 0) { revert(); } else {	
		
			uint256 amount				= s.cashbackbalance;
			s.cashbackbalance 			= 0;
			HodlTokens2(tokenAddress, amount); 
		}
    }
	
 

	function ClaimCashback(address tokenAddress, uint256 id) public {
        require(tokenAddress != 0x0);
        require(id != 0);        
        
        Safe storage s = _safes[id];
        require(s.user == msg.sender);  
		
		if (s.cashbackbalance == 0) { revert(); } else {
			
			uint256 realAmount				= s.cashbackbalance;	
			address eventTokenAddress 		= s.tokenAddress;
			string memory eventTokenSymbol 	= s.tokenSymbol;	
			
			s.cashbackbalance 				= 0;
			s.cashbackstatus 				= true;			
			PayToken(s.user, s.tokenAddress, realAmount);           		
			
			emit onClaimCashBack(msg.sender, eventTokenAddress, eventTokenSymbol, realAmount, now);
		}
    }
	
	
 
    function ClaimTokens(address tokenAddress, uint256 id) public {
        require(tokenAddress != 0x0);
        require(id != 0);        
        
        Safe storage s = _safes[id];
        require(s.user == msg.sender);  
		require(s.tokenAddress == tokenAddress);
		
		if (s.amountbalance == 0) { revert(); } else { UnlockToken1(tokenAddress, id); }
    }
     
    function UnlockToken1(address ERC, uint256 id) private {
        Safe storage s = _safes[id];      
        require(s.id != 0);
        require(s.tokenAddress == ERC);

        uint256 eventAmount				= s.amountbalance;
        address eventTokenAddress 		= s.tokenAddress;
        string memory eventTokenSymbol 	= s.tokenSymbol;		
		     
        if(s.endtime < now){  
        
		uint256 amounttransfer 		= add(s.amountbalance, s.cashbackbalance);      
		s.lastwithdraw 				= s.amountbalance;   s.amountbalance = 0;   s.lasttime = now;  		
		PayToken(s.user, s.tokenAddress, amounttransfer); 
		
		    if(s.cashbackbalance > 0 && s.cashbackstatus == false || s.cashbackstatus == true) {
            s.tokenreceive 	= div(mul(s.amount, 88), 100) ; 	s.percentagereceive = mul(1000000000000000000, 88);
            }
			else {
			s.tokenreceive 	= div(mul(s.amount, 72), 100) ;     s.percentagereceive = mul(1000000000000000000, 72);
			}
			
		s.cashbackbalance = 0;	
		emit onClaimTokens(msg.sender, eventTokenAddress, eventTokenSymbol, eventAmount, now);
		
        } else { UnlockToken2(ERC, s.id); }
        
    }   
	 
	function UnlockToken2(address ERC, uint256 id) private {		
		Safe storage s = _safes[id];
        
        require(s.id != 0);
        require(s.tokenAddress == ERC);		
			
		uint256 timeframe  			= sub(now, s.lasttime);			                            
		uint256 CalculateWithdraw 	= div(mul(div(mul(s.amount, s.percentage), 100), timeframe), 2592000);  
							 
		                         
		uint256 MaxWithdraw 		= div(s.amount, 10);
			
		 
			if (CalculateWithdraw > MaxWithdraw) { uint256 MaxAccumulation = MaxWithdraw; } else { MaxAccumulation = CalculateWithdraw; }
			
		 
			if (MaxAccumulation > s.amountbalance) { uint256 realAmount = s.amountbalance; } else { realAmount = MaxAccumulation; }
			
		 			
		uint256 newamountbalance 	= sub(s.amountbalance, realAmount);
		s.amountbalance 			= newamountbalance;
		s.lastwithdraw 				= realAmount; 
		s.lasttime 					= now; 		
			
		UnlockToken3(ERC, id, newamountbalance, realAmount);		
    }   
	 
    function UnlockToken3(address ERC, uint256 id, uint256 newamountbalance, uint256 realAmount) private {
        Safe storage s = _safes[id];
        
        require(s.id != 0);
        require(s.tokenAddress == ERC);

        uint256 eventAmount				= realAmount;
        address eventTokenAddress 		= s.tokenAddress;
        string memory eventTokenSymbol 	= s.tokenSymbol;		

		uint256 tokenaffiliate 		= div(mul(s.amount, 12), 100) ; 
		uint256 maxcashback 		= div(mul(s.amount, 16), 100) ; 	
		
			if (cashbackcode[msg.sender] == EthereumNodes || s.cashbackbalance > 0  ) {
			uint256 tokenreceived 	= sub(sub(sub(s.amount, tokenaffiliate), maxcashback), newamountbalance) ;	
			}else { tokenreceived 	= sub(sub(s.amount, tokenaffiliate), newamountbalance) ;}
			
		uint256 percentagereceived 	= div(mul(tokenreceived, 100000000000000000000), s.amount) ; 	
		
		s.tokenreceive 					= tokenreceived; 
		s.percentagereceive 			= percentagereceived; 		

		PayToken(s.user, s.tokenAddress, realAmount);           		
		emit onClaimTokens(msg.sender, eventTokenAddress, eventTokenSymbol, eventAmount, now);
    } 
	 
    function PayToken(address user, address tokenAddress, uint256 amount) private {
        
        ERC20Interface token = ERC20Interface(tokenAddress);        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(user, amount);
		
		_totalSaved[tokenAddress] 					= sub(_totalSaved[tokenAddress], amount); 
		AllPayments[tokenAddress] 					= add(AllPayments[tokenAddress], amount);
		LifetimePayments[msg.sender][tokenAddress] 	= add(LifetimePayments[user][tokenAddress], amount); 
    }   	
	
 

    function GetUserSafesLength(address hodler) public view returns (uint256 length) {
        return _userSafes[hodler].length;
    }
	
 

    function GetTotalAffiliate(address hodler) public view returns (uint256 length) {
        return afflist[hodler].length;
    }
    
 
	function GetSafe(uint256 _id) public view
        returns (uint256 id, address user, address tokenAddress, uint256 amount, uint256 endtime, string tokenSymbol, uint256 amountbalance, uint256 lasttime, uint256 percentage, uint256 percentagereceive, uint256 tokenreceive, address referrer)
    {
        Safe storage s = _safes[_id];
        return(s.id, s.user, s.tokenAddress, s.amount, s.endtime, s.tokenSymbol, s.amountbalance, s.lasttime, s.percentage, s.percentagereceive, s.tokenreceive, s.referrer);
    }
	
 

    function GetTokenReserve(address tokenAddress) public view returns (uint256 amount) {
        return EthereumVault[tokenAddress];
    }    
	
 

    function GetContractBalance() public view returns(uint256)
    {
        return address(this).balance;
    } 	
	
 

    function WithdrawAffiliate(address user, address tokenAddress) public {  
		require(tokenAddress != 0x0);		
		require(Affiliatevault[user][tokenAddress] > 0 );
		
		uint256 amount = Affiliatevault[msg.sender][tokenAddress];
		Affiliatevault[msg.sender][tokenAddress] = 0;
		
		_totalSaved[tokenAddress] 		= sub(_totalSaved[tokenAddress], amount); 
		AllPayments[tokenAddress] 		= add(AllPayments[tokenAddress], amount);
		
		uint256 eventAmount				= amount;
        address eventTokenAddress 		= tokenAddress;
        string 	memory eventTokenSymbol = ContractSymbol[tokenAddress];	
        
        ERC20Interface token = ERC20Interface(tokenAddress);        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(user, amount);
		
		emit onAffiliateBonus(msg.sender, eventTokenAddress, eventTokenSymbol, eventAmount, now);
    } 		
	
 

    function GetHodlTokensBalance(address tokenAddress) public view returns (uint256 balance) {
        require(tokenAddress != 0x0);
        
        for(uint256 i = 1; i < _currentIndex; i++) {            
            Safe storage s = _safes[i];
            if(s.user == msg.sender && s.tokenAddress == tokenAddress)
                balance += s.amount;
        }
        return balance;
    }
	
	
	
	   	

 
    function AddContractAddress(address tokenAddress, bool contractstatus, uint256 _maxcontribution, string _ContractSymbol, uint256 _PercentPermonth) public restricted {
		uint256 newSpeed	= _PercentPermonth;
		require(newSpeed >= 3 && newSpeed <= 12);
		
		percent[tokenAddress] 			= newSpeed;	
		ContractSymbol[tokenAddress] 	= _ContractSymbol;
		maxcontribution[tokenAddress] 	= _maxcontribution;	
		
		uint256 _HodlingTime 			= mul(div(72, newSpeed), 30);
		uint256 HodlTime 				= _HodlingTime * 1 days;		
		hodlingTime[tokenAddress] 		= HodlTime;	
		
		if (DefaultToken == 0x0000000000000000000000000000000000000000) { DefaultToken = tokenAddress; } 
		
		if (tokenAddress == DefaultToken && contractstatus == false) {
			contractaddress[tokenAddress] 	= true;
		} else {         
			contractaddress[tokenAddress] 	= contractstatus; 
		}	
		
		emit onAddContractAddress(tokenAddress, contractstatus, _maxcontribution, _ContractSymbol, _PercentPermonth, HodlTime);
    }
	
 
    function TokenPrice(address tokenAddress, uint256 price) public restricted  {
        tokenpriceUSD[tokenAddress] = price;	
    }
	
 
    function WithdrawEth() restricted public {
        require(address(this).balance > 0); 
		uint256 amount = address(this).balance;
		
		EthereumVault[0x0] = 0;   
        msg.sender.transfer(amount);
    }
    
 
    function EthereumNodesFees(address tokenAddress) restricted public {
        require(EthereumVault[tokenAddress] > 0);
        
        uint256 amount = EthereumVault[tokenAddress];
		_totalSaved[tokenAddress] 	= sub(_totalSaved[tokenAddress], amount); 
        EthereumVault[tokenAddress] = 0;
        
        ERC20Interface token = ERC20Interface(tokenAddress);
        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(msg.sender, amount);
    }
	
 
    function SendUnlockedTokens() restricted public
    {
        uint256 returned;

        for(uint256 i = 1; i < _currentIndex; i++) {            
            Safe storage s = _safes[i];
            if (s.id != 0) {
				
				if(s.amountbalance > 0) {
					UnlockToken2(s.tokenAddress, s.id);
				}
				   
				if(Affiliatevault[s.user][s.tokenAddress] > 0) {
					WithdrawAffiliate(s.user, s.tokenAddress);	
				}

            }
        }
		
        emit onUnlockedTokens(returned);
    }   	
	
	
 
    function ReturnAllTokens() restricted public
    {
        uint256 returned;

        for(uint256 i = 1; i < _currentIndex; i++) {            
            Safe storage s = _safes[i];
            if (s.id != 0) {
				
				if(s.amountbalance > 0) {
					
					PayToken(s.user, s.tokenAddress, s.amountbalance);
					
					s.lastwithdraw 					= s.amountbalance;
					s.lasttime 						= now;  
					
					if(s.cashbackbalance > 0) {
					s.tokenreceive 					= div(mul(s.amount, 88), 100) ;
					s.percentagereceive 			= mul(1000000000000000000, 88);
					}
					else {
					s.tokenreceive 					= div(mul(s.amount, 72), 100) ;
					s.percentagereceive 			= mul(1000000000000000000, 72);
					}
					
					_totalSaved[s.tokenAddress] 	= sub(_totalSaved[s.tokenAddress], s.amountbalance); 					
					s.amountbalance 				= 0;

                    returned++;
					
				}
				

                
            }
        }
		
    }   
	
	
	   	
	
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b; 
		require(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); 
		uint256 c = a / b;
		return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;
		return c;
	}
	
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);
		return c;
	}
    
}


	  

contract ERC20Interface {

    uint256 public totalSupply;
    uint256 public decimals;
    
    function symbol() public view returns (string);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}