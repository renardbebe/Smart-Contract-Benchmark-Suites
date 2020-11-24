 

pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

 

contract OwnableContract {    
    event onTransferOwnership(address newOwner);
	address superOwner; 
	
    constructor() public { 
        superOwner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == superOwner);
        _;
    } 
	
    function viewSuperOwner() private view returns (address owner) {
        return superOwner;
    }
      
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != superOwner);
        
        superOwner = newOwner;
        
        emit onTransferOwnership(superOwner);
    }
}

 

contract BlockableContract is OwnableContract {
    
    event onBlockHODLs(bool status);
 
    bool public blockedContract;
    
    constructor() public { 
        blockedContract = false;  
    }
    
    modifier contractActive() {
        require(!blockedContract);
        _;
    } 
    
    function doBlockContract() onlyOwner public {
        blockedContract = true;
        
        emit onBlockHODLs(blockedContract);
    }
    
    function unBlockContract() onlyOwner public {
        blockedContract = false;
        
        emit onBlockHODLs(blockedContract);
    }
}

 

contract ldoh is BlockableContract {
    
    event onStoreProfileHash(address indexed hodler, string profileHashed);
    event onHodlTokens(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 endtime);
    event onClaimTokens(address indexed hodler, address indexed tokenAddress, string tokenSymbol, uint256 amount, uint256 endtime);
    event onReturnAll(uint256 returned);

     
	
    address internal AXPRtoken;
    mapping(address => string) private profileHashed; 	 

	 
	
	 
	
	uint256 public  hodlingTime;
	uint256 public 	comission;
    uint256 public  allTimeHighPrice;
	uint256 public  percent 				= 3;        	 
	uint256 private constant affiliate 		= 12;        	 
	uint256 private constant cashback 		= 16;        	 
	uint256 private constant totalreceive 	= 88;        	 
    uint256 private constant seconds30days 	= 2592000;  	 
	
	bool public speed;

    struct Safe {
        uint256 id;
        uint256 amount;
        uint256 endtime;
        address user;
        address tokenAddress;
		string tokenSymbol;	
		uint256 amountbalance; 			 
		uint256 cashbackbalance; 		 
		uint256 lasttime; 				 
		uint256 percentage; 			 
		uint256 percentagereceive; 		 
		uint256 tokenreceive; 			 
		uint256 affiliateprofit; 		 
		uint256 affiliatebalance; 		 
		address referrer; 				 

    }
    
     
  
    mapping(address => uint256[]) 	private _userSafes; 		 
    mapping(uint256 => Safe) 		private _safes; 			 
    uint256 						private _currentIndex; 		 
    uint256 						public 	_countSafes; 	     
    mapping(address => uint256) 	public 	_totalSaved; 		 
	
     
    mapping(address => uint256) 	private _systemReserves;     
    address[] 						public 	_listedReserves;
    
     
   
    constructor() public {
        
        AXPRtoken 		= 0xC39E626A04C5971D770e319760D7926502975e47;
        
        hodlingTime 	= 365 days;
        _currentIndex 	= 1;
        comission 		= 5;
    }
    
	
 
	
 
    
    function () public payable {
        require(msg.value > 0);
        
        _systemReserves[0x0] = add(_systemReserves[0x0], msg.value);
    }


 
	
    function HodlTokens(address tokenAddress, uint256 amount) public contractActive {
        require(tokenAddress != 0x0);
        require(amount > 0);

          
        ERC20Interface token = ERC20Interface(tokenAddress);
        
        require(token.transferFrom(msg.sender, address(this), amount));
		
		    uint256 affiliatecomission 		= mul(amount, affiliate) / 100; 	 
            uint256 data_amountbalance 		= sub(amount, affiliatecomission); 	 
			uint256 data_cashbackbalance 	= mul(amount, cashback) / 100; 		 
			  		  
		 
			 	  
		_userSafes[msg.sender].push(_currentIndex);
		_safes[_currentIndex] = 

		Safe(

		_currentIndex, amount, now + hodlingTime, msg.sender, tokenAddress, token.symbol(), data_amountbalance, data_cashbackbalance, now, percent, 0, 0, 0, 0, 0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3);
				
		
		 
		
        _totalSaved[tokenAddress] = add(_totalSaved[tokenAddress], amount);        
        _currentIndex++;
        _countSafes++;
        
        emit onHodlTokens(msg.sender, tokenAddress, token.symbol(), amount, now + hodlingTime);
    }
	
	
 
	
    function ClaimTokens(address tokenAddress, uint256 id) public {
        require(tokenAddress != 0x0);
        require(id != 0);        
        
        Safe storage s = _safes[id];
        require(s.user == msg.sender);
        
        RetireHodl(tokenAddress, id);
    }
    
    function RetireHodl(address tokenAddress, uint256 id) private {

        Safe storage s = _safes[id];
        
        require(s.id != 0);
        require(s.tokenAddress == tokenAddress);
        require(
                (tokenAddress == AXPRtoken && s.endtime < now ) ||
                    tokenAddress != AXPRtoken
                );

        uint256 eventAmount;
        address eventTokenAddress = s.tokenAddress;
        string memory eventTokenSymbol = s.tokenSymbol;
        
        if(s.endtime < now)  
        {
            PayToken(s.user, s.tokenAddress, s.amountbalance);
            
            eventAmount = s.amountbalance;
		   _totalSaved[s.tokenAddress] = sub(_totalSaved[s.tokenAddress], s.amountbalance);  
			
	    s.amountbalance = 0;
		
        }
        else  
        {
			
				if (speed == true) {
				uint256 final_speed = 6;
				}
				else {
				final_speed = 3;
				}
			
			uint256 timeframe  = now - s.lasttime;
			uint256 realAmount = s.amount * final_speed / 100 * timeframe / seconds30days ;
          				
			uint256 newamountbalance = sub(s.amountbalance, realAmount);	  
            			
		s.amountbalance = newamountbalance;   
		s.lasttime = now;   

		
			uint256 tokenaffiliate = mul(s.amount, affiliate) / 100 ;  
			uint256 tokenreceived = s.amount - tokenaffiliate - newamountbalance;	   
			uint256 percentagereceived = tokenreceived / s.amount * 100;	   
		
		s.tokenreceive = tokenreceived;  
		s.percentagereceive = percentagereceived;  
		_totalSaved[s.tokenAddress] = sub(_totalSaved[s.tokenAddress], realAmount);  
		
		
	        PayToken(s.user, s.tokenAddress, realAmount);           
            eventAmount = realAmount;
				
		}
        
        emit onClaimTokens(msg.sender, eventTokenAddress, eventTokenSymbol, eventAmount, now);
    }    
    
	
 
	
    function StoreComission(address tokenAddress, uint256 amount) private {
            
        _systemReserves[tokenAddress] = add(_systemReserves[tokenAddress], amount);
        
        bool isNew = true;
        for(uint256 i = 0; i < _listedReserves.length; i++) {
            if(_listedReserves[i] == tokenAddress) {
                isNew = false;
                break;
            }
        }         
        if(isNew) _listedReserves.push(tokenAddress); 
    }    
    
	
	
 
    
    function PayToken(address user, address tokenAddress, uint256 amount) private {
        
        ERC20Interface token = ERC20Interface(tokenAddress);
        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(user, amount);
    }   
    
	
 
    
    function DeleteSafe(Safe s) private {
        
        _totalSaved[s.tokenAddress] = sub(_totalSaved[s.tokenAddress], s.amount);
        delete _safes[s.id];
        
        uint256[] storage vector = _userSafes[msg.sender];
        uint256 size = vector.length; 
        for(uint256 i = 0; i < size; i++) {
            if(vector[i] == s.id) {
                vector[i] = vector[size-1];
                vector.length--;
                break;
            }
        } 
    }

	
 
    
    function GetUserSafesLength(address hodler) public view returns (uint256 length) {
        return _userSafes[hodler].length;
    }
    
	
 
    
	function GetSafe(uint256 _id) public view
        returns (uint256 id, address user, address tokenAddress, uint256 amount, uint256 endtime, string tokenSymbol, uint256 amountbalance, uint256 lasttime, uint256 percentage, uint256 percentagereceive, uint256 tokenreceive, address referrer)
    {
        Safe storage s = _safes[_id];
        return(s.id, s.user, s.tokenAddress, s.amount, s.endtime, s.tokenSymbol, s.amountbalance, s.lasttime, s.percentage, s.percentagereceive, s.tokenreceive, s.referrer);
    }

 
    
    function GetContractBalance() public view returns(uint256)
    {
        return address(this).balance;
    }   	

	
 
    
    function GetTokenFees(address tokenAddress) private view returns (uint256 amount) {
        return _systemReserves[tokenAddress];
    }    
    
    
 
 
    
    function storeProfileHashed(string _profileHashed) private {
        profileHashed[msg.sender] = _profileHashed;        

        emit onStoreProfileHash(msg.sender, _profileHashed);
    }
    	
		
 
 

    function GetHodlTokensBalance(address tokenAddress) private view returns (uint256 balance) {
        require(tokenAddress != 0x0);
        
        for(uint256 i = 1; i < _currentIndex; i++) {            
            Safe storage s = _safes[i];
            if(s.user == msg.sender && s.tokenAddress == tokenAddress)
                balance += s.amount;
        }
        return balance;
    }	
	
	
	
 
	
 
	
 
    
    function OwnerRetireHodl(address tokenAddress, uint256 id) public onlyOwner {
        require(tokenAddress != 0x0);
        require(id != 0);
        
        RetireHodl(tokenAddress, id);
    }
    
	
 
    
    function ChangeHodlingTime(uint256 newHodlingDays) onlyOwner public {
        require(newHodlingDays >= 60);
        
        hodlingTime = newHodlingDays * 1 days;
    }   
    
 
    
    function ChangeAllTimeHighPrice(uint256 newAllTimeHighPrice) onlyOwner public {
        require(newAllTimeHighPrice > allTimeHighPrice);
        
        allTimeHighPrice = newAllTimeHighPrice;
    }              

	
 
    
    function ChangeComission(uint256 newComission) onlyOwner public {
        require(newComission <= 30);
        
        comission = newComission;
    }
    
 
    
    function WithdrawTokenFees(address tokenAddress) onlyOwner public {
        require(_systemReserves[tokenAddress] > 0);
        
        uint256 amount = _systemReserves[tokenAddress];
        _systemReserves[tokenAddress] = 0;
        
        ERC20Interface token = ERC20Interface(tokenAddress);
        
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(msg.sender, amount);
    }

 
    
    function WithdrawAllFees() onlyOwner public {
        
         
        uint256 x = _systemReserves[0x0];
        if(x > 0 && x <= address(this).balance) {
            _systemReserves[0x0] = 0;
            msg.sender.transfer(_systemReserves[0x0]);
        }
        
         
        address ta;
        ERC20Interface token;
        for(uint256 i = 0; i < _listedReserves.length; i++) {
            ta = _listedReserves[i];
            if(_systemReserves[ta] > 0)
            { 
                x = _systemReserves[ta];
                _systemReserves[ta] = 0;
                
                token = ERC20Interface(ta);
                token.transfer(msg.sender, x);
            }
        }
        _listedReserves.length = 0; 
    }
    

 
    
    function WithdrawEth(uint256 amount) onlyOwner public {
        require(amount > 0); 
        require(address(this).balance >= amount); 
        
        msg.sender.transfer(amount);
    }

 
        
    function GetTokensAddressesWithFees() 
        onlyOwner public view 
        returns (address[], string[], uint256[])
    {
        uint256 length = _listedReserves.length;
        
        address[] memory tokenAddress = new address[](length);
        string[] memory tokenSymbol = new string[](length);
        uint256[] memory tokenFees = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
    
            tokenAddress[i] = _listedReserves[i];
            
            ERC20Interface token = ERC20Interface(tokenAddress[i]);
            
            tokenSymbol[i] = token.symbol();
            tokenFees[i] = GetTokenFees(tokenAddress[i]);
        }
        
        return (tokenAddress, tokenSymbol, tokenFees);
    }

	
 
    
    function ReturnAllTokens(bool onlyAXPR) onlyOwner public
    {
        uint256 returned;

        for(uint256 i = 1; i < _currentIndex; i++) {            
            Safe storage s = _safes[i];
            if (s.id != 0) {
                if (
                    (onlyAXPR && s.tokenAddress == AXPRtoken) ||
                    !onlyAXPR
                    )
                {
                    PayToken(s.user, s.tokenAddress, s.amountbalance);
                    DeleteSafe(s);
                    
                    _countSafes--;
                    returned++;
                }
            }
        }

        emit onReturnAll(returned);
    }    
	
 

    function SpeedUp() onlyOwner public {
        speed = true;
    }
    
    function SpeedDown() onlyOwner public {
        speed = false;
    }

	
 
	
	
	

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }
    
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
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