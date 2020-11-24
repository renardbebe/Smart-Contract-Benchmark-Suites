 

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

 
 
contract EtherColor is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "EtherColors";  
  string public constant SYMBOL = "EtherColor";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;

   

   
   
  mapping (uint256 => address) public colorIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public colorIndexToApproved;

   
  mapping (uint256 => uint256) private colorIndexToPrice;

   
   
  mapping (uint256 => uint256) private colorIndexToPreviousPrice;

   
  mapping (uint256 => address[5]) private colorIndexToPreviousOwners;


   
  address public ceoAddress;
  address public cooAddress;

   
  struct Color {
    string name;
  }

  Color[] private colors;

   
   
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

   
  function EtherColor() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    colorIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createContractColor(string _name) public onlyCOO {
    _createColor(_name, address(this), startingPrice);
  }

   
   
  function getColor(uint256 _tokenId) public view returns (
    string colorName,
    uint256 sellingPrice,
    address owner,
    uint256 previousPrice,
    address[5] previousOwners
  ) {
    Color storage color = colors[_tokenId];
    colorName = color.name;
    sellingPrice = colorIndexToPrice[_tokenId];
    owner = colorIndexToOwner[_tokenId];
    previousPrice = colorIndexToPreviousPrice[_tokenId];
    previousOwners = colorIndexToPreviousOwners[_tokenId];
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
    owner = colorIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = colorIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    address[5] storage previousOwners = colorIndexToPreviousOwners[_tokenId];

    uint256 sellingPrice = colorIndexToPrice[_tokenId];
    uint256 previousPrice = colorIndexToPreviousPrice[_tokenId];
     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 priceDelta = SafeMath.sub(sellingPrice, previousPrice);
    uint256 ownerPayout = SafeMath.add(previousPrice, SafeMath.mul(SafeMath.div(priceDelta, 100), 49));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
    } else if (sellingPrice < secondStepLimit) {
       
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    } else {
       
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 100);
    }
    colorIndexToPreviousPrice[_tokenId] = sellingPrice;

    uint256 fee_for_dev;
     
     
    if (oldOwner != address(this)) {
       
      oldOwner.transfer(ownerPayout);
      fee_for_dev = SafeMath.mul(SafeMath.div(priceDelta, 100), 1);
    } else {
      fee_for_dev = SafeMath.add(ownerPayout, SafeMath.mul(SafeMath.div(priceDelta, 100), 1));
    }

     
    for (uint i = 0; i <= 4; i++) {
        if (previousOwners[i] != address(this)) {
            previousOwners[i].transfer(uint256(SafeMath.div(SafeMath.mul(priceDelta, 10), 100)));
        } else {
            fee_for_dev = SafeMath.add(fee_for_dev, uint256(SafeMath.div(SafeMath.mul(priceDelta, 10), 100)));
        }
    }
    ceoAddress.transfer(fee_for_dev);

    _transfer(oldOwner, newOwner, _tokenId);

     

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return colorIndexToPrice[_tokenId];
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
    address oldOwner = colorIndexToOwner[_tokenId];

     
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
      uint256 totalColors = totalSupply();
      uint256 resultIndex = 0;
      uint256 colorId;
      for (colorId = 0; colorId <= totalColors; colorId++) {
        if (colorIndexToOwner[colorId] == _owner) {
          result[resultIndex] = colorId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return colors.length;
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
    return colorIndexToApproved[_tokenId] == _to;
  }

   
  function _createColor(string _name, address _owner, uint256 _price) private {
    Color memory _color = Color({
      name: _name
    });
    uint256 newColorId = colors.push(_color) - 1;

     
     
    require(newColorId == uint256(uint32(newColorId)));

    Birth(newColorId, _name, _owner);

    colorIndexToPrice[newColorId] = _price;
    colorIndexToPreviousPrice[newColorId] = 0;
    colorIndexToPreviousOwners[newColorId] =
        [address(this), address(this), address(this), address(this), address(this)];

     
     
    _transfer(address(0), _owner, newColorId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == colorIndexToOwner[_tokenId];
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
     
    colorIndexToOwner[_tokenId] = _to;
     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete colorIndexToApproved[_tokenId];
    }
     
    colorIndexToPreviousOwners[_tokenId][4]=colorIndexToPreviousOwners[_tokenId][3];
    colorIndexToPreviousOwners[_tokenId][3]=colorIndexToPreviousOwners[_tokenId][2];
    colorIndexToPreviousOwners[_tokenId][2]=colorIndexToPreviousOwners[_tokenId][1];
    colorIndexToPreviousOwners[_tokenId][1]=colorIndexToPreviousOwners[_tokenId][0];
     
    if (_from != address(0)) {
        colorIndexToPreviousOwners[_tokenId][0]=_from;
    } else {
        colorIndexToPreviousOwners[_tokenId][0]=address(this);
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