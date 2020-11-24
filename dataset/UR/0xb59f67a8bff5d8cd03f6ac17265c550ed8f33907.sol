 

 
 
 

pragma solidity ^0.4.17;

 
contract Owned {
	modifier only_owner { require (msg.sender == owner); _; }

	event NewOwner(address indexed old, address indexed current);

	function setOwner(address _new) public only_owner { NewOwner(owner, _new); owner = _new; }

	address public owner;
}

 
 
 
 
 
 
contract FrozenToken is Owned {
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	struct Account {
		uint balance;
		bool liquid;
	}

	 
	function FrozenToken(uint _totalSupply, address _owner)
        public
		when_non_zero(_totalSupply)
	{
		totalSupply = _totalSupply;
		owner = _owner;
		accounts[_owner].balance = totalSupply;
		accounts[_owner].liquid = true;
	}

	 
	function balanceOf(address _who) public constant returns (uint256) {
		return accounts[_who].balance;
	}

	 
	function makeLiquid(address _to)
		public
		when_liquid(msg.sender)
		returns(bool)
	{
		accounts[_to].liquid = true;
		return true;
	}

	 
	function transfer(address _to, uint256 _value)
		public
		when_owns(msg.sender, _value)
		when_liquid(msg.sender)
		returns(bool)
	{
		Transfer(msg.sender, _to, _value);
		accounts[msg.sender].balance -= _value;
		accounts[_to].balance += _value;

		return true;
	}

	 
	function() public {
		assert(false);
	}

	 
	modifier when_owns(address _owner, uint _amount) {
		require (accounts[_owner].balance >= _amount);
		_;
	}

	modifier when_liquid(address who) {
		require (accounts[who].liquid);
		_;
	}

	 
	modifier when_non_zero(uint _value) {
		require (_value > 0);
		_;
	}

	 
	uint public totalSupply;

	 
	mapping (address => Account) accounts;

	 
	string public constant name = "DOT Allocation Indicator";
	string public constant symbol = "DOT";
	uint8 public constant decimals = 3;
}