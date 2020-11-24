 

pragma solidity ^0.4.24;




 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract ERC721Basic {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}


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

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ListingsERC721 is Ownable {
    using SafeMath for uint256;

    struct Listing {
        address seller;
        address tokenContractAddress;
        uint256 price;
        uint256 allowance;
        uint256 dateStarts;
        uint256 dateEnds;
    }
    
    event ListingCreated(bytes32 indexed listingId, address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateStarts, uint256 dateEnds, address indexed seller);
    event ListingCancelled(bytes32 indexed listingId, uint256 dateCancelled);
    event ListingBought(bytes32 indexed listingId, address tokenContractAddress, uint256 price, uint256 amount, uint256 dateBought, address buyer);

    string constant public VERSION = "1.0.1";
    uint16 constant public GAS_LIMIT = 4999;
    uint256 public ownerPercentage;
    mapping (bytes32 => Listing) public listings;

    constructor (uint256 percentage) public {
        ownerPercentage = percentage;
    }

    function updateOwnerPercentage(uint256 percentage) external onlyOwner {
        ownerPercentage = percentage;
    }

    function withdrawBalance() onlyOwner external {
        assert(owner.send(address(this).balance));
    }
    function approveToken(address token, uint256 amount) onlyOwner external {
        assert(ERC20(token).approve(owner, amount));
    }

    function() external payable { }

    function getHash(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) external view returns (bytes32) {
        return getHashInternal(tokenContractAddress, price, allowance, dateEnds, salt);
    }

    function getHashInternal(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, tokenContractAddress, price, allowance, dateEnds, salt));
    }

    function createListing(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) external {
        require(price > 0, "price less than zero");
        require(allowance > 0, "allowance less than zero");
        require(dateEnds > 0, "dateEnds less than zero");
        require(ERC721(tokenContractAddress).ownerOf(allowance) == msg.sender, "user doesn't own this token");
        bytes32 listingId = getHashInternal(tokenContractAddress, price, allowance, dateEnds, salt);
        Listing memory listing = Listing(msg.sender, tokenContractAddress, price, allowance, now, dateEnds);
        listings[listingId] = listing;
        emit ListingCreated(listingId, tokenContractAddress, price, allowance, now, dateEnds, msg.sender);

    }
    function cancelListing(bytes32 listingId) external {
        Listing storage listing = listings[listingId];
        require(msg.sender == listing.seller);
        delete listings[listingId];
        emit ListingCancelled(listingId, now);
    }

    function buyListing(bytes32 listingId, uint256 amount) external payable {
        Listing storage listing = listings[listingId];
        address seller = listing.seller;
        address contractAddress = listing.tokenContractAddress;
        uint256 price = listing.price;
        uint256 tokenId = listing.allowance;
        ERC721 tokenContract = ERC721(contractAddress);
         
        require(now <= listing.dateEnds);
         
        require(tokenContract.ownerOf(tokenId) == seller, "user doesn't own this token");
         
        require(tokenContract.getApproved(tokenId) == address(this));
        require(msg.value == price);
        tokenContract.transferFrom(seller, msg.sender, tokenId);
        if (ownerPercentage > 0) {
            seller.transfer(price - (listing.price.mul(ownerPercentage).div(10000)));
        } else {
            seller.transfer(price);
        }
        emit ListingBought(listingId, contractAddress, price, amount, now, msg.sender);
    }


}