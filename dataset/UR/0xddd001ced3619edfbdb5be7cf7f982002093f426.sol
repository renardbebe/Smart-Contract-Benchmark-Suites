 

pragma solidity 0.4.21;

 

contract LANDStorage {

  mapping (address => uint) public latestPing;

  uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 constant factor = 0x100000000000000000000000000000000;

  mapping (address => bool) public authorizedDeploy;

  mapping (uint256 => address) public updateOperator;
}

 

contract OwnableStorage {

  address public owner;

  function OwnableStorage() internal {
    owner = msg.sender;
  }

}

 

contract ProxyStorage {

   
  address public currentContract;
  address public proxyOwner;
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

   
  mapping(uint256 => address) internal _approval;
}

 

contract Storage is ProxyStorage, OwnableStorage, AssetRegistryStorage, LANDStorage {
}

 

contract IApplication {
  function initialize(bytes data) public;
}

 

contract Ownable is Storage {

  event OwnerUpdate(address _prevOwner, address _newOwner);

  function bytesToAddress (bytes b) pure public returns (address) {
    uint result = 0;
    for (uint i = b.length-1; i+1 > 0; i--) {
      uint c = uint(b[i]);
      uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
      result += to_inc;
    }
    return address(result);
  }

  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != owner);
    owner = _newOwner;
  }
}

 

interface ILANDRegistry {

   
  function assignNewParcel(int x, int y, address beneficiary) public;
  function assignMultipleParcels(int[] x, int[] y, address beneficiary) public;

   
  function ping() public;

   
  function encodeTokenId(int x, int y) view public returns (uint256);
  function decodeTokenId(uint value) view public returns (int, int);
  function exists(int x, int y) view public returns (bool);
  function ownerOfLand(int x, int y) view public returns (address);
  function ownerOfLandMany(int[] x, int[] y) view public returns (address[]);
  function landOf(address owner) view public returns (int[], int[]);
  function landData(int x, int y) view public returns (string);

   
  function transferLand(int x, int y, address to) public;
  function transferManyLand(int[] x, int[] y, address to) public;

   
  function updateLandData(int x, int y, string data) public;
  function updateManyLandData(int[] x, int[] y, string data) public;

   

  event Update(  
    uint256 indexed assetId, 
    address indexed holder,  
    address indexed operator,  
    string data  
  );
}

 

interface IERC721Base {
  function totalSupply() public view returns (uint256);

   
  function ownerOf(uint256 assetId) public view returns (address);

  function balanceOf(address holder) public view returns (uint256);

  function safeTransferFrom(address from, address to, uint256 assetId) public;
  function safeTransferFrom(address from, address to, uint256 assetId, bytes userData) public;

  function transferFrom(address from, address to, uint256 assetId) public;

  function approve(address operator, uint256 assetId) public;
  function setApprovalForAll(address operator, bool authorized) public;

  function getApprovedAddress(uint256 assetId) public view returns (address);
  function isApprovedForAll(address operator, address assetOwner) public view returns (bool);

  function isAuthorized(address operator, uint256 assetId) public view returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed assetId,
    address operator,
    bytes userData
  );
  event ApprovalForAll(
    address indexed operator,
    address indexed holder,
    bool authorized
  );
  event Approval(
    address indexed owner,
    address indexed operator,
    uint256 indexed assetId
  );
}

 

interface IERC721Receiver {
  function onERC721Received(
    uint256 _tokenId,
    address _oldOwner,
    bytes   _userData
  ) public returns (bytes4);
}

 

 
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

 

interface ERC165 {
  function supportsInterface(bytes4 interfaceID) public view returns (bool);
}

contract ERC721Base is AssetRegistryStorage, IERC721Base, ERC165 {
  using SafeMath for uint256;

   
   
   

   
  function totalSupply() public view returns (uint256) {
    return _count;
  }

   
   
   

   
  function ownerOf(uint256 assetId) public view returns (address) {
    return _holderOf[assetId];
  }

   
   
   
   
  function balanceOf(address owner) public view returns (uint256) {
    return _assetsOf[owner].length;
  }

   
   
   

   
  function isApprovedForAll(address operator, address assetHolder)
    public view returns (bool)
  {
    return _operators[assetHolder][operator];
  }

   
  function getApprovedAddress(uint256 assetId) public view returns (address) {
    return _approval[assetId];
  }

   
  function isAuthorized(address operator, uint256 assetId)
    public view returns (bool)
  {
    require(operator != 0);
    address owner = ownerOf(assetId);
    if (operator == owner) {
      return true;
    }
    return isApprovedForAll(operator, owner) || getApprovedAddress(assetId) == operator;
  }

   
   
   

   
  function setApprovalForAll(address operator, bool authorized) public {
    if (authorized) {
      require(!isApprovedForAll(operator, msg.sender));
      _addAuthorization(operator, msg.sender);
    } else {
      require(isApprovedForAll(operator, msg.sender));
      _clearAuthorization(operator, msg.sender);
    }
    ApprovalForAll(operator, msg.sender, authorized);
  }

   
  function approve(address operator, uint256 assetId) public {
    address holder = ownerOf(assetId);
    require(operator != holder);
    if (getApprovedAddress(assetId) != operator) {
      _approval[assetId] = operator;
      Approval(holder, operator, assetId);
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

    uint256 length = balanceOf(to);

    _assetsOf[to].push(assetId);

    _indexOfAsset[assetId] = length;

    _count = _count.add(1);
  }

  function _removeAssetFrom(address from, uint256 assetId) internal {
    uint256 assetIndex = _indexOfAsset[assetId];
    uint256 lastAssetIndex = balanceOf(from).sub(1);
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
    if (ownerOf(assetId) == holder && _approval[assetId] != 0) {
      _approval[assetId] = 0;
      Approval(holder, 0, assetId);
    }
  }

   
   
   

  function _generate(uint256 assetId, address beneficiary) internal {
    require(_holderOf[assetId] == 0);

    _addAssetTo(beneficiary, assetId);

    Transfer(0, beneficiary, assetId, msg.sender, '');
  }

  function _destroy(uint256 assetId) internal {
    address holder = _holderOf[assetId];
    require(holder != 0);

    _removeAssetFrom(holder, assetId);

    Transfer(holder, 0, assetId, msg.sender, '');
  }

   
   
   

  modifier onlyHolder(uint256 assetId) {
    require(_holderOf[assetId] == msg.sender);
    _;
  }

  modifier onlyAuthorized(uint256 assetId) {
    require(isAuthorized(msg.sender, assetId));
    _;
  }

  modifier isCurrentOwner(address from, uint256 assetId) {
    require(_holderOf[assetId] == from);
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

   
  function safeTransferFrom(address from, address to, uint256 assetId) public {
    return _doTransferFrom(from, to, assetId, '', msg.sender, true);
  }

   
  function safeTransferFrom(address from, address to, uint256 assetId, bytes userData) public {
    return _doTransferFrom(from, to, assetId, userData, msg.sender, true);
  }

   
  function transferFrom(address from, address to, uint256 assetId) public {
    return _doTransferFrom(from, to, assetId, '', msg.sender, false);
  }

  function _doTransferFrom(
    address from,
    address to,
    uint256 assetId,
    bytes userData,
    address operator,
    bool doCheck
  )
    isDestinataryDefined(to)
    destinataryIsNotHolder(assetId, to)
    isCurrentOwner(from, assetId)
    onlyAuthorized(assetId)
    internal
  {
    address holder = _holderOf[assetId];
    _removeAssetFrom(holder, assetId);
    _clearApproval(holder, assetId);
    _addAssetTo(to, assetId);

    if (doCheck && _isContract(to)) {
       
      bytes4 ERC721_RECEIVED = bytes4(0xf0b9e5ba);
      require(
        IERC721Receiver(to).onERC721Received(
          assetId, holder, userData
        ) == ERC721_RECEIVED
      );
    }

    Transfer(holder, to, assetId, operator, userData);
  }

   
  function supportsInterface(bytes4 _interfaceID) public view returns (bool) {

    if (_interfaceID == 0xffffffff) {
      return false;
    }
    return _interfaceID == 0x01ffc9a7 || _interfaceID == 0x7c0633c6;
  }

   
   
   

  function _isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

 

contract IERC721Enumerable {

   
   
   

   
   
   

   
   
   

   
  function tokensOf(address owner) public view returns (uint256[]);

   
  function tokenOfOwnerByIndex(
    address owner, uint256 index
  ) public view returns (uint256 tokenId);
}

 

contract ERC721Enumerable is AssetRegistryStorage, IERC721Enumerable {

   
  function tokensOf(address owner) public view returns (uint256[]) {
    return _assetsOf[owner];
  }

   
  function tokenOfOwnerByIndex(
    address owner, uint256 index
    ) public view returns (uint256 assetId)
  {
    require(index < _assetsOf[owner].length);
    require(index < (1<<127));
    return _assetsOf[owner][index];
  }

}

 

contract IERC721Metadata {

   
  function name() public view returns (string);

   
  function symbol() public view returns (string);

   
  function description() public view returns (string);

   
  function tokenMetadata(uint256 assetId) public view returns (string);
}

 

contract ERC721Metadata is AssetRegistryStorage, IERC721Metadata {
  function name() public view returns (string) {
    return _name;
  }
  function symbol() public view returns (string) {
    return _symbol;
  }
  function description() public view returns (string) {
    return _description;
  }
  function tokenMetadata(uint256 assetId) public view returns (string) {
    return _assetData[assetId];
  }
  function _update(uint256 assetId, string data) internal {
    _assetData[assetId] = data;
  }
}

 

contract FullAssetRegistry is ERC721Base, ERC721Enumerable, ERC721Metadata {
  function FullAssetRegistry() public {
  }

   
  function exists(uint256 assetId) public view returns (bool) {
    return _holderOf[assetId] != 0;
  }

  function decimals() public pure returns (uint256) {
    return 0;
  }
}

 

contract LANDRegistry is Storage,
  Ownable, FullAssetRegistry,
  ILANDRegistry
{

  function initialize(bytes) public {
    _name = 'Decentraland LAND';
    _symbol = 'LAND';
    _description = 'Contract that stores the Decentraland LAND registry';
  }

  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner);
    _;
  }

   
   
   

  modifier onlyOwnerOf(uint256 assetId) {
    require(msg.sender == ownerOf(assetId));
    _;
  }

  modifier onlyUpdateAuthorized(uint256 tokenId) {
    require(msg.sender == ownerOf(tokenId) || isUpdateAuthorized(msg.sender, tokenId));
    _;
  }

  function isUpdateAuthorized(address operator, uint256 assetId) public view returns (bool) {
    return operator == ownerOf(assetId) || updateOperator[assetId] == operator;
  }

  function authorizeDeploy(address beneficiary) public onlyProxyOwner {
    authorizedDeploy[beneficiary] = true;
  }
  function forbidDeploy(address beneficiary) public onlyProxyOwner {
    authorizedDeploy[beneficiary] = false;
  }

  function assignNewParcel(int x, int y, address beneficiary) public onlyProxyOwner {
    _generate(encodeTokenId(x, y), beneficiary);
  }

  function assignMultipleParcels(int[] x, int[] y, address beneficiary) public onlyProxyOwner {
    for (uint i = 0; i < x.length; i++) {
      _generate(encodeTokenId(x[i], y[i]), beneficiary);
    }
  }

   
   
   

  function ping() public {
    latestPing[msg.sender] = now;
  }

  function setLatestToNow(address user) public {
    require(msg.sender == proxyOwner || isApprovedForAll(msg.sender, user));
    latestPing[user] = now;
  }

   
   
   

  function encodeTokenId(int x, int y) view public returns (uint) {
    return ((uint(x) * factor) & clearLow) | (uint(y) & clearHigh);
  }

  function decodeTokenId(uint value) view public returns (int, int) {
    uint x = (value & clearLow) >> 128;
    uint y = (value & clearHigh);
    return (expandNegative128BitCast(x), expandNegative128BitCast(y));
  }

  function expandNegative128BitCast(uint value) pure internal returns (int) {
    if (value & (1<<127) != 0) {
      return int(value | clearLow);
    }
    return int(value);
  }

  function exists(int x, int y) view public returns (bool) {
    return exists(encodeTokenId(x, y));
  }

  function ownerOfLand(int x, int y) view public returns (address) {
    return ownerOf(encodeTokenId(x, y));
  }

  function ownerOfLandMany(int[] x, int[] y) view public returns (address[]) {
    require(x.length > 0);
    require(x.length == y.length);

    address[] memory addrs = new address[](x.length);
    for (uint i = 0; i < x.length; i++) {
      addrs[i] = ownerOfLand(x[i], y[i]);
    }

    return addrs;
  }

  function landOf(address owner) public view returns (int[], int[]) {
    uint256 len = _assetsOf[owner].length;
    int[] memory x = new int[](len);
    int[] memory y = new int[](len);

    int assetX;
    int assetY;
    for (uint i = 0; i < len; i++) {
      (assetX, assetY) = decodeTokenId(_assetsOf[owner][i]);
      x[i] = assetX;
      y[i] = assetY;
    }

    return (x, y);
  }

  function landData(int x, int y) view public returns (string) {
    return tokenMetadata(encodeTokenId(x, y));
  }

   
   
   

  function transferLand(int x, int y, address to) public {
    uint256 tokenId = encodeTokenId(x, y);
    safeTransferFrom(ownerOf(tokenId), to, tokenId);
  }

  function transferManyLand(int[] x, int[] y, address to) public {
    require(x.length > 0);
    require(x.length == y.length);

    for (uint i = 0; i < x.length; i++) {
      uint256 tokenId = encodeTokenId(x[i], y[i]);
      safeTransferFrom(ownerOf(tokenId), to, tokenId);
    }
  }

  function setUpdateOperator(uint256 assetId, address operator) public onlyOwnerOf(assetId) {
    updateOperator[assetId] = operator;
  }

   
   
   

  function updateLandData(int x, int y, string data) public onlyUpdateAuthorized (encodeTokenId(x, y)) {
    uint256 assetId = encodeTokenId(x, y);
    _update(assetId, data);

    Update(assetId, _holderOf[assetId], msg.sender, data);
  }

  function updateManyLandData(int[] x, int[] y, string data) public {
    require(x.length > 0);
    require(x.length == y.length);
    for (uint i = 0; i < x.length; i++) {
      updateLandData(x[i], y[i], data);
    }
  }

  function _doTransferFrom(
    address from,
    address to,
    uint256 assetId,
    bytes userData,
    address operator,
    bool doCheck
  ) internal {
    updateOperator[assetId] = address(0);
    super._doTransferFrom(from, to, assetId, userData, operator, doCheck);
  }
}