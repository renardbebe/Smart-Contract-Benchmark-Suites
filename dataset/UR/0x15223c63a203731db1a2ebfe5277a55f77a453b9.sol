 

pragma solidity 0.4.11;

contract ERC20Interface {
	uint256 public totalSupply;
	function balanceOf(address _owner) public constant returns (uint balance);  
	function transfer(address _to, uint256 _value) public returns (bool success);  
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);  
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);  
	event Transfer(address indexed _from, address indexed _to, uint256 _value);  
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);  
}

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}
contract ERC20Token is ERC20Interface {
	using SafeMath for uint256;

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint256)) allowed;

	modifier onlyPayloadSize(uint size) {
		require(msg.data.length >= (size + 4));
		_;
	}

	function () public{
		revert();
	}

	function balanceOf(address _owner) public constant returns (uint balance) {
		return balances[_owner];
	}
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
		_transferFrom(msg.sender, _to, _value);
		return true;
	}
	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		_transferFrom(_from, _to, _value);
		return true;
	}
	function _transferFrom(address _from, address _to, uint256 _value) internal {
		require(_value > 0);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}
}

contract owned {
	address public owner;

	function owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) revert();
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		owner = newOwner;
	}
}


contract IQFToken is ERC20Token, owned{
	using SafeMath for uint256;

	string public name = 'IQF TOKEN';
	string public symbol = 'IQF';
	uint8 public decimals = 8;
	uint256 public totalSupply = 10000000000000000; 

	function IQFToken() public {
		balances[this] = totalSupply;
	}

	function setTokens(address target, uint256 _value) public onlyOwner {
		balances[this] = balances[this].sub(_value);
		balances[target] = balances[target].add(_value);
		Transfer(this, target, _value);
	}

	function burnBalance() public onlyOwner {
		totalSupply = totalSupply.sub(balances[this]);
		Transfer(this, address(0), balances[this]);
		balances[this] = 0;
	}
}