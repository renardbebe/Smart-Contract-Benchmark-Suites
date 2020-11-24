 

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


contract CryptoSocialMediaToken is ERC721 {

   
   
  
   

   
  event Birth(uint256 tokenId, string name, address owner, bytes32 message);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoSocialMedia";  
  string public constant SYMBOL = "CryptoSocialMediaToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

   

   
   
  mapping (uint256 => address) public itemIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public itemIndexToApproved;

   
  mapping (uint256 => uint256) private itemIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

   
  struct Item {
    string name;
	bytes32 message;
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

   
  function CryptoSocialMediaToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
	
	createContractItem("4chan", "");
	createContractItem("9gag", "");
	createContractItem("Discord", "");
	createContractItem("Facebook", "");
	createContractItem("Google Plus", "");
	createContractItem("Instagram", "");
	createContractItem("Medium", "");
	createContractItem("Periscope", "");
	createContractItem("Pinterest", "");
	createContractItem("Reddit", "");
	createContractItem("Skype", "");
	createContractItem("Snapchat", "");
	createContractItem("Tumblr", "");
	createContractItem("Twitch", "");
	createContractItem("Twitter", "");
	createContractItem("Wechat", "");
	createContractItem("Whatsapp", "");
	createContractItem("Youtube", "");
	
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

   
  function createContractItem(string _name, bytes32 _message) public onlyCOO {
    _createItem(_name, address(this), startingPrice, _message);
  }

   
   
  function getItem(uint256 _tokenId) public view returns (
    string itemName,
    uint256 sellingPrice,
    address owner,
	bytes32 itemMessage
  ) {
    Item storage item = items[_tokenId];
    itemName = item.name;
	itemMessage = item.message;
    sellingPrice = itemIndexToPrice[_tokenId];
    owner = itemIndexToOwner[_tokenId];
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

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
       
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
       
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);
	
     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, itemIndexToPrice[_tokenId], oldOwner, newOwner, items[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
	
	 
	items[_tokenId].message = _message;
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

   
  function _createItem(string _name, address _owner, uint256 _price, bytes32 _message) private {
    Item memory _item = Item({
      name: _name,
	  message: _message
    });
    uint256 newItemId = items.push(_item) - 1;

     
     
    require(newItemId == uint256(uint32(newItemId)));

    Birth(newItemId, _name, _owner, _message);

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