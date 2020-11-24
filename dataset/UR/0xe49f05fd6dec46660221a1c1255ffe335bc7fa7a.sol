 

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


 
library Fractions16 {
   
  function createProperFraction16(uint8 n, uint8 d) internal pure returns (uint16) {
     
    require(d != 0);

     
    require(n < d);

     
    return uint16(n) << 8 | d;
  }

   
  function toPercent(uint16 f) internal pure returns(uint8) {
     
    uint8 nominator = getNominator(f);
    uint8 denominator = getDenominator(f);

     
    if(nominator == denominator) {
       
      return 100;
    }

     
    require(nominator < denominator);

     
     
    return uint8(100 * uint16(nominator) / denominator);
  }

   
  function isZero(uint16 f) internal pure returns(bool) {
     
    return getNominator(f) == 0;
  }

   
  function isOne(uint16 f) internal pure returns(bool) {
     
    return getNominator(f) == getDenominator(f);
  }

   
  function isProper(uint16 f) internal pure returns(bool) {
     
     
    return getNominator(f) < getDenominator(f);
  }

   
  function getNominator(uint16 f) internal pure returns(uint8) {
    return uint8(f >> 8);
  }

   
  function getDenominator(uint16 f) internal pure returns(uint8) {
    return uint8(f);
  }

   
  function multiplyByInteger(uint16 f, uint256 by) internal pure returns(uint256) {
     
    uint8 nominator = getNominator(f);
    uint8 denominator = getDenominator(f);

     
    if(nominator == denominator) {
       
      return by;
    }

     
    require(nominator < denominator);

     
    if(by == uint240(by)) {
       
      return by * nominator / denominator;
    }

     
    return by / denominator * nominator;
  }
}


 
contract CountryERC721 is AccessControl, ERC165 {
   
  using Fractions16 for uint16;

   
   
   
  uint32 public constant TOKEN_VERSION = 0x1;

   
  string public constant symbol = "CTY";
   
  string public constant name = "Country – CryptoMiner World";
   
   
  uint8 public constant decimals = 0;

   
   
  struct Country {
     
    uint8 id;

     
     
    uint16 plots;

     
    uint16 tax;

     
    uint32 taxModified;

     
    uint8 index;

     
    address owner;
  }

   
  uint16[] public countryData;

   
   
   
  mapping(uint256 => Country) public countries;

   
   
  mapping(uint256 => address) public approvals;

   
   
  mapping(address => mapping(address => bool)) public approvedOperators;

   
   
   
   
   
   
   
  mapping(address => uint8[]) public collections;

   
   
   
   
  uint8[] public allTokens;

   
  uint8 private _totalSupply;

   
   
   
  uint192 public tokenMap;

   
   
  uint32 public maxTaxChangeFreq = 86400;  

   
   
   
  uint8 public constant TOTAL_SUPPLY_MAX = 192;

   
   
   
  uint8 public constant MAX_TAX_INV = 5;  

   
   
  uint16 public constant DEFAULT_TAX_RATE = 0x010A;  

   
  uint32 public constant FEATURE_TRANSFERS = 0x00000001;

   
  uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x00000002;

   
  uint32 public constant FEATURE_ALLOW_TAX_UPDATE = 0x00000004;

   
   
   
  uint32 public constant ROLE_TAX_MANAGER = 0x00020000;

   
   
  uint32 public constant ROLE_TOKEN_CREATOR = 0x00040000;

   
   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   

   
  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;

   
  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;

   
  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;

   
  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;

   
   
   
  event Minted(address indexed _by, address indexed _to, uint8 indexed _tokenId);

   
   
   
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId, uint256 _value);

   
   
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

   
   
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _value);

   
  event TaxRateUpdated(address indexed _owner, uint256 indexed _tokenId, uint16 tax, uint16 oldTax);

   
  constructor(uint16[] _countryData) public {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);

     
    require(_countryData.length <= TOTAL_SUPPLY_MAX);

     
    countryData = _countryData;
  }

   
  function getNumberOfCountries() public constant returns(uint8) {
     
    return uint8(countryData.length);
  }

   
  function getTotalNumberOfPlots() public constant returns(uint32) {
     
    uint32 result = 0;

     
    for(uint i = 0; i < countryData.length; i++) {
       
      result += countryData[i];
    }

     
    return result;
  }

   
  function getNumberOfPlotsByCountryOwner(address owner) public constant returns(uint32) {
     
    uint32 result = 0;

     
    for(uint i = 0; i < collections[owner].length; i++) {
       
      result += countries[collections[owner][i]].plots;
    }

     
    return result;
  }

   
  function getPacked(uint256 _tokenId) public constant returns(uint32) {
     
    require(exists(_tokenId));

     
    Country memory country = countries[_tokenId];

     
    return uint32(country.plots) << 16 | country.tax;
  }

   
  function getCollection(address owner) public constant returns(uint8[]) {
     
    return collections[owner];
  }

   
  function getPackedCollection(address owner) public constant returns(uint40[]) {
     
    uint8[] memory ids = getCollection(owner);

     
    uint40[] memory packedCollection = new uint40[](ids.length);

     
    for(uint i = 0; i < ids.length; i++) {
       
      uint8 tokenId = ids[i];

       
      uint32 packedData = getPacked(tokenId);

       
      packedCollection[i] = uint40(tokenId) << 32 | packedData;
    }

     
    return packedCollection;
  }

   
  function getNumberOfPlots(uint256 _tokenId) public constant returns(uint16) {
     
    require(exists(_tokenId));

     
    return countries[_tokenId].plots;
  }

   
  function getTax(uint256 _tokenId) public constant returns(uint8, uint8) {
     
    uint16 tax = getTaxPacked(_tokenId);

     
    return (tax.getNominator(), tax.getDenominator());
  }

   
  function getTaxPacked(uint256 _tokenId) public constant returns(uint16) {
     
    require(exists(_tokenId));

     
    return countries[_tokenId].tax;
  }

   
  function getTaxPercent(uint256 _tokenId) public constant returns (uint8) {
     
    require(exists(_tokenId));

     
    return countries[_tokenId].tax.toPercent();
  }

   
  function calculateTaxValueFor(uint256 _tokenId, uint256 _value) public constant returns (uint256) {
     
    require(exists(_tokenId));

     
    return countries[_tokenId].tax.multiplyByInteger(_value);
  }

   
  function updateTaxRate(uint256 _tokenId, uint8 nominator, uint8 denominator) public {
     
    require(__isFeatureEnabled(FEATURE_ALLOW_TAX_UPDATE));

     
    require(msg.sender == ownerOf(_tokenId));

     
    require(nominator <= denominator / MAX_TAX_INV);

     
    require(countries[_tokenId].taxModified + maxTaxChangeFreq <= now);

     
    uint16 oldTax = countries[_tokenId].tax;

     
    countries[_tokenId].tax = Fractions16.createProperFraction16(nominator, denominator);

     
    countries[_tokenId].taxModified = uint32(now);

     
    emit TaxRateUpdated(msg.sender, _tokenId, countries[_tokenId].tax, oldTax);
  }

   
  function updateMaxTaxChangeFreq(uint32 _maxTaxChangeFreq) public {
     
    require(__isSenderInRole(ROLE_TAX_MANAGER));

     
    maxTaxChangeFreq = _maxTaxChangeFreq;
  }


   
  function mint(address to, uint8 tokenId) public {
     
    require(to != address(0));
    require(to != address(this));

     
    require(__isSenderInRole(ROLE_TOKEN_CREATOR));

     
    __mint(to, tokenId);

     
    emit Minted(msg.sender, to, tokenId);

     
    emit Transfer(address(0), to, tokenId, 1);
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
     
    require(_owner != address(0));

     
    return collections[_owner].length;
  }

   
  function exists(uint256 _tokenId) public constant returns (bool) {
     
    return countries[_tokenId].owner != address(0);
  }

   
  function ownerOf(uint256 _tokenId) public constant returns (address) {
     
    require(exists(_tokenId));

     
    return countries[_tokenId].owner;
  }

   
  function transfer(address to, uint256 _tokenId) public {
     
    require(__isFeatureEnabled(FEATURE_TRANSFERS));

     
    address from = msg.sender;

     
    __transfer(from, to, _tokenId);
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public {
     
     
    require(_from == msg.sender && __isFeatureEnabled(FEATURE_TRANSFERS)
      || _from != msg.sender && __isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF));

     
    address operator = msg.sender;

     
    address approved = approvals[_tokenId];

     
     

     
    bool approvedOperator = approvedOperators[_from][operator];

     
     
     
     
    if(operator != approved && !approvedOperator) {
       
       
       
       
      require(_from == operator);
    }

     
    __transfer(_from, _to, _tokenId);
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

     
    return StringUtils.concat("http://cryptominerworld.com/country/", StringUtils.itoa(_tokenId, 10));
  }

   
   
   
   
   
  function __transfer(address from, address to, uint256 _tokenId) private {
     
    require(to != address(0));
    require(to != from);
     
     
    assert(from != address(0));

     
    require(exists(_tokenId));

     
    require(ownerOf(_tokenId) == from);

     
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
     
    uint8 tokenId = uint8(_tokenId);

     
    assert(tokenId == _tokenId);

     
    Country storage country = countries[_tokenId];

     
    uint8[] storage source = collections[from];

     
    uint8[] storage destination = collections[to];

     
    assert(source.length != 0);

     
    uint8 i = country.index;

     
     
    uint8 sourceId = source[source.length - 1];

     
    countries[sourceId].index = i;

     
    source[i] = sourceId;

     
    source.length--;

     
    country.index = uint8(destination.length);

     
    country.owner = to;

     
    destination.push(tokenId);
  }

   
   
   
   
   
  function __mint(address to, uint8 tokenId) private {
     
    require(tokenId > 0 && tokenId <= countryData.length);

     
    require(!exists(tokenId));

     
    Country memory country = Country({
      id: tokenId,
      plots: countryData[tokenId - 1],
      tax: DEFAULT_TAX_RATE,
      taxModified: 0,
      index: uint8(collections[to].length),
      owner: to
    });

     
    collections[to].push(tokenId);

     
    countries[tokenId] = country;

     
     
    allTokens.push(tokenId);

     
    tokenMap |= uint192(1 << uint256(tokenId - 1));
  }

}