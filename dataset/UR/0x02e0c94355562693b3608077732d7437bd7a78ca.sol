 

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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
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

 

contract FeeSplitterChaingear is PaymentSplitter, Ownable {
    
    event PayeeAddressChanged(
        uint8 payeeIndex, 
        address oldAddress, 
        address newAddress
    );

    constructor(address[] _payees, uint256[] _shares)
        public
        payable
        PaymentSplitter(_payees, _shares)
    { }
    
    function changePayeeAddress(uint8 _payeeIndex, address _newAddress)
        external
        onlyOwner
    {
        require(_payeeIndex < 12);
        require(payees[_payeeIndex] != _newAddress);
        
        address oldAddress = payees[_payeeIndex];
        shares[_newAddress] = shares[oldAddress];
        released[_newAddress] = released[oldAddress];
        payees[_payeeIndex] = _newAddress;

        delete shares[oldAddress];
        delete released[oldAddress];

        emit PayeeAddressChanged(_payeeIndex, oldAddress, _newAddress);
    }

}

 

library ERC721MetadataValidation {

    function validateName(string _base) 
        internal
        pure
    {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            require(_baseBytes[i] >= 0x61 && _baseBytes[i] <= 0x7A || _baseBytes[i] >= 0x30 && _baseBytes[i] <= 0x39 || _baseBytes[i] == 0x2D);
        }
    }

    function validateSymbol(string _base) 
        internal
        pure
    {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            require(_baseBytes[i] >= 0x41 && _baseBytes[i] <= 0x5A || _baseBytes[i] >= 0x30 && _baseBytes[i] <= 0x39);
        }
    }
}

 

 
contract Chaingear is IChaingear, Ownable, SupportsInterfaceWithLookup, Pausable, FeeSplitterChaingear, ERC721Token {

    using SafeMath for uint256;
    using ERC721MetadataValidation for string;

     

    struct DatabaseMeta {
        IDatabase databaseContract;
        address creatorOfDatabase;
        string versionOfDatabase;
        string linkABI;
        uint256 createdTimestamp;
        uint256 currentWei;
        uint256 accumulatedWei;
    }

    struct DatabaseBuilder {
        IDatabaseBuilder builderAddress;
        string linkToABI;
        string description;
        bool operational;
    }

    DatabaseMeta[] private databases;
    mapping(string => bool) private databasesNamesIndex;
    mapping(string => bool) private databasesSymbolsIndex;

    uint256 private headTokenID = 0;
    mapping(address => uint256) private databasesIDsByAddressesIndex;
    mapping(string => address) private databasesAddressesByNameIndex;
    mapping(uint256 => string) private databasesSymbolsByIDIndex;
    mapping(string => uint256) private databasesIDsBySymbolIndex;

    uint256 private amountOfBuilders = 0;
    mapping(uint256 => string) private buildersVersionIndex;
    mapping(string => DatabaseBuilder) private buildersVersion;

    Safe private chaingearSafe;
    uint256 private databaseCreationFeeWei = 10 ether;

    string private constant CHAINGEAR_DESCRIPTION = "The novel Ethereum database framework";
    bytes4 private constant INTERFACE_CHAINGEAR_EULER_ID = 0xea1db66f; 
    bytes4 private constant INTERFACE_DATABASE_V1_EULER_ID = 0xf2c320c4;
    bytes4 private constant INTERFACE_DATABASE_BUILDER_EULER_ID = 0xce8bbf93;
    
     
    event DatabaseBuilderAdded(
        string version,
        IDatabaseBuilder builderAddress,
        string linkToABI,
        string description
    );
    event DatabaseDescriptionUpdated(string version, string description);
    event DatabaseBuilderDepricated(string version);
    event DatabaseCreated(
        string name,
        address databaseAddress,
        address creatorAddress,
        uint256 databaseChaingearID
    );
    event DatabaseDeleted(
        string name,
        address databaseAddress,
        address creatorAddress,
        uint256 databaseChaingearID
    );
    event DatabaseFunded(
        uint256 databaseID,
        address sender,
        uint256 amount
    );
    event DatabaseFundsClaimed(
        uint256 databaseID,
        address claimer,
        uint256 amount
    );    
    event CreationFeeUpdated(uint256 newFee);

     

    constructor(address[] _beneficiaries, uint256[] _shares)
        public
        ERC721Token ("CHAINGEAR", "CHG")
        FeeSplitterChaingear (_beneficiaries, _shares)
    {
        chaingearSafe = new Safe();
        _registerInterface(INTERFACE_CHAINGEAR_EULER_ID);
    }

     

    modifier onlyOwnerOf(uint256 _databaseID){
        require(ownerOf(_databaseID) == msg.sender);
        _;
    }

     

    function addDatabaseBuilderVersion(
        string _version,
        IDatabaseBuilder _builderAddress,
        string _linkToABI,
        string _description
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(buildersVersion[_version].builderAddress == address(0));

        SupportsInterfaceWithLookup support = SupportsInterfaceWithLookup(_builderAddress);
        require(support.supportsInterface(INTERFACE_DATABASE_BUILDER_EULER_ID));

        buildersVersion[_version] = (DatabaseBuilder(
        {
            builderAddress: _builderAddress,
            linkToABI: _linkToABI,
            description: _description,
            operational: true
        }));
        buildersVersionIndex[amountOfBuilders] = _version;
        amountOfBuilders = amountOfBuilders.add(1);
        
        emit DatabaseBuilderAdded(
            _version,
            _builderAddress,
            _linkToABI,
            _description
        );
    }

    function updateDatabaseBuilderDescription(string _version, string _description)
        external
        onlyOwner
        whenNotPaused
    {
        require(buildersVersion[_version].builderAddress != address(0));
        buildersVersion[_version].description = _description;    
        emit DatabaseDescriptionUpdated(_version, _description);
    }
    
    function depricateDatabaseBuilder(string _version)
        external
        onlyOwner
        whenPaused
    {
        require(buildersVersion[_version].builderAddress != address(0));
        require(buildersVersion[_version].operational == true);
        buildersVersion[_version].operational = false;
        emit DatabaseBuilderDepricated(_version);
    }

    function createDatabase(
        string    _version,
        address[] _beneficiaries,
        uint256[] _shares,
        string    _name,
        string    _symbol
    )
        external
        payable
        whenNotPaused
        returns (address, uint256)
    {
        _name.validateName();
        _symbol.validateSymbol();
        require(buildersVersion[_version].builderAddress != address(0));
        require(buildersVersion[_version].operational == true);
        require(databaseCreationFeeWei == msg.value);
        require(databasesNamesIndex[_name] == false);
        require(databasesSymbolsIndex[_symbol] == false);

        return _deployDatabase(
            _version,
            _beneficiaries,
            _shares,
            _name,
            _symbol
        );
    }

    function deleteDatabase(uint256 _databaseID)
        external
        onlyOwnerOf(_databaseID)
        whenNotPaused
    {
        uint256 databaseIndex = allTokensIndex[_databaseID];
        IDatabase database = databases[databaseIndex].databaseContract;
        require(database.getSafeBalance() == uint256(0));
        require(database.getPaused() == true);
        
        string memory databaseName = ERC721(database).name();
        string memory databaseSymbol = ERC721(database).symbol();
        
        delete databasesNamesIndex[databaseName];
        delete databasesSymbolsIndex[databaseSymbol];
        delete databasesIDsByAddressesIndex[database];  
        delete databasesIDsBySymbolIndex[databaseSymbol];
        delete databasesSymbolsByIDIndex[_databaseID];

        uint256 lastDatabaseIndex = databases.length.sub(1);
        DatabaseMeta memory lastDatabase = databases[lastDatabaseIndex];
        databases[databaseIndex] = lastDatabase;
        delete databases[lastDatabaseIndex];
        databases.length--;

        super._burn(msg.sender, _databaseID);
        database.transferOwnership(msg.sender);
        
        emit DatabaseDeleted(
            databaseName,
            database,
            msg.sender,
            _databaseID
        );
    }

    function fundDatabase(uint256 _databaseID)
        external
        whenNotPaused
        payable
    {
        require(exists(_databaseID) == true);
        uint256 databaseIndex = allTokensIndex[_databaseID];

        uint256 currentWei = databases[databaseIndex].currentWei.add(msg.value);
        databases[databaseIndex].currentWei = currentWei;

        uint256 accumulatedWei = databases[databaseIndex].accumulatedWei.add(msg.value);
        databases[databaseIndex].accumulatedWei = accumulatedWei;

        emit DatabaseFunded(_databaseID, msg.sender, msg.value);
        address(chaingearSafe).transfer(msg.value);
    }

    function claimDatabaseFunds(uint256 _databaseID, uint256 _amount)
        external
        onlyOwnerOf(_databaseID)
        whenNotPaused
    {
        uint256 databaseIndex = allTokensIndex[_databaseID];

        uint256 currentWei = databases[databaseIndex].currentWei;
        require(_amount <= currentWei);

        databases[databaseIndex].currentWei = currentWei.sub(_amount);

        emit DatabaseFundsClaimed(_databaseID, msg.sender, _amount);
        chaingearSafe.claim(msg.sender, _amount);
    }

    function updateCreationFee(uint256 _newFee)
        external
        onlyOwner
        whenPaused
    {
        databaseCreationFeeWei = _newFee;
        emit CreationFeeUpdated(_newFee);
    }

     

    function getAmountOfBuilders()
        external
        view
        returns(uint256)
    {
        return amountOfBuilders;
    }

    function getBuilderByID(uint256 _id)
        external
        view
        returns(string)
    {
        return buildersVersionIndex[_id];
    }

    function getDatabaseBuilder(string _version)
        external
        view
        returns (
            address,
            string,
            string,
            bool
        )
    {
        return(
            buildersVersion[_version].builderAddress,
            buildersVersion[_version].linkToABI,
            buildersVersion[_version].description,
            buildersVersion[_version].operational
        );
    }

    function getDatabasesIDs()
        external
        view
        returns(uint256[])
    {
        return allTokens;
    }

    function getDatabaseIDByAddress(address _databaseAddress)
        external
        view
        returns(uint256)
    {
        uint256 databaseID = databasesIDsByAddressesIndex[_databaseAddress];
        return databaseID;
    }
    
    function getDatabaseAddressByName(string _name)
        external
        view
        returns(address)
    {
        return databasesAddressesByNameIndex[_name];
    }

    function getDatabaseSymbolByID(uint256 _databaseID)
        external
        view
        returns(string)
    {
        return databasesSymbolsByIDIndex[_databaseID];
    }

    function getDatabaseIDBySymbol(string _symbol)
        external
        view
        returns(uint256)
    {
        return databasesIDsBySymbolIndex[_symbol];
    }

    function getDatabase(uint256 _databaseID)
        external
        view
        returns (
            string,
            string,
            address,
            string,
            uint256,
            address,
            uint256
        )
    {
        uint256 databaseIndex = allTokensIndex[_databaseID];
        IDatabase databaseAddress = databases[databaseIndex].databaseContract;

        return (
            ERC721(databaseAddress).name(),
            ERC721(databaseAddress).symbol(),
            databaseAddress,
            databases[databaseIndex].versionOfDatabase,
            databases[databaseIndex].createdTimestamp,
            databaseAddress.getAdmin(),
            ERC721(databaseAddress).totalSupply()
        );
    }

    function getDatabaseBalance(uint256 _databaseID)
        external
        view
        returns (uint256, uint256)
    {
        uint256 databaseIndex = allTokensIndex[_databaseID];

        return (
            databases[databaseIndex].currentWei,
            databases[databaseIndex].accumulatedWei
        );
    }

    function getChaingearDescription()
        external
        pure
        returns (string)
    {
        return CHAINGEAR_DESCRIPTION;
    }

    function getCreationFeeWei()
        external
        view
        returns (uint256)
    {
        return databaseCreationFeeWei;
    }

    function getSafeBalance()
        external
        view
        returns (uint256)
    {
        return address(chaingearSafe).balance;
    }

    function getSafeAddress()
        external
        view
        returns (address)
    {
        return chaingearSafe;
    }

    function getNameExist(string _name)
        external
        view
        returns (bool)
    {
        return databasesNamesIndex[_name];
    }

    function getSymbolExist(string _symbol)
        external
        view
        returns (bool)
    {
        return databasesSymbolsIndex[_symbol];
    }

     

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        uint256 databaseIndex = allTokensIndex[_tokenId];
        IDatabase database = databases[databaseIndex].databaseContract;
        require(address(database).balance == 0);
        require(database.getPaused() == true);
        super.transferFrom(_from, _to, _tokenId);
        
        IDatabase databaseAddress = databases[databaseIndex].databaseContract;
        databaseAddress.deletePayees();
        databaseAddress.transferAdminRights(_to);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
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

     

    function _deployDatabase(
        string    _version,
        address[] _beneficiaries,
        uint256[] _shares,
        string    _name,
        string    _symbol
    )
        private
        returns (address, uint256)
    {
        IDatabaseBuilder builder = buildersVersion[_version].builderAddress;
        IDatabase databaseContract = builder.deployDatabase(
            _beneficiaries,
            _shares,
            _name,
            _symbol
        );

        address databaseAddress = address(databaseContract);

        SupportsInterfaceWithLookup support = SupportsInterfaceWithLookup(databaseAddress);
        require(support.supportsInterface(INTERFACE_DATABASE_V1_EULER_ID));
        require(support.supportsInterface(InterfaceId_ERC721));
        require(support.supportsInterface(InterfaceId_ERC721Metadata));
        require(support.supportsInterface(InterfaceId_ERC721Enumerable));

        DatabaseMeta memory database = (DatabaseMeta(
        {
            databaseContract: databaseContract,
            creatorOfDatabase: msg.sender,
            versionOfDatabase: _version,
            linkABI: buildersVersion[_version].linkToABI,
            createdTimestamp: block.timestamp,
            currentWei: 0,
            accumulatedWei: 0
        }));

        databases.push(database);

        databasesNamesIndex[_name] = true;
        databasesSymbolsIndex[_symbol] = true;

        uint256 newTokenID = headTokenID;
        databasesIDsByAddressesIndex[databaseAddress] = newTokenID;
        super._mint(msg.sender, newTokenID);
        databasesSymbolsByIDIndex[newTokenID] = _symbol;
        databasesIDsBySymbolIndex[_symbol] = newTokenID;
        databasesAddressesByNameIndex[_name] = databaseAddress;
        headTokenID = headTokenID.add(1);

        emit DatabaseCreated(
            _name,
            databaseAddress,
            msg.sender,
            newTokenID
        );

        databaseContract.transferAdminRights(msg.sender);
        return (databaseAddress, newTokenID);
    }

}