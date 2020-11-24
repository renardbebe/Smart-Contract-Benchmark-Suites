 

 
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

contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
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

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract ERC721Holder is ERC721Receiver {
  function onERC721Received(address, uint256, bytes) public returns(bytes4) {
    return ERC721_RECEIVED;
  }
}

contract AmmuNationStore is Claimable, ERC721Holder{

    using SafeMath for uint256;

    GTAInterface public token;

    uint256 private tokenSellPrice;  
    uint256 private tokenBuyPrice;  
    uint256 public buyDiscount;  

    mapping (address => mapping (uint256 => uint256)) public nftPrices;

    event Buy(address buyer, uint256 amount, uint256 payed);
    event Robbery(address robber);

    constructor (address _tokenAddress) public {
        token = GTAInterface(_tokenAddress);
    }

     

     
     
    function depositGTA(uint256 amount) onlyOwner public {
        require(token.transferFrom(msg.sender, this, amount), "Insufficient funds");
    }

     
     
    function listNFT(address _nftToken, uint256[] _tokenIds, uint256 _price) onlyOwner public {
        ERC721Basic erc721 = ERC721Basic(_nftToken);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            erc721.safeTransferFrom(msg.sender, this, _tokenIds[i]);
            nftPrices[_nftToken][_tokenIds[i]] = _price;
        }
    }

    function delistNFT(address _nftToken, uint256[] _tokenIds) onlyOwner public {
        ERC721Basic erc721 = ERC721Basic(_nftToken);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            erc721.safeTransferFrom(this, msg.sender, _tokenIds[i]);
        }
    }

    function withdrawGTA(uint256 amount) onlyOwner public {
        require(token.transfer(msg.sender, amount), "Amount exceeds the available balance");
    }

    function robCashier() onlyOwner public {
        msg.sender.transfer(address(this).balance);
        emit Robbery(msg.sender);
    }

     
    function setTokenPrices(uint256 _newSellPrice, uint256 _newBuyPrice) onlyOwner public {
        tokenSellPrice = _newSellPrice;
        tokenBuyPrice = _newBuyPrice;
    }

    function buyNFT(address _nftToken, uint256 _tokenId) payable public returns (uint256){
        ERC721Basic erc721 = ERC721Basic(_nftToken);
        require(erc721.ownerOf(_tokenId) == address(this), "This token is not available");
        require(nftPrices[_nftToken][_tokenId] <= msg.value, "Payed too little");
        erc721.safeTransferFrom(this, msg.sender, _tokenId);
    }

    function buy() payable public returns (uint256){
         
         
        uint256 value = msg.value.mul(1 ether);
        uint256 _buyPrice = tokenBuyPrice;
        if (buyDiscount > 0) {
             
            _buyPrice = _buyPrice.sub(_buyPrice.mul(buyDiscount).div(100));
        }
        uint256 amount = value.div(_buyPrice);
        require(token.balanceOf(this) >= amount, "Sold out");
        require(token.transfer(msg.sender, amount), "Couldn't transfer token");
        emit Buy(msg.sender, amount, msg.value);
        return amount;
    }

     
     
     
     

    function applyDiscount(uint256 discount) onlyOwner public {
        buyDiscount = discount;
    }

    function getTokenBuyPrice() public view returns (uint256) {
        uint256 _buyPrice = tokenBuyPrice;
        if (buyDiscount > 0) {
            _buyPrice = _buyPrice.sub(_buyPrice.mul(buyDiscount).div(100));
        }
        return _buyPrice;
    }

    function getTokenSellPrice() public view returns (uint256) {
        return tokenSellPrice;
    }
}

 
interface GTAInterface {

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256);

}