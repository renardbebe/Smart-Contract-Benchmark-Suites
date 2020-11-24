 

 

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

 

pragma solidity ^0.5.12;

 
interface ITransferManager {

     
    function isApproved(address _spender, address _from, address _to, uint256 _amount) external returns (bool);

}

 

pragma solidity ^0.5.12;

 
library AddressList {

    string private constant ERROR_INVALID_ADDRESS = "Invalid address";

    struct Data {
        bool added;
        uint248 index;
    }

     
    function addTo(
        address _address,
        mapping(address => Data) storage _data,
        address[] storage _list
    )
        internal
    {
        require(_address != address(0), ERROR_INVALID_ADDRESS);

        if (!_data[_address].added) {
            _data[_address] = Data({
                added: true,
                index: uint248(_list.length)
                });
            _list.push(_address);
        }
    }

     
    function removeFrom(
        address _address,
        mapping(address => Data) storage _data,
        address[] storage _list
    )
        internal
    {
        require(_address != address(0), ERROR_INVALID_ADDRESS);

        if (_data[_address].added) {
            uint248 index = _data[_address].index;
            if (index != _list.length - 1) {
                _list[index] = _list[_list.length - 1];
                _data[_list[index]].index = index;
            }
            _list.length--;
            delete _data[_address];
        }
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

 

pragma solidity ^0.5.12;

 
interface IPermissionManager {

    function hasRole(address _user, bytes32 _role) external view returns (bool);

    function hasRoles(address _user, bytes32[] calldata _roles) external view returns (bool);

    function addRole(address _user, bytes32 _role) external;

    function removeRole(address _user, bytes32 _role) external;

    function getRoles() external returns (bytes32[] memory);

}

 

pragma solidity ^0.5.12;


 
contract AllowableStorage {

    string internal constant ERROR_ACCESS_DENIED = "Access is denied";
    string internal constant ERROR_INVALID_ADDRESS = "Invalid address";
    string internal constant ERROR_IS_NOT_ALLOWED = "Is not allowed";
    string internal constant ERROR_ROLE_NOT_FOUND = "Role not found";
    string internal constant ERROR_STOPPED = "Contract is stopped";
    string internal constant ERROR_NOT_STOPPED = "Contract is not stopped";

    string internal constant ERROR_ACTION_WAS_NOT_REQUESTED = "Action wasn't requested";
    string internal constant ERROR_ACTION_WAS_REQUESTED_BY_SENDER = "Action was requested by a sender";

    address _owner = address(0x00);

     
    bytes32[] roleNames;

     
    mapping(bytes32 => mapping(address => AddressList.Data)) roleUserData;
     
    mapping(bytes32 => address[]) roleUsers;

     
    address permissionManager = address(0x00);

     
    bool roleApproval = false;

    bool transferOwnershipApproval = false;

    bool stopped = false;

     
    mapping(address => address) transferOwnershipInitiator;

     
    mapping(address => mapping(bytes32 => address)) addRoleInitiators;

     
    mapping(address => mapping(bytes32 => address)) removeRoleInitiators;

     
    bytes32[] adminRoles;

    address stopInitiator = address(0x00);

    address startInitiator = address(0x00);

    address configurator = address(0x00);

}

 

pragma solidity ^0.5.12;


library AllowableLib {
    using AddressList for address;

    string internal constant ERROR_ROLE_NOT_FOUND = "Role not found";

    string internal constant ERROR_ACCESS_DENIED = "Access is denied";
    string internal constant ERROR_ACTION_WAS_NOT_REQUESTED = "Action wasn't requested";
    string internal constant ERROR_ACTION_WAS_REQUESTED_BY_SENDER = "Action was requested by a sender";

    event RoleAdded(address indexed _user, bytes32 _role);
    event RoleRemoved(address indexed _user, bytes32 _role);

    event RoleAddingRequested(address indexed _user, bytes32 _role);
    event RoleRemovingRequested(address indexed _user, bytes32 _role);

     
    function addRole(
        address _user,
        bytes32 _role,
        bool _withApproval,
        bool _withSameRole,
        bytes32[] storage roleNames,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData,
        mapping(bytes32 => address[]) storage roleUsers,
        mapping(address => mapping(bytes32 => address)) storage addRoleInitiators
    )
        public
    {
        if (_withApproval) {
            _checkRoleLevel(_role, _withSameRole, roleUserData);
            _checkInitiator(addRoleInitiators[_user][_role]);
        }
        require(isExists(_role, roleNames), ERROR_ROLE_NOT_FOUND);
        _user.addTo(roleUserData[_role], roleUsers[_role]);
        emit RoleAdded(_user, _role);
        if (_withApproval) {
            delete addRoleInitiators[_user][_role];
        }
    }

     
    function addRoleRequest(
        address _user,
        bytes32 _role,
        bool _withSameRole,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData,
        mapping(address => mapping(bytes32 => address)) storage addRoleInitiators
    )
        public
    {
        _checkRoleLevel(_role, _withSameRole, roleUserData);
        addRoleInitiators[_user][_role] = msg.sender;
        emit RoleAddingRequested(_user, _role);
    }

     
    function removeRole(
        address _user,
        bytes32 _role,
        bool _withApproval,
        bool _withSameRole,
        bytes32[] storage roleNames,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData,
        mapping(bytes32 => address[]) storage roleUsers,
        mapping(address => mapping(bytes32 => address)) storage removeRoleInitiators
    )
        public
    {
        if (_withApproval) {
            _checkRoleLevel(_role, _withSameRole, roleUserData);
            _checkInitiator(removeRoleInitiators[_user][_role]);
        }
        require(isExists(_role, roleNames), ERROR_ROLE_NOT_FOUND);
        _user.removeFrom(roleUserData[_role], roleUsers[_role]);
        emit RoleRemoved(_user, _role);
        if (_withApproval) {
            delete removeRoleInitiators[_user][_role];
        }
    }

     
    function removeRoleRequest(
        address _user,
        bytes32 _role,
        bool _withSameRole,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData,
        mapping(address => mapping(bytes32 => address)) storage removeRoleInitiators
    )
        public
    {
        _checkRoleLevel(_role, _withSameRole, roleUserData);
        removeRoleInitiators[_user][_role] = msg.sender;
        emit RoleRemovingRequested(_user, _role);
    }

     
    function addSystemRole(
        bytes32 _role,
        bytes32[] storage roleNames
    )
        public
    {
        if (!isExists(_role, roleNames)) {
            roleNames.push(_role);
        }
    }

     
    function isExists(
        bytes32 _role,
        bytes32[] storage roleNames
    )
        private
        view
        returns (bool)
    {
        for (uint i = 0; i < roleNames.length; i++) {
            if (_role == roleNames[i]) {
                return true;
            }
        }
        return false;
    }

     
    function _checkRoleLevel(
        bytes32 _role,
        bool _withSameRole,
        mapping(bytes32 => mapping(address => AddressList.Data)) storage roleUserData
    )
        internal
        view
    {
        if (_withSameRole) {
            require(roleUserData[_role][msg.sender].added, ERROR_ACCESS_DENIED);
        }
    }

     
    function _checkInitiator(address _initiator) internal view {
        require(_initiator != address(0), ERROR_ACTION_WAS_NOT_REQUESTED);
        require(_initiator != msg.sender, ERROR_ACTION_WAS_REQUESTED_BY_SENDER);
    }

}

 

pragma solidity ^0.5.12;







 
contract AllowableModifiers is AllowableStorage  {
    using AddressList for address;

    bytes32 internal constant ROLE_INVENIAM_ADMIN = "INVENIAM_ADMIN";

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), ERROR_ACCESS_DENIED);
        _;
    }

    modifier onlyRole(bytes32 _role) {
        require(_hasRole(msg.sender, _role), ERROR_ACCESS_DENIED);
        _;
    }

    modifier onlyRoleStrict(bytes32 _role) {
        require(_hasRoleStrict(msg.sender, _role), ERROR_ACCESS_DENIED);
        _;
    }

    modifier onlyRoles(bytes32[] memory _roles) {
        require(_hasRoles(msg.sender, _roles), ERROR_ACCESS_DENIED);
        _;
    }

    modifier onlyAdmin {
        require(_hasRoles(msg.sender, adminRoles), ERROR_ACCESS_DENIED);
        _;
    }

    modifier notStopped() {
        require(!stopped, ERROR_STOPPED);
        _;
    }

    modifier isStopped() {
        require(stopped, ERROR_NOT_STOPPED);
        _;
    }

     
    function _hasRole(address _user, bytes32 _role) internal view returns (bool) {
        return isOwner() || _hasRoleStrict(_user, _role);
    }

     
    function _hasRoleStrict(address _user, bytes32 _role) internal view returns (bool) {
        return roleUserData[_role][_user].added
        || (permissionManager != address(0) && IPermissionManager(permissionManager).hasRole(_user, _role));
    }

     
    function _hasRoles(address _user, bytes32[] memory _roles) internal view returns (bool) {
        if (isOwner()) {
            return true;
        }
        return _hasLocalRoles(_user, _roles)
        || (permissionManager != address(0) && IPermissionManager(permissionManager).hasRoles(_user, _roles));
    }

     
    function _hasLocalRoles(address _user, bytes32[] memory _roles) internal view returns (bool) {
        for (uint i = 0; i < _roles.length; i++) {
            bytes32 role = _roles[i];
            if (roleUserData[role][_user].added) {
                return true;
            }
        }
        return false;
    }

}

 

pragma solidity ^0.5.12;

 
contract FunctionProxy {

    string private constant ERROR_IMPLEMENTATION_NOT_FOUND = "Implementation not found";

     
    function _getImplementation() internal view returns (address) {
        return address(0);
    }

     
    function () external {
        address implementation = _getImplementation();
        require(implementation != address(0), ERROR_IMPLEMENTATION_NOT_FOUND);

        assembly {
            let pointer := mload(0x40)
            calldatacopy(pointer, 0, calldatasize)
            let result := delegatecall(gas, implementation, pointer, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(pointer, 0, size)

            switch result
            case 0 { revert(pointer, size) }
            default { return(pointer, size) }
        }
    }

}

 

pragma solidity ^0.5.12;








 
contract Allowable is AllowableModifiers, FunctionProxy {
    using AddressList for address;

    bytes32 private constant ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN = "INDIVIDUAL_ISSUE_TOKEN_ADMIN";

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event RoleAdded(address indexed _user, bytes32 _role);
    event RoleRemoved(address indexed _user, bytes32 _role);

    event RoleAddingRequested(address indexed _user, bytes32 _role);
    event RoleRemovingRequested(address indexed _user, bytes32 _role);

    function initRoleApproval() public {
        roleApproval = true;
    }

     
    function _addSystemRole(bytes32 _role) internal {
        AllowableLib.addSystemRole(_role, roleNames);
    }

     
    function addRole(address _user, bytes32 _role) public notStopped onlyAdmin {
        _addRole(_user, _role);
    }

     
    function addRoles(address[] memory _users, bytes32 _role) public notStopped onlyAdmin {
        for (uint i = 0; i < _users.length; i++) {
            _addRole(_users[i], _role);
        }
    }

     
    function _addRole(address _user, bytes32 _role) private {
        bool withApproval = _addRoleWithApproval(_user, _role);
        bool withSameRole = _withSameRole(_role);
        AllowableLib.addRole(_user, _role, withApproval, withSameRole, roleNames, roleUserData, roleUsers, addRoleInitiators);
    }

     
    function addRoleRequest(address _user, bytes32 _role) public notStopped onlyAdmin {
        _addRoleRequest(_user, _role);
    }

     
    function _addRoleRequest(address _user, bytes32 _role) private {
        bool withSameRole = _withSameRole(_role);
        AllowableLib.addRoleRequest(_user, _role, withSameRole, roleUserData, addRoleInitiators);
    }

     
    function removeRole(address _user, bytes32 _role) public notStopped onlyAdmin {
        _removeRole(_user, _role);
    }

     
    function _removeRole(address _user, bytes32 _role) private {
        bool withApproval = _removeRoleWithApproval(_user, _role);
        bool withSameRole = _withSameRole(_role);
        AllowableLib.removeRole(_user, _role, withApproval, withSameRole, roleNames, roleUserData, roleUsers, removeRoleInitiators);
    }

     
    function removeRoleRequest(address _user, bytes32 _role) public notStopped onlyAdmin {
        _removeRoleRequest(_user, _role);
    }

     
    function _removeRoleRequest(address _user, bytes32 _role) private {
        bool withSameRole = _withSameRole(_role);
        AllowableLib.removeRoleRequest(_user, _role, withSameRole, roleUserData, removeRoleInitiators);
    }

     
    function _withSameRole(bytes32 _role) private pure returns (bool) {
        return _role == ROLE_INVENIAM_ADMIN;
    }

     
    function _addRoleWithApproval(address  , bytes32  ) internal view returns (bool) {
        return roleApproval && _getAdminCount() > 0;
    }

     
    function _removeRoleWithApproval(address  , bytes32 _role) internal view returns (bool) {
        uint adminCount = _getAdminCount();
         
        if (_role == adminRoles[0] || _role == adminRoles[1]) {
            adminCount--;
        }
        return roleApproval && adminCount > 0;
    }

     
    function _getAdminCount() private view returns (uint) {
        uint adminCount;
        if (adminRoles.length == 2) {
            adminCount = roleUsers[adminRoles[0]].length + roleUsers[adminRoles[1]].length;
        }
        return adminCount;
    }

     
    function getRoles() public view returns (bytes32[] memory) {
        return roleNames;
    }

     
    function getUsersByRole(bytes32 _role) public view returns (address[] memory) {
        return roleUsers[_role];
    }

     
    function setPermissionManager(address _permissionManager) public notStopped onlyAdmin {
        _setPermissionManager(_permissionManager);
    }

    function _setPermissionManager(address _permissionManager) private {
        permissionManager = _permissionManager;
    }

     
    function getPermissionManager() public view returns (address) {
        return permissionManager;
    }

     
    function transferOwnership(address newOwner) public notStopped onlyOwner {
        if (transferOwnershipApproval) {
            transferOwnershipInitiator[newOwner] = msg.sender;
        } else {
            transferOwnershipApproval = true;
            _transferOwnership(newOwner);
        }
    }

     
    function _transferOwnership(address newOwner) private {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

     
    function approveTransferOwnership(address newOwner) public notStopped onlyRoleStrict(ROLE_INVENIAM_ADMIN) {
        _checkInitiator(transferOwnershipInitiator[newOwner]);
        _transferOwnership(newOwner);
        delete transferOwnershipInitiator[newOwner];
    }

     
    function stopRequest() public notStopped onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN) {
        stopInitiator = msg.sender;
    }

     
    function stop() public notStopped onlyRoleStrict(ROLE_INVENIAM_ADMIN) {
        _checkInitiator(stopInitiator);
        stopped = true;
        delete stopInitiator;
    }

     
    function startRequest() public isStopped onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN) {
        startInitiator = msg.sender;
    }

     
    function start() public isStopped onlyRoleStrict(ROLE_INVENIAM_ADMIN) {
        _checkInitiator(startInitiator);
        stopped = false;
        delete startInitiator;
    }

     
    function _checkInitiator(address _initiator) private view {
        require(_initiator != address(0), ERROR_ACTION_WAS_NOT_REQUESTED);
        require(_initiator != msg.sender, ERROR_ACTION_WAS_REQUESTED_BY_SENDER);
    }

     
    function _getImplementation() internal view returns (address) {
        return configurator;
    }

}

 

pragma solidity ^0.5.12;

 
interface IDocumentManager {

    event DocumentAdded(
        string indexed _document,
        string _uri,
        string indexed _checksum,
        string _checksumAlgo,
        string _timestamp,
        string _figi,
        string _individualId
    );

     
    function setFieldSeparator(string calldata _separator) external;

     
    function getFieldSeparator() external view returns (string memory);

     
    function setSaveData(bool _saveData) external;

     
    function getSaveData() external view returns (bool);

     
    function setDocument(string calldata _symbol, string calldata _data) external;

     
    function getDocument(string calldata _symbol, bytes32 _id)
        external
        view
        returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory);

     
    function getDocumentIds(string calldata _symbol) external view returns (bytes32[] memory);

}

 

pragma solidity ^0.5.12;



library InveniamTokenLib {
    using SafeMath for uint256;
    using AddressList for address;

    string private constant ERROR_INVALID_INDEX = "Index out of bound";
    string private constant ERROR_INVALID_ADDRESS = "Invalid address";
    string private constant ERROR_INVALID_AMOUNT = "Invalid amount";
    string private constant ERROR_AMOUNT_IS_NOT_AVAILABLE = "Amount is not available";

    event TransferRequested(address indexed _from, address indexed _to, uint256 _amount);

    struct HistoryBalance {
        uint40 timestamp;
        uint216 value;
    }

     
    function afterTransfer(
        address tokenAddress,
        address _from,
        address _to,
        uint _balanceFrom,
        uint _balanceTo,
        mapping(address => AddressList.Data) storage holderData,
        address[] storage holders,
        mapping(address => HistoryBalance[]) storage historyBalances,
        address[] storage historyHolders
    )
        public
    {
        if (_from != tokenAddress) {
            if (_balanceFrom == 0) {
                _from.removeFrom(holderData, holders);
            }
            if (historyBalances[_from].length == 0) {
                historyHolders.push(_from);
            }
            historyBalances[_from].push(HistoryBalance(uint40(now), uint216(_balanceFrom)));
        }

        if (_to != tokenAddress) {
            if (_balanceTo > 0) {
                _to.addTo(holderData, holders);
            }
            if (historyBalances[_to].length == 0) {
                historyHolders.push(_to);
            }
            historyBalances[_to].push(HistoryBalance(uint40(now), uint216(_balanceTo)));
        }
    }

     
    function afterMint(
        address _account,
        uint _balance,
        mapping(address => AddressList.Data) storage holderData,
        address[] storage holders,
        mapping(address => HistoryBalance[]) storage historyBalances,
        address[] storage historyHolders
    )
        public
    {
        if (_balance > 0) {
            _account.addTo(holderData, holders);
        }

        if (historyBalances[_account].length == 0) {
            historyHolders.push(_account);
        }
        historyBalances[_account].push(HistoryBalance(uint40(now), uint216(_balance)));
    }

     
    function afterBurn(
        address _account,
        uint _balance,
        mapping(address => AddressList.Data) storage holderData,
        address[] storage holders,
        mapping(address => HistoryBalance[]) storage historyBalances,
        address[] storage historyHolders
    )
        public
    {
        if (_balance == 0) {
            _account.removeFrom(holderData, holders);
        }

        if (historyBalances[_account].length == 0) {
            historyHolders.push(_account);
        }
        historyBalances[_account].push(HistoryBalance(uint40(now), uint216(_balance)));
    }

     
    function requestTransfer(
        address _from,
        address _to,
        uint256  ,
        mapping(address => AddressList.Data) storage senderData,
        address[] storage senders,
        mapping(address => mapping (address => uint256)) storage  ,
        mapping(address => mapping(address => AddressList.Data)) storage senderToReceiverData,
        mapping(address => address[]) storage senderToReceivers
    )
        public
    {
        if (senderToReceivers[_from].length == 0) {
            _from.addTo(senderData, senders);
        }
        _to.addTo(senderToReceiverData[_from], senderToReceivers[_from]);
    }

     
    function removeParticipants(
        address _from,
        address _to,
        mapping(address => AddressList.Data) storage senderData,
        address[] storage senders,
        mapping(address => mapping(address => AddressList.Data)) storage senderToReceiverData,
        mapping(address => address[]) storage senderToReceivers
    )
        public
    {
        _to.removeFrom(senderToReceiverData[_from], senderToReceivers[_from]);
        if (senderToReceivers[_from].length == 0) {
            _from.removeFrom(senderData, senders);
        }
    }

     
    function validateTransfer(address  , address _to, uint256 _amount, uint256 _balance) public pure {
        require(_amount > 0, ERROR_INVALID_AMOUNT);
        require(_amount <= _balance, ERROR_AMOUNT_IS_NOT_AVAILABLE);
        require(_to != address(0), ERROR_INVALID_ADDRESS);
    }

}

 

pragma solidity ^0.5.12;



 
contract TokenStorage {

     
    mapping(address => mapping (address => uint256)) transferBalances;

     
    address transferManager = address(0x00);

     
    mapping(address => AddressList.Data) senderData;
    address[] senders;

     
    mapping(address => mapping(address => AddressList.Data)) senderToReceiverData;
    mapping(address => address[]) senderToReceivers;

     
    mapping(address => AddressList.Data) holderData;
    address[] holders;

     
    mapping(address => InveniamTokenLib.HistoryBalance[]) historyBalances;
    address[] historyHolders;

     
    address documentManager = address(0x00);

     
    bool savePendingBalances = false;

     
    bool saveHoldersHistory = false;

     
    bool forceTransferApproval = false;

    address allowable = address(0x00);

     
    mapping(address => mapping(address => mapping(uint256 => address))) forceTransferInitiators;

}

 

pragma solidity ^0.5.12;

 
interface ITokenConfigurator {

     
    function getPendingBalance(address _from, address _to) external view returns (uint256);

     
    function getSenders() external view returns (address[] memory);

     
    function getReceiversBySender(address _sender) external view returns (address[] memory);

     
    function getHolders() external view returns (address[] memory);

     
    function getHistoryHolders() external view returns (address[] memory);

     
    function getHistoryLength(address _account) external view returns (uint);

     
    function getHistoryBalance(address _account, uint _index) external view returns (uint40, uint216);

     
    function setTransferManager(address _transferManager) external;

     
    function getTransferManager() external view returns (address);

     
    function setDocumentManager(address _documentManager) external;

     
    function getDocumentManager() external view returns (address);

     
    function setSavePendingBalances(bool _savePendingBalances) external;

     
    function getSavePendingBalances() external view returns (bool);

     
    function setSaveHoldersHistory(bool _saveHoldersHistory) external;

     
    function getSaveHoldersHistory() external view returns (bool);

    function initForceTransferApproval() external;

}

 

pragma solidity ^0.5.12;











 
contract InveniamToken is AllowableModifiers, TokenStorage, ERC20, ERC20Detailed, FunctionProxy {

    bytes32 private constant ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN = "INDIVIDUAL_ISSUE_TOKEN_ADMIN";

    string private constant ERROR_INVALID_AMOUNT = "Invalid amount";
    string private constant ERROR_AMOUNT_IS_NOT_AVAILABLE = "Amount is not available";
    string private constant ERROR_AMOUNT_IS_NOT_ALLOWED = "Amount is not allowed";
    string private constant ERROR_INVALID_TOTAL_SUPPLY = "New supply is equal to the current supply";
    string private constant ERROR_TRANSFER_NOT_FOUND = "Pending transfer not found";

    event TransferRequested(address indexed _from, address indexed _to, uint256 _amount);

    event TransferApproved(address indexed _from, address indexed _to, uint256 _amount);

    event TransferRejected(address indexed _from, address indexed _to, uint256 _amount);

    event SupplyChanged(uint256 _delta, uint256 _totalSupply);

    event ForcedTransfer(address indexed _from, address indexed _to, uint256 _amount);

    event ForceTransferRequested(address indexed _from, address indexed _to, uint256 _amount);

    event DocumentAdded(
        string indexed _document,
        string _uri,
        string indexed _checksum,
        string _checksumAlgo,
        string _timestamp,
        string _figi,
        string _individualId
    );

    event RawDocumentAdded(string _data);

     
    constructor (
        string memory _symbol,
        string memory _name,
        uint8 _decimals,
        uint256 _totalSupply,
        address _tokenOwner,
        address _tokenRegistry,
        bool _saveHoldersHistory,
        address _allowable,
        address _configurator
    )
        ERC20Detailed(_name, _symbol, _decimals)
        public
    {
        saveHoldersHistory = _saveHoldersHistory;
        allowable = _allowable;
        configurator = _configurator;
        if (_totalSupply > 0) {
            _mint(_tokenOwner, _totalSupply);
        }

        AllowableLib.addSystemRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN, roleNames);
        AllowableLib.addSystemRole(ROLE_INVENIAM_ADMIN, roleNames);
         
         
        _addRole(_tokenRegistry, ROLE_INVENIAM_ADMIN);

        adminRoles.push(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN);
        adminRoles.push(ROLE_INVENIAM_ADMIN);
    }

     
    function _addRole(address _user, bytes32 _role) private {
        AllowableLib.addRole(_user, _role, false, false, roleNames, roleUserData, roleUsers, addRoleInitiators);
    }

     
    function transfer(address _to, uint256 _amount) public notStopped returns (bool) {
        _validateTransfer(msg.sender, _to, _amount);

        if (_isApproved(msg.sender, msg.sender, _to, _amount)) {
            super.transfer(_to, _amount);
            emit TransferApproved(msg.sender, _to, _amount);
        } else {
            super.transfer(address(this), _amount);
            _requestTransfer(msg.sender, _to, _amount);
        }
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public notStopped returns (bool) {
        _validateTransfer(_from, _to, _amount);
        require(_amount <= allowance(_from, msg.sender), ERROR_AMOUNT_IS_NOT_ALLOWED);

        if (_isApproved(msg.sender, _from, _to, _amount)) {
            super.transferFrom(_from, _to, _amount);
            emit TransferApproved(_from, _to, _amount);
        } else {
            super.transferFrom(_from, address(this), _amount);
            _requestTransfer(_from, _to, _amount);
        }
        return true;
    }

     
    function approveTransfer(address _from, address _to, uint256 _amount) external notStopped onlyAdmin {
        require(_amount > 0, ERROR_INVALID_AMOUNT);
        require(_amount <= transferBalances[_from][_to], ERROR_AMOUNT_IS_NOT_AVAILABLE);

        transferBalances[_from][_to] = transferBalances[_from][_to].sub(_amount);
        if (transferBalances[_from][_to] == 0) {
            _removeParticipants(_from, _to);
        }

        _transfer(address(this), _to, _amount);
        emit TransferApproved(_from, _to, _amount);
    }

     
    function rejectTransfer(address _from, address _to)
        external
        notStopped
        onlyAdmin
    {
        require(transferBalances[_from][_to] > 0, ERROR_TRANSFER_NOT_FOUND);

        uint256 amount = transferBalances[_from][_to];
        transferBalances[_from][_to] = 0;
        _removeParticipants(_from, _to);

        _transfer(address(this), _from, amount);
        emit TransferRejected(_from, _to, amount);
    }

     
    function forceTransferRequest(address _from, address _to, uint256 _amount)
        public
        notStopped
        onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN)
    {
        _validateTransfer(_from, _to, _amount);

        if (forceTransferApproval) {
            forceTransferInitiators[_from][_to][_amount] = msg.sender;
            emit ForceTransferRequested(_from, _to, _amount);
        } else {
            _forceTransfer(_from, _to, _amount);
        }
    }

     
    function forceTransfer(address _from, address _to, uint256 _amount)
        public
        notStopped
        onlyRoleStrict(ROLE_INVENIAM_ADMIN)
    {
        if (forceTransferApproval) {
            address initiator = forceTransferInitiators[_from][_to][_amount];
            require(initiator != address(0), ERROR_ACTION_WAS_NOT_REQUESTED);
            require(initiator != msg.sender, ERROR_ACTION_WAS_REQUESTED_BY_SENDER);
        }

        require(_amount <= balanceOf(_from), ERROR_AMOUNT_IS_NOT_AVAILABLE);
        _forceTransfer(_from, _to, _amount);

        if (forceTransferApproval) {
            delete forceTransferInitiators[_from][_to][_amount];
        }
    }

    function _forceTransfer(address _from, address _to, uint256 _amount) private {
        _transfer(_from, _to, _amount);
        emit ForcedTransfer(_from, _to, _amount);
        emit TransferApproved(msg.sender, _to, _amount);
    }

     
    function changeTotalSupply(uint256 _newTotalSupply) public notStopped onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN) {
        require(_newTotalSupply != totalSupply(), ERROR_INVALID_TOTAL_SUPPLY);

        bool isReducing = _newTotalSupply < totalSupply();
        uint256 delta;
        if (isReducing) {
            delta = totalSupply().sub(_newTotalSupply);
            _burn(owner(), delta);
        } else {
            delta = _newTotalSupply.sub(totalSupply());
            _mint(owner(), delta);
        }
        emit SupplyChanged(delta, totalSupply());
    }

     
    function setDocument(string calldata _data) external notStopped onlyRole(ROLE_INDIVIDUAL_ISSUE_TOKEN_ADMIN) {
        if (address(documentManager) != address(0x00)) {
            IDocumentManager(documentManager).setDocument(symbol(), _data);
        } else {
            emit RawDocumentAdded(_data);
        }
    }

     
    function _transfer(address _from, address _to, uint256 _amount) internal {
        super._transfer(_from, _to, _amount);
        if (saveHoldersHistory && _amount > 0) {
            uint balanceFrom = balanceOf(_from);
            uint balanceTo = balanceOf(_to);

            InveniamTokenLib.afterTransfer(
                address(this),
                _from,
                _to,
                balanceFrom,
                balanceTo,
                holderData,
                holders,
                historyBalances,
                historyHolders
            );
        }
    }

     
    function _mint(address _account, uint256 _amount) internal {
        super._mint(_account, _amount);
        if (saveHoldersHistory && _amount > 0) {
            uint balance = balanceOf(_account);

            InveniamTokenLib.afterMint(
                _account,
                balance,
                holderData,
                holders,
                historyBalances,
                historyHolders
            );
        }
    }

     
    function _burn(address _account, uint256 _amount) internal {
        super._burn(_account, _amount);
        if (saveHoldersHistory && _amount > 0) {
            uint balance = balanceOf(_account);

            InveniamTokenLib.afterBurn(
                _account,
                balance,
                holderData,
                holders,
                historyBalances,
                historyHolders
            );
        }
    }

     
    function _validateTransfer(address _from, address _to, uint256 _amount) internal view {
        InveniamTokenLib.validateTransfer(_from, _to, _amount, balanceOf(_from));
    }

     
    function _isApproved(address _spender, address _from, address _to, uint256 _amount) internal returns (bool) {
        return (transferManager != address(0x00) &&
                ITransferManager(transferManager).isApproved(_spender, _from, _to, _amount));
    }

     
    function _requestTransfer(address _from, address _to, uint256 _amount) internal {
        transferBalances[_from][_to] = transferBalances[_from][_to].add(_amount);
        if (savePendingBalances) {
            InveniamTokenLib.requestTransfer(
                _from,
                _to,
                _amount,
                senderData,
                senders,
                transferBalances,
                senderToReceiverData,
                senderToReceivers
            );
        }
        emit TransferRequested(_from, _to, _amount);
    }

     
    function _removeParticipants(address _from, address _to) internal {
        if (savePendingBalances) {
            InveniamTokenLib.removeParticipants(
                _from,
                _to,
                senderData,
                senders,
                senderToReceiverData,
                senderToReceivers
            );
        }
    }

     
    function _getImplementation() internal view returns (address) {
        return allowable;
    }

}