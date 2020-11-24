 

pragma solidity ^0.4.9;

contract Token {
  
   
   
  function balanceOf(address _owner) constant returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
  string public symbol;

}

contract BMT is Token {
    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
  
    mapping(address => uint256) freezeAccount;

    address public minter;
 function BMT(uint256 initialSupply, string tokenName, uint8 decimalUnits,uint256 _totalSupply,string tokenSymbol) {
    minter = msg.sender;
	balances[msg.sender] = initialSupply;  
	name = tokenName;  
	decimals = decimalUnits;  
	totalSupply= _totalSupply;  
	symbol = tokenSymbol;  

  }
  function transfer(address _to, uint256 _value) returns (bool success) {
     
     
     
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to] && freezeAccount[msg.sender]==0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
     
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to] && freezeAccount[_from]==0) {
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
   
  function freezeAccountOf(address _owner) constant returns (uint256 freeze) {
    return freezeAccount[_owner];
  }
   
  function freeze(address account,uint key) {
    if (msg.sender != minter) throw;
    freezeAccount[account] = key;
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