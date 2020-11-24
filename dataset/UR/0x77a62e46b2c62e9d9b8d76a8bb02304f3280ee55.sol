 

pragma solidity ^0.4.19;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
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

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause()
        public
        onlyOwner
        whenNotPaused
        returns (bool)
    {
        paused = true;
        Pause();
        return true;
    }

     
    function unpause()
        public
        onlyOwner
        whenPaused
        returns (bool)
    {
        paused = false;
        Unpause();
        return true;
    }
}


 
 
contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external view returns (address _owner);

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 _balance);
}


contract MasterpieceAccessControl {
     
     
     
     

     
    address public ceoAddress;
    address public cfoAddress;
    address public curatorAddress;

     
    bool public paused = false;

     
    event ContractFork(address newContract);

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCurator() {
        require(msg.sender == curatorAddress);
        _;
    }

     
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == curatorAddress
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCurator(address _newCurator) external onlyCEO {
        require(_newCurator != address(0));

        curatorAddress = _newCurator;
    }

     
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause()
        external
        onlyCLevel
        whenNotPaused
    {
        paused = true;
    }

     
     
     
     
     
    function unpause()
        public
        onlyCEO
        whenPaused
    {
         
        paused = false;
    }

}


 
contract MasterpieceBase is MasterpieceAccessControl {

     
     
    struct Masterpiece {
         
        string name;
         
        string artist;
         
        uint64 birthTime;
    }

     
     
    event Birth(address owner, uint256 tokenId, uint256 snatchWindow, string name, string artist);
     
     
    event TransferToken(address from, address to, uint256 tokenId);
     
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 price, address prevOwner, address owner, string name);

     
     
     
    Masterpiece[] masterpieces;

     
     
     
    SaleClockAuction public saleAuction;

     
    mapping (uint256 => address) public masterpieceToOwner;

     
    mapping (uint256 => uint256) public masterpieceToSnatchWindow;

     
     
    mapping (address => uint256) public ownerMasterpieceCount;

     
     
     
    mapping (uint256 => address) public masterpieceToApproved;

     
    mapping (uint256 => uint256) public masterpieceToPrice;

     
    function snatchWindowOf(uint256 _tokenId)
        public
        view
        returns (uint256 price)
    {
        return masterpieceToSnatchWindow[_tokenId];
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownerMasterpieceCount[_to]++;
        masterpieceToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownerMasterpieceCount[_from]--;
             
            delete masterpieceToApproved[_tokenId];
        }
         
        TransferToken(_from, _to, _tokenId);
    }

     
     
     
     
    function _createMasterpiece(
        string _name,
        string _artist,
        uint256 _price,
        uint256 _snatchWindow,
        address _owner
    )
        internal
        returns (uint)
    {
        Masterpiece memory _masterpiece = Masterpiece({
            name: _name,
            artist: _artist,
            birthTime: uint64(now)
        });
        uint256 newMasterpieceId = masterpieces.push(_masterpiece) - 1;

         
        Birth(
            _owner,
            newMasterpieceId,
            _snatchWindow,
            _masterpiece.name,
            _masterpiece.artist
        );

         
        masterpieceToPrice[newMasterpieceId] = _price;

         
        masterpieceToSnatchWindow[newMasterpieceId] = _snatchWindow;

         
        _transfer(0, _owner, newMasterpieceId);

        return newMasterpieceId;
    }

}


 
contract MasterpiecePricing is MasterpieceBase {

     
     
    uint128 private constant FIRST_STEP_LIMIT = 0.05 ether;
    uint128 private constant SECOND_STEP_LIMIT = 0.5 ether;
    uint128 private constant THIRD_STEP_LIMIT = 2.0 ether;
    uint128 private constant FOURTH_STEP_LIMIT = 5.0 ether;

     
     
     
     
    function setNextPriceOf(uint256 tokenId, uint256 salePrice)
        external
        whenNotPaused
    {
         
         
         
        require(msg.sender == address(saleAuction));
        masterpieceToPrice[tokenId] = computeNextPrice(salePrice);
    }

     
    function computeNextPrice(uint256 salePrice)
        internal
        pure
        returns (uint256)
    {
        if (salePrice < FIRST_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 200), 95);
        } else if (salePrice < SECOND_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 135), 96);
        } else if (salePrice < THIRD_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 125), 97);
        } else if (salePrice < FOURTH_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 120), 97);
        } else {
            return SafeMath.div(SafeMath.mul(salePrice, 115), 98);
        }
    }

     
     
    function computePayment(uint256 salePrice)
        internal
        pure
        returns (uint256)
    {
        if (salePrice < FIRST_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 95), 100);
        } else if (salePrice < SECOND_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 96), 100);
        } else if (salePrice < FOURTH_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 97), 100);
        } else {
            return SafeMath.div(SafeMath.mul(salePrice, 98), 100);
        }
    }

}


 
contract MasterpieceOwnership is MasterpiecePricing, ERC721 {

     
    string public constant NAME = "Masterpieces";
     
     
    string public constant SYMBOL = "CMP";

    bytes4 public constant INTERFACE_SIGNATURE_ERC165 =
    bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 public constant INTERFACE_SIGNATURE_ERC721 =
    bytes4(keccak256("name()")) ^
    bytes4(keccak256("symbol()")) ^
    bytes4(keccak256("totalSupply()")) ^
    bytes4(keccak256("balanceOf(address)")) ^
    bytes4(keccak256("ownerOf(uint256)")) ^
    bytes4(keccak256("approve(address,uint256)")) ^
    bytes4(keccak256("transfer(address,uint256)")) ^
    bytes4(keccak256("transferFrom(address,address,uint256)")) ^
    bytes4(keccak256("tokensOfOwner(address)")) ^
    bytes4(keccak256("tokenMetadata(uint256,string)"));

     
     
     
     
     
     
    function approve(address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function transfer(address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
         
         
        require(_to != address(saleAuction));
         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function tokensOfOwner(address _owner)
        external
        view
        returns(uint256[] ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMasterpieces = totalSupply();
            uint256 resultIndex = 0;

            uint256 masterpieceId;
            for (masterpieceId = 0; masterpieceId <= totalMasterpieces; masterpieceId++) {
                if (masterpieceToOwner[masterpieceId] == _owner) {
                    result[resultIndex] = masterpieceId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
     
     
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {
        return ((_interfaceID == INTERFACE_SIGNATURE_ERC165) || (_interfaceID == INTERFACE_SIGNATURE_ERC721));
    }

     
    function name() external pure returns (string) {
        return NAME;
    }

     
    function symbol() external pure returns (string) {
        return SYMBOL;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = masterpieceToOwner[_tokenId];
        require(owner != address(0));
    }

     
     
    function totalSupply() public view returns (uint) {
        return masterpieces.length;
    }

     
     
     
    function balanceOf(address _owner)
        public
        view
        returns (uint256 count)
    {
        return ownerMasterpieceCount[_owner];
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return masterpieceToOwner[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        masterpieceToApproved[_tokenId] = _approved;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return masterpieceToApproved[_tokenId] == _claimant;
    }

     
    function _addressNotNull(address _to) internal pure returns (bool) {
        return _to != address(0);
    }
}


 
 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    MasterpieceOwnership public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) public tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 price, address winner);
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
            _transfer(msg.sender, _tokenId);
             
            nonFungibleContract.setNextPriceOf(_tokenId, price);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction)
        internal
        view
        returns (bool)
    {
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


 
 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
    bytes4 public constant INTERFACE_SIGNATURE_ERC721 = bytes4(0x9a20483d);

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        MasterpieceOwnership candidateContract = MasterpieceOwnership(_nftAddress);
        require(candidateContract.supportsInterface(INTERFACE_SIGNATURE_ERC721));
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
        external
        whenPaused
        onlyOwner
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


 
 
contract SaleClockAuction is ClockAuction {

     
     
    bool public isSaleClockAuction = true;

     
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
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
         
         
        _bid(_tokenId, msg.value);
    }
}


contract MasterpieceAuction is MasterpieceOwnership {

     
     
     
    function withdrawAuctionBalances()
        external
        onlyCLevel
    {
        saleAuction.withdrawBalance();
    }

     
     
     
     
    function setSaleAuctionAddress(address _address)
        external
        onlyCEO
    {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
         
         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

     
    function createSaleAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
         
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, saleAuction);
         
         
        saleAuction.createAuction(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

}


contract MasterpieceSale is MasterpieceAuction {

     
    function purchase(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
        address newOwner = msg.sender;
        address oldOwner = masterpieceToOwner[_tokenId];
        uint256 salePrice = masterpieceToPrice[_tokenId];

         
         
        require(
            (oldOwner == address(this)) ||
            (now - masterpieces[_tokenId].birthTime <= masterpieceToSnatchWindow[_tokenId])
        );

         
        require(oldOwner != newOwner);

         
         
        require(address(oldOwner) != address(saleAuction));

         
        require(_addressNotNull(newOwner));

         
        require(msg.value >= salePrice);

        uint256 payment = uint256(computePayment(salePrice));
        uint256 purchaseExcess = SafeMath.sub(msg.value, salePrice);

         
        masterpieceToPrice[_tokenId] = computeNextPrice(salePrice);

         
        _transfer(oldOwner, newOwner, _tokenId);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        TokenSold(_tokenId, salePrice, masterpieceToPrice[_tokenId], oldOwner, newOwner, masterpieces[_tokenId].name);

         
        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId)
        public
        view
        returns (uint256 price)
    {
        return masterpieceToPrice[_tokenId];
    }

}


contract MasterpieceMinting is MasterpieceSale {

     
     
    uint128 private constant STARTING_PRICE = 0.001 ether;
     
    uint16 private constant PROMO_CREATION_LIMIT = 10000;

     
    uint16 public promoMasterpiecesCreatedCount;
     
    ERC721 public nonFungibleContract;

     
    function createMasterpiece(
        string _name,
        string _artist,
        uint256 _snatchWindow
    )
        public
        onlyCurator
        returns (uint)
    {
        uint256 masterpieceId = _createMasterpiece(_name, _artist, STARTING_PRICE, _snatchWindow, address(this));
        return masterpieceId;
    }

     
     
     
    function createPromoMasterpiece(
        string _name,
        string _artist,
        uint256 _snatchWindow,
        uint256 _price,
        address _owner
    )
        public
        onlyCurator
        returns (uint)
    {
        require(promoMasterpiecesCreatedCount < PROMO_CREATION_LIMIT);

        address masterpieceOwner = _owner;
        if (masterpieceOwner == address(0)) {
            masterpieceOwner = curatorAddress;
        }

        if (_price <= 0) {
            _price = STARTING_PRICE;
        }

        uint256 masterpieceId = _createMasterpiece(_name, _artist, _price, _snatchWindow, masterpieceOwner);
        promoMasterpiecesCreatedCount++;
        return masterpieceId;
    }

}


 
contract MasterpieceCore is MasterpieceMinting {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

    function MasterpieceCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        curatorAddress = msg.sender;
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address)
        external
        onlyCEO
        whenPaused
    {
         
        newContractAddress = _v2Address;
        ContractFork(_v2Address);
    }

     
     
     
     
    function withdrawBalance(address _to) external onlyCFO {
         
        if (_to == address(0)) {
            cfoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

     
     
    function getMasterpiece(uint256 _tokenId) external view returns (
        string name,
        string artist,
        uint256 birthTime,
        uint256 snatchWindow,
        uint256 sellingPrice,
        address owner
    ) {
        Masterpiece storage masterpiece = masterpieces[_tokenId];
        name = masterpiece.name;
        artist = masterpiece.artist;
        birthTime = uint256(masterpiece.birthTime);
        snatchWindow = masterpieceToSnatchWindow[_tokenId];
        sellingPrice = masterpieceToPrice[_tokenId];
        owner = masterpieceToOwner[_tokenId];
    }

     
     
     
     
     
    function unpause()
        public
        onlyCEO
        whenPaused
    {
        require(saleAuction != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

}