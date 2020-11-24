 

pragma solidity ^0.4.23;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract BTYCToken is ERC20Interface, Owned {
     using SafeMath for uint;
     

    uint256 public sellPrice;  
	uint256 public buyPrice;  
	uint256 public sysPrice;  
	uint256 public sysPer;  
	
	uint256 public onceOuttime;  
	uint256 public onceAddTime;  
	uint256 public onceoutTimePer;  
	
	
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
	mapping(address => bool) public frozenAccount;
	 
	 
	 
	mapping(address => uint256) public canOf;
	 
	mapping(address => uint) public cronoutOf;
	 
	mapping(address => uint) public cronaddOf;
	
	  
	event FrozenFunds(address target, bool frozen);
     
     
     
    constructor() public{
       
        
        sellPrice = 510;  
    	buyPrice =  526;  
    	sysPrice = 766;  
    	sysPer = 225;  
    	
    	 
    	 
    	 
    	
    	onceOuttime = 600;  
    	onceAddTime = 1800;  
    	onceoutTimePer = 60000;  
	
	
        
       
    }



     
     
     
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function canuseOf(address tokenOwner) public view returns (uint balance) {
        return canOf[tokenOwner];
    }
    function myuseOf(address tokenOwner) public returns (uint balance) {
         
        if(cronoutOf[tokenOwner] < 1) {
			return 0;
		}else{
		    uint lefttimes = now - cronoutOf[tokenOwner];
    		if(lefttimes >= onceOuttime) {
    			uint leftpers = lefttimes / onceoutTimePer;
    			if(leftpers > 1) {
    				leftpers = 1;
    			}
    			canOf[tokenOwner] = balances[tokenOwner] * leftpers;
    			return canOf[tokenOwner];
    		}else{
    		    return canOf[tokenOwner];
    		}
		}
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[to]);
        canOf[msg.sender] = myuseOf(msg.sender);
        canOf[msg.sender] = canOf[msg.sender].sub(tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
     
    
     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
	function mintToken(address target, uint256 mintedAmount) onlyOwner public {
		require(!frozenAccount[target]);
		if(cronoutOf[target] < 1) {
		    cronoutOf[target] = now + onceOuttime;
		}
		if(cronaddOf[target] < 1) {
		    cronaddOf[target] = now + onceAddTime;
		}

		balances[target] += mintedAmount;
		uint256 amounts = mintedAmount / 100;
		canOf[target] += amounts;
		 
		emit Transfer(this, target, mintedAmount);

	}
	 
	function mint() public {
		require(!frozenAccount[msg.sender]);
		require(cronaddOf[msg.sender] > 0 && now > cronaddOf[msg.sender]);
		uint256 mintAmount = balances[msg.sender] * sysPer / 10000;
		balances[msg.sender] += mintAmount;
		cronaddOf[msg.sender] = now + onceAddTime;
		 
		emit Transfer(this, msg.sender, mintAmount);

	}
    
	 
	function freezeAccount(address target, bool freeze) onlyOwner public {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}
	 
	function setPrices( uint256 newBuyPrice, uint256 newSellPrice, uint256 systyPrice, uint256 sysPermit) onlyOwner public {
		buyPrice = newBuyPrice;
		sellPrice = newSellPrice;
		sysPrice = systyPrice;
		sysPer = sysPermit;
	}
	 
	function getprice()  public view returns (uint256 bprice,uint256 spice,uint256 sprice,uint256 sper) {
          bprice = buyPrice;
          spice = sellPrice;
          sprice = sysPrice;
          sper = sysPer;
   }
   


    
}
contract BTYC is BTYCToken{
  string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

     
     
     
    constructor() public{
        symbol = "BYTCT";
        name = "BYTYCT Coin";
        decimals = 18;
        _totalSupply = 1000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    function buy(uint money) public payable {
        require(!frozenAccount[msg.sender]);
        uint amount = money / buyPrice;
        balances[msg.sender] += amount;
        msg.sender.transfer(money);
    }
     
    function sell(uint amount)  public returns (bool success){
         
         
         
        require(canOf[msg.sender] >= amount ); 
        balances[msg.sender] -= amount;
        canOf[msg.sender] -= amount;
        uint moneys = amount / sellPrice;
        owner.transfer(moneys);
         
        return true;              
    }
    

  
}