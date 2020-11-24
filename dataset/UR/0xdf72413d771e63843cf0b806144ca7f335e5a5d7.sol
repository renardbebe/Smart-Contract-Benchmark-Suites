 

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract Pausable is Context, PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.5;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

 

pragma solidity ^0.5.0;




 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;




contract Withdrawable is Ownable {
    using SafeERC20 for IERC20;

    function adminWithdraw(address asset) onlyOwner public {
        uint amount = adminWitrawAllowed(asset);
        require(amount > 0, "admin witdraw not allowed");
        if (asset == address(0)) {
            msg.sender.transfer(amount);
        } else {
            IERC20(asset).safeTransfer(msg.sender, amount);
        }
    }

     
    function adminWitrawAllowed(address asset) internal view returns(uint allowedAmount) {
        allowedAmount = asset == address(0)
            ? address(this).balance
            : IERC20(asset).balanceOf(address(this));
    }
}

 

pragma solidity ^0.5.0;






contract SimpleStaking is Withdrawable, Pausable {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  IERC20 public token;
  uint public stakingStart;
  uint public stakingEnd;
  uint public interestRate;
  uint constant interestRateUnit = 1e6;
 
 
  uint constant HUGE_TIME = 99999999999999999;
  uint public adminStopTime = HUGE_TIME;
  uint public accruingInterval;

  mapping (address => uint) public lockedAmount;
  mapping (address => uint) public alreadyWithdrawn;
  uint public totalLocked;
  uint public totalWithdrawn;

  uint public interestReserveBalance;

  event StakingUpdated(address indexed user, uint userLocked, uint remainingInterestReserve);
  event Withdraw(address investor, uint amount);

  constructor (address token_, uint start_, uint end_, uint accruingInterval_, uint rate_) public {
    token = IERC20(token_);
    require(end_ > start_, "end must be greater than start");
    stakingStart = start_;
    stakingEnd = end_;
    require(rate_ > 0 && rate_ < interestRateUnit, "rate must be greater than 0 and lower than unit");
    interestRate = rate_;
    require(accruingInterval_ > 0, "accruingInterval_ must be greater than 0");
    require((end_ - start_) % accruingInterval_ == 0, "end time not alligned");
    require(end_ - start_ >= accruingInterval_, "end - start must be greater than accruingInterval");
    accruingInterval = accruingInterval_;
  }

  modifier afterStart() {
    require(stakingStart < now, "Only after start");
    _;
  }

  modifier beforeStart() {
    require(now < stakingStart, "Only before start");
    _;
  }

  function adminWitrawAllowed(address asset) internal view returns(uint) {
    if (asset != address(token)) {
      return super.adminWitrawAllowed(asset);
    } else {
      uint balance = token.balanceOf(address(this));
      uint interest = adminStopTime == HUGE_TIME
        ? _getTotalInterestAmount(totalLocked)
        : _getAccruedInterest(totalLocked, adminStopTime);
      uint reserved = totalLocked.add(interest).sub(totalWithdrawn);
      return reserved < balance ? balance - reserved : 0;
    }
  }

  function _min(uint a, uint b) private pure returns(uint) {
    return a < b ? a : b;
  }

  function _max(uint a, uint b) private pure returns(uint) {
    return a > b ? a : b;
  }

  function adminStop() public onlyOwner {
    require(adminStopTime == HUGE_TIME, "already admin stopped");
    require(now < stakingEnd, "already ended");
    adminStopTime = _max(now, stakingStart);
  }

  function _transferTokensFromSender(uint amount) private {
    require(amount > 0, "Invalid amount");
    uint expectedBalance = token.balanceOf(address(this)).add(amount);
    token.safeTransferFrom(msg.sender, address(this), amount);
    require(token.balanceOf(address(this)) == expectedBalance, "Invalid balance after transfer");
  }

  function addFundsForInterests(uint amount) public {
    _transferTokensFromSender(amount);
    interestReserveBalance = interestReserveBalance.add(amount);
  }

  function getAvailableStaking() external view returns(uint) {
    return now > stakingStart
    ? 0
    : interestReserveBalance.mul(interestRateUnit).div(interestRate).add(interestRateUnit / interestRate).sub(1);
  }

  function _getTotalInterestAmount(uint investmentAmount) private view returns(uint) {
    return investmentAmount.mul(interestRate).div(interestRateUnit);
  }

  function getAccruedInterestNow(address user) public view returns(uint) {
    return getAccruedInterest(user, now);
  }

  function getAccruedInterest(address user, uint time) public view returns(uint) {
    uint totalInterest = _getTotalInterestAmount(lockedAmount[user]);
    return _getAccruedInterest(totalInterest, time);
  }

  function _getAccruedInterest(uint totalInterest, uint time) private view returns(uint) {
    if (time < stakingStart + accruingInterval) {
      return 0;
    } else if ( stakingEnd <= time && time < adminStopTime) {
      return totalInterest;
    } else {
      uint lockTimespanLength = stakingEnd - stakingStart;
      uint elapsed = _min(time, adminStopTime).sub(stakingStart).div(accruingInterval).mul(accruingInterval);
      return totalInterest.mul(elapsed).div(lockTimespanLength);
    }
  }

  function addStaking(uint amount) external
    whenNotPaused
    beforeStart
  {
    require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
    uint interestAmount = _getTotalInterestAmount(amount);
    require(interestAmount <= interestReserveBalance, "No tokens available for interest");

    _transferTokensFromSender(amount);
    interestReserveBalance = interestReserveBalance.sub(interestAmount);

    uint newLockedAmount = lockedAmount[msg.sender].add(amount);
    lockedAmount[msg.sender] = newLockedAmount;
    totalLocked = totalLocked.add(amount);

    emit StakingUpdated(msg.sender, newLockedAmount, interestReserveBalance);
  }

  function withdraw() external
    afterStart
    returns(uint)
  {
    uint locked = lockedAmount[msg.sender];
    uint withdrawn = alreadyWithdrawn[msg.sender];
    uint accruedInterest = getAccruedInterest(msg.sender, now);
    uint unlockedAmount = now < _min(stakingEnd, adminStopTime) ? 0 : locked;

    uint accrued = accruedInterest + unlockedAmount;
    require(accrued > withdrawn, "nothing to withdraw");
    uint toTransfer = accrued.sub(withdrawn);

    alreadyWithdrawn[msg.sender] = withdrawn.add(toTransfer);
    totalWithdrawn = totalWithdrawn.add(toTransfer);
    token.safeTransfer(msg.sender, toTransfer);
    emit Withdraw(msg.sender, toTransfer);

    return toTransfer;
  }
}