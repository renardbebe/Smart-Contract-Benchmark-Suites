 

pragma solidity ^0.4.19;

 

 
 
 
interface IERC721Base   {
   
   
   
   
   
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

   
   
   
   
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

   
   
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

   
   
   
   
   
  function balanceOf(address _owner) external view returns (uint256);

   
   
   
   
   
  function ownerOf(uint256 _tokenId) external view returns (address);

   
   
   
   
   
   
   
   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable;

   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

   
   
   
   
   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

   
   
   
   
   
   
  function approve(address _approved, uint256 _tokenId) external payable;

   
   
   
   
   
  function setApprovalForAll(address _operator, bool _approved) external;

   
   
   
   
  function getApproved(uint256 _tokenId) external view returns (address);

   
   
   
   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

 
contract HasNoEther is Ownable {

   
  function HasNoEther() payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 

 
contract AxieClockAuction is HasNoEther, Pausable {

   
  struct Auction {
     
    address seller;
     
    uint128 startingPrice;
     
    uint128 endingPrice;
     
    uint64 duration;
     
     
    uint64 startedAt;
  }

   
   
  uint256 public ownerCut;

   
  mapping (address => mapping (uint256 => Auction)) public auctions;

  event AuctionCreated(
    address indexed _nftAddress,
    uint256 indexed _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  );

  event AuctionSuccessful(
    address indexed _nftAddress,
    uint256 indexed _tokenId,
    uint256 _totalPrice,
    address _winner
  );

  event AuctionCancelled(
    address indexed _nftAddress,
    uint256 indexed _tokenId
  );

   
   
   
   
  function AxieClockAuction(uint256 _ownerCut) public {
    require(_ownerCut <= 10000);
    ownerCut = _ownerCut;
  }

   
  function () external {}

   
   
  modifier canBeStoredWith64Bits(uint256 _value) {
    require(_value <= 18446744073709551615);
    _;
  }

  modifier canBeStoredWith128Bits(uint256 _value) {
    require(_value < 340282366920938463463374607431768211455);
    _;
  }

   
   
   
  function getAuction(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    view
    returns (
      address seller,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt
    )
  {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    return (
      _auction.seller,
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      _auction.startedAt
    );
  }

   
   
   
  function getCurrentPrice(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    view
    returns (uint256)
  {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    return _getCurrentPrice(_auction);
  }

   
   
   
   
   
   
   
   
  function createAuction(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    external
    whenNotPaused
    canBeStoredWith128Bits(_startingPrice)
    canBeStoredWith128Bits(_endingPrice)
    canBeStoredWith64Bits(_duration)
  {
    address _seller = msg.sender;
    require(_owns(_nftAddress, _seller, _tokenId));
    _escrow(_nftAddress, _seller, _tokenId);
    Auction memory _auction = Auction(
      _seller,
      uint128(_startingPrice),
      uint128(_endingPrice),
      uint64(_duration),
      uint64(now)
    );
    _addAuction(_nftAddress, _tokenId, _auction, _seller);
  }

   
   
   
   
   
  function bid(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    payable
    whenNotPaused
  {
     
    _bid(_nftAddress, _tokenId, msg.value);
    _transfer(_nftAddress, msg.sender, _tokenId);
  }

   
   
   
   
   
   
  function cancelAuction(address _nftAddress, uint256 _tokenId) external {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    require(msg.sender == _auction.seller);
    _cancelAuction(_nftAddress, _tokenId, _auction.seller);
  }

   
   
   
   
   
  function cancelAuctionWhenPaused(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    whenPaused
    onlyOwner
  {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    _cancelAuction(_nftAddress, _tokenId, _auction.seller);
  }

   
   
  function _isOnAuction(Auction storage _auction) internal view returns (bool) {
    return (_auction.startedAt > 0);
  }

   
   
  function _getNftContract(address _nftAddress) internal pure returns (IERC721Base) {
    IERC721Base candidateContract = IERC721Base(_nftAddress);
     
    return candidateContract;
  }

   
   
   
   
  function _getCurrentPrice(
    Auction storage _auction
  )
    internal
    view
    returns (uint256)
  {
    uint256 _secondsPassed = 0;

     
     
     
    if (now > _auction.startedAt) {
      _secondsPassed = now - _auction.startedAt;
    }

    return _computeCurrentPrice(
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      _secondsPassed
    );
  }

   
   
   
   
  function _computeCurrentPrice(
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    uint256 _secondsPassed
  )
    internal
    pure
    returns (uint256)
  {
     
     
     
     
     
    if (_secondsPassed >= _duration) {
       
       
      return _endingPrice;
    } else {
       
       
      int256 _totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

       
       
       
      int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_duration);

       
       
      int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;

      return uint256(_currentPrice);
    }
  }

   
   
   
   
  function _owns(address _nftAddress, address _claimant, uint256 _tokenId) private view returns (bool) {
    IERC721Base _nftContract = _getNftContract(_nftAddress);
    return (_nftContract.ownerOf(_tokenId) == _claimant);
  }

   
   
   
   
  function _addAuction(
    address _nftAddress,
    uint256 _tokenId,
    Auction _auction,
    address _seller
  ) internal {
     
     
    require(_auction.duration >= 1 minutes);

    auctions[_nftAddress][_tokenId] = _auction;

    AuctionCreated(
      _nftAddress,
      _tokenId,
      uint256(_auction.startingPrice),
      uint256(_auction.endingPrice),
      uint256(_auction.duration),
      _seller
    );
  }

   
   
  function _removeAuction(address _nftAddress, uint256 _tokenId) internal {
    delete auctions[_nftAddress][_tokenId];
  }

   
  function _cancelAuction(address _nftAddress, uint256 _tokenId, address _seller) internal {
    _removeAuction(_nftAddress, _tokenId);
    _transfer(_nftAddress, _seller, _tokenId);
    AuctionCancelled(_nftAddress, _tokenId);
  }

   
   
   
   
   
  function _escrow(address _nftAddress, address _owner, uint256 _tokenId) private {
    IERC721Base _nftContract = _getNftContract(_nftAddress);

     
    _nftContract.transferFrom(_owner, this, _tokenId);
  }

   
   
   
   
   
  function _transfer(address _nftAddress, address _receiver, uint256 _tokenId) internal {
    IERC721Base _nftContract = _getNftContract(_nftAddress);

     
    _nftContract.transferFrom(this, _receiver, _tokenId);
  }

   
   
  function _computeCut(uint256 _price) internal view returns (uint256) {
     
     
     
     
     
    return _price * ownerCut / 10000;
  }

   
   
  function _bid(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _bidAmount
  )
    internal
    returns (uint256)
  {
     
    Auction storage _auction = auctions[_nftAddress][_tokenId];

     
     
     
     
    require(_isOnAuction(_auction));

     
     
    uint256 _price = _getCurrentPrice(_auction);
    require(_bidAmount >= _price);

     
     
    address _seller = _auction.seller;

     
     
    _removeAuction(_nftAddress, _tokenId);

     
    if (_price > 0) {
       
       
       
      uint256 _auctioneerCut = _computeCut(_price);
      uint256 _sellerProceeds = _price - _auctioneerCut;

       
       
       
       
       
       
       
       
      _seller.transfer(_sellerProceeds);
    }

    if (_bidAmount > _price) {
       
       
       
       
      uint256 _bidExcess = _bidAmount - _price;

       
       
       
      msg.sender.transfer(_bidExcess);
    }

     
    AuctionSuccessful(_nftAddress, _tokenId, _price, msg.sender);

    return _price;
  }
}