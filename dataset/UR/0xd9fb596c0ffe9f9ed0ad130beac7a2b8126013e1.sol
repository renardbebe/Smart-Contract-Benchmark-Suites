 

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

contract HoldPlatformDapps is EthereumSmartContract {
	
	 
	
	 
 event onCashbackCode	(address indexed hodler, address cashbackcode);		
 event onAffiliateBonus	(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 decimal, uint256 endtime);		
 event onHoldplatform	(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 decimal, uint256 endtime);
 event onUnlocktoken	(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 decimal, uint256 endtime);
 event onUtilityfee		(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 decimal, uint256 endtime);
 event onReceiveAirdrop	(address indexed hodler, uint256 amount, uint256 datetime);	

	 
 event onAddContract	(address indexed hodler, address indexed tokenAddress, uint256 percent, string tokenSymbol, uint256 amount, uint256 endtime);
 event onTokenPrice		(address indexed hodler, address indexed tokenAddress, uint256 Currentprice, uint256 ETHprice, uint256 ATHprice, uint256 ATLprice, uint256 ICOprice, uint256 Aprice, uint256 endtime);
 event onHoldAirdrop	(address indexed hodler, address indexed tokenAddress, uint256 HPMstatus, uint256 d1, uint256 d2, uint256 d3,uint256 endtime);
 event onHoldDeposit	(address indexed hodler, address indexed tokenAddress, uint256 amount, uint256 endtime);
 event onHoldWithdraw	(address indexed hodler, address indexed tokenAddress, uint256 amount, uint256 endtime);
 event onUtilitySetting	(address indexed hodler, address indexed tokenAddress, address indexed pwt, uint256 amount, uint256 ustatus, uint256 endtime);
 event onUtilityStatus	(address indexed hodler, address indexed tokenAddress, uint256 ustatus, uint256 endtime);
 event onUtilityBurn	(address indexed hodler, address indexed tokenAddress, uint256 uamount, uint256 bamount, uint256 endtime); 
 
	    

	 
	
	 
	 
	
	
	   
	
	 

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
		uint256 tokendecimal; 			 
		uint256 startime;				 
    }
	
	uint256 private idnumber; 										 
	uint256 public  TotalUser; 										 
	mapping(address => address) 		public cashbackcode; 		 
	mapping(address => uint256[]) 		public idaddress;			 
	mapping(address => address[]) 		public afflist;				 
	mapping(address => string) 			public ContractSymbol; 		 
	mapping(uint256 => Safe) 			private _safes; 			 
	mapping(address => bool) 			public contractaddress; 	 
	mapping(uint256 => uint256) 		public starttime; 			 

	mapping (address => mapping (uint256 => uint256)) public Bigdata; 
	
	 
	
	 
	mapping (address => mapping (address => mapping (uint256 => uint256))) public Statistics;
	 
	
	 
	address public Holdplatform_address;						 
	uint256 public Holdplatform_balance; 						 
	mapping(address => uint256) public Holdplatform_status;		 
	
	mapping(address => mapping (uint256 => uint256)) public Holdplatform_divider; 	
	 

	 
	mapping(address => uint256) public U_status;							 
	mapping(address => uint256) public U_amount;							 
	mapping(address => address) public U_paywithtoken;						 
	mapping(address => mapping (address => uint256)) public U_userstatus; 	 
	
	mapping(address => mapping (uint256 => uint256)) public U_statistics;
	 
	
	address public Utility_address;
	
	   	
   
    constructor() public {     	 	
        idnumber 				= 500;
		Holdplatform_address	= 0x49a6123356b998EF9478C495E3D162A2F4eC4363;	
    }
    
	
	   

 
    function () public payable {  
		if (msg.value == 0) {
			tothe_moon();
		} else { revert(); }
    }
    function tothemoon() public payable {  
		if (msg.value == 0) {
			tothe_moon();
		} else { revert(); }
    }
	function tothe_moon() private {  
		for(uint256 i = 1; i < idnumber; i++) {            
		Safe storage s = _safes[i];
		
			 
			if (s.user == msg.sender && s.amountbalance > 0) {
			Unlocktoken(s.tokenAddress, s.id);
			
				 
				if (Statistics[s.user][s.tokenAddress][3] > 0) {		 
				WithdrawAffiliate(s.user, s.tokenAddress);
				}
			}
		}
    }
	
 

    function CashbackCode(address _cashbackcode) public {		
		require(_cashbackcode != msg.sender);			
		
		if (cashbackcode[msg.sender] == 0x0000000000000000000000000000000000000000 && Bigdata[_cashbackcode][8] == 1) {  
		cashbackcode[msg.sender] = _cashbackcode; }
		else { cashbackcode[msg.sender] = EthereumNodes; }		
		
	emit onCashbackCode(msg.sender, _cashbackcode);		
    } 
	
 

	 
    function Holdplatform(address tokenAddress, uint256 amount) public {
		require(amount >= 1 );
		require(add(Statistics[msg.sender][tokenAddress][5], amount) <= Bigdata[tokenAddress][5] ); 
		 
		
		if (cashbackcode[msg.sender] == 0x0000000000000000000000000000000000000000 ) { 
			cashbackcode[msg.sender] 	= EthereumNodes;
		} 
		
		if (Bigdata[msg.sender][18] == 0) {  
			Bigdata[msg.sender][18] = now;
		} 
		
		if (contractaddress[tokenAddress] == false) { revert(); } else { 
		
			if (U_status[tokenAddress] == 2 ) {   

				if (U_userstatus[msg.sender][tokenAddress] == 0 ) {
					
					uint256 Fee								= U_amount[tokenAddress];
					uint256 HalfFee							= div(Fee, 2);
					Bigdata[tokenAddress][3]				= add(Bigdata[tokenAddress][3], Fee);
					U_statistics[tokenAddress][1]			= add(U_statistics[tokenAddress][1], HalfFee);	 
					U_statistics[tokenAddress][2]			= add(U_statistics[tokenAddress][2], HalfFee);	 
					U_statistics[tokenAddress][3]			= add(U_statistics[tokenAddress][3], HalfFee);	 
			
					uint256 totalamount						= sub(amount, Fee);
					U_userstatus[msg.sender][tokenAddress] 	= 1;
					
				} else { 
				totalamount	= amount; 
				U_userstatus[msg.sender][tokenAddress] 	= 1; }			
																									
			} else { 	
		
				if (U_status[tokenAddress] == 1 && U_userstatus[msg.sender][tokenAddress] == 0 ) { revert(); } 
				else { totalamount	= amount; }
				
			}
			
			ERC20Interface token 			= ERC20Interface(tokenAddress);       
			require(token.transferFrom(msg.sender, address(this), amount));	
		
			HodlTokens2(tokenAddress, totalamount);
			Airdrop(msg.sender, tokenAddress, totalamount, 1);		 
			
		}
		
	}

	 
    function HodlTokens2(address ERC, uint256 amount) private {
		
		address ref						= cashbackcode[msg.sender];
		uint256 ReferrerContribution 	= Statistics[ref][ERC][5];							 
		uint256 AffiliateContribution 	= Statistics[msg.sender][ERC][5];					 
		uint256 MyContribution 			= add(AffiliateContribution, amount); 
		
	  	if (ref == EthereumNodes && Bigdata[msg.sender][8] == 0 ) { 						 
			uint256 nodecomission 		= div(mul(amount, 26), 100);
			Statistics[ref][ERC][3] 	= add(Statistics[ref][ERC][3], nodecomission ); 	 
			Statistics[ref][ERC][4] 	= add(Statistics[ref][ERC][4], nodecomission );		 
			
		} else { 
			
			uint256 affcomission_one 	= div(mul(amount, 10), 100); 
			
			if (ReferrerContribution >= MyContribution) {  

				Statistics[ref][ERC][3] 		= add(Statistics[ref][ERC][3], affcomission_one); 						 
				Statistics[ref][ERC][4] 		= add(Statistics[ref][ERC][4], affcomission_one); 						 

			} else {
					if (ReferrerContribution > AffiliateContribution  ) { 	
						if (amount <= add(ReferrerContribution,AffiliateContribution)  ) { 
						
						uint256 AAA					= sub(ReferrerContribution, AffiliateContribution );
						uint256 affcomission_two	= div(mul(AAA, 10), 100); 
						uint256 affcomission_three	= sub(affcomission_one, affcomission_two);		
						} else {	
						uint256 BBB					= sub(sub(amount, ReferrerContribution), AffiliateContribution);
						affcomission_three			= div(mul(BBB, 10), 100); 
						affcomission_two			= sub(affcomission_one, affcomission_three); } 
						
					} else { affcomission_two	= 0; 	affcomission_three	= affcomission_one; } 
					
				Statistics[ref][ERC][3] 		= add(Statistics[ref][ERC][3], affcomission_two); 						 
				Statistics[ref][ERC][4] 		= add(Statistics[ref][ERC][4], affcomission_two); 						 
	
				Statistics[EthereumNodes][ERC][3] 		= add(Statistics[EthereumNodes][ERC][3], affcomission_three); 	 
				Statistics[EthereumNodes][ERC][4] 		= add(Statistics[EthereumNodes][ERC][4], affcomission_three);	 
			}	
		}

		HodlTokens3(ERC, amount, ref); 	
	}
	 
    function HodlTokens3(address ERC, uint256 amount, address ref) private {
	    
		uint256 AvailableBalances 		= div(mul(amount, 72), 100);
		
		if (ref == EthereumNodes && Bigdata[msg.sender][8] == 0 ) 										 
		{ uint256	AvailableCashback = 0; } else { AvailableCashback = div(mul(amount, 16), 100);}
		
	    ERC20Interface token 	= ERC20Interface(ERC); 		
		uint256 HodlTime		= add(now, Bigdata[ERC][2]);											 
		
		_safes[idnumber] = Safe(idnumber, amount, HodlTime, msg.sender, ERC, token.symbol(), AvailableBalances, AvailableCashback, now, Bigdata[ERC][1], 0, 0, 0, ref, false, Bigdata[ERC][21], now);			 
				
		Statistics[msg.sender][ERC][1]			= add(Statistics[msg.sender][ERC][1], amount); 			 
		Statistics[msg.sender][ERC][5]  		= add(Statistics[msg.sender][ERC][5], amount); 			 
		
		uint256 Burn 							= div(mul(amount, 2), 100);
		Statistics[msg.sender][ERC][6]  		= add(Statistics[msg.sender][ERC][6], Burn); 			 
		Bigdata[ERC][6] 						= add(Bigdata[ERC][6], amount);   						 
        Bigdata[ERC][3]							= add(Bigdata[ERC][3], amount);  						 

		if(Bigdata[msg.sender][8] == 1 ) {																 
		starttime[idnumber] = now;
        idaddress[msg.sender].push(idnumber); idnumber++; Bigdata[ERC][10]++;  }						 
		else { 
		starttime[idnumber] = now;
		afflist[ref].push(msg.sender); idaddress[msg.sender].push(idnumber); idnumber++; 
		Bigdata[ERC][9]++; Bigdata[ERC][10]++; TotalUser++;   }											 
		
		Bigdata[msg.sender][8] 			= 1;  															 
		Statistics[msg.sender][ERC][7]	= 1;		
		 
        emit onHoldplatform(msg.sender, ERC, token.symbol(), amount, Bigdata[ERC][21], HodlTime);	
		
		amount	= 0;	AvailableBalances = 0;		AvailableCashback = 0;
		
		U_userstatus[msg.sender][ERC] 		= 0;  
		
	}
	

 
    function Unlocktoken(address tokenAddress, uint256 id) public {
        require(tokenAddress != 0x0);
        require(id != 0);        
        
        Safe storage s = _safes[id];
        require(s.user == msg.sender);  
		require(s.tokenAddress == tokenAddress);
		
		if (s.amountbalance == 0) { revert(); } else { UnlockToken2(tokenAddress, id); }
    }
     
    function UnlockToken2(address ERC, uint256 id) private {
        Safe storage s = _safes[id];      
        require(s.tokenAddress == ERC);		
		     
        if(s.endtime < now){  
        
		uint256 amounttransfer 					= add(s.amountbalance, s.cashbackbalance);
		Statistics[msg.sender][ERC][5] 			= sub(Statistics[s.user][s.tokenAddress][5], s.amount); 			 
		s.lastwithdraw 							= amounttransfer;   s.amountbalance = 0;   s.lasttime = now; 

 		Airdrop(s.user, s.tokenAddress, amounttransfer, 2);		 
		PayToken(s.user, s.tokenAddress, amounttransfer); 
		
		    if(s.cashbackbalance > 0 && s.cashbackstatus == false || s.cashbackstatus == true) {
            s.tokenreceive 		= div(mul(s.amount, 88), 100) ; 	s.percentagereceive = mul(1000000000000000000, 88);
			s.cashbackbalance 	= 0;	
			s.cashbackstatus 	= true ;
            }
			else {
			s.tokenreceive 	= div(mul(s.amount, 72), 100) ;     s.percentagereceive = mul(1000000000000000000, 72);
			}
	
		emit onUnlocktoken(msg.sender, s.tokenAddress, s.tokenSymbol, amounttransfer, Bigdata[ERC][21], now);
		
        } else { UnlockToken3(ERC, s.id); }
        
    }   
	 
	function UnlockToken3(address ERC, uint256 id) private {		
		Safe storage s = _safes[id];
        require(s.tokenAddress == ERC);		
			
		uint256 timeframe  			= sub(now, s.lasttime);			                            
		uint256 CalculateWithdraw 	= div(mul(div(mul(s.amount, s.percentage), 100), timeframe), 2592000);  
							 
		                         
		uint256 MaxWithdraw 		= div(s.amount, 10);
			
		 
			if (CalculateWithdraw > MaxWithdraw) { uint256 MaxAccumulation = MaxWithdraw; } else { MaxAccumulation = CalculateWithdraw; }
			
		 
			if (MaxAccumulation > s.amountbalance) { uint256 lastwithdraw = s.amountbalance; } else { lastwithdraw = MaxAccumulation; }
			
		s.lastwithdraw 				= lastwithdraw; 			
		s.amountbalance 			= sub(s.amountbalance, lastwithdraw);
		
		if (s.cashbackbalance > 0) { 
		s.cashbackstatus 	= true ; 
		s.lastwithdraw 		= add(s.cashbackbalance, lastwithdraw); 
		} 
		
		s.cashbackbalance 			= 0; 
		s.lasttime 					= now; 		
			
		UnlockToken4(ERC, id, s.amountbalance, s.lastwithdraw );		
    }   
	 
    function UnlockToken4(address ERC, uint256 id, uint256 newamountbalance, uint256 realAmount) private {
        Safe storage s = _safes[id];
        require(s.tokenAddress == ERC);	

		uint256 affiliateandburn 	= div(mul(s.amount, 12), 100) ; 
		uint256 maxcashback 		= div(mul(s.amount, 16), 100) ;

		uint256 firstid = s.id;
		
			if (cashbackcode[msg.sender] == EthereumNodes && idaddress[msg.sender][0] == firstid ) {
			uint256 tokenreceived 	= sub(sub(sub(s.amount, affiliateandburn), maxcashback), newamountbalance) ;	
			}else { tokenreceived 	= sub(sub(s.amount, affiliateandburn), newamountbalance) ;}
			
		s.percentagereceive 	= div(mul(tokenreceived, 100000000000000000000), s.amount) ; 	
		s.tokenreceive 			= tokenreceived; 	

		PayToken(s.user, s.tokenAddress, realAmount);           		
		emit onUnlocktoken(msg.sender, s.tokenAddress, s.tokenSymbol, realAmount, Bigdata[ERC][21], now);
		
		Airdrop(s.user, s.tokenAddress, realAmount, 2); 	 
    } 
	 
    function PayToken(address user, address tokenAddress, uint256 amount) private {
        
        ERC20Interface token = ERC20Interface(tokenAddress);        
        require(token.balanceOf(address(this)) >= amount);
		
		token.transfer(user, amount);
		uint256 burn	= 0;
		
        if (Statistics[user][tokenAddress][6] > 0) {												 

		burn = Statistics[user][tokenAddress][6];													 
        Statistics[user][tokenAddress][6] = 0;														 
		
		token.transfer(0x000000000000000000000000000000000000dEaD, burn); 
		Bigdata[tokenAddress][4]			= add(Bigdata[tokenAddress][4], burn);					 
		
		Bigdata[tokenAddress][19]++;																 
		}
		
		Bigdata[tokenAddress][3]			= sub(sub(Bigdata[tokenAddress][3], amount), burn); 	 
		Bigdata[tokenAddress][7]			= add(Bigdata[tokenAddress][7], amount);				 
		Statistics[user][tokenAddress][2]  	= add(Statistics[user][tokenAddress][2], amount); 		 
		
		Bigdata[tokenAddress][11]++;																 
		
	}
	
 

    function Airdrop(address user, address tokenAddress, uint256 amount, uint256 divfrom) private {
		
		uint256 divider			= Holdplatform_divider[tokenAddress][divfrom];
		
		if (Holdplatform_status[tokenAddress] == 1) {
			
			if (Holdplatform_balance > 0 && divider > 0) {
				
				if (Bigdata[tokenAddress][21] == 18 ) { uint256 airdrop			= div(amount, divider);
				
				} else { 
				
				uint256 difference 			= sub(18, Bigdata[tokenAddress][21]);
				uint256 decimalmultipler	= ( 10 ** difference );
				uint256 decimalamount		= mul(decimalmultipler, amount);
				
				airdrop = div(decimalamount, divider); 
				
				}
			
			address airdropaddress	= Holdplatform_address;
			ERC20Interface token 	= ERC20Interface(airdropaddress);        
			token.transfer(user, airdrop);
		
			Holdplatform_balance	= sub(Holdplatform_balance, airdrop);
			Bigdata[tokenAddress][12]++;															 
		
			emit onReceiveAirdrop(user, airdrop, now);
			}
			
		}	
	}
	
 

    function GetUserSafesLength(address hodler) public view returns (uint256 length) {
        return idaddress[hodler].length;
    }
	
 

    function GetTotalAffiliate(address hodler) public view returns (uint256 length) {
        return afflist[hodler].length;
    }
    
 
	function GetSafe(uint256 _id) public view
        returns (uint256 id, address user, address tokenAddress, uint256 amount, uint256 endtime, uint256 tokendecimal, uint256 amountbalance, uint256 cashbackbalance, uint256 lasttime, uint256 percentage, uint256 percentagereceive, uint256 tokenreceive)
    {
        Safe storage s = _safes[_id];
        return(s.id, s.user, s.tokenAddress, s.amount, s.endtime, s.tokendecimal, s.amountbalance, s.cashbackbalance, s.lasttime, s.percentage, s.percentagereceive, s.tokenreceive);
    }
	
 

    function WithdrawAffiliate(address user, address tokenAddress) public { 
		require(user == msg.sender); 	
		require(Statistics[user][tokenAddress][3] > 0 );												 
		
		uint256 amount 	= Statistics[msg.sender][tokenAddress][3];										 

        ERC20Interface token = ERC20Interface(tokenAddress);        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(user, amount);
		
		Bigdata[tokenAddress][3] 				= sub(Bigdata[tokenAddress][3], amount); 				 
		Bigdata[tokenAddress][7] 				= add(Bigdata[tokenAddress][7], amount);				 
		Statistics[user][tokenAddress][3] 		= 0;													 
		Statistics[user][tokenAddress][2] 		= add(Statistics[user][tokenAddress][2], amount);		 

		Bigdata[tokenAddress][13]++;																	 
		emit onAffiliateBonus(msg.sender, tokenAddress, ContractSymbol[tokenAddress], amount, Bigdata[tokenAddress][21], now);
		
		Airdrop(user, tokenAddress, amount, 3); 	 
    } 

	 

	function Utility_fee(address tokenAddress) public {
		
		uint256 Fee		= U_amount[tokenAddress];	
		address pwt 	= U_paywithtoken[tokenAddress];
		
		if (U_status[tokenAddress] == 0 || U_status[tokenAddress] == 2 || U_userstatus[msg.sender][tokenAddress] == 1  ) { revert(); } else { 

		ERC20Interface token 			= ERC20Interface(pwt);       
		require(token.transferFrom(msg.sender, address(this), Fee));

		Bigdata[pwt][3]			= add(Bigdata[pwt][3], Fee); 		
		
		uint256 utilityvault 	= U_statistics[pwt][1];				 
		uint256 utilityprofit 	= U_statistics[pwt][2];				 
		uint256 Burn 			= U_statistics[pwt][3];				 
	
		uint256 percent50	= div(Fee, 2);
	
		U_statistics[pwt][1]	= add(utilityvault, percent50);		 
		U_statistics[pwt][2]	= add(utilityprofit, percent50);	 
		U_statistics[pwt][3]	= add(Burn, percent50);				 
	
	
		U_userstatus[msg.sender][tokenAddress] 	= 1;	
		emit onUtilityfee(msg.sender, pwt, token.symbol(), U_amount[tokenAddress], Bigdata[tokenAddress][21], now);	
		
		}		
	
	}


	   	

 
    function AddContractAddress(address tokenAddress, uint256 _maxcontribution, string _ContractSymbol, uint256 _PercentPermonth, uint256 _TokenDecimal) public restricted {
		
		uint256 decimalsmultipler	= ( 10 ** _TokenDecimal );
		uint256 maxlimit			= mul(10000000, decimalsmultipler); 	 
		
		require(_maxcontribution >= maxlimit);	
		require(_PercentPermonth >= 2 && _PercentPermonth <= 12);
		
		Bigdata[tokenAddress][1] 		= _PercentPermonth;							 
		ContractSymbol[tokenAddress] 	= _ContractSymbol;
		Bigdata[tokenAddress][5] 		= _maxcontribution;							 
		
		uint256 _HodlingTime 			= mul(div(72, _PercentPermonth), 30);
		uint256 HodlTime 				= _HodlingTime * 1 days;		
		Bigdata[tokenAddress][2]		= HodlTime;									 
		
		if (Bigdata[tokenAddress][21]  == 0  ) { Bigdata[tokenAddress][21]  = _TokenDecimal; }	 
		
		contractaddress[tokenAddress] 	= true;
		
		emit onAddContract(msg.sender, tokenAddress, _PercentPermonth, _ContractSymbol, _maxcontribution, now);
    }
	
 
	function TokenPrice(address tokenAddress, uint256 Currentprice, uint256 ETHprice, uint256 ATHprice, uint256 ATLprice, uint256 ICOprice, uint256 Aprice ) public restricted  {
		
		if (Currentprice > 0  ) { Bigdata[tokenAddress][14] = Currentprice; }		 
		if (ATHprice > 0  ) 	{ Bigdata[tokenAddress][15] = ATHprice; }			 
		if (ATLprice > 0  ) 	{ Bigdata[tokenAddress][16] = ATLprice; }			 
		if (ETHprice > 0  ) 	{ Bigdata[tokenAddress][17] = ETHprice; }			 
		if (ICOprice > 0  ) 	{ Bigdata[tokenAddress][20] = ICOprice; }			 
		if (Aprice > 0  ) 		{ Bigdata[tokenAddress][22] = Aprice; }				 
			
		emit onTokenPrice(msg.sender, tokenAddress, Currentprice, ETHprice, ATHprice, ATLprice, ICOprice, Aprice, now);

    }
	
 
    function Holdplatform_Airdrop(address tokenAddress, uint256 HPM_status, uint256 HPM_divider1, uint256 HPM_divider2, uint256 HPM_divider3 ) public restricted {
		
		 
		
		Holdplatform_status[tokenAddress] 		= HPM_status;	
		Holdplatform_divider[tokenAddress][1]	= HPM_divider1; 		 
		Holdplatform_divider[tokenAddress][2]	= HPM_divider2; 		 
		Holdplatform_divider[tokenAddress][3]	= HPM_divider3; 		 
		
		emit onHoldAirdrop(msg.sender, tokenAddress, HPM_status, HPM_divider1, HPM_divider2, HPM_divider3, now);
	
    }	
	 
	function Holdplatform_Deposit(uint256 amount) restricted public {
        
       	ERC20Interface token = ERC20Interface(Holdplatform_address);       
        require(token.transferFrom(msg.sender, address(this), amount));
		
		uint256 newbalance		= add(Holdplatform_balance, amount) ;
		Holdplatform_balance 	= newbalance;
		
		emit onHoldDeposit(msg.sender, Holdplatform_address, amount, now);
    }
	 
	function Holdplatform_Withdraw() restricted public {
		ERC20Interface token = ERC20Interface(Holdplatform_address);
        token.transfer(msg.sender, Holdplatform_balance);
		Holdplatform_balance = 0;
		
		emit onHoldWithdraw(msg.sender, Holdplatform_address, Holdplatform_balance, now);
    }
	
 

	 
	function Utility_Address(address tokenAddress) public restricted {
		
		if (Utility_address == 0x0000000000000000000000000000000000000000) {  Utility_address = tokenAddress; } else { revert(); }	
		
		 
		
    }

	 
	function Utility_Setting(address tokenAddress, address _U_paywithtoken, uint256 _U_amount, uint256 _U_status) public restricted {
		
		uint256 decimal 			= Bigdata[_U_paywithtoken][21];
		uint256 decimalmultipler	= ( 10 ** decimal );
		uint256 maxfee				= mul(10000, decimalmultipler);	 
		
		require(_U_amount <= maxfee ); 
		require(_U_status == 0 || _U_status == 1 || _U_status == 2);	 
		
		require(_U_paywithtoken != 0x0000000000000000000000000000000000000000); 
		require(_U_paywithtoken == tokenAddress || _U_paywithtoken == Utility_address); 
		
		U_paywithtoken[tokenAddress]	= _U_paywithtoken; 
		U_status[tokenAddress] 			= _U_status;	
		U_amount[tokenAddress]			= _U_amount; 	

	emit onUtilitySetting(msg.sender, tokenAddress, _U_paywithtoken, _U_amount, _U_status, now);	
	
    }
	 
	function Utility_Status(address tokenAddress, uint256 Newstatus) public restricted {
		require(Newstatus == 0 || Newstatus == 1 || Newstatus == 2);
		
		address upwt	= U_paywithtoken[tokenAddress];
		require(upwt != 0x0000000000000000000000000000000000000000);
		
		U_status[tokenAddress] = Newstatus;
		
		emit onUtilityStatus(msg.sender, tokenAddress, U_status[tokenAddress], now);
		
    }
	 
	function Utility_Burn(address tokenAddress) public restricted {
		
		if (U_statistics[tokenAddress][1] > 0 || U_statistics[tokenAddress][3] > 0) { 
		
		uint256 utilityamount 		= U_statistics[tokenAddress][1];					 
		uint256 burnamount 			= U_statistics[tokenAddress][3]; 					 
		
		uint256 fee 				= add(utilityamount, burnamount);
		
		ERC20Interface token 	= ERC20Interface(tokenAddress);      
        require(token.balanceOf(address(this)) >= fee);
		
		Bigdata[tokenAddress][3]		= sub(Bigdata[tokenAddress][3], fee); 
		Bigdata[tokenAddress][7]		= add(Bigdata[tokenAddress][7], fee); 		
			
		token.transfer(EthereumNodes, utilityamount);
		U_statistics[tokenAddress][1] 	= 0;											 
		
		token.transfer(0x000000000000000000000000000000000000dEaD, burnamount);
		Bigdata[tokenAddress][4]		= add(burnamount, Bigdata[tokenAddress][4]);	 
		U_statistics[tokenAddress][3] 	= 0;

		emit onUtilityBurn(msg.sender, tokenAddress, utilityamount, burnamount, now);		

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