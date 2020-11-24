 

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
   
   
  event Birth(uint256 tokenId, uint256 metadata, string text, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner, uint256 metadata, string text);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
   
  string public constant NAME = "CryptoMemes";  
  string public constant SYMBOL = "CM";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 50000;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;

   
   
   
  mapping (uint256 => address) public memeIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public memeIndexToApproved;

   
  mapping (uint256 => uint256) private memeIndexToPrice;

   
   
  address public dogeAddress;
   
   
  address public r9kAddress;

  uint256 public promoCreatedCount;

   
  struct Meme {
    uint256 metadata;
    string text;
  }

   
  Meme[] private memes;

   
   
  modifier onlyDoge() {
    require(msg.sender == dogeAddress);
    _;
  }

   
  modifier onlyr9k() {
    require(msg.sender == r9kAddress);
    _;
  }

   
  modifier onlyDogeAndr9k() {
    require(
      msg.sender == dogeAddress ||
      msg.sender == r9kAddress
    );
    _;
  }

   
  function MemeToken() public {
    dogeAddress = msg.sender;
    r9kAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public
  {
     
    require(_owns(msg.sender, _tokenId));

    memeIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
   
  function createPromoMeme(address _owner, uint256 _metadata, string _text, uint256 _price) public onlyDogeAndr9k {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address memeOwner = _owner;
    if (memeOwner == address(0)) {
      memeOwner = dogeAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createMeme(_metadata, _text, memeOwner, _price);
  }

   
   
  function createUserMeme(address _owner, uint256 _metadata, string _text, uint256 _price) public onlyDogeAndr9k {
    address memeOwner = _owner;
    if (memeOwner == address(0)) {
      memeOwner = dogeAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    _createMeme(_metadata, _text, memeOwner, _price);
  }

   
  function createContractMeme(uint256 _metadata, string _text) public onlyDogeAndr9k {
    _createMeme(_metadata, _text, address(this), startingPrice);
  }

   
   
  function getMeme(uint256 _tokenId) public view returns (
    uint256 metadata,
    string text,
    uint256 sellingPrice,
    address owner
  ) {
    Meme storage meme = memes[_tokenId];
    metadata = meme.metadata;
    text = meme.text;
    sellingPrice = memeIndexToPrice[_tokenId];
    owner = memeIndexToOwner[_tokenId];
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

  function payout(address _to) public onlyDoge {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = memeIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = memeIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 97), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
    } else if (sellingPrice < secondStepLimit) {
       
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    } else {
       
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 100);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, memeIndexToPrice[_tokenId], oldOwner, newOwner, memes[_tokenId].metadata, memes[_tokenId].text);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return memeIndexToPrice[_tokenId];
  }

   
   
  function setDoge(address _newDoge) public onlyDoge {
    require(_newDoge != address(0));

    dogeAddress = _newDoge;
  }

   
   
  function setRobot(address _newRobot) public onlyDoge {
    require(_newRobot != address(0));

    r9kAddress = _newRobot;
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
      uint256 memeCount = totalSupply();
      uint256 resultIndex = 0;

      uint256 memeId;
      for (memeId = 0; memeId <= memeCount; memeId++) {
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
  ) public
  {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public
  {
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

   
  function _createMeme(uint256 _metadata, string _text, address _owner, uint256 _price) private {
    Meme memory _meme = Meme({
      metadata: _metadata,
      text: _text
    });
    uint256 newMemeId = memes.push(_meme) - 1;

     
     
    require(newMemeId == uint256(uint64(newMemeId)));

    Birth(newMemeId, _metadata, _text, _owner);

    memeIndexToPrice[newMemeId] = _price;

     
     
    _transfer(address(0), _owner, newMemeId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == memeIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      dogeAddress.transfer(this.balance);
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