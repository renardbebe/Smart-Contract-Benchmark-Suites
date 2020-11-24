 

pragma solidity ^0.4.18;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract EIP820ImplementerInterface {
     
     
     
     
     
    function canImplementInterfaceForAddress(address addr, bytes32 interfaceHash) view public returns(bool);
}

contract EIP820Registry {

    mapping (address => mapping(bytes32 => address)) interfaces;
    mapping (address => address) managers;

    modifier canManage(address addr) {
        require(getManager(addr) == msg.sender);
        _;
    }

     
     
    function interfaceHash(string interfaceName) public pure returns(bytes32) {
        return keccak256(interfaceName);
    }

     
    function getManager(address addr) public view returns(address) {
         
        if (managers[addr] == 0) {
            return addr;
        } else {
            return managers[addr];
        }
    }

     
     
     
     
     
    function setManager(address addr, address newManager) public canManage(addr) {
        managers[addr] = newManager == addr ? 0 : newManager;
        ManagerChanged(addr, newManager);
    }

     
     
     
     
     
     
    function getInterfaceImplementer(address addr, bytes32 iHash) public constant returns (address) {
        return interfaces[addr][iHash];
    }

     
     
     
     
     
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public canManage(addr)  {
        if ((implementer != 0) && (implementer!=msg.sender)) {
            require(EIP820ImplementerInterface(implementer).canImplementInterfaceForAddress(addr, iHash));
        }
        interfaces[addr][iHash] = implementer;
        InterfaceImplementerSet(addr, iHash, implementer);
    }

    event InterfaceImplementerSet(address indexed addr, bytes32 indexed interfaceHash, address indexed implementer);
    event ManagerChanged(address indexed addr, address indexed newManager);
}

contract EIP820Implementer {
    EIP820Registry eip820Registry = EIP820Registry(0x9aA513f1294c8f1B254bA1188991B4cc2EFE1D3B);

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        eip820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal constant returns(address) {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        return eip820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        eip820Registry.setManager(this, newManager);
    }

}



contract AssetRegistryStorage {

  string internal _name;
  string internal _symbol;
  string internal _description;

   
  uint256 internal _count;

   
  mapping(address => uint256[]) internal _assetsOf;

   
  mapping(uint256 => address) internal _holderOf;

   
  mapping(uint256 => uint256) internal _indexOfAsset;

   
  mapping(uint256 => string) internal _assetData;

   
  mapping(address => mapping(address => bool)) internal _operators;

   
  bool internal _reentrancy;

   
  uint256 internal _reentrancyCount;

   
  mapping(uint256 => address) internal _approval;
}


interface IAssetHolder {
  function onAssetReceived(
     
    uint256 _assetId,
    address _previousHolder,
    address _currentHolder,
    bytes   _userData,
    address _operator,
    bytes   _operatorData
  ) public;
}


interface IAssetRegistry {

   
  function name() public view returns (string);
  function symbol() public view returns (string);
  function description() public view returns (string);
  function totalSupply() public view returns (uint256);
  function decimals() public view returns (uint256);

  function isERC821() public view returns (bool);

   
  function exists(uint256 assetId) public view returns (bool);

  function holderOf(uint256 assetId) public view returns (address);
  function ownerOf(uint256 assetId) public view returns (address);

  function safeHolderOf(uint256 assetId) public view returns (address);
  function safeOwnerOf(uint256 assetId) public view returns (address);

  function assetData(uint256 assetId) public view returns (string);
  function safeAssetData(uint256 assetId) public view returns (string);

   
  function assetCount(address holder) public view returns (uint256);
  function balanceOf(address holder) public view returns (uint256);

  function assetByIndex(address holder, uint256 index) public view returns (uint256);
  function assetsOf(address holder) external view returns (uint256[]);

   
  function transfer(address to, uint256 assetId) public;
  function transfer(address to, uint256 assetId, bytes userData) public;
  function transfer(address to, uint256 assetId, bytes userData, bytes operatorData) public;

   
  function authorizeOperator(address operator, bool authorized) public;
  function approve(address operator, uint256 assetId) public;

   
  function isOperatorAuthorizedBy(address operator, address assetHolder)
    public view returns (bool);

  function approvedFor(uint256 assetId)
    public view returns (address);

  function isApprovedFor(address operator, uint256 assetId)
    public view returns (bool);

   
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed assetId,
    address operator,
    bytes userData,
    bytes operatorData
  );
  event Update(
    uint256 indexed assetId,
    address indexed holder,
    address indexed operator,
    string data
  );
  event AuthorizeOperator(
    address indexed operator,
    address indexed holder,
    bool authorized
  );
  event Approve(
    address indexed owner,
    address indexed operator,
    uint256 indexed assetId
  );
}


contract StandardAssetRegistry is AssetRegistryStorage, IAssetRegistry, EIP820Implementer {
  using SafeMath for uint256;

   
   
   

  function name() public view returns (string) {
    return _name;
  }

  function symbol() public view returns (string) {
    return _symbol;
  }

  function description() public view returns (string) {
    return _description;
  }

  function totalSupply() public view returns (uint256) {
    return _count;
  }

  function decimals() public view returns (uint256) {
    return 0;
  }

  function isERC821() public view returns (bool) {
    return true;
  }

   
   
   

  function exists(uint256 assetId) public view returns (bool) {
    return _holderOf[assetId] != 0;
  }

  function holderOf(uint256 assetId) public view returns (address) {
    return _holderOf[assetId];
  }

  function ownerOf(uint256 assetId) public view returns (address) {
     
     
    return holderOf(assetId);
  }

  function safeHolderOf(uint256 assetId) public view returns (address) {
    address holder = _holderOf[assetId];
    require(holder != 0);
    return holder;
  }

  function safeOwnerOf(uint256 assetId) public view returns (address) {
    return safeHolderOf(assetId);
  }

  function assetData(uint256 assetId) public view returns (string) {
    return _assetData[assetId];
  }

  function safeAssetData(uint256 assetId) public view returns (string) {
    require(_holderOf[assetId] != 0);
    return _assetData[assetId];
  }

   
   
   

  function assetCount(address holder) public view returns (uint256) {
    return _assetsOf[holder].length;
  }

  function balanceOf(address holder) public view returns (uint256) {
    return assetCount(holder);
  }

  function assetByIndex(address holder, uint256 index) public view returns (uint256) {
    require(index < _assetsOf[holder].length);
    require(index < (1<<127));
    return _assetsOf[holder][index];
  }

  function assetsOf(address holder) external view returns (uint256[]) {
    return _assetsOf[holder];
  }

   
   
   

  function isOperatorAuthorizedBy(address operator, address assetHolder)
    public view returns (bool)
  {
    return _operators[assetHolder][operator];
  }

  function approvedFor(uint256 assetId) public view returns (address) {
    return _approval[assetId];
  }

  function isApprovedFor(address operator, uint256 assetId)
    public view returns (bool)
  {
    require(operator != 0);
    if (operator == holderOf(assetId)) {
      return true;
    }
    return _approval[assetId] == operator;
  }

   
   
   

  function authorizeOperator(address operator, bool authorized) public {
    if (authorized) {
      require(!isOperatorAuthorizedBy(operator, msg.sender));
      _addAuthorization(operator, msg.sender);
    } else {
      require(isOperatorAuthorizedBy(operator, msg.sender));
      _clearAuthorization(operator, msg.sender);
    }
    AuthorizeOperator(operator, msg.sender, authorized);
  }

  function approve(address operator, uint256 assetId) public {
    address holder = holderOf(assetId);
    require(operator != holder);
    if (approvedFor(assetId) != operator) {
      _approval[assetId] = operator;
      Approve(holder, operator, assetId);
    }
  }

  function _addAuthorization(address operator, address holder) private {
    _operators[holder][operator] = true;
  }

  function _clearAuthorization(address operator, address holder) private {
    _operators[holder][operator] = false;
  }

   
   
   

  function _addAssetTo(address to, uint256 assetId) internal {
    _holderOf[assetId] = to;

    uint256 length = assetCount(to);

    _assetsOf[to].push(assetId);

    _indexOfAsset[assetId] = length;

    _count = _count.add(1);
  }

  function _addAssetTo(address to, uint256 assetId, string data) internal {
    _addAssetTo(to, assetId);

    _assetData[assetId] = data;
  }

  function _removeAssetFrom(address from, uint256 assetId) internal {
    uint256 assetIndex = _indexOfAsset[assetId];
    uint256 lastAssetIndex = assetCount(from).sub(1);
    uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

    _holderOf[assetId] = 0;

     
    _assetsOf[from][assetIndex] = lastAssetId;

     
    _assetsOf[from][lastAssetIndex] = 0;
    _assetsOf[from].length--;

     
    if (_assetsOf[from].length == 0) {
      delete _assetsOf[from];
    }

     
    _indexOfAsset[assetId] = 0;
    _indexOfAsset[lastAssetId] = assetIndex;

    _count = _count.sub(1);
  }

  function _clearApproval(address holder, uint256 assetId) internal {
    if (holderOf(assetId) == holder && _approval[assetId] != 0) {
      _approval[assetId] = 0;
      Approve(holder, 0, assetId);
    }
  }

  function _removeAssetData(uint256 assetId) internal {
    _assetData[assetId] = '';
  }

   
   
   

  function _generate(uint256 assetId, address beneficiary, string data) internal {
    require(_holderOf[assetId] == 0);

    _addAssetTo(beneficiary, assetId, data);

    Transfer(0, beneficiary, assetId, msg.sender, bytes(data), '');
  }

  function _destroy(uint256 assetId) internal {
    address holder = _holderOf[assetId];
    require(holder != 0);

    _removeAssetFrom(holder, assetId);
    _removeAssetData(assetId);

    Transfer(holder, 0, assetId, msg.sender, '', '');
  }

   
   
   

  modifier onlyHolder(uint256 assetId) {
    require(_holderOf[assetId] == msg.sender);
    _;
  }

  modifier onlyOperatorOrHolder(uint256 assetId) {
    require(
      _holderOf[assetId] == msg.sender
      || isOperatorAuthorizedBy(msg.sender, _holderOf[assetId])
      || isApprovedFor(msg.sender, assetId)
    );
    _;
  }

  modifier isDestinataryDefined(address destinatary) {
    require(destinatary != 0);
    _;
  }

  modifier destinataryIsNotHolder(uint256 assetId, address to) {
    require(_holderOf[assetId] != to);
    _;
  }

  function transfer(address to, uint256 assetId) public {
    return _doTransfer(to, assetId, '', 0, '');
  }

  function transfer(address to, uint256 assetId, bytes userData) public {
    return _doTransfer(to, assetId, userData, 0, '');
  }

  function transfer(address to, uint256 assetId, bytes userData, bytes operatorData) public {
    return _doTransfer(to, assetId, userData, msg.sender, operatorData);
  }

  function _doTransfer(
    address to, uint256 assetId, bytes userData, address operator, bytes operatorData
  )
    isDestinataryDefined(to)
    destinataryIsNotHolder(assetId, to)
    onlyOperatorOrHolder(assetId)
    internal
  {
    return _doSend(to, assetId, userData, operator, operatorData);
  }


  function _doSend(
    address to, uint256 assetId, bytes userData, address operator, bytes operatorData
  )
    internal
  {
    address holder = _holderOf[assetId];
    _removeAssetFrom(holder, assetId);
    _clearApproval(holder, assetId);
    _addAssetTo(to, assetId);

    if (_isContract(to)) {
      require(!_reentrancy);
      _reentrancy = true;

      address recipient = interfaceAddr(to, 'IAssetHolder');
      require(recipient != 0);

      IAssetHolder(recipient).onAssetReceived(assetId, holder, to, userData, operator, operatorData);

      _reentrancy = false;
    }

    Transfer(holder, to, assetId, operator, userData, operatorData);
  }

   
   
   

  function _update(uint256 assetId, string data) internal {
    require(exists(assetId));
    _assetData[assetId] = data;
    Update(assetId, _holderOf[assetId], msg.sender, data);
  }

   
   
   

  function _isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}



 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  string public constant ROLE_ADMIN = "admin";

   
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}


contract Mintable821 is StandardAssetRegistry, RBAC {
  event Mint(uint256 assetId, address indexed beneficiary, string data);
  event MintFinished();

  uint256 public nextAssetId = 0;

  string constant ROLE_MINTER = "minter";
  bool public minting;

  modifier onlyMinter() {
    require(
      hasRole(msg.sender, ROLE_MINTER)
    );
    _;
  }

  modifier canMint() {
    require(minting);
    _;
  }

  function Mintable821(address minter) public {
    _name = "Mintable821";
    _symbol = "MINT";
    _description = "ERC 821 minting contract";

    removeRole(msg.sender, ROLE_ADMIN);
    addRole(minter, ROLE_MINTER);

    minting = true;
  }

  function isContractProxy(address addr) public view returns (bool) {
    return _isContract(addr);
  }

  function generate(address beneficiary, string data)
    onlyMinter
    canMint
    public
  {
    uint256 assetId = nextAssetId;
    _generate(assetId, beneficiary, data);
    Mint(assetId, beneficiary, data);
    nextAssetId = nextAssetId + 1;
  }

   
   
   
   
   
   

  function transferTo(
    address to, uint256 assetId, bytes userData, bytes operatorData
  )
    public
  {
    return transfer(to, assetId, userData, operatorData);
  }

  function endMinting()
    onlyMinter
    canMint
    public
  {
    minting = false;
    MintFinished();
  }
}


contract XLNTPeople is Mintable821 {
  function XLNTPeople()
    Mintable821(msg.sender)
    public
  {
    _name = "XLNTPeople";
    _symbol = "XLNTPPL";
    _description = "I found this XLNT Person!";
  }
}