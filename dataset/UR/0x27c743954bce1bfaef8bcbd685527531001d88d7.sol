 

 
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
 
library SafeMath {
     
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

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        require(account != address(this), "Roles: account is the contract address");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        require(account != address(this), "Roles: account is the contract address");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
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

 
contract Ownable {
    address internal _owner;

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

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(newOwner != address(this), "Ownable: new owner is the contract address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private constant MAX_UINT = 2**256 - 1;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
         
         
         
         
         
         
        require((value == 0) || (_allowances[msg.sender][spender] == 0),
            "ERC20: must change allowance to 0 before changing to a different value");

        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        uint256 currentAllowance = _allowances[from][msg.sender];
        if (currentAllowance < MAX_UINT) {
            _approve(from, msg.sender, currentAllowance.sub(value));
        }
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(addedValue > 0, "ERC20: addedValue value can't be 0");
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(subtractedValue > 0, "ERC20: decreaseAllowance value can't be 0");
        require(_allowances[msg.sender][spender] > 0, "ERC20: current allowance must not be 0");
        uint256 allowanceToSet;
        if (subtractedValue < _allowances[msg.sender][spender]) {
            allowanceToSet = _allowances[msg.sender][spender].sub(subtractedValue);
        } else {
            allowanceToSet = 0;
        }
        _approve(msg.sender, spender, allowanceToSet);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(to != address(this), "ERC20: transfer to the contract address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(account != address(this), "ERC20: mint to the contract address");
        require(value != 0, "ERC20: mint value must be positive");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account != address(this), "ERC20: burn from the contract address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(value));
    }
}

contract PauserRole {
    using SafeMath for uint256;
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;
    uint256 internal _pausersCount;

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

    function removePauser(address account) public onlyPauser {
        _removePauser(account);
    }

    function _addPauser(address account) internal {
        _pausersCount = _pausersCount.add(1);
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        require(_pausersCount > 1, "PauserRole: there should always be at least one pauser left");
        _pausersCount = _pausersCount.sub(1);
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

 
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 
contract UpgradeAgent {
     
    function isUpgradeAgent() external pure returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) external;
}

 
contract SafeUpgradeableTokenERC20 is ERC20Pausable, ERC20Detailed, Ownable, UpgradeAgent {
    using SafeMath for uint256;

     
    address public upgradeMaster;

     
    UpgradeAgent public upgradeAgent;

     
    uint256 public totalUpgraded;

     
    address public previousToken;

     
    string public version = "1.0";

     
    enum UpgradeState {WaitingForAgent, ReadyToUpgrade, Upgrading, UpgradeFinished}

     
    event LogUpgrade(address indexed from, address indexed to, uint256 value);

     
    event LogUpgradeAgentSet(address indexed agent);

    constructor (address _previousToken, string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply)
        public
        ERC20Detailed(_name, _symbol, _decimals)
    {
        upgradeMaster = msg.sender;
        previousToken = _previousToken;
         
        if (_supply > 0) {
            _mint(msg.sender, _supply);
        }
    }

     
    modifier onlyUpgradeMaster() {
        require(msg.sender == upgradeMaster, "caller must be upgradeMaster");
        _;
    }

     
    modifier validateAddress(address input) {
        require(input != address(0), "invalid address, shouldnt be 0");
        require(input != address(this), "invalid address, shouldnt be current contract address");
        _;
    }

     
    function upgrade(uint256 value) external {
        UpgradeState state = getUpgradeState();
        require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading, "upgrade state does not allow upgrade");
        require(value != 0, "value must be non-zero");

         
        _burn(msg.sender, value);
        totalUpgraded = totalUpgraded.add(value);
        emit LogUpgrade(msg.sender, address(upgradeAgent), value);

         
        upgradeAgent.upgradeFrom(msg.sender, value);
    }
     
    function upgradeFrom(address _from, uint256 _value) external validateAddress(_from) {
        require(previousToken != address(0), "previousToken was not set");
        require(msg.sender == previousToken, "upgradeFrom should only be called by previousToken");
        _mint(_from, _value);
    }

     
    function setUpgradeAgent(UpgradeAgent newUpgradeAgent) external onlyUpgradeMaster validateAddress(address(newUpgradeAgent)) {
        require(getUpgradeState() != UpgradeState.Upgrading, "upgrade already started");

        upgradeAgent = newUpgradeAgent;
        emit LogUpgradeAgentSet(address(newUpgradeAgent));

         
        require(newUpgradeAgent.isUpgradeAgent(), "Bad interface");
    }

     
    function getUpgradeState() public view returns(UpgradeState) {
        if (address(upgradeAgent) == address(0)) {
            return UpgradeState.WaitingForAgent;
        } else if (totalUpgraded == 0) {
            return UpgradeState.ReadyToUpgrade;
        } else if (totalUpgraded < totalSupply()) {
            return UpgradeState.Upgrading;
        } else {
            return UpgradeState.UpgradeFinished;
        }
    }

     
    function setUpgradeMaster(address master) external onlyUpgradeMaster validateAddress(master) {
        upgradeMaster = master;
    }

     
    function recoverToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "no tokens to recover for received token type");
        SafeERC20.safeTransfer(_token, _owner, balance);
    }

     
    function reclaimContract(Ownable contractInst) external onlyOwner {
        contractInst.transferOwnership(_owner);
    }

     
    function tokenFallback(address from, uint256 value, bytes calldata data) external pure {
         
    function recoverEther() external onlyOwner {
        require(address(this).balance > 0, "no ether to recover");
        address(uint160(_owner)).transfer(address(this).balance);
    }
}