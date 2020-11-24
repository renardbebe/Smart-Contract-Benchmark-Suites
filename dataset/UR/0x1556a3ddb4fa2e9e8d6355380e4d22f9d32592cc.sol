 

 
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


 
contract AbstractSnapshottableToken is SafeMath, Token {
   
  uint256 constant MAX_TOKENS = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  uint256 constant MAX_ADDRESS = 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  uint256 constant TWO_160 = 0x00010000000000000000000000000000000000000000;

   
  function AbstractSnapshottableToken () {
    snapshots.length = 1;  
  }

   
  function totalSupply () constant returns (uint256 supply) {
    return tokensCount;
  }

   
  function totalSupplyAt (uint256 _index) constant returns (uint256 supply) {
    require (_index > 0);
    require (_index < snapshots.length);

    return snapshots [_index].tokensCount;
  }

   
  function balanceOf (address _owner) constant returns (uint256 balance) {
    return accounts [_owner].balance;
  }

   
  function balanceOfAt (address _owner, uint256 _index)
    constant returns (uint256 balance) {
    require (_index > 0);
    require (_index < snapshots.length);

    if (_index > accounts [_owner].lastSnapshotIndex)
      return accounts [_owner].balance;
    else {
      uint8 level = 0;
      while (_index > 0) {
        uint256 v = historicalBalances [_owner][level][_index];
        if (v != 0) return v;

        _index >>= 1;
        level += 1;  
      }

      return 0;
    }
  }

   
  function firstAddressAt (uint256 _index)
    constant returns (bool hasResult, address result) {
    require (_index > 0);
    require (_index < snapshots.length);
    uint256 rawFirstAddress = snapshots [_index].firstAddress;
    hasResult = rawFirstAddress != MAX_UINT256;
    result = hasResult ?
      address (rawFirstAddress & MAX_ADDRESS) :
        0;
  }

   
  function nextAddress (address _address)
    constant returns (bool hasResult, address result) {
    uint256 rawNextAddress = nextAddresses [_address];
    require (rawNextAddress != 0);
    hasResult = rawNextAddress != MAX_UINT256;
    result = hasResult ?
      address (rawNextAddress & MAX_ADDRESS) :
        0;
  }

   
  function transfer (address _to, uint256 _value) returns (bool success) {
    return doTransfer (msg.sender, _to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    if (_value > approved [_from][msg.sender]) return false;
    else if (doTransfer (_from, _to, _value)) {
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

   
  function allowance (address _owner, address _spender) constant
  returns (uint256 remaining) {
    return approved [_owner][_spender];
  }

   
  function snapshot () returns (uint256 index) {
    index = snapshots.length++;
    snapshots [index].tokensCount = tokensCount;
    snapshots [index].firstAddress = firstAddress;
    Snapshot (index);
  }

   
  function doTransfer (address _from, address _to, uint256 _value)
    internal returns (bool success) {
    if (_value > accounts [_from].balance) return false;
    else if (_value > 0 && _from != _to) {
      saveAddress (_to);
      updateHistoricalBalances (_from);
      updateHistoricalBalances (_to);
      accounts [_from].balance = safeSub (accounts [_from].balance, _value);
      accounts [_to].balance = safeAdd (accounts [_to].balance, _value);
      Transfer (_from, _to, _value);
      return true;
    } else return true;
  }

   
  function doCreateTokens (uint256 _value) internal returns (bool success) {
    if (_value > safeSub (MAX_TOKENS, tokensCount)) return false;
    else if (_value > 0) {
      saveAddress (msg.sender);
      updateHistoricalBalances (msg.sender);
      accounts [msg.sender].balance =
        safeAdd (accounts [msg.sender].balance, _value);
      tokensCount = safeAdd (tokensCount, _value);
      return true;
    } else return true;
  }

   
  function updateHistoricalBalances (address _owner) internal {
    uint256 balance = accounts [_owner].balance;
    uint256 nextSnapshotIndex = snapshots.length;
    uint256 lastNextSnapshotIndex =
      safeAdd (accounts [_owner].lastSnapshotIndex, 1);
    if (nextSnapshotIndex > lastNextSnapshotIndex) {
      if (balance > 0) {
        setHistoricalBalance (
          _owner, lastNextSnapshotIndex, nextSnapshotIndex, balance);
      }
      accounts [_owner].lastSnapshotIndex =
        safeSub (nextSnapshotIndex, 1);
    }
  }

   
  function setHistoricalBalance (
    address _owner, uint256 _from, uint256 _to, uint256 _balance)
    internal {
    assert (_from > 0);
    assert (_to >= _from);
    assert (_balance > 0);

    uint8 level = 0;
    while (_from < _to) {
      if (_from & 1 == 1) {
         
        historicalBalances [_owner][level][_from++] = _balance;
      }

      if (_to & 1 == 1) {
         
        historicalBalances [_owner][level][--_to] = _balance;
      }

      _from >>= 1;
      _to >>= 1;
      level += 1;  
                   
    }
  }

   
  function saveAddress (address _address) internal {
    if (nextAddresses [_address] == 0) {
      nextAddresses [_address] = firstAddress;
      firstAddress = TWO_160 | uint256(_address);
    }
  }

   
  uint256 tokensCount;

   
  SnapshotInfo [] snapshots;

   
  mapping (address => Account) accounts;

   
  uint256 firstAddress = MAX_UINT256;

   
  mapping (address => uint256) nextAddresses;

   
  mapping (address => mapping (uint8 => mapping (uint256 => uint256)))
    historicalBalances;

   
  mapping (address => mapping (address => uint256)) approved;

   
  struct SnapshotInfo {
     
    uint256 tokensCount;

     
    uint256 firstAddress;
  }

   
  struct Account {
     
    uint256 balance;

     
    uint256 lastSnapshotIndex;
  }

   
  event Snapshot (uint256 indexed _index);
}


 

 
contract StandardSnapshottableToken is AbstractSnapshottableToken {
   
  function StandardSnapshottableToken ()
    AbstractSnapshottableToken () {
    owner = msg.sender;
  }

   
  function transfer (address _to, uint256 _value) returns (bool success) {
    if (frozen) return false;
    else return AbstractSnapshottableToken.transfer (_to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    if (frozen) return false;
    else
      return AbstractSnapshottableToken.transferFrom (_from, _to, _value);
  }

   
  function createTokens (uint256 _value) returns (bool success) {
    require (msg.sender == owner);

    return doCreateTokens (_value);
  }

   
  function freezeTransfers () {
    require (msg.sender == owner);

    if (!frozen)
    {
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

   
  function setOwner (address _newOwner) {
    require (msg.sender == owner);

    owner = _newOwner;
  }

   
  address owner;

   
  bool frozen;

   
  event Freeze ();

   
  event Unfreeze ();
}


 

 
contract ScienceBlockchainToken is StandardSnapshottableToken {
   
  function ScienceBlockchainToken ()
    StandardSnapshottableToken () {
    snapshotCreator = msg.sender;
  }

   
  function snapshot () returns (uint256 index) {
    require (msg.sender == snapshotCreator);
    return AbstractSnapshottableToken.snapshot ();
  }

   
  function name () constant returns (string result) {
    return "SCIENCE BLOCKCHAIN";
  }

   
  function symbol () constant returns (string result) {
    return "SCI";
  }

   
  function decimals () constant returns (uint8 result) {
    return 0;
  }

   
  function burnTokens (uint256 _value) returns (bool success) {
    uint256 balance = accounts [msg.sender].balance;
    if (_value > balance) return false;
    if (_value > 0) {
      updateHistoricalBalances (msg.sender);
      accounts [msg.sender].balance = safeSub (balance, _value);
      tokensCount = safeSub (tokensCount, _value);
      return true;
    }
    return true;
  }

   
  function setSnapshotCreator (address _snapshotCreator) {
    require (msg.sender == owner);
    snapshotCreator = _snapshotCreator;
  }

   
  address snapshotCreator;
}