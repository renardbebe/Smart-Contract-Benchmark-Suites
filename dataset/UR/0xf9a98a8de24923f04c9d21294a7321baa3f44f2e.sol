 

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
	
    function GetEthereumNodes() public view returns (address owner) {
        return EthereumNodes;
    }
}

 
contract ldoh is EthereumSmartContract {
	
	 
	
	event onAffiliateBonus(
		  address indexed hodler,
		  address indexed tokenAddress,
	      string tokenSymbol,
		  uint256 amount,
		  uint256 endtime
		);
		
	event onClaimTokens(
		  address indexed hodler,
		  address indexed tokenAddress,
	      string tokenSymbol,
		  uint256 amount,
		  uint256 endtime
		);		
		
	event onHodlTokens(
		  address indexed hodler,
		  address indexed tokenAddress,
	      string tokenSymbol,
		  uint256 amount,
		  uint256 endtime
		);				
		
	event onAddContractAddress(
		  address indexed contracthodler,
		  bool contractstatus,
	      uint256 _maxcontribution,
		  string _ContractSymbol
		);	
		
	event onCashbackCode(
		  address indexed hodler,
		  address cashbackcode
		);			
	
	event onUnlockedTokens(
	      uint256 returned
		);		
		
	event onReturnAll( 
	      uint256 returned   	 
		);
	
	
	
	    

	address internal DefaultToken;		
	
		 

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
    }
	
		 
	
	uint256 public 	percent 				= 1200;        	 
	uint256 private constant affiliate 		= 12;        	 
	uint256 private constant cashback 		= 16;        	 
	uint256 private constant nocashback 	= 28;        	 
	uint256 private constant totalreceive 	= 88;        	 
    uint256 private constant seconds30days 	= 2592000;  	 
	uint256 public  hodlingTime;							 
	uint256 private _currentIndex; 							 
	uint256 public  _countSafes; 							 
	
		 
	
	mapping(address => bool) 			public contractaddress; 	 
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
	
    	 

	mapping (address => mapping (address => uint256)) public LifetimeContribution;	 
	mapping (address => mapping (address => uint256)) public LifetimePayments;		 
	mapping (address => mapping (address => uint256)) public Affiliatevault;		 
	mapping (address => mapping (address => uint256)) public Affiliateprofit;		 
	
	
	
	   	
   
    constructor() public {
        	 	
        hodlingTime 	= 730 days;
        _currentIndex 	= 500;
    }
    
	
	
	   

 
    function () public payable {
        require(msg.value > 0);       
        EthereumVault[0x0] = add(EthereumVault[0x0], msg.value);
    }
	
 
    function CashbackCode(address _cashbackcode) public {
		require(_cashbackcode != msg.sender);
		
		if (cashbackcode[msg.sender] == 0) {
			cashbackcode[msg.sender] = _cashbackcode;
			emit onCashbackCode(msg.sender, _cashbackcode);
		}		             
    } 
	
 
    function HodlTokens(address tokenAddress, uint256 amount) public {
        require(tokenAddress != 0x0);
		require(amount > 0 && amount <= maxcontribution[tokenAddress] );
		
		if (contractaddress[tokenAddress] == false) {
			revert();
		}
		else {
			
		
        ERC20Interface token = ERC20Interface(tokenAddress);       
        require(token.transferFrom(msg.sender, address(this), amount));
		
		uint256 affiliatecomission 		= div(mul(amount, affiliate), 100); 	
		uint256 no_cashback 			= div(mul(amount, nocashback), 100); 	
		
		 	if (cashbackcode[msg.sender] == 0 ) { 				
			uint256 data_amountbalance 		= div(mul(amount, 72), 100);	
			uint256 data_cashbackbalance 	= 0; 
			address data_referrer			= EthereumNodes;
			
			cashbackcode[msg.sender] = EthereumNodes;
			emit onCashbackCode(msg.sender, EthereumNodes);
			
			EthereumVault[tokenAddress] 	= add(EthereumVault[tokenAddress], no_cashback);
			
			} else { 	
			data_amountbalance 				= sub(amount, affiliatecomission);			
			data_cashbackbalance 			= div(mul(amount, cashback), 100);			
			data_referrer					= cashbackcode[msg.sender];
			uint256 referrer_contribution 	= LifetimeContribution[data_referrer][tokenAddress];
			
			uint256 mycontribution			= add(LifetimeContribution[msg.sender][tokenAddress], amount);

				if (referrer_contribution >= mycontribution) {
		
					Affiliatevault[data_referrer][tokenAddress] 	= add(Affiliatevault[data_referrer][tokenAddress], affiliatecomission); 
					Affiliateprofit[data_referrer][tokenAddress] 	= add(Affiliateprofit[data_referrer][tokenAddress], affiliatecomission); 
					
				} else {
					
					uint256 Newbie 	= div(mul(referrer_contribution, affiliate), 100); 
					
					Affiliatevault[data_referrer][tokenAddress] 	= add(Affiliatevault[data_referrer][tokenAddress], Newbie); 
					Affiliateprofit[data_referrer][tokenAddress] 	= add(Affiliateprofit[data_referrer][tokenAddress], Newbie); 
					
					uint256 data_unusedfunds 		= sub(affiliatecomission, Newbie);	
					EthereumVault[tokenAddress] 	= add(EthereumVault[tokenAddress], data_unusedfunds);
					
				}
			
			} 	
			  		  				  					  
	 
	
		afflist[data_referrer].push(msg.sender);	
		_userSafes[msg.sender].push(_currentIndex);
		_safes[_currentIndex] = 

		Safe(
		_currentIndex, amount, now + hodlingTime, msg.sender, tokenAddress, token.symbol(), data_amountbalance, data_cashbackbalance, now, percent, 0, 0, 0, data_referrer);	

		LifetimeContribution[msg.sender][tokenAddress] = add(LifetimeContribution[msg.sender][tokenAddress], amount); 		
		
	 
		AllContribution[tokenAddress] 	= add(AllContribution[tokenAddress], amount);   	
        _totalSaved[tokenAddress] 		= add(_totalSaved[tokenAddress], amount);     		
        _currentIndex++;
        _countSafes++;
        
        emit onHodlTokens(msg.sender, tokenAddress, token.symbol(), amount, now + hodlingTime);
    }	
			
			
}
		
	
 
    function ClaimTokens(address tokenAddress, uint256 id) public {
        require(tokenAddress != 0x0);
        require(id != 0);        
        
        Safe storage s = _safes[id];
        require(s.user == msg.sender);  
		
		if (s.amountbalance == 0) {
			revert();
		}
		else {
			UnlockToken(tokenAddress, id);
		}
    }
    
    function UnlockToken(address tokenAddress, uint256 id) private {
        Safe storage s = _safes[id];
        
        require(s.id != 0);
        require(s.tokenAddress == tokenAddress);

        uint256 eventAmount;
        address eventTokenAddress = s.tokenAddress;
        string memory eventTokenSymbol = s.tokenSymbol;		
		     
        if(s.endtime < now)  
        {
            PayToken(s.user, s.tokenAddress, s.amountbalance);
            
            eventAmount 				= s.amountbalance;
		   _totalSaved[s.tokenAddress] 	= sub(_totalSaved[s.tokenAddress], s.amountbalance);  
		
		s.lastwithdraw 		= s.amountbalance;
		s.amountbalance 	= 0;
		s.lasttime 			= now;  
		
		    if(s.cashbackbalance > 0) {
            s.tokenreceive 					= div(mul(s.amount, 88), 100) ;
			s.percentagereceive 			= mul(1000000000000000000, 88);
            }
			else {
			s.tokenreceive 					= div(mul(s.amount, 72), 100) ;
			s.percentagereceive 			= mul(1000000000000000000, 72);
			}
		
		emit onClaimTokens(msg.sender, eventTokenAddress, eventTokenSymbol, eventAmount, now);
		
        }
        else 
        {
			
			UpdateUserData1(s.tokenAddress, s.id);
				
		}
        
    }   
	
	function UpdateUserData1(address tokenAddress, uint256 id) private {
			
		Safe storage s = _safes[id];
        
        require(s.id != 0);
        require(s.tokenAddress == tokenAddress);		
			
			uint256 timeframe  			= sub(now, s.lasttime);			                            
			uint256 CalculateWithdraw 	= div(mul(div(mul(s.amount, s.percentage), 100), timeframe), seconds30days); 
		 
		                         
			uint256 MaxWithdraw 		= div(s.amount, 10);
			
			 
			if (CalculateWithdraw > MaxWithdraw) { 				
			uint256 MaxAccumulation = MaxWithdraw; 
			} else { MaxAccumulation = CalculateWithdraw; }
			
			 
			if (MaxAccumulation > s.amountbalance) { 			     	
			uint256 realAmount1 = s.amountbalance; 
			} else { realAmount1 = MaxAccumulation; }
			
			 
			
			uint256 amountbalance72 = div(mul(s.amount, 72), 100);
			
			if (s.amountbalance >= amountbalance72) { 				
			uint256 realAmount = add(realAmount1, s.cashbackbalance); 
			} else { realAmount = realAmount1; }	
			
			s.lastwithdraw = realAmount;  			
			uint256 newamountbalance = sub(s.amountbalance, realAmount);	   	          			
			UpdateUserData2(tokenAddress, id, newamountbalance, realAmount);
					
    }   

    function UpdateUserData2(address tokenAddress, uint256 id, uint256 newamountbalance, uint256 realAmount) private {
        Safe storage s = _safes[id];
        
        require(s.id != 0);
        require(s.tokenAddress == tokenAddress);

        uint256 eventAmount;
        address eventTokenAddress = s.tokenAddress;
        string memory eventTokenSymbol = s.tokenSymbol;		

		s.amountbalance 				= newamountbalance;  
		s.lasttime 						= now;  
		
			uint256 tokenaffiliate 		= div(mul(s.amount, affiliate), 100) ; 
			uint256 maxcashback 		= div(mul(s.amount, cashback), 100) ; 		
			uint256 tokenreceived 		= sub(add(sub(sub(s.amount, tokenaffiliate), newamountbalance), s.cashbackbalance), maxcashback) ;		
		 
			
			 
			
			uint256 percentagereceived 	= div(mul(tokenreceived, 100000000000000000000), s.amount) ; 	
		
		s.tokenreceive 					= tokenreceived; 
		s.percentagereceive 			= percentagereceived; 		
		_totalSaved[s.tokenAddress] 	= sub(_totalSaved[s.tokenAddress], realAmount); 
		
		
	        PayToken(s.user, s.tokenAddress, realAmount);           		
            eventAmount = realAmount;
			
			emit onClaimTokens(msg.sender, eventTokenAddress, eventTokenSymbol, eventAmount, now);
    } 
	

    function PayToken(address user, address tokenAddress, uint256 amount) private {
		
		AllPayments[tokenAddress] 					= add(AllPayments[tokenAddress], amount);
		LifetimePayments[msg.sender][tokenAddress] 	= add(LifetimePayments[user][tokenAddress], amount); 
        
        ERC20Interface token = ERC20Interface(tokenAddress);        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(user, amount);
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
		
		_totalSaved[tokenAddress] 		= sub(_totalSaved[tokenAddress], amount); 
		AllPayments[tokenAddress] 		= add(AllPayments[tokenAddress], amount);
		
		uint256 eventAmount				= amount;
        address eventTokenAddress 		= tokenAddress;
        string 	memory eventTokenSymbol = ContractSymbol[tokenAddress];	
		
		Affiliatevault[msg.sender][tokenAddress] = 0;
        
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
	
	
	
	   	

 
    function AddContractAddress(address tokenAddress, bool contractstatus, uint256 _maxcontribution, string _ContractSymbol) public restricted {
        contractaddress[tokenAddress] 	= contractstatus;
		ContractSymbol[tokenAddress] 	= _ContractSymbol;
		maxcontribution[tokenAddress] 	= _maxcontribution;
		
		if (DefaultToken == 0) {
			DefaultToken = tokenAddress;
		}
		
		if (tokenAddress == DefaultToken && contractstatus == false) {
			contractaddress[tokenAddress] 	= true;
		}	
		
		emit onAddContractAddress(tokenAddress, contractstatus, _maxcontribution, _ContractSymbol);
    }
	
	
 
    function AddMaxContribution(address tokenAddress, uint256 _maxcontribution) public restricted  {
        maxcontribution[tokenAddress] = _maxcontribution;	
    }
	
	
 
    function UnlockTokens(address tokenAddress, uint256 id) public restricted {
        require(tokenAddress != 0x0);
        require(id != 0);      
        UnlockToken(tokenAddress, id);
    }
	
    
 
    function ChangeHodlingTime(uint256 newHodlingDays) restricted public {
        require(newHodlingDays >= 180);      
        hodlingTime = newHodlingDays * 1 days;
    }   
	
 
    function ChangeSpeedDistribution(uint256 newSpeed) restricted public {
        require(newSpeed >= 3 && newSpeed <= 12);   	
		percent = newSpeed;
    }
	
	
 
    function WithdrawEth(uint256 amount) restricted public {
        require(amount > 0); 
        require(address(this).balance >= amount); 
        
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
				
				UpdateUserData1(s.tokenAddress, s.id);
				WithdrawAffiliate(s.user, s.tokenAddress);	   
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
		
        emit onReturnAll(returned);
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