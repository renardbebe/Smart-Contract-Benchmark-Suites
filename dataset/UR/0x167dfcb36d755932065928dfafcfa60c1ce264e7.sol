 

pragma solidity ^0.4.24;

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 

 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

interface IGrowHops {

  function addPlanBase(uint256 minimumAmount, uint256 lockTime, uint32 lessToHops) external;

  function togglePlanBase(bytes32 planBaseId, bool isOpen) external;

  function growHops(bytes32 planBaseId, uint256 lessAmount) external;

  function updateHopsAddress(address _address) external;

  function updatelessAddress(address _address) external;

  function withdraw(bytes32 planId) external;

  function checkPlanBase(bytes32 planBaseId)
    external view returns (uint256, uint256, uint32, bool);
  
  function checkPlanBaseIds() external view returns(bytes32[]);

  function checkPlanIdsByPlanBase(bytes32 planBaseId) external view returns(bytes32[]);

  function checkPlanIdsByUser(address user) external view returns(bytes32[]);

  function checkPlan(bytes32 planId)
    external view returns (bytes32, address, uint256, uint256, uint256, uint256, bool);

   

  event PlanBaseEvt (
    bytes32 planBaseId,
    uint256 minimumAmount,
    uint256 lockTime,
    uint32 lessToHops,
    bool isOpen
  );

  event TogglePlanBaseEvt (
    bytes32 planBaseId,
    bool isOpen
  );

  event PlanEvt (
    bytes32 planId,
    bytes32 planBaseId,
    address plantuser,
    uint256 lessAmount,
    uint256 hopsAmount,
    uint256 lockAt,
    uint256 releaseAt,
    bool isWithdrawn
  );

  event WithdrawPlanEvt (
    bytes32 planId,
    address plantuser,
    uint256 lessAmount,
    bool isWithdrawn,
    uint256 withdrawAt
  );

}

 

 
library SafeMath {
   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function mul(uint256 a, uint256 b) 
      internal 
      pure 
      returns (uint256 c) 
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath mul failed");
    return c;
  }

   
  function sub(uint256 a, uint256 b)
      internal
      pure
      returns (uint256) 
  {
    require(b <= a, "SafeMath sub failed");
    return a - b;
  }

   
  function add(uint256 a, uint256 b)
      internal
      pure
      returns (uint256 c) 
  {
    c = a + b;
    require(c >= a, "SafeMath add failed");
    return c;
  }
  
   
  function sqrt(uint256 x)
      internal
      pure
      returns (uint256 y) 
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y) 
    {
      y = z;
      z = ((add((x / z),z)) / 2);
    }
  }
  
   
  function sq(uint256 x)
      internal
      pure
      returns (uint256)
  {
    return (mul(x,x));
  }
  
   
  function pwr(uint256 x, uint256 y)
      internal 
      pure 
      returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else 
    {
      uint256 z = x;
      for (uint256 i=1; i < y; i++)
        z = mul(z,x);
      return (z);
    }
  }
}

 

interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function allowance(address tokenOwner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function mint(address to, uint256 value) external returns (bool);
}

contract GrowHops is IGrowHops, Ownable, Pausable {

  using SafeMath for *;

  address public hopsAddress;
  address public lessAddress;

  struct PlanBase {
    uint256 minimumAmount;
    uint256 lockTime;
    uint32 lessToHops;
    bool isOpen;
  }

  struct Plan {
    bytes32 planBaseId;
    address plantuser;
    uint256 lessAmount;
    uint256 hopsAmount;
    uint256 lockAt;
    uint256 releaseAt;
    bool isWithdrawn;
  }
  bytes32[] public planBaseIds;

  mapping (bytes32 => bytes32[]) planIdsByPlanBase;
  mapping (bytes32 => PlanBase) planBaseIdToPlanBase;
  
  mapping (bytes32 => Plan) planIdToPlan;
  mapping (address => bytes32[]) userToPlanIds;

  constructor (address _hopsAddress, address _lessAddress) public {
    hopsAddress = _hopsAddress;
    lessAddress = _lessAddress;
  }

  function addPlanBase(uint256 minimumAmount, uint256 lockTime, uint32 lessToHops)
    onlyOwner external {
    bytes32 planBaseId = keccak256(
      abi.encodePacked(block.timestamp, minimumAmount, lockTime, lessToHops)
    );

    PlanBase memory planBase = PlanBase(
      minimumAmount,
      lockTime,
      lessToHops,
      true
    );

    planBaseIdToPlanBase[planBaseId] = planBase;
    planBaseIds.push(planBaseId);
    emit PlanBaseEvt(planBaseId, minimumAmount, lockTime, lessToHops, true);
  }

  function togglePlanBase(bytes32 planBaseId, bool isOpen) onlyOwner external {

    planBaseIdToPlanBase[planBaseId].isOpen = isOpen;
    emit TogglePlanBaseEvt(planBaseId, isOpen);
  }
  
  function growHops(bytes32 planBaseId, uint256 lessAmount) whenNotPaused external {
    address sender = msg.sender;
    require(IERC20(lessAddress).allowance(sender, address(this)) >= lessAmount);

    PlanBase storage planBase = planBaseIdToPlanBase[planBaseId];
    require(planBase.isOpen);
    require(lessAmount >= planBase.minimumAmount);
    bytes32 planId = keccak256(
      abi.encodePacked(block.timestamp, sender, planBaseId, lessAmount)
    );
    uint256 hopsAmount = lessAmount.mul(planBase.lessToHops);

    Plan memory plan = Plan(
      planBaseId,
      sender,
      lessAmount,
      hopsAmount,
      block.timestamp,
      block.timestamp.add(planBase.lockTime),
      false
    );
    
    require(IERC20(lessAddress).transferFrom(sender, address(this), lessAmount));
    require(IERC20(hopsAddress).mint(sender, hopsAmount));

    planIdToPlan[planId] = plan;
    userToPlanIds[sender].push(planId);
    planIdsByPlanBase[planBaseId].push(planId);
    emit PlanEvt(planId, planBaseId, sender, lessAmount, hopsAmount, block.timestamp, block.timestamp.add(planBase.lockTime), false);
  }

  function updateHopsAddress(address _address) external onlyOwner {
    hopsAddress = _address;
  }

  function updatelessAddress(address _address) external onlyOwner {
    lessAddress = _address;
  }

  function withdraw(bytes32 planId) whenNotPaused external {
    address sender = msg.sender;
    Plan storage plan = planIdToPlan[planId];
    require(!plan.isWithdrawn);
    require(plan.plantuser == sender);
    require(block.timestamp >= plan.releaseAt);
    require(IERC20(lessAddress).transfer(sender, plan.lessAmount));

    planIdToPlan[planId].isWithdrawn = true;
    emit WithdrawPlanEvt(planId, sender, plan.lessAmount, true, block.timestamp);
  }

  function checkPlanBase(bytes32 planBaseId)
    external view returns (uint256, uint256, uint32, bool){
    PlanBase storage planBase = planBaseIdToPlanBase[planBaseId];
    return (
      planBase.minimumAmount,
      planBase.lockTime,
      planBase.lessToHops,
      planBase.isOpen
    );
  }

  function checkPlanBaseIds() external view returns(bytes32[]) {
    return planBaseIds;
  }

  function checkPlanIdsByPlanBase(bytes32 planBaseId) external view returns(bytes32[]) {
    return planIdsByPlanBase[planBaseId];
  }

  function checkPlanIdsByUser(address user) external view returns(bytes32[]) {
    return userToPlanIds[user];
  }

  function checkPlan(bytes32 planId)
    external view returns (bytes32, address, uint256, uint256, uint256, uint256, bool) {
    Plan storage plan = planIdToPlan[planId];
    return (
      plan.planBaseId,
      plan.plantuser,
      plan.lessAmount,
      plan.hopsAmount,
      plan.lockAt,
      plan.releaseAt,
      plan.isWithdrawn
    );
  }
}