 

pragma solidity ^0.5.0;


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

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
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

contract Pausable is PauserRole {
    
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
        emit Paused(msg.sender);
    }

    
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

interface IDistribution {
    event RewardAssigned(uint256 periodEnd, address indexed masternode, uint256 value);
    event RewardCollected(uint256 periodEnd, address indexed masternode, uint256 value);
    event RewardSet(address indexed masternode, uint256 value);

    function rewardOf(address account) external view returns (uint256);
    function periodEndOf(address account) external view returns (uint256);

    function assignRewards(uint256 periodEnd, address[] calldata accounts, uint256[] calldata values) external returns (bool);
    function encodedAssignRewards(uint256 periodEnd, uint160 lotSize, uint256[] calldata rewards) external returns (bool);
    function collect() external returns (bool);
    function collectRewards(address[] calldata accounts) external returns (bool);
    function clear() external returns (bool);
}

contract ManagerRole {
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private _manager;

    
    modifier onlyManager() {
        require(_isManager(msg.sender));
        _;
    }

    function _addManager(address account) internal {
        _manager.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(address account) internal {
        _manager.remove(account);
        emit ManagerRemoved(account);
    }

    function _isManager(address account) internal view returns (bool) {
        return _manager.has(account);
    }
}

contract Distribution is IDistribution, ManagerRole, Ownable, Pausable {
    using SafeMath for uint256;

    struct AccountReward {
        uint256 reward;
        uint256 periodEnd;
    }

    
    mapping(address => AccountReward) public _rewards;

    
    IERC20 private _swmERC20;

    
    constructor(address swmERC20) public {
        _swmERC20 = IERC20(swmERC20);
    }

    
    
    function rewardOf(address account) external view returns (uint256) {
        return _rewards[account].reward;
    }

    
    function periodEndOf(address account) external view returns (uint256) {
        return _rewards[account].periodEnd;
    }

    
    function assignRewards(uint256 periodEnd, address[] calldata accounts, uint256[] calldata values) external whenNotPaused onlyOwnerOrManager returns (bool) {
        require(accounts.length != 0, "Accounts length is zero");
        require(accounts.length == values.length, "Lengths difference");
        require(periodEnd < now, "Period end is in future");

        uint256 sumValues = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            _assign(periodEnd, accounts[i], values[i]);

            sumValues = sumValues.add(values[i]);
        }

        require(_swmERC20.transferFrom(msg.sender, address(this), sumValues));

        return true;
    }

    
    function encodedAssignRewards(uint256 periodEnd, uint160 lotSize, uint256[] calldata rewards) external whenNotPaused onlyOwnerOrManager returns (bool) {
        require(rewards.length != 0, "Values length is zero");
        require(periodEnd < now, "Period end is in future");

        uint256 count = rewards.length;
        uint256 sumValues = 0;

        for (uint256 i = 0; i < count; i++) {
            uint256 reward = rewards[i];
            uint256 value = (reward >> 160) * lotSize;
            address to = address(reward & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            _assign(periodEnd, to, value);

            sumValues = sumValues.add(value);
        }

        require(_swmERC20.transferFrom(msg.sender, address(this), sumValues), "Transfer from failed");

        return true;
    }

    
    function setRewards(address[] calldata accounts, uint256[] calldata values) external whenPaused onlyOwner returns (bool) {
        require(accounts.length != 0, "Accounts length is zero");
        require(accounts.length == values.length, "Lengths difference");

        for (uint256 i = 0; i < accounts.length; i++) {
            _set(accounts[i], values[i]);
        }

        return true;
    }

    
    function collect() external whenNotPaused returns (bool) {
        _collect(msg.sender);

        return true;
    }

    
    function collectRewards(address[] calldata accounts) external onlyOwner returns (bool) {
        require(accounts.length != 0, "Accounts length is zero");

        for (uint256 i = 0; i < accounts.length; i++) {
            _collect(accounts[i]);
        }

        return true;
    }

    
    function clear() external onlyOwner returns (bool) {
        return _swmERC20.transfer(msg.sender, _swmERC20.balanceOf(address(this)));
    }

    
    
    function isManager(address account) external view returns (bool) {
        return _isManager(account);
    }

    
    function addManager(address account) external onlyOwner {
        _addManager(account);
    }

    
    function removeManager(address account) external onlyOwner {
        _removeManager(account);
    }

    
    modifier onlyOwnerOrManager() {
        require(isOwner() || _isManager(msg.sender), "Not Owner or Manager");
        _;
    }

    
    function _collect(address account) internal {
        require(_rewards[account].reward != 0, "Reward is zero");

        uint256 reward = _rewards[account].reward;
        uint256 periodEnd = _rewards[account].periodEnd;

        delete _rewards[account].reward;

        require(_swmERC20.transfer(account, reward));

        emit RewardCollected(periodEnd, account, reward);
    }

    function _assign(uint256 periodEnd, address account, uint256 value) internal {
        require(value != 0, "Value is zero");
        require(account != address(0), "Account address is zero");
        require(periodEnd > _rewards[account].periodEnd, "Period end less than saved for account");

        _rewards[account].reward = _rewards[account].reward.add(value);
        _rewards[account].periodEnd = periodEnd;

        emit RewardAssigned(periodEnd, account, value);
    }

    function _set(address account, uint256 value) internal {
        require(account != address(0), "Account address is zero");

        _rewards[account].reward = value;

        emit RewardSet(account, value);
    }
}