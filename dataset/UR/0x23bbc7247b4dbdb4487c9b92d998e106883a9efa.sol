 

pragma solidity ^0.4.21;

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

contract Ownable {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function Ownable() public {
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

contract StorageBase is Ownable {

    function withdrawBalance() external onlyOwner returns (bool) {
         
         
        bool res = msg.sender.send(address(this).balance);
        return res;
    }
}

contract ClockAuctionStorage is StorageBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    mapping (uint256 => Auction) tokenIdToAuction;

    function addAuction(
        uint256 _tokenId,
        address _seller,
        uint128 _startingPrice,
        uint128 _endingPrice,
        uint64 _duration,
        uint64 _startedAt
    )
        external
        onlyOwner
    {
        tokenIdToAuction[_tokenId] = Auction(
            _seller,
            _startingPrice,
            _endingPrice,
            _duration,
            _startedAt
        );
    }

    function removeAuction(uint256 _tokenId) public onlyOwner {
        delete tokenIdToAuction[_tokenId];
    }

    function getAuction(uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint128 startingPrice,
            uint128 endingPrice,
            uint64 duration,
            uint64 startedAt
        )
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    function isOnAuction(uint256 _tokenId) external view returns (bool) {
        return (tokenIdToAuction[_tokenId].startedAt > 0);
    }

    function getSeller(uint256 _tokenId) external view returns (address) {
        return tokenIdToAuction[_tokenId].seller;
    }

    function transfer(ERC721 _nonFungibleContract, address _receiver, uint256 _tokenId) external onlyOwner {
         
        _nonFungibleContract.transfer(_receiver, _tokenId);
    }
}

contract SiringClockAuctionStorage is ClockAuctionStorage {
    bool public isSiringClockAuctionStorage = true;
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

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract HasNoContracts is Pausable {

    function reclaimContract(address _contractAddr) external onlyOwner whenPaused {
        Ownable contractInst = Ownable(_contractAddr);
        contractInst.transferOwnership(owner);
    }
}

contract LogicBase is HasNoContracts {

     
     
     
    bytes4 constant InterfaceSignature_NFC = bytes4(0x9f40b779);

     
    ERC721 public nonFungibleContract;

     
    StorageBase public storageContract;

    function LogicBase(address _nftAddress, address _storageAddress) public {
         
        paused = true;

        setNFTAddress(_nftAddress);

        require(_storageAddress != address(0));
        storageContract = StorageBase(_storageAddress);
    }

     
     
     
    function destroy() external onlyOwner whenPaused {
        address storageOwner = storageContract.owner();
         
        require(storageOwner != address(this));
         
        selfdestruct(owner);
    }

     
     
     
    function destroyAndSendToStorageOwner() external onlyOwner whenPaused {
        address storageOwner = storageContract.owner();
         
        require(storageOwner != address(this));
         
        selfdestruct(storageOwner);
    }

     
    function unpause() public onlyOwner whenPaused {
         
        require(nonFungibleContract != address(0));
        require(storageContract != address(0));
         
        require(storageContract.owner() == address(this));

        super.unpause();
    }

    function setNFTAddress(address _nftAddress) public onlyOwner {
        require(_nftAddress != address(0));
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_NFC));
        nonFungibleContract = candidateContract;
    }

     
    function withdrawBalance() external returns (bool) {
        address nftAddress = address(nonFungibleContract);
         
        require(msg.sender == owner || msg.sender == nftAddress);
         
         
        bool res = nftAddress.send(address(this).balance);
        return res;
    }

    function withdrawBalanceFromStorageContract() external returns (bool) {
        address nftAddress = address(nonFungibleContract);
         
        require(msg.sender == owner || msg.sender == nftAddress);
         
         
        bool res = storageContract.withdrawBalance();
        return res;
    }
}

contract ClockAuction is LogicBase {
    
     
    ClockAuctionStorage public clockAuctionStorage;

     
     
    uint256 public ownerCut;

     
    uint256 public minCutValue;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner, address seller, uint256 sellerProceeds);
    event AuctionCancelled(uint256 tokenId);

    function ClockAuction(address _nftAddress, address _storageAddress, uint256 _cut, uint256 _minCutValue) 
        LogicBase(_nftAddress, _storageAddress) public
    {
        setOwnerCut(_cut);
        setMinCutValue(_minCutValue);

        clockAuctionStorage = ClockAuctionStorage(_storageAddress);
    }

    function setOwnerCut(uint256 _cut) public onlyOwner {
        require(_cut <= 10000);
        ownerCut = _cut;
    }

    function setMinCutValue(uint256 _minCutValue) public onlyOwner {
        minCutValue = _minCutValue;
    }

    function getMinPrice() public view returns (uint256) {
         
         
        return minCutValue;
    }

     
     
    function isValidPrice(uint256 _startingPrice, uint256 _endingPrice) public view returns (bool) {
        return (_startingPrice < _endingPrice ? _startingPrice : _endingPrice) >= getMinPrice();
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
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        
         
         
        nonFungibleContract.transferFrom(_seller, address(clockAuctionStorage), _tokenId);

         
        require(_duration >= 1 minutes);

        clockAuctionStorage.addAuction(
            _tokenId,
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );

        emit AuctionCreated(_tokenId, _startingPrice, _endingPrice, _duration);
    }

    function cancelAuction(uint256 _tokenId) external {
        require(clockAuctionStorage.isOnAuction(_tokenId));
        address seller = clockAuctionStorage.getSeller(_tokenId);
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _tokenId) external whenPaused onlyOwner {
        require(clockAuctionStorage.isOnAuction(_tokenId));
        address seller = clockAuctionStorage.getSeller(_tokenId);
        _cancelAuction(_tokenId, seller);
    }

    function getAuction(uint256 _tokenId)
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
        require(clockAuctionStorage.isOnAuction(_tokenId));
        return clockAuctionStorage.getAuction(_tokenId);
    }

    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        require(clockAuctionStorage.isOnAuction(_tokenId));
        return _currentPrice(_tokenId);
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        clockAuctionStorage.removeAuction(_tokenId);
        clockAuctionStorage.transfer(nonFungibleContract, _seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount, address bidder) internal returns (uint256) {

        require(clockAuctionStorage.isOnAuction(_tokenId));

         
        uint256 price = _currentPrice(_tokenId);
        require(_bidAmount >= price);

        address seller = clockAuctionStorage.getSeller(_tokenId);
        uint256 sellerProceeds = 0;

         
        clockAuctionStorage.removeAuction(_tokenId);

         
        if (price > 0) {
             
            uint256 auctioneerCut = _computeCut(price);
            sellerProceeds = price - auctioneerCut;

             
            seller.transfer(sellerProceeds);
        }

         
         
         
        uint256 bidExcess = _bidAmount - price;
        bidder.transfer(bidExcess);

        emit AuctionSuccessful(_tokenId, price, bidder, seller, sellerProceeds);

        return price;
    }

    function _currentPrice(uint256 _tokenId) internal view returns (uint256) {

        uint256 secondsPassed = 0;

        address seller;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
        (seller, startingPrice, endingPrice, duration, startedAt) = clockAuctionStorage.getAuction(_tokenId);

        if (now > startedAt) {
            secondsPassed = now - startedAt;
        }

        return _computeCurrentPrice(
            startingPrice,
            endingPrice,
            duration,
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
        uint256 cutValue = _price * ownerCut / 10000;
        if (_price < minCutValue) return cutValue;
        if (cutValue > minCutValue) return cutValue;
        return minCutValue;
    }
}

contract SiringClockAuction is ClockAuction {

    bool public isSiringClockAuction = true;

    function SiringClockAuction(address _nftAddr, address _storageAddress, uint256 _cut, uint256 _minCutValue) 
        ClockAuction(_nftAddr, _storageAddress, _cut, _minCutValue) public
    {
        require(SiringClockAuctionStorage(_storageAddress).isSiringClockAuctionStorage());
    }

    function bid(uint256 _tokenId, address bidder) external payable {
         
        require(msg.sender == address(nonFungibleContract));
         
        address seller = clockAuctionStorage.getSeller(_tokenId);
         
        _bid(_tokenId, msg.value, bidder);
         
        clockAuctionStorage.transfer(nonFungibleContract, seller, _tokenId);
    }
}