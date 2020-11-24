 

pragma solidity 0.4.24;

 
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

 
contract ERC721Basic {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 _tokenId
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
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

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

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
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

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
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
      emit Approval(_owner, address(0), _tokenId);
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
      _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 
contract ERC721Token is ERC721, ERC721BasicToken {
   
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
  }

   
  function name() public view returns (string) {
    return name_;
  }

   
  function symbol() public view returns (string) {
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

 

contract WorldCupPlayerToken is ERC721Token("WWWorld Cup", "WWWC"), Ownable {

  string constant public PLAYER_METADATA = "ipfs://ipfs/QmNgMeQT62pnUkkFcz4y59cQTmTZHBVFKmQ7Y7HQjh7tRw";
  uint256 constant DISTINCT_LEGENDARY_LIMIT = 1;
  uint256 constant DISTINCT_RARE_LIMIT = 2;
  uint256 constant DISTINCT_COMMON_LIMIT = 3;
  uint256 constant LEGENDARY_MAX_ID = 32;
  uint256 constant RARE_MAX_ID = 96;
  uint256 constant COMMON_MAX_ID = 736;
  mapping (uint256 => uint256) public playerCount;
  mapping (uint256 => uint256) internal tokenPlayerIds;

   
  modifier enforcePlayerScarcity(uint256 playerId, uint256 limit) {
    require(playerCount[playerId] < limit, "Player limit reached.");
    _;
  }

   
  modifier validatePlayerIdRange(uint256 playerId, uint256 min, uint256 max) {
    require(playerId > min, "Player ID must be greater than the rarity minimum.");
    require(playerId <= max, "Player ID must be less than or equal to rarity maximum.");
    _;
  }

   
  function _mintToken(uint256 playerId, string tokenURI, address owner) internal {
    
     
    uint256 tokenId = allTokens.length + 1;
    super._mint(owner, tokenId);

     
    _setTokenURI(tokenId, tokenURI);
    _setPlayerId(tokenId, playerId);
  }

   
  function _setPlayerId(uint256 tokenId, uint256 playerId) internal {
    require(exists(tokenId), "Token does not exist.");
    tokenPlayerIds[tokenId] = playerId;
  }

   
  function playerId(uint256 tokenId) public view returns (uint256) {
    require(exists(tokenId), "Token does not exist.");
    return tokenPlayerIds[tokenId];
  }

}

 

contract AuctionableWorldCupPlayerToken is WorldCupPlayerToken {

  Auction[] public auctions;
  struct Auction {
    address highestBidder;
    uint256 highestBidAmount;
    uint256 endsAtBlock;
    uint256 playerId;
    bool finalized;
    string tokenURI;
  }
  uint256 constant MIN_BID_INCREMENT = 0.01 ether;
  uint256 constant AUCTION_BLOCK_LENGTH = 257;
  uint256 public totalUnclaimedBidsAmount = 0;
  mapping (uint256 => mapping(address => uint256)) public unclaimedBidsByAuctionIndexByBidder;

  event AuctionCreated(uint256 playerId);
  event AuctionFinalized(uint256 auctionIndex, address highestBidder);
  event BidIncremented(uint256 auctionIndex, address bidder);
  event BidReturned(uint256 auctionIndex, address bidder);

   
  function totalAuctionsCount() public view returns (uint256) {
    return auctions.length;
  }

   
  function _startAuction(uint256 auctionIndex) internal {
    auctions[auctionIndex].endsAtBlock = block.number + AUCTION_BLOCK_LENGTH;
  }

   
  function _createAuction(uint256 playerId, string tokenURI) internal {
    playerCount[playerId] += 1;
    Auction memory auction = Auction(address(0), 0, 0, playerId, false, tokenURI);
    auctions.push(auction);
    emit AuctionCreated(playerId);
  }

   
  function createLegendaryAuction(uint256 playerId, string tokenURI)
    public
    onlyOwner
    enforcePlayerScarcity(playerId, DISTINCT_LEGENDARY_LIMIT)
    validatePlayerIdRange(playerId, 0, LEGENDARY_MAX_ID)
  {
    _createAuction(playerId, tokenURI);
  }

   
  function createRareAuction(uint256 playerId, string tokenURI)
    public
    onlyOwner
    enforcePlayerScarcity(playerId, DISTINCT_RARE_LIMIT)
    validatePlayerIdRange(playerId, LEGENDARY_MAX_ID, RARE_MAX_ID)
  {
    _createAuction(playerId, tokenURI);
  }

   
  function createCommonAuction(uint256 playerId, string tokenURI)
    public
    onlyOwner
    enforcePlayerScarcity(playerId, DISTINCT_COMMON_LIMIT)
    validatePlayerIdRange(playerId, RARE_MAX_ID, COMMON_MAX_ID)
  {
    _createAuction(playerId, tokenURI);
  }

   
  function incrementBid(uint256 auctionIndex) public payable {

     
    require(auctionIndex + 1 <= auctions.length, "Auction does not exist.");

     
    uint256 auctionEndsAtBlock = auctions[auctionIndex].endsAtBlock;
    require(auctionEndsAtBlock == 0 || block.number < auctionEndsAtBlock, "Auction has ended.");

     
    uint256 newTotalBid = unclaimedBidsByAuctionIndexByBidder[auctionIndex][msg.sender] + msg.value;

     
    require(newTotalBid >= auctions[auctionIndex].highestBidAmount + MIN_BID_INCREMENT, "Must increment bid by MIN_BID_INCREMENT.");

     
    if (auctions[auctionIndex].endsAtBlock == 0) {
      _startAuction(auctionIndex);
    }

     
    auctions[auctionIndex].highestBidder = msg.sender;

     
    auctions[auctionIndex].highestBidAmount = newTotalBid;

     
    unclaimedBidsByAuctionIndexByBidder[auctionIndex][msg.sender] += msg.value;

     
    totalUnclaimedBidsAmount += msg.value;

    emit BidIncremented(auctionIndex, msg.sender);
  }

   
  function finalizeAuction(uint256 auctionIndex) public {

     
    require(auctionIndex + 1 <= auctions.length, "Auction does not exist.");

     
    require(auctions[auctionIndex].finalized == false, "Auction has already been finalized.");

     
    require(block.number > auctions[auctionIndex].endsAtBlock, "Auction has not ended yet.");

     
    auctions[auctionIndex].finalized = true;

    Auction memory auction = auctions[auctionIndex];

     
    totalUnclaimedBidsAmount = totalUnclaimedBidsAmount - auction.highestBidAmount;

     
    unclaimedBidsByAuctionIndexByBidder[auctionIndex][auction.highestBidder] = 0;

     
    _mintToken(auction.playerId, auction.tokenURI, auction.highestBidder);

    emit AuctionFinalized(auctionIndex, auction.highestBidder);
  }

   
  function withdraw() public onlyOwner {
    uint256 amount = address(this).balance - totalUnclaimedBidsAmount;
    owner.transfer(amount);
  }

   
  function returnBids(uint256 auctionIndex, address bidder) public {

     
    require(auctionIndex + 1 <= auctions.length, "Auction does not exist.");

     
    require(block.number > auctions[auctionIndex].endsAtBlock, "Auction has not ended yet.");

     
    require(bidder != auctions[auctionIndex].highestBidder, "Bidder who won auction cannot return bids.");

     
    uint256 refund = unclaimedBidsByAuctionIndexByBidder[auctionIndex][bidder];

     
    unclaimedBidsByAuctionIndexByBidder[auctionIndex][bidder] = 0;

     
    bidder.transfer(refund);

    emit BidReturned(auctionIndex, bidder);
  }

}