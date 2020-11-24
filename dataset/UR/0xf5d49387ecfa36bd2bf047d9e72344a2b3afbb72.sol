 

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
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

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.2;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
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

 

pragma solidity ^0.5.2;


 
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

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

pragma solidity ^0.5.2;

 
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }
}

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.2;




 
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

 

pragma solidity 0.5.4;


interface IERC1594Capped {
    function balanceOf(address who) external view returns (uint256);
    function cap() external view returns (uint256);
    function totalRedeemed() external view returns (uint256);
}

 

pragma solidity 0.5.4;


interface IRewards {
    event Deposited(address indexed from, uint amount);
    event Withdrawn(address indexed from, uint amount);
    event Reclaimed(uint amount);

    function deposit(uint amount) external;
    function withdraw() external;
    function reclaimRewards() external;
    function claimedRewards(address payee) external view returns (uint);
    function unclaimedRewards(address payee) external view returns (uint);
    function supply() external view returns (uint);
    function isRunning() external view returns (bool);
}

 

pragma solidity 0.5.4;


interface IRewardsUpdatable {
    event NotifierUpdated(address implementation);

    function updateOnTransfer(address from, address to, uint amount) external returns (bool);
    function updateOnBurn(address account, uint amount) external returns (bool);
    function setRewardsNotifier(address notifier) external;
}

 

pragma solidity 0.5.4;



interface IRewardable {
    event RewardsUpdated(address implementation);

    function setRewards(IRewardsUpdatable rewards) external;
}

 

pragma solidity 0.5.4;



 
contract RewarderRole {
    using Roles for Roles.Role;

    event RewarderAdded(address indexed account);
    event RewarderRemoved(address indexed account);

    Roles.Role internal _rewarders;

    modifier onlyRewarder() {
        require(isRewarder(msg.sender), "Only Rewarders can execute this function.");
        _;
    }

    constructor() internal {
        _addRewarder(msg.sender);
    }    

    function isRewarder(address account) public view returns (bool) {
        return _rewarders.has(account);
    }

    function addRewarder(address account) public onlyRewarder {
        _addRewarder(account);
    }

    function renounceRewarder() public {
        _removeRewarder(msg.sender);
    }
  
    function _addRewarder(address account) internal {
        _rewarders.add(account);
        emit RewarderAdded(account);
    }

    function _removeRewarder(address account) internal {
        _rewarders.remove(account);
        emit RewarderRemoved(account);
    }
}

 

pragma solidity 0.5.4;



 
contract ModeratorRole {
    using Roles for Roles.Role;

    event ModeratorAdded(address indexed account);
    event ModeratorRemoved(address indexed account);

    Roles.Role internal _moderators;

    modifier onlyModerator() {
        require(isModerator(msg.sender), "Only Moderators can execute this function.");
        _;
    }

    constructor() internal {
        _addModerator(msg.sender);
    }

    function isModerator(address account) public view returns (bool) {
        return _moderators.has(account);
    }

    function addModerator(address account) public onlyModerator {
        _addModerator(account);
    }

    function renounceModerator() public {
        _removeModerator(msg.sender);
    }    

    function _addModerator(address account) internal {
        _moderators.add(account);
        emit ModeratorAdded(account);
    }    

    function _removeModerator(address account) internal {
        _moderators.remove(account);
        emit ModeratorRemoved(account);
    }
}

 

pragma solidity 0.5.4;



contract Whitelistable is ModeratorRole {
    event Whitelisted(address account);
    event Unwhitelisted(address account);

    mapping (address => bool) public isWhitelisted;

    modifier onlyWhitelisted(address account) {
        require(isWhitelisted[account], "Account is not whitelisted.");
        _;
    }

    modifier onlyNotWhitelisted(address account) {
        require(!isWhitelisted[account], "Account is whitelisted.");
        _;
    }

    function whitelist(address account) external onlyModerator {
        require(account != address(0), "Cannot whitelist zero address.");
        require(account != msg.sender, "Cannot whitelist self.");
        require(!isWhitelisted[account], "Address already whitelisted.");
        isWhitelisted[account] = true;
        emit Whitelisted(account);
    }

    function unwhitelist(address account) external onlyModerator {
        require(account != address(0), "Cannot unwhitelist zero address.");
        require(account != msg.sender, "Cannot unwhitelist self.");
        require(isWhitelisted[account], "Address not whitelisted.");
        isWhitelisted[account] = false;
        emit Unwhitelisted(account);
    }
}

 

pragma solidity 0.5.4;















 
contract Rewards is IRewards, IRewardsUpdatable, RewarderRole, Pausable, Ownable, ReentrancyGuard, Whitelistable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using SignedSafeMath for int;

    IERC1594Capped private rewardableToken;  
    IERC20 private rewardsToken;  
    address private rewardsNotifier;  

    bool public isRunning = true;
    uint public maxShares;  
    uint public totalRewards;  
    uint public totalDepositedRewards;  
    uint public totalClaimedRewards;  
    mapping(address => int) private _dampings;  
    mapping(address => uint) public claimedRewards;  

    event Deposited(address indexed from, uint amount);
    event Withdrawn(address indexed from, uint amount);
    event Reclaimed(uint amount);
    event NotifierUpdated(address implementation);

    constructor(IERC1594Capped _rewardableToken, IERC20 _rewardsToken) public {
        uint _cap = _rewardableToken.cap();
        require(_cap != 0, "Shares token cap must be non-zero.");
        maxShares = _cap;
        rewardableToken = _rewardableToken;
        rewardsToken = _rewardsToken;
        rewardsNotifier = address(_rewardableToken);
    }

        
    modifier onlyRewardsNotifier() {
        require(msg.sender == rewardsNotifier, "Can only be called by the rewards notifier contract.");
        _;
    }

     
    modifier whenRunning() {
        require(isRunning, "Rewards contract has stopped running.");
        _;
    }

    function () external payable {  
        require(msg.value == 0, "Received non-zero msg.value.");
        withdraw();  
    }

     
    function deposit(uint _amount) external onlyRewarder whenRunning whenNotPaused {
        require(_amount != 0, "Deposit amount must non-zero.");
        totalDepositedRewards = totalDepositedRewards.add(_amount);
        totalRewards = totalRewards.add(_amount);
        address from = msg.sender;
        emit Deposited(from, _amount);

        rewardsToken.safeTransferFrom(msg.sender, address(this), _amount);  
    }

     
    function setRewardsNotifier(address _notifier) external onlyOwner {
        require(address(_notifier) != address(0), "Rewards address must not be a zero address.");
        require(Address.isContract(address(_notifier)), "Address must point to a contract.");
        rewardsNotifier = _notifier;
        emit NotifierUpdated(_notifier);
    }

     
    function updateOnTransfer(address _from, address _to, uint _value) external onlyRewardsNotifier nonReentrant returns (bool) {
        int fromUserShareChange = int(_value);  
        int fromDampingChange = _dampingChange(totalShares(), totalRewards, fromUserShareChange);

        int toUserShareChange = int(_value).mul(-1);  
        int toDampingChange = _dampingChange(totalShares(), totalRewards, toUserShareChange);

        assert((fromDampingChange.add(toDampingChange)) == 0);

        _dampings[_from] = damping(_from).add(fromDampingChange);
        _dampings[_to] = damping(_to).add(toDampingChange);
        return true;
    }

     
    function updateOnBurn(address _account, uint _value) external onlyRewardsNotifier nonReentrant returns (bool) { 
        uint totalSharesBeforeBurn = totalShares().add(_value);  
        uint redeemableRewards = _value.mul(totalRewards).div(totalSharesBeforeBurn);  
        totalRewards = totalRewards.sub(redeemableRewards);  
        _dampings[_account] = damping(_account).add(int(redeemableRewards));  
        return true;
    }

     
    function reclaimRewards() external onlyOwner {
        uint256 balance = rewardsToken.balanceOf(address(this));
        isRunning = false;
        rewardsToken.safeTransfer(owner(), balance);
        emit Reclaimed(balance);
    }

    
    function withdraw() public whenRunning whenNotPaused onlyWhitelisted(msg.sender) nonReentrant {
        address payee = msg.sender;
        uint unclaimedReward = unclaimedRewards(payee);
        require(unclaimedReward > 0, "Unclaimed reward must be non-zero to withdraw.");
        require(supply() >= unclaimedReward, "Rewards contract must have sufficient PAY to disburse.");

        claimedRewards[payee] = claimedRewards[payee].add(unclaimedReward);  
        totalClaimedRewards = totalClaimedRewards.add(unclaimedReward);
        emit Withdrawn(payee, unclaimedReward);

         
        rewardsToken.safeTransfer(payee, unclaimedReward);  
    }

     
    function supply() public view returns (uint) {
        return rewardsToken.balanceOf(address(this));
    }

     
    function totalShares() public view returns (uint) {
        uint totalRedeemed = rewardableToken.totalRedeemed();
        return maxShares.sub(totalRedeemed);
    }

     
    function unclaimedRewards(address _payee) public view returns(uint) {
        require(_payee != address(0), "Payee must not be a zero address.");
        uint totalUserReward = totalUserRewards(_payee);
        if (totalUserReward == uint(0)) {
            return 0;
        }

        uint unclaimedReward = totalUserReward.sub(claimedRewards[_payee]);
        return unclaimedReward;
    }

     
    function totalUserRewards(address _payee) internal view returns (uint) {
        require(_payee != address(0), "Payee must not be a zero address.");
        uint userShares = rewardableToken.balanceOf(_payee);  
        int userDamping = damping(_payee);
        uint result = _totalUserRewards(totalShares(), totalRewards, userShares, userDamping);
        return result;
    }    

     
    function _dampingChange(
        uint _totalShares,
        uint _totalRewards,
        int _sharesChange
    ) internal pure returns (int) {
        return int(_totalRewards).mul(_sharesChange).div(int(_totalShares));
    }

     
    function _totalUserRewards(
        uint _totalShares,
        uint _totalRewards,
        uint _userShares,
        int _userDamping
    ) internal pure returns (uint) {
        uint maxUserReward = _userShares.mul(_totalRewards).div(_totalShares);
        int userReward = int(maxUserReward).add(_userDamping);
        uint result = (userReward > 0 ? uint(userReward) : 0);
        return result;
    }

    function damping(address account) internal view returns (int) {
        return _dampings[account];
    }
}