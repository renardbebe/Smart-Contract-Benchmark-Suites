 

pragma solidity ^0.4.24;

 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    if(a==0){
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

  function sub(uint256 a, uint256 b) internal pure returns (uint256){
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
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
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

 

contract ERC721Basic is ERC165 {
  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;

   
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId );
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId );
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved );
  
   
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns (address owner);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transfer(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;

  function implementsERC721() public pure returns(bool);
}

 

contract ERC721TokenReceiver {
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;
  bytes4 retval;
  bool reverts;

  constructor(bytes4 _retval, bool _reverts) public {
    retval = _retval;
    reverts = _reverts;
  }

  event Received(address _operator, address _from, uint256 _tokenId, bytes _data, uint256 _gas );

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data ) public returns(bytes4) {
    require(!reverts);
    emit Received(
      _operator,
      _from,
      _tokenId,
      _data,
      gasleft()
    );
    return retval;
  }
}

 

contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  mapping(bytes4 => bool) internal supportedInterfaces;
  
  constructor() public {
    _registerInterface(InterfaceId_ERC165);
  }

  function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
    return supportedInterfaces[_interfaceId];
  }

  function _registerInterface(bytes4 _interfaceId) internal {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 

contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic{
  using SafeMath for uint256;
  using AddressUtils for address;
  
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
  mapping (uint256 => address) internal tokenIDToOwner;
  mapping (uint256 => address) internal tokenIDToApproved;
  mapping (address => uint256) internal ownershipTokenCount;
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor() public {
    _registerInterface(InterfaceId_ERC721);
  }
  function implementsERC721() public pure returns(bool){
      return true;
  }
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownershipTokenCount[_owner];
  }
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenIDToOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }
  
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenIDToApproved[_tokenId];
  }
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }
  function isApprovedForAll(address _owner, address _operator ) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }
  function _exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenIDToOwner[_tokenId];
    return owner != address(0);
  }
  function isApprovedOrOwner(address _spender, uint256 _tokenId ) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return (
      _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender)
    );
  }
  function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data ) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}

 

contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

 

contract ChainDrawingsAccess{
  event ContractUpgrade(address newContract);

  address public owner;

  bool public paused = false;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function setNewOwner(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
  }

  function withdrawBalance() external onlyOwner {
    owner.transfer(address(this).balance);
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }
 
  function pause() public onlyOwner whenNotPaused {
    paused = true;
  }

  function unpause() public onlyOwner whenPaused {
    paused = false;
  }
}

 

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if(newOwner != address(0)){
      owner = newOwner;
    }
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

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public returns (bool){
    paused = true;
    emit Pause();
    return true;   
  }

  function unpause() onlyOwner whenPaused public returns (bool){
    paused = false;
    emit Unpause();
    return true;   
  } 
}

 

contract SaleClockAuction is Pausable {
  bool public isSaleClockAuction = true;

  struct Auction {
    address seller;
    uint128 startingPrice;   
    uint128 endingPrice;     
    uint64 duration;  
    uint64 startedAt;  
  }

  ERC721Basic public nonFungibleContract;     

  uint256 public commission;     
  mapping (uint256 => Auction) tokenIdToAuction;    
  mapping (address => uint256[]) public ownershipAuctionTokenIDs;    

  event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
  event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
  event AuctionCancelled(uint256 tokenId);

  bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;

  constructor(address _nftAddress, uint256 _commission) public {
    require(_commission <= 10000);
    commission = _commission;
   
    ERC721Basic candidateContract = ERC721Basic(_nftAddress);
    require(candidateContract.implementsERC721());
    require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
    nonFungibleContract = candidateContract;
  }

  function () external {}	 

   
  modifier canBeStoredWith64Bits(uint256 _value){
    require(_value <= 18446744073709551615);
    _;
  }

  modifier canBeStoredWith128Bits(uint256 _value){
    require(_value < 340282366920938463463374607431768211455);
    _;
  }

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool){
    return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
  }

  function _escrow(address _owner, uint256 _tokenId) internal {
    nonFungibleContract.transferFrom(_owner, this, _tokenId);
     
    ownershipAuctionTokenIDs[_owner].push(_tokenId);
  }

   
  function _addAuction(uint256 _tokenId, Auction _auction) internal {
    require(_auction.duration >= 1 minutes);

    tokenIdToAuction[_tokenId] = _auction;

    emit AuctionCreated(
      uint256(_tokenId),
      uint256(_auction.startingPrice),
      uint256(_auction.endingPrice),
      uint256(_auction.duration)
    );
  }

   
  function _cancelAuction(uint256 _tokenId, address _seller) internal {
    _removeAuction(_tokenId);
    nonFungibleContract.transfer(_seller, _tokenId);
     
    removeFromOwnershipAuctionTokenIDs(_seller, _tokenId);
    
    emit AuctionCancelled(_tokenId);
  }

   
  function removeFromOwnershipAuctionTokenIDs(address seller, uint256 tokenId) internal {
    uint len = ownershipAuctionTokenIDs[seller].length;
    if(len > 0){
      bool hasFound = false;
      for(uint i=0; i<len-1; i++){
        if(!hasFound && ownershipAuctionTokenIDs[seller][i] == tokenId){
          hasFound = true;
          ownershipAuctionTokenIDs[seller][i] = ownershipAuctionTokenIDs[seller][i+1];
        }else if(hasFound){
          ownershipAuctionTokenIDs[seller][i] = ownershipAuctionTokenIDs[seller][i+1];
        }
      }

      if(!hasFound && ownershipAuctionTokenIDs[seller][len - 1] == tokenId){   
        hasFound = true;
      }
      
      if(hasFound){
        delete ownershipAuctionTokenIDs[seller][len-1];
        ownershipAuctionTokenIDs[seller].length--;  
      }
    }
  }

  function _bid(uint256 _tokenId, uint256 _bidAmount) internal returns(uint256){
    Auction storage auction = tokenIdToAuction[_tokenId];

    require(_isOnAuction(auction));

    uint256 price = _currentPrice(auction);
    require(_bidAmount >= price);

    address seller = auction.seller;
    _removeAuction(_tokenId);

     
    removeFromOwnershipAuctionTokenIDs(seller, _tokenId);
    
     
    if(price > 0) {
      uint256 auctioneerCommission = _computeCommission(price);
      uint256 sellerProceeds = price - auctioneerCommission;

      seller.transfer(sellerProceeds);
    }

     
    uint256 bidExcess = _bidAmount - price;
    msg.sender.transfer(bidExcess);

    emit AuctionSuccessful(_tokenId, price, msg.sender);

    return price;
  } 

  function _removeAuction(uint256 _tokenId) internal {
    delete tokenIdToAuction[_tokenId];
  }

  function _isOnAuction(Auction storage _auction) internal view returns (bool){
    return (_auction.startedAt > 0);
  }

  function _currentPrice(Auction storage _auction) internal view returns (uint256) {
    uint256 secondsPassed = 0;
    
    if(now > _auction.startedAt){
      secondsPassed = now - _auction.startedAt;
    }

    return _computeCurrentPrice(
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      secondsPassed
    );
  }

   
  function _computeCurrentPrice(
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    uint256 _secondsPassed
  ) internal pure returns (uint256){
    
    if(_secondsPassed >= _duration){	 
      return _endingPrice;  
    } else {
      int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
      int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

      int256 currentPrice = int256(_startingPrice) + currentPriceChange;

      return uint256(currentPrice); 
    }
  }

   
  function _computeCommission(uint256 _price) internal view returns (uint256) { 
    return _price * commission / 10000;
  }

   
  function withdrawBalance() external {
    address nftAddress = address(nonFungibleContract);  
    require(msg.sender == owner || msg.sender == nftAddress);

    nftAddress.transfer(address(this).balance);
  }

   
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  ) public
    canBeStoredWith128Bits(_startingPrice)
    canBeStoredWith128Bits(_endingPrice)
    canBeStoredWith64Bits(_duration)
  {
    require(msg.sender == address(nonFungibleContract));
    require(_owns(_seller, _tokenId));
    _escrow(_seller, _tokenId);
    Auction memory auction = Auction(
      _seller,
      uint128(_startingPrice),
      uint128(_endingPrice),
      uint64(_duration),
      uint64(now)
    );
    _addAuction(_tokenId, auction);
  }

  function bid(uint256 _tokenId) public payable whenNotPaused {
    _bid(_tokenId, msg.value);
    nonFungibleContract.transfer(msg.sender, _tokenId);
  }

  function cancelAuction(uint256 _tokenId) public {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));
    address seller = auction.seller;
    require(msg.sender == seller);

    _cancelAuction(_tokenId, seller);
  }

  function cancelAuctionWhenPaused(uint256 _tokenId) public onlyOwner whenPaused {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));
    _cancelAuction(_tokenId, auction.seller);
  }

  function getAuction(uint256 _tokenId) public view returns(
    address seller,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 duration,
    uint256 startedAt
  ){
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));
    return(
      auction.seller,
      auction.startingPrice,
      auction.endingPrice,
      auction.duration,
      auction.startedAt
    );
  }

  function getCurrentPrice(uint256 _tokenId) public view returns (uint256){
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction));
    return _currentPrice(auction);
  }

  function getFund() public view returns (uint256 balance){
    return address(this).balance;
  }

   
  function getAuctionTokenIDsOfOwner(address owner) public view returns(uint256[]){
    return ownershipAuctionTokenIDs[owner];
  }
}

 

contract ChainDrawingsBase is ChainDrawingsAccess, SupportsInterfaceWithLookup, ERC721BasicToken, ERC721Enumerable, ERC721Metadata {
  using SafeMath for uint256;
  using AddressUtils for address;

  string internal name_ = "LianPaoTu";
  string internal symbol_ = "LPT";
  
   
  event Create(address owner, uint256 drawingsID, bytes32 chainID);

   
  struct ChainDrawings {
    bytes32 chainID;		 
    bytes32 author;	 
    uint64 createTime;	 
  }

   
  ChainDrawings[] drawings;

  mapping (bytes32 => uint256) public chainIDToTokenID;    
  mapping (uint256 => string) internal tokenIDToUri;  


   
  mapping(address => uint256[]) internal ownedTokens;   
  mapping(uint256 => uint256) internal ownedTokensIndex;  
  uint256[] internal allTokens;  
  mapping(uint256 => uint256) internal allTokensIndex;   


  SaleClockAuction public saleAuction;
  
  constructor() public {
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }
  
   
  modifier validNFToken(uint256 _tokenId) {
    require(tokenIDToOwner[_tokenId] != address(0));
    _;
  }
  
  function name() external view returns (string) {
    return name_;
  }
  function symbol() external view returns (string) {
    return symbol_;
  }
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(_exists(_tokenId));
    return tokenIDToUri[_tokenId];
  }
  function tokenOfOwnerByIndex(address _owner, uint256 _index ) public view returns (uint256) {
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
  
   
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    if(_from != address(0)){
      ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);   
      delete tokenIDToApproved[_tokenId];
      removeFromOwnedTokens(_from, _tokenId);
    }

    ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);   
    tokenIDToOwner[_tokenId] = _to;

    uint256 length = ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length.sub(1);

    emit Transfer(_from, _to, _tokenId);
  }
  
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool){
    return tokenIDToOwner[_tokenId] == _claimant;
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenIDToApproved[_tokenId] == _claimant;
  }

  function _approve(uint256 _tokenId, address _approved) internal {
    tokenIDToApproved[_tokenId] = _approved;
    emit Approval(msg.sender, _approved, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public whenNotPaused {
    require(_owns(msg.sender, _tokenId));
    _approve(_tokenId, _to);
  }

   
  function transfer(address _to, uint256 _tokenId) public whenNotPaused{
    require(_to != address(0));
    require(_to != address(this));
    require(_to != address(saleAuction));
    require(_owns(msg.sender, _tokenId));

    _transfer(msg.sender, _to, _tokenId);
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused{
    require(_to != address(0));
    require(_to != address(this));
    require(_approvedFor(msg.sender, _tokenId));
    require(_owns(_from, _tokenId));
    _transfer(_from, _to, _tokenId);
  }
  
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }
  
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public whenNotPaused {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }
  
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) internal validNFToken(_tokenId) {
    transferFrom(_from, _to, _tokenId);
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }
 
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens){
    if(balanceOf(_owner) == 0){
      return new uint256[](0);
    }else{
      return ownedTokens[_owner];
    }
  }

   
  function _createDrawings(bytes32 _chainID, bytes32 _author, address _owner, string metaUrl) internal returns(uint) {
    ChainDrawings memory _drawings = ChainDrawings({
      chainID: _chainID,
      author: _author,
      createTime: uint64(now)
    });

    uint256 _tokenId = drawings.push(_drawings);
    _tokenId = _tokenId.sub(1);
    chainIDToTokenID[_chainID] = _tokenId;
    require(_tokenId == uint256(uint32(_tokenId)));

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
    tokenIDToUri[_tokenId] = metaUrl;

     
    emit Create(_owner, _tokenId, _chainID);
    _transfer(address(0), _owner, _tokenId);

    return _tokenId;
  }

   
  function removeFromOwnedTokens(address _owner, uint256 _tokenId) internal {
    require(tokenIDToOwner[_tokenId] == _owner);
    uint len = ownedTokens[_owner].length;
    assert(len > 0);

    if(len == 1){
      delete ownedTokens[_owner];
      delete ownedTokensIndex[_tokenId];
      return;
    }

    uint256 tokenToRemoveIndex = ownedTokensIndex[_tokenId];

    if(tokenToRemoveIndex == len.sub(1)){
      ownedTokens[_owner].length = ownedTokens[_owner].length.sub(1);
      delete ownedTokensIndex[_tokenId];
      return;
    }

    uint256 lastToken = ownedTokens[_owner][len.sub(1)];

    ownedTokens[_owner][tokenToRemoveIndex] = lastToken;
    ownedTokensIndex[lastToken] = tokenToRemoveIndex;
    ownedTokens[_owner].length = ownedTokens[_owner].length.sub(1);
    delete ownedTokensIndex[_tokenId];
  }
}

 

contract ChainDrawingsAuction is ChainDrawingsBase {

  function setSaleAuctionAddress(address _address) public onlyOwner {
    SaleClockAuction candidateContract = SaleClockAuction(_address);
    require(candidateContract.isSaleClockAuction());

    saleAuction = candidateContract;
  }

  function createSaleAuction(
    uint256 _tokenID,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  ) public whenNotPaused {

    require(_owns(msg.sender, _tokenID));
    approve(saleAuction, _tokenID);
    saleAuction.createAuction(_tokenID, _startingPrice, _endingPrice, _duration, msg.sender);
  }

  function withdrawAuctionBalances() external onlyOwner {
    saleAuction.withdrawBalance();
  }
}

 

contract ChainDrawingsGeneration is ChainDrawingsAuction {
   
  function createAuthorDrawings(bytes32 _chainID, 
                                bytes32 _author, 
                                address _owner, 
                                string _metaUrl) public onlyOwner {
     
    uint256 tokenID = chainIDToTokenID[_chainID];
    if(tokenID != 0){   
      ChainDrawings storage drawing = drawings[tokenID];
      drawing.author = _author;

      return;
    }

    if(_owner == address(0)){
      _owner = owner;
    }
    _createDrawings(_chainID, _author, _owner, _metaUrl);
  }

   
  function createInternalAuction(bytes32 _chainID, 
                                bytes32 _author, 
                                uint256 _startingPrice,
                                uint256 _endingPrice,
                                uint256 _duration, 
                                string _metaUrl) public onlyOwner {
     
    uint256 tokenID  = chainIDToTokenID[_chainID];
    if(tokenID != 0){   
      ChainDrawings storage drawing = drawings[tokenID];
      drawing.author = _author;

      return;
    }

    uint256 newTokenID = _createDrawings(_chainID, _author, address(this), _metaUrl);
    _approve(newTokenID, saleAuction);

    saleAuction.createAuction(
      newTokenID,
      _startingPrice,
      _endingPrice,
      _duration,
      address(this)
    );
  }
}

 

 
contract BatchCreateDrawingsInterface {
  function isBatchCreateDrawings() public pure returns (bool);

   
  function getInternalDrawings(uint index) public returns (bytes32 _chainID, 
                                uint256 _startingPrice,
                                uint256 _endingPrice,
                                uint256 _duration, 
                                string memory _metaUrl);

   
  function getAuthorDrawings(uint index) public returns (bytes32 _chainID, 
                                bytes32 _author, 
                                address _owner, 
                                string memory _metaUrl);
}

 

contract ChainDrawingsCore is ChainDrawingsGeneration {
  address public newContractAddress;
  BatchCreateDrawingsInterface public batchCreateDrawings;
  
  constructor() public {
    paused = true;
    owner = msg.sender;
    _createDrawings("-1",  "-1", address(0), "https://chain.chuangyipaobu.com");  
  }
  
   
  function setBatchCreateDrawingsAddress(address _address) external onlyOwner {
    BatchCreateDrawingsInterface candidateContract = BatchCreateDrawingsInterface(_address);
    require(candidateContract.isBatchCreateDrawings());

     
    batchCreateDrawings = candidateContract;
  }

   
  function batchCreateInternalDrawings() internal onlyOwner {
    require(batchCreateDrawings != address(0));

    bytes32 chainID;
    uint256 startingPrice;
    uint256 endingPrice;
    uint256 duration;
    string memory metaUrl;
    uint index = 0;

    while(index < 20){	 
      (chainID, startingPrice, endingPrice, duration, metaUrl) = batchCreateDrawings.getInternalDrawings(index++);
      if(chainID == "0"){
        return;
      }

      if(chainIDToTokenID[chainID] > 0){
        continue;
      }
    
      createInternalAuction(chainID, "跑地图", startingPrice, endingPrice, duration, metaUrl);
    }
  }

   
  function batchCreateAuthorDrawings() internal onlyOwner {
    require(batchCreateDrawings != address(0));

    bytes32 chainID;
    bytes32 author;
    address owner; 
    string memory metaUrl;
    uint index = 0;

    while(index < 20){	 
      (chainID, author, owner, metaUrl) = batchCreateDrawings.getAuthorDrawings(index++);
      if(chainID == "0"){
        return;
      }
      if(chainIDToTokenID[chainID] > 0){
        continue;
      }  

      createAuthorDrawings(chainID, author, owner, metaUrl);
    }
  }

   
  function batchCreateDrawings() external onlyOwner {
    batchCreateInternalDrawings();
    batchCreateAuthorDrawings();
  }

   
  function setNewAddress(address _newAddress) external onlyOwner whenPaused {
    newContractAddress = _newAddress;
    emit ContractUpgrade(_newAddress);
  }

  function() external payable {
    require(msg.sender == address(saleAuction));
  }

  function getChainDrawings(uint256 _id) public view returns(
      uint256 tokenID,
      bytes32 chainID,   
      bytes32 author,    
      uint256 createTime
  ) {
    ChainDrawings storage drawing = drawings[_id];

    tokenID = _id;
    chainID = drawing.chainID;
    author = drawing.author;
    createTime = drawing.createTime;
  }

   
  function getCoreAddress() external view returns(address){
    return address(this);
  }

   
  function getSaleAuctionAddress() external view returns(address){
    return address(saleAuction);
  }

   
  function getBatchCreateDrawingsAddress() external view returns(address){
    return address(batchCreateDrawings);
  }

  function unpause() public onlyOwner whenPaused {
    require(saleAuction != address(0));
    require(newContractAddress == address(0));

    super.unpause();
  }

   
  function getChainDrawingsByChainID(bytes32 _chainID) external view returns(
      uint256 tokenID,
      bytes32 chainID,         
      bytes32 author,    
      uint256 createTime          
  ){
    tokenID = chainIDToTokenID[_chainID];
    return getChainDrawings(tokenID);
  }

  function getFund() external view returns (uint256 balance){
    return address(this).balance;
  }

   
  function getAllTokensOfUser(address _owner) public view returns (uint256[]){
    uint256[] memory ownerTokensNonAuction = this.tokensOfOwner(_owner);
    uint256[] memory ownerTokensAuction = saleAuction.getAuctionTokenIDsOfOwner(_owner);
    
    uint length1 = ownerTokensNonAuction.length;
    uint length2 = ownerTokensAuction.length;
    uint length = length1 + length2;

    if(length == 0) return;

    uint256[] memory result = new uint[](length);
    uint index = 0;

    for (uint i=0; i<length2; i++) {
      result[index++] = ownerTokensAuction[i];
    }
    for (uint j=0; j<length1; j++) {
      result[index++] = ownerTokensNonAuction[j];
    }
    
    return result;
  }
  
   
  function getAllChainIDsOfUser(address _owner) external view returns (bytes32[]){
    uint256[] memory ownerTokens = this.getAllTokensOfUser(_owner);
    uint len = ownerTokens.length;
 
    if(len == 0) return;

    bytes32[] memory ownerChainIDs = new bytes32[](len);
    for (uint i=0; i<len; i++) {
      ChainDrawings storage drawing = drawings[ownerTokens[i]];
      ownerChainIDs[i] = drawing.chainID;
    }
    return ownerChainIDs;
  }

   
  function getTokensCountOfUser(address _owner) external view returns (uint256){
    uint256[] memory ownerTokensNonAuction = this.tokensOfOwner(_owner);
    uint256[] memory ownerTokensAuction = saleAuction.getAuctionTokenIDsOfOwner(_owner);
    
    uint length1 = ownerTokensNonAuction.length;
    uint length2 = ownerTokensAuction.length;
    return length1 + length2;
  }
}