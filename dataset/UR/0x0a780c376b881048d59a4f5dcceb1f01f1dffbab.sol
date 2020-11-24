 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

 

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

 

 
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

 

 
contract IERC721Receiver {
   
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

 

 
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) private _supportedInterfaces;

   
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

   
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

 

 
contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

   
   
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) private _tokenOwner;

   
  mapping (uint256 => address) private _tokenApprovals;

   
  mapping (address => uint256) private _ownedTokensCount;

   
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
   

  constructor()
    public
  {
     
    _registerInterface(_InterfaceId_ERC721);
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

   
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

   
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

   
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

   
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
     
    safeTransferFrom(from, to, tokenId, "");
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
     
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

   
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

   
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
     
     
     
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

   
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

   
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

   
  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

 

 
contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

 

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
   
  mapping(address => uint256[]) private _ownedTokens;

   
  mapping(uint256 => uint256) private _ownedTokensIndex;

   
  uint256[] private _allTokens;

   
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
   

   
  constructor() public {
     
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

   
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

   
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

   
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);

     
     
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];

    _ownedTokens[from][tokenIndex] = lastToken;
     
    _ownedTokens[from].length--;

     
     
     

    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}

 

 
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}

 

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
   
  string private _name;

   
  string private _symbol;

   
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;

     
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return _name;
  }

   
  function symbol() external view returns (string) {
    return _symbol;
  }

   
  function tokenURI(uint256 tokenId) external view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

   
  function _setTokenURI(uint256 tokenId, string uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

 

 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

 
contract TokenRecover is Ownable {

   
  function recoverERC20(
    address tokenAddress,
    uint256 tokenAmount
  )
    public
    onlyOwner
  {
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
  }
}

 

contract StructureInterface {
  function getValue (uint256 _id) public view returns (uint256);
}


 
library StructuredLinkedList {

  uint256 constant NULL = 0;
  uint256 constant HEAD = 0;
  bool constant PREV = false;
  bool constant NEXT = true;

  struct List {
    mapping (uint256 => mapping (bool => uint256)) list;
  }

   
  function listExists(
    List storage self
  )
  internal
  view
  returns (bool)
  {
     
    if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
      return true;
    } else {
      return false;
    }
  }

   
  function nodeExists(
    List storage self,
    uint256 _node
  )
  internal
  view
  returns (bool)
  {
    if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
      if (self.list[HEAD][NEXT] == _node) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

   
  function sizeOf(
    List storage self
  )
  internal
  view
  returns (uint256)
  {
    bool exists;
    uint256 i;
    uint256 numElements;
    (exists, i) = getAdjacent(self, HEAD, NEXT);
    while (i != HEAD) {
      (exists, i) = getAdjacent(self, i, NEXT);
      numElements++;
    }
    return numElements;
  }

   
  function getNode(
    List storage self,
    uint256 _node
  )
  internal
  view
  returns (bool, uint256, uint256)
  {
    if (!nodeExists(self, _node)) {
      return (false, 0, 0);
    } else {
      return (true, self.list[_node][PREV], self.list[_node][NEXT]);
    }
  }

   
  function getAdjacent(
    List storage self,
    uint256 _node,
    bool _direction
  )
  internal
  view
  returns (bool, uint256)
  {
    if (!nodeExists(self, _node)) {
      return (false, 0);
    } else {
      return (true, self.list[_node][_direction]);
    }
  }

   
  function getNextNode(
    List storage self,
    uint256 _node
  )
  internal
  view
  returns (bool, uint256)
  {
    return getAdjacent(self, _node, NEXT);
  }

   
  function getPreviousNode(
    List storage self,
    uint256 _node
  )
  internal
  view
  returns (bool, uint256)
  {
    return getAdjacent(self, _node, PREV);
  }

   
  function getSortedSpot(
    List storage self,
    address _structure,
    uint256 _value
  )
  internal view returns (uint256)
  {
    if (sizeOf(self) == 0) {
      return 0;
    }
    bool exists;
    uint256 next;
    (exists, next) = getAdjacent(self, HEAD, NEXT);
    while (
      (next != 0) && ((_value < StructureInterface(_structure).getValue(next)) != NEXT)
    ) {
      next = self.list[next][NEXT];
    }
    return next;
  }

   
  function createLink(
    List storage self,
    uint256 _node,
    uint256 _link,
    bool _direction
  )
  internal
  {
    self.list[_link][!_direction] = _node;
    self.list[_node][_direction] = _link;
  }

   
  function insert(
    List storage self,
    uint256 _node,
    uint256 _new,
    bool _direction
  )
  internal returns (bool)
  {
    if (!nodeExists(self, _new) && nodeExists(self, _node)) {
      uint256 c = self.list[_node][_direction];
      createLink(
        self,
        _node,
        _new,
        _direction
      );
      createLink(
        self,
        _new,
        c,
        _direction
      );
      return true;
    } else {
      return false;
    }
  }

   
  function insertAfter(
    List storage self,
    uint256 _node,
    uint256 _new
  )
  internal
  returns (bool)
  {
    return insert(
      self,
      _node,
      _new,
      NEXT
    );
  }

   
  function insertBefore(
    List storage self,
    uint256 _node,
    uint256 _new
  )
  internal
  returns (bool)
  {
    return insert(
      self,
      _node,
      _new,
      PREV
    );
  }

   
  function remove(
    List storage self,
    uint256 _node
  )
  internal
  returns (uint256)
  {
    if ((_node == NULL) || (!nodeExists(self, _node))) {
      return 0;
    }
    createLink(
      self,
      self.list[_node][PREV],
      self.list[_node][NEXT],
      NEXT
    );
    delete self.list[_node][PREV];
    delete self.list[_node][NEXT];
    return _node;
  }

   
  function push(
    List storage self,
    uint256 _node,
    bool _direction
  )
  internal
  returns (bool)
  {
    return insert(
      self,
      HEAD,
      _node,
      _direction
    );
  }

   
  function pop(
    List storage self,
    bool _direction
  )
  internal
  returns (uint256)
  {
    bool exists;
    uint256 adj;

    (exists, adj) = getAdjacent(self, HEAD, _direction);

    return remove(self, adj);
  }
}

 

contract WallOfChainToken is ERC721Full, TokenRecover, MinterRole {
  using StructuredLinkedList for StructuredLinkedList.List;

  StructuredLinkedList.List list;

  struct WallStructure {
    uint256 value;
    string firstName;
    string lastName;
    uint256 pattern;
    uint256 icon;
  }

  bool public mintingFinished = false;

  uint256 public progressiveId = 0;

   
  mapping(uint256 => WallStructure) structureIndex;

  modifier canGenerate() {
    require(
      !mintingFinished,
      "Minting is finished"
    );
    _;
  }

  constructor(string _name, string _symbol) public
  ERC721Full(_name, _symbol)
  {}

   
  function finishMinting() public onlyOwner canGenerate {
    mintingFinished = true;
  }

  function newToken(
    address _beneficiary,
    uint256 _value,
    string _firstName,
    string _lastName,
    uint256 _pattern,
    uint256 _icon
  )
    public
    canGenerate
    onlyMinter
    returns (uint256)
  {
    uint256 tokenId = progressiveId.add(1);
    _mint(_beneficiary, tokenId);
    structureIndex[tokenId] = WallStructure(
      _value,
      _firstName,
      _lastName,
      _value == 0 ? 0 : _pattern,
      _value == 0 ? 0 : _icon
    );
    progressiveId = tokenId;

    uint256 position = list.getSortedSpot(StructureInterface(this), _value);
    list.insertBefore(position, tokenId);

    return tokenId;
  }

  function editToken (
    uint256 _tokenId,
    uint256 _value,
    string _firstName,
    string _lastName,
    uint256 _pattern,
    uint256 _icon
  )
    public
    onlyMinter
    returns (uint256)
  {
    require(
      _exists(_tokenId),
      "Token must exists"
    );

    uint256 value = getValue(_tokenId);

    if (_value > 0) {
      value = value.add(_value);  

       
      list.remove(_tokenId);
      uint256 position = list.getSortedSpot(StructureInterface(this), value);
      list.insertBefore(position, _tokenId);
    }

    structureIndex[_tokenId] = WallStructure(
      value,
      _firstName,
      _lastName,
      value == 0 ? 0 : _pattern,
      value == 0 ? 0 : _icon
    );

    return _tokenId;
  }

  function getWall (
    uint256 _tokenId
  )
    public
    view
    returns (
      address tokenOwner,
      uint256 value,
      string firstName,
      string lastName,
      uint256 pattern,
      uint256 icon
    )
  {
    require(
      _exists(_tokenId),
      "Token must exists"
    );

    WallStructure storage wall = structureIndex[_tokenId];

    tokenOwner = ownerOf(_tokenId);

    value = wall.value;
    firstName = wall.firstName;
    lastName = wall.lastName;
    pattern = wall.pattern;
    icon = wall.icon;
  }

  function getValue (uint256 _tokenId) public view returns (uint256) {
    require(
      _exists(_tokenId),
      "Token must exists"
    );
    WallStructure storage wall = structureIndex[_tokenId];
    return wall.value;
  }

  function getNextNode(uint256 _tokenId) public view returns (bool, uint256) {
    return list.getNextNode(_tokenId);
  }

  function getPreviousNode(
    uint256 _tokenId
  )
    public
    view
    returns (bool, uint256)
  {
    return list.getPreviousNode(_tokenId);
  }

   
  function burn(uint256 _tokenId) public {
    address tokenOwner = isOwner() ? ownerOf(_tokenId) : msg.sender;
    super._burn(tokenOwner, _tokenId);
    list.remove(_tokenId);
    delete structureIndex[_tokenId];
  }
}

 

contract WallOfChainMarket is TokenRecover {
  using SafeMath for uint256;

   
  WallOfChainToken public token;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 tokenId
  );

   
  event TokenEdit(
    address indexed beneficiary,
    uint256 value,
    uint256 tokenId
  );

   
  constructor(address _wallet, WallOfChainToken _token) public {
    require(
      _wallet != address(0),
      "Wallet can't be the zero address"
    );
    require(
      _token != address(0),
      "Token can't be the zero address"
    );

    wallet = _wallet;
    token = _token;
  }

   
  function buyToken(
    address _beneficiary,
    string _firstName,
    string _lastName,
    uint256 _pattern,
    uint256 _icon
  )
    public
    payable
  {
    uint256 weiAmount = msg.value;

    _preValidatePurchase(_beneficiary);

     
    weiRaised = weiRaised.add(weiAmount);

    uint256 lastTokenId = _processPurchase(
      _beneficiary,
      weiAmount,
      _firstName,
      _lastName,
      _pattern,
      _icon
    );

    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      lastTokenId
    );

    _forwardFunds();
  }

   
  function editToken(
    uint256 _tokenId,
    string _firstName,
    string _lastName,
    uint256 _pattern,
    uint256 _icon
  )
    public
    payable
  {
    address tokenOwner = token.ownerOf(_tokenId);
    require(msg.sender == tokenOwner, "Sender must be token owner");

     
    uint256 weiAmount = msg.value;
    weiRaised = weiRaised.add(weiAmount);

    uint256 currentTokenId = _processEdit(
      _tokenId,
      weiAmount,
      _firstName,
      _lastName,
      _pattern,
      _icon
    );

    emit TokenEdit(
      tokenOwner,
      weiAmount,
      currentTokenId
    );

    _forwardFunds();
  }

   
  function changeWallet(address _newWallet) public onlyOwner {
    require(
      _newWallet != address(0),
      "Wallet can't be the zero address"
    );

    wallet = _newWallet;
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary
  )
    internal
    pure
  {
    require(
      _beneficiary != address(0),
      "Beneficiary can't be the zero address"
    );
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _weiAmount,
    string _firstName,
    string _lastName,
    uint256 _pattern,
    uint256 _icon
  )
    internal
    returns (uint256)
  {
    return token.newToken(
      _beneficiary,
      _weiAmount,
      _firstName,
      _lastName,
      _pattern,
      _icon
    );
  }

   
  function _processEdit(
    uint256 _tokenId,
    uint256 _weiAmount,
    string _firstName,
    string _lastName,
    uint256 _pattern,
    uint256 _icon
  )
    internal
    returns (uint256)
  {
    return token.editToken(
      _tokenId,
      _weiAmount,
      _firstName,
      _lastName,
      _pattern,
      _icon
    );
  }

   
  function _forwardFunds() internal {
    if (msg.value > 0) {
      wallet.transfer(msg.value);
    }
  }
}