 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}









 
 
 
contract ClockAuctionBase {

     
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

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
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
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenId, price, msg.sender);

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

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


 
 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
         
        bool res = nftAddress.send(this.balance);
    }

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
        whenNotPaused
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

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
        external
        payable
        whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
        external
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
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}


 
 
contract SiringClockAuction is ClockAuction {

     
     
    bool public isSiringClockAuction = true;

     
    function SiringClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

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
    }

     
     
     
     
    function bid(uint256 _tokenId)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
         
        _bid(_tokenId, msg.value);
         
         
        _transfer(seller, _tokenId);
    }

}