 

pragma solidity ^0.4.21;
 

 
contract Token {
   
  function totalSupply () public constant returns (uint256 supply);

   
  function balanceOf (address _owner) public constant returns (uint256 balance);

   
  function transfer (address _to, uint256 _value) public returns (bool success);

   
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success);

   
  function approve (address _spender, uint256 _value) public returns (bool success);

   
  function allowance (address _owner, address _spender) constant
  public returns (uint256 remaining);

   
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

   
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}
 

 
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  function safeAdd (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

   
  function safeSub (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

   
  function safeMul (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    if (y == 0) return 0;  
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
}
 

contract AbstractToken is Token, SafeMath {
   
  function AbstractToken () public {
     
  }

   
  function balanceOf (address _owner) public constant returns (uint256 balance) {
    return accounts [_owner];
  }

   
  function transferrableBalanceOf (address _owner) public constant returns (uint256 balance) {
    if (holds[_owner] > accounts[_owner]) {
        return 0;
    } else {
        return safeSub(accounts[_owner], holds[_owner]);
    }
  }

   
  function transfer (address _to, uint256 _value) public returns (bool success) {
    require (transferrableBalanceOf(msg.sender) >= _value);
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      if (!hasAccount[_to]) {
          hasAccount[_to] = true;
          accountList.push(_to);
      }
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    emit Transfer (msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success) {
    require (allowances [_from][msg.sender] >= _value);
    require (transferrableBalanceOf(_from) >= _value);

    allowances [_from][msg.sender] =
      safeSub (allowances [_from][msg.sender], _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (accounts [_from], _value);
      if (!hasAccount[_to]) {
          hasAccount[_to] = true;
          accountList.push(_to);
      }
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    emit Transfer (_from, _to, _value);
    return true;
  }

   
  function approve (address _spender, uint256 _value) public returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    emit Approval (msg.sender, _spender, _value);

    return true;
  }

   
  function allowance (address _owner, address _spender) public constant
  returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

   
  mapping (address => uint256) accounts;

   
  mapping (address => bool) internal hasAccount;
  
   
  address [] internal accountList;
  
   
  mapping (address => mapping (address => uint256)) private allowances;

   
  mapping (address =>  uint256) internal holds;
}
 


contract PonderAirdropToken is AbstractToken {
   
  mapping (address => bool) private owners;
  
   
  address private supplyOwner;
  
   
  bool frozen = false;

   
  function PonderAirdropToken () public {
    supplyOwner = msg.sender;
    owners[supplyOwner] = true;
    accounts [supplyOwner] = totalSupply();
    hasAccount [supplyOwner] = true;
    accountList.push(supplyOwner);
  }

   
  function totalSupply () public constant returns (uint256 supply) {
    return 480000000 * (uint256(10) ** decimals());
  }

   
  function name () public pure returns (string result) {
    return "Ponder Airdrop Token";
  }

   
  function symbol () public pure returns (string result) {
    return "PONA";
  }

   
  function decimals () public pure returns (uint8 result) {
    return 18;
  }

   
  function transfer (address _to, uint256 _value) public returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }

   
  function transferFrom (address _from, address _to, uint256 _value)
    public returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

   
  function approve (address _spender, uint256 _currentValue, uint256 _newValue)
    public returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }

   
  function setOwner (address _address, bool _value) public {
    require (owners[msg.sender]);
     
     
    require (_value == true || _address != msg.sender);

    owners[_address] = _value;
  }

     
  function initAccounts (address [] _to, uint256 [] _value) public {
      require (owners[msg.sender]);
      require (_to.length == _value.length);
      for (uint256 i=0; i < _to.length; i++){
          uint256 amountToAdd;
          uint256 amountToSub;
          if (_value[i] > accounts[_to[i]]){
            amountToAdd = safeSub(_value[i], accounts[_to[i]]);
          }else{
            amountToSub = safeSub(accounts[_to[i]], _value[i]);
          }
          accounts [supplyOwner] = safeAdd (accounts [supplyOwner], amountToSub);
          accounts [supplyOwner] = safeSub (accounts [supplyOwner], amountToAdd);
          if (!hasAccount[_to[i]]) {
              hasAccount[_to[i]] = true;
              accountList.push(_to[i]);
          }
          accounts [_to[i]] = _value[i];
          if (amountToAdd > 0){
            emit Transfer (supplyOwner, _to[i], amountToAdd);
          }
      }
  }

     
  function initAccounts (address [] _to, uint256 [] _value, uint256 [] _holds) public {
    setHolds(_to, _holds);
    initAccounts(_to, _value);
  }
  
   
  function setHolds (address [] _account, uint256 [] _value) public {
    require (owners[msg.sender]);
    require (_account.length == _value.length);
    for (uint256 i=0; i < _account.length; i++){
        holds[_account[i]] = _value[i];
    }
  }
  
     
  function getNumAccounts () public constant returns (uint256 count) {
    require (owners[msg.sender]);
    return accountList.length;
  }
  
     
  function getAccounts (uint256 _start, uint256 _count) public constant returns (address [] addresses){
    require (owners[msg.sender]);
    require (_start >= 0 && _count >= 1);
    if (_start == 0 && _count >= accountList.length) {
      return accountList;
    }
    address [] memory _slice = new address[](_count);
    for (uint256 i=0; i < _count; i++){
      _slice[i] = accountList[i + _start];
    }
    return _slice;
  }
  
   
  function freezeTransfers () public {
    require (owners[msg.sender]);

    if (!frozen) {
      frozen = true;
      emit Freeze ();
    }
  }

   
  function unfreezeTransfers () public {
    require (owners[msg.sender]);

    if (frozen) {
      frozen = false;
      emit Unfreeze ();
    }
  }

   
  event Freeze ();

   
  event Unfreeze ();

   
  function kill() public { 
    if (owners[msg.sender]) selfdestruct(msg.sender);
  }
}