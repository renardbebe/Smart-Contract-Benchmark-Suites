 

pragma solidity ^0.5.2;


 


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 


 
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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

 



contract OwnerRole {
    using Roles for Roles.Role;

    event OwnerAdded(address indexed account);
    event OwnerRemoved(address indexed account);

    Roles.Role private _owners;

    constructor () internal {
        _addOwner(msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "OwnerRole: caller does not have the Owner role");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return _owners.has(account);
    }

    function addOwner(address account) public onlyOwner {
         
        _addOwner(account);
         
    }

    function renounceOwner() public {
        _removeOwner(msg.sender);
    }

    function _addOwner(address account) internal {
        _owners.add(account);
        emit OwnerAdded(account);
    }

    function _removeOwner(address account) internal {
        _owners.remove(account);
        emit OwnerRemoved(account);
    }
}

 






 
contract TokenVesting is OwnerRole {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private token;
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

    constructor(IERC20 _token, address _beneficiary, uint256 _day) public {
        require(address(_token) != address(0x0), "Token address is not valid");
        token = _token;
        addVestingPlan(_beneficiary, _day);
    }

    function getToken() public view returns (IERC20) {
        return token;
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
        require(!vesting.released, VESTING_ALREADY_RELEASED);
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
        require(!vesting.released, VESTING_ALREADY_RELEASED);
         
        require(block.timestamp >= vesting.releaseTime, NOT_VESTED);

        require(token.balanceOf(address(this)) >= vesting.amount, INSUFFICIENT_BALANCE);
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        token.safeTransfer(vesting.beneficiary, vesting.amount);
        emit TokenVestingReleased(_vestingId, vesting.beneficiary, vesting.amount);
    }

    function retrieveExcessTokens(uint256 _amount) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)).sub(tokensToVest), INSUFFICIENT_BALANCE);
        token.safeTransfer(msg.sender, _amount);
    }

    function addVestingPlan(address _beneficiary, uint256 _day) private onlyOwner {
        uint256 SCALING_FACTOR = 10 ** 18;
        uint256 day = _day;
        addVesting(_beneficiary, now + 0, 3230085552 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 30 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 61 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 91 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 122 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 153 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 183 * day, 1088418885 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 214 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 244 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 275 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 306 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 335 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 366 * day, 1218304816 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 396 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 427 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 457 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 488 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 519 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 549 * day, 1218304816 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 580 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 610 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 641 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 672 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 700 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 731 * day, 1084971483 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 761 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 792 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 822 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 853 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 884 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 914 * day, 618304816 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 945 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 975 * day, 25000000 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 1096 * day, 593304816 * SCALING_FACTOR);
        addVesting(_beneficiary, now + 1279 * day, 273304816 * SCALING_FACTOR);
    }
}