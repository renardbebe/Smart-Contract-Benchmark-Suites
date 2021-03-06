 

 

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

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
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


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

     
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

     
    function cap() public view returns (uint256) {
        return _cap;
    }

     
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

 

pragma solidity ^0.5.0;

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 

 
 
pragma solidity ^0.5.0;




library Snapshots {
    using Math for uint256;
    using SafeMath for uint256;

     
    struct Snapshot {
        uint256 fromBlock;
        uint256 value;
    }

    struct SnapshotList {
        Snapshot[] history;
    }

     
    function createSnapshot(SnapshotList storage item, uint256 _value) internal {
        uint256 length = item.history.length;
        if (length == 0 || (item.history[length.sub(1)].fromBlock < block.number)) {
            item.history.push(Snapshot(block.number, _value));
        } else {
             
            item.history[length.sub(1)].value = _value;
        }
    }

     
    function findBlockIndex(
        SnapshotList storage item, 
        uint256 blockNumber
    ) 
        internal
        view 
        returns (uint256)
    {
         
        uint256 length = item.history.length;

         
        if (item.history[length.sub(1)].fromBlock <= blockNumber) {
            return length.sub(1);
        } else {
             
            uint256 low = 0;
            uint256 high = length.sub(1);

            while (low < high.sub(1)) {
                uint256 mid = Math.average(low, high);
                 
                if (item.history[mid].fromBlock <= blockNumber) {
                    low = mid;
                } else {
                    high = mid;
                }
            }
            return low;
        }   
    }

     
    function getValueAt(
        SnapshotList storage item, 
        uint256 blockNumber
    )
        internal
        view
        returns (uint256)
    {
        if (item.history.length == 0 || blockNumber < item.history[0].fromBlock) {
            return 0;
        } else {
            uint256 index = findBlockIndex(item, blockNumber);
            return item.history[index].value;
        }
    }
}

 

 
 
pragma solidity ^0.5.0;


contract IERC20Snapshot {
     
    function totalSupplyAt(uint256 blockNumber) public view returns (uint256);

     
    function balanceOfAt(address owner, uint256 blockNumber) public view returns (uint256);
}

 

 
 
pragma solidity ^0.5.0;





contract ERC20Snapshot is ERC20, IERC20Snapshot {
    using Snapshots for Snapshots.SnapshotList;

    mapping(address => Snapshots.SnapshotList) private _snapshotBalances; 
    Snapshots.SnapshotList private _snapshotTotalSupply;   

    event AccountSnapshotCreated(address indexed account, uint256 indexed blockNumber, uint256 value);
    event TotalSupplySnapshotCreated(uint256 indexed blockNumber, uint256 value);

     
    function totalSupplyAt(uint256 blockNumber) public view returns (uint256) {
        return _snapshotTotalSupply.getValueAt(blockNumber);
    }

     
    function balanceOfAt(address owner, uint256 blockNumber) 
        public 
        view 
        returns (uint256) 
    {
        return _snapshotBalances[owner].getValueAt(blockNumber);
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        super._transfer(from, to, value);
        _snapshotBalances[from].createSnapshot(balanceOf(from));
        _snapshotBalances[to].createSnapshot(balanceOf(to));
        emit AccountSnapshotCreated(from, block.number, balanceOf(from));
        emit AccountSnapshotCreated(to, block.number, balanceOf(to));
    }

     
    function _mint(address account, uint256 value) internal {
        super._mint(account, value);
        _snapshotBalances[account].createSnapshot(balanceOf(account));
        _snapshotTotalSupply.createSnapshot(totalSupply());
        emit AccountSnapshotCreated(account, block.number, balanceOf(account));
        emit TotalSupplySnapshotCreated(block.number, totalSupply());
    }

     
    function _burn(address account, uint256 value) internal {
        super._burn(account, value);
        _snapshotBalances[account].createSnapshot(balanceOf(account));
        _snapshotTotalSupply.createSnapshot(totalSupply());
        emit AccountSnapshotCreated(account, block.number, balanceOf(account));
        emit TotalSupplySnapshotCreated(block.number, totalSupply());
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


contract IVault {
     
    function receiveFor(address beneficiary, uint256 value) public;

     
    function updateReleaseTime(uint256 roundEndTime) public;
}

 

 
 
pragma solidity ^0.5.0;


contract CounterGuard {
     
    modifier onlyOnce(bool criterion) {
        require(criterion == false, "Already been set");
        _;
    }
}

 

 
 
pragma solidity ^0.5.0;










contract IvoToken is CounterGuard, Reclaimable, ERC20Detailed,
    ERC20Snapshot, ERC20Capped, ERC20Burnable, PausableManager {
     
    uint256 private constant SAFT_ALLOCATION = 22500000 ether;
    uint256 private constant RESERVE_ALLOCATION = 10000000 ether;
    uint256 private constant ADVISOR_ALLOCATION = 1500000 ether;
    uint256 private constant TEAM_ALLOCATION = 13500000 ether;

    address private _saftVaultAddress;
    address private _reserveVaultAddress;
    address private _advisorVestingAddress;
    address private _teamVestingAddress;
    mapping(address=>bool) private _listOfVaults;
    bool private _setRole;

     
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap
    )
        public
        ERC20Detailed(name, symbol, decimals)
        ERC20Capped(cap) {
            pause();
        }

     
    function transfer(address to, uint256 value)
        public
        returns (bool)
    {
        require(!this.paused() || _listOfVaults[msg.sender], "The token is paused and you are not a valid vault/vesting contract");
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

     
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

     
    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

     
    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

     
    function roleSetup(
        address newOwner,
        address crowdsaleContractAddress,
        IVault saftVaultAddress,
        IVault privateVaultAddress,
        IVault presaleVaultAddress,
        IVault advisorVestingAddress,
        IVault teamVestingAddress,
        IVault reserveVaultAddress
    )
        public
        onlyOwner
        onlyOnce(_setRole)
    {
        _setRole = true;

         
        _saftVaultAddress = address(saftVaultAddress);
        _reserveVaultAddress = address(reserveVaultAddress);
        _advisorVestingAddress = address(advisorVestingAddress);
        _teamVestingAddress = address(teamVestingAddress);
        _listOfVaults[_saftVaultAddress] = true;
        _listOfVaults[address(privateVaultAddress)] = true;
        _listOfVaults[address(presaleVaultAddress)] = true;
        _listOfVaults[_advisorVestingAddress] = true;
        _listOfVaults[_teamVestingAddress] = true;

         
         
         
        mint(_saftVaultAddress, SAFT_ALLOCATION);
        mint(_reserveVaultAddress, RESERVE_ALLOCATION);
        mint(_advisorVestingAddress, ADVISOR_ALLOCATION);
        mint(_teamVestingAddress, TEAM_ALLOCATION);

        addManager(newOwner);
        addManager(crowdsaleContractAddress);
        addMinter(crowdsaleContractAddress);
        _removeManager(msg.sender);
        _removeMinter(msg.sender);
        transferOwnership(newOwner);
    }
}