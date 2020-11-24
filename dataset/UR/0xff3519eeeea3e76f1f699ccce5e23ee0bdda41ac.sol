 

 

 
pragma solidity ^0.4.1;

 
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

 
 
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  function safeAdd (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (x > MAX_UINT256 - y) throw;
    return x + y;
  }

   
  function safeSub (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (x < y) throw;
    return x - y;
  }

   
  function safeMul (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (y == 0) return 0;  
    if (x > MAX_UINT256 / y) throw;
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
      Transfer (msg.sender, _to, _value);
    }
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
      Transfer (_from, _to, _value);
    }
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


 


 
contract StandardToken is AbstractToken {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  function StandardToken (address _tokenIssuer) AbstractToken () {
    tokenIssuer = _tokenIssuer;
    accounts [_tokenIssuer] = MAX_UINT256;
  }

   
  function totalSupply () constant returns (uint256 supply) {
    return safeSub (MAX_UINT256, accounts [tokenIssuer]);
  }

   
  function balanceOf (address _owner) constant returns (uint256 balance) {
    return _owner == tokenIssuer ? 0 : AbstractToken.balanceOf (_owner);
  }

   
  address private tokenIssuer;
}

 
contract BCAPToken is StandardToken {
   
  function BCAPToken (address _tokenIssuer)
    StandardToken (_tokenIssuer) {
    owner = _tokenIssuer;
  }

   
  function freezeTransfers () {
    if (msg.sender != owner) throw;

    if (!transfersFrozen) {
      transfersFrozen = true;
      Freeze ();
    }
  }

   
  function unfreezeTransfers () {
    if (msg.sender != owner) throw;

    if (transfersFrozen) {
      transfersFrozen = false;
      Unfreeze ();
    }
  }

   
  function transfer (address _to, uint256 _value) returns (bool success) {
    if (transfersFrozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    if (transfersFrozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

   
  event Freeze ();

   
  event Unfreeze ();

   
  address owner;

   
  bool transfersFrozen = false;
}