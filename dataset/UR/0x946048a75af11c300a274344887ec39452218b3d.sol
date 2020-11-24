 

pragma solidity 0.4.24;

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
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

  constructor() public {
    minters.add(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public {
    minters.remove(msg.sender);
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

 

 
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal _supportedInterfaces;

   
  constructor()
    public
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

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

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
     
    require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
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

   
  function _clearApproval(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
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

   
  function _checkAndCallSafeTransfer(
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
  function tokenURI(uint256 tokenId) public view returns (string);
}

 

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
   
  string internal _name;

   
  string internal _symbol;

   
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

   
  function tokenURI(uint256 tokenId) public view returns (string) {
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

 

 
contract ERC721Mintable is ERC721Full, MinterRole {
  event MintingFinished();

  bool private _mintingFinished = false;

  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }

   
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }

   
  function mint(
    address to,
    uint256 tokenId
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mint(to, tokenId);
    return true;
  }

  function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string tokenURI
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    mint(to, tokenId);
    _setTokenURI(tokenId, tokenURI);
    return true;
  }

   
  function finishMinting()
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }
}

 

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() public {
    pausers.add(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function renouncePauser() public {
    pausers.remove(msg.sender);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 

 
contract Pausable is PauserRole {
  event Paused();
  event Unpaused();

  bool private _paused = false;


   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

 

 
contract ERC721Pausable is ERC721, Pausable {
  function approve(
    address to,
    uint256 tokenId
  )
    public
    whenNotPaused
  {
    super.approve(to, tokenId);
  }

  function setApprovalForAll(
    address to,
    bool approved
  )
    public
    whenNotPaused
  {
    super.setApprovalForAll(to, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    whenNotPaused
  {
    super.transferFrom(from, to, tokenId);
  }
}

 

contract HeroAsset is ERC721Mintable, ERC721Pausable {

    uint16 public constant HERO_TYPE_OFFSET = 10000;

    string public tokenURIPrefix = "https://www.mycryptoheroes.net/metadata/hero/";
    mapping(uint16 => uint16) private heroTypeToSupplyLimit;

    constructor() public ERC721Full("MyCryptoHeroes:Hero", "MCHH") {}

    function setSupplyLimit(uint16 _heroType, uint16 _supplyLimit) external onlyMinter {
        require(heroTypeToSupplyLimit[_heroType] == 0 || _supplyLimit < heroTypeToSupplyLimit[_heroType],
            "_supplyLimit is bigger");
        heroTypeToSupplyLimit[_heroType] = _supplyLimit;
    }

    function setTokenURIPrefix(string _tokenURIPrefix) external onlyMinter {
        tokenURIPrefix = _tokenURIPrefix;
    }

    function getSupplyLimit(uint16 _heroType) public view returns (uint16) {
        return heroTypeToSupplyLimit[_heroType];
    }

    function mintHeroAsset(address _owner, uint256 _tokenId) public onlyMinter {
        uint16 _heroType = uint16(_tokenId / HERO_TYPE_OFFSET);
        uint16 _heroTypeIndex = uint16(_tokenId % HERO_TYPE_OFFSET) - 1;
        require(_heroTypeIndex < heroTypeToSupplyLimit[_heroType], "supply over");
        _mint(_owner, _tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string) {
        bytes32 tokenIdBytes;
        if (tokenId == 0) {
            tokenIdBytes = "0";
        } else {
            uint256 value = tokenId;
            while (value > 0) {
                tokenIdBytes = bytes32(uint256(tokenIdBytes) / (2 ** 8));
                tokenIdBytes |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
                value /= 10;
            }
        }

        bytes memory prefixBytes = bytes(tokenURIPrefix);
        bytes memory tokenURIBytes = new bytes(prefixBytes.length + tokenIdBytes.length);

        uint8 i;
        uint8 index = 0;
        
        for (i = 0; i < prefixBytes.length; i++) {
            tokenURIBytes[index] = prefixBytes[i];
            index++;
        }
        
        for (i = 0; i < tokenIdBytes.length; i++) {
            tokenURIBytes[index] = tokenIdBytes[i];
            index++;
        }
        
        return string(tokenURIBytes);
    }

}

 

 
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    _owner = msg.sender;
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
    emit OwnershipRenounced(_owner);
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

 

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

   
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}

 

 
contract ReentrancyGuard {

   
  uint256 private _guardCounter = 1;

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

 

contract HeroPresale is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    struct HeroSale {
        uint128 highestPrice;
        uint128 previousPrice;
        uint128 priceIncreaseTo;
        uint64  since;
        uint64  until;
        uint64  previousSaleAt;
        uint16  lowestPriceRate;
        uint16  decreaseRate;
        uint16  supplyLimit;
        uint16  suppliedCounts;
        uint8   currency;
        bool    exists;
    }
    
    mapping(uint16 => HeroSale) public heroTypeToHeroSales;
    mapping(uint16 => uint256[]) public heroTypeIds;
    mapping(uint16 => mapping(address => bool)) public hasAirDropHero;

    ERC20 public coin;
    HeroAsset public heroAsset;
    uint16 constant internal SUPPLY_LIMIT_MAX = 10000;

    event AddSalesEvent(
        uint16 indexed heroType,
        uint128 startPrice,
        uint256 lowestPrice,
        uint256 becomeLowestAt
    );

    event SoldHeroEvent(
        uint16 indexed heroType,
        uint256 soldPrice,
        uint64  soldAt,
        uint256 priceIncreaseTo,
        uint256 lowestPrice,
        uint256 becomeLowestAt,
        address purchasedBy,
        address indexed code,
        uint8   currency
    );

    function setHeroAssetAddress(address _heroAssetAddress) external onlyOwner() {
        heroAsset = HeroAsset(_heroAssetAddress);
    }

    function setCoinAddress(ERC20 _coinAddress) external onlyOwner() {
        coin = _coinAddress;
    }

    function withdrawEther() external onlyOwner() {
        owner().transfer(address(this).balance);
    }

    function withdrawEMONT() external onlyOwner() {
        uint256 emontBalance = coin.balanceOf(this);
        coin.approve(address(this), emontBalance);
        coin.transferFrom(address(this), msg.sender, emontBalance);
    }

    function addSales(
        uint16 _heroType,
        uint128 _startPrice,
        uint16 _lowestPriceRate,
        uint16 _decreaseRate,
        uint64 _since,
        uint64 _until,
        uint16 _supplyLimit,
        uint8  _currency
    ) external onlyOwner() {
        require(!heroTypeToHeroSales[_heroType].exists, "this heroType is already added sales");
        require(0 <= _lowestPriceRate && _lowestPriceRate <= 100, "lowestPriceRate should be between 0 and 100");
        require(1 <= _decreaseRate && _decreaseRate <= 100, "decreaseRate should be should be between 1 and 100");
        require (_until > _since, "until should be later than since");

        HeroSale memory _herosale = HeroSale({
            highestPrice: _startPrice,
            previousPrice: _startPrice,
            priceIncreaseTo: _startPrice,
            since:_since,
            until:_until,
            previousSaleAt: _since,
            lowestPriceRate: _lowestPriceRate,
            decreaseRate: _decreaseRate,
            supplyLimit:_supplyLimit,
            suppliedCounts: 0,
            currency: _currency,
            exists: true
        });

        heroTypeToHeroSales[_heroType] = _herosale;
        heroAsset.setSupplyLimit(_heroType, _supplyLimit);

        uint256 _lowestPrice = uint256(_startPrice).mul(_lowestPriceRate).div(100);
        uint256 _becomeLowestAt = uint256(86400).mul(uint256(100).sub(_lowestPriceRate)).div(_decreaseRate).add(_since);

        emit AddSalesEvent(
            _heroType,
            _startPrice,
            _lowestPrice,
            _becomeLowestAt
        );
    }

    function purchase(uint16 _heroType, address _code) external whenNotPaused() nonReentrant() payable {
     
        return purchaseImpl(_heroType, uint64(block.timestamp), _code);
    }

    function purchaseByEMONT(uint16 _heroType, uint256 _price, address _code) external whenNotPaused() {
       
        return purchaseByEMONTImpl(_heroType, _price, uint64(block.timestamp), _code);
    }

    function airDrop(uint16 _heroType) external whenNotPaused() {
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(airDropHero(_heroType), "currency is not 2 (airdrop)");
        require(!hasAirDropHero[_heroType][msg.sender]);
        uint64 _at = uint64(block.timestamp);
        require(isOnSale(_heroType, _at), "out of sales period");

        createHero(_heroType, msg.sender);
        hasAirDropHero[_heroType][msg.sender] = true;
        heroSales.suppliedCounts++;
        heroSales.previousSaleAt = _at;

        emit SoldHeroEvent(
            _heroType,
            1,
            _at,
            1,
            1,
            1,
            msg.sender,
            0x0000000000000000000000000000000000000000,
            2
        );
    }


    function computeCurrentPrice(uint16 _heroType) external view returns (uint8, uint256){
         
        return computeCurrentPriceImpl(_heroType, uint64(block.timestamp));
    }

    function canBePurchasedByETH(uint16 _heroType) internal view returns (bool){
        return (heroTypeToHeroSales[_heroType].currency == 0);
    }

    function canBePurchasedByEMONT(uint16 _heroType) internal view returns (bool){
        return (heroTypeToHeroSales[_heroType].currency == 1);
    }

    function airDropHero(uint16 _heroType) internal view returns (bool){
        return (heroTypeToHeroSales[_heroType].currency == 2);
    }

    function isOnSale(uint16 _heroType, uint64 _now) internal view returns (bool){
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(heroSales.exists, "not exist sales of this heroType");

        if (heroSales.since <= _now && _now <= heroSales.until) {
            return true;
        } else {
            return false;
        }
    }

    function computeCurrentPriceImpl(uint16 _heroType, uint64 _at) internal view returns (uint8, uint256) {
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(heroSales.exists, "not exist sales of this heroType");
        require(heroSales.previousSaleAt < _at, "current timestamp should be later than previousSaleAt");

        uint256 _lowestPrice = uint256(heroSales.highestPrice).mul(heroSales.lowestPriceRate).div(100);
        uint256 _secondsPassed = uint256(_at).sub(heroSales.previousSaleAt);
        uint256 _decreasedPrice = uint256(heroSales.priceIncreaseTo).mul(_secondsPassed).mul(heroSales.decreaseRate).div(100).div(86400);
        uint256 currentPrice;

        if (uint256(heroSales.priceIncreaseTo).sub(_lowestPrice) > _decreasedPrice){
            currentPrice = uint256(heroSales.priceIncreaseTo).sub(_decreasedPrice);
        } else {
            currentPrice = _lowestPrice;
        }

        return (1, currentPrice);
    }

    function purchaseImpl(uint16 _heroType, uint64 _at, address code)
        internal
    {
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(canBePurchasedByETH(_heroType), "currency is not 0 (eth)");
        require(isOnSale(_heroType, _at), "out of sales period");
        (,uint256 _price)  = computeCurrentPriceImpl(_heroType, _at);
        require(msg.value >= _price, "value is less than the price");

        createHero(_heroType, msg.sender);

        if (msg.value > _price){
            msg.sender.transfer(msg.value.sub(_price));
        }

        heroSales.previousPrice = uint128(_price);
        heroSales.suppliedCounts++;
        heroSales.previousSaleAt = _at;

        if (heroSales.previousPrice > heroSales.highestPrice){
            heroSales.highestPrice = heroSales.previousPrice;
        }

        uint256 _priceIncreaseTo;
        uint256 _lowestPrice;
        uint256 _becomeLowestAt;

        if(heroSales.supplyLimit > heroSales.suppliedCounts){
            _priceIncreaseTo = SafeMath.add(_price, _price.div((uint256(heroSales.supplyLimit).sub(heroSales.suppliedCounts))));
            heroSales.priceIncreaseTo = uint128(_priceIncreaseTo);
            _lowestPrice = uint256(heroSales.lowestPriceRate).mul(heroSales.highestPrice).div(100);
            _becomeLowestAt = uint256(86400).mul(100).mul((_priceIncreaseTo.sub(_lowestPrice))).div(_priceIncreaseTo).div(heroSales.decreaseRate).add(_at);
        } else {
            _priceIncreaseTo = heroSales.previousPrice;
            heroSales.priceIncreaseTo = uint128(_priceIncreaseTo);
            _lowestPrice = heroSales.previousPrice;
            _becomeLowestAt = _at;
        }

        address Invitees;

        if (code == msg.sender){
            Invitees = address(0x0);
        } else {
            Invitees = code;
        }

        emit SoldHeroEvent(
            _heroType,
            _price,
            _at,
            _priceIncreaseTo,
            _lowestPrice,
            _becomeLowestAt,
            msg.sender,
            Invitees,
            0
        );

    }

    function purchaseByEMONTImpl(uint16 _heroType, uint256 _inputPrice, uint64 _at, address _code)
        internal
    {
        HeroSale storage heroSales = heroTypeToHeroSales[_heroType];
        require(canBePurchasedByEMONT(_heroType), "currency is not 1 (EMONT)");
        require(isOnSale(_heroType, _at), "out of sales period");
        (,uint256 _price)  = computeCurrentPriceImpl(_heroType, _at);
        require(_inputPrice > _price, "input price is not more than actual price");

        createHero(_heroType, msg.sender);
        coin.transferFrom(msg.sender, address(this), _price);

        heroSales.previousPrice = uint128(_price);
        heroSales.suppliedCounts++;
        heroSales.previousSaleAt = _at;

        if (heroSales.previousPrice > heroSales.highestPrice){
            heroSales.highestPrice = heroSales.previousPrice;
        }

        uint256 _priceIncreaseTo;
        uint256 _lowestPrice;
        uint256 _becomeLowestAt;

        if(heroSales.supplyLimit > heroSales.suppliedCounts){
            _priceIncreaseTo = SafeMath.add(_price, _price.div((uint256(heroSales.supplyLimit).sub(heroSales.suppliedCounts))));
            heroSales.priceIncreaseTo = uint128(_priceIncreaseTo);
            _lowestPrice = uint256(heroSales.lowestPriceRate).mul(heroSales.highestPrice).div(100);
            _becomeLowestAt = uint256(86400).mul(100).mul((_priceIncreaseTo.sub(_lowestPrice))).div(_priceIncreaseTo).div(heroSales.decreaseRate).add(_at);
        } else {
            _priceIncreaseTo = heroSales.previousPrice;
            heroSales.priceIncreaseTo = uint128(_priceIncreaseTo);
            _lowestPrice = heroSales.previousPrice;
            _becomeLowestAt = _at;
        }

        address Invitees;

        if (_code == msg.sender){
            Invitees = address(0x0);
        } else {
            Invitees = _code;
        }

        emit SoldHeroEvent(
            _heroType,
            _price,
            _at,
            _priceIncreaseTo,
            _lowestPrice,
            _becomeLowestAt,
            msg.sender,
            Invitees,
            1
        );

    }

    function createHero(uint16 _heroType, address _owner) internal {
        require(heroTypeToHeroSales[_heroType].exists, "not exist sales of this heroType");
        require(heroTypeIds[_heroType].length < heroTypeToHeroSales[_heroType].supplyLimit, "Heroes cant be created more than supplyLimit");

        uint256 _heroId = uint256(_heroType).mul(SUPPLY_LIMIT_MAX).add(heroTypeIds[_heroType].length).add(1);
        heroTypeIds[_heroType].push(_heroId);
        heroAsset.mintHeroAsset(_owner, _heroId);
    }
}