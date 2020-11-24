 

pragma solidity ^0.4.24;
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
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}
contract ListingsERC20 is Ownable {
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

    string constant public VERSION = "2.0.0";
    uint16 constant public GAS_LIMIT = 4999;
    uint256 public ownerPercentage;
    mapping (bytes32 => Listing) public listings;
    mapping (bytes32 => uint256) public sold;
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
        assert(DetailedERC20(token).approve(owner, amount));
    }

    function() external payable { }

    function getHash(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) external view returns (bytes32) {
        return getHashInternal(tokenContractAddress, price, allowance, dateEnds, salt);
    }

    function getHashInternal(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, tokenContractAddress, price, allowance, dateEnds, salt));
    }
    function getBalance(address tokenContract, address seller) internal returns (uint256) {
        return DetailedERC20(tokenContract).balanceOf.gas(GAS_LIMIT)(seller);
    }
    function getAllowance(address tokenContract, address seller, address listingContract) internal returns (uint256) {
        return DetailedERC20(tokenContract).allowance.gas(GAS_LIMIT)(seller, listingContract);
    }
    function getDecimals(address tokenContract) internal returns (uint256) {
        return DetailedERC20(tokenContract).decimals.gas(GAS_LIMIT)();
    }

    function createListing(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) external {
        require(price > 0, "price less than zero");
        require(allowance > 0, "allowance less than zero");
        require(dateEnds > 0, "dateEnds less than zero");
        require(getBalance(tokenContractAddress, msg.sender) >= allowance, "balance less than allowance");
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
        uint256 decimals = getDecimals(listing.tokenContractAddress);
        uint256 factor = 10 ** decimals;
        uint256 sale;
        if (decimals > 0) {
            sale = price.mul(amount).div(factor);
        } else {
            sale = price.mul(amount);
        } 
        uint256 allowance = listing.allowance;
         
        require(now <= listing.dateEnds);
         
        require(allowance - sold[listingId] >= amount);
         
        require(getBalance(contractAddress, seller) >= amount);
         
        require(getAllowance(contractAddress, seller, this) >= amount);
        require(msg.value == sale);
        DetailedERC20 tokenContract = DetailedERC20(contractAddress);
        require(tokenContract.transferFrom(seller, msg.sender, amount));
        if (ownerPercentage > 0) {
            seller.transfer(sale - (sale.mul(ownerPercentage).div(10000)));
        } else {
            seller.transfer(sale);
        }
        sold[listingId] = sold[listingId].add(amount);
        emit ListingBought(listingId, contractAddress, price, amount, now, msg.sender);
    }

}