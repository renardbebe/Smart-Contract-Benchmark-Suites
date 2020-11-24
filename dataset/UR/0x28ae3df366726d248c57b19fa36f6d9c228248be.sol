 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
pragma solidity ^0.4.24;



 
contract Beneficiary is Ownable {
    address public beneficiary;

    constructor() public {
        beneficiary = msg.sender;
    }

     
    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }
}

 

 
pragma solidity ^0.4.25;



 
contract Affiliate is Ownable {
    mapping(address => bool) public canSetAffiliate;
    mapping(address => address) public userToAffiliate;

     
    function setAffiliateSetter(address _setter) public onlyOwner {
        canSetAffiliate[_setter] = true;
    }

     
    function setAffiliate(address _user, address _affiliate) public {
        require(canSetAffiliate[msg.sender]);
        if (userToAffiliate[_user] == address(0)) {
            userToAffiliate[_user] = _affiliate;
        }
    }

}

 

contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool) ;
    function transfer(address _to, uint256 _tokenId) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
     
     
     
     
}

 

contract PepeInterface is ERC721{
    function cozyTime(uint256 _mother, uint256 _father, address _pepeReceiver) public returns (bool);
    function getCozyAgain(uint256 _pepeId) public view returns(uint64);
}

 

 
pragma solidity ^0.4.24;





 
contract AuctionBase is Beneficiary {
    mapping(uint256 => PepeAuction) public auctions; 
    PepeInterface public pepeContract;
    Affiliate public affiliateContract;
    uint256 public fee = 37500;  
    uint256 public constant FEE_DIVIDER = 1000000;  

    struct PepeAuction {
        address seller;
        uint256 pepeId;
        uint64 auctionBegin;
        uint64 auctionEnd;
        uint256 beginPrice;
        uint256 endPrice;
    }

    event AuctionWon(uint256 indexed pepe, address indexed winner, address indexed seller);
    event AuctionStarted(uint256 indexed pepe, address indexed seller);
    event AuctionFinalized(uint256 indexed pepe, address indexed seller);

    constructor(address _pepeContract, address _affiliateContract) public {
        pepeContract = PepeInterface(_pepeContract);
        affiliateContract = Affiliate(_affiliateContract);
    }

     
    function savePepe(uint256 _pepeId) external {
         
        require(auctions[_pepeId].auctionEnd < now); 
        require(pepeContract.transfer(auctions[_pepeId].seller, _pepeId)); 

        emit AuctionFinalized(_pepeId, auctions[_pepeId].seller);

        delete auctions[_pepeId]; 
    }

     
    function changeFee(uint256 _fee) external onlyOwner {
        require(_fee < fee); 
        fee = _fee;
    }

     
    function startAuction(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public {
        require(pepeContract.transferFrom(msg.sender, address(this), _pepeId));
         
        require(now > auctions[_pepeId].auctionEnd); 

        PepeAuction memory auction;

        auction.seller = msg.sender;
        auction.pepeId = _pepeId;
         
        auction.auctionBegin = uint64(now);
         
        auction.auctionEnd = uint64(now) + _duration;
        require(auction.auctionEnd > auction.auctionBegin);
        auction.beginPrice = _beginPrice;
        auction.endPrice = _endPrice;

        auctions[_pepeId] = auction;

        emit AuctionStarted(_pepeId, msg.sender);
    }

     
     
    function startAuctionDirect(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration, address _seller) public {
        require(msg.sender == address(pepeContract));  
         
        require(now > auctions[_pepeId].auctionEnd); 

        PepeAuction memory auction;

        auction.seller = _seller;
        auction.pepeId = _pepeId;
         
        auction.auctionBegin = uint64(now);
         
        auction.auctionEnd = uint64(now) + _duration;
        require(auction.auctionEnd > auction.auctionBegin);
        auction.beginPrice = _beginPrice;
        auction.endPrice = _endPrice;

        auctions[_pepeId] = auction;

        emit AuctionStarted(_pepeId, _seller);
    }

   
    function calculateBid(uint256 _pepeId) public view returns(uint256 currentBid) {
        PepeAuction storage auction = auctions[_pepeId];
         
        uint256 timePassed = now - auctions[_pepeId].auctionBegin;

         
         
        if (now >= auction.auctionEnd) {
            return auction.endPrice;
        } else {
             
            int256 priceDifference = int256(auction.endPrice) - int256(auction.beginPrice);
             
            int256 duration = int256(auction.auctionEnd) - int256(auction.auctionBegin);

             
             
             
             
            int256 priceChange = priceDifference * int256(timePassed) / duration;

             
            int256 price = int256(auction.beginPrice) + priceChange;

            return uint256(price);
        }
    }

   
    function getFees() public {
        beneficiary.transfer(address(this).balance);
    }


}

 

 
pragma solidity ^0.4.19;



 
 
contract PepeAuctionSale is AuctionBase {
   
    constructor(address _pepeContract, address _affiliateContract) AuctionBase(_pepeContract, _affiliateContract) public {

    }

     
    function buyPepe(uint256 _pepeId) public payable {
        PepeAuction storage auction = auctions[_pepeId];

         
        require(now < auction.auctionEnd); 

        uint256 price = calculateBid(_pepeId);
        require(msg.value >= price);  
        uint256 totalFee = price * fee / FEE_DIVIDER;  

         
        auction.seller.transfer(price - totalFee);
         

         
        if(affiliateContract.userToAffiliate(msg.sender) != address(0) && affiliateContract.userToAffiliate(msg.sender).send(totalFee / 2)) {  
             
        }
         
        if (!pepeContract.transfer(msg.sender, _pepeId)) {
            revert();  
        }

        emit AuctionWon(_pepeId, msg.sender, auction.seller);

        if (msg.value > price) {  
            msg.sender.transfer(msg.value - price);
        }

        delete auctions[_pepeId]; 
    }

     
     
    function buyPepeAffiliated(uint256 _pepeId, address _affiliate) external payable {
        affiliateContract.setAffiliate(msg.sender, _affiliate);
        buyPepe(_pepeId);
    }

}