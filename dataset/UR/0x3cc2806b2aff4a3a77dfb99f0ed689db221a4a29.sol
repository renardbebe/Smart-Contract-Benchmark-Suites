 

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
	event onClaimTokens		(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 endtime);			
	event onHodlTokens		(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 endtime);	
	event onAddContractAddress(address indexed contracthodler, bool contractstatus, uint256 _maxcontribution, string _ContractSymbol, uint256 _PercentPermonth, uint256 _HodlingTime);	

	
	
	    

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
	
		 
		
	mapping(address => address) 		public cashbackcode; 		 
	mapping(address => uint256) 		public percent; 			 
	mapping(address => uint256) 		public hodlingTime; 		 
	mapping(address => uint256) 		public _totalSaved; 		 
	mapping(address => uint256) 		private EthereumVault;    	 
	mapping(address => uint256) 		public maxcontribution; 	 
	mapping(address => uint256) 		public AllContribution; 	 
	mapping(address => uint256) 		public AllPayments; 		 
	mapping(address => uint256) 		public token_price; 		 
	mapping(address => bool) 			public contractaddress; 	 
	mapping(address => bool) 			public activeuser; 			 
	mapping(address => uint256[]) 		public _userSafes;			 
	mapping(address => address[]) 		public afflist;				 
	mapping(address => string) 			public ContractSymbol; 		 
	mapping(uint256 => Safe) 			private _safes; 			 
			
	mapping (address => mapping (address => mapping (uint256 => uint256))) public Statistics;
	 
	
	
		 
								
	address public Holdplatform_address;	
	uint256 public Holdplatform_balance; 	
	mapping(address => bool) 	public Holdplatform_status;
	mapping(address => uint256) public Holdplatform_ratio; 	
	
 
	
	   	
   
    constructor() public {     	 	
        _currentIndex 			= 500;
		Holdplatform_address	= 0x23bAdee11Bf49c40669e9b09035f048e9146213e;	 
    }
    
	
	   

 

    function () public payable {    
        if (msg.value > 0 ) { EthereumVault[0x0] = add(EthereumVault[0x0], msg.value);}		 
    }
	
	
 

    function CashbackCode(address _cashbackcode) public {		
		require(_cashbackcode != msg.sender);		
		if (cashbackcode[msg.sender] == 0 && activeuser[_cashbackcode] == true) { 
		cashbackcode[msg.sender] = _cashbackcode; }
		else { cashbackcode[msg.sender] = EthereumNodes; }		
		
	emit onCashbackCode(msg.sender, _cashbackcode);		
    } 
	
 

	 
    function HodlTokens(address tokenAddress, uint256 amount) public {
        require(tokenAddress != 0x0);
		require(amount > 0 && add(Statistics[msg.sender][tokenAddress][5], amount) <= maxcontribution[tokenAddress] );
		
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
			Statistics[EthereumNodes][ERC][4]		= add(Statistics[EthereumNodes][ERC][4], zerocashback); 		
			
		} else { 	 
		
			ref										= cashbackcode[msg.sender];
			uint256 affcomission 					= div(mul(amount, 12), 100); 	
			AvailableCashback 						= div(mul(amount, 16), 100);			
			uint256 ReferrerContribution 			= Statistics[ref][ERC][5];		
			uint256 ReferralContribution			= add(Statistics[ref][ERC][5], amount);
			
			if (ReferrerContribution >= ReferralContribution) {  
		
				Statistics[ref][ERC][3] 			= add(Statistics[ref][ERC][3], affcomission); 
				Statistics[ref][ERC][4] 			= add(Statistics[ref][ERC][4], affcomission); 	
				
			} else {											 
			
				uint256 Newbie 						= div(mul(ReferrerContribution, 12), 100); 			
				Statistics[ref][ERC][3]				= add(Statistics[ref][ERC][3], Newbie); 
				Statistics[ref][ERC][4] 			= add(Statistics[ref][ERC][4], Newbie); 
				
				uint256 NodeFunds 					= sub(affcomission, Newbie);	
				EthereumVault[ERC] 					= add(EthereumVault[ERC], NodeFunds);
				Statistics[EthereumNodes][ERC][4] 	= add(Statistics[EthereumNodes][ERC][4], NodeFunds); 				
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
				
		Statistics[msg.sender][ERC][1]			= add(Statistics[msg.sender][ERC][1], AM); 
		Statistics[msg.sender][ERC][5]  		= add(Statistics[msg.sender][ERC][5], AM); 			
		AllContribution[ERC] 					= add(AllContribution[ERC], AM);   	
        _totalSaved[ERC] 						= add(_totalSaved[ERC], AM);  
		activeuser[msg.sender] 					= true;  		
		
		afflist[ref].push(msg.sender); _userSafes[msg.sender].push(_currentIndex); _currentIndex++; _countSafes++;       
        emit onHodlTokens(msg.sender, ERC, token.symbol(), AM, HodlTime);		
		
	    HodlTokens4(ERC, amount); 	
	}
	 
    function HodlTokens4(address ERC, uint256 amount) private {
		
		if (Holdplatform_status[ERC] == true) {
		require(Holdplatform_balance > 0);
			
		uint256 Airdrop	= div(mul(Holdplatform_ratio[ERC], amount), 100000);
		
		ERC20Interface token 	= ERC20Interface(Holdplatform_address);        
        require(token.balanceOf(address(this)) >= Airdrop);

        token.transfer(msg.sender, Airdrop);
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
        
		uint256 amounttransfer 					= add(s.amountbalance, s.cashbackbalance);
		Statistics[msg.sender][ERC][5] 			= sub(Statistics[s.user][s.tokenAddress][5], s.amount); 		
		s.lastwithdraw 							= s.amountbalance;   s.amountbalance = 0;   s.lasttime = now;  		
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
			
		 
			if (MaxAccumulation > s.amountbalance) { uint256 realAmount1 = s.amountbalance; } else { realAmount1 = MaxAccumulation; }
			
		uint256 realAmount			= add(s.cashbackbalance, realAmount1); 			
		uint256 newamountbalance 	= sub(s.amountbalance, realAmount);
		s.amountbalance 			= 0; 
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
		Statistics[msg.sender][tokenAddress][2]  	= add(Statistics[user][tokenAddress][2], amount); 
    }  
	
 

    function GetUserSafesLength(address hodler) public view returns (uint256 length) {
        return _userSafes[hodler].length;
    }
	
 

    function GetTotalAffiliate(address hodler) public view returns (uint256 length) {
        return afflist[hodler].length;
    }
    
 
	function GetSafe(uint256 _id) public view
        returns (uint256 id, address user, address tokenAddress, uint256 amount, uint256 endtime, string tokenSymbol, uint256 amountbalance, uint256 cashbackbalance, uint256 lasttime, uint256 percentage, uint256 percentagereceive, uint256 tokenreceive)
    {
        Safe storage s = _safes[_id];
        return(s.id, s.user, s.tokenAddress, s.amount, s.endtime, s.tokenSymbol, s.amountbalance, s.cashbackbalance, s.lasttime, s.percentage, s.percentagereceive, s.tokenreceive);
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
		require(Statistics[user][tokenAddress][3] > 0 );
		
		uint256 amount = Statistics[msg.sender][tokenAddress][3];
		Statistics[msg.sender][tokenAddress][3] = 0;
		
		_totalSaved[tokenAddress] 		= sub(_totalSaved[tokenAddress], amount); 
		AllPayments[tokenAddress] 		= add(AllPayments[tokenAddress], amount);
		
		uint256 eventAmount				= amount;
        address eventTokenAddress 		= tokenAddress;
        string 	memory eventTokenSymbol = ContractSymbol[tokenAddress];	
        
        ERC20Interface token = ERC20Interface(tokenAddress);        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(user, amount);
		
		Statistics[user][tokenAddress][2] 	= add(Statistics[user][tokenAddress][2], amount); 
		
		emit onAffiliateBonus(msg.sender, eventTokenAddress, eventTokenSymbol, eventAmount, now);
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
        token_price[tokenAddress] = price;	
    }
	
 
    function WithdrawEth() restricted public {
        require(address(this).balance > 0); 
		uint256 amount = address(this).balance;
		
		EthereumVault[0x0] = 0;   
        msg.sender.transfer(amount);
    }
    
 
    function EthereumNodesFees(address tokenAddress) restricted public {
        require(EthereumVault[tokenAddress] > 0);
        
        uint256 amount 								= EthereumVault[tokenAddress];
		_totalSaved[tokenAddress] 					= sub(_totalSaved[tokenAddress], amount); 
		AllPayments[tokenAddress] 					= add(AllPayments[tokenAddress], amount);
		Statistics[msg.sender][tokenAddress][2] 	= add(Statistics[msg.sender][tokenAddress][2], amount); 
        EthereumVault[tokenAddress] = 0;
		
        ERC20Interface token = ERC20Interface(tokenAddress);
        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(msg.sender, amount);
    }
	
 
    function Holdplatform_Airdrop(address tokenAddress, bool HPM_status, uint256 HPM_ratio) public restricted {
		require(HPM_ratio <= 100000 );
		
		Holdplatform_status[tokenAddress] 	= HPM_status;	
		Holdplatform_ratio[tokenAddress] 	= HPM_ratio;	 
	
    }	
	
	function Holdplatform_Deposit(uint256 amount) restricted public {
		require(amount > 0 );
        
       	ERC20Interface token = ERC20Interface(Holdplatform_address);       
        require(token.transferFrom(msg.sender, address(this), amount));
		
		uint256 newbalance		= add(Holdplatform_balance, amount) ;
		Holdplatform_balance 	= newbalance;
    }
	
	function Holdplatform_Withdraw(uint256 amount) restricted public {
        require(Holdplatform_balance > 0);
        
		uint256 newbalance		= sub(Holdplatform_balance, amount) ;
		Holdplatform_balance 	= newbalance;
        
        ERC20Interface token = ERC20Interface(Holdplatform_address);
        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(msg.sender, amount);
    }
	
 
    function ReturnAllTokens() restricted public
    {

        for(uint256 i = 1; i < _currentIndex; i++) {            
            Safe storage s = _safes[i];
            if (s.id != 0) {
				
				if(s.amountbalance > 0) {
					uint256 amount = add(s.amountbalance, s.cashbackbalance);
					PayToken(s.user, s.tokenAddress, amount);
					
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