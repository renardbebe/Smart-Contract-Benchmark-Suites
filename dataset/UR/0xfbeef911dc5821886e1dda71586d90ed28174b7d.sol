 

pragma solidity ^0.4.24;

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 
contract AccessControl {

  using Roles for Roles.Role;

  uint8 public constant ROLE_KNOWN_ORIGIN = 1;
  uint8 public constant ROLE_MINTER = 2;
  uint8 public constant ROLE_UNDER_MINTER = 3;

  event RoleAdded(address indexed operator, uint8 role);
  event RoleRemoved(address indexed operator, uint8 role);

  address public owner;

  mapping(uint8 => Roles.Role) private roles;

  modifier onlyIfKnownOrigin() {
    require(msg.sender == owner || hasRole(msg.sender, ROLE_KNOWN_ORIGIN));
    _;
  }

  modifier onlyIfMinter() {
    require(msg.sender == owner || hasRole(msg.sender, ROLE_KNOWN_ORIGIN) || hasRole(msg.sender, ROLE_MINTER));
    _;
  }

  modifier onlyIfUnderMinter() {
    require(msg.sender == owner || hasRole(msg.sender, ROLE_KNOWN_ORIGIN) || hasRole(msg.sender, ROLE_UNDER_MINTER));
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

   
   
   

  function addAddressToAccessControl(address _operator, uint8 _role)
  public
  onlyIfKnownOrigin
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  function removeAddressFromAccessControl(address _operator, uint8 _role)
  public
  onlyIfKnownOrigin
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  function checkRole(address _operator, uint8 _role)
  public
  view
  {
    roles[_role].check(_operator);
  }

  function hasRole(address _operator, uint8 _role)
  public
  view
  returns (bool)
  {
    return roles[_role].has(_operator);
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

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
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

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

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

 

library Strings {
   
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(string _a, string _b) internal pure returns (string) {
    return strConcat(_a, _b, "", "", "");
  }
}

 

 


 


 


 


 


 


 
contract KnownOriginDigitalAssetV2 is
ERC721Token,
AccessControl,
HasNoEther,
Pausable
{
  using SafeMath for uint256;

   
   
   

   
  event Purchase(
    uint256 indexed _tokenId,
    uint256 indexed _editionNumber,
    address indexed _buyer,
    uint256 _priceInWei
  );

   
  event Minted(
    uint256 indexed _tokenId,
    uint256 indexed _editionNumber,
    address indexed _buyer
  );

   
  event EditionCreated(
    uint256 indexed _editionNumber,
    bytes32 indexed _editionData,
    uint256 indexed _editionType
  );

   
   
   

  uint256 constant internal MAX_UINT32 = ~uint32(0);

  string public tokenBaseURI = "https://ipfs.infura.io/ipfs/";

   
  uint256 public highestEditionNumber;

   
  uint256 public totalPurchaseValueInWei;

   
  uint256 public totalNumberMinted;

   
  uint256 public totalNumberAvailable;

   
  address public koCommissionAccount;

   
  mapping(uint256 => CommissionSplit) editionNumberToOptionalCommissionSplit;

   
  struct CommissionSplit {
    uint256 rate;
    address recipient;
  }

   
  struct EditionDetails {
     
    uint256 editionNumber;     
    bytes32 editionData;       
    uint256 editionType;       
     
    uint256 startDate;         
    uint256 endDate;           
    address artistAccount;     
    uint256 artistCommission;  
    uint256 priceInWei;        
    string tokenURI;           
    bool active;               
     
    uint256 totalSupply;       
    uint256 totalAvailable;    
  }

   
  mapping(uint256 => EditionDetails) internal editionNumberToEditionDetails;

   
  mapping(uint256 => uint256) internal tokenIdToEditionNumber;

   
  mapping(uint256 => uint256[]) internal editionNumberToTokenIds;
  mapping(uint256 => uint256) internal editionNumberToTokenIdIndex;

   
  mapping(address => uint256[]) internal artistToEditionNumbers;
  mapping(uint256 => uint256) internal editionNumberToArtistIndex;

   
  mapping(uint256 => uint256[]) internal editionTypeToEditionNumber;
  mapping(uint256 => uint256) internal editionNumberToTypeIndex;

   
   
   

  modifier onlyAvailableEdition(uint256 _editionNumber) {
    require(editionNumberToEditionDetails[_editionNumber].totalSupply < editionNumberToEditionDetails[_editionNumber].totalAvailable, "No more editions left to purchase");
    _;
  }

  modifier onlyActiveEdition(uint256 _editionNumber) {
    require(editionNumberToEditionDetails[_editionNumber].active, "Edition not active");
    _;
  }

  modifier onlyRealEdition(uint256 _editionNumber) {
    require(editionNumberToEditionDetails[_editionNumber].editionNumber > 0, "Edition number invalid");
    _;
  }

  modifier onlyValidTokenId(uint256 _tokenId) {
    require(exists(_tokenId), "Token ID does not exist");
    _;
  }

  modifier onlyPurchaseDuringWindow(uint256 _editionNumber) {
    require(editionNumberToEditionDetails[_editionNumber].startDate <= block.timestamp, "Edition not available yet");
    require(editionNumberToEditionDetails[_editionNumber].endDate >= block.timestamp, "Edition no longer available");
    _;
  }

   
  constructor () public payable ERC721Token("KnownOriginDigitalAsset", "KODA") {
     
    koCommissionAccount = msg.sender;
  }

   
  function createActiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalAvailable
  )
  public
  onlyIfKnownOrigin
  returns (bool)
  {
    return _createEdition(_editionNumber, _editionData, _editionType, _startDate, _endDate, _artistAccount, _artistCommission, _priceInWei, _tokenURI, _totalAvailable, true);
  }

   
  function createInactiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalAvailable
  )
  public
  onlyIfKnownOrigin
  returns (bool)
  {
    return _createEdition(_editionNumber, _editionData, _editionType, _startDate, _endDate, _artistAccount, _artistCommission, _priceInWei, _tokenURI, _totalAvailable, false);
  }

   
  function createActivePreMintedEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalSupply,
    uint256 _totalAvailable
  )
  public
  onlyIfKnownOrigin
  returns (bool)
  {
    _createEdition(_editionNumber, _editionData, _editionType, _startDate, _endDate, _artistAccount, _artistCommission, _priceInWei, _tokenURI, _totalAvailable, true);
    updateTotalSupply(_editionNumber, _totalSupply);
    return true;
  }

   
  function createInactivePreMintedEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalSupply,
    uint256 _totalAvailable
  )
  public
  onlyIfKnownOrigin
  returns (bool)
  {
    _createEdition(_editionNumber, _editionData, _editionType, _startDate, _endDate, _artistAccount, _artistCommission, _priceInWei, _tokenURI, _totalAvailable, false);
    updateTotalSupply(_editionNumber, _totalSupply);
    return true;
  }

   
  function _createEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalAvailable,
    bool _active
  )
  internal
  returns (bool)
  {
     
    require(_editionNumber != 0, "Edition number not provided");

     
    require(_editionNumber > highestEditionNumber, "Edition number must be greater than previously used");

     
    require(highestEditionNumber.add(editionNumberToEditionDetails[highestEditionNumber].totalAvailable) < _editionNumber, "Edition number must be greater than previously used plus total available");

     
    require(_editionType != 0, "Edition type not provided");

     
    require(bytes(_tokenURI).length != 0, "Token URI is missing");

     
    require(_artistAccount != address(0), "Artist account not provided");

     
    require(_artistCommission <= 100 && _artistCommission >= 0, "Artist commission cannot be greater than 100 or less than 0");

     
    require(editionNumberToEditionDetails[_editionNumber].editionNumber == 0, "Edition already in existence");

     
    uint256 endDate = _endDate;
    if (_endDate == 0) {
      endDate = MAX_UINT32;
    }

    editionNumberToEditionDetails[_editionNumber] = EditionDetails({
      editionNumber : _editionNumber,
      editionData : _editionData,
      editionType : _editionType,
      startDate : _startDate,
      endDate : endDate,
      artistAccount : _artistAccount,
      artistCommission : _artistCommission,
      priceInWei : _priceInWei,
      tokenURI : _tokenURI,
      totalSupply : 0,  
      totalAvailable : _totalAvailable,
      active : _active
      });

     
    totalNumberAvailable = totalNumberAvailable.add(_totalAvailable);

     
    _updateArtistLookupData(_artistAccount, _editionNumber);
    _updateEditionTypeLookupData(_editionType, _editionNumber);

    emit EditionCreated(_editionNumber, _editionData, _editionType);

     
    highestEditionNumber = _editionNumber;

    return true;
  }

  function _updateEditionTypeLookupData(uint256 _editionType, uint256 _editionNumber) internal {
    uint256 typeEditionIndex = editionTypeToEditionNumber[_editionType].length;
    editionTypeToEditionNumber[_editionType].push(_editionNumber);
    editionNumberToTypeIndex[_editionNumber] = typeEditionIndex;
  }

  function _updateArtistLookupData(address _artistAccount, uint256 _editionNumber) internal {
    uint256 artistEditionIndex = artistToEditionNumbers[_artistAccount].length;
    artistToEditionNumbers[_artistAccount].push(_editionNumber);
    editionNumberToArtistIndex[_editionNumber] = artistEditionIndex;
  }

   
  function purchase(uint256 _editionNumber)
  public
  payable
  returns (uint256) {
    return purchaseTo(msg.sender, _editionNumber);
  }

   
  function purchaseTo(address _to, uint256 _editionNumber)
  public
  payable
  whenNotPaused
  onlyRealEdition(_editionNumber)
  onlyActiveEdition(_editionNumber)
  onlyAvailableEdition(_editionNumber)
  onlyPurchaseDuringWindow(_editionNumber)
  returns (uint256) {

    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    require(msg.value >= _editionDetails.priceInWei, "Value must be greater than price of edition");

     
    uint256 _tokenId = _nextTokenId(_editionNumber);

     
    _mintToken(_to, _tokenId, _editionNumber, _editionDetails.tokenURI);

     
    _handleFunds(_editionNumber, _editionDetails.priceInWei, _editionDetails.artistAccount, _editionDetails.artistCommission);

     
    emit Purchase(_tokenId, _editionNumber, _to, msg.value);

    return _tokenId;
  }

   
  function mint(address _to, uint256 _editionNumber)
  public
  onlyIfMinter
  onlyRealEdition(_editionNumber)
  onlyAvailableEdition(_editionNumber)
  returns (uint256) {
     
    uint256 _tokenId = _nextTokenId(_editionNumber);

     
    _mintToken(_to, _tokenId, _editionNumber, editionNumberToEditionDetails[_editionNumber].tokenURI);

     
    return _tokenId;
  }

   
  function underMint(address _to, uint256 _editionNumber)
  public
  onlyIfUnderMinter
  onlyRealEdition(_editionNumber)
  returns (uint256) {
     
    uint256 _tokenId = _underMintNextTokenId(_editionNumber);

     
    if (_tokenId > _editionNumber.add(editionNumberToEditionDetails[_editionNumber].totalAvailable)) {
      revert("Reached max tokenId, cannot under mint anymore");
    }

     
    _mintToken(_to, _tokenId, _editionNumber, editionNumberToEditionDetails[_editionNumber].tokenURI);

     
    return _tokenId;
  }

  function _nextTokenId(uint256 _editionNumber) internal returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

     
    _editionDetails.totalSupply = _editionDetails.totalSupply.add(1);

     
    return _editionDetails.editionNumber.add(_editionDetails.totalSupply);
  }

  function _underMintNextTokenId(uint256 _editionNumber) internal returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

     
    uint256 _tokenId = _editionDetails.editionNumber.add(1);

     
    while (exists(_tokenId)) {
      _tokenId = _tokenId.add(1);
    }

     
    if (_tokenId > _editionDetails.editionNumber.add(_editionDetails.totalSupply)) {
      _editionDetails.totalSupply = _editionDetails.totalSupply.add(1);
    }

    return _tokenId;
  }

  function _mintToken(address _to, uint256 _tokenId, uint256 _editionNumber, string _tokenURI) internal {

     
    super._mint(_to, _tokenId);
    super._setTokenURI(_tokenId, _tokenURI);

     
    tokenIdToEditionNumber[_tokenId] = _editionNumber;

     
    uint256 currentIndexOfTokenId = editionNumberToTokenIds[_editionNumber].length;

     
    editionNumberToTokenIds[_editionNumber].push(_tokenId);

     
    editionNumberToTokenIdIndex[_tokenId] = currentIndexOfTokenId;

     
    totalNumberMinted = totalNumberMinted.add(1);

     
    emit Minted(_tokenId, _editionNumber, _to);
  }

  function _handleFunds(uint256 _editionNumber, uint256 _priceInWei, address _artistAccount, uint256 _artistCommission) internal {

     
    uint256 artistPayment = _priceInWei.div(100).mul(_artistCommission);
    if (artistPayment > 0) {
      _artistAccount.transfer(artistPayment);
    }

     
    CommissionSplit storage commission = editionNumberToOptionalCommissionSplit[_editionNumber];

     
    if (commission.rate > 0) {
      uint256 rateSplit = _priceInWei.div(100).mul(commission.rate);
      commission.recipient.transfer(rateSplit);
    }

     
    uint256 remainingCommission = msg.value.sub(artistPayment).sub(rateSplit);
    koCommissionAccount.transfer(remainingCommission);

     
    totalPurchaseValueInWei = totalPurchaseValueInWei.add(msg.value);
  }

   
  function burn(uint256 _tokenId) public onlyIfKnownOrigin {

     
    super._burn(ownerOf(_tokenId), _tokenId);

     
    uint256 _editionNumber = tokenIdToEditionNumber[_tokenId];

     
    delete tokenIdToEditionNumber[_tokenId];

     
    uint256[] storage tokenIdsForEdition = editionNumberToTokenIds[_editionNumber];
    uint256 editionTokenIdIndex = editionNumberToTokenIdIndex[_tokenId];
    delete tokenIdsForEdition[editionTokenIdIndex];
  }

   
  function batchTransfer(address _to, uint256[] _tokenIds) public {
    for (uint i = 0; i < _tokenIds.length; i++) {
      safeTransferFrom(ownerOf(_tokenIds[i]), _to, _tokenIds[i]);
    }
  }

   
  function batchTransferFrom(address _from, address _to, uint256[] _tokenIds) public {
    for (uint i = 0; i < _tokenIds.length; i++) {
      transferFrom(_from, _to, _tokenIds[i]);
    }
  }

   
   
   

  function updateTokenBaseURI(string _newBaseURI)
  external
  onlyIfKnownOrigin {
    require(bytes(_newBaseURI).length != 0, "Base URI invalid");
    tokenBaseURI = _newBaseURI;
  }

  function updateKoCommissionAccount(address _koCommissionAccount)
  external
  onlyIfKnownOrigin {
    require(_koCommissionAccount != address(0), "Invalid address");
    koCommissionAccount = _koCommissionAccount;
  }

   
   
   

  function updateEditionTokenURI(uint256 _editionNumber, string _uri)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].tokenURI = _uri;
  }

  function updatePriceInWei(uint256 _editionNumber, uint256 _priceInWei)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].priceInWei = _priceInWei;
  }

  function updateArtistCommission(uint256 _editionNumber, uint256 _rate)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].artistCommission = _rate;
  }

  function updateArtistsAccount(uint256 _editionNumber, address _artistAccount)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {

    EditionDetails storage _originalEditionDetails = editionNumberToEditionDetails[_editionNumber];

    uint256 editionArtistIndex = editionNumberToArtistIndex[_editionNumber];

     
    uint256[] storage editionNumbersForArtist = artistToEditionNumbers[_originalEditionDetails.artistAccount];

     
    delete editionNumbersForArtist[editionArtistIndex];

     
    uint256 newArtistsEditionIndex = artistToEditionNumbers[_artistAccount].length;
    artistToEditionNumbers[_artistAccount].push(_editionNumber);
    editionNumberToArtistIndex[_editionNumber] = newArtistsEditionIndex;

     
    _originalEditionDetails.artistAccount = _artistAccount;
  }

  function updateEditionType(uint256 _editionNumber, uint256 _editionType)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {

    EditionDetails storage _originalEditionDetails = editionNumberToEditionDetails[_editionNumber];

     
    uint256[] storage editionNumbersForType = editionTypeToEditionNumber[_originalEditionDetails.editionType];

     
    uint256 editionTypeIndex = editionNumberToTypeIndex[_editionNumber];
    delete editionNumbersForType[editionTypeIndex];

     
    uint256 newTypeEditionIndex = editionTypeToEditionNumber[_editionType].length;
    editionTypeToEditionNumber[_editionType].push(_editionNumber);
    editionNumberToTypeIndex[_editionNumber] = newTypeEditionIndex;

     
    _originalEditionDetails.editionType = _editionType;
  }

  function updateActive(uint256 _editionNumber, bool _active)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].active = _active;
  }

  function updateTotalSupply(uint256 _editionNumber, uint256 _totalSupply)
  public
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    require(tokensOfEdition(_editionNumber).length <= _totalSupply, "Can not lower totalSupply to below the number of tokens already in existence");
    editionNumberToEditionDetails[_editionNumber].totalSupply = _totalSupply;
  }

  function updateTotalAvailable(uint256 _editionNumber, uint256 _totalAvailable)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];

    require(_editionDetails.totalSupply <= _totalAvailable, "Unable to reduce available amount to the below the number totalSupply");

    uint256 originalAvailability = _editionDetails.totalAvailable;
    _editionDetails.totalAvailable = _totalAvailable;
    totalNumberAvailable = totalNumberAvailable.sub(originalAvailability).add(_totalAvailable);
  }

  function updateStartDate(uint256 _editionNumber, uint256 _startDate)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].startDate = _startDate;
  }

  function updateEndDate(uint256 _editionNumber, uint256 _endDate)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    editionNumberToEditionDetails[_editionNumber].endDate = _endDate;
  }

  function updateOptionalCommission(uint256 _editionNumber, uint256 _rate, address _recipient)
  external
  onlyIfKnownOrigin
  onlyRealEdition(_editionNumber) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    uint256 artistCommission = _editionDetails.artistCommission;

    if (_rate > 0) {
      require(_recipient != address(0), "Setting a rate must be accompanied by a valid address");
    }
    require(artistCommission.add(_rate) <= 100, "Cant set commission greater than 100%");

    editionNumberToOptionalCommissionSplit[_editionNumber] = CommissionSplit({rate : _rate, recipient : _recipient});
  }

   
   
   

  function setTokenURI(uint256 _tokenId, string _uri)
  external
  onlyIfKnownOrigin
  onlyValidTokenId(_tokenId) {
    _setTokenURI(_tokenId, _uri);
  }

   
   
   

   
  function editionOfTokenId(uint256 _tokenId) public view returns (uint256 _editionNumber) {
    return tokenIdToEditionNumber[_tokenId];
  }

   
  function editionsOfType(uint256 _type) public view returns (uint256[] _editionNumbers) {
    return editionTypeToEditionNumber[_type];
  }

   
  function artistsEditions(address _artistsAccount) public view returns (uint256[] _editionNumbers) {
    return artistToEditionNumbers[_artistsAccount];
  }

   
  function tokensOfEdition(uint256 _editionNumber) public view returns (uint256[] _tokenIds) {
    return editionNumberToTokenIds[_editionNumber];
  }

   
  function tokensOf(address _owner) public view returns (uint256[] _tokenIds) {
    return ownedTokens[_owner];
  }

   
  function editionExists(uint256 _editionNumber) public view returns (bool) {
    if (_editionNumber == 0) {
      return false;
    }
    EditionDetails storage editionNumber = editionNumberToEditionDetails[_editionNumber];
    return editionNumber.editionNumber == _editionNumber;
  }

   
  function editionOptionalCommission(uint256 _editionNumber) public view returns (uint256 _rate, address _recipient) {
    CommissionSplit storage commission = editionNumberToOptionalCommissionSplit[_editionNumber];
    return (commission.rate, commission.recipient);
  }

   
  function detailsOfEdition(uint256 editionNumber)
  public view
  onlyRealEdition(editionNumber)
  returns (
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenURI,
    uint256 _totalSupply,
    uint256 _totalAvailable,
    bool _active
  ) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[editionNumber];
    return (
    _editionDetails.editionData,
    _editionDetails.editionType,
    _editionDetails.startDate,
    _editionDetails.endDate,
    _editionDetails.artistAccount,
    _editionDetails.artistCommission,
    _editionDetails.priceInWei,
    Strings.strConcat(tokenBaseURI, _editionDetails.tokenURI),
    _editionDetails.totalSupply,
    _editionDetails.totalAvailable,
    _editionDetails.active
    );
  }

   
  function tokenData(uint256 _tokenId)
  public view
  onlyValidTokenId(_tokenId)
  returns (
    uint256 _editionNumber,
    uint256 _editionType,
    bytes32 _editionData,
    string _tokenURI,
    address _owner
  ) {
    uint256 editionNumber = tokenIdToEditionNumber[_tokenId];
    EditionDetails storage editionDetails = editionNumberToEditionDetails[editionNumber];
    return (
    editionNumber,
    editionDetails.editionType,
    editionDetails.editionData,
    tokenURI(_tokenId),
    ownerOf(_tokenId)
    );
  }

  function tokenURI(uint256 _tokenId) public view onlyValidTokenId(_tokenId) returns (string) {
    return Strings.strConcat(tokenBaseURI, tokenURIs[_tokenId]);
  }

  function tokenURISafe(uint256 _tokenId) public view returns (string) {
    return Strings.strConcat(tokenBaseURI, tokenURIs[_tokenId]);
  }

  function purchaseDatesToken(uint256 _tokenId) public view returns (uint256 _startDate, uint256 _endDate) {
    uint256 _editionNumber = tokenIdToEditionNumber[_tokenId];
    return purchaseDatesEdition(_editionNumber);
  }

  function priceInWeiToken(uint256 _tokenId) public view returns (uint256 _priceInWei) {
    uint256 _editionNumber = tokenIdToEditionNumber[_tokenId];
    return priceInWeiEdition(_editionNumber);
  }

   
   
   

  function editionData(uint256 _editionNumber) public view returns (bytes32) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.editionData;
  }

  function editionType(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.editionType;
  }

  function purchaseDatesEdition(uint256 _editionNumber) public view returns (uint256 _startDate, uint256 _endDate) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return (
    _editionDetails.startDate,
    _editionDetails.endDate
    );
  }

  function artistCommission(uint256 _editionNumber) public view returns (address _artistAccount, uint256 _artistCommission) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return (
    _editionDetails.artistAccount,
    _editionDetails.artistCommission
    );
  }

  function priceInWeiEdition(uint256 _editionNumber) public view returns (uint256 _priceInWei) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.priceInWei;
  }

  function tokenURIEdition(uint256 _editionNumber) public view returns (string) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return Strings.strConcat(tokenBaseURI, _editionDetails.tokenURI);
  }

  function editionActive(uint256 _editionNumber) public view returns (bool) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.active;
  }

  function totalRemaining(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalAvailable.sub(_editionDetails.totalSupply);
  }

  function totalAvailableEdition(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalAvailable;
  }

  function totalSupplyEdition(uint256 _editionNumber) public view returns (uint256) {
    EditionDetails storage _editionDetails = editionNumberToEditionDetails[_editionNumber];
    return _editionDetails.totalSupply;
  }

}