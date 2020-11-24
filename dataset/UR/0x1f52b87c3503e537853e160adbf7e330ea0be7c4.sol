 

pragma solidity ^0.4.18;


 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint _tokenId) public view returns (address _owner);
    function approve(address _to, uint _tokenId) public;
    function transferFrom(address _from, address _to, uint _tokenId) public;
    function transfer(address _to, uint _tokenId) public;
    function implementsERC721() public view returns (bool _implementsERC721);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address nftAddress;
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
     
    uint256 public ownerCut;

     
    mapping (address => mapping(uint256 => Auction)) nftToTokenIdToAuction;

    event AuctionCreated(address nftAddress, uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(address nftAddress, uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(address nftAddress, uint256 tokenId);

     
    function() external {}

     
     
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

     
     
     
     
    function _owns(address _nft, address _claimant, uint256 _tokenId) internal view returns (bool) {
        ERC721 nonFungibleContract = _getNft(_nft);
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
     
    function _escrow(address _nft, address _owner, uint256 _tokenId) internal {
        ERC721 nonFungibleContract = _getNft(_nft);

         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
     
    function _transfer(address _nft, address _receiver, uint256 _tokenId) internal {
        ERC721 nonFungibleContract = _getNft(_nft);

         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(address _nft, uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        nftToTokenIdToAuction[_nft][_tokenId] = _auction;
        
        AuctionCreated(
            address(_nft),
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(address _nft, uint256 _tokenId, address _seller) internal {
        _removeAuction(_nft, _tokenId);
        _transfer(_nft, _seller, _tokenId);
        AuctionCancelled(_nft, _tokenId);
    }

     
     
    function _bid(address _nft, uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = nftToTokenIdToAuction[_nft][_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_nft, _tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
        AuctionSuccessful(_nft, _tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(address _nft, uint256 _tokenId) internal {
        delete nftToTokenIdToAuction[_nft][_tokenId];
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

     
     
    function _getNft(address _nft) internal view returns (ERC721) {
        ERC721 candidateContract = ERC721(_nft);
         
        return candidateContract;
    }

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
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

 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
     
    function ClockAuction(uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;
    }

     
     
     
     
    function withdrawBalance() external {
        require(
            msg.sender == owner
        );
        msg.sender.transfer(this.balance);
    }

     
     
     
     
     
     
     
     
     
    function createAuction(
        address _nftAddress,
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
        require(_owns(_nftAddress, msg.sender, _tokenId));
        _escrow(_nftAddress, msg.sender, _tokenId);
        Auction memory auction = Auction(
            _nftAddress,
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_nftAddress, _tokenId, auction);
    }

     
     
     
     
     
    function bid(address _nftAddress, uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
         
        _bid(_nftAddress, _tokenId, msg.value);
        _transfer(_nftAddress, msg.sender, _tokenId);
    }

     
     
     
     
     
     
    function cancelAuction(address _nftAddress, uint256 _tokenId)
        public
    {
        Auction storage auction = nftToTokenIdToAuction[_nftAddress][_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_nftAddress, _tokenId, seller);
    }

     
     
     
     
     
    function cancelAuctionWhenPaused(address _nftAddress, uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = nftToTokenIdToAuction[_nftAddress][_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_nftAddress, _tokenId, auction.seller);
    }

     
     
     
    function getAuction(address _nftAddress, uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = nftToTokenIdToAuction[_nftAddress][_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
     
    function getCurrentPrice(address _nftAddress, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = nftToTokenIdToAuction[_nftAddress][_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}

 
contract SaleClockAuction is ClockAuction {

     
    function SaleClockAuction(uint256 _cut) public
        ClockAuction(_cut) {}

     
     
     
     
     
     
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        address seller = msg.sender;
        _escrow(_nftAddress, seller, _tokenId);
        Auction memory auction = Auction(
            _nftAddress,
            seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_nftAddress, _tokenId, auction);
    }

     
     
    function bid(address _nftAddress, uint256 _tokenId)
        public
        payable
    {
         
        address seller = nftToTokenIdToAuction[_nftAddress][_tokenId].seller;
        uint256 price = _bid(_nftAddress, _tokenId, msg.value);
        _transfer(_nftAddress, msg.sender, _tokenId);
    }
}