 

pragma solidity ^0.4.24;

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

 
contract ERC721Basic is ERC165 {
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

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}

 

 
contract ERC165Support is ERC165 {

  bytes4 internal constant InterfaceId_ERC165 = 0x01ffc9a7;
   

  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool) 
  {
    return _supportsInterface(_interfaceId);
  }

  function _supportsInterface(bytes4 _interfaceId)
    internal
    view
    returns (bool) 
  {
    return _interfaceId == InterfaceId_ERC165;
  }
}

 

 
contract ERC721BasicToken is ERC165Support, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  function _supportsInterface(bytes4 _interfaceId)
    internal
    view
    returns (bool)
  {
    return super._supportsInterface(_interfaceId) || 
      _interfaceId == InterfaceId_ERC721 || _interfaceId == InterfaceId_ERC721Exists;
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
    canTransfer(_tokenId)
  {
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
    canTransfer(_tokenId)
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
    canTransfer(_tokenId)
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

 

 
contract Migratable {
   
  event Migrated(string contractName, string migrationId);

   
  mapping (string => mapping (string => bool)) internal migrated;

   
  string constant private INITIALIZED_ID = "initialized";


   
  modifier isInitializer(string contractName, string migrationId) {
    validateMigrationIsPending(contractName, INITIALIZED_ID);
    validateMigrationIsPending(contractName, migrationId);
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
    migrated[contractName][INITIALIZED_ID] = true;
  }

   
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId), "Prerequisite migration ID has not been run yet");
    validateMigrationIsPending(contractName, newMigrationId);
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

   
  function isMigrated(string contractName, string migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }

   
  function initialize() isInitializer("Migratable", "1.2.1") public {
  }

   
  function validateMigrationIsPending(string contractName, string migrationId) private view {
    require(!isMigrated(contractName, migrationId), "Requested target migration ID has already been run");
  }
}

 

 
contract ERC721Token is Migratable, ERC165Support, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  function initialize(string _name, string _symbol) public isInitializer("ERC721Token", "1.9.0") {
    name_ = _name;
    symbol_ = _symbol;
  }

  function _supportsInterface(bytes4 _interfaceId)
    internal
    view
    returns (bool)
  {
    return super._supportsInterface(_interfaceId) || 
      _interfaceId == InterfaceId_ERC721Enumerable || _interfaceId == InterfaceId_ERC721Metadata;
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
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

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

 

 
contract Ownable is Migratable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function initialize(address _sender) public isInitializer("Ownable", "1.9.0") {
    owner = _sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract IEstateRegistry {
  function mint(address to, string metadata) external returns (uint256);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);  

   

  event CreateEstate(
    address indexed _owner,
    uint256 indexed _estateId,
    string _data
  );

  event AddLand(
    uint256 indexed _estateId,
    uint256 indexed _landId
  );

  event RemoveLand(
    uint256 indexed _estateId,
    uint256 indexed _landId,
    address indexed _destinatary
  );

  event Update(
    uint256 indexed _assetId,
    address indexed _holder,
    address indexed _operator,
    string _data
  );

  event UpdateOperator(
    uint256 indexed _estateId,
    address indexed _operator
  );

  event UpdateManager(
    address indexed _owner,
    address indexed _operator,
    address indexed _caller,
    bool _approved
  );

  event SetLANDRegistry(
    address indexed _registry
  );
}

 

contract LANDRegistry {
  function decodeTokenId(uint value) external pure returns (int, int);
  function updateLandData(int x, int y, string data) external;
  function setUpdateOperator(uint256 assetId, address operator) external;
  function setManyUpdateOperator(uint256[] landIds, address operator) external;
  function ping() public;
  function ownerOf(uint256 tokenId) public returns (address);
  function safeTransferFrom(address, address, uint256) public;
  function updateOperator(uint256 landId) public returns (address);
}


contract EstateStorage {
  bytes4 internal constant InterfaceId_GetMetadata = bytes4(keccak256("getMetadata(uint256)"));
  bytes4 internal constant InterfaceId_VerifyFingerprint = bytes4(
    keccak256("verifyFingerprint(uint256,bytes)")
  );

  LANDRegistry public registry;

   
  mapping(uint256 => uint256[]) public estateLandIds;

   
  mapping(uint256 => uint256) public landIdEstate;

   
  mapping(uint256 => mapping(uint256 => uint256)) public estateLandIndex;

   
  mapping(uint256 => string) internal estateData;

   
  mapping (uint256 => address) public updateOperator;

   
  mapping(address => mapping(address => bool)) public updateManager;

}

 

 
 
contract EstateRegistry is Migratable, IEstateRegistry, ERC721Token, ERC721Receiver, Ownable, EstateStorage {
  modifier canTransfer(uint256 estateId) {
    require(isApprovedOrOwner(msg.sender, estateId), "Only owner or operator can transfer");
    _;
  }

  modifier onlyRegistry() {
    require(msg.sender == address(registry), "Only the registry can make this operation");
    _;
  }

  modifier onlyUpdateAuthorized(uint256 estateId) {
    require(_isUpdateAuthorized(msg.sender, estateId), "Unauthorized user");
    _;
  }

  modifier onlyLandUpdateAuthorized(uint256 estateId, uint256 landId) {
    require(_isLandUpdateAuthorized(msg.sender, estateId, landId), "unauthorized user");
    _;
  }

  modifier canSetUpdateOperator(uint256 estateId) {
    address owner = ownerOf(estateId);
    require(
      isApprovedOrOwner(msg.sender, estateId) || updateManager[owner][msg.sender],
      "unauthorized user"
    );
    _;
  }

   
  function mint(address to, string metadata) external onlyRegistry returns (uint256) {
    return _mintEstate(to, metadata);
  }

   
  function transferLand(
    uint256 estateId,
    uint256 landId,
    address destinatary
  )
    external
    canTransfer(estateId)
  {
    return _transferLand(estateId, landId, destinatary);
  }

   
  function transferManyLands(
    uint256 estateId,
    uint256[] landIds,
    address destinatary
  )
    external
    canTransfer(estateId)
  {
    uint length = landIds.length;
    for (uint i = 0; i < length; i++) {
      _transferLand(estateId, landIds[i], destinatary);
    }
  }

   
  function getLandEstateId(uint256 landId) external view returns (uint256) {
    return landIdEstate[landId];
  }

  function setLANDRegistry(address _registry) external onlyOwner {
    require(_registry.isContract(), "The LAND registry address should be a contract");
    require(_registry != 0, "The LAND registry address should be valid");
    registry = LANDRegistry(_registry);
    emit SetLANDRegistry(registry);
  }

  function ping() external {
    registry.ping();
  }

   
  function getEstateSize(uint256 estateId) external view returns (uint256) {
    return estateLandIds[estateId].length;
  }

   
  function updateMetadata(
    uint256 estateId,
    string metadata
  )
    external
    onlyUpdateAuthorized(estateId)
  {
    _updateMetadata(estateId, metadata);

    emit Update(
      estateId,
      ownerOf(estateId),
      msg.sender,
      metadata
    );
  }

  function getMetadata(uint256 estateId) external view returns (string) {
    return estateData[estateId];
  }

  function isUpdateAuthorized(address operator, uint256 estateId) external view returns (bool) {
    return _isUpdateAuthorized(operator, estateId);
  }

   
  function setUpdateManager(address _owner, address _operator, bool _approved) external {
    require(_operator != msg.sender, "The operator should be different from owner");
    require(
      _owner == msg.sender
      || operatorApprovals[_owner][msg.sender],
      "Unauthorized user"
    );

    updateManager[_owner][_operator] = _approved;

    emit UpdateManager(
      _owner,
      _operator,
      msg.sender,
      _approved
    );
  }

   
  function setUpdateOperator(
    uint256 estateId,
    address operator
  )
    public
    canSetUpdateOperator(estateId)
  {
    updateOperator[estateId] = operator;
    emit UpdateOperator(estateId, operator);
  }

   
  function setManyUpdateOperator(
    uint256[] _estateIds,
    address _operator
  )
    public
  {
    for (uint i = 0; i < _estateIds.length; i++) {
      setUpdateOperator(_estateIds[i], _operator);
    }
  }

   
  function setLandUpdateOperator(
    uint256 estateId,
    uint256 landId,
    address operator
  )
    public
    canSetUpdateOperator(estateId)
  {
    require(landIdEstate[landId] == estateId, "The LAND is not part of the Estate");
    registry.setUpdateOperator(landId, operator);
  }

  
  function setManyLandUpdateOperator(
    uint256 _estateId,
    uint256[] _landIds,
    address _operator
  )
    public
    canSetUpdateOperator(_estateId)
  {
    for (uint i = 0; i < _landIds.length; i++) {
      require(landIdEstate[_landIds[i]] == _estateId, "The LAND is not part of the Estate");
    }
    registry.setManyUpdateOperator(_landIds, _operator);
  }

  function initialize(
    string _name,
    string _symbol,
    address _registry
  )
    public
    isInitializer("EstateRegistry", "0.0.2")
  {
    require(_registry != 0, "The registry should be a valid address");

    ERC721Token.initialize(_name, _symbol);
    Ownable.initialize(msg.sender);
    registry = LANDRegistry(_registry);
  }

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    onlyRegistry
    returns (bytes4)
  {
    uint256 estateId = _bytesToUint(_data);
    _pushLandId(estateId, _tokenId);
    return ERC721_RECEIVED;
  }

   
  function getFingerprint(uint256 estateId)
    public
    view
    returns (bytes32 result)
  {
    result = keccak256(abi.encodePacked("estateId", estateId));

    uint256 length = estateLandIds[estateId].length;
    for (uint i = 0; i < length; i++) {
      result ^= keccak256(abi.encodePacked(estateLandIds[estateId][i]));
    }
    return result;
  }

   
  function verifyFingerprint(uint256 estateId, bytes fingerprint) public view returns (bool) {
    return getFingerprint(estateId) == _bytesToBytes32(fingerprint);
  }

   
  function safeTransferManyFrom(address from, address to, uint256[] estateIds) public {
    safeTransferManyFrom(
      from,
      to,
      estateIds,
      ""
    );
  }

   
  function safeTransferManyFrom(
    address from,
    address to,
    uint256[] estateIds,
    bytes data
  )
    public
  {
    for (uint i = 0; i < estateIds.length; i++) {
      safeTransferFrom(
        from,
        to,
        estateIds[i],
        data
      );
    }
  }

   
  function updateLandData(uint256 estateId, uint256 landId, string data) public {
    _updateLandData(estateId, landId, data);
  }

   
  function updateManyLandData(uint256 estateId, uint256[] landIds, string data) public {
    uint length = landIds.length;
    for (uint i = 0; i < length; i++) {
      _updateLandData(estateId, landIds[i], data);
    }
  }

  function transferFrom(address _from, address _to, uint256 _tokenId)
  public
  {
    updateOperator[_tokenId] = address(0);
    super.transferFrom(_from, _to, _tokenId);
  }

   
  function _supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
     
    return super._supportsInterface(_interfaceId)
      || _interfaceId == InterfaceId_GetMetadata
      || _interfaceId == InterfaceId_VerifyFingerprint;
  }

   
  function _mintEstate(address to, string metadata) internal returns (uint256) {
    require(to != address(0), "You can not mint to an empty address");
    uint256 estateId = _getNewEstateId();
    _mint(to, estateId);
    _updateMetadata(estateId, metadata);
    emit CreateEstate(to, estateId, metadata);
    return estateId;
  }

   
  function _updateMetadata(uint256 estateId, string metadata) internal {
    estateData[estateId] = metadata;
  }

   
  function _getNewEstateId() internal view returns (uint256) {
    return totalSupply().add(1);
  }

   
  function _pushLandId(uint256 estateId, uint256 landId) internal {
    require(exists(estateId), "The Estate id should exist");
    require(landIdEstate[landId] == 0, "The LAND is already owned by an Estate");
    require(registry.ownerOf(landId) == address(this), "The EstateRegistry cannot manage the LAND");

    estateLandIds[estateId].push(landId);

    landIdEstate[landId] = estateId;

    estateLandIndex[estateId][landId] = estateLandIds[estateId].length;

    emit AddLand(estateId, landId);
  }

   
  function _transferLand(
    uint256 estateId,
    uint256 landId,
    address destinatary
  )
    internal
  {
    require(destinatary != address(0), "You can not transfer LAND to an empty address");

    uint256[] storage landIds = estateLandIds[estateId];
    mapping(uint256 => uint256) landIndex = estateLandIndex[estateId];

     
    require(landIndex[landId] != 0, "The LAND is not part of the Estate");

    uint lastIndexInArray = landIds.length.sub(1);

     
    uint indexInArray = landIndex[landId].sub(1);

     
    uint tempTokenId = landIds[lastIndexInArray];

     
    landIndex[tempTokenId] = indexInArray.add(1);
    landIds[indexInArray] = tempTokenId;

     
    delete landIds[lastIndexInArray];
    landIds.length = lastIndexInArray;

     
    landIndex[landId] = 0;

     
    landIdEstate[landId] = 0;

    registry.safeTransferFrom(this, destinatary, landId);

    emit RemoveLand(estateId, landId, destinatary);
  }

  function _isUpdateAuthorized(address operator, uint256 estateId) internal view returns (bool) {
    address owner = ownerOf(estateId);

    return isApprovedOrOwner(operator, estateId)
      || updateOperator[estateId] == operator
      || updateManager[owner][operator];
  }

  function _isLandUpdateAuthorized(
    address operator,
    uint256 estateId,
    uint256 landId
  )
    internal returns (bool)
  {
    return _isUpdateAuthorized(operator, estateId) || registry.updateOperator(landId) == operator;
  }

  function _bytesToUint(bytes b) internal pure returns (uint256) {
    return uint256(_bytesToBytes32(b));
  }

  function _bytesToBytes32(bytes b) internal pure returns (bytes32) {
    bytes32 out;

    for (uint i = 0; i < b.length; i++) {
      out |= bytes32(b[i] & 0xFF) >> i.mul(8);
    }

    return out;
  }

  function _updateLandData(
    uint256 estateId,
    uint256 landId,
    string data
  )
    internal
    onlyLandUpdateAuthorized(estateId, landId)
  {
    require(landIdEstate[landId] == estateId, "The LAND is not part of the Estate");
    int x;
    int y;
    (x, y) = registry.decodeTokenId(landId);
    registry.updateLandData(x, y, data);
  }
}