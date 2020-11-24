 

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

 
contract EmojiToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "EmojiBlockchain";  
  string public constant SYMBOL = "EmojiToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 77;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.55 ether;

   

   
   
  mapping (uint256 => address) public emojiIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public emojiIndexToApproved;

   
  mapping (uint256 => uint256) private emojiIndexToPrice;
  
   
   
  mapping (uint256 => uint256) private emojiIndexToPreviousPrice;

   
   
  mapping (uint256 => string) private emojiIndexToCustomMessage;

   
  mapping (uint256 => address[7]) private emojiIndexToPreviousOwners;


   
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
  struct Emoji {
    string name;
  }

  Emoji[] private emojis;

   
   
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

   
  function EmojiToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    emojiIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoEmoji(address _owner, string _name, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address emojiOwner = _owner;
    if (emojiOwner == address(0)) {
      emojiOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createEmoji(_name, emojiOwner, _price);
  }

   
  function createContractEmoji(string _name) public onlyCOO {
    _createEmoji(_name, address(this), startingPrice);
  }

   
   
  function getEmoji(uint256 _tokenId) public view returns (
    string emojiName,
    uint256 sellingPrice,
    address owner,
    string message,
    uint256 previousPrice,
    address[7] previousOwners
  ) {
    Emoji storage emoji = emojis[_tokenId];
    emojiName = emoji.name;
    sellingPrice = emojiIndexToPrice[_tokenId];
    owner = emojiIndexToOwner[_tokenId];
    message = emojiIndexToCustomMessage[_tokenId];
    previousPrice = emojiIndexToPreviousPrice[_tokenId];
    previousOwners = emojiIndexToPreviousOwners[_tokenId];
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
    owner = emojiIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
   
  function addMessage(uint256 _tokenId, string _message) public {
    require(_owns(msg.sender, _tokenId));
    require(bytes(_message).length<281);
    emojiIndexToCustomMessage[_tokenId] = _message;
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = emojiIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    
    address[7] storage previousOwners = emojiIndexToPreviousOwners[_tokenId];

    uint256 sellingPrice = emojiIndexToPrice[_tokenId];
    uint256 previousPrice = emojiIndexToPreviousPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 priceDelta = SafeMath.sub(sellingPrice, previousPrice);
    uint256 payoutTotal = uint256(SafeMath.div(SafeMath.mul(priceDelta, 90), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      emojiIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 90);
    } else if (sellingPrice < secondStepLimit) {
       
      emojiIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 90);
    } else {
       
      emojiIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 90);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
     
    if (oldOwner != address(this) && previousPrice > 0) {
       
      oldOwner.transfer(previousPrice);
    }
    
     
     
     
    if (previousOwners[0] != address(this) && payoutTotal > 0) {
      previousOwners[0].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 75), 100)));
    }
    if (previousOwners[1] != address(this) && payoutTotal > 0) {
      previousOwners[1].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 12), 100)));
    }
    if (previousOwners[2] != address(this) && payoutTotal > 0) {
      previousOwners[2].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 6), 100)));
    }
    if (previousOwners[3] != address(this) && payoutTotal > 0) {
      previousOwners[3].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 3), 100)));
    }
    if (previousOwners[4] != address(this) && payoutTotal > 0) {
      previousOwners[4].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 2), 100)));
    }
    if (previousOwners[5] != address(this) && payoutTotal > 0) {
       
      previousOwners[5].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 15), 1000)));
    }
    if (previousOwners[6] != address(this) && payoutTotal > 0) {
       
      previousOwners[6].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 5), 1000)));
    }
    
    TokenSold(_tokenId, sellingPrice, emojiIndexToPrice[_tokenId], oldOwner, newOwner, emojis[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return emojiIndexToPrice[_tokenId];
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
    address oldOwner = emojiIndexToOwner[_tokenId];

     
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
      uint256 totalEmojis = totalSupply();
      uint256 resultIndex = 0;
      uint256 emojiId;
      for (emojiId = 0; emojiId <= totalEmojis; emojiId++) {
        if (emojiIndexToOwner[emojiId] == _owner) {
          result[resultIndex] = emojiId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return emojis.length;
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
    return emojiIndexToApproved[_tokenId] == _to;
  }

   
  function _createEmoji(string _name, address _owner, uint256 _price) private {
    Emoji memory _emoji = Emoji({
      name: _name
    });
    uint256 newEmojiId = emojis.push(_emoji) - 1;

     
     
    require(newEmojiId == uint256(uint32(newEmojiId)));

    Birth(newEmojiId, _name, _owner);

    emojiIndexToPrice[newEmojiId] = _price;
    emojiIndexToPreviousPrice[newEmojiId] = 0;
    emojiIndexToCustomMessage[newEmojiId] = 'hi';
    emojiIndexToPreviousOwners[newEmojiId] =
        [address(this), address(this), address(this), address(this), address(this), address(this), address(this)];

     
     
    _transfer(address(0), _owner, newEmojiId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == emojiIndexToOwner[_tokenId];
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
     
    emojiIndexToOwner[_tokenId] = _to;
     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete emojiIndexToApproved[_tokenId];
    }
     
    emojiIndexToPreviousOwners[_tokenId][6]=emojiIndexToPreviousOwners[_tokenId][5];
    emojiIndexToPreviousOwners[_tokenId][5]=emojiIndexToPreviousOwners[_tokenId][4];
    emojiIndexToPreviousOwners[_tokenId][4]=emojiIndexToPreviousOwners[_tokenId][3];
    emojiIndexToPreviousOwners[_tokenId][3]=emojiIndexToPreviousOwners[_tokenId][2];
    emojiIndexToPreviousOwners[_tokenId][2]=emojiIndexToPreviousOwners[_tokenId][1];
    emojiIndexToPreviousOwners[_tokenId][1]=emojiIndexToPreviousOwners[_tokenId][0];
     
    if (_from != address(0)) {
        emojiIndexToPreviousOwners[_tokenId][0]=_from;
    } else {
        emojiIndexToPreviousOwners[_tokenId][0]=address(this);
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