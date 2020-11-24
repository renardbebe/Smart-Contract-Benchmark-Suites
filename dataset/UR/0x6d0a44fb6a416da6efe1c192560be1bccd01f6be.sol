 

pragma solidity ^0.4.19;

 
contract OwnableSimple {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function OwnableSimple() public {
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

 
contract RandomApi {
    uint64 _seed = 0;

    function random(uint64 maxExclusive) public returns (uint64 randomNumber) {
         
        _seed = uint64(keccak256(keccak256(block.blockhash(block.number - 1), _seed), block.timestamp));
        return _seed % maxExclusive;
    }

    function random256() public returns (uint256 randomNumber) {
        uint256 rand = uint256(keccak256(keccak256(block.blockhash(block.number - 1), _seed), block.timestamp));
        _seed = uint64(rand);
        return rand;
    }
}

 
 
contract ERC165 {
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
 
 
contract ERC721 is ERC165 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 count);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
     
     
    function takeOwnership(uint256 _tokenId) external;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
     
     
    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl);
    
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    function tokenMetadata(uint256 _tokenId) external view returns (string infoUrl);
}

 
 
 
library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
    
    function memcpy(uint dest, uint src, uint len) private pure {
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
    
    function toString(slice self) internal pure returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }
    
    function len(slice self) internal pure returns (uint l) {
         
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }
    
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }
    
    function toSliceB32(bytes32 self) internal pure returns (slice ret) {
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }
    
    function concat(slice self, slice other) internal pure returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }
}

 
contract PausableSimple is OwnableSimple {
    event Pause();
    event Unpause();

    bool public paused = true;

     
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

 
 
 
contract PresaleMarket is PausableSimple {
    struct Auction {
        address seller;
        uint256 price;            
    }

    ERC721 public artworkContract;
    mapping (uint256 => Auction) artworkIdToAuction;

     
     
     
     
     
     
    uint256 public distributionCut = 2500;
    bool public constant isPresaleMarket = true;

    event AuctionCreated(uint256 _artworkId, uint256 _price);
    event AuctionConcluded(uint256 _artworkId, uint256 _price, address _buyer);
    event AuctionCancelled(uint256 _artworkId);

     
     
     
     
     
     
     
     
    function auctionsRunByUser(address _address) external view returns(uint256[]) {
        uint256 allArtworkCount = artworkContract.balanceOf(this);

        uint256 artworkCount = 0;
        uint256[] memory allArtworkIds = new uint256[](allArtworkCount);
        for(uint256 i = 0; i < allArtworkCount; i++) {
            uint256 artworkId = artworkContract.tokenOfOwnerByIndex(this, i);
            Auction storage auction = artworkIdToAuction[artworkId];
            if(auction.seller == _address) {
                allArtworkIds[artworkCount++] = artworkId;
            }
        }

        uint256[] memory result = new uint256[](artworkCount);
        for(i = 0; i < artworkCount; i++) {
            result[i] = allArtworkIds[i];
        }

        return result;
    }

     
    function PresaleMarket(address _artworkContract) public {
        artworkContract = ERC721(_artworkContract);
    }

    function bid(uint256 _artworkId) external payable whenNotPaused {
        require(_isAuctionExist(_artworkId));
        Auction storage auction = artworkIdToAuction[_artworkId];
        require(auction.seller != msg.sender);
        uint256 price = auction.price;
        require(msg.value == price);

        address seller = auction.seller;
        delete artworkIdToAuction[_artworkId];

        if(price > 0) {
            uint256 myCut =  price * distributionCut / 100000;
            uint256 sellerCut = price - myCut;
            seller.transfer(sellerCut);
        }

        AuctionConcluded(_artworkId, price, msg.sender);
        artworkContract.transfer(msg.sender, _artworkId);
    }

    function getAuction(uint256 _artworkId) external view returns(address seller, uint256 price) {
        require(_isAuctionExist(_artworkId));
        Auction storage auction = artworkIdToAuction[_artworkId];
        return (auction.seller, auction.price);
    }

    function createAuction(uint256 _artworkId, uint256 _price, address _originalOwner) external whenNotPaused {
        require(msg.sender == address(artworkContract));

         
        _takeOwnership(_originalOwner, _artworkId);

        Auction memory auction;

        auction.seller = _originalOwner;
        auction.price = _price;

        _createAuction(_artworkId, auction);
    }

    function _createAuction(uint256 _artworkId, Auction _auction) internal {
        artworkIdToAuction[_artworkId] = _auction;
        AuctionCreated(_artworkId, _auction.price);
    }

    function cancelAuction(uint256 _artworkId) external {
        require(_isAuctionExist(_artworkId));
        Auction storage auction = artworkIdToAuction[_artworkId];
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_artworkId, seller);
    }

    function _cancelAuction(uint256 _artworkId, address _owner) internal {
        delete artworkIdToAuction[_artworkId];
        artworkContract.transfer(_owner, _artworkId);
        AuctionCancelled(_artworkId);
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(this.balance);
    }

     
    function cancelAuctionEmergency(uint256 _artworkId) external whenPaused onlyOwner {
        require(_isAuctionExist(_artworkId));
        Auction storage auction = artworkIdToAuction[_artworkId];
        _cancelAuction(_artworkId, auction.seller);
    }

     

    function _isAuctionExist(uint256 _artworkId) internal view returns(bool) {
        return artworkIdToAuction[_artworkId].seller != address(0);
    }

    function _owns(address _address, uint256 _artworkId) internal view returns(bool) {
        return artworkContract.ownerOf(_artworkId) == _address;
    }

    function _takeOwnership(address _originalOwner, uint256 _artworkId) internal {
        artworkContract.transferFrom(_originalOwner, this, _artworkId);
    }
}

contract Presale is OwnableSimple, RandomApi, ERC721 {
    using strings for *;

     
     
     
    uint256 public batchCount;
    mapping(uint256 => uint256) public prices;
    mapping(uint256 => uint256) public supplies;
    mapping(uint256 => uint256) public sold;

     
     
     
     
     
     
    mapping(uint256 => bool) public isTransferDisabled;

    uint256[] public dnas;
    mapping(address => uint256) public ownerToTokenCount;
    mapping (uint256 => address) public artworkIdToOwner;
    mapping (uint256 => address) public artworkIdToTransferApproved;

    PresaleMarket public presaleMarket;

    bytes4 constant ERC165Signature_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));

     
    bytes4 constant ERC165Signature_ERC721A =
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));

     
     
    bytes4 constant ERC165Signature_ERC721B =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('takeOwnership(uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
    bytes4(keccak256('tokenMetadata(uint256)'));

    function Presale() public {
         
         
         
         

         
         
         
         
         

         
         
         
         
         

         
         
         
         

         
         
         

         
         
         
         
         

         
        _addPresale(0.05 ether, 450);

         
        _addPresale(0.12 ether, 325);

         
        _addPresale(0.35 ether, 150);

         
        _addPresale(1.0 ether, 75);
    }

    function buy(uint256 _batch) public payable {
        require(_batch < batchCount);
        require(msg.value == prices[_batch]);  
        require(sold[_batch] < supplies[_batch]);

        sold[_batch]++;
        uint256 dna = _generateRandomDna(_batch);

        uint256 artworkId = dnas.push(dna) - 1;
        ownerToTokenCount[msg.sender]++;
        artworkIdToOwner[artworkId] = msg.sender;

        Transfer(0, msg.sender, artworkId);
    }

    function getArtworkInfo(uint256 _id) external view returns (
        uint256 dna, address owner) {
        require(_id < totalSupply());

        dna = dnas[_id];
        owner = artworkIdToOwner[_id];
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(this.balance);
    }

    function getBatchInfo(uint256 _batch) external view returns(uint256 price, uint256 supply, uint256 soldAmount) {
        require(_batch < batchCount);

        return (prices[_batch], supplies[_batch], sold[_batch]);
    }

    function setTransferDisabled(uint256 _batch, bool _isDisabled) external onlyOwner {
        require(_batch < batchCount);

        isTransferDisabled[_batch] = _isDisabled;
    }

    function setPresaleMarketAddress(address _address) public onlyOwner {
        PresaleMarket presaleMarketTest = PresaleMarket(_address);
        require(presaleMarketTest.isPresaleMarket());
        presaleMarket = presaleMarketTest;
    }

    function sell(uint256 _artworkId, uint256 _price) external {
        require(_isOwnerOf(msg.sender, _artworkId));
        require(_canTransferBatch(_artworkId));
        _approveTransfer(_artworkId, presaleMarket);
        presaleMarket.createAuction(_artworkId, _price, msg.sender);
    }

     

    function _addPresale(uint256 _price, uint256 _supply) private {
        prices[batchCount] = _price;
        supplies[batchCount] = _supply;

        batchCount++;
    }

    function _generateRandomDna(uint256 _batch) private returns(uint256 dna) {
        uint256 rand = random256() % (10 ** 76);

         
        rand = rand / 100000000 * 100000000 + _batch;

        return rand;
    }

    function _isOwnerOf(address _address, uint256 _tokenId) private view returns (bool) {
        return artworkIdToOwner[_tokenId] == _address;
    }

    function _approveTransfer(uint256 _tokenId, address _address) internal {
        artworkIdToTransferApproved[_tokenId] = _address;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        artworkIdToOwner[_tokenId] = _to;
        ownerToTokenCount[_to]++;

        ownerToTokenCount[_from]--;
        delete artworkIdToTransferApproved[_tokenId];

        Transfer(_from, _to, _tokenId);
    }

    function _approvedForTransfer(address _address, uint256 _tokenId) internal view returns (bool) {
        return artworkIdToTransferApproved[_tokenId] == _address;
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(_isOwnerOf(_from, _tokenId));
        require(_approvedForTransfer(msg.sender, _tokenId));

         
        require(_to != address(0));
        require(_to != address(this));

         
        _transfer(_from, _to, _tokenId);
    }

    function _canTransferBatch(uint256 _tokenId) internal view returns(bool) {
        uint256 batch = dnas[_tokenId] % 10;
        return !isTransferDisabled[batch];
    }

    function _tokenMetadata(uint256 _tokenId, string _preferredTransport) internal view returns (string infoUrl) {
        _preferredTransport;  

        require(_tokenId < totalSupply());

        strings.slice memory tokenIdSlice = _uintToBytes(_tokenId).toSliceB32();
        return "/http/etherwaifu.com/presale/artwork/".toSlice().concat(tokenIdSlice);
    }

     
     
     
    function _uintToBytes(uint256 v) internal pure returns(bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint256(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

     

    function totalSupply() public view returns (uint256) {
        return dnas.length;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return ownerToTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address theOwner = artworkIdToOwner[_tokenId];
        require(theOwner != address(0));
        return theOwner;
    }

    function approve(address _to, uint256 _tokenId) external {
        require(_canTransferBatch(_tokenId));

        require(_isOwnerOf(msg.sender, _tokenId));

         
         
         

        require(msg.sender != _to);

        address prevApprovedAddress = artworkIdToTransferApproved[_tokenId];
        _approveTransfer(_tokenId, _to);

         
         
        if(!(prevApprovedAddress == address(0) && _to == address(0))) {
            Approval(msg.sender, _to, _tokenId);
        }
    }

    function transfer(address _to, uint256 _tokenId) external {
        require(_canTransferBatch(_tokenId));
        require(_isOwnerOf(msg.sender, _tokenId));

         
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(presaleMarket));

         
        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(_canTransferBatch(_tokenId));
        _transferFrom(_from, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) external {
        require(_canTransferBatch(_tokenId));
        address owner = artworkIdToOwner[_tokenId];
        _transferFrom(owner, msg.sender, _tokenId);
    }

     

    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds) {
        uint256 count = balanceOf(_owner);

        uint256[] memory res = new uint256[](count);
        uint256 allArtworkCount = totalSupply();
        uint256 i = 0;

        for(uint256 artworkId = 1; artworkId <= allArtworkCount && i < count; artworkId++) {
            if(artworkIdToOwner[artworkId] == _owner) {
                res[i++] = artworkId;
            }
        }

        return res;
    }

    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        return _tokenMetadata(_tokenId, _preferredTransport);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId) {
        require(_index < balanceOf(_owner));

         
         
        uint256 allArtworkCount = totalSupply();

        uint256 i = 0;
        for(uint256 artworkId = 0; artworkId < allArtworkCount; artworkId++) {
            if(artworkIdToOwner[artworkId] == _owner) {
                if(i == _index) {
                    return artworkId;
                } else {
                    i++;
                }
            }
        }
        assert(false);  
    }

    function tokenMetadata(uint256 _tokenId) external view returns (string infoUrl) {
        return _tokenMetadata(_tokenId, "http");
    }

     

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return _interfaceID == ERC165Signature_ERC165 ||
        _interfaceID == ERC165Signature_ERC721A ||
        _interfaceID == ERC165Signature_ERC721B;
    }
}