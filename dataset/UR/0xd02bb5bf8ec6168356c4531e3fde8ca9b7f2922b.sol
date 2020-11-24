 

 

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

 

 
 
pragma solidity 0.5.7;


contract Utils {
     
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "invalid address");
        _;
    }
}

 

 
 
 pragma solidity 0.5.7;



contract Manageable is Ownable, Utils {
    mapping(address => bool) public isManager;      

     
    event ChangedManager(address indexed manager, bool active);

     
    modifier onlyManager() {
        require(isManager[msg.sender], "is not manager");
        _;
    }

     
    constructor() public {
        setManager(msg.sender, true);
    }

     
    function setManager(address _manager, bool _active) public onlyOwner onlyValidAddress(_manager) {
        isManager[_manager] = _active;
        emit ChangedManager(_manager, _active);
    }

     
    function renounceOwnership() public onlyOwner {
        revert("Cannot renounce ownership");
    }
}

 

 

pragma solidity 0.5.7;




contract GlobalWhitelist is Ownable, Manageable {
    mapping(address => bool) public isWhitelisted;  
    bool public isWhitelisting = true;              

     
    event ChangedWhitelisting(address indexed registrant, bool whitelisted);
    event GlobalWhitelistDisabled(address indexed manager);
    event GlobalWhitelistEnabled(address indexed manager);

     
    function addAddressToWhitelist(address _address) public onlyManager onlyValidAddress(_address) {
        isWhitelisted[_address] = true;
        emit ChangedWhitelisting(_address, true);
    }

     
    function addAddressesToWhitelist(address[] calldata _addresses) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addAddressToWhitelist(_addresses[i]);
        }
    }

     
    function removeAddressFromWhitelist(address _address) public onlyManager onlyValidAddress(_address) {
        isWhitelisted[_address] = false;
        emit ChangedWhitelisting(_address, false);
    }

     
    function removeAddressesFromWhitelist(address[] calldata _addresses) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            removeAddressFromWhitelist(_addresses[i]);
        }
    }

     
    function toggleWhitelist() external onlyOwner {
        isWhitelisting = isWhitelisting ? false : true;

        if (isWhitelisting) {
            emit GlobalWhitelistEnabled(msg.sender);
        } else {
            emit GlobalWhitelistDisabled(msg.sender);
        }
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

 

 
pragma solidity 0.5.7;




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

 

 

pragma solidity 0.5.7;  


 
interface IERC20Snapshot {   
     
    function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint256);

     
    function totalSupplyAt(uint _blockNumber) external view returns(uint256);
}

 

 
pragma solidity 0.5.7;  





contract ERC20Snapshot is ERC20, IERC20Snapshot {
    using Snapshots for Snapshots.SnapshotList;

    mapping(address => Snapshots.SnapshotList) private _snapshotBalances; 
    Snapshots.SnapshotList private _snapshotTotalSupply;   

    event AccountSnapshotCreated(address indexed account, uint256 indexed blockNumber, uint256 value);
    event TotalSupplySnapshotCreated(uint256 indexed blockNumber, uint256 value);

     
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256) {
        return _snapshotTotalSupply.getValueAt(blockNumber);
    }

     
    function balanceOfAt(address owner, uint256 blockNumber) 
        external 
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

 

 

pragma solidity 0.5.7;  





contract ERC20ForcedTransfer is Ownable, ERC20 {
     
    event ForcedTransfer(address indexed account, uint256 amount, address indexed receiver);

     
     
    function forceTransfer(address _confiscatee, address _receiver, uint256 _amount) public onlyOwner {
        _transfer(_confiscatee, _receiver, _amount);

        emit ForcedTransfer(_confiscatee, _amount, _receiver);
    }
}

 

 

pragma solidity 0.5.7;  





contract ERC20Whitelist is Ownable, ERC20 {   
    GlobalWhitelist public whitelist;
    bool public isWhitelisting = true;   

     
    event ESTWhitelistingEnabled();
    event ESTWhitelistingDisabled();

     
     
    function toggleWhitelist() external onlyOwner {
        isWhitelisting = isWhitelisting ? false : true;
        
        if (isWhitelisting) {
            emit ESTWhitelistingEnabled();
        } else {
            emit ESTWhitelistingDisabled();
        }
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (checkWhitelistEnabled()) {
            checkIfWhitelisted(msg.sender);
            checkIfWhitelisted(_to);
        }
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (checkWhitelistEnabled()) {
            checkIfWhitelisted(_from);
            checkIfWhitelisted(_to);
        }
        return super.transferFrom(_from, _to, _value);
    }

     
    function checkWhitelistEnabled() public view returns (bool) {
         
        if (isWhitelisting) {
             
            if (whitelist.isWhitelisting()) {
                return true;
            }
        }

        return false;
    }

     
     
    function checkIfWhitelisted(address _account) internal view {
        require(whitelist.isWhitelisted(_account), "not whitelisted");
    }
}

 

 
 
 pragma solidity 0.5.7;




 
 
contract ERC20DocumentRegistry is Ownable {
    using SafeMath for uint256;

    struct HashedDocument {
        uint256 timestamp;
        string documentUri;
    }

     
    HashedDocument[] private _documents;

    event LogDocumentedAdded(string documentUri, uint256 indexed documentIndex);

     
    function addDocument(string calldata documentUri) external onlyOwner {
        require(bytes(documentUri).length > 0, "invalid documentUri");

        HashedDocument memory document = HashedDocument({
            timestamp: block.timestamp,
            documentUri: documentUri
        });

        _documents.push(document);

        emit LogDocumentedAdded(documentUri, _documents.length.sub(1));
    }

     
    function currentDocument() external view 
        returns (uint256 timestamp, string memory documentUri, uint256 index) {
            require(_documents.length > 0, "no documents exist");
            uint256 last = _documents.length.sub(1);

            HashedDocument storage document = _documents[last];
            return (document.timestamp, document.documentUri, last);
        }

     
    function getDocument(uint256 documentIndex) external view
        returns (uint256 timestamp, string memory documentUri, uint256 index) {
            require(documentIndex < _documents.length, "invalid index");

            HashedDocument storage document = _documents[documentIndex];
            return (document.timestamp, document.documentUri, documentIndex);
        }

     
    function documentCount() external view returns (uint256) {
        return _documents.length;
    }
}

 

 

pragma solidity 0.5.7;



contract ERC20BatchSend is ERC20 {
     
    function batchSend(address[] calldata beneficiaries, uint256[] calldata amounts) external {
        require(beneficiaries.length == amounts.length, "mismatched array lengths");

        uint256 length = beneficiaries.length;

        for (uint256 i = 0; i < length; i++) {
            transfer(beneficiaries[i], amounts[i]);
        }
    }
}

 

 

pragma solidity 0.5.7;












contract ExporoToken is Ownable, ERC20Snapshot, ERC20Detailed, ERC20Burnable, ERC20ForcedTransfer, ERC20Whitelist, ERC20BatchSend, ERC20Pausable, ERC20DocumentRegistry {
     
     
     
    constructor(string memory _name, string memory _symbol, uint8 _decimal, address _whitelist, uint256 _initialSupply, address _recipient)
        public 
        ERC20Detailed(_name, _symbol, _decimal) {
            _mint(_recipient, _initialSupply);

            whitelist = GlobalWhitelist(_whitelist);
        }
     
}

 

 

pragma solidity 0.5.7;





 
 
contract ExporoTokenFactory is Manageable {
    address public whitelist;

     
    event NewTokenDeployed(address indexed contractAddress, string name, string symbol, uint8 decimals);
   
     
     
    constructor(address _whitelist) 
        public 
        onlyValidAddress(_whitelist) {
            whitelist = _whitelist;
        }

     
    function newToken(string calldata _name, string calldata _symbol, uint8 _decimals, uint256 _initialSupply, address _recipient) 
        external 
        onlyManager 
        onlyValidAddress(_recipient)
        returns (address) {
            require(bytes(_name).length > 0, "name cannot be blank");
            require(bytes(_symbol).length > 0, "symbol cannot be blank");
            require(_initialSupply > 0, "supply cannot be 0");

            ExporoToken token = new ExporoToken(_name, _symbol, _decimals, whitelist, _initialSupply, _recipient);

            emit NewTokenDeployed(address(token), _name, _symbol, _decimals);
            
            return address(token);
        }
    
     
     
    function addDocument(address _est, string calldata _documentUri) external onlyValidAddress(_est) onlyManager {
        ExporoToken(_est).addDocument(_documentUri);
    }

     
    function toggleESTWhitelist(address _est) public onlyValidAddress(_est) onlyManager {
        ExporoToken(_est).toggleWhitelist();
    }

     
    function togglePauseEST(address _est) public onlyValidAddress(_est) onlyManager {
        ExporoToken est = ExporoToken(_est);
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

            ExporoToken est = ExporoToken(_est);
            est.forceTransfer(_confiscatee, _receiver, _amount);
        }

     
    function toggleGlobalWhitelist() public onlyManager {
        GlobalWhitelist(whitelist).toggleWhitelist();
    }

     
    function whitelistSetManager(address _manager, bool _active) public onlyValidAddress(_manager) onlyManager {
        GlobalWhitelist(whitelist).setManager(_manager, _active);
    }
}