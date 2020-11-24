 

pragma solidity ^0.4.11;


interface IERC20 {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


library SafeMath {

   
  function mul(uint256 a, uint256 b) internal  returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal  returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}






contract CMBToken is IERC20 {

using SafeMath for uint256;
uint public constant _totalSupply = 6500000000000000;

string public constant symbol = "CMBT";
string public constant name = "CMB Token";
uint8 public constant decimals = 8;


mapping (address => uint256) balances;
mapping(address =>  mapping(address => uint256)) allowed;

 function CMBToken() {
	balances[msg.sender] = _totalSupply;

}

function totalSupply() constant returns (uint256 totalSupply) {
	return _totalSupply;
}

function balanceOf(address _owner) constant returns (uint256 balance) {
	return balances[_owner];
}

function transfer(address _to, uint256 _value) returns (bool success) {
	require(
		balances[msg.sender] >= _value
		&& _value > 0
	);
	balances[msg.sender] = balances[msg.sender].sub(_value);
	balances [_to] = balances[_to].add(_value);
	Transfer(msg.sender, _to, _value);
	return true;

}

function transferFrom(address _from, address _to, uint256 _value) returns (bool success) { 
	require(
	allowed[_from][msg.sender] >= _value
	&& balances[_from] >= _value
	&& _value > 0
	);
	balances[_from] = balances[msg.sender].sub(_value);
	balances[_to] = balances[_to].add(_value);
	allowed[_from][msg.sender] = balances[msg.sender].sub(_value);
	Transfer(_from, _to, _value);
	return true;

}

function approve(address _spender, uint256 _value) returns (bool success) {
	allowed[msg.sender][_spender] = _value;
	Approval(msg.sender, _spender, _value);
	return true;	
}

function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
	return allowed[_owner][_spender];

}

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}