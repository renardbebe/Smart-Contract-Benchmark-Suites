 

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


contract CryptoPepeMarketToken is ERC721 {

   
   
  
   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoSocialMedia";  
  string public constant SYMBOL = "CryptoPepeMarketToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

  mapping (uint256 => TopOwner) private topOwner;
  mapping (uint256 => address) public lastBuyer;

   

   
   
  mapping (uint256 => address) public itemIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public itemIndexToApproved;

   
  mapping (uint256 => uint256) private itemIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  struct TopOwner {
    address addr;
    uint256 price;
  }

   
  struct Item {
    string name;
	bytes32 message;
	address creatoraddress;		 
  }

  Item[] private items;

   
   
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

   
  function CryptoPepeMarketToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;

	 
	 _createItem("Feelsgood", 0x7d9450A4E85136f46BA3F519e20Fea52f5BEd063,359808729788989630,"",address(this));
	_createItem("Ree",0x2C3756c4cB4Ff488F666a3856516ba981197f3f3,184801761494400960,"",address(this));
	_createItem("TwoGender",0xb16948C62425ed389454186139cC94178D0eFbAF,359808729788989630,"",address(this));
	_createItem("Gains",0xA69E065734f57B73F17b38436f8a6259cCD090Fd,359808729788989630,"",address(this));
	_createItem("Trump",0xBcce2CE773bE0250bdDDD4487d927aCCd748414F,94916238056430340,"",address(this));
	_createItem("Brain",0xBcce2CE773bE0250bdDDD4487d927aCCd748414F,94916238056430340,"",address(this));
	_createItem("Illuminati",0xbd6A9D2C44b571F33Ee2192BD2d46aBA2866405a,94916238056430340,"",address(this));
	_createItem("Hang",0x2C659bf56012deeEc69Aea6e87b6587664B99550,94916238056430340,"",address(this));
	_createItem("Pepesaur",0x7d9450A4E85136f46BA3F519e20Fea52f5BEd063,184801761494400960,"",address(this));
	_createItem("BlockChain",0x2C3756c4cB4Ff488F666a3856516ba981197f3f3,184801761494400960,"",address(this));
	_createItem("Wanderer",0xBcce2CE773bE0250bdDDD4487d927aCCd748414F,184801761494400960,"",address(this));
	_createItem("Link",0xBcce2CE773bE0250bdDDD4487d927aCCd748414F,184801761494400960,"",address(this));

	 
	topOwner[1] = TopOwner(0x7d9450A4E85136f46BA3F519e20Fea52f5BEd063,350000000000000000); 
    topOwner[2] = TopOwner(0xb16948C62425ed389454186139cC94178D0eFbAF, 350000000000000000); 
    topOwner[3] = TopOwner(0xA69E065734f57B73F17b38436f8a6259cCD090Fd, 350000000000000000); 
	lastBuyer[1] = ceoAddress;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    itemIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createContractItem(string _name, bytes32 _message, address _creatoraddress) public onlyCOO {
    _createItem(_name, address(this), startingPrice, _message, _creatoraddress);
  }

   
   
  function getItem(uint256 _tokenId) public view returns (
    string itemName,
    uint256 sellingPrice,
    address owner,
	bytes32 itemMessage,
	address creator
  ) {
    Item storage item = items[_tokenId];

    itemName = item.name;
	itemMessage = item.message;
    sellingPrice = itemIndexToPrice[_tokenId];
    owner = itemIndexToOwner[_tokenId];
	creator = item.creatoraddress;
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
    owner = itemIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId, bytes32 _message) public payable {
    address oldOwner = itemIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = itemIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    uint256 msgPrice = msg.value;
    require(msgPrice >= sellingPrice);

	 
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 86), 100));

	 
	uint256 twoPercentFee = uint256(SafeMath.mul(SafeMath.div(sellingPrice, 100), 2));
	topOwner[1].addr.transfer(twoPercentFee); 
    topOwner[2].addr.transfer(twoPercentFee); 
    topOwner[3].addr.transfer(twoPercentFee);

	uint256 fourPercentFee = uint256(SafeMath.mul(SafeMath.div(sellingPrice, 100), 4));

	 
	lastBuyer[1].transfer(fourPercentFee);

	 
	if(items[_tokenId].creatoraddress != address(this)){
		items[_tokenId].creatoraddress.transfer(fourPercentFee);
	}


     
    if (sellingPrice < firstStepLimit) {
       
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 86);
    } else if (sellingPrice < secondStepLimit) {
       
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 86);
    } else {
       
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 86);
    }

    _transfer(oldOwner, newOwner, _tokenId);
	
     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

	 
	items[_tokenId].message = _message;

    TokenSold(_tokenId, sellingPrice, itemIndexToPrice[_tokenId], oldOwner, newOwner);

	 
	lastBuyer[1] = msg.sender;

	 
	if(sellingPrice > topOwner[3].price){
        for(uint8 i = 3; i >= 1; i--){
            if(sellingPrice > topOwner[i].price){
                if(i <= 2){ topOwner[3] = topOwner[2]; }
                if(i <= 1){ topOwner[2] = topOwner[1]; }
                topOwner[i] = TopOwner(msg.sender, sellingPrice);
                break;
            }
        }
    }

	 
	uint256 excess = SafeMath.sub(msg.value, sellingPrice);
	msg.sender.transfer(excess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return itemIndexToPrice[_tokenId];
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
    address oldOwner = itemIndexToOwner[_tokenId];

     
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
      uint256 totalItems = totalSupply();
      uint256 resultIndex = 0;

      uint256 itemId;
      for (itemId = 0; itemId <= totalItems; itemId++) {
        if (itemIndexToOwner[itemId] == _owner) {
          result[resultIndex] = itemId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return items.length;
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
    return itemIndexToApproved[_tokenId] == _to;
  }

   
  function _createItem(string _name, address _owner, uint256 _price, bytes32 _message, address _creatoraddress) private {
    Item memory _item = Item({
      name: _name,
	  message: _message,
	  creatoraddress: _creatoraddress
    });
    uint256 newItemId = items.push(_item) - 1;

     
     
    require(newItemId == uint256(uint32(newItemId)));

    Birth(newItemId, _name, _owner);

    itemIndexToPrice[newItemId] = _price;

     
     
    _transfer(address(0), _owner, newItemId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == itemIndexToOwner[_tokenId];
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
     
    itemIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete itemIndexToApproved[_tokenId];
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