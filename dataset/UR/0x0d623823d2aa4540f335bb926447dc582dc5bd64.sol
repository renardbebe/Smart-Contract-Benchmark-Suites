 

pragma solidity ^0.4.18;  



 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}


contract MemeToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoMemes";  
  string public constant SYMBOL = "MemeToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

   

   
   
  mapping (uint256 => address) public memeIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public memeIndexToApproved;

   
  mapping (uint256 => uint256) private memeIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
  struct Meme {
    string name;
  }

  struct Memes {
    uint256 Id;
    string memeName;
    uint256 sellingPrice;
    address owner;
  }

  Meme[] private memes;

   
   
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

   
  function MemeToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    memeIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoMeme(address _owner, string _name, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address memeOwner = _owner;
    if (memeOwner == address(0)) {
      memeOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createMeme(_name, memeOwner, _price);
  }

   
  function createContractMeme(string _name) public onlyCOO {
    _createMeme(_name, address(this), startingPrice);
  }

   
   
  function getMeme(uint256 _tokenId) public view returns (
    uint256 Id,
    string memeName,
    uint256 sellingPrice,
    address owner
  ) {
    Meme storage meme = memes[_tokenId];
    Id = _tokenId;
    memeName = meme.name;
    sellingPrice = memeIndexToPrice[_tokenId];
    owner = memeIndexToOwner[_tokenId];
  }

   
   
  function getMemeSellingPrices(uint256[] _tokenIds) public view returns (
    uint256[] sellingPrices
  ) {
    sellingPrices = new uint256[](_tokenIds.length);
    for(uint i=0;i<_tokenIds.length;i++){
      sellingPrices[i]=memeIndexToPrice[_tokenIds[i]];
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
    owner = memeIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = memeIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = memeIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
       
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
       
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, memeIndexToPrice[_tokenId], oldOwner, newOwner, memes[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return memeIndexToPrice[_tokenId];
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
    address oldOwner = memeIndexToOwner[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
   
   
   
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalMemes = totalSupply();
      uint256 resultIndex = 0;

      uint256 memeId;
      for (memeId = 0; memeId <= totalMemes; memeId++) {
        if (memeIndexToOwner[memeId] == _owner) {
          result[resultIndex] = memeId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return memes.length;
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
    return memeIndexToApproved[_tokenId] == _to;
  }

   
  function _createMeme(string _name, address _owner, uint256 _price) private {
    Meme memory _meme = Meme({
      name: _name
    });
    uint256 newMemeId = memes.push(_meme) - 1;

     
     
    require(newMemeId == uint256(uint32(newMemeId)));

    Birth(newMemeId, _name, _owner);

    memeIndexToPrice[newMemeId] = _price;

     
     
    _transfer(address(0), _owner, newMemeId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == memeIndexToOwner[_tokenId];
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
     
    memeIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete memeIndexToApproved[_tokenId];
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