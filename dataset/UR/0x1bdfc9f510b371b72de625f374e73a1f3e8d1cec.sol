 

pragma solidity 0.4.24;

 
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

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
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

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}



 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}


 
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


 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

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


 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
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

contract CryptantCrabStoreInterface {
  function createAddress(bytes32 key, address value) external returns (bool);
  function createAddresses(bytes32[] keys, address[] values) external returns (bool);
  function updateAddress(bytes32 key, address value) external returns (bool);
  function updateAddresses(bytes32[] keys, address[] values) external returns (bool);
  function removeAddress(bytes32 key) external returns (bool);
  function removeAddresses(bytes32[] keys) external returns (bool);
  function readAddress(bytes32 key) external view returns (address);
  function readAddresses(bytes32[] keys) external view returns (address[]);
   
  function createBool(bytes32 key, bool value) external returns (bool);
  function createBools(bytes32[] keys, bool[] values) external returns (bool);
  function updateBool(bytes32 key, bool value) external returns (bool);
  function updateBools(bytes32[] keys, bool[] values) external returns (bool);
  function removeBool(bytes32 key) external returns (bool);
  function removeBools(bytes32[] keys) external returns (bool);
  function readBool(bytes32 key) external view returns (bool);
  function readBools(bytes32[] keys) external view returns (bool[]);
   
  function createBytes32(bytes32 key, bytes32 value) external returns (bool);
  function createBytes32s(bytes32[] keys, bytes32[] values) external returns (bool);
  function updateBytes32(bytes32 key, bytes32 value) external returns (bool);
  function updateBytes32s(bytes32[] keys, bytes32[] values) external returns (bool);
  function removeBytes32(bytes32 key) external returns (bool);
  function removeBytes32s(bytes32[] keys) external returns (bool);
  function readBytes32(bytes32 key) external view returns (bytes32);
  function readBytes32s(bytes32[] keys) external view returns (bytes32[]);
   
  function createUint256(bytes32 key, uint256 value) external returns (bool);
  function createUint256s(bytes32[] keys, uint256[] values) external returns (bool);
  function updateUint256(bytes32 key, uint256 value) external returns (bool);
  function updateUint256s(bytes32[] keys, uint256[] values) external returns (bool);
  function removeUint256(bytes32 key) external returns (bool);
  function removeUint256s(bytes32[] keys) external returns (bool);
  function readUint256(bytes32 key) external view returns (uint256);
  function readUint256s(bytes32[] keys) external view returns (uint256[]);
   
  function createInt256(bytes32 key, int256 value) external returns (bool);
  function createInt256s(bytes32[] keys, int256[] values) external returns (bool);
  function updateInt256(bytes32 key, int256 value) external returns (bool);
  function updateInt256s(bytes32[] keys, int256[] values) external returns (bool);
  function removeInt256(bytes32 key) external returns (bool);
  function removeInt256s(bytes32[] keys) external returns (bool);
  function readInt256(bytes32 key) external view returns (int256);
  function readInt256s(bytes32[] keys) external view returns (int256[]);
   
  function parseKey(bytes32 key) internal pure returns (bytes32);
  function parseKeys(bytes32[] _keys) internal pure returns (bytes32[]);
}

interface GenesisCrabInterface {
  function generateCrabGene(bool isPresale, bool hasLegendaryPart) external returns (uint256 _gene, uint256 _skin, uint256 _heartValue, uint256 _growthValue);
  function mutateCrabPart(uint256 _part, uint256 _existingPartGene, uint256 _legendaryPercentage) external view returns (uint256);
  function generateCrabHeart() external view returns (uint256, uint256);
}

contract CrabData {
  modifier crabDataLength(uint256[] memory _crabData) {
    require(_crabData.length == 8);
    _;
  }

  struct CrabPartData {
    uint256 hp;
    uint256 dps;
    uint256 blockRate;
    uint256 resistanceBonus;
    uint256 hpBonus;
    uint256 dpsBonus;
    uint256 blockBonus;
    uint256 mutiplierBonus;
  }

  function arrayToCrabPartData(
    uint256[] _partData
  ) 
    internal 
    pure 
    crabDataLength(_partData) 
    returns (CrabPartData memory _parsedData) 
  {
    _parsedData = CrabPartData(
      _partData[0],    
      _partData[1],    
      _partData[2],    
      _partData[3],    
      _partData[4],    
      _partData[5],    
      _partData[6],    
      _partData[7]);   
  }

  function crabPartDataToArray(CrabPartData _crabPartData) internal pure returns (uint256[] memory _resultData) {
    _resultData = new uint256[](8);
    _resultData[0] = _crabPartData.hp;
    _resultData[1] = _crabPartData.dps;
    _resultData[2] = _crabPartData.blockRate;
    _resultData[3] = _crabPartData.resistanceBonus;
    _resultData[4] = _crabPartData.hpBonus;
    _resultData[5] = _crabPartData.dpsBonus;
    _resultData[6] = _crabPartData.blockBonus;
    _resultData[7] = _crabPartData.mutiplierBonus;
  }
}


contract GeneSurgeon {
   
  uint256[] internal crabPartMultiplier = [0, 10**9, 10**6, 10**3, 1];

  function extractElementsFromGene(uint256 _gene) internal view returns (uint256[] memory _elements) {
    _elements = new uint256[](4);
    _elements[0] = _gene / crabPartMultiplier[1] / 100 % 10;
    _elements[1] = _gene / crabPartMultiplier[2] / 100 % 10;
    _elements[2] = _gene / crabPartMultiplier[3] / 100 % 10;
    _elements[3] = _gene / crabPartMultiplier[4] / 100 % 10;
  }

  function extractPartsFromGene(uint256 _gene) internal view returns (uint256[] memory _parts) {
    _parts = new uint256[](4);
    _parts[0] = _gene / crabPartMultiplier[1] % 100;
    _parts[1] = _gene / crabPartMultiplier[2] % 100;
    _parts[2] = _gene / crabPartMultiplier[3] % 100;
    _parts[3] = _gene / crabPartMultiplier[4] % 100;
  }
}

contract CryptantCrabNFT is ERC721Token, Whitelist, CrabData, GeneSurgeon {
  event CrabPartAdded(uint256 hp, uint256 dps, uint256 blockAmount);
  event GiftTransfered(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event DefaultMetadataURIChanged(string newUri);

   
  bytes4 internal constant CRAB_BODY = 0xc398430e;
  bytes4 internal constant CRAB_LEG = 0x889063b1;
  bytes4 internal constant CRAB_LEFT_CLAW = 0xdb6290a2;
  bytes4 internal constant CRAB_RIGHT_CLAW = 0x13453f89;

   
  mapping(bytes4 => mapping(uint256 => CrabPartData[])) internal crabPartData;

   
  mapping(uint256 => uint256) internal crabSpecialSkins;

   
  string public defaultMetadataURI = "https://www.cryptantcrab.io/md/";

  constructor(string _name, string _symbol) public ERC721Token(_name, _symbol) {
     
    initiateCrabPartData();
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));

    string memory _uri = tokenURIs[_tokenId];

    if(bytes(_uri).length == 0) {
      _uri = getMetadataURL(bytes(defaultMetadataURI), _tokenId);
    }

    return _uri;
  }

   
  function dataOfPart(uint256 _partIndex, uint256 _element, uint256 _setIndex) public view returns (uint256[] memory _resultData) {
    bytes4 _key;
    if(_partIndex == 1) {
      _key = CRAB_BODY;
    } else if(_partIndex == 2) {
      _key = CRAB_LEG;
    } else if(_partIndex == 3) {
      _key = CRAB_LEFT_CLAW;
    } else if(_partIndex == 4) {
      _key = CRAB_RIGHT_CLAW;
    } else {
      revert();
    }

    CrabPartData storage _crabPartData = crabPartData[_key][_element][_setIndex];

    _resultData = crabPartDataToArray(_crabPartData);
  }

   
  function giftToken(address _from, address _to, uint256 _tokenId) external {
    safeTransferFrom(_from, _to, _tokenId);

    emit GiftTransfered(_from, _to, _tokenId);
  }

   
  function mintToken(address _tokenOwner, uint256 _tokenId, uint256 _skinId) external onlyIfWhitelisted(msg.sender) {
    super._mint(_tokenOwner, _tokenId);

    if(_skinId > 0) {
      crabSpecialSkins[_tokenId] = _skinId;
    }
  }

   
  function crabPartDataFromGene(uint256 _gene) external view returns (
    uint256[] _bodyData,
    uint256[] _legData,
    uint256[] _leftClawData,
    uint256[] _rightClawData
  ) {
    uint256[] memory _parts = extractPartsFromGene(_gene);
    uint256[] memory _elements = extractElementsFromGene(_gene);

    _bodyData = dataOfPart(1, _elements[0], _parts[0]);
    _legData = dataOfPart(2, _elements[1], _parts[1]);
    _leftClawData = dataOfPart(3, _elements[2], _parts[2]);
    _rightClawData = dataOfPart(4, _elements[3], _parts[3]);
  }

   
  function setPartData(uint256 _partIndex, uint256 _element, uint256[] _partDataArray) external onlyOwner {
    CrabPartData memory _partData = arrayToCrabPartData(_partDataArray);

    bytes4 _key;
    if(_partIndex == 1) {
      _key = CRAB_BODY;
    } else if(_partIndex == 2) {
      _key = CRAB_LEG;
    } else if(_partIndex == 3) {
      _key = CRAB_LEFT_CLAW;
    } else if(_partIndex == 4) {
      _key = CRAB_RIGHT_CLAW;
    }

     
    if(crabPartData[_key][_element][1].hp == 0 && crabPartData[_key][_element][1].dps == 0) {
      crabPartData[_key][_element][1] = _partData;
    } else {
      crabPartData[_key][_element].push(_partData);
    }

    emit CrabPartAdded(_partDataArray[0], _partDataArray[1], _partDataArray[2]);
  }

   
  function setDefaultMetadataURI(string _defaultUri) external onlyOwner {
    defaultMetadataURI = _defaultUri;

    emit DefaultMetadataURIChanged(_defaultUri);
  }

   
  function setTokenURI(uint256 _tokenId, string _uri) external onlyIfWhitelisted(msg.sender) {
    _setTokenURI(_tokenId, _uri);
  }

   
  function specialSkinOfTokenId(uint256 _tokenId) external view returns (uint256) {
    return crabSpecialSkins[_tokenId];
  }

   
  function initiateCrabPartData() internal {
    require(crabPartData[CRAB_BODY][1].length == 0);

    for(uint256 i = 1 ; i <= 5 ; i++) {
      crabPartData[CRAB_BODY][i].length = 2;
      crabPartData[CRAB_LEG][i].length = 2;
      crabPartData[CRAB_LEFT_CLAW][i].length = 2;
      crabPartData[CRAB_RIGHT_CLAW][i].length = 2;
    }
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender) || whitelist(_spender);
  }

   
  function getMetadataURL(bytes _uri, uint256 _tokenId) internal pure returns (string) {
    uint256 _tmpTokenId = _tokenId;
    uint256 _tokenLength;

     
    do {
      _tokenLength++;
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

     
    bytes memory _result = new bytes(_uri.length + _tokenLength);

     
    for(uint256 i = 0 ; i < _uri.length ; i ++) {
      _result[i] = _uri[i];
    }

     
    uint256 lastIndex = _result.length - 1;
    for(_tmpTokenId = _tokenId ; _tmpTokenId > 0 ; _tmpTokenId /= 10) {
      _result[lastIndex--] = byte(48 + _tmpTokenId % 10);
    }

    return string(_result);
  }
}


contract CryptantCrabBase is Ownable {
  GenesisCrabInterface public genesisCrab;
  CryptantCrabNFT public cryptantCrabToken;
  CryptantCrabStoreInterface public cryptantCrabStorage;

  constructor(address _genesisCrabAddress, address _cryptantCrabTokenAddress, address _cryptantCrabStorageAddress) public {
     
    
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);
  }

  function setAddresses(
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  external onlyOwner {
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);
  }

  function _setAddresses(
    address _genesisCrabAddress,
    address _cryptantCrabTokenAddress,
    address _cryptantCrabStorageAddress
  )
  internal 
  {
    if(_genesisCrabAddress != address(0)) {
      GenesisCrabInterface genesisCrabContract = GenesisCrabInterface(_genesisCrabAddress);
      genesisCrab = genesisCrabContract;
    }
    
    if(_cryptantCrabTokenAddress != address(0)) {
      CryptantCrabNFT cryptantCrabTokenContract = CryptantCrabNFT(_cryptantCrabTokenAddress);
      cryptantCrabToken = cryptantCrabTokenContract;
    }
    
    if(_cryptantCrabStorageAddress != address(0)) {
      CryptantCrabStoreInterface cryptantCrabStorageContract = CryptantCrabStoreInterface(_cryptantCrabStorageAddress);
      cryptantCrabStorage = cryptantCrabStorageContract;
    }
  }
}


contract CryptantCrabInformant is CryptantCrabBase{
  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabBase
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
     

  }

  function _getCrabData(uint256 _tokenId) internal view returns 
  (
    uint256 _gene, 
    uint256 _level, 
    uint256 _exp, 
    uint256 _mutationCount,
    uint256 _trophyCount,
    uint256 _heartValue,
    uint256 _growthValue
  ) {
    require(cryptantCrabStorage != address(0));

    bytes32[] memory keys = new bytes32[](7);
    uint256[] memory values;

    keys[0] = keccak256(abi.encodePacked(_tokenId, "gene"));
    keys[1] = keccak256(abi.encodePacked(_tokenId, "level"));
    keys[2] = keccak256(abi.encodePacked(_tokenId, "exp"));
    keys[3] = keccak256(abi.encodePacked(_tokenId, "mutationCount"));
    keys[4] = keccak256(abi.encodePacked(_tokenId, "trophyCount"));
    keys[5] = keccak256(abi.encodePacked(_tokenId, "heartValue"));
    keys[6] = keccak256(abi.encodePacked(_tokenId, "growthValue"));

    values = cryptantCrabStorage.readUint256s(keys);

     
    uint256 _processedHeartValue;
    for(uint256 i = 1 ; i <= 1000 ; i *= 10) {
      if(uint256(values[5]) / i % 10 > 0) {
        _processedHeartValue += i;
      }
    }

    _gene = values[0];
    _level = values[1];
    _exp = values[2];
    _mutationCount = values[3];
    _trophyCount = values[4];
    _heartValue = _processedHeartValue;
    _growthValue = values[6];
  }

  function _geneOfCrab(uint256 _tokenId) internal view returns (uint256 _gene) {
    require(cryptantCrabStorage != address(0));

    _gene = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, "gene")));
  }
}

contract CryptantCrabPurchasable is CryptantCrabInformant {
  using SafeMath for uint256;

  event CrabHatched(address indexed owner, uint256 tokenId, uint256 gene, uint256 specialSkin, uint256 crabPrice, uint256 growthValue);
  event CryptantFragmentsAdded(address indexed cryptantOwner, uint256 amount, uint256 newBalance);
  event CryptantFragmentsRemoved(address indexed cryptantOwner, uint256 amount, uint256 newBalance);
  event Refund(address indexed refundReceiver, uint256 reqAmt, uint256 paid, uint256 refundAmt);

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
     

  }

  function getCryptantFragments(address _sender) public view returns (uint256) {
    return cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_sender, "cryptant")));
  }

  function createCrab(uint256 _customTokenId, uint256 _crabPrice, uint256 _customGene, uint256 _customSkin, uint256 _customHeart, bool _hasLegendary) external onlyOwner {
    return _createCrab(false, _customTokenId, _crabPrice, _customGene, _customSkin, _customHeart, _hasLegendary);
  }

  function _addCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).add(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsAdded(_cryptantOwner, _amount, _newBalance);
  }

  function _removeCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).sub(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsRemoved(_cryptantOwner, _amount, _newBalance);
  }

  function _createCrab(bool _isPresale, uint256 _tokenId, uint256 _crabPrice, uint256 _customGene, uint256 _customSkin, uint256 _customHeart, bool _hasLegendary) internal {
    uint256[] memory _values = new uint256[](4);
    bytes32[] memory _keys = new bytes32[](4);

    uint256 _gene;
    uint256 _specialSkin;
    uint256 _heartValue;
    uint256 _growthValue;
    if(_customGene == 0) {
      (_gene, _specialSkin, _heartValue, _growthValue) = genesisCrab.generateCrabGene(_isPresale, _hasLegendary);
    } else {
      _gene = _customGene;
    }

    if(_customSkin != 0) {
      _specialSkin = _customSkin;
    }

    if(_customHeart != 0) {
      _heartValue = _customHeart;
    } else if (_heartValue == 0) {
      (_heartValue, _growthValue) = genesisCrab.generateCrabHeart();
    }
    
    cryptantCrabToken.mintToken(msg.sender, _tokenId, _specialSkin);

     
    _keys[0] = keccak256(abi.encodePacked(_tokenId, "gene"));
    _values[0] = _gene;

     
    _keys[1] = keccak256(abi.encodePacked(_tokenId, "level"));
    _values[1] = 1;

     
    _keys[2] = keccak256(abi.encodePacked(_tokenId, "heartValue"));
    _values[2] = _heartValue;

     
    _keys[3] = keccak256(abi.encodePacked(_tokenId, "growthValue"));
    _values[3] = _growthValue;

    require(cryptantCrabStorage.createUint256s(_keys, _values));

    emit CrabHatched(msg.sender, _tokenId, _gene, _specialSkin, _crabPrice, _growthValue);
  }

  function _refundExceededValue(uint256 _senderValue, uint256 _requiredValue) internal {
    uint256 _exceededValue = _senderValue.sub(_requiredValue);

    if(_exceededValue > 0) {
      msg.sender.transfer(_exceededValue);

      emit Refund(msg.sender, _requiredValue, _senderValue, _exceededValue);
    } 
  }
}

contract Withdrawable is Ownable {
  address public withdrawer;

   
  modifier onlyWithdrawer() {
    require(msg.sender == withdrawer);
    _;
  }

  function setWithdrawer(address _newWithdrawer) external onlyOwner {
    withdrawer = _newWithdrawer;
  }

   
  function withdraw(uint256 _amount) external onlyWithdrawer returns(bool) {
    require(_amount <= address(this).balance);
    withdrawer.transfer(_amount);
    return true;
  }
}

contract Randomable {
   
  function _generateRandom(bytes32 seed) view internal returns (bytes32) {
    return keccak256(abi.encodePacked(blockhash(block.number-1), seed));
  }

  function _generateRandomNumber(bytes32 seed, uint256 max) view internal returns (uint256) {
    return uint256(_generateRandom(seed)) % max;
  }
}

contract CryptantCrabPresale is CryptantCrabPurchasable, HasNoEther, Withdrawable, Randomable {
  event PresalePurchased(address indexed owner, uint256 amount, uint256 cryptant, uint256 refund);

  uint256 constant public PRESALE_LIMIT = 5000;

   
  uint256 public presaleEndTime = 1542412800;

   
  uint256 public currentPresalePrice = 250 finney;

   
  uint256 public currentTokenId = 721;

   
  uint256 public giveawayTokenId = 5102;

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabPurchasable
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
     

  }

  function setCurrentTokenId(uint256 _newTokenId) external onlyOwner {
    currentTokenId = _newTokenId;
  }

  function setPresaleEndtime(uint256 _newEndTime) external onlyOwner {
    presaleEndTime = _newEndTime;
  }

  function getPresalePrice() public view returns (uint256) {
    return currentPresalePrice;
  }

  function purchase(uint256 _amount) external payable {
    require(genesisCrab != address(0));
    require(cryptantCrabToken != address(0));
    require(cryptantCrabStorage != address(0));
    require(_amount > 0 && _amount <= 10);
    require(isPresale());
    require(PRESALE_LIMIT >= currentTokenId + _amount);

    uint256 _value = msg.value;
    uint256 _currentPresalePrice = getPresalePrice();
    uint256 _totalRequiredAmount = _currentPresalePrice * _amount;

    require(_value >= _totalRequiredAmount);

     
     
    uint256 _crabWithLegendaryPart = 100;
    if(_amount == 10) {
       
      _crabWithLegendaryPart = _generateRandomNumber(bytes32(currentTokenId), 10);
    }

    for(uint256 i = 0 ; i < _amount ; i++) {
      currentTokenId++;
      _createCrab(true, currentTokenId, _currentPresalePrice, 0, 0, 0, _crabWithLegendaryPart == i);
    }

     
    _addCryptantFragments(msg.sender, (i * 3000));

     
    _refundExceededValue(_value, _totalRequiredAmount);

    emit PresalePurchased(msg.sender, _amount, i * 3000, _value - _totalRequiredAmount);
  }

  function createCrab(uint256 _customTokenId, uint256 _crabPrice, uint256 _customGene, uint256 _customSkin, uint256 _customHeart, bool _hasLegendary) external onlyOwner {
    return _createCrab(true, _customTokenId, _crabPrice, _customGene, _customSkin, _customHeart, _hasLegendary);
  }

  function generateGiveawayCrabs(uint256 _amount) external onlyOwner {
    for(uint256 i = 0 ; i < _amount ; i++) {
      _createCrab(false, giveawayTokenId++, 120 finney, 0, 0, 0, false);
    }
  }

  function isPresale() internal view returns (bool) {
    return now < presaleEndTime;
  }
}