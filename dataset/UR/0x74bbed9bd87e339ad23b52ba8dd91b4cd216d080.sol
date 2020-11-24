 

pragma solidity ^0.4.24;

 

 
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

 

contract HarbergerTaxable is Ownable {
  using SafeMath for uint256;

  uint256 public taxPercentage;
  address public taxCollector;
  address public ethFoundation;
  uint256 public currentFoundationContribution;
  uint256 public ethFoundationPercentage;
  uint256 public taxCollectorPercentage;

  event UpdateCollector(address indexed newCollector);
  event UpdateTaxPercentages(uint256 indexed newEFPercentage, uint256 indexed newTaxCollectorPercentage);

  constructor(uint256 _taxPercentage, address _taxCollector) public {
    taxPercentage = _taxPercentage;
    taxCollector = _taxCollector;
    ethFoundation = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;
    ethFoundationPercentage = 20;
    taxCollectorPercentage = 80;
  }

   
  mapping(address => uint256) public valueHeld;

   
  mapping(address => uint256) public lastPaidTaxes;

   
  mapping(address => uint256) public userBalanceAtLastPaid;

   

  modifier hasPositveBalance(address user) {
    require(userHasPositveBalance(user) == true, "User has a negative balance");
    _;
  }

   

  function updateCollector(address _newCollector)
    public
    onlyOwner
  {
    require(_newCollector != address(0));
    taxCollector == _newCollector;
    emit UpdateCollector(_newCollector);
  }

  function updateTaxPercentages(uint256 _newEFPercentage, uint256 _newTaxCollectorPercentage)
    public
    onlyOwner
  {
    require(_newEFPercentage < 100);
    require(_newTaxCollectorPercentage < 100);
    require(_newEFPercentage.add(_newTaxCollectorPercentage) == 100);

    ethFoundationPercentage = _newEFPercentage;
    taxCollectorPercentage = _newTaxCollectorPercentage;
    emit UpdateTaxPercentages(_newEFPercentage, _newTaxCollectorPercentage);
  }

  function addFunds()
    public
    payable
  {
    userBalanceAtLastPaid[msg.sender] = userBalanceAtLastPaid[msg.sender].add(msg.value);
  }

  function withdraw(uint256 value) public onlyOwner {
     
    require(transferTaxes(msg.sender, false), "User has a negative balance");

     
    userBalanceAtLastPaid[msg.sender] = userBalanceAtLastPaid[msg.sender].sub(value);

     
    msg.sender.transfer(value);
  }

  function userHasPositveBalance(address user) public view returns (bool) {
    return userBalanceAtLastPaid[user] >= _taxesDue(user);
  }

  function userBalance(address user) public view returns (uint256) {
    return userBalanceAtLastPaid[user].sub(_taxesDue(user));
  }

   
  function transferTaxes(address user, bool isInAuction) public returns (bool) {

    if (isInAuction) {
      return true;
    }

    uint256 taxesDue = _taxesDue(user);

     
    if (userBalanceAtLastPaid[user] < taxesDue) {
        return false;
    }

     
    _payoutTaxes(taxesDue);
     
    lastPaidTaxes[user] = now;
     
    userBalanceAtLastPaid[user] = userBalanceAtLastPaid[user].sub(taxesDue);

    return true;
  }

  function payoutEF()
    public
  {
    uint256 uincornsRequirement = 2.014 ether;
    require(currentFoundationContribution >= uincornsRequirement);

    currentFoundationContribution = currentFoundationContribution.sub(uincornsRequirement);
    ethFoundation.transfer(uincornsRequirement);
  }

   

  function _payoutTaxes(uint256 _taxesDue)
    internal
  {
    uint256 foundationContribution = _taxesDue.mul(ethFoundationPercentage).div(100);
    uint256 taxCollectorContribution = _taxesDue.mul(taxCollectorPercentage).div(100);

    currentFoundationContribution += foundationContribution;

    taxCollector.transfer(taxCollectorContribution);
  }

   
   
  function _taxesDue(address user) internal view returns (uint256) {
     
    if (lastPaidTaxes[user] == 0) {
      return 0;
    }

    uint256 timeElapsed = now.sub(lastPaidTaxes[user]);
    return (valueHeld[user].mul(timeElapsed).div(365 days)).mul(taxPercentage).div(100);
  }

  function _addToValueHeld(address user, uint256 value) internal {
    require(transferTaxes(user, false), "User has a negative balance");
    require(userBalanceAtLastPaid[user] > 0);
    valueHeld[user] = valueHeld[user].add(value);
  }

  function _subFromValueHeld(address user, uint256 value, bool isInAuction) internal {
    require(transferTaxes(user, isInAuction), "User has a negative balance");
    valueHeld[user] = valueHeld[user].sub(value);
  }
}

 

 
contract RadicalPixels is HarbergerTaxable, ERC721Token {
  using SafeMath for uint256;

  uint256 public   xMax;
  uint256 public   yMax;
  uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 constant factor = 0x100000000000000000000000000000000;

  struct Pixel {
     
    bytes32 id;
     
    address seller;
     
    uint256 x;
     
    uint256 y;
     
    uint256 price;
     
    bytes32 auctionId;
     
    bytes32 contentData;
  }

  struct Auction {
     
    bytes32 auctionId;
     
    bytes32 blockId;
     
    uint256 x;
     
    uint256 y;
     
    uint256 currentPrice;
     
    address currentLeader;
     
    uint256 endTime;
  }

  mapping(uint256 => mapping(uint256 => Pixel)) public pixelByCoordinate;
  mapping(bytes32 => Auction) public auctionById;

   
   modifier validRange(uint256 _x, uint256 _y)
  {
    require(_x < xMax, "X coordinate is out of range");
    require(_y < yMax, "Y coordinate is out of range");
    _;
  }

  modifier auctionNotOngoing(uint256 _x, uint256 _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    require(pixel.auctionId == 0);
    _;
  }

   

  event BuyPixel(
    bytes32 indexed id,
    address indexed seller,
    address indexed buyer,
    uint256 x,
    uint256 y,
    uint256 price,
    bytes32 contentData
  );

  event SetPixelPrice(
    bytes32 indexed id,
    address indexed seller,
    uint256 x,
    uint256 y,
    uint256 price
  );

  event BeginDutchAuction(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    bytes32 indexed auctionId,
    address initiator,
    uint256 x,
    uint256 y,
    uint256 startTime,
    uint256 endTime
  );

  event UpdateAuctionBid(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    bytes32 indexed auctionId,
    address bidder,
    uint256 amountBet,
    uint256 timeBet
  );

  event EndDutchAuction(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    address indexed claimer,
    uint256 x,
    uint256 y
  );

  event UpdateContentData(
    bytes32 indexed pixelId,
    address indexed owner,
    uint256 x,
    uint256 y,
    bytes32 newContentData
  );

  constructor(uint256 _xMax, uint256 _yMax, uint256 _taxPercentage, address _taxCollector)
    public
    ERC721Token("Radical Pixels", "RPX")
    HarbergerTaxable(_taxPercentage, _taxCollector)
  {
    require(_xMax > 0, "xMax must be a valid number");
    require(_yMax > 0, "yMax must be a valid number");

    xMax = _xMax;
    yMax = _yMax;
  }

   

   
  function transferFrom(address _from, address _to, uint256 _tokenId, uint256 _price, uint256 _x, uint256 _y)
    public
    auctionNotOngoing(_x, _y)
  {
    _subFromValueHeld(msg.sender, _price, false);
    _addToValueHeld(_to, _price);
    require(_to == msg.sender);
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    super.transferFrom(_from, _to, _tokenId);
  }

    
   function buyUninitializedPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
     public
   {
     require(_price > 0);
     _buyUninitializedPixelBlock(_x, _y, _price, _contentData);
   }

   
  function buyUninitializedPixelBlocks(uint256[] _x, uint256[] _y, uint256[] _price, bytes32[] _contentData)
    public
  {
    require(_x.length == _y.length && _x.length == _price.length && _x.length == _contentData.length);
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      _buyUninitializedPixelBlock(_x[i], _y[i], _price[i], _contentData[i]);
    }
  }

   
  function buyPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
    public
    payable
  {
    require(_price > 0);
    uint256 _ = _buyPixelBlock(_x, _y, _price, msg.value, _contentData);
  }

   
  function buyPixelBlocks(uint256[] _x, uint256[] _y, uint256[] _price, bytes32[] _contentData)
    public
    payable
  {
    require(_x.length == _y.length && _x.length == _price.length && _x.length == _contentData.length);
    uint256 currentValue = msg.value;
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      currentValue = _buyPixelBlock(_x[i], _y[i], _price[i], currentValue, _contentData[i]);
    }
  }

   
  function setPixelBlockPrice(uint256 _x, uint256 _y, uint256 _price)
    public
    payable
  {
    require(_price > 0);
    _setPixelBlockPrice(_x, _y, _price);
  }

   
  function setPixelBlockPrices(uint256[] _x, uint256[] _y, uint256[] _price)
    public
    payable
  {
    require(_x.length == _y.length && _x.length == _price.length);
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      _setPixelBlockPrice(_x[i], _y[i], _price[i]);
    }
  }

   
  function beginDutchAuction(uint256 _x, uint256 _y)
    public
    auctionNotOngoing(_x, _y)
    validRange(_x, _y)
  {
    Pixel storage pixel = pixelByCoordinate[_x][_y];

    require(!userHasPositveBalance(pixel.seller));
    require(pixel.auctionId == 0);

     
    pixel.auctionId = _generateDutchAuction(_x, _y);
    uint256 tokenId = _encodeTokenId(_x, _y);

    _updatePixelMapping(pixel.seller, _x, _y, pixel.price, pixel.auctionId, "");

    emit BeginDutchAuction(
      pixel.id,
      tokenId,
      pixel.auctionId,
      msg.sender,
      _x,
      _y,
      block.timestamp,
      block.timestamp.add(1 days)
    );
  }

   
  function bidInAuction(uint256 _x, uint256 _y, uint256 _bid)
    public
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction storage auction = auctionById[pixel.auctionId];

    uint256 _tokenId = _encodeTokenId(_x, _y);
    require(pixel.auctionId != 0);
    require(auction.currentPrice < _bid);
    require(block.timestamp < auction.endTime);

    auction.currentPrice = _bid;
    auction.currentLeader = msg.sender;

    emit UpdateAuctionBid(
      pixel.id,
      _tokenId,
      auction.auctionId,
      msg.sender,
      _bid,
      block.timestamp
    );
  }

   
  function endDutchAuction(uint256 _x, uint256 _y)
    public
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction memory auction = auctionById[pixel.auctionId];

    require(pixel.auctionId != 0);
    require(auction.endTime < block.timestamp);

     
    address winner = _endDutchAuction(_x, _y);
    _updatePixelMapping(winner, _x, _y, auction.currentPrice, 0, "");

     
    _subFromValueHeld(pixel.seller, pixel.price, true);
    _addToValueHeld(winner, auction.currentPrice);

    uint256 tokenId = _encodeTokenId(_x, _y);
    removeTokenFrom(pixel.seller, tokenId);
    addTokenTo(winner, tokenId);
    emit Transfer(pixel.seller, winner, tokenId);

    emit EndDutchAuction(
      pixel.id,
      tokenId,
      winner,
      _x,
      _y
    );
  }

   
  function changeContentData(uint256 _x, uint256 _y, bytes32 _contentData)
    public
  {
    Pixel storage pixel = pixelByCoordinate[_x][_y];

    require(msg.sender == pixel.seller);

    pixel.contentData = _contentData;

    emit UpdateContentData(
      pixel.id,
      pixel.seller,
      _x,
      _y,
      _contentData
  );

  }

   
  function encodeTokenId(uint256 _x, uint256 _y)
    public
    view
    validRange(_x, _y)
    returns (uint256)
  {
    return _encodeTokenId(_x, _y);
  }

   

   
  function _buyUninitializedPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
    internal
    validRange(_x, _y)
    hasPositveBalance(msg.sender)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller == address(0), "Pixel must not be initialized");

    uint256 tokenId = _encodeTokenId(_x, _y);
    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price, 0, _contentData);

    _addToValueHeld(msg.sender, _price);
    _mint(msg.sender, tokenId);

    emit BuyPixel(
      pixelId,
      address(0),
      msg.sender,
      _x,
      _y,
      _price,
      _contentData
    );
  }

   
  function _buyPixelBlock(uint256 _x, uint256 _y, uint256 _price, uint256 _currentValue, bytes32 _contentData)
    internal
    validRange(_x, _y)
    hasPositveBalance(msg.sender)
    returns (uint256)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    require(pixel.auctionId == 0);   
    uint256 _taxOnPrice = _calculateTax(_price);

    require(pixel.seller != address(0), "Pixel must be initialized");
    require(userBalanceAtLastPaid[msg.sender] >= _taxOnPrice);
    require(pixel.price <= _currentValue, "Must have sent sufficient funds");

    uint256 tokenId = _encodeTokenId(_x, _y);

    removeTokenFrom(pixel.seller, tokenId);
    addTokenTo(msg.sender, tokenId);
    emit Transfer(pixel.seller, msg.sender, tokenId);

    _addToValueHeld(msg.sender, _price);
    _subFromValueHeld(pixel.seller, pixel.price, false);

    _updatePixelMapping(msg.sender, _x, _y, _price, 0, _contentData);
    pixel.seller.transfer(pixel.price);

    emit BuyPixel(
      pixel.id,
      pixel.seller,
      msg.sender,
      _x,
      _y,
      pixel.price,
      _contentData
    );

    return _currentValue.sub(pixel.price);
  }

   
  function _setPixelBlockPrice(uint256 _x, uint256 _y, uint256 _price)
    internal
    auctionNotOngoing(_x, _y)
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller == msg.sender, "Sender must own the block");
    _addToValueHeld(msg.sender, _price);

    delete pixelByCoordinate[_x][_y];

    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price, 0, "");

    emit SetPixelPrice(
      pixelId,
      pixel.seller,
      _x,
      _y,
      pixel.price
    );
  }

   
  function _generateDutchAuction(uint256 _x, uint256 _y)
    internal
    returns (bytes32)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    bytes32 _auctionId = keccak256(
      abi.encodePacked(
        block.timestamp,
        _x,
        _y
      )
    );

    auctionById[_auctionId] = Auction({
      auctionId: _auctionId,
      blockId: pixel.id,
      x: _x,
      y: _y,
      currentPrice: 0,
      currentLeader: msg.sender,
      endTime: block.timestamp.add(1 days)
    });

    return _auctionId;
  }

   
  function _endDutchAuction(uint256 _x, uint256 _y)
    internal
    returns (address)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction memory auction = auctionById[pixel.auctionId];

    address _winner = auction.currentLeader;

    delete auctionById[auction.auctionId];

    return _winner;
  }
   
  function _updatePixelMapping
  (
    address _seller,
    uint256 _x,
    uint256 _y,
    uint256 _price,
    bytes32 _auctionId,
    bytes32 _contentData
  )
    internal
    returns (bytes32)
  {
    bytes32 pixelId = keccak256(
      abi.encodePacked(
        _x,
        _y
      )
    );

    pixelByCoordinate[_x][_y] = Pixel({
      id: pixelId,
      seller: _seller,
      x: _x,
      y: _y,
      price: _price,
      auctionId: _auctionId,
      contentData: _contentData
    });

    return pixelId;
  }

  function _calculateTax(uint256 _price)
    internal
    view
    returns (uint256)
  {
    return _price.mul(taxPercentage).div(100);
  }
   
  function _encodeTokenId(uint256 _x, uint256 _y)
    internal
    pure
    returns (uint256 result)
  {
    return ((_x * factor) & clearLow) | (_y & clearHigh);
  }
}