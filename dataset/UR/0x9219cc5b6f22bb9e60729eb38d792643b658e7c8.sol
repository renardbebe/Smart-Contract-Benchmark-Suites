 

 

pragma solidity ^0.4.24;

 
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

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event TokensReleased(address token, uint256 amount);

   
  address private _beneficiary;

  uint256 private _cliff;
  uint256 private _start;
  uint256 private _duration;

  mapping (address => uint256) private _released;
   
  constructor(
    address beneficiary,
    uint256 start,
    uint256 cliffDuration,
    uint256 duration
  )
    public
  {
    require(beneficiary != address(0));
    require(cliffDuration <= duration);
    require(duration > 0);
    require(start.add(duration) > block.timestamp);

    _beneficiary = beneficiary;
    _duration = duration;
    _cliff = start.add(cliffDuration);
    _start = start;
  }

   
  function beneficiary() public view returns(address) {
    return _beneficiary;
  }

   
  function cliff() public view returns(uint256) {
    return _cliff;
  }

   
  function start() public view returns(uint256) {
    return _start;
  }

   
  function duration() public view returns(uint256) {
    return _duration;
  }

   
  function released(address token) public view returns(uint256) {
    return _released[token];
  }

   
  function releasable(address token) public view returns(uint256) {
    return _releasableAmount(IERC20(token));
  }

   
  function release(IERC20 token) public {
    uint256 unreleased = _releasableAmount(token);

    require(unreleased > 0);

    _released[token] = _released[token].add(unreleased);

    token.safeTransfer(_beneficiary, unreleased);

    emit TokensReleased(token, unreleased);
  }

   
  function _releasableAmount(IERC20 token) private view returns (uint256) {
    return _vestedAmount(token).sub(_released[token]);
  }

   
  function _vestedAmount(IERC20 token) private view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(_released[token]);

    if (block.timestamp < _cliff) {
      return 0;
    } else if (block.timestamp >= _start.add(_duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
    }
  }
}