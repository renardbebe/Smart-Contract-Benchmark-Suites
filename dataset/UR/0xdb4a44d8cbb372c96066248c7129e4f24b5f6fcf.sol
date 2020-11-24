 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
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

 

contract RBACManager is Ownable {
  using Roles for Roles.Role;

  event ManagerAdded(address indexed account);
  event ManagerRemoved(address indexed account);

  Roles.Role private managers;

  modifier onlyOwnerOrManager() {
    require(
      msg.sender == owner() || isManager(msg.sender),
      "unauthorized"
    );
    _;
  }

  constructor() public {
    addManager(msg.sender);
  }

  function isManager(address account) public view returns (bool) {
    return managers.has(account);
  }

  function addManager(address account) public onlyOwner {
    managers.add(account);
    emit ManagerAdded(account);
  }

  function removeManager(address account) public onlyOwner {
    managers.remove(account);
    emit ManagerRemoved(account);
  }
}

 

contract CharityProject is RBACManager {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  modifier canWithdraw() {
    require(
      _canWithdrawBeforeEnd || _closingTime == 0 || block.timestamp > _closingTime,  
      "can't withdraw");
    _;
  }

  uint256 private _feeInMillis;
  uint256 private _withdrawnTokens;
  uint256 private _withdrawnFees;
  uint256 private _maxGoal;
  uint256 private _openingTime;
  uint256 private _closingTime;
  address private _wallet;
  IERC20 private _token;
  bool private _canWithdrawBeforeEnd;

  constructor (
    uint256 feeInMillis,
    uint256 maxGoal,
    uint256 openingTime,
    uint256 closingTime,
    address wallet,
    IERC20 token,
    bool canWithdrawBeforeEnd,
    address additionalManager
  ) public {
    require(wallet != address(0), "wallet can't be zero");
    require(token != address(0), "token can't be zero");
    require(
      closingTime == 0 || closingTime >= openingTime,
      "wrong value for closingTime"
    );

    _feeInMillis = feeInMillis;
    _maxGoal = maxGoal;
    _openingTime = openingTime;
    _closingTime = closingTime;
    _wallet = wallet;
    _token = token;
    _canWithdrawBeforeEnd = canWithdrawBeforeEnd;

    if (_wallet != owner()) {
      addManager(_wallet);
    }

     
    if (additionalManager != address(0) && additionalManager != owner() && additionalManager != _wallet) {
      addManager(additionalManager);
    }
  }

   
   
   

  function feeInMillis() public view returns(uint256) {
    return _feeInMillis;
  }

  function withdrawnTokens() public view returns(uint256) {
    return _withdrawnTokens;
  }

  function withdrawnFees() public view returns(uint256) {
    return _withdrawnFees;
  }

  function maxGoal() public view returns(uint256) {
    return _maxGoal;
  }

  function openingTime() public view returns(uint256) {
    return _openingTime;
  }

  function closingTime() public view returns(uint256) {
    return _closingTime;
  }

  function wallet() public view returns(address) {
    return _wallet;
  }

  function token() public view returns(IERC20) {
    return _token;
  }

  function canWithdrawBeforeEnd() public view returns(bool) {
    return _canWithdrawBeforeEnd;
  }

   
   
   

  function setMaxGoal(uint256 newMaxGoal) public onlyOwner {
    _maxGoal = newMaxGoal;
  }

  function setTimes(
    uint256 newOpeningTime,
    uint256 newClosingTime
  )
  public
  onlyOwner
  {
    require(
      newClosingTime == 0 || newClosingTime >= newOpeningTime,
      "wrong value for closingTime"
    );

    _openingTime = newOpeningTime;
    _closingTime = newClosingTime;
  }

  function setCanWithdrawBeforeEnd(
    bool newCanWithdrawBeforeEnd
  )
  public
  onlyOwner
  {
    _canWithdrawBeforeEnd = newCanWithdrawBeforeEnd;
  }

   
   
   

  function totalRaised() public view returns (uint256) {
    uint256 raised = _token.balanceOf(this);
    return raised.add(_withdrawnTokens).add(_withdrawnFees);
  }

  function totalFee() public view returns (uint256) {
    return totalRaised().mul(_feeInMillis).div(1000);
  }

  function hasStarted() public view returns (bool) {
     
    return _openingTime == 0 ? true : block.timestamp > _openingTime;
  }

  function hasClosed() public view returns (bool) {
     
    return _closingTime == 0 ? false : block.timestamp > _closingTime;
  }

  function maxGoalReached() public view returns (bool) {
    return totalRaised() >= _maxGoal;
  }

   
   
   

  function withdrawTokens(
    address to,
    uint256 value
  )
  public
  onlyOwnerOrManager
  canWithdraw
  {
    uint256 expectedTotalWithdraw = _withdrawnTokens.add(value);
    require(
      expectedTotalWithdraw <= totalRaised().sub(totalFee()),
      "can't withdraw more than available token"
    );
    _withdrawnTokens = expectedTotalWithdraw;
    _token.safeTransfer(to, value);
  }

  function withdrawFees(
    address to,
    uint256 value
  )
  public
  onlyOwner
  canWithdraw
  {
    uint256 expectedTotalWithdraw = _withdrawnFees.add(value);
    require(
      expectedTotalWithdraw <= totalFee(),
      "can't withdraw more than available fee"
    );
    _withdrawnFees = expectedTotalWithdraw;
    _token.safeTransfer(to, value);
  }

  function recoverERC20(
    address tokenAddress,
    address receiverAddress,
    uint256 amount
  )
  public
  onlyOwnerOrManager
  {
    require(
      tokenAddress != address(_token),
      "to transfer project's funds use withdrawTokens"
    );
    IERC20(tokenAddress).safeTransfer(receiverAddress, amount);
  }
}