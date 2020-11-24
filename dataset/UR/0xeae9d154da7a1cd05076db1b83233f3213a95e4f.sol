 

pragma solidity 0.4.23;

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
     
    uint256 size = 0;

     
     
     
     
     
    assembly {
       
      size := extcodesize(addr)
    }

     
    return size > 0;
  }

}


 
library StringUtils {
   
  function atoi(string a, uint8 base) internal pure returns (uint256 i) {
     
    require(base == 2 || base == 8 || base == 10 || base == 16);

     
    bytes memory buf = bytes(a);

     
    for(uint256 p = 0; p < buf.length; p++) {
       
      uint8 digit = uint8(buf[p]) - 0x30;

       
       
      if(digit > 10) {
         
        digit -= 7;
      }

       
      require(digit < base);

       
      i *= base;

       
      i += digit;
    }

     
    return i;
  }

   
  function itoa(uint256 i, uint8 base) internal pure returns (string a) {
     
    require(base == 2 || base == 8 || base == 10 || base == 16);

     
    if (i == 0) {
      return "0";
    }

     
    bytes memory buf = new bytes(256);

     
    uint256 p = 0;

     
    while (i > 0) {
       
      uint8 digit = uint8(i % base);

       
       
       
       
       
      uint8 ascii = digit + 0x30;

       
       
       
      if(digit > 10) {
         
        ascii += 7;
      }

       
      buf[p++] = byte(ascii);

       
      i /= base;
    }

     
    uint256 length = p;

     
    for(p = 0; p < length / 2; p++) {
       
       
      buf[p] ^= buf[length - 1 - p];
      buf[length - 1 - p] ^= buf[p];
      buf[p] ^= buf[length - 1 - p];
    }

     
    return string(buf);
  }

   
  function concat(string s1, string s2) internal pure returns (string s) {
     
    bytes memory buf1 = bytes(s1);
     
    bytes memory buf2 = bytes(s2);
     
    bytes memory buf = new bytes(buf1.length + buf2.length);

     
    for(uint256 i = 0; i < buf1.length; i++) {
      buf[i] = buf1[i];
    }

     
    for(uint256 j = buf1.length; j < buf2.length; j++) {
      buf[j] = buf2[j - buf1.length];
    }

     
    return string(buf);
  }
}


 
contract AccessControl {
   
   
  uint256 private constant ROLE_ROLE_MANAGER = 0x10000000;

   
   
   
  uint256 private constant ROLE_FEATURE_MANAGER = 0x20000000;

   
  uint256 private constant FULL_PRIVILEGES_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  uint256 public features;

   
   
   
   
   
   
   
  mapping(address => uint256) public userRoles;

   
  event FeaturesUpdated(address indexed _by, uint256 _requested, uint256 _actual);

   
  event RoleUpdated(address indexed _by, address indexed _to, uint256 _role);

   
  constructor() public {
     
    userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
  }

   
  function updateFeatures(uint256 mask) public {
     
    address caller = msg.sender;
     
    uint256 p = userRoles[caller];

     
    require(__hasRole(p, ROLE_FEATURE_MANAGER));

     
     
    features |= p & mask;
     
    features &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ mask));

     
    emit FeaturesUpdated(caller, mask, features);
  }

   
  function addOperator(address operator, uint256 role) public {
     
    address manager = msg.sender;

     
    uint256 permissions = userRoles[manager];

     
    require(userRoles[operator] == 0);

     
    require(__hasRole(permissions, ROLE_ROLE_MANAGER));

     
     
    uint256 r = role & permissions;

     
    require(r != 0);

     
    userRoles[operator] = r;

     
    emit RoleUpdated(manager, operator, userRoles[operator]);
  }

   
  function removeOperator(address operator) public {
     
    address manager = msg.sender;

     
    require(userRoles[operator] != 0);

     
     
    require(operator != manager);

     
     
    require(__hasRole(userRoles[manager], ROLE_ROLE_MANAGER | userRoles[operator]));

     
    delete userRoles[operator];

     
    emit RoleUpdated(manager, operator, 0);
  }

   
  function addRole(address operator, uint256 role) public {
     
    address manager = msg.sender;

     
    uint256 permissions = userRoles[manager];

     
    require(userRoles[operator] != 0);

     
    require(__hasRole(permissions, ROLE_ROLE_MANAGER));

     
     
    uint256 r = role & permissions;

     
    require(r != 0);

     
    userRoles[operator] |= r;

     
    emit RoleUpdated(manager, operator, userRoles[operator]);
  }

   
  function removeRole(address operator, uint256 role) public {
     
    address manager = msg.sender;

     
    uint256 permissions = userRoles[manager];

     
     
     

     
    require(__hasRole(permissions, ROLE_ROLE_MANAGER));

     
     
    uint256 r = role & permissions;

     
    require(r != 0);

     
    userRoles[operator] &= FULL_PRIVILEGES_MASK ^ r;

     
    emit RoleUpdated(manager, operator, userRoles[operator]);
  }

   
  function __isFeatureEnabled(uint256 featureRequired) internal constant returns(bool) {
     
    return __hasRole(features, featureRequired);
  }

   
  function __isSenderInRole(uint256 roleRequired) internal constant returns(bool) {
     
    uint256 userRole = userRoles[msg.sender];

     
    return __hasRole(userRole, roleRequired);
  }

   
  function __hasRole(uint256 userRole, uint256 roleRequired) internal pure returns(bool) {
     
    return userRole & roleRequired == roleRequired;
  }
}


 
interface ERC721Receiver {
   
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}


 
contract ERC165 {
   
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor() public {
     
    _registerInterface(InterfaceId_ERC165);
  }



   
  function supportsInterface(bytes4 _interfaceId) public constant returns (bool) {
     
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId) internal {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


 
contract GemERC721 is AccessControl, ERC165 {
   
   
   
  uint32 public constant TOKEN_VERSION = 0x3;

   
  string public constant symbol = "GEM";
   
  string public constant name = "GEM – CryptoMiner World";
   
   
  uint8 public constant decimals = 0;

   
   
  struct Gem {
     
     
     
     
    uint64 coordinates;

     
    uint8 color;

     
     
     
    uint32 levelModified;

     
    uint8 level;

     
     
     
    uint32 gradeModified;

     
     
    uint32 grade;

     
     
     
    uint32 stateModified;

     
    uint48 state;


     
     
     
     
    uint32 creationTime;

     
    uint32 index;

     
     
     
    uint32 ownershipModified;

     
    address owner;
  }

   
   
   
  mapping(uint256 => Gem) public gems;

   
   
  mapping(uint256 => address) public approvals;

   
   
  mapping(address => mapping(address => bool)) public approvedOperators;

   
   
   
   
   
   
   
  mapping(address => uint32[]) public collections;

   
   
   
   
  uint32[] public allTokens;

   
   
   
   
   
  uint64 public lockedBitmask = DEFAULT_MINING_BIT;

   
  uint32 public constant FEATURE_TRANSFERS = 0x00000001;

   
  uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x00000002;

   
   
   

   
   
   

   
   
   

   
   
   
   
   
   
  uint64 public constant DEFAULT_MINING_BIT = 0x1;  

   
   
   
   

   
   
  uint32 public constant ROLE_LEVEL_PROVIDER = 0x00100000;

   
   
  uint32 public constant ROLE_GRADE_PROVIDER = 0x00200000;

   
   
  uint32 public constant ROLE_STATE_PROVIDER = 0x00400000;

   
   
  uint32 public constant ROLE_STATE_LOCK_PROVIDER = 0x00800000;

   
   
  uint32 public constant ROLE_TOKEN_CREATOR = 0x00040000;

   
   
   

   
   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   

   
  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;

   
  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;

   
  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;

   
  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;

   
   
   
  event Minted(address indexed _by, address indexed _to, uint32 indexed _tokenId);

   
   
   

   
   
   
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId, uint256 _value);

   
   
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

   
   
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _value);

   
  event LevelUp(address indexed _by, address indexed _owner, uint256 indexed _tokenId, uint8 _levelReached);

   
  event UpgradeComplete(address indexed _by, address indexed _owner, uint256 indexed _tokenId, uint32 _gradeFrom, uint32 _gradeTo);

   
  event StateModified(address indexed _by, address indexed _owner, uint256 indexed _tokenId, uint48 _stateFrom, uint48 _stateTo);

   
   
  constructor() public {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function getPacked(uint256 _tokenId) public constant returns(uint256, uint256) {
     
    require(exists(_tokenId));

     
    Gem memory gem = gems[_tokenId];

     
    uint256 high = uint256(gem.coordinates) << 192
                 | uint192(gem.color) << 184
                 | uint184(gem.levelModified) << 152
                 | uint152(gem.level) << 144
                 | uint144(gem.gradeModified) << 112
                 | uint112(gem.grade) << 80
                 | uint80(gem.stateModified) << 48
                 | uint48(gem.state);

     
    uint256 low  = uint256(gem.creationTime) << 224
                 | uint224(gem.index) << 192
                 | uint192(gem.ownershipModified) << 160
                 | uint160(gem.owner);

     
    return (high, low);
  }

   
  function getPackedCollection(address owner) public constant returns (uint80[]) {
     
    uint32[] memory tokenIds = getCollection(owner);

     
    uint32 balance = uint32(tokenIds.length);

     
    uint80[] memory result = new uint80[](balance);

     
    for(uint32 i = 0; i < balance; i++) {
       
      uint32 tokenId = tokenIds[i];
       
      uint48 properties = getProperties(tokenId);

       
      result[i] = uint80(tokenId) << 48 | properties;
    }

     
    return result;
  }

   
  function getCollection(address owner) public constant returns(uint32[]) {
     
    return collections[owner];
  }

   
  function setLockedBitmask(uint64 bitmask) public {
     
    require(__isSenderInRole(ROLE_STATE_LOCK_PROVIDER));

     
    lockedBitmask = bitmask;
  }

   
  function getCoordinates(uint256 _tokenId) public constant returns(uint64) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].coordinates;
  }

   
  function getPlotId(uint256 _tokenId) public constant returns(uint32) {
     
    return uint32(getCoordinates(_tokenId) >> 32);
  }

   
  function getDepth(uint256 _tokenId) public constant returns(uint16) {
     
    return uint16(getCoordinates(_tokenId) >> 16);
  }

   
  function getGemNum(uint256 _tokenId) public constant returns(uint16) {
     
    return uint16(getCoordinates(_tokenId));
  }

   
  function getProperties(uint256 _tokenId) public constant returns(uint48) {
     
    require(exists(_tokenId));

     
    Gem memory gem = gems[_tokenId];

     
    return uint48(gem.color) << 40 | uint40(gem.level) << 32 | gem.grade;
  }

   
  function getColor(uint256 _tokenId) public constant returns(uint8) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].color;
  }

   
  function getLevelModified(uint256 _tokenId) public constant returns(uint32) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].levelModified;
  }

   
  function getLevel(uint256 _tokenId) public constant returns(uint8) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].level;
  }

   
  function levelUp(uint256 _tokenId) public {
     
    require(__isSenderInRole(ROLE_LEVEL_PROVIDER));

     
    require(exists(_tokenId));

     
    gems[_tokenId].levelModified = uint32(block.number);

     
    gems[_tokenId].level++;

     
    emit LevelUp(msg.sender, ownerOf(_tokenId), _tokenId, gems[_tokenId].level);
  }

   
  function getGradeModified(uint256 _tokenId) public constant returns(uint32) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].gradeModified;
  }

   
  function getGrade(uint256 _tokenId) public constant returns(uint32) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].grade;
  }

   
  function getGradeType(uint256 _tokenId) public constant returns(uint8) {
     
    return uint8(getGrade(_tokenId) >> 24);
  }

   
  function getGradeValue(uint256 _tokenId) public constant returns(uint24) {
     
    return uint24(getGrade(_tokenId));
  }

   
  function upgradeGrade(uint256 _tokenId, uint32 grade) public {
     
    require(__isSenderInRole(ROLE_GRADE_PROVIDER));

     
    require(exists(_tokenId));

     
    require(gems[_tokenId].grade < grade);

     
    emit UpgradeComplete(msg.sender, ownerOf(_tokenId), _tokenId, gems[_tokenId].grade, grade);

     
    gems[_tokenId].grade = grade;

     
    gems[_tokenId].gradeModified = uint32(block.number);
  }

   
  function getStateModified(uint256 _tokenId) public constant returns(uint32) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].stateModified;
  }

   
  function getState(uint256 _tokenId) public constant returns(uint48) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].state;
  }

   
  function setState(uint256 _tokenId, uint48 state) public {
     
    require(__isSenderInRole(ROLE_STATE_PROVIDER));

     
    require(exists(_tokenId));

     
    emit StateModified(msg.sender, ownerOf(_tokenId), _tokenId, gems[_tokenId].state, state);

     
    gems[_tokenId].state = state;

     
    gems[_tokenId].stateModified = uint32(block.number);
  }

   
  function getCreationTime(uint256 _tokenId) public constant returns(uint32) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].creationTime;
  }

   
  function getOwnershipModified(uint256 _tokenId) public constant returns(uint32) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].ownershipModified;
  }

   
  function totalSupply() public constant returns (uint256) {
     
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public constant returns (uint256) {
     
    require(_index < allTokens.length);

     
    return allTokens[_index];
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint256) {
     
    require(_index < collections[_owner].length);

     
    return collections[_owner][_index];
  }

   
  function balanceOf(address _owner) public constant returns (uint256) {
     
    return collections[_owner].length;
  }

   
  function exists(uint256 _tokenId) public constant returns (bool) {
     
    return gems[_tokenId].owner != address(0);
  }

   
  function ownerOf(uint256 _tokenId) public constant returns (address) {
     
    require(exists(_tokenId));

     
    return gems[_tokenId].owner;
  }

   
  function mint(
    address to,
    uint32 tokenId,
    uint32 plotId,
    uint16 depth,
    uint16 gemNum,
    uint8 color,
    uint8 level,
    uint8 gradeType,
    uint24 gradeValue
  ) public {
     
    require(to != address(0));
    require(to != address(this));

     
     
    require(__isSenderInRole(ROLE_TOKEN_CREATOR));

     
    __mint(to, tokenId, plotId, depth, gemNum, color, level, gradeType, gradeValue);

     
    emit Transfer(address(0), to, tokenId, 1);
  }

   
  function transfer(address to, uint256 _tokenId) public {
     
    require(__isFeatureEnabled(FEATURE_TRANSFERS));

     
    address from = msg.sender;

     
    __transfer(from, to, _tokenId);
  }

   
  function transferFrom(address from, address to, uint256 _tokenId) public {
     
    require(__isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF));

     
    address operator = msg.sender;

     
    address approved = approvals[_tokenId];

     
     

     
    bool approvedOperator = approvedOperators[from][operator];

     
     
     
     
    if(operator != approved && !approvedOperator) {
       
       
       
       
      require(from == operator);

       
      require(__isFeatureEnabled(FEATURE_TRANSFERS));
    }

     
    __transfer(from, to, _tokenId);
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public {
     
    transferFrom(_from, _to, _tokenId);

     
    if (AddressUtils.isContract(_to)) {
       
      bytes4 response = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);

       
      require(response == ERC721_RECEIVED);
    }
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function approve(address _approved, uint256 _tokenId) public {
     
    address from = msg.sender;

     
    address owner = ownerOf(_tokenId);

     
    require(from == owner);
     
    require(_approved != owner);
     
    require(approvals[_tokenId] != address(0) || _approved != address(0));

     
    approvals[_tokenId] = _approved;

     
    emit Approval(from, _approved, _tokenId);
  }

   
  function revokeApproval(uint256 _tokenId) public {
     
    approve(address(0), _tokenId);
  }

   
  function setApprovalForAll(address to, bool approved) public {
     
    address from = msg.sender;

     
    require(to != address(0));

     
    require(to != from);

     
    approvedOperators[from][to] = approved;

     
    emit ApprovalForAll(from, to, approved);
  }

   
  function getApproved(uint256 _tokenId) public constant returns (address) {
     
    require(exists(_tokenId));

     
    return approvals[_tokenId];
  }

   
  function isApprovedForAll(address _owner, address _operator) public constant returns (bool) {
     
    return approvedOperators[_owner][_operator];
  }

   
  function tokenURI(uint256 _tokenId) public constant returns (string) {
     
    require(exists(_tokenId));

     
    return StringUtils.concat("http://cryptominerworld.com/gem/", StringUtils.itoa(_tokenId, 16));
  }

   
   
   
   
   
  function __mint(
    address to,
    uint32 tokenId,
    uint32 plotId,
    uint16 depth,
    uint16 gemNum,
    uint8 color,
    uint8 level,
    uint8 gradeType,
    uint24 gradeValue
  ) private {
     
    require(tokenId > 0);

     
    require(!exists(tokenId));

     
    Gem memory gem = Gem({
      coordinates: uint64(plotId) << 32 | uint32(depth) << 16 | gemNum,
      color: color,
      levelModified: 0,
      level: level,
      gradeModified: 0,
      grade: uint32(gradeType) << 24 | gradeValue,
      stateModified: 0,
      state: 0,

      creationTime: uint32(block.number),
       
       
      index: uint32(collections[to].length),
      ownershipModified: 0,
      owner: to
    });

     
    collections[to].push(tokenId);

     
    gems[tokenId] = gem;

     
     
    allTokens.push(tokenId);

     
    emit Minted(msg.sender, to, tokenId);
     
    emit Transfer(address(0), to, tokenId, 1);
  }

   
   
   
   
   
  function __transfer(address from, address to, uint256 _tokenId) private {
     
    require(to != address(0));
    require(to != from);
     
     
    assert(from != address(0));

     
    require(exists(_tokenId));

     
    require(ownerOf(_tokenId) == from);

     
     
    require(getState(_tokenId) & lockedBitmask == 0);

     
    __clearApprovalFor(_tokenId);

     
     
    __move(from, to, _tokenId);

     
    emit Transfer(from, to, _tokenId, 1);
  }

   
  function __clearApprovalFor(uint256 _tokenId) private {
     
    if(approvals[_tokenId] != address(0)) {
       
      delete approvals[_tokenId];

       
      emit Approval(msg.sender, address(0), _tokenId);
    }
  }

   
   
   
  function __move(address from, address to, uint256 _tokenId) private {
     
    uint32 tokenId = uint32(_tokenId);

     
    assert(tokenId == _tokenId);

     
    Gem storage gem = gems[_tokenId];

     
    uint32[] storage source = collections[from];

     
    uint32[] storage destination = collections[to];

     
    assert(source.length != 0);

     
    uint32 i = gem.index;

     
     
    uint32 sourceId = source[source.length - 1];

     
    gems[sourceId].index = i;

     
    source[i] = sourceId;

     
    source.length--;

     
    gem.index = uint32(destination.length);

     
    gem.owner = to;

     
    gem.ownershipModified = uint32(block.number);

     
    destination.push(tokenId);
  }

}