 

 

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

 

 
 
pragma solidity ^0.5.0;





contract ManagerRole is Ownable {
    using Roles for Roles.Role;
    using SafeMath for uint256;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private managers;
    uint256 private _numManager;

    constructor() internal {
        _addManager(msg.sender);
        _numManager = 1;
    }

     
    modifier onlyManager() {
        require(isManager(msg.sender), "The account is not a manager");
        _;
    }

     
     
    function addManagers(address[] calldata accounts) external onlyOwner {
        uint256 length = accounts.length;
        require(length <= 256, "too many accounts");
        for (uint256 i = 0; i < length; i++) {
            _addManager(accounts[i]);
        }
    }
    
     
    function removeManager(address account) external onlyOwner {
        _removeManager(account);
    }

     
    function isManager(address account) public view returns (bool) {
        return managers.has(account);
    }

     
    function numManager() public view returns (uint256) {
        return _numManager;
    }

     
    function addManager(address account) public onlyOwner {
        require(account != address(0), "account is zero");
        _addManager(account);
    }

     
    function renounceManager() public {
        require(_numManager >= 2, "Managers are fewer than 2");
        _removeManager(msg.sender);
    }

     
    function renounceOwnership() public onlyOwner {
        revert("Cannot renounce ownership");
    }

     
    function _addManager(address account) internal {
        _numManager = _numManager.add(1);
        managers.add(account);
        emit ManagerAdded(account);
    }

     
    function _removeManager(address account) internal {
        _numManager = _numManager.sub(1);
        managers.remove(account);
        emit ManagerRemoved(account);
    }
}

 

 
 
pragma solidity ^0.5.0;



contract PausableManager is ManagerRole {

    event BePaused(address manager);
    event BeUnpaused(address manager);

    bool private _paused;    

    constructor() internal {
        _paused = false;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "not paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "paused");
        _;
    }

     
    function paused() public view returns(bool) {
        return _paused;
    }

     
    function pause() public onlyManager whenNotPaused {
        _paused = true;
        emit BePaused(msg.sender);
    }

     
    function unpause() public onlyManager whenPaused {
        _paused = false;
        emit BeUnpaused(msg.sender);
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

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
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

 

 
 
pragma solidity ^0.5.0;





contract Reclaimable is Ownable {
    using SafeERC20 for IERC20;

     
    function reclaimToken(IERC20 tokenToBeRecovered) external onlyOwner {
        uint256 balance = tokenToBeRecovered.balanceOf(address(this));
        tokenToBeRecovered.safeTransfer(owner(), balance);
    }
}

 

 
 
pragma solidity ^0.5.0;


contract CounterGuard {
     
    modifier onlyOnce(bool criterion) {
        require(criterion == false, "Already been set");
        _;
    }
}

 

 
 
pragma solidity ^0.5.0;


contract ValidAddress {
     
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Not a valid address");
        _;
    }

     
    modifier isSenderNot(address _address) {
        require(_address != msg.sender, "Address is the same as the sender");
        _;
    }

     
    modifier isSender(address _address) {
        require(_address == msg.sender, "Address is different from the sender");
        _;
    }
}

 

 
 
pragma solidity ^0.5.0;


contract IVault {
     
    function receiveFor(address beneficiary, uint256 value) public;

     
    function updateReleaseTime(uint256 roundEndTime) public;
}

 

 
 
pragma solidity ^0.5.0;









contract BasicVault is IVault, Reclaimable, CounterGuard, ValidAddress, PausableManager {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

     
    IERC20 private _token;
     
     
    mapping(address=>uint256) private _balances;
     
    uint256 private _totalBalance;
     
    uint256 private _updateTime;
     
    uint256 private _releaseTime;
     
    bool private _knownReleaseTime;
    address private _crowdsale;

    event Received(address indexed owner, uint256 value);
    event Released(address indexed owner, uint256 value);
    event ReleaseTimeUpdated(address indexed account, uint256 updateTime, uint256 releaseTime);

     
    modifier readyToRelease {
        require(_knownReleaseTime && (block.timestamp >= _releaseTime), "Not ready to release");
        _;
    }

     
    modifier saleNotEnd {
        require(!_knownReleaseTime || (block.timestamp < _updateTime), "Cannot modifiy anymore");
        _;
    }

     
    modifier onlyCrowdsale {
        require(msg.sender == _crowdsale, "The caller is not the crowdsale contract");
        _;
    }
    
    
     
     
    constructor(
        IERC20 token,
        address crowdsale,
        bool knownWhenToRelease,
        uint256 updateTime,
        uint256 releaseTime
    )
        public
        onlyValidAddress(crowdsale)
        isSenderNot(crowdsale)
    {
        _token = token;
        _crowdsale = crowdsale;
        _knownReleaseTime = knownWhenToRelease;
        _updateTime = updateTime;
        _releaseTime = releaseTime;
    }
     

     
    function reclaimToken(IERC20 tokenToBeRecovered) external onlyOwner {
         
        uint256 balance = tokenToBeRecovered.balanceOf(address(this));
        if (tokenToBeRecovered == _token) {
            tokenToBeRecovered.safeTransfer(owner(), balance.sub(_totalBalance));
        } else {
            tokenToBeRecovered.safeTransfer(owner(), balance);
        }
    }

     
    function balanceOf(address beneficiary) public view returns (uint256) {
        return _balances[beneficiary];
    }

     
    function totalBalance() public view returns(uint256) {
        return _totalBalance;
    }

     
    function token() public view returns(IERC20) {
        return _token;
    }

     
    function crowdsale() public view returns(address) {
        return _crowdsale;
    }

     
    function releaseTime() public view returns(uint256) {
        return _releaseTime;
    }

     
    function updateTime() public view returns(uint256) {
        return _updateTime;
    }

     
    function knownReleaseTime() public view returns(bool) {
        return _knownReleaseTime;
    }

     
    function receiveFor(address beneficiary, uint256 value)
        public 
        saleNotEnd
        onlyManager
    {
        _receiveFor(beneficiary, value);
    }

     
    function release() public readyToRelease {
        _releaseFor(msg.sender, _balances[msg.sender]);
    }

     
    function releaseFor(address account) public readyToRelease {
        _releaseFor(account, _balances[account]);
    }

     
      
    function updateReleaseTime(uint256 newTime) public {
        revert("cannot update release time");
    }

     
    function _receiveFor(address account, uint256 value) internal {
        _balances[account] = _balances[account].add(value);
        _totalBalance = _totalBalance.add(value);
        emit Received(account, value);
    }

      
    function _releaseFor(address account, uint256 amount) internal {
        require(amount > 0 && _balances[account] >= amount, "the account does not have enough amount");

        _balances[account] = _balances[account].sub(amount);
        _totalBalance = _totalBalance.sub(amount);

        _token.safeTransfer(account, amount);
        emit Released(account, amount);
    }

     
    function _updateReleaseTime(uint256 newUpdateTime, uint256 newReleaseTime) 
        internal
        onlyOnce(_knownReleaseTime) 
    {
        _knownReleaseTime = true;
        _updateTime = newUpdateTime;
        _releaseTime = newReleaseTime;
        emit ReleaseTimeUpdated(msg.sender, newUpdateTime, newReleaseTime);
    }

     
    function roleSetup(address newOwner) internal {
        _removeManager(msg.sender);
        transferOwnership(newOwner);
    }
}

 

 
 
pragma solidity ^0.5.0;


contract IIvoCrowdsale {
     
    function startingTime() public view returns(uint256);
}

 

 
 
pragma solidity ^0.5.0;






contract SaftVault is BasicVault {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

     
    uint256 private constant ALLOCATION = 22500000 ether;
    uint256 private constant RELEASE_PERIOD = 180 days;  

     
     
    constructor(
        IERC20 token,
        address crowdsale,
        uint256 updateTime,
        address newOwner
    )
        public
        BasicVault(token, crowdsale, true, updateTime, updateTime.add(RELEASE_PERIOD))
    {
        require(updateTime == IIvoCrowdsale(crowdsale).startingTime(), "Update time not correct");
        roleSetup(newOwner);
    }
     

     
    modifier capNotReached(uint256 additional) {
        require(totalBalance().add(additional) <= ALLOCATION, "exceed the maximum allocation");
        _;
    }
    
     
     
    function batchReceiveFor(address[] calldata beneficiaries, uint256[] calldata amounts)
        external
    {
        uint256 length = amounts.length;
        require(beneficiaries.length == length, "length !=");
        require(length <= 256, "To long, please consider shorten the array");
        for (uint256 i = 0; i < length; i++) {
            receiveFor(beneficiaries[i], amounts[i]);
        }
    }

     
    function reclaimToken(IERC20 tokenToBeRecovered) external onlyOwner {
         
        uint256 balance = tokenToBeRecovered.balanceOf(address(this));
        if (tokenToBeRecovered == this.token()) {
            if (block.timestamp <= this.releaseTime()) {
                tokenToBeRecovered.safeTransfer(owner(), balance.sub(ALLOCATION));
            } else {
                tokenToBeRecovered.safeTransfer(owner(), balance.sub(this.totalBalance()));
            }
        } else {
            tokenToBeRecovered.safeTransfer(owner(), balance);
        }
    }

     
    function receiveFor(address beneficiary, uint256 value)
        public 
        capNotReached(value)
    {
        require((block.timestamp < this.releaseTime()), "Cannot modifiy anymore");
        super.receiveFor(beneficiary, value);
    }

     
    function roleSetup(address newOwner) internal {
        addManager(newOwner);
        super.roleSetup(newOwner);
    }
}