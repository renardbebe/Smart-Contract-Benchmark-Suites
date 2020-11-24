 

pragma solidity ^0.4.25;

contract ERC20 {
 
 
 
	function transfer(address to, uint value) public returns (bool success);
	function transferFrom(address from, address to, uint value) public returns (bool success);
	function approve(address spender, uint value) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract SafeMath {
    
	function mul(uint a, uint b) internal pure returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns (uint) {
		assert(b > 0);
		return a / b;
	}

	function sub(uint a, uint b) internal pure returns (uint) {
		assert(b <= a);
		return a - b;
	}

	function add(uint a, uint b) internal pure returns (uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function min(uint x, uint y) internal pure returns (uint) {
		return x <= y ? x : y;
	}

	function max(uint x, uint y) internal pure returns (uint) {
		return x >= y ? x : y;
	}
}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Token is ERC20, SafeMath, Owned {

	 
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	 
	uint public totalSupply;

	 
	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;

	mapping(address=>uint) public lock; 
	mapping(address=>bool) public freezeIn;
	mapping(address=>bool) public freezeOut;
	
	 
	 
	event Burn(address indexed from, uint value);
	event FreezeIn(address[] indexed from, bool value);
	event FreezeOut(address[] indexed from, bool value);

	function Token(string tokenName, string tokenSymbol, uint initSupply) public {
		totalSupply=initSupply*10**uint(decimals);       
		name=tokenName;
		symbol=tokenSymbol;
		balanceOf[owner]=totalSupply;        
	}

	 
	 

	function internalTransfer(address from, address toaddr, uint value) internal {
		require(toaddr!=0);
		require(balanceOf[from]>=value);

		require(now>=lock[from]);
		require(!freezeIn[toaddr]);
		require(!freezeOut[from]);

		balanceOf[from]=sub(balanceOf[from], value);
		balanceOf[toaddr]=add(balanceOf[toaddr], value);

		Transfer(from, toaddr, value);
	}

	function transfer(address toaddr, uint value) public returns (bool) {
		internalTransfer(msg.sender, toaddr, value);
		return true;
	}
	
	function transferFrom(address from, address toaddr, uint value) public returns (bool) {
		require(allowance[from][msg.sender]>=value);
		allowance[from][msg.sender]=sub(allowance[from][msg.sender], value);
		internalTransfer(from, toaddr, value);
		return true;
	}

	function approve(address spender, uint amount) public returns (bool) {
		require((amount == 0) || (allowance[msg.sender][spender] == 0));
		allowance[msg.sender][spender]=amount;
		Approval(msg.sender, spender, amount);
		return true;
	}

	 

	function setNameSymbol(string tokenName, string tokenSymbol) public onlyOwner {
		name=tokenName;
		symbol=tokenSymbol;
	}

	 
	function setLock(address[] addrs, uint[] times) public onlyOwner {
		require(addrs.length==times.length);
		for (uint i=0; i<addrs.length; i++) {
			lock[addrs[i]]=times[i];
		}
	}

	function setFreezeIn(address[] addrs, bool value) public onlyOwner {
		for (uint i=0; i<addrs.length; i++) {
			freezeIn[addrs[i]]=value;
		}
		FreezeIn(addrs, value);
	}

	function setFreezeOut(address[] addrs, bool value) public onlyOwner {
		for (uint i=0; i<addrs.length; i++) {
			freezeOut[addrs[i]]=value;
		}
		FreezeOut(addrs, value);
	}
	 
	function mint(address addrs, uint amount) public onlyOwner {
		balanceOf[addrs]=add(balanceOf[addrs], amount);
		totalSupply=add(totalSupply, amount);
	}

	function burn(address addrs, uint amount) public onlyOwner {
		balanceOf[addrs]=sub(balanceOf[addrs], amount);
		totalSupply=sub(totalSupply, amount);
	}

	 

	function withdrawEther(uint amount) public onlyOwner {
		owner.transfer(amount);
	}

	 
	function() public payable {
    }
}