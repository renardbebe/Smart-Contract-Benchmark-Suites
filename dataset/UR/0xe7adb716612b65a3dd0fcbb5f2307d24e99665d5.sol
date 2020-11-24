 

 

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

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;




 
contract QTChainVesting is Ownable {
   
   
   
   
   

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event TokensReleased(address beneficiary, uint256 amount);

   
  uint256 constant private _firstMonthPercentage = 10;
  uint256 constant private _otherMonthlyPercentage = 15;
  uint256 constant private _hundred = 100;
  uint256 constant private _oneMonth = 30 days;
  uint256 constant private _duration = 180 days;
  uint256 private _start;
  IERC20 private _token;
  mapping(address => uint256) private _released;
  mapping(address => uint256) private _lockBalance;
  uint256 private _totalLockBalance;

   
  constructor (IERC20 token, uint256 start) public {
    require(start > block.timestamp, "TokenVesting: start time is before current time");
    _token = token;
    _start = start;
  }

   
  modifier notStart() {
    require(block.timestamp < _start, "The lock has begun to release");
    _;
  }
   
  function duration() public pure returns (uint256) {
    return _duration;
  }

   
  function otherMonthlyPercentage() public pure returns (uint256) {
    return _otherMonthlyPercentage;
  }

   
  function firstMonthPercentage() public pure returns (uint256) {
    return _firstMonthPercentage;
  }

   
  function start() public view returns (uint256) {
    return _start;
  }

   
  function setStart(uint256 timestamp) public onlyOwner notStart{
    _start = timestamp;
  }

   
  function lockedBalance(address beneficiary) public view returns (uint256) {
    return _lockBalance[beneficiary];
  }

   
  function released(address beneficiary) public view returns (uint256) {
    return _released[beneficiary];
  }

   
  function release(address beneficiary) public {
    uint256 unreleased = releasableAmount(beneficiary);

    require(unreleased > 0, "TokenVesting: no tokens are due");

    _released[beneficiary] = _released[beneficiary].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

    emit TokensReleased(beneficiary, unreleased);
  }


   
  function releasableAmount(address beneficiary) public view returns (uint256) {
    return vestedAmount(beneficiary).sub(_released[beneficiary]);
  }

   
  function vestedAmount(address beneficiary) public view returns (uint256) {
    uint256 totalBalance = _lockBalance[beneficiary];
    return totalBalance.mul(currentPercentage()).div(_hundred);
  }

   
  function currentPercentage() public view returns (uint256) {
    if (block.timestamp < _start) {
      return 0;
    } else if (block.timestamp < _start.add(_oneMonth)) {
      return _firstMonthPercentage;
    } else if (block.timestamp >= _start.add(_duration)) {
      return _hundred;
    } else {
      uint256 periods = block.timestamp.sub(_start).sub(_oneMonth).div(_oneMonth);
      uint256 increasePercent = periods.mul(_otherMonthlyPercentage).add(_otherMonthlyPercentage);
      return _firstMonthPercentage.add(increasePercent);
    }
  }

   
  function newLock(address beneficiary, uint256 lockBalance) public onlyOwner notStart{
    require(beneficiary != address(0), "zero address");
    require(lockBalance > 0, "The lock amount needs to be greater than 0");
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalLock = _totalLockBalance.sub(_lockBalance[beneficiary]).add(lockBalance);
    require(currentBalance >= totalLock, "Insufficient account balance");
    _totalLockBalance = totalLock;
    _lockBalance[beneficiary] = lockBalance;
  }
}