 

pragma solidity ^0.4.25;

 
 
 
interface ERC721   {
     
     
     
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
 
 
interface ERC721Metadata   {
     
    function name() external view returns (string _name);

     
    function symbol() external view returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}

 
 
 
interface ERC721Enumerable   {
     
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

 
interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
 
contract TimeAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);
    event AuctionSettled(uint256 tokenId, uint256 price, uint256 sellerProceeds, address seller, address buyer);
    event AuctionRepriced(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint64 duration, uint64 startedAt);

     
    function() external {}

     
     
    modifier canBeStoredWith32Bits(uint256 _value) {
        require(_value <= 4294967295);
        _;
    }

     
     
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.approve(_receiver, _tokenId);
        nonFungibleContract.transferFrom(address(this), _receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            address(_auction.seller),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
            emit AuctionSettled(_tokenId, price, sellerProceeds, seller, msg.sender);
        }

         
        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
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
    )
        internal
        pure
        returns (uint256)
    {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract TimeAuction is Pausable, TimeAuctionBase {

     
     
     
     
     
     
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);
        require(msg.sender == nftAddress);
        nftAddress.transfer(address(this).balance);
    }

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
        whenNotPaused
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
    function bid(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 currentPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        uint256 price = _currentPrice(auction);
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            price,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentAuctionPrices(uint128[] _tokenIds) public view returns (uint128[50]) {

        require (_tokenIds.length <= 50);

         
        uint128[50] memory currentPricesArray;

        for (uint8 i = 0; i < _tokenIds.length; i++) {
          Auction storage auction = tokenIdToAuction[_tokenIds[i]];
          if (_isOnAuction(auction)) {
            uint256 price = _currentPrice(auction);
            currentPricesArray[i] = uint128(price);
          }
        }

        return currentPricesArray;
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}

 
contract SaleClockAuctionListener {
    function implementsSaleClockAuctionListener() public pure returns (bool);
    function auctionCreated(uint256 tokenId, address seller, uint128 startingPrice, uint128 endingPrice, uint64 duration) public;
    function auctionSuccessful(uint256 tokenId, uint128 totalPrice, address seller, address buyer) public;
    function auctionCancelled(uint256 tokenId, address seller) public;
}

 
contract SaleClockAuction is TimeAuction {

     
     
    SaleClockAuctionListener public listener;

     
    constructor(address _nftAddr, uint256 _cut) public TimeAuction(_nftAddr, _cut) {

    }

     
     
    function isSaleClockAuction() public pure returns (bool) {
        return true;
    }

     
     
     
     
     
     
     
    function setListener(address _listener) public {
      require(listener == address(0));
      SaleClockAuctionListener candidateContract = SaleClockAuctionListener(_listener);
      require(candidateContract.implementsSaleClockAuctionListener());
      listener = candidateContract;
    }

     
     
     
     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);

        if (listener != address(0)) {
          listener.auctionCreated(_tokenId, _seller, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration));
        }
    }

     
     
     
     
     
     
     
     
     
     
    function repriceAuctions(
        uint256[] _tokenIds,
        uint256[] _startingPrices,
        uint256[] _endingPrices,
        uint256 _duration,
        address _seller
    )
    public
    canBeStoredWith64Bits(_duration)
    {
        require(msg.sender == address(nonFungibleContract));

        uint64 timeNow = uint64(now);
        for (uint32 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint256 _startingPrice = _startingPrices[i];
            uint256 _endingPrice = _endingPrices[i];

             
            require(_startingPrice < 340282366920938463463374607431768211455);
            require(_endingPrice < 340282366920938463463374607431768211455);

            Auction storage auction = tokenIdToAuction[_tokenId];

             
             
             
            if (auction.seller == _seller) {
                 
                auction.startingPrice = uint128(_startingPrice);
                auction.endingPrice = uint128(_endingPrice);
                auction.duration = uint64(_duration);
                auction.startedAt = timeNow;
                emit AuctionRepriced(_tokenId, _startingPrice, _endingPrice, uint64(_duration), timeNow);
            }
        }
    }

     
     
    function batchBid(uint256[] _tokenIds) public payable whenNotPaused
    {
         
         
        uint256 totalPrice = 0;
        for (uint32 i = 0; i < _tokenIds.length; i++) {
          uint256 _tokenId = _tokenIds[i];
          Auction storage auction = tokenIdToAuction[_tokenId];
          totalPrice += _currentPrice(auction);
        }
        require(msg.value >= totalPrice);

         
         
        for (i = 0; i < _tokenIds.length; i++) {

          _tokenId = _tokenIds[i];
          auction = tokenIdToAuction[_tokenId];

           
           
          address seller = auction.seller;

          uint256 bid = _currentPrice(auction);
          uint256 price = _bid(_tokenId, bid);
          _transfer(msg.sender, _tokenId);

          if (listener != address(0)) {
            listener.auctionSuccessful(_tokenId, uint128(price), seller, msg.sender);
          }
        }
    }

     
     
     
    function bid(uint256 _tokenId) public payable whenNotPaused
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
        address seller = auction.seller;

         
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

        if (listener != address(0)) {
          listener.auctionSuccessful(_tokenId, uint128(price), seller, msg.sender);
        }
    }

     
     
     
    function cancelAuction(uint256 _tokenId) public
    {
      super.cancelAuction(_tokenId);
      if (listener != address(0)) {
        listener.auctionCancelled(_tokenId, msg.sender);
      }
    }

}