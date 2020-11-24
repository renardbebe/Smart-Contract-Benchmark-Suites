 

 

pragma solidity 0.5.2;

 

 
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
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

 

 
contract MaticTokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private maticToken;
    uint256 private tokensToVest = 0;
    uint256 private vestingId = 0;

    string private constant INSUFFICIENT_BALANCE = "Insufficient balance";
    string private constant INVALID_VESTING_ID = "Invalid vesting id";
    string private constant VESTING_ALREADY_RELEASED = "Vesting already released";
    string private constant INVALID_BENEFICIARY = "Invalid beneficiary address";
    string private constant NOT_VESTED = "Tokens have not vested yet";

    struct Vesting {
        uint256 releaseTime;
        uint256 amount;
        address beneficiary;
        bool released;
    }
    mapping(uint256 => Vesting) public vestings;

    event TokenVestingReleased(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);
    event TokenVestingAdded(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);
    event TokenVestingRemoved(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);

    constructor(IERC20 _token) public {
        require(address(_token) != address(0x0), "Matic token address is not valid");
        maticToken = _token;

        uint256 SCALING_FACTOR = 10 ** 18;
        uint256 sec = 1 seconds;

        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 0, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 30 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 61 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 91 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 122 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 153 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 183 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 214 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 244 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 275 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 306 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 335 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 366 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 396 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 427 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 457 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 488 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 519 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 549 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 580 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 610 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 641 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 672 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 700 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 731 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 761 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 792 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 822 * sec, 10000 * SCALING_FACTOR);
        addVesting(0x18b0c9A0F972dBB09F34C8ade1820B62DdDdEF76, now + 853 * sec, 10000 * SCALING_FACTOR);
    }

    function token() public view returns (IERC20) {
        return maticToken;
    }

    function beneficiary(uint256 _vestingId) public view returns (address) {
        return vestings[_vestingId].beneficiary;
    }

    function releaseTime(uint256 _vestingId) public view returns (uint256) {
        return vestings[_vestingId].releaseTime;
    }

    function vestingAmount(uint256 _vestingId) public view returns (uint256) {
        return vestings[_vestingId].amount;
    }

    function removeVesting(uint256 _vestingId) public onlyOwner {
        Vesting storage vesting = vestings[_vestingId];
        require(vesting.beneficiary != address(0x0), INVALID_VESTING_ID);
        require(!vesting.released , VESTING_ALREADY_RELEASED);
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        emit TokenVestingRemoved(_vestingId, vesting.beneficiary, vesting.amount);
    }

    function addVesting(address _beneficiary, uint256 _releaseTime, uint256 _amount) public onlyOwner {
        require(_beneficiary != address(0x0), INVALID_BENEFICIARY);
        tokensToVest = tokensToVest.add(_amount);
        vestingId = vestingId.add(1);
        vestings[vestingId] = Vesting({
            beneficiary: _beneficiary,
            releaseTime: _releaseTime,
            amount: _amount,
            released: false
        });
        emit TokenVestingAdded(vestingId, _beneficiary, _amount);
    }

    function release(uint256 _vestingId) public {
        Vesting storage vesting = vestings[_vestingId];
        require(vesting.beneficiary != address(0x0), INVALID_VESTING_ID);
        require(!vesting.released , VESTING_ALREADY_RELEASED);
         
        require(block.timestamp >= vesting.releaseTime, NOT_VESTED);

        require(maticToken.balanceOf(address(this)) >= vesting.amount, INSUFFICIENT_BALANCE);
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        maticToken.safeTransfer(vesting.beneficiary, vesting.amount);
        emit TokenVestingReleased(_vestingId, vesting.beneficiary, vesting.amount);
    }

    function retrieveExcessTokens(uint256 _amount) public onlyOwner {
        require(_amount <= maticToken.balanceOf(address(this)).sub(tokensToVest), INSUFFICIENT_BALANCE);
        maticToken.safeTransfer(owner(), _amount);
    }
}