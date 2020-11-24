 

pragma solidity ^0.4.23;

library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
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
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}

contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

 
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}

 
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}

 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;

     
     
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) internal tokenOwner;

     
    mapping (uint256 => address) internal tokenApprovals;

     
    mapping (address => uint256) internal ownedTokensCount;

     
    mapping (address => mapping (address => bool)) internal operatorApprovals;

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require (ownerOf(_tokenId) == msg.sender);
        _;
    }

     
    modifier canTransfer(uint256 _tokenId) {
        require (isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        require (_owner != address(0));
        return ownedTokensCount[_owner];
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    function isOwnerOf(address _owner, uint256 _tokenId) public view returns (bool) {
        address owner = ownerOf(_tokenId);
        return owner == _owner;
    }

     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

     
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require (_to != owner);
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

     
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

     
    function setApprovalForAll(address _to, bool _approved) public {
        require (_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

     
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require (_from != address(0));
        require (_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
         
        safeTransferFrom(_from, _to, _tokenId, "");
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
         
        require (checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

     
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
         
         
         
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
         
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

     
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

     
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require (ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
        }
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
         
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require (ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

     
    function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

 
contract ERC721Receiver {
     
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }
}

 
contract ERC721Token is ERC721, ERC721BasicToken {

     
    string internal name_ = "CryptoFlowers";

     
    string internal symbol_ = "CF";

     
    mapping(address => uint256[]) internal ownedTokens;

     
    mapping(uint256 => uint256) internal ownedTokensIndex;

     
    uint256[] internal allTokens;

     
    mapping(uint256 => uint256) internal allTokensIndex;

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];

        return string(bab);
    }

     
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        string memory infoUrl;
        infoUrl = strConcat('https: 
        return infoUrl;
    }

     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require (_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

     
    function totalSupply() public view returns (uint256) {
        return allTokens.length - 1;
    }

     
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require (_index <= totalSupply());
        return allTokens[_index];
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

     
    function name() public view returns (string) {
        return name_;
    }

     
    function symbol() public view returns (string) {
        return symbol_;
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

     
    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);

         
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }

    bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
     

    bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
     

    bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
     

    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
     

    bytes4 public constant InterfaceSignature_ERC721Optional =- 0x4f558e79;
     

     
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165)
        || (_interfaceID == InterfaceSignature_ERC721)
        || (_interfaceID == InterfaceSignature_ERC721Enumerable)
        || (_interfaceID == InterfaceSignature_ERC721Metadata));
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

}

contract GenomeInterface {
    function isGenome() public pure returns (bool);
    function mixGenes(uint256 genes1, uint256 genes2) public returns (uint256);
}

contract FlowerAdminAccess {
    address public rootAddress;
    address public adminAddress;

    event ContractUpgrade(address newContract);

    address public gen0SellerAddress;
    address public giftHolderAddress;

    bool public stopped = false;

    modifier onlyRoot() {
        require(msg.sender == rootAddress);
        _;
    }

    modifier onlyAdmin()  {
        require(msg.sender == adminAddress);
        _;
    }

    modifier onlyAdministrator() {
        require(msg.sender == rootAddress || msg.sender == adminAddress);
        _;
    }

    function setRoot(address _newRoot) external onlyAdministrator {
        require(_newRoot != address(0));
        rootAddress = _newRoot;
    }

    function setAdmin(address _newAdmin) external onlyRoot {
        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

    modifier whenNotStopped() {
        require(!stopped);
        _;
    }

    modifier whenStopped {
        require(stopped);
        _;
    }

    function setStop() public onlyAdministrator whenNotStopped {
        stopped = true;
    }

    function setStart() public onlyAdministrator whenStopped {
        stopped = false;
    }
}

contract FlowerBase is ERC721Token {

    struct Flower {
        uint256 genes;
        uint64 birthTime;
        uint64 cooldownEndBlock;
        uint32 matronId;
        uint32 sireId;
        uint16 cooldownIndex;
        uint16 generation;
    }

    Flower[] flowers;

    mapping (uint256 => uint256) genomeFlowerIds;

     
    uint32[14] public cooldowns = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];

    event Birth(address owner, uint256 flowerId, uint256 matronId, uint256 sireId, uint256 genes);
    event Transfer(address from, address to, uint256 tokenId);
    event Money(address from, string actionType, uint256 sum, uint256 cut, uint256 tokenId, uint256 blockNumber);

    function _createFlower(uint256 _matronId, uint256 _sireId, uint256 _generation, uint256 _genes, address _owner) internal returns (uint) {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));
        require(checkUnique(_genes));

        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Flower memory _flower = Flower({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
            });

        uint256 newFlowerId = flowers.push(_flower) - 1;

        require(newFlowerId == uint256(uint32(newFlowerId)));

        genomeFlowerIds[_genes] = newFlowerId;

        emit Birth(_owner, newFlowerId, uint256(_flower.matronId), uint256(_flower.sireId), _flower.genes);

        _mint(_owner, newFlowerId);

        return newFlowerId;
    }

    function checkUnique(uint256 _genome) public view returns (bool) {
        uint256 _flowerId = uint256(genomeFlowerIds[_genome]);
        return !(_flowerId > 0);
    }
}

contract FlowerOwnership is FlowerBase, FlowerAdminAccess {
    SaleClockAuction public saleAuction;
    BreedingClockAuction public breedingAuction;

    uint256 public secondsPerBlock = 15;

    function setSecondsPerBlock(uint256 secs) external onlyAdministrator {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
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

    ERC721Token public nonFungibleContract;

    uint256 public ownerCut;

    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);
    event Money(address from, string actionType, uint256 sum, uint256 cut, uint256 tokenId, uint256 blockNumber);

    function isOwnerOf(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(this, _receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(uint256(_tokenId), uint256(_auction.startingPrice), uint256(_auction.endingPrice), uint256(_auction.duration));
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount, address _sender) internal returns (uint256) {
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

            emit Money(_sender, "AuctionSuccessful", price, auctioneerCut, _tokenId, block.number);
        }

        uint256 bidExcess = _bidAmount - price;

        _sender.transfer(bidExcess);

        emit AuctionSuccessful(_tokenId, price, _sender);

        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0 && _auction.startedAt < now);
    }

    function _currentPrice(Auction storage _auction) internal view returns (uint256) {
        uint256 secondsPassed = 0;

        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(_auction.startingPrice, _auction.endingPrice, _auction.duration, secondsPassed);
    }

    function _computeCurrentPrice(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _secondsPassed) internal pure returns (uint256) {
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
        return uint256(_price * ownerCut / 10000);
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

    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract ClockAuction is Pausable, ClockAuctionBase {
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Token candidateContract = ERC721Token(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);
        require(msg.sender == owner || msg.sender == nftAddress);
        owner.transfer(address(this).balance);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external whenNotPaused {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));
        require(isOwnerOf(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(startAt)
        );
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId, address _sender) external payable whenNotPaused {
        _bid(_tokenId, msg.value, _sender);
        _transfer(_sender, _tokenId);
    }

    function cancelAuction(uint256 _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionByAdmin(uint256 _tokenId) onlyOwner external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    function getAuction(uint256 _tokenId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (auction.seller, auction.startingPrice, auction.endingPrice, auction.duration, auction.startedAt);
    }

    function getCurrentPrice(uint256 _tokenId) external view returns (uint256){
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

     
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract BreedingClockAuction is ClockAuction {

    bool public isBreedingClockAuction = true;

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

    function bid(uint256 _tokenId, address _sender) external payable {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value, _sender);
        _transfer(seller, _tokenId);
    }

    function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(_seller, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration), uint64(startAt));
        _addAuction(_tokenId, auction);
    }
}





contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;

    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

    address public gen0SellerAddress;
    function setGen0SellerAddress(address _newAddress) external {
        require(msg.sender == address(nonFungibleContract));
        gen0SellerAddress = _newAddress;
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(_seller, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration), uint64(startAt));
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId) external payable {
         
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value, msg.sender);
        _transfer(msg.sender, _tokenId);

         
        if (seller == address(gen0SellerAddress)) {
             
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function bidGift(uint256 _tokenId, address _to) external payable {
         
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value, msg.sender);
        _transfer(_to, _tokenId);

         
        if (seller == address(gen0SellerAddress)) {
             
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

    function computeCut(uint256 _price) public view returns (uint256) {
        return _computeCut(_price);
    }

    function getSeller(uint256 _tokenId) public view returns (address) {
        return address(tokenIdToAuction[_tokenId].seller);
    }
}

 
contract FlowerBreeding is FlowerOwnership {

     
    uint256 public autoBirthFee = 2 finney;
    uint256 public giftFee = 2 finney;

    GenomeInterface public geneScience;

     
    function setGenomeContractAddress(address _address) external onlyAdministrator {
        geneScience = GenomeInterface(_address);
    }

    function _isReadyToAction(Flower _flower) internal view returns (bool) {
        return _flower.cooldownEndBlock <= uint64(block.number);
    }

    function isReadyToAction(uint256 _flowerId) public view returns (bool) {
        require(_flowerId > 0);
        Flower storage flower = flowers[_flowerId];
        return _isReadyToAction(flower);
    }

    function _setCooldown(Flower storage _flower) internal {
        _flower.cooldownEndBlock = uint64((cooldowns[_flower.cooldownIndex]/secondsPerBlock) + block.number);

        if (_flower.cooldownIndex < 13) {
            _flower.cooldownIndex += 1;
        }
    }

    function setAutoBirthFee(uint256 val) external onlyAdministrator {
        autoBirthFee = val;
    }

    function setGiftFee(uint256 _fee) external onlyAdministrator {
        giftFee = _fee;
    }

     
    function _isValidPair(Flower storage _matron, uint256 _matronId, Flower storage _sire, uint256 _sireId) private view returns(bool) {
        if (_matronId == _sireId) {
            return false;
        }

         
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

         
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

         
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        return true;
    }

    function canBreedWith(uint256 _matronId, uint256 _sireId) external view returns (bool) {
        return _canBreedWith(_matronId, _sireId);
    }

    function _canBreedWith(uint256 _matronId, uint256 _sireId) internal view returns (bool) {
        require(_matronId > 0);
        require(_sireId > 0);
        Flower storage matron = flowers[_matronId];
        Flower storage sire = flowers[_sireId];
        return _isValidPair(matron, _matronId, sire, _sireId);
    }

    function _born(uint256 _matronId, uint256 _sireId) internal {
        Flower storage sire = flowers[_sireId];
        Flower storage matron = flowers[_matronId];

        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes);
        address owner = ownerOf(_matronId);
        uint256 flowerId = _createFlower(_matronId, _sireId, parentGen + 1, childGenes, owner);

        Flower storage child = flowers[flowerId];

        _setCooldown(sire);
        _setCooldown(matron);
        _setCooldown(child);
    }

     
    function breedOwn(uint256 _matronId, uint256 _sireId) external payable whenNotStopped {
        require(msg.value >= autoBirthFee);
        require(isOwnerOf(msg.sender, _matronId));
        require(isOwnerOf(msg.sender, _sireId));

        Flower storage matron = flowers[_matronId];
        require(_isReadyToAction(matron));

        Flower storage sire = flowers[_sireId];
        require(_isReadyToAction(sire));

        require(_isValidPair(matron, _matronId, sire, _sireId));

        _born(_matronId, _sireId);

        gen0SellerAddress.transfer(autoBirthFee);

        emit Money(msg.sender, "BirthFee-own", autoBirthFee, autoBirthFee, _sireId, block.number);
    }
}

 
contract FlowerAuction is FlowerBreeding {

     
    function setSaleAuctionAddress(address _address) external onlyAdministrator {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

     
    function setBreedingAuctionAddress(address _address) external onlyAdministrator {
        BreedingClockAuction candidateContract = BreedingClockAuction(_address);
        require(candidateContract.isBreedingClockAuction());
        breedingAuction = candidateContract;
    }

     
    function createSaleAuction(uint256 _flowerId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotStopped {
        require(isOwnerOf(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));
        approve(saleAuction, _flowerId);
        saleAuction.createAuction(_flowerId, _startingPrice, _endingPrice, _duration, msg.sender, 0);
    }

     
    function createBreedingAuction(uint256 _flowerId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotStopped {
        require(isOwnerOf(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));
        approve(breedingAuction, _flowerId);
        breedingAuction.createAuction(_flowerId, _startingPrice, _endingPrice, _duration, msg.sender, 0);
    }

     
    function bidOnBreedingAuction(uint256 _sireId, uint256 _matronId) external payable whenNotStopped {
        require(isOwnerOf(msg.sender, _matronId));
        require(isReadyToAction(_matronId));
        require(isReadyToAction(_sireId));
        require(_canBreedWith(_matronId, _sireId));

        uint256 currentPrice = breedingAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

         
        breedingAuction.bid.value(msg.value - autoBirthFee)(_sireId, msg.sender);
        _born(uint32(_matronId), uint32(_sireId));
        gen0SellerAddress.transfer(autoBirthFee);
        emit Money(msg.sender, "BirthFee-bid", autoBirthFee, autoBirthFee, _sireId, block.number);
    }

     
    function withdrawAuctionBalances() external onlyAdministrator {
        saleAuction.withdrawBalance();
        breedingAuction.withdrawBalance();
    }

    function sendGift(uint256 _flowerId, address _to) external payable whenNotStopped {
        require(isOwnerOf(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));

        transferFrom(msg.sender, _to, _flowerId);
    }

    function makeGift(uint256 _flowerId) external payable whenNotStopped {
        require(isOwnerOf(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));
        require(msg.value >= giftFee);

        transferFrom(msg.sender, giftHolderAddress, _flowerId);
        giftHolderAddress.transfer(msg.value);

        emit Money(msg.sender, "MakeGift", msg.value, msg.value, _flowerId, block.number);
    }
}

contract FlowerCore is FlowerAuction, Ownable {
     
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;
     
    uint256 public constant GEN0_STARTING_PRICE = 10 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;
     
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    constructor() public {
        stopped = true;
        rootAddress = msg.sender;
        adminAddress = msg.sender;
        _createFlower(0, 0, 0, uint256(-1), address(0));
    }

    function setGen0SellerAddress(address _newAddress) external onlyAdministrator {
        gen0SellerAddress = _newAddress;
        saleAuction.setGen0SellerAddress(_newAddress);
    }

    function setGiftHolderAddress(address _newAddress) external onlyAdministrator {
        giftHolderAddress = _newAddress;
    }

     
    function createPromoFlower(uint256 _genes, address _owner) external onlyAdministrator {
        address flowerOwner = _owner;
        if (flowerOwner == address(0)) {
            flowerOwner = adminAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);
        promoCreatedCount++;
        gen0CreatedCount++;
        _createFlower(0, 0, 0, _genes, flowerOwner);
    }

    function createGen0Auction(uint256 _genes, uint64 _auctionStartAt) external onlyAdministrator {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);
        uint256 flowerId = _createFlower(0, 0, 0, _genes, address(gen0SellerAddress));
        tokenApprovals[flowerId] = saleAuction;
         

        gen0CreatedCount++;

        saleAuction.createAuction(flowerId, _computeNextGen0Price(), 0, GEN0_AUCTION_DURATION, address(gen0SellerAddress), _auctionStartAt);
    }

     
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

         
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

         
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }

     
    function getFlower(uint256 _id) external view returns (bool isReady, uint256 cooldownIndex, uint256 nextActionAt, uint256 birthTime, uint256 matronId, uint256 sireId, uint256 generation, uint256 genes) {
        Flower storage flower = flowers[_id];
        isReady = (flower.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(flower.cooldownIndex);
        nextActionAt = uint256(flower.cooldownEndBlock);
        birthTime = uint256(flower.birthTime);
        matronId = uint256(flower.matronId);
        sireId = uint256(flower.sireId);
        generation = uint256(flower.generation);
        genes = flower.genes;
    }

     
    function unstop() public onlyAdministrator whenStopped {
        require(geneScience != address(0));

        super.setStart();
    }

    function withdrawBalance() external onlyAdministrator {
        owner.transfer(address(this).balance);
    }
}