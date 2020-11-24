 

 

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

 

 
 
pragma solidity ^0.5.7;


contract Utils {
     
     
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Invalid address");
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

     
    modifier onlyOnce(bool criterion) {
        require(criterion == false, "Already been set");
        _;
        criterion = true;
    }
}

 

pragma solidity ^0.5.7;




contract Managed is Utils, Ownable {
     
    mapping(address => bool) public isManager;
    
     
    event ChangedManager(address indexed manager, bool active);

     
    modifier onlyManager() {
        require(isManager[msg.sender], "not manager");
        _;
    }
    
     
    function setManager(address manager, bool active) public onlyOwner onlyValidAddress(manager) {
        isManager[manager] = active;
        emit ChangedManager(manager, active);
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



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 

pragma solidity ^0.5.2;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
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

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

 

pragma solidity ^0.5.2;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
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

 

pragma solidity ^0.5.2;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
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

 

 
 
pragma solidity ^0.5.7;





contract Reclaimable is Ownable {
    using SafeERC20 for IERC20;

     
    function reclaimToken(IERC20 tokenToBeRecovered) external onlyOwner {
        uint256 balance = tokenToBeRecovered.balanceOf(address(this));
        tokenToBeRecovered.safeTransfer(msg.sender, balance);
    }
}

 

pragma solidity ^0.5.2;


 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 

pragma solidity ^0.5.2;



 
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

 

pragma solidity ^0.5.2;

 
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

 

 
pragma solidity ^0.5.7;




library Snapshots {
    using Math for uint256;
    using SafeMath for uint256;

     
    struct Snapshot {
        uint256 timestamp;
        uint256 value;
    }

    struct SnapshotList {
        Snapshot[] history;
    }

     
    function createSnapshot(SnapshotList storage item, uint256 _value) internal {
        uint256 length = item.history.length;
        if (length == 0 || (item.history[length.sub(1)].timestamp < block.timestamp)) {
            item.history.push(Snapshot(block.timestamp, _value));
        } else {
             
            item.history[length.sub(1)].value = _value;
        }
    }

     
    function findBlockIndex(
        SnapshotList storage item, 
        uint256 timestamp
    ) 
        internal
        view 
        returns (uint256)
    {
         
        uint256 length = item.history.length;

         
        if (item.history[length.sub(1)].timestamp <= timestamp) {
            return length.sub(1);
        } else {
             
            uint256 low = 0;
            uint256 high = length.sub(1);

            while (low < high.sub(1)) {
                uint256 mid = Math.average(low, high);
                 
                if (item.history[mid].timestamp <= timestamp) {
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
        uint256 timestamp
    )
        internal
        view
        returns (uint256)
    {
        if (item.history.length == 0 || timestamp < item.history[0].timestamp) {
            return 0;
        } else {
            uint256 index = findBlockIndex(item, timestamp);
            return item.history[index].value;
        }
    }
}

 

 
pragma solidity ^0.5.7;  




contract ERC20Snapshot is ERC20 {
    using Snapshots for Snapshots.SnapshotList;

    mapping(address => Snapshots.SnapshotList) private _snapshotBalances; 
    Snapshots.SnapshotList private _snapshotTotalSupply;   

    event CreatedAccountSnapshot(address indexed account, uint256 indexed timestamp, uint256 value);
    event CreatedTotalSupplySnapshot(uint256 indexed timestamp, uint256 value);

     
    function totalSupplyAt(uint256 timestamp) public view returns (uint256) {
        return _snapshotTotalSupply.getValueAt(timestamp);
    }

     
    function balanceOfAt(address owner, uint256 timestamp) 
        public 
        view 
        returns (uint256) {
            return _snapshotBalances[owner].getValueAt(timestamp);
        }

     
    function _transfer(address from, address to, uint256 value) internal {
        super._transfer(from, to, value);  

        _createAccountSnapshot(from, balanceOf(from));
        _createAccountSnapshot(to, balanceOf(to));
    }

     
    function _mint(address account, uint256 value) internal {
        super._mint(account, value);
        
        _createAccountSnapshot(account, balanceOf(account));
        _createTotalSupplySnapshot(account, totalSupplyAt(block.timestamp).add(value));
    }

     
    function _burn(address account, uint256 value) internal {
        super._burn(account, value);

        _createAccountSnapshot(account, balanceOf(account));
        _createTotalSupplySnapshot(account, totalSupplyAt(block.timestamp).sub(value));
    }

     
    function _createTotalSupplySnapshot(address account, uint256 amount) internal {
        _snapshotTotalSupply.createSnapshot(amount);

        emit CreatedTotalSupplySnapshot(block.timestamp, amount);
    }

     
    function _createAccountSnapshot(address account, uint256 amount) internal {
        _snapshotBalances[account].createSnapshot(amount);

        emit CreatedAccountSnapshot(account, block.timestamp, amount);
    }

    function _precheckSnapshot() internal {
         
         
    }
}

 

 
pragma solidity ^0.5.7;




 
contract WhitelistedSnapshot is ERC20Snapshot, WhitelistedRole {
     
    function addWhitelisted(address account) public {
        super.addWhitelisted(account);

        uint256 balance = balanceOf(account);
        _createAccountSnapshot(account, balance);

        uint256 newSupplyValue = totalSupplyAt(now).add(balance);
        _createTotalSupplySnapshot(account, newSupplyValue);
    }
    
     
    function removeWhitelisted(address account) public {
        super.removeWhitelisted(account);

        _createAccountSnapshot(account, 0);

        uint256 balance = balanceOf(account);
        uint256 newSupplyValue = totalSupplyAt(now).sub(balance);
        _createTotalSupplySnapshot(account, newSupplyValue);
    }

     
    function _transfer(address from, address to, uint256 value) internal {
         
        super._transfer(from, to, value);

         
         
         
        (bool isWhitelistedHetero, bool isAdding) = _isWhitelistedHeterogeneousTransfer(from, to);

        if (isWhitelistedHetero) {  
            uint256 newSupplyValue = totalSupplyAt(block.timestamp);
            address account;

            if (isAdding) { 
                newSupplyValue = newSupplyValue.add(value);
                account = to;
            } else { 
                newSupplyValue = newSupplyValue.sub(value);
                account = from;
            }

            _createTotalSupplySnapshot(account, newSupplyValue);
        }
    }

     
    function _isWhitelistedHeterogeneousTransfer(address from, address to) 
        internal 
        view 
        returns (bool isHetero, bool isAdding) {
            bool _isToWhitelisted = isWhitelisted(to);
            bool _isFromWhitelisted = isWhitelisted(from);

            if (!_isFromWhitelisted && _isToWhitelisted) {
                isHetero = true;    
                isAdding = true;     
            } else if (_isFromWhitelisted && !_isToWhitelisted) {
                isHetero = true;    
            }
        }

     
    function _createTotalSupplySnapshot(address account, uint256 amount) internal {
        if (isWhitelisted(account)) {
            super._createTotalSupplySnapshot(account, amount);
        }
    }

     
    function _createAccountSnapshot(address account, uint256 amount) internal {
        if (isWhitelisted(account)) {
            super._createAccountSnapshot(account, amount);
        }
    }

    function _precheckSnapshot() internal onlyWhitelisted {}
}

 

 
pragma solidity ^0.5.7;


contract BaseOptedIn {
     
    mapping(address => uint256) public optedOutAddresses;  

     
    event OptedOut(address indexed account);
    event OptedIn(address indexed account);

    modifier onlyOptedBool(bool isIn) {  
        if (isIn) {
            require(optedOutAddresses[msg.sender] > 0, "already opted in");
        } else {
            require(optedOutAddresses[msg.sender] == 0, "already opted out");
        }
        _;
    }

     
    function optOut() public onlyOptedBool(false) {
        optedOutAddresses[msg.sender] = block.timestamp;
        
        emit OptedOut(msg.sender);
    }

     
    function optIn() public onlyOptedBool(true) {
        optedOutAddresses[msg.sender] = 0;

        emit OptedIn(msg.sender);
    }

     
    function isOptedIn(address account) public view returns (bool optedIn) {
        if (optedOutAddresses[account] == 0) {
            optedIn = true;
        }
    }
}

 

 
pragma solidity ^0.5.7;




 
contract OptedInSnapshot is ERC20Snapshot, BaseOptedIn {
     
    function optIn() public {
         
        super._precheckSnapshot();
        super.optIn();

        address account = msg.sender;
        uint256 balance = balanceOf(account);
        _createAccountSnapshot(account, balance);

        _createTotalSupplySnapshot(account, totalSupplyAt(now).add(balance));
    }

     
    function optOut() public {
         
        super._precheckSnapshot();
        super.optOut();

        address account = msg.sender;
        _createAccountSnapshot(account, 0);

        _createTotalSupplySnapshot(account, totalSupplyAt(now).sub(balanceOf(account)));
    }

     
    function _transfer(address from, address to, uint256 value) internal {
         
        super._transfer(from, to, value);

         
         
         
        (bool isOptedHetero, bool isAdding) = _isOptedHeterogeneousTransfer(from, to);

        if (isOptedHetero) {  
            uint256 newSupplyValue = totalSupplyAt(block.timestamp);
            address account;

            if (isAdding) {
                newSupplyValue = newSupplyValue.add(value);
                account = to;
            } else {
                newSupplyValue = newSupplyValue.sub(value);
                account = from;
            }

            _createTotalSupplySnapshot(account, newSupplyValue);
        }
    }

     
    function _isOptedHeterogeneousTransfer(address from, address to) 
        internal 
        view 
        returns (bool isOptedHetero, bool isOptedInIncrease) {
            bool _isToOptedIn = isOptedIn(to);
            bool _isFromOptedIn = isOptedIn(from);
            
            if (!_isFromOptedIn && _isToOptedIn) {
                isOptedHetero = true;    
                isOptedInIncrease = true;     
            } else if (_isFromOptedIn && !_isToOptedIn) {
                isOptedHetero = true; 
            }
        }

     
    function _createTotalSupplySnapshot(address account, uint256 amount) internal {
        if (isOptedIn(account)) {
            super._createTotalSupplySnapshot(account, amount);
        }
    }

     
    function _createAccountSnapshot(address account, uint256 amount) internal {
        if (isOptedIn(account)) {
            super._createAccountSnapshot(account, amount);
        }
    }
}

 

 
pragma solidity ^0.5.7;  




 
contract ERC20ForceTransfer is Ownable, ERC20 {
    event ForcedTransfer(address indexed confiscatee, uint256 amount, address indexed receiver);

     
    function forceTransfer(address confiscatee, address receiver) external onlyOwner {
        uint256 balance = balanceOf(confiscatee);
        _transfer(confiscatee, receiver, balance);

        emit ForcedTransfer(confiscatee, balance, receiver);
    }

     
    function forceTransfer(address confiscatee, address receiver, uint256 amount) external onlyOwner {
        _transfer(confiscatee, receiver, amount);

        emit ForcedTransfer(confiscatee, amount, receiver);
    }
}

 

 
pragma solidity ^0.5.7;




 
contract BaseDocumentRegistry is Ownable {
    using SafeMath for uint256;
    
    struct HashedDocument {
        uint256 timestamp;
        string documentUri;
    }

    HashedDocument[] private _documents;

    event AddedLogDocumented(string documentUri, uint256 documentIndex);

     
    function addDocument(string calldata documentUri) external onlyOwner {
        require(bytes(documentUri).length > 0, "invalid documentUri");

        HashedDocument memory document = HashedDocument({
            timestamp: block.timestamp,
            documentUri: documentUri
        });

        _documents.push(document);

        emit AddedLogDocumented(documentUri, _documents.length.sub(1));
    }

     
    function currentDocument() 
        public 
        view 
        returns (uint256 timestamp, string memory documentUri, uint256 index) {
            require(_documents.length > 0, "no documents exist");
            uint256 last = _documents.length.sub(1);

            HashedDocument storage document = _documents[last];
            return (document.timestamp, document.documentUri, last);
        }

     
    function getDocument(uint256 documentIndex) 
        public 
        view
        returns (uint256 timestamp, string memory documentUri, uint256 index) {
            require(documentIndex < _documents.length, "invalid index");

            HashedDocument storage document = _documents[documentIndex];
            return (document.timestamp, document.documentUri, documentIndex);
        }

     
    function documentCount() public view returns (uint256) {
        return _documents.length;
    }
}

 

 
pragma solidity ^0.5.7;












contract ExampleSecurityToken is 
    Utils, 
    Reclaimable, 
    ERC20Detailed, 
    WhitelistedSnapshot, 
    OptedInSnapshot,
    ERC20Mintable, 
    ERC20Burnable, 
    ERC20Pausable,
    ERC20ForceTransfer,
    BaseDocumentRegistry {
    
    bool private _isSetup;

     
    constructor(string memory name, string memory symbol, address initialAccount, uint256 initialBalance) 
        public
        ERC20Detailed(name, symbol, 0) {
             
            _mint(initialAccount, initialBalance);
            roleSetup(initialAccount);
        }

     
    function roleSetup(address board) internal onlyOwner onlyOnce(_isSetup) {   
        addMinter(board);
        addPauser(board);
        _addWhitelistAdmin(board);
    }

     
    function _burn(address account, uint256 value) internal onlyOwner {
        super._burn(account, value);
    } 
}

 

 
pragma solidity ^0.5.7;








contract Dividends is Utils, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public _wallet;   
    
    struct Dividend {
        uint256 recordDate;      
        uint256 claimPeriod;     
        address payoutToken;     
        uint256 payoutAmount;    
        uint256 claimedAmount;   
        uint256 totalSupply;     
        bool reclaimed;           
        mapping(address => bool) claimed;  
    }

    address public _token;
    Dividend[] public dividends;

     
    mapping(address => uint256) public totalBalance;

     
    event DepositedDividend(uint256 indexed dividendIndex, address indexed payoutToken, uint256 payoutAmount, uint256 recordDate, uint256 claimPeriod);
    event ReclaimedDividend(uint256 indexed dividendIndex, address indexed claimer, uint256 claimedAmount);
    event RecycledDividend(uint256 indexed dividendIndex, uint256 timestamp, uint256 recycledAmount);

     
    modifier validDividendIndex(uint256 _dividendIndex) {
        require(_dividendIndex < dividends.length, "Such dividend does not exist");
        _;
    } 

     
     
    constructor(address stoToken, address wallet) public onlyValidAddress(stoToken) onlyValidAddress(wallet) {
        _token = stoToken;
        _wallet = wallet;
        transferOwnership(wallet);
    }
     

     
    function depositDividend(address payoutToken, uint256 recordDate, uint256 claimPeriod, uint256 amount)
        public
        onlyOwner
        onlyValidAddress(payoutToken)
    {
        require(amount > 0, "invalid deposit amount");
        require(recordDate > 0, "invalid recordDate");
        require(claimPeriod > 0, "invalid claimPeriod");

        IERC20(payoutToken).safeTransferFrom(msg.sender, address(this), amount);      
        totalBalance[payoutToken] = totalBalance[payoutToken].add(amount);  

        dividends.push(
            Dividend(
                recordDate,
                claimPeriod,
                payoutToken,
                amount,
                0,
                ERC20Snapshot(_token).totalSupplyAt(block.timestamp),  
                false
            )
        );

        emit DepositedDividend((dividends.length).sub(1), payoutToken, amount, block.timestamp, claimPeriod);
    }

     
    function claimDividend(uint256 dividendIndex) 
        public 
        validDividendIndex(dividendIndex) 
    {
        Dividend storage dividend = dividends[dividendIndex];
        require(dividend.claimed[msg.sender] == false, "Dividend already claimed");
        require(dividend.reclaimed == false, "Dividend already reclaimed");
        require((dividend.recordDate).add(dividend.claimPeriod) >= block.timestamp, "No longer claimable");

        _claimDividend(dividendIndex, msg.sender);
    }

     
    function claimAllDividends(uint256 startingIndex) 
        public 
        validDividendIndex(startingIndex) 
    {
        for (uint256 i = startingIndex; i < dividends.length; i++) {
            Dividend storage dividend = dividends[i];

            if (dividend.claimed[msg.sender] == false 
                && (dividend.recordDate).add(dividend.claimPeriod) >= block.timestamp && dividend.reclaimed == false) {
                _claimDividend(i, msg.sender);
            }
        }
    }

     
    function reclaimDividend(uint256 dividendIndex) 
        public
        onlyOwner
        validDividendIndex(dividendIndex)     
    {
        Dividend storage dividend = dividends[dividendIndex];
        require(dividend.reclaimed == false, "Dividend already reclaimed");
        require((dividend.recordDate).add(dividend.claimPeriod) < block.timestamp, "Still claimable");

        dividend.reclaimed = true;
        uint256 recycledAmount = (dividend.payoutAmount).sub(dividend.claimedAmount);
        totalBalance[dividend.payoutToken] = totalBalance[dividend.payoutToken].sub(recycledAmount);
        IERC20(dividend.payoutToken).safeTransfer(_wallet, recycledAmount);

        emit RecycledDividend(dividendIndex, block.timestamp, recycledAmount);
    }

     
    function getDividend(uint256 dividendIndex) 
        public
        view 
        validDividendIndex(dividendIndex)
        returns (uint256, uint256, address, uint256, uint256, uint256, bool)
    {
        Dividend memory result = dividends[dividendIndex];
        return (
            result.recordDate,
            result.claimPeriod,
            address(result.payoutToken),
            result.payoutAmount,
            result.claimedAmount,
            result.totalSupply,
            result.reclaimed);
    }

     
    function _claimDividend(uint256 dividendIndex, address account) internal {
        Dividend storage dividend = dividends[dividendIndex];

        uint256 claimAmount = _calcClaim(dividendIndex, account);
        
        dividend.claimed[account] = true;
        dividend.claimedAmount = (dividend.claimedAmount).add(claimAmount);
        totalBalance[dividend.payoutToken] = totalBalance[dividend.payoutToken].sub(claimAmount);

        IERC20(dividend.payoutToken).safeTransfer(account, claimAmount);
        emit ReclaimedDividend(dividendIndex, account, claimAmount);
    }

     
    function _calcClaim(uint256 dividendIndex, address account) internal view returns (uint256) {
        Dividend memory dividend = dividends[dividendIndex];

        uint256 balance = ERC20Snapshot(_token).balanceOfAt(account, dividend.recordDate);
        return balance.mul(dividend.payoutAmount).div(dividend.totalSupply);
    }
}

 

 

pragma solidity 0.5.7;





 
 
contract ExampleTokenFactory is Managed {

    mapping(address => address) public tokenToDividend;

     
    event DeployedToken(address indexed contractAddress, string name, string symbol, address indexed clientOwner);
    event DeployedDividend(address indexed contractAddress);
   
     
    function newToken(string calldata _name, string calldata _symbol, address _clientOwner, uint256 _initialAmount) external onlyOwner {
        address tokenAddress = _deployToken(_name, _symbol, _clientOwner, _initialAmount);
    }

    function newTokenAndDividend(string calldata _name, string calldata _symbol, address _clientOwner, uint256 _initialAmount) external onlyOwner {
        address tokenAddress = _deployToken(_name, _symbol, _clientOwner, _initialAmount);
        address dividendAddress = _deployDividend(tokenAddress, _clientOwner);
        tokenToDividend[tokenAddress] = dividendAddress;
    }
    
     
     
    function addDocument(address _est, string calldata _documentUri) external onlyValidAddress(_est) onlyManager {
        ExampleSecurityToken(_est).addDocument(_documentUri);
    }

     
    function togglePauseEST(address _est) public onlyValidAddress(_est) onlyManager {
        ExampleSecurityToken est = ExampleSecurityToken(_est);
        bool result = est.paused();
        result ? est.unpause() : est.pause();
    }

     
    function forceTransferEST(address _est, address _confiscatee, address _receiver, uint256 _amount) 
        public 
        onlyValidAddress(_est) 
        onlyValidAddress(_confiscatee)
        onlyValidAddress(_receiver)
        onlyManager {
            require(_amount > 0, "invalid amount");

            ExampleSecurityToken est = ExampleSecurityToken(_est);
            est.forceTransfer(_confiscatee, _receiver, _amount);
        }

    function _deployToken(string memory _name, string memory _symbol, address _clientOwner, uint256 _initialAmount) internal returns (address) {
        require(bytes(_name).length > 0, "name cannot be blank");
        require(bytes(_symbol).length > 0, "symbol cannot be blank");

        ExampleSecurityToken tokenContract = new ExampleSecurityToken(_name, _symbol, _clientOwner, _initialAmount);
        
        emit DeployedToken(address(tokenContract), _name, _symbol, _clientOwner);
        return address(tokenContract);
    }

    function _deployDividend(address tokenAddress, address wallet) internal returns (address) {
        Dividends dividendContract = new Dividends(tokenAddress, wallet);

        emit DeployedDividend(address(dividendContract));
        return address(dividendContract);
    }
}