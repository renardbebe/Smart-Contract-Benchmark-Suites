 

pragma solidity ^0.4.18;  



 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  uint256 public totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}


contract CollectibleToken is ERC721 {

   

   
  event Birth(uint256 tokenId, uint256 startPrice, uint256 totalSupply);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "crypto-youCollect";  
  string public constant SYMBOL = "CYC";  
  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;


   

   
   
  mapping (uint256 => address) public collectibleIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public collectibleIndexToApproved;

   
  mapping (uint256 => uint256) private collectibleIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

   
  function CollectibleToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    collectibleIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoCollectible(uint256 tokenId, address _owner, uint256 _price) public onlyCOO {
    require(collectibleIndexToOwner[tokenId]==address(0));
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address collectibleOwner = _owner;
    if (collectibleOwner == address(0)) {
      collectibleOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createCollectible(tokenId, _price);
     
     
    _transfer(address(0), collectibleOwner, tokenId);

  }

   
   
  function getCollectible(uint256 _tokenId) public view returns (uint256 tokenId,
    uint256 sellingPrice,
    address owner,
    uint256 nextSellingPrice
  ) {
    tokenId = _tokenId;
    sellingPrice = collectibleIndexToPrice[_tokenId];
    owner = collectibleIndexToOwner[_tokenId];

    if (sellingPrice == 0)
      sellingPrice = startingPrice;
    if (sellingPrice < firstStepLimit) {
      nextSellingPrice = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
      nextSellingPrice = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
      nextSellingPrice = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

   
   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = collectibleIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = collectibleIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = collectibleIndexToPrice[_tokenId];
    if (sellingPrice == 0) {
      sellingPrice = startingPrice;
      _createCollectible(_tokenId, sellingPrice);
    }

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      collectibleIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
       
      collectibleIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
       
      collectibleIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);
    TokenSold(_tokenId, sellingPrice, collectibleIndexToPrice[_tokenId], oldOwner, newOwner);

     
    if (oldOwner != address(this) && oldOwner != address(0)) {
      oldOwner.transfer(payment);  
    }


    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    price = collectibleIndexToPrice[_tokenId];
    if (price == 0)
      price = startingPrice;
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
   
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = collectibleIndexToOwner[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return collectibleIndexToApproved[_tokenId] == _to;
  }

   
  function _createCollectible(uint256 tokenId, uint256 _price) private {
    collectibleIndexToPrice[tokenId] = _price;
    totalSupply++;
    Birth(tokenId, _price, totalSupply);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == collectibleIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    collectibleIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete collectibleIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }
}
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