 

pragma solidity ^0.4.21;

contract KKToken {
  
   
  mapping (address => uint256) balances;
   
  mapping (address => mapping (address => uint256)) allowed;
  
   
  string public name = " Kunkun Token";
  string public symbol = "KKT";
  uint8 public decimals = 18;   
  uint256 public totalSupply;

  uint256 public initialSupply = 100000000;

   
  function (){
    throw;
  }

   
  function KKToken(){
     
    totalSupply = initialSupply * (10 ** uint256(decimals));
     
    balances[msg.sender] = totalSupply;
  }

   
  function balanceOf(address _owner) view returns (uint256 balance){
    return balances[_owner];
  }

   
   
  function transfer(address _to, uint256 _value) returns (bool success){
     
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { 
      return false; 
    }
  }

   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
     
     
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

   
  function approve(address _spender, uint256 _value) returns (bool success){
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) view returns (uint256 remaining){
    return allowed[_owner][_spender];
  }

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
}