 

pragma solidity ^0.4.8;

 
contract SYLVIe {

  function () {
       
      throw;
  }

  string public name = "SYLVIe";                               
  uint8 public decimals = 0;                                   
  string public symbol = "SLV";                                
  uint256 public totalSupply = 100000000;                      
  mapping (address => uint256) balances;                       
  mapping (address => mapping (address => uint256)) allowed;   

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  function SYLVIe() {
    balances[msg.sender] = totalSupply;
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
          balances[msg.sender] -= _value;
          balances[_to] += _value;
          Transfer(msg.sender, _to, _value);
          return true;
      } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
          balances[_to] += _value;
          balances[_from] -= _value;
          allowed[_from][msg.sender] -= _value;
          Transfer(_from, _to, _value);
          return true;
      } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}