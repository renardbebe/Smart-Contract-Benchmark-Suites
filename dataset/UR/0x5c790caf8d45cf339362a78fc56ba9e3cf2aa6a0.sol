 

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
    if (accounts [msg.sender] < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    if (allowances [_from][msg.sender] < _value) return false;
    if (accounts [_from] < _value) return false;

    allowances [_from][msg.sender] =
      safeSub (allowances [_from][msg.sender], _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (accounts [_from], _value);
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


 
contract CGCoinToken is AbstractToken {
   
  uint256 constant MAX_TOKEN_COUNT =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  address private owner;

   
  uint256 tokenCount = 0;

   
  bool frozen = false;

   
  function CGCoinToken () {
    owner = msg.sender;
  }

   
  function totalSupply () constant returns (uint256 supply) {
    return tokenCount;
  }

   
  function name () constant returns (string result) {
    return "CGCOIN";
  }

   
  function symbol () constant returns (string result) {
    return "CGC";
  }

   
  function decimals () constant returns (uint8 result) {
    return 0;
  }

   
  function transfer (address _to, uint256 _value) returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

   
  function approve (address _spender, uint256 _currentValue, uint256 _newValue)
    returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }

   
  function burnTokens (uint256 _value) returns (bool success) {
    if (_value > accounts [msg.sender]) return false;
    else if (_value > 0) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      tokenCount = safeSub (tokenCount, _value);
      return true;
    } else return true;
  }

   
  function createTokens (uint256 _value)
    returns (bool success) {
    require (msg.sender == owner);

    if (_value > 0) {
      if (_value > safeSub (MAX_TOKEN_COUNT, tokenCount)) return false;
      accounts [msg.sender] = safeAdd (accounts [msg.sender], _value);
      tokenCount = safeAdd (tokenCount, _value);
    }

    return true;
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
}