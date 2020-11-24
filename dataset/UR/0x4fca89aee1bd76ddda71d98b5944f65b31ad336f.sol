 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;


 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

 

pragma solidity ^0.5.0;


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

pragma solidity ^0.5.0;




 
contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
     
}

 

pragma solidity 0.5.0;


contract IMarketplace {
    function createAuction(
        uint256 _tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint128 duration
    )
        external;
}

 

pragma solidity 0.5.0;






contract AnimalMarketplace is Ownable, IMarketplace {
    using SafeMath for uint256;
    uint8 internal percentFee = 5;

    IERC721Full private erc721Contract;

    struct Auction {
        address payable tokenOwner;
        uint256 startTime;
        uint128 startPrice;
        uint128 endPrice;
        uint128 duration;
    }

    struct AuctionEntry {
        uint256 keyIndex;
        Auction value;
    }

    struct TokenIdAuctionMap {
        mapping(uint256 => AuctionEntry) data;
        uint256[] keys;
    }

    TokenIdAuctionMap private auctions;

    event AuctionBoughtEvent(
        uint256 tokenId,
        address previousOwner,
        address newOwner,
        uint256 pricePaid
    );

    event AuctionCreatedEvent(
        uint256 tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint128 duration
    );

    event AuctionCanceledEvent(uint256 tokenId);

    constructor(IERC721Full _erc721Contract) public {
        erc721Contract = _erc721Contract;
    }

     
    function createAuction(
        uint256 _tokenId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint128 _duration
    )
        external
    {
         
        require(msg.sender == address(erc721Contract));

        AuctionEntry storage entry = auctions.data[_tokenId];
        require(entry.keyIndex == 0);

        address payable tokenOwner = address(uint160(erc721Contract.ownerOf(_tokenId)));
        erc721Contract.transferFrom(tokenOwner, address(this), _tokenId);

        entry.value = Auction({
            tokenOwner: tokenOwner,
            startTime: block.timestamp,
            startPrice: _startPrice,
            endPrice: _endPrice,
            duration: _duration
        });

        entry.keyIndex = ++auctions.keys.length;
        auctions.keys[entry.keyIndex - 1] = _tokenId;

        emit AuctionCreatedEvent(_tokenId, _startPrice, _endPrice, _duration);
    }

    function cancelAuction(uint256 _tokenId) external {
        AuctionEntry storage entry = auctions.data[_tokenId];
        Auction storage auction = entry.value;
        address sender = msg.sender;
        require(sender == auction.tokenOwner);
        erc721Contract.transferFrom(address(this), sender, _tokenId);
        deleteAuction(_tokenId, entry);
        emit AuctionCanceledEvent(_tokenId);
    }

    function buyAuction(uint256 _tokenId)
        external
        payable
    {
        AuctionEntry storage entry = auctions.data[_tokenId];
        require(entry.keyIndex > 0);
        Auction storage auction = entry.value;
        address payable sender = msg.sender;
        address payable tokenOwner = auction.tokenOwner;
        uint256 auctionPrice = calculateCurrentPrice(auction);
        uint256 pricePaid = msg.value;

        require(pricePaid >= auctionPrice);
        deleteAuction(_tokenId, entry);

        refundSender(sender, pricePaid, auctionPrice);
        payTokenOwner(tokenOwner, auctionPrice);
        erc721Contract.transferFrom(address(this), sender, _tokenId);
        emit AuctionBoughtEvent(_tokenId, tokenOwner, sender, auctionPrice);
    }

    function getAuctionByTokenId(uint256 _tokenId)
        external
        view
        returns (
            uint256 tokenId,
            address tokenOwner,
            uint128 startPrice,
            uint128 endPrice,
            uint256 startTime,
            uint128 duration,
            uint256 currentPrice,
            bool exists
        )
    {
        AuctionEntry storage entry = auctions.data[_tokenId];
        Auction storage auction = entry.value;
        uint256 calculatedCurrentPrice = calculateCurrentPrice(auction);
        return (
            entry.keyIndex > 0 ? _tokenId : 0,
            auction.tokenOwner,
            auction.startPrice,
            auction.endPrice,
            auction.startTime,
            auction.duration,
            calculatedCurrentPrice,
            entry.keyIndex > 0
        );
    }

    function getAuctionByIndex(uint256 _auctionIndex)
        external
        view
        returns (
            uint256 tokenId,
            address tokenOwner,
            uint128 startPrice,
            uint128 endPrice,
            uint256 startTime,
            uint128 duration,
            uint256 currentPrice,
            bool exists
        )
    {
         
        if (_auctionIndex >= auctions.keys.length) {
            return (0, address(0), 0, 0, 0, 0, 0, false);
        }

        uint256 currentTokenId = auctions.keys[_auctionIndex];
        Auction storage auction = auctions.data[currentTokenId].value;
        uint256 calculatedCurrentPrice = calculateCurrentPrice(auction);
        return (
            currentTokenId,
            auction.tokenOwner,
            auction.startPrice,
            auction.endPrice,
            auction.startTime,
            auction.duration,
            calculatedCurrentPrice,
            true
        );
    }

    function getAuctionsCount() external view returns (uint256 auctionsCount) {
        return auctions.keys.length;
    }

    function isOnAuction(uint256 _tokenId) public view returns (bool onAuction) {
        return auctions.data[_tokenId].keyIndex > 0;
    }

    function withdrawContract() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function refundSender(address payable _sender, uint256 _pricePaid, uint256 _auctionPrice) private {
        uint256 etherToRefund = _pricePaid.sub(_auctionPrice);
        if (etherToRefund > 0) {
            _sender.transfer(etherToRefund);
        }
    }

    function payTokenOwner(address payable _tokenOwner, uint256 _auctionPrice) private {
        uint256 etherToPay = _auctionPrice.sub(_auctionPrice * percentFee / 100);
        if (etherToPay > 0) {
            _tokenOwner.transfer(etherToPay);
        }
    }

    function deleteAuction(uint256 _tokenId, AuctionEntry storage _entry) private {
        uint256 keysLength = auctions.keys.length;
        if (_entry.keyIndex <= keysLength) {
             
            auctions.data[auctions.keys[keysLength - 1]].keyIndex = _entry.keyIndex;
            auctions.keys[_entry.keyIndex - 1] = auctions.keys[keysLength - 1];
            auctions.keys.length = keysLength - 1;
            delete auctions.data[_tokenId];
        }
    }

    function calculateCurrentPrice(Auction storage _auction) private view returns (uint256) {
        uint256 secondsInProgress = block.timestamp - _auction.startTime;

        if (secondsInProgress >= _auction.duration) {
            return _auction.endPrice;
        }

        int256 totalPriceChange = int256(_auction.endPrice) - int256(_auction.startPrice);
        int256 currentPriceChange =
            totalPriceChange * int256(secondsInProgress) / int256(_auction.duration);

        int256 calculatedPrice = int256(_auction.startPrice) + int256(currentPriceChange);

        return uint256(calculatedPrice);
    }

}