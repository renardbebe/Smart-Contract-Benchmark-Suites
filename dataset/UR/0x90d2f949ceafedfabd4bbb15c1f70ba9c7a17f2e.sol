 

pragma solidity >= 0.4.24 < 0.6.0;

 
contract Owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0x0));
		owner = newOwner;
	}
}

 
contract SafeMath {
	function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);

		return c;
	}

	function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		uint256 c = a - b;

		return c;
	}
}

contract CURESToken is Owned, SafeMath {
	 
	string public name = "CURESToken";									 
	string public symbol = "CRS";										 
	uint8 public decimals = 18;											 
	uint256 public totalSupply = 500000000 * 10 ** uint256(decimals);	 

	 
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowances;
	mapping (address => uint256) public frozenAccounts;

	 
	constructor() public {
		 
		balances[msg.sender] = totalSupply;
	}

	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	 	
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}

	 	
	function transfer(address _to, uint256 _value) public returns (bool success) {
		 
		require(_to != address(0x0));

		 
		require(_value > 0);

		 
		require(frozenAccounts[msg.sender] < now);

		 
		require(balances[msg.sender] >= _value);

		 
		balances[msg.sender] = safeSub(balances[msg.sender], _value);

		 
		balances[_to] = safeAdd(balances[_to], _value);

		 
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		 
		require(_to != address(0x0));

		 
		require(_value > 0);

		 
		require(frozenAccounts[_from] < now);

		 
		require(allowances[_from][msg.sender] >= _value);

		 
		require(balances[_from] >= _value);

		 
		allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);

		 
		balances[_from] = safeSub(balances[_from], _value);

		 
		balances[_to] = safeAdd(balances[_to], _value);

		 
		emit Transfer(_from, _to, _value);
		return true;
	}

	 	
	function approve(address _spender, uint256 _value) public returns (bool success) {
		 
		require(_value >= 0);

		allowances[msg.sender][_spender] = _value;

		 
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function burn(uint256 _value) public returns (bool success) {
		 
		require(_value > 0);

		 
		require(balances[msg.sender] >= _value);

		 
		balances[msg.sender] = safeSub(balances[msg.sender], _value);

		 
		totalSupply = safeSub(totalSupply, _value);

		 
		emit Burn(msg.sender, _value);
		return true;
	}

	 
	function FreezeAccounts(address[] memory _addresses, uint256 _until) public onlyOwner returns (bool success) {
		for (uint i = 0; i < _addresses.length; i++) {
			frozenAccounts[_addresses[i]] = _until;

			 
			emit Freeze(_addresses[i], _until);
		}

		return true;
	}

	 
	event Transfer(address indexed _owner, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed _owner, uint256 _value);
	event Freeze(address indexed _owner, uint256 _until);
}