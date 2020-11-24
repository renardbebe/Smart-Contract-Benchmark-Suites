 

pragma solidity ^0.4.0;

 
contract ERC20 {

   
  function totalSupply() constant returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) constant returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
 contract StandardToken is ERC20 {

  uint256 public totalSupply;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;


  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
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

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}


contract TST is StandardToken {
    string public name = 'Test Standard Token';
    string public symbol = 'TST';
    uint public decimals = 18;

    function showMeTheMoney(address _to, uint256 _value) {
        totalSupply += _value;
        balances[_to] += _value;
        Transfer(0, _to, _value);
    }
}