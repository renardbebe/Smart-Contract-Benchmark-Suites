 

pragma solidity ^0.4.24;

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

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

contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
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

contract VictorTokenSale is TimedCrowdsale, Ownable, Whitelist, TokenDestructible {

  using SafeMath for uint256;



   

  uint256 public constant STAGE_1_BONUS_RT = 35;

  uint256 public constant STAGE_2_BONUS_RT = 30;

  uint256 public constant STAGE_3_BONUS_RT = 25;

  uint256 public constant STAGE_4_BONUS_RT = 20;

  uint256 public constant STAGE_5_BONUS_RT = 15;

  uint256 public constant STAGE_6_BONUS_RT = 10;

  uint256 public constant STAGE_7_BONUS_RT =  5;



   

   

  uint256 public constant BOUNDARY_1 =  550000000000000000000000000;

  uint256 public constant BOUNDARY_2 = 1100000000000000000000000000;

  uint256 public constant BOUNDARY_3 = 1650000000000000000000000000;

  uint256 public constant BOUNDARY_4 = 2200000000000000000000000000;

  uint256 public constant BOUNDARY_5 = 2750000000000000000000000000;

  uint256 public constant BOUNDARY_6 = 3300000000000000000000000000;

  uint256 public constant BOUNDARY_7 = 3850000000000000000000000000;  



  VictorToken _token;



  uint256 public bonusRate;

  uint256 public calcAdditionalRatio;

  uint256 public cumulativeSumofToken = 0;



  uint256 public minimum_buy_limit = 0.1 ether;

  uint256 public maximum_buy_limit = 1000 ether;



  event SetPeriod(uint256 _openingTime, uint256 _closingTime);

  event SetBuyLimit(uint256 _minLimit, uint256 _maxLimit);



   

   

   

   

   

  constructor(

    VictorToken _token_,

    address _wallet

  )

    public

    Crowdsale(25000, _wallet, _token_)

    TimedCrowdsale(block.timestamp, block.timestamp + 16 weeks)

  {

    _token = _token_;



    emit SetPeriod(openingTime, closingTime);



    calcBonusRate();

  }



   

   

   

  function _preValidatePurchase(

    address _beneficiary,

    uint256 _weiAmount

  )

    onlyWhileOpen

    onlyIfWhitelisted(_beneficiary)

    internal

  {

    require(_beneficiary != address(0));

    require(_weiAmount >= minimum_buy_limit);

    require(_weiAmount <= maximum_buy_limit);

    require(BOUNDARY_7 >= (cumulativeSumofToken + _weiAmount));

  }



   

  function _getTokenAmount(

    uint256 _weiAmount

  )

    internal

    view

    returns (uint256)

  {

    return (_weiAmount.mul(rate)).add(_weiAmount.mul(calcAdditionalRatio)) ;

  }



   

   

   

  function _updatePurchasingState(

    address _beneficiary,

    uint256 _weiAmount

  )

    internal

  {

    uint256 lockBalance = _weiAmount.mul(calcAdditionalRatio);



    _token.increaseLockBalance(_beneficiary, lockBalance);

    

    cumulativeSumofToken = cumulativeSumofToken.add(_weiAmount.mul(rate));



    calcBonusRate();



    return;

  }



   

   

   

   

  function calcBonusRate()

    public

  {

    if      (cumulativeSumofToken >=          0 && cumulativeSumofToken < BOUNDARY_1 && bonusRate != STAGE_1_BONUS_RT)

    {

      bonusRate = STAGE_1_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_1 && cumulativeSumofToken < BOUNDARY_2 && bonusRate != STAGE_2_BONUS_RT)

    {

      bonusRate = STAGE_2_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_2 && cumulativeSumofToken < BOUNDARY_3 && bonusRate != STAGE_3_BONUS_RT)

    {

      bonusRate = STAGE_3_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_3 && cumulativeSumofToken < BOUNDARY_4 && bonusRate != STAGE_4_BONUS_RT)

    {

      bonusRate = STAGE_4_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_4 && cumulativeSumofToken < BOUNDARY_5 && bonusRate != STAGE_5_BONUS_RT)

    {

      bonusRate = STAGE_5_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_5 && cumulativeSumofToken < BOUNDARY_6 && bonusRate != STAGE_6_BONUS_RT)

    {

      bonusRate = STAGE_6_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_6 && cumulativeSumofToken < BOUNDARY_7 && bonusRate != STAGE_7_BONUS_RT)

    {

      bonusRate = STAGE_7_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_7)

    {

      bonusRate = 0;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    

    return;

  }



   

  function changePeriod(

    uint256 _openingTime,

    uint256 _closingTime

  )

    onlyOwner

    external

    returns (bool)

  {

    require(_openingTime >= block.timestamp);

    require(_closingTime >= _openingTime);



    openingTime = _openingTime;

    closingTime = _closingTime;



    calcAdditionalRatio = (rate.mul(bonusRate)).div(100);



    emit SetPeriod(openingTime, closingTime);



    return true;

  }



   

  function changeLimit(

    uint256 _minLimit,

    uint256 _maxLimit

  )

    onlyOwner

    external

    returns (bool)

  {

    require(_minLimit >= 0 ether);

    require(_maxLimit >= 3 ether);



    minimum_buy_limit = _minLimit;

    maximum_buy_limit = _maxLimit;



    emit SetBuyLimit(minimum_buy_limit, maximum_buy_limit);



    return true;

  }



   

  function bonusDrop(

    address _beneficiary,

    uint256 _tokenAmount

  )

    onlyOwner

    external

    returns (bool)

  {

    _processPurchase(_beneficiary, _tokenAmount);



    emit TokenPurchase(

      msg.sender,

      _beneficiary,

      0,

      _tokenAmount

    );



    _token.increaseLockBalance(_beneficiary, _tokenAmount);



    return true;

  }



   

  function unlockBonusDrop(

    address _beneficiary,

    uint256 _tokenAmount

  )

    onlyOwner

    external

    returns (bool)

  {

    _processPurchase(_beneficiary, _tokenAmount);



    emit TokenPurchase(

      msg.sender,

      _beneficiary,

      0,

      _tokenAmount

    );



    return true;

  }



   

   

   

   

  function increaseTokenLock(

    address _beneficiary,

    uint256 _tokenAmount

  )

    onlyOwner

    external

    returns (bool)

  {

    return(_token.increaseLockBalance(_beneficiary, _tokenAmount));

  }



   

  function decreaseTokenLock(

    address _beneficiary,

    uint256 _tokenAmount

  )

    onlyOwner

    external

    returns (bool)

  {

    return(_token.decreaseLockBalance(_beneficiary, _tokenAmount));

  }



   

  function clearTokenLock(

    address _beneficiary

  )

    onlyOwner

    external

    returns (bool)

  {

    return(_token.clearLock(_beneficiary));

  }



   

  function resetLockReleaseTime(

    address _beneficiary,

    uint256 _releaseTime

  )

    onlyOwner

    external

    returns (bool)

  {

    return(_token.setReleaseTime(_beneficiary, _releaseTime));

  }



   

  function transferTokenOwnership(

    address _newOwner

  )

    onlyOwner

    external

    returns (bool)

  {

    _token.transferOwnership(_newOwner);

    return true;

  }



   

  function pauseToken()

    onlyOwner

    external

    returns (bool)

  {

    _token.pause();

    return true;

  }



   

  function unpauseToken()

    onlyOwner

    external

    returns (bool)

  {

    _token.unpause();

    return true;

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

library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
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

contract VictorToken is IndividualLockableToken, TokenDestructible {

  using SafeMath for uint256;



  string public constant name = "VictorToken";

  string public constant symbol = "VIC";

  uint8  public constant decimals = 18;



   

  uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));



  constructor()

    public

  {

    totalSupply_ = INITIAL_SUPPLY;

    balances[msg.sender] = totalSupply_;

  }

}