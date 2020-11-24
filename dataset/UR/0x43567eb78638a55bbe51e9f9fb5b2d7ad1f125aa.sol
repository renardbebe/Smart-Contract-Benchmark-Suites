 

pragma solidity ^0.4.11;

contract ERC20Interface {
	function totalSupply() constant returns (uint256 total);  
	function balanceOf(address _owner) constant returns (uint256 balance);  
	function transfer(address _to, uint256 _value) returns (bool success);  
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);  
	 
	 
	 
	 
	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value);  
	 
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

contract owned {
	address public owner;

	function owned() {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) revert();
		_;
	}

	 
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract HacToken is ERC20Interface, owned{
	string public standard = 'Token 0.1';
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public freeTokens;
	uint256 public totalSupply;

	mapping (address => uint256) public balanceOf;

	event TransferFrom(address indexed _from, address indexed _to, uint256 _value);  

	function HacToken() {
		totalSupply = freeTokens = 10000000000000;
		name = "HAC Token";
		decimals = 4;
		symbol = "HAC";
	}

	function totalSupply() constant returns (uint256 total) {
		return total = totalSupply;
	}
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balanceOf[_owner];
	}
	 
	function () {
		revert();
	}

	function setTokens(address target, uint256 amount) onlyOwner {
		if(freeTokens < amount) revert();

		balanceOf[target] = SafeMath.add(balanceOf[target], amount);
		freeTokens = SafeMath.sub(freeTokens, amount);
		Transfer(this, target, amount);
	}

	function transfer(address _to, uint256 _value) returns (bool success){
		balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
		balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

		Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) onlyOwner returns (bool success) {
		balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
		balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

		TransferFrom(_from, _to, _value);
		return true;
	}
}