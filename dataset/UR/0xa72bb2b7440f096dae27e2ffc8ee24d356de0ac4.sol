 

pragma solidity ^0.4.24;

contract ERC165Interface {
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC165 is ERC165Interface {
     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 
 
contract ERC721Basic is ERC165 {
     

     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    function balanceOf(address _owner) public view returns (uint256);

     
    function ownerOf(uint256 _tokenId) public view returns (address);

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

     
    function approve(address _approved, uint256 _tokenId) external;

     
    function setApprovalForAll(address _operator, bool _approved) external;

     
    function getApproved(uint256 _tokenId) public view returns (address);

     
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

     

     
     
    
     

     
    function name() external view returns (string _name);

     
    function symbol() external view returns (string _symbol);

     
    function tokenURI(uint256 _tokenId) external view returns (string);

     
     

     

     
    function totalSupply() public view returns (uint256);
}

 
contract ERC721TokenReceiver {
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns (bytes4);
}

 

contract ERC721Holder is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

 
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

 
contract AuctionBase is ERC721Holder {
    using SafeMath for uint256;

     
    struct Auction {
         
        address seller;
         
        uint128 price;
         
         
        uint64 startedAt;
    }

     
    ERC721Basic public nonFungibleContract;

     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 price);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address bidder);
    event AuctionCanceled(uint256 tokenId);

     
    function() external {}

     
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= (2**64 - 1));
        _;
    }

     
    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value <= (2**128 - 1));
        _;
    }

     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(_owner, this, _tokenId);
    }

     
    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(this, _receiver, _tokenId);
    }

     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.price)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCanceled(_tokenId);
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
            uint256 sellerProceeds = price.sub(auctioneerCut);

            seller.transfer(sellerProceeds);
        }

         
        uint256 bidExcess = _bidAmount - price;

         
        msg.sender.transfer(bidExcess);

         
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
        return _auction.price;
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

 
contract Auction is Pausable, AuctionBase {

     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(address(this).balance);
    }

     
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        whenNotPaused
        canBeStoredWith128Bits(_price)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
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

     
    function cancelAuction(uint256 _tokenId, address _seller)
        external
    {
         
         
         
         
        require(msg.sender == address(nonFungibleContract));
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(_seller == seller);
        _cancelAuction(_tokenId, seller);
    }

     
    function cancelAuctionForOwner(uint256 _tokenId)
        external
        onlyOwner
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
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
        uint256 price,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.price,
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

 
contract SaleAuction is Auction {

     
    bool public isSaleAuction = true;

     
    uint256[5] public lastGen0SalePrices;
    
     
    uint256 public gen0SaleCount;

     
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        nonFungibleContract = candidateContract;
    }

     
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        canBeStoredWith128Bits(_price)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
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

         
         
         
        if (seller == address(nonFungibleContract) || seller == owner) {
             
             
            for (uint256 i = 0; i < 5; i++) {
                if (lastGen0SalePrices[i] == 0) {
                    lastGen0SalePrices[i] = 175 finney;
                }
            }
             
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }
     
    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum = sum.add(lastGen0SalePrices[i]);
        }
        return (sum / 5) * 685 / 1000;
    }
}