 

pragma solidity ^0.4.14;
 
contract Ownable {
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

   
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

 
 
contract ERC721 {
     
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external view returns (address owner);
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     
}

 
 
contract ERC721Metadata {
     
    function getMetadata(uint256 _tokenId, string) public pure returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
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

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) internal tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
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
            uint256(_auction.duration),
            uint256(_auction.startedAt)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount) internal returns (uint256) {
         
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

 
 
contract ClockAuction is Ownable, ClockAuctionBase {

     
     
     
    bytes4 public constant  INTERFACE_SIGNATURE_ERC721 = bytes4(0x9a20483d);

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
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

     
     
    function getAuction(uint256 _tokenId) external view returns (
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

     
    uint256 public artworkSaleCount;
    uint256[5] public lastArtworkSalePrices;
    uint256 internal value;

     
    function SaleClockAuction(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

     
     
     
     
     
     
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
         
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

         
        if (seller == address(nonFungibleContract)) {
             
            lastArtworkSalePrices[artworkSaleCount % 5] = price;
            value += price;
            artworkSaleCount++;
        }
    }

    function averageArtworkSalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastArtworkSalePrices[i];
        }
        return sum / 5;
    }

    function getValue() external view returns (uint256) {
        return value;
    }

}


contract ArtworkAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
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

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}


 
 
contract ArtworkBase is ArtworkAccessControl {
     

     
     
     
    event Birth(address owner, uint256 artworkId, string name, string author, uint32 series);

     
     
    event Transfer(address from, address to, uint256 tokenId);

     
     
     
     
     
     
    struct Artwork {
          
        uint64 birthTime;
         
        string name;
        string author;
         
         
         
        uint32 series;
    }

     
     
     
     
     
     
    Artwork[] internal artworks;
     
     
    mapping (uint256 => address) public artworkIndexToOwner;

     
     
    mapping (address => uint256) internal ownershipTokenCount;

     
     
     
    mapping (uint256 => address) public artworkIndexToApproved;


     
     
     
    SaleClockAuction public saleAuction;

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownershipTokenCount[_to]++;
         
        artworkIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete artworkIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
          
    uint64 internal birthTime;
    string internal author;
     
    string internal name;
    uint32 internal series;

    function _createArtwork(string _name, string _author, uint32 _series, address _owner ) internal returns (uint) {
        Artwork memory _artwork = Artwork({ birthTime: uint64(now), name: _name, author: _author, series: _series});
        uint256 newArtworkId = artworks.push(_artwork) - 1;

         
         
        require(newArtworkId == uint256(uint32(newArtworkId)));

         
        Birth(_owner, newArtworkId, _artwork.name, _artwork.author, _series);

         
         
        _transfer(0, _owner, newArtworkId);

        return newArtworkId;
    }

}


     
     
contract ArtworkUnique {

     
    mapping  (bytes32 => bool) internal uniqueArtworks;
    
     
    function getUniqueKey(string name, string author, uint32 _version)  internal pure returns(bytes32) {
        string memory version = _uintToString(_version);
        string memory main = _strConcat(name, author, version, "$%)");
        string memory lowercased = _toLower(main);
        return keccak256(lowercased);
    }
    
     
     
    function _toLower(string str) internal pure returns (string)  {
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			 
			if ((bStr[i] >= 65) && (bStr[i] <= 90)) {
				 
				bLower[i] = bytes1(int(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}
	
     
    function _strConcat(string _a, string _b, string _c, string _separator) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_separator);
        bytes memory _bc = bytes(_b);
        bytes memory _bd = bytes(_separator);
        bytes memory _be = bytes(_c);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

     
    function _uintToString(uint v) internal pure returns (string) {
        bytes32 data = _uintToBytes(v);
        return _bytes32ToString(data);
    }

     
     
     
    function _uintToBytes(uint v) private pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function _bytes32ToString(bytes32 x) private pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}


 
 
 
contract ArtworkOwnership is ArtworkBase, ArtworkUnique, ERC721 {

     
    string public constant NAME = "CryptoArtworks";
    string public constant SYMBOL = "CA";

     
    ERC721Metadata public erc721Metadata;

    bytes4 private constant INTERFACE_SIGNATURE_ERC165 =
    bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 private constant INTERFACE_SIGNATURE_ERC721 =
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

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
    function transfer(address _to, uint256 _tokenId) external whenNotPaused {

         
        require(_to != address(0));

         
         
         
        require(_to != address(this));

         
         
         
        require(_to != address(saleAuction));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);

    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalArts = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 artworkId;

            for (artworkId = 1; artworkId <= totalArts; artworkId++) {
                if (artworkIndexToOwner[artworkId] == _owner) {
                    result[resultIndex] = artworkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
         
         

        return ((_interfaceID == INTERFACE_SIGNATURE_ERC165) || (_interfaceID == INTERFACE_SIGNATURE_ERC721));
    }

     
     
     
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }

     
     
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = artworkIndexToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

     
     
    function totalSupply() public view returns (uint) {
        return artworks.length - 1;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return artworkIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return artworkIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        artworkIndexToApproved[_tokenId] = _approved;
    }

     
     
     
    function _memcpy(uint _dest, uint _src, uint _len) private view {
         
        for (; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

         
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

     
     
     
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }
}


 
 
 
contract ArtworkAuction is ArtworkOwnership {

     
     
     


     
     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }

     
     
    function createSaleAuction(
        uint256 _artworkId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _artworkId));
        _approve(_artworkId, saleAuction);
         
         
        saleAuction.createAuction(
            _artworkId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
    }
}


 
contract ArtworkMinting is ArtworkAuction {

     
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant CREATION_LIMIT = 450000;

     
    uint256 public constant ARTWORK_STARTING_PRICE = 10 finney;
    uint256 public constant ARTWORK_AUCTION_DURATION = 1 days;

     
    uint256 public promoCreatedCount;
    uint256 public artsCreatedCount;

     
     
    function createPromoArtwork(string _name, string _author, uint32 _series, address _owner) external onlyCOO {
        bytes32 uniqueKey = getUniqueKey(_name, _author, _series);
        (require(!uniqueArtworks[uniqueKey]));
        if (_series != 0) {
            bytes32 uniqueKeyForZero = getUniqueKey(_name, _author, 0);
            (require(!uniqueArtworks[uniqueKeyForZero]));
        }
        address artworkOwner = _owner;
        if (artworkOwner == address(0)) {
            artworkOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createArtwork(_name, _author, _series, artworkOwner);
        uniqueArtworks[uniqueKey] = true;
    }

     
     
    function createArtworkAuction(string _name, string _author, uint32 _series) external onlyCOO {
        bytes32 uniqueKey = getUniqueKey(_name, _author, _series);
        (require(!uniqueArtworks[uniqueKey]));
        require(artsCreatedCount < CREATION_LIMIT);
        if (_series != 0) {
            bytes32 uniqueKeyForZero = getUniqueKey(_name, _author, 0);
            (require(!uniqueArtworks[uniqueKeyForZero]));
        }
        uint256 artworkId = _createArtwork(_name, _author, _series, address(this));
        _approve(artworkId, saleAuction);
        uint256 price = _computeNextArtworkPrice();
        saleAuction.createAuction(
            artworkId,
            price,
            0,
            ARTWORK_AUCTION_DURATION,
            address(this)
        );
        artsCreatedCount++;
        uniqueArtworks[uniqueKey] = true;
    }

     
     
    function _computeNextArtworkPrice() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageArtworkSalePrice();

         
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

         
        if (nextPrice < ARTWORK_STARTING_PRICE) {
            nextPrice = ARTWORK_STARTING_PRICE;
        }

        return nextPrice;
    }
}


 
contract ArtworkQuestions is ArtworkMinting {
    string private constant QUESTION  = "What is the value? Nothing is ";
    string public constant MAIN_QUESTION = "What is a masterpiece? ";
    
    function getQuestion() public view returns (string) {
        uint256 value = saleAuction.getValue();
        string memory auctionValue = _uintToString(value);
        return _strConcat(QUESTION, auctionValue, "", "");
    }
}


 
 
 
contract ArtworkCore is ArtworkQuestions {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

     
    function ArtworkCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
        _createArtwork("none", "none", 0, address(0));
    }

     
     
     
    function() external payable {
        require(
            msg.sender == address(saleAuction)
        );
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        cfoAddress.send(balance);
    }

     
     
    function getArtwork(uint256 _id)
        external
        view
        returns (
        uint256 birthTime,
        string name,
        string author,
        uint32 series
    ) {
        Artwork storage art = artworks[_id];
        birthTime = uint256(art.birthTime);
        name = string(art.name);
        author = string(art.author);
        series = uint32(art.series);
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(newContractAddress == address(0));
         
        super.unpause();
    }

}