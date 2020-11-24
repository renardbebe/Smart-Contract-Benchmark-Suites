 

pragma solidity ^0.4.18;


 
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






contract Beneficiary is Ownable {

    address public beneficiary;

    function Beneficiary() public {
        beneficiary = msg.sender;
    }

    function setBeneficiary(address _beneficiary) onlyOwner public {
        beneficiary = _beneficiary;
    }


}


 
 

contract ERC721 {

    function implementsERC721() public pure returns (bool);

    function totalSupply() public view returns (uint256 total);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function ownerOf(uint256 _tokenId) public view returns (address owner);

    function approve(address _to, uint256 _tokenId) public;

    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool);

    function transfer(address _to, uint256 _tokenId) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
     
     
     
     
}


contract ERC721Auction is Beneficiary {

    struct Auction {
        address seller;
        uint256 tokenId;
        uint64 auctionBegin;
        uint64 auctionEnd;
        uint256 startPrice;
        uint256 endPrice;
    }

    uint32 public auctionDuration = 7 days;

    ERC721 public ERC721Contract;
    uint256 public fee = 45000;  
    uint256 constant FEE_DIVIDER = 1000000;
    mapping(uint256 => Auction) public auctions;

    event AuctionWon(uint256 indexed tokenId, address indexed winner, address indexed seller, uint256 price);

    event AuctionStarted(uint256 indexed tokenId, address indexed seller);

    event AuctionFinalized(uint256 indexed tokenId, address indexed seller);


    function startAuction(uint256 _tokenId, uint256 _startPrice, uint256 _endPrice) external {
        require(ERC721Contract.transferFrom(msg.sender, address(this), _tokenId));
         
        require(_startPrice <= 10000 ether && _endPrice <= 10000 ether);
        require(_startPrice >= (1 ether / 100) && _endPrice >= (1 ether / 100));

        Auction memory auction;

        auction.seller = msg.sender;
        auction.tokenId = _tokenId;
        auction.auctionBegin = uint64(now);
        auction.auctionEnd = uint64(now + auctionDuration);
        require(auction.auctionEnd > auction.auctionBegin);
        auction.startPrice = _startPrice;
        auction.endPrice = _endPrice;

        auctions[_tokenId] = auction;

        AuctionStarted(_tokenId, msg.sender);
    }


    function buyAuction(uint256 _tokenId) payable external {
        Auction storage auction = auctions[_tokenId];

        uint256 price = calculateBid(_tokenId);
        uint256 totalFee = price * fee / FEE_DIVIDER;  

        require(price <= msg.value);  

        if (price != msg.value) { 
            msg.sender.transfer(msg.value - price);
        }

        beneficiary.transfer(totalFee);

        auction.seller.transfer(price - totalFee);

        if (!ERC721Contract.transfer(msg.sender, _tokenId)) {
            revert();
             
        }

        AuctionWon(_tokenId, msg.sender, auction.seller, price);

        delete auctions[_tokenId];
         
    }

    function saveToken(uint256 _tokenId) external {
        require(auctions[_tokenId].auctionEnd < now);
         
        require(ERC721Contract.transfer(auctions[_tokenId].seller, _tokenId));
         

        AuctionFinalized(_tokenId, auctions[_tokenId].seller);

        delete auctions[_tokenId];
         
    }

    function ERC721Auction(address _ERC721Contract) public {
        ERC721Contract = ERC721(_ERC721Contract);
    }

    function setFee(uint256 _fee) onlyOwner public {
        if (_fee > fee) {
            revert();  
        }
        fee = _fee;  
    }

    function calculateBid(uint256 _tokenId) public view returns (uint256) {
        Auction storage auction = auctions[_tokenId];

        if (now >= auction.auctionEnd) { 
            return auction.endPrice;
        }
         
        uint256 hoursPassed = (now - auction.auctionBegin) / 1 hours;
        uint256 currentPrice;
         
        uint16 totalHours = uint16(auctionDuration /1 hours) - 1;

        if (auction.endPrice > auction.startPrice) {
            currentPrice = auction.startPrice + (hoursPassed * (auction.endPrice - auction.startPrice))/ totalHours;
        } else if(auction.endPrice < auction.startPrice) {
            currentPrice = auction.startPrice - (hoursPassed * (auction.startPrice - auction.endPrice))/ totalHours;
        } else { 
            currentPrice = auction.endPrice;
        }

        return uint256(currentPrice);
         
    }

     
    function returnToken(uint256 _tokenId) onlyOwner public {
        require(ERC721Contract.transfer(auctions[_tokenId].seller, _tokenId));
         

        AuctionFinalized(_tokenId, auctions[_tokenId].seller);

        delete auctions[_tokenId];
    }
}