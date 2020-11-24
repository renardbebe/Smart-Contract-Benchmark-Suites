 

pragma solidity 0.4.25;

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 

 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

     
     
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
     
    ownedTokens[_from].length--;

     
     
     

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

interface IDatabase {
    
    function createEntry() external payable returns (uint256);
    function auth(uint256, address) external;
    function deleteEntry(uint256) external;
    function fundEntry(uint256) external payable;
    function claimEntryFunds(uint256, uint256) external;
    function updateEntryCreationFee(uint256) external;
    function updateDatabaseDescription(string) external;
    function addDatabaseTag(bytes32) external;
    function updateDatabaseTag(uint8, bytes32) external;
    function removeDatabaseTag(uint8) external;
    function readEntryMeta(uint256) external view returns (
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256
    );
    function getChaingearID() external view returns (uint256);
    function getEntriesIDs() external view returns (uint256[]);
    function getIndexByID(uint256) external view returns (uint256);
    function getEntryCreationFee() external view returns (uint256);
    function getEntriesStorage() external view returns (address);
    function getSchemaDefinition() external view returns (string);
    function getDatabaseBalance() external view returns (uint256);
    function getDatabaseDescription() external view returns (string);
    function getDatabaseTags() external view returns (bytes32[]);
    function getDatabaseSafe() external view returns (address);
    function getSafeBalance() external view returns (uint256);
    function getDatabaseInitStatus() external view returns (bool);
    function pause() external;
    function unpause() external;
    function transferAdminRights(address) external;
    function getAdmin() external view returns (address);
    function getPaused() external view returns (bool);
    function transferOwnership(address) external;
    function deletePayees() external;
}

 

interface IDatabaseBuilder {
    
    function deployDatabase(
        address[],
        uint256[],
        string,
        string
    ) external returns (IDatabase);
    function setChaingearAddress(address) external;
    function getChaingearAddress() external view returns (address);
    function getOwner() external view returns (address);
}

 

interface IChaingear {
    
    function addDatabaseBuilderVersion(
        string,
        IDatabaseBuilder,
        string,
        string
    ) external;
    function updateDatabaseBuilderDescription(string, string) external;
    function depricateDatabaseBuilder(string) external;
    function createDatabase(
        string,
        address[],
        uint256[],
        string,
        string
    ) external payable returns (address, uint256);
    function deleteDatabase(uint256) external;
    function fundDatabase(uint256) external payable;
    function claimDatabaseFunds(uint256, uint256) external;
    function updateCreationFee(uint256) external;
    function getAmountOfBuilders() external view returns (uint256);
    function getBuilderByID(uint256) external view returns(string);
    function getDatabaseBuilder(string) external view returns(address, string, string, bool);
    function getDatabasesIDs() external view returns (uint256[]);
    function getDatabaseIDByAddress(address) external view returns (uint256);
    function getDatabaseAddressByName(string) external view returns (address);
    function getDatabaseSymbolByID(uint256) external view returns (string);
    function getDatabaseIDBySymbol(string) external view returns (uint256);
    function getDatabase(uint256) external view returns (
        string,
        string,
        address,
        string,
        uint256,
        address,
        uint256
    );
    function getDatabaseBalance(uint256) external view returns (uint256, uint256);
    function getChaingearDescription() external pure returns (string);
    function getCreationFeeWei() external view returns (uint256);
    function getSafeBalance() external view returns (uint256);
    function getSafeAddress() external view returns (address);
    function getNameExist(string) external view returns (bool);
    function getSymbolExist(string) external view returns (bool);
}

 

interface ISchema {

    function createEntry() external;
    function deleteEntry(uint256) external;
}

 

 
contract Safe {
    
    address private owner;

    constructor() public
    {
        owner = msg.sender;
    }

    function()
        external
        payable
    {
        require(msg.sender == owner);
    }

    function claim(address _entryOwner, uint256 _amount)
        external
    {
        require(msg.sender == owner);
        require(_amount <= address(this).balance);
        require(_entryOwner != address(0));
        
        _entryOwner.transfer(_amount);
    }

    function getOwner()
        external
        view
        returns(address)
    {
        return owner;
    }
}

 

 
contract PaymentSplitter {
    
    using SafeMath for uint256;

    uint256 internal totalShares;
    uint256 internal totalReleased;

    mapping(address => uint256) internal shares;
    mapping(address => uint256) internal released;
    address[] internal payees;
    
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    constructor (address[] _payees, uint256[] _shares)
        public
        payable
    {
        _initializePayess(_payees, _shares);
    }

    function ()
        external
        payable
    {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function getTotalShares()
        external
        view
        returns (uint256)
    {
        return totalShares;
    }

    function getTotalReleased()
        external
        view
        returns (uint256)
    {
        return totalReleased;
    }

    function getShares(address _account)
        external
        view
        returns (uint256)
    {
        return shares[_account];
    }

    function getReleased(address _account)
        external
        view
        returns (uint256)
    {
        return released[_account];
    }

    function getPayee(uint256 _index)
        external
        view
        returns (address)
    {
        return payees[_index];
    }
    
    function getPayeesCount() 
        external
        view
        returns (uint256)
    {   
        return payees.length;
    }

    function release(address _account) 
        public
    {
        require(shares[_account] > 0);

        uint256 totalReceived = address(this).balance.add(totalReleased);
        uint256 payment = totalReceived.mul(shares[_account]).div(totalShares).sub(released[_account]);

        require(payment != 0);

        released[_account] = released[_account].add(payment);
        totalReleased = totalReleased.add(payment);

        _account.transfer(payment);
        
        emit PaymentReleased(_account, payment);
    }
    
    function _initializePayess(address[] _payees, uint256[] _shares)
        internal
    {
        require(payees.length == 0);
        require(_payees.length == _shares.length);
        require(_payees.length > 0 && _payees.length <= 8);

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    function _addPayee(
        address _account,
        uint256 _shares
    ) 
        internal
    {
        require(_account != address(0));
        require(_shares > 0);
        require(shares[_account] == 0);

        payees.push(_account);
        shares[_account] = _shares;
        totalShares = totalShares.add(_shares);
        
        emit PayeeAdded(_account, _shares);
    }
}

 

 
contract DatabasePermissionControl is Ownable {

     

    enum CreateEntryPermissionGroup {OnlyAdmin, Whitelist, AllUsers}

    address private admin;
    bool private paused = true;

    mapping(address => bool) private whitelist;

    CreateEntryPermissionGroup private permissionGroup = CreateEntryPermissionGroup.OnlyAdmin;

     

    event Pause();
    event Unpause();
    event PermissionGroupChanged(CreateEntryPermissionGroup);
    event AddedToWhitelist(address);
    event RemovedFromWhitelist(address);
    event AdminshipTransferred(address, address);

     

    constructor()
        public
    { }

     

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyPermissionedToCreateEntries() {
        if (permissionGroup == CreateEntryPermissionGroup.OnlyAdmin) {
            require(msg.sender == admin);
        } else if (permissionGroup == CreateEntryPermissionGroup.Whitelist) {
            require(whitelist[msg.sender] == true || msg.sender == admin);
        }
        _;
    }

     

    function pause()
        external
        onlyAdmin
        whenNotPaused
    {
        paused = true;
        emit Pause();
    }

    function unpause()
        external
        onlyAdmin
        whenPaused
    {
        paused = false;
        emit Unpause();
    }

    function transferAdminRights(address _newAdmin)
        external
        onlyOwner
        whenPaused
    {
        require(_newAdmin != address(0));
        emit AdminshipTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }

    function updateCreateEntryPermissionGroup(CreateEntryPermissionGroup _newPermissionGroup)
        external
        onlyAdmin
        whenPaused
    {
        require(CreateEntryPermissionGroup.AllUsers >= _newPermissionGroup);
        
        permissionGroup = _newPermissionGroup;
        emit PermissionGroupChanged(_newPermissionGroup);
    }

    function addToWhitelist(address _address)
        external
        onlyAdmin
        whenPaused
    {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeFromWhitelist(address _address)
        external
        onlyAdmin
        whenPaused
    {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function getAdmin()
        external
        view
        returns (address)
    {
        return admin;
    }

    function getDatabasePermissions()
        external
        view
        returns (CreateEntryPermissionGroup)
    {
        return permissionGroup;
    }

    function checkWhitelisting(address _address)
        external
        view
        returns (bool)
    {
        return whitelist[_address];
    }
    
    function getPaused()
        external
        view
        returns (bool)
    {
        return paused;
    }
}

 

contract FeeSplitterDatabase is PaymentSplitter, DatabasePermissionControl {
    
    event PayeeAddressChanged(
        uint8 payeeIndex, 
        address oldAddress, 
        address newAddress
    );
    event PayeesDeleted();

    constructor(address[] _payees, uint256[] _shares)
        public
        payable
        PaymentSplitter(_payees, _shares)
    { }
    
    function ()
        external
        payable
        whenNotPaused
    {
        emit PaymentReceived(msg.sender, msg.value);
    }
    
    function changePayeeAddress(uint8 _payeeIndex, address _newAddress)
        external
        whenNotPaused
    {
        require(_payeeIndex < 8);
        require(msg.sender == payees[_payeeIndex]);
        require(payees[_payeeIndex] != _newAddress);
        
        address oldAddress = payees[_payeeIndex];

        shares[_newAddress] = shares[oldAddress];
        released[_newAddress] = released[oldAddress];
        payees[_payeeIndex] = _newAddress;

        delete shares[oldAddress];
        delete released[oldAddress];

        emit PayeeAddressChanged(_payeeIndex, oldAddress, _newAddress);
    }
    
    function setPayess(address[] _payees, uint256[] _shares)
        external
        whenPaused
        onlyAdmin
    {
        _initializePayess(_payees, _shares);
    }
    
    function deletePayees()
        external
        whenPaused
        onlyOwner
    {
        for (uint8 i = 0; i < payees.length; i++) {
            address account = payees[i];
            delete shares[account];
            delete released[account];
        }
        payees.length = 0;
        totalShares = 0;
        totalReleased = 0;
        
        emit PayeesDeleted();
    }
}

 

 
contract DatabaseV1 is IDatabase, Ownable, DatabasePermissionControl, SupportsInterfaceWithLookup, FeeSplitterDatabase, ERC721Token {

    using SafeMath for uint256;

     
    
    bytes4 private constant INTERFACE_SCHEMA_EULER_ID = 0x153366ed;
    bytes4 private constant INTERFACE_DATABASE_V1_EULER_ID = 0xf2c320c4;

     
    struct EntryMeta {
        address creator;
        uint256 createdAt;
        uint256 lastUpdateTime;
        uint256 currentWei;
        uint256 accumulatedWei;
    }

    EntryMeta[] private entriesMeta;
    Safe private databaseSafe;

    uint256 private headTokenID = 0;
    uint256 private entryCreationFeeWei = 0;

    bytes32[] private databaseTags;
    string private databaseDescription;
    
    string private schemaDefinition;
    ISchema private entriesStorage;
    bool private databaseInitStatus = false;

     

    modifier onlyOwnerOf(uint256 _entryID){
        require(ownerOf(_entryID) == msg.sender);
        _;
    }

    modifier databaseInitialized {
        require(databaseInitStatus == true);
        _;
    }

     

    event EntryCreated(uint256 entryID, address creator);
    event EntryDeleted(uint256 entryID, address owner);
    event EntryFunded(
        uint256 entryID,
        address funder,
        uint256 amount
    );
    event EntryFundsClaimed(
        uint256 entryID,
        address claimer,
        uint256 amount
    );
    event EntryCreationFeeUpdated(uint256 newFees);
    event DescriptionUpdated(string newDescription);
    event DatabaseInitialized();
    event TagAdded(bytes32 tag);
    event TagUpdated(uint8 index, bytes32 tag);
    event TagDeleted(uint8 index);

     

    constructor(
        address[] _beneficiaries,
        uint256[] _shares,
        string _name,
        string _symbol
    )
        ERC721Token (_name, _symbol)
        FeeSplitterDatabase (_beneficiaries, _shares)
        public
        payable
    {
        _registerInterface(INTERFACE_DATABASE_V1_EULER_ID);
        databaseSafe = new Safe();
    }

     

    function createEntry()
        external
        databaseInitialized
        onlyPermissionedToCreateEntries
        whenNotPaused
        payable
        returns (uint256)
    {
        require(msg.value == entryCreationFeeWei);

        EntryMeta memory meta = (EntryMeta(
        {
            lastUpdateTime: block.timestamp,
            createdAt: block.timestamp,
            creator: msg.sender,
            currentWei: 0,
            accumulatedWei: 0
        }));
        entriesMeta.push(meta);

        uint256 newTokenID = headTokenID;
        super._mint(msg.sender, newTokenID);
        headTokenID = headTokenID.add(1);

        emit EntryCreated(newTokenID, msg.sender);

        entriesStorage.createEntry();

        return newTokenID;
    }

    function auth(uint256 _entryID, address _caller)
        external
        whenNotPaused
    {
        require(msg.sender == address(entriesStorage));
        require(ownerOf(_entryID) == _caller);
        uint256 entryIndex = allTokensIndex[_entryID];
        entriesMeta[entryIndex].lastUpdateTime = block.timestamp;
    }

    function deleteEntry(uint256 _entryID)
        external
        databaseInitialized
        onlyOwnerOf(_entryID)
        whenNotPaused
    {
        uint256 entryIndex = allTokensIndex[_entryID];
        require(entriesMeta[entryIndex].currentWei == 0);

        uint256 lastEntryIndex = entriesMeta.length.sub(1);
        EntryMeta memory lastEntry = entriesMeta[lastEntryIndex];

        entriesMeta[entryIndex] = lastEntry;
        delete entriesMeta[lastEntryIndex];
        entriesMeta.length--;

        super._burn(msg.sender, _entryID);
        emit EntryDeleted(_entryID, msg.sender);

        entriesStorage.deleteEntry(entryIndex);
    }

    function fundEntry(uint256 _entryID)
        external
        databaseInitialized
        whenNotPaused
        payable
    {
        require(exists(_entryID) == true);

        uint256 entryIndex = allTokensIndex[_entryID];
        uint256 currentWei = entriesMeta[entryIndex].currentWei.add(msg.value);
        entriesMeta[entryIndex].currentWei = currentWei;

        uint256 accumulatedWei = entriesMeta[entryIndex].accumulatedWei.add(msg.value);
        entriesMeta[entryIndex].accumulatedWei = accumulatedWei;

        emit EntryFunded(_entryID, msg.sender, msg.value);
        address(databaseSafe).transfer(msg.value);
    }

    function claimEntryFunds(uint256 _entryID, uint256 _amount)
        external
        databaseInitialized
        onlyOwnerOf(_entryID)
        whenNotPaused
    {
        uint256 entryIndex = allTokensIndex[_entryID];

        uint256 currentWei = entriesMeta[entryIndex].currentWei;
        require(_amount <= currentWei);
        entriesMeta[entryIndex].currentWei = currentWei.sub(_amount);

        emit EntryFundsClaimed(_entryID, msg.sender, _amount);
        databaseSafe.claim(msg.sender, _amount);
    }

    function updateEntryCreationFee(uint256 _newFee)
        external
        onlyAdmin
        whenPaused
    {
        entryCreationFeeWei = _newFee;
        emit EntryCreationFeeUpdated(_newFee);
    }

    function updateDatabaseDescription(string _newDescription)
        external
        onlyAdmin
    {
        databaseDescription = _newDescription;
        emit DescriptionUpdated(_newDescription);
    }

    function addDatabaseTag(bytes32 _tag)
        external
        onlyAdmin
    {
        require(databaseTags.length < 16);
        databaseTags.push(_tag);    
        emit TagAdded(_tag);
    }

    function updateDatabaseTag(uint8 _index, bytes32 _tag)
        external
        onlyAdmin
    {
        require(_index < databaseTags.length);
        databaseTags[_index] = _tag;    
        emit TagUpdated(_index, _tag);
    }

    function removeDatabaseTag(uint8 _index)
        external
        onlyAdmin
    {
        require(databaseTags.length > 0);
        require(_index < databaseTags.length);

        uint256 lastTagIndex = databaseTags.length.sub(1);
        bytes32 lastTag = databaseTags[lastTagIndex];

        databaseTags[_index] = lastTag;
        databaseTags[lastTagIndex] = "";
        databaseTags.length--;
        
        emit TagDeleted(_index);
    }

     

    function readEntryMeta(uint256 _entryID)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(exists(_entryID) == true);
        uint256 entryIndex = allTokensIndex[_entryID];

        EntryMeta memory m = entriesMeta[entryIndex];
        return(
            ownerOf(_entryID),
            m.creator,
            m.createdAt,
            m.lastUpdateTime,
            m.currentWei,
            m.accumulatedWei
        );
    }

    function getChaingearID()
        external
        view
        returns(uint256)
    {
        return IChaingear(owner).getDatabaseIDByAddress(address(this));
    }

    function getEntriesIDs()
        external
        view
        returns (uint256[])
    {
        return allTokens;
    }

    function getIndexByID(uint256 _entryID)
        external
        view
        returns (uint256)
    {
        require(exists(_entryID) == true);
        return allTokensIndex[_entryID];
    }

    function getEntryCreationFee()
        external
        view
        returns (uint256)
    {
        return entryCreationFeeWei;
    }

    function getEntriesStorage()
        external
        view
        returns (address)
    {
        return address(entriesStorage);
    }
    
    function getSchemaDefinition()
        external
        view
        returns (string)
    {
        return schemaDefinition;
    }

    function getDatabaseBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function getDatabaseDescription()
        external
        view
        returns (string)
    {
        return databaseDescription;
    }

    function getDatabaseTags()
        external
        view
        returns (bytes32[])
    {
        return databaseTags;
    }

    function getDatabaseSafe()
        external
        view
        returns (address)
    {
        return databaseSafe;
    }

    function getSafeBalance()
        external
        view
        returns (uint256)
    {
        return address(databaseSafe).balance;
    }

    function getDatabaseInitStatus()
        external
        view
        returns (bool)
    {
        return databaseInitStatus;
    }

     
    
    function initializeDatabase(string _schemaDefinition, bytes _schemaBytecode)
        public
        onlyAdmin
        whenPaused
        returns (address)
    {
        require(databaseInitStatus == false);
        address deployedAddress;

        assembly {
            let s := mload(_schemaBytecode)
            let p := add(_schemaBytecode, 0x20)
            deployedAddress := create(0, p, s)
        }

        require(deployedAddress != address(0));
        require(SupportsInterfaceWithLookup(deployedAddress).supportsInterface(INTERFACE_SCHEMA_EULER_ID));
        entriesStorage = ISchema(deployedAddress);
    
        schemaDefinition = _schemaDefinition;
        databaseInitStatus = true;

        emit DatabaseInitialized();
        return deployedAddress;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        databaseInitialized
        whenNotPaused
    {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        databaseInitialized
        whenNotPaused
    {
        safeTransferFrom(
            _from,
            _to,
            _tokenId,
            ""
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public
        databaseInitialized
        whenNotPaused
    {
        transferFrom(_from, _to, _tokenId);
        require(
            checkAndCallSafeTransfer(
                _from,
                _to,
                _tokenId,
                _data
        ));
    }
}