 

pragma solidity 0.4.21;

 

 
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

 

 
contract ERC20Interface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

 
contract ERC721Interface {
    function ownerOf(uint256 assetId) public view returns (address);
    function safeTransferFrom(address from, address to, uint256 assetId) public;
    function isAuthorized(address operator, uint256 assetId) public view returns (bool);
}

contract Marketplace is Ownable {
    using SafeMath for uint256;

    ERC20Interface public acceptedToken;
    ERC721Interface public nonFungibleRegistry;

    struct Auction {
         
        bytes32 id;
         
        address seller;
         
        uint256 price;
         
        uint256 expiresAt;
    }

    mapping (uint256 => Auction) public auctionByAssetId;

    uint256 public ownerCutPercentage;
    uint256 public publicationFeeInWei;

     
    event AuctionCreated(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller, 
        uint256 priceInWei, 
        uint256 expiresAt
    );
    event AuctionSuccessful(
        bytes32 id,
        uint256 indexed assetId, 
        address indexed seller, 
        uint256 totalPrice, 
        address indexed winner
    );
    event AuctionCancelled(
        bytes32 id,
        uint256 indexed assetId, 
        address indexed seller
    );

    event ChangedPublicationFee(uint256 publicationFee);
    event ChangedOwnerCut(uint256 ownerCut);


     
    function Marketplace(address _acceptedToken, address _nonFungibleRegistry) public {
        acceptedToken = ERC20Interface(_acceptedToken);
        nonFungibleRegistry = ERC721Interface(_nonFungibleRegistry);
    }

     
    function setPublicationFee(uint256 publicationFee) onlyOwner public {
        publicationFeeInWei = publicationFee;

        ChangedPublicationFee(publicationFeeInWei);
    }

     
    function setOwnerCut(uint8 ownerCut) onlyOwner public {
        require(ownerCut < 100);

        ownerCutPercentage = ownerCut;

        ChangedOwnerCut(ownerCutPercentage);
    }

     
    function createOrder(uint256 assetId, uint256 priceInWei, uint256 expiresAt) public {
        address assetOwner = nonFungibleRegistry.ownerOf(assetId);
        require(msg.sender == assetOwner);
        require(nonFungibleRegistry.isAuthorized(address(this), assetId));
        require(priceInWei > 0);
        require(expiresAt > now.add(1 minutes));

        bytes32 auctionId = keccak256(
            block.timestamp, 
            assetOwner,
            assetId, 
            priceInWei
        );

        auctionByAssetId[assetId] = Auction({
            id: auctionId,
            seller: assetOwner,
            price: priceInWei,
            expiresAt: expiresAt
        });

         
         
        if (publicationFeeInWei > 0) {
            require(acceptedToken.transferFrom(
                msg.sender,
                owner,
                publicationFeeInWei
            ));
        }

        AuctionCreated(
            auctionId,
            assetId, 
            assetOwner,
            priceInWei, 
            expiresAt
        );
    }

     
    function cancelOrder(uint256 assetId) public {
        require(auctionByAssetId[assetId].seller == msg.sender || msg.sender == owner);

        bytes32 auctionId = auctionByAssetId[assetId].id;
        address auctionSeller = auctionByAssetId[assetId].seller;
        delete auctionByAssetId[assetId];

        AuctionCancelled(auctionId, assetId, auctionSeller);
    }

     
    function executeOrder(uint256 assetId, uint256 price) public {
        address seller = auctionByAssetId[assetId].seller;

        require(seller != address(0));
        require(seller != msg.sender);
        require(auctionByAssetId[assetId].price == price);
        require(now < auctionByAssetId[assetId].expiresAt);

        require(seller == nonFungibleRegistry.ownerOf(assetId));

        uint saleShareAmount = 0;

        if (ownerCutPercentage > 0) {

             
            saleShareAmount = price.mul(ownerCutPercentage).div(100);

             
            acceptedToken.transferFrom(
                msg.sender,
                owner,
                saleShareAmount
            );
        }

         
        acceptedToken.transferFrom(
            msg.sender,
            seller,
            price.sub(saleShareAmount)
        );

         
        nonFungibleRegistry.safeTransferFrom(
            seller,
            msg.sender,
            assetId
        );


        bytes32 auctionId = auctionByAssetId[assetId].id;
        delete auctionByAssetId[assetId];

        AuctionSuccessful(auctionId, assetId, seller, price, msg.sender);
    }
 }