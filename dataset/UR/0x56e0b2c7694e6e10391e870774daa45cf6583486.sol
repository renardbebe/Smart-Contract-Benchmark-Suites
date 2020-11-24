 

pragma solidity ^0.5.0;

contract DUO {
	 
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	 
	uint public totalSupply;

	 
	mapping (address => uint) public balanceOf;
	mapping (address => mapping (address => uint)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

	 
	constructor(
		uint initialSupply,
		string memory tokenName,
		string memory tokenSymbol
	) public 
	{
		totalSupply = initialSupply;   
		balanceOf[msg.sender] = totalSupply;				 
		name = tokenName;								    
		symbol = tokenSymbol;							    
	}

	 
	function transfer(address from, address to, uint value) internal {
		 
		require(to != address(0));
		 
		require(balanceOf[from] >= value);
		 
		require(balanceOf[to] + value > balanceOf[to]);
		 
		uint previousBalances = balanceOf[from] + balanceOf[to];
		 
		balanceOf[from] -= value;
		 
		balanceOf[to] += value;
		emit Transfer(from, to, value);
		 
		assert(balanceOf[from] + balanceOf[to] == previousBalances);
	}

	 
	function transfer(address to, uint value) public returns (bool success) {
		transfer(msg.sender, to, value);
		return true;
	}

	 
	function transferFrom(address from, address to, uint value) public returns (bool success) {
		require(value <= allowance[from][msg.sender]);	  
		allowance[from][msg.sender] -= value;
		transfer(from, to, value);
		return true;
	}

	 
	function approve(address spender, uint value) public returns (bool success) {
		allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}
}