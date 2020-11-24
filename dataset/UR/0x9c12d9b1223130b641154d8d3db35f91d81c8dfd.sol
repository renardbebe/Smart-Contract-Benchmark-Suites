 

pragma solidity >= 0.4.5<0.60;

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

 
contract InBitToken {

  using SafeMath for uint;

  string public name = 'InBit Token';
  string public symbol = 'InBit';
  string public standard = 'InBit Token v1.0';
  uint256 public totalSupply;
  uint8 public decimals;

   
   
   
   
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

   
   
   
   

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

   
   
   
  event Burn(
    address indexed _from,
    uint256 _value
  );

   
   
   
   
   
  event Locked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount,
    uint256 _validity
  );

   
   
   
   
  event Unlocked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount
  );

   
  mapping(address => uint256) public balanceOf;

   
  mapping(address => mapping(address => uint256)) public allowance;
   

   
  mapping(address => bytes32[]) public lockReason;

   
   
  mapping(address => mapping(bytes32 => lockToken)) public locked;

   
   
   
   
   
  struct lockToken {
    uint256 amount;
    uint256 validity;
    bool claimed;
  }

  constructor(uint256 _intialSupply, uint8 _intialDecimals)
    public
  {
    balanceOf[msg.sender] = _intialSupply;
    totalSupply = _intialSupply;
    decimals = _intialDecimals;
  }


   
   
   
   
  function transfer(address _to, uint256 _value)
    public
    returns(bool success)
  {
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
   
   
   
   
   
  function approve(address _spender, uint256 _value)
    public
    returns(bool success)
  {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value)
    public
    returns(bool success)
  {
    require(balanceOf[_from] >= _value);
    require(allowance[_from][msg.sender] >= _value);
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
   
   
   
   
   
  function lock(bytes32 _reason, uint256 _amount, uint256 _time)
  public
  returns (bool)
  {
    uint256 validUntil = now.add(_time);
    require(tokensLocked(msg.sender, _reason) == 0, 'Tokens already locked');
     
     
    require(_amount != 0, 'Amount can not be 0');
    if (locked[msg.sender][_reason].amount == 0)
      lockReason[msg.sender].push(_reason);
    transfer(address(this), _amount);
    locked[msg.sender][_reason] = lockToken(_amount, validUntil, false);
    emit Locked(msg.sender, _reason, _amount, validUntil);
    return true;
  }

   
   
   
   
   
   
   
  function transferWithLock(
    address _to,
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  )
    public
    returns (bool)
  {
    uint256 validUntil = now.add(_time);
    require(tokensLocked(_to, _reason) == 0, 'Tokens already locked');
    require(_amount != 0, 'Amount can not be 0');
    if (locked[_to][_reason].amount == 0)
      lockReason[_to].push(_reason);
    transfer(address(this), _amount);
    locked[_to][_reason] = lockToken(_amount, validUntil, false);
    emit Locked(_to, _reason, _amount, validUntil);
    return true;
  }

   
   
   
   
  function extendLock(bytes32 _reason, uint256 _time)
    public
    returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, 'There are no tokens locked for specified reason');
    locked[msg.sender][_reason].validity = locked[msg.sender][_reason].validity.add(_time);
    emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
    return true;
  }

   
   
   
  function increaseLockAmount(bytes32 _reason, uint256 _amount) public returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, 'There are no tokens locked for specified reason');
    transfer(address(this), _amount);
    locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount.add(_amount);
    emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
    return true;
  }

   
   
   
  function unlock(address _of) public returns (uint256 unlockableTokens) {
    uint256 lockedTokens;
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
      if (lockedTokens > 0) {
        unlockableTokens = unlockableTokens.add(lockedTokens);
        locked[_of][lockReason[_of][i]].claimed = true;
        emit Unlocked(_of, lockReason[_of][i], lockedTokens);
      }
    }
    if (unlockableTokens > 0)
      this.transfer(_of, unlockableTokens);
  }

   
   
  function burn(uint256 _value) public returns (bool success)
  {
    require(balanceOf[msg.sender] >= _value);
    require(_value >= 0);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

   
   
   
   
   
   
  function tokensLocked(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    if (!locked[_of][_reason].claimed)
    amount = locked[_of][_reason].amount;
  }

   
   
   
   
   
   
   
  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
    public
    view
    returns (uint256 amount)
  {
    if (locked[_of][_reason].validity > _time)
    amount = locked[_of][_reason].amount;
  }

   
   
  function totalBalanceOf(address _of)
    public
    view
    returns (uint256 amount)
  {
    amount = balanceOf[_of];
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
    }
  }

   
   
   
   
  function tokensUnlockable(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed){
      amount = locked[_of][_reason].amount;
    }
  }

   
   
  function getUnlockableTokens(address _of)
    public
    view
    returns (uint256 unlockableTokens)
  {
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
    }
  }
}