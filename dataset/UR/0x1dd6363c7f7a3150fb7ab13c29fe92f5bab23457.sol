 

pragma solidity ^0.4.24;

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

contract RBACManager is RBAC, Ownable {
  string constant ROLE_MANAGER = "manager";

  modifier onlyOwnerOrManager() {
    require(
      msg.sender == owner || hasRole(msg.sender, ROLE_MANAGER),
      "unauthorized"
    );
    _;
  }

  constructor() public {
    addRole(msg.sender, ROLE_MANAGER);
  }

  function addManager(address _manager) public onlyOwner {
    addRole(_manager, ROLE_MANAGER);
  }

  function removeManager(address _manager) public onlyOwner {
    removeRole(_manager, ROLE_MANAGER);
  }
}

 

contract CharityProject is RBACManager {
  using SafeMath for uint256;

  modifier canWithdraw() {
    require(
      canWithdrawBeforeEnd || closingTime == 0 || block.timestamp > closingTime,  
      "can't withdraw");
    _;
  }

  uint256 public withdrawn;

  uint256 public maxGoal;
  uint256 public openingTime;
  uint256 public closingTime;
  address public wallet;
  ERC20 public token;
  bool public canWithdrawBeforeEnd;

  constructor (
    uint256 _maxGoal,
    uint256 _openingTime,
    uint256 _closingTime,
    address _wallet,
    ERC20 _token,
    bool _canWithdrawBeforeEnd,
    address _additionalManager
  ) public {
    require(_wallet != address(0), "_wallet can't be zero");
    require(_token != address(0), "_token can't be zero");
    require(
      _closingTime == 0 || _closingTime >= _openingTime,
      "wrong value for _closingTime"
    );

    maxGoal = _maxGoal;
    openingTime = _openingTime;
    closingTime = _closingTime;
    wallet = _wallet;
    token = _token;
    canWithdrawBeforeEnd = _canWithdrawBeforeEnd;

    if (wallet != owner) {
      addManager(wallet);
    }

     
    if (_additionalManager != address(0) && _additionalManager != owner && _additionalManager != wallet) {
      addManager(_additionalManager);
    }
  }

  function withdrawTokens(
    address _to,
    uint256 _value
  )
  public
  onlyOwnerOrManager
  canWithdraw
  {
    token.transfer(_to, _value);
    withdrawn = withdrawn.add(_value);
  }

  function totalRaised() public view returns (uint256) {
    uint256 raised = token.balanceOf(this);
    return raised.add(withdrawn);
  }

  function hasStarted() public view returns (bool) {
     
    return openingTime == 0 ? true : block.timestamp > openingTime;
  }

  function hasClosed() public view returns (bool) {
     
    return closingTime == 0 ? false : block.timestamp > closingTime;
  }

  function maxGoalReached() public view returns (bool) {
    return totalRaised() >= maxGoal;
  }

  function setMaxGoal(uint256 _newMaxGoal) public onlyOwner {
    maxGoal = _newMaxGoal;
  }

  function setTimes(
    uint256 _openingTime,
    uint256 _closingTime
  )
  public
  onlyOwner
  {
    require(
      _closingTime == 0 || _closingTime >= _openingTime,
      "wrong value for _closingTime"
    );

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  function setCanWithdrawBeforeEnd(
    bool _canWithdrawBeforeEnd
  )
  public
  onlyOwner
  {
    canWithdrawBeforeEnd = _canWithdrawBeforeEnd;
  }
}