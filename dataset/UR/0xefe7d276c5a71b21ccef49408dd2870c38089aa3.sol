 

pragma solidity ^0.4.9;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract XToken {

  string public constant name = "XTOKEN";
  string public constant symbol = "XTOKEN";
  uint8 public constant decimals = 18;
  string public constant version = '0.15';
  uint256 public constant totalSupply = 1000000000 * 1000000000000000000;

  address public owner;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event NewOwner(address _newOwner);

  modifier checkIfToContract(address _to) {
    if(_to != address(this))  {
      _;
    }
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  function XToken() {
    owner = msg.sender;
    balances[owner] = totalSupply;
  }

  function replaceOwner(address _newOwner) returns (bool success) {
    if (msg.sender != owner) throw;
    owner = _newOwner;
    NewOwner(_newOwner);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) checkIfToContract(_to) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) checkIfToContract(_to) returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}