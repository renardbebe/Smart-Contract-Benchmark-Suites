 

pragma solidity ^0.4.13;

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract TokenDestructible is Ownable {

  constructor() public payable { }

   
  function destroy(address[] _tokens) public onlyOwner {

     
    for (uint256 i = 0; i < _tokens.length; i++) {
      ERC20Basic token = ERC20Basic(_tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract IndividualLockableToken is PausableToken{
  using SafeMath for uint256;

  event LockTimeSetted(address indexed holder, uint256 old_release_time, uint256 new_release_time);
  event Locked(address indexed holder, uint256 locked_balance_change, uint256 total_locked_balance, uint256 release_time);

  struct lockState {
    uint256 locked_balance;
    uint256 release_time;
  }

   
  uint256 public lock_period = 24 weeks;

  mapping(address => lockState) internal userLock;

   
  function setReleaseTime(address _holder, uint256 _release_time)
    public
    onlyOwner
    returns (bool)
  {
    require(_holder != address(0));
	require(_release_time >= block.timestamp);

	uint256 old_release_time = userLock[_holder].release_time;

	userLock[_holder].release_time = _release_time;
	emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);
	return true;
  }

   
  function getReleaseTime(address _holder)
    public
    view
    returns (uint256)
  {
    require(_holder != address(0));

	return userLock[_holder].release_time;
  }

   
  function clearReleaseTime(address _holder)
    public
    onlyOwner
    returns (bool)
  {
    require(_holder != address(0));
    require(userLock[_holder].release_time > 0);

	uint256 old_release_time = userLock[_holder].release_time;

	userLock[_holder].release_time = 0;
	emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);
	return true;
  }

   
   
  function increaseLockBalance(address _holder, uint256 _value)
    public
    onlyOwner
    returns (bool)
  {
	require(_holder != address(0));
	require(_value > 0);
	require(balances[_holder] >= _value);

	if (userLock[_holder].release_time == 0) {
		userLock[_holder].release_time = block.timestamp + lock_period;
	}

	userLock[_holder].locked_balance = (userLock[_holder].locked_balance).add(_value);
	emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);
	return true;
  }

   
  function decreaseLockBalance(address _holder, uint256 _value)
    public
    onlyOwner
    returns (bool)
  {
	require(_holder != address(0));
	require(_value > 0);
	require(userLock[_holder].locked_balance >= _value);

	userLock[_holder].locked_balance = (userLock[_holder].locked_balance).sub(_value);
	emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);
	return true;
  }

   
  function clearLock(address _holder)
    public
    onlyOwner
    returns (bool)
  {
	require(_holder != address(0));
	require(userLock[_holder].release_time > 0);

	userLock[_holder].locked_balance = 0;
	userLock[_holder].release_time = 0;
	emit Locked(_holder, 0, userLock[_holder].locked_balance, userLock[_holder].release_time);
	return true;
  }

   
  function getLockedBalance(address _holder)
    public
    view
    returns (uint256)
  {
    if(block.timestamp >= userLock[_holder].release_time) return uint256(0);
    return userLock[_holder].locked_balance;
  }

   
  function getFreeBalance(address _holder)
    public
    view
    returns (uint256)
  {
    if(block.timestamp >= userLock[_holder].release_time) return balances[_holder];
    return balances[_holder].sub(userLock[_holder].locked_balance);
  }

   
  function transfer(
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(msg.sender) >= _value);
    return super.transfer(_to, _value);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(_from) >= _value);
    return super.transferFrom(_from, _to, _value);
  }

   
  function approve(
    address _spender,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(msg.sender) >= _value);
    return super.approve(_spender, _value);
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool success)
  {
    require(getFreeBalance(msg.sender) >= allowed[msg.sender][_spender].add(_addedValue));
    return super.increaseApproval(_spender, _addedValue);
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool success)
  {
	uint256 oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue < oldValue) {
      require(getFreeBalance(msg.sender) >= oldValue.sub(_subtractedValue));
    }
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract NaturalEcoCoin is IndividualLockableToken, TokenDestructible {
  using SafeMath for uint256;

  string public constant name = "Natural Eco Carbon";
  string public constant symbol = "NECC";
  uint8  public constant decimals = 18;

   
  uint256 public constant INITIAL_SUPPLY = 2400000000 * (10 ** uint256(decimals));

  constructor()
    public
  {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = totalSupply_;
  }
}