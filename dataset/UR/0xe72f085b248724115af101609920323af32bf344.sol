 

pragma solidity ^0.5.7;

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
contract TokenRecover is Ownable {

     
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
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

 

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

 
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
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         

        require(address(token).isContract());

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)));
        }
    }
}

 

 
contract TokenTimelock {
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address private _beneficiary;

     
    uint256 private _releaseTime;

    constructor (IERC20 token, address beneficiary, uint256 releaseTime) public {
         
        require(releaseTime > block.timestamp);
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

     
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

     
    function release() public {
         
        require(block.timestamp >= _releaseTime);

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0);

        _token.safeTransfer(_beneficiary, amount);
    }
}

 

 
contract MBMTimelock is TokenTimelock {

     
    string private _note;

     
    constructor(
        IERC20 token,
        address beneficiary,
        uint256 releaseTime,
        string memory note
    )
        public
        TokenTimelock(token, beneficiary, releaseTime)
    {
        _note = note;
    }

     
    function note() public view returns (string memory) {
        return _note;
    }
}

 

 
contract MBMLockBuilder is TokenRecover {
    using SafeERC20 for IERC20;

    event LockCreated(address indexed timelock, address indexed beneficiary, uint256 releaseTime, uint256 amount);

     
    IERC20 private _token;

     
    constructor(IERC20 token) public {
        require(address(token) != address(0));

        _token = token;
    }

     
    function createLock(
        address beneficiary,
        uint256 releaseTime,
        uint256 amount,
        string calldata note
    )
        external
        onlyOwner
    {
        MBMTimelock lock = new MBMTimelock(_token, beneficiary, releaseTime, note);

        emit LockCreated(address(lock), beneficiary, releaseTime, amount);

        if (amount > 0) {
            _token.safeTransfer(address(lock), amount);
        }
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }
}