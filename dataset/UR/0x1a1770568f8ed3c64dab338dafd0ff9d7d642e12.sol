 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 

 
contract Permission {
    address public owner;
	function Permission() public {
        owner = msg.sender;
    }

	modifier onlyOwner() { 
		require(msg.sender == owner);
		_;
	}

	function changeOwner(address newOwner) onlyOwner public returns (bool) {
		require(newOwner != address(0));
		owner = newOwner;
        return true;
	}
		
}	

 
library Math {

	function add(uint a, uint b) internal pure returns (uint c) {
		c = a + b;
		 
		 
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


 
contract NauticusToken is Permission {

     
    event Approval(address indexed owner, address indexed spender, uint val);
    event Transfer(address indexed sender, address indexed recipient, uint val);

     
    using Math for uint;
    
     
     
     
     
     
    uint public constant inception = 1521331200;
    uint public constant termination = 1526601600;

     
    string public constant name = "NauticusToken";
	string public constant symbol = "NTS";
	uint8 public constant decimals = 18;

     
    uint public totalSupply;
    
     
    bool public minted = false;

     
    uint public constant hardCap = 2500000000000000000000000000;
    
     
    bool public transferActive = false;
    
     
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
     
	modifier canMint(){
	    require(!minted);
	    _;
	}
	
	 
	
	modifier ICOTerminated() {
	    require(now > termination * 1 seconds);
	    _;
	}

	modifier transferable() { 
		 
		if(msg.sender != owner) {
			require(transferActive);
		}
		_;
	}
	
       
     
    function approve(address spender, uint val) public returns (bool) {
        allowed[msg.sender][spender] = val;
        Approval(msg.sender, spender, val);
        return true;
    }

     
	function transfer(address to, uint val) transferable ICOTerminated public returns (bool) {
		 
		require(to != address(0));
		require(val <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender] - val;

		 
		balances[to] = balances[to] + val;

		 
		Transfer(msg.sender, to, val);
		return true;
	}

     
	function balanceOf(address client) public constant returns (uint) {
		return balances[client];
	}

     
	function transferFrom(address from, address recipient, uint val) transferable ICOTerminated public returns (bool) {
		 
		require(recipient != address(0));
		require(from != address(0));
		 
		require(val <= balances[from]);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(val);
		balances[from] = balances[from] - val;
		balances[recipient] = balances[recipient] + val;

		Transfer(from,recipient,val);
        return true;
	}
	
     
	function toggleTransfer(bool newTransferState) onlyOwner public returns (bool) {
	    require(newTransferState != transferActive);
	    transferActive = newTransferState;
	    return true;
	}
	
     
	function mint(uint tokensToExist) onlyOwner ICOTerminated canMint public returns (bool) {
	    tokensToExist > hardCap ? totalSupply = hardCap : totalSupply = tokensToExist;
	    balances[owner] = balances[owner].add(totalSupply);
        minted = true;
        transferActive = true;
	    return true;
	    
	}
     
	
    function allowance(address holder, address recipient) public constant returns (uint) {
        return allowed[holder][recipient];
    }
    
     
    function NauticusToken () public {}
	
}