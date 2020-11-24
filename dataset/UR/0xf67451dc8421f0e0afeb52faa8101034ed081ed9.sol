 

pragma solidity ^0.4.15;

 
 
contract ERC20 {
   
   
  function totalSupply() constant returns (uint256);

   
   
   
  function balanceOf(address _owner) constant returns (uint256);

   
   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool);

   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool);

   
   
   
   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool);

   
   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256);

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Owned {
  address public owner;

  function Owned() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function changeOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Token is ERC20 {
  function () {
     
    require(false);
  }

   
  mapping(address => uint256) balances;

   
  mapping(address => mapping (address => uint256)) allowed;

   
  uint256 internal _totalSupply;

   
   
  function totalSupply() constant returns (uint256) {
    return _totalSupply;
  }

   
   
   
  function balanceOf(address _owner) constant returns (uint256) {
    return balances[_owner];
  }

   
   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(balances[msg.sender] >= _value);
    require(_value > 0);
    require(balances[_to] + _value > balances[_to]);

    balances[msg.sender] -= _value;
    balances[_to]        += _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(balances[_from] >= _value);
    require(_value > 0);
    require(allowed[_from][msg.sender] >= _value);
    require(balances[_to] + _value > balances[_to]);

    balances[_from] -= _value;
    balances[_to]   += _value;
    allowed[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

   
   
   
   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256) {
    return allowed[_owner][_spender];
  }
}

contract Gambit is Token, Owned {
  string public constant name     = 'Gambit';
  uint8  public constant decimals = 8;
  string public constant symbol   = 'GAM';
  string public constant version  = '1.0.0';
  uint256 internal _totalBurnt    = 0;

   
  function Gambit() {
    _totalSupply = 260000000000000;
    balances[owner] = _totalSupply;
  }

   
   
  function totalBurnt() constant returns (uint256) {
    return _totalBurnt;
  }

   
   
   
  function burn(uint256 _value) onlyOwner returns (bool) {
    require(balances[msg.sender] >= _value);
    require(_value > 0);

    balances[msg.sender] -= _value;
    _totalSupply         -= _value;
    _totalBurnt          += _value;
    Transfer(msg.sender, 0x0, _value);
    return true;
  }
}