 

 
pragma solidity ^0.4.16;

 
pragma solidity ^0.4.16;


 
pragma solidity ^0.4.16;

 
contract Token {
   
  function totalSupply () constant returns (uint256 supply);

   
  function balanceOf (address _owner) constant returns (uint256 balance);

   
  function transfer (address _to, uint256 _value) returns (bool success);

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success);

   
  function approve (address _spender, uint256 _value) returns (bool success);

   
  function allowance (address _owner, address _spender) constant
  returns (uint256 remaining);

   
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

   
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}

 
pragma solidity ^0.4.16;

 
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  function safeAdd (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

   
  function safeSub (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

   
  function safeMul (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (y == 0) return 0;  
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
}


 
contract AbstractToken is Token, SafeMath {
   
  function AbstractToken () {
     
  }

   
  function balanceOf (address _owner) constant returns (uint256 balance) {
    return accounts [_owner];
  }

   
  function transfer (address _to, uint256 _value) returns (bool success) {
    uint256 fromBalance = accounts [msg.sender];
    if (fromBalance < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    uint256 spenderAllowance = allowances [_from][msg.sender];
    if (spenderAllowance < _value) return false;
    uint256 fromBalance = accounts [_from];
    if (fromBalance < _value) return false;

    allowances [_from][msg.sender] =
      safeSub (spenderAllowance, _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (_from, _to, _value);
    return true;
  }

   
  function approve (address _spender, uint256 _value) returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);

    return true;
  }

   
  function allowance (address _owner, address _spender) constant
  returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

   
  mapping (address => uint256) accounts;

   
  mapping (address => mapping (address => uint256)) private allowances;
}

 
contract NuggetsToken is AbstractToken {
   
  uint constant INITIAL_SUPPLY = 10000000000e18;

   
  function NuggetsToken () {
    owner = msg.sender;
    accounts [owner] = INITIAL_SUPPLY;
    tokensCount = INITIAL_SUPPLY;
  }

   
  function name () constant returns (string result) {
    return "Nuggets";
  }

   
  function symbol () constant returns (string result) {
    return "NUG";
  }

   
  function decimals () constant returns (uint8 result) {
    return 18;
  }

   
  function totalSupply () constant returns (uint256 supply) {
    return tokensCount;
  }

   
  function transfer (address _to, uint256 _value) returns (bool success) {
    return frozen ? false : AbstractToken.transfer (_to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    return frozen ? false : AbstractToken.transferFrom (_from, _to, _value);
  }

   
  function approve (address _spender, uint256 _currentValue, uint256 _newValue)
  returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }

   
  function burnTokens (uint256 _value) returns (bool success) {
    uint256 ownerBalance = accounts [msg.sender];
    if (_value > ownerBalance) return false;
    else if (_value > 0) {
      accounts [msg.sender] = safeSub (ownerBalance, _value);
      tokensCount = safeSub (tokensCount, _value);
      return true;
    } else return true;
  }

   
  function setOwner (address _newOwner) {
    require (msg.sender == owner);

    owner = _newOwner;
  }

   
  function freezeTransfers () {
    require (msg.sender == owner);

    if (!frozen) {
      frozen = true;
      Freeze ();
    }
  }

   
  function unfreezeTransfers () {
    require (msg.sender == owner);

    if (frozen) {
      frozen = false;
      Unfreeze ();
    }
  }

   
  event Freeze ();

   
  event Unfreeze ();

   
  uint256 tokensCount;

   
  address owner;

   
  bool frozen;
}