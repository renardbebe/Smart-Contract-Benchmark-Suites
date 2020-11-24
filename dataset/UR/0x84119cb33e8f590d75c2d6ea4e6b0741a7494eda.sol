 

 
pragma solidity ^0.4.1;

 
contract Token {
   
  function totalSupply () constant returns (uint256 supply);

   
  function balanceOf (address _owner) constant returns (uint256 balance);

   
  function transfer (address _to, uint256 _value) returns (bool success);

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success);

   
  function approve (address _spender, uint256 _value) returns (bool success);

   
  function allowance (address _owner, address _spender)
  constant returns (uint256 remaining);

   
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
   
  function totalSupply () constant returns (uint256 supply) {
    return tokensCount;
  }

   
  function balanceOf (address _owner) constant returns (uint256 balance) {
    return accounts [_owner];
  }

   
  function transfer (address _to, uint256 _value) returns (bool success) {
    return doTransfer (msg.sender, _to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success)
  {
    if (_value > approved [_from][msg.sender]) return false;
    if (doTransfer (_from, _to, _value)) {
      approved [_from][msg.sender] =
        safeSub (approved[_from][msg.sender], _value);
      return true;
    } else return false;
  }

   
  function approve (address _spender, uint256 _value) returns (bool success) {
    approved [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);
    return true;
  }

   
  function allowance (address _owner, address _spender)
  constant returns (uint256 remaining) {
    return approved [_owner][_spender];
  }

   
  function createTokens (address _owner, uint256 _value) internal {
    if (_value > 0) {
      accounts [_owner] = safeAdd (accounts [_owner], _value);
      tokensCount = safeAdd (tokensCount, _value);
    }
  }

   
  function doTransfer (address _from, address _to, uint256 _value)
  private returns (bool success) {
    if (_value > accounts [_from]) return false;
    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (accounts [_from], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
      Transfer (_from, _to, _value);
    }
    return true;
  }

   
  uint256 tokensCount;

   
  mapping (address => uint256) accounts;

   
  mapping (address => mapping (address => uint256)) approved;
}

 
contract StandardToken is AbstractToken {
   
  uint256 constant private MAX_TOKENS = 0xFFFFFFFFFFFFFFFF;

   
  address owner;

   
  bool frozen;

   
  function StandardToken () {
    owner = msg.sender;
  }

   
  function transfer (address _to, uint256 _value)
  returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

   
  function createTokens (uint256 _value)
  returns (bool success) {
    if (msg.sender != owner) throw;

    if (_value > MAX_TOKENS - totalSupply ()) return false;

    AbstractToken.createTokens (owner, _value);

    return true;
  }

   
  function freezeTransfers () {
    if (msg.sender != owner) throw;

    if (!frozen)
    {
      frozen = true;
      Freeze ();
    }
  }

   
  function unfreezeTransfers () {
    if (msg.sender != owner) throw;

    if (frozen) {
      frozen = false;
      Unfreeze ();
    }
  }

   
  function setOwner (address _newOwner) {
    if (msg.sender != owner) throw;

    owner = _newOwner;
  }

   
  event Freeze ();

   
  event Unfreeze ();
}

 
contract GigaWattToken is StandardToken {
   
  function GigaWattToken () StandardToken () {
     
  }
}