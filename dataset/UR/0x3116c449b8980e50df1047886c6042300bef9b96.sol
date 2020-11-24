 

pragma solidity ^0.4.18;

 
 

contract ERC721 {
   
  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;

   
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract CryptoColors is ERC721 {

   

   
  event Released(uint256 tokenId, string name, address owner);

   
  event ColorSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
   
  string public constant NAME = "CryptoColors";
  string public constant SYMBOL = "COLOR";

  uint256 private constant PROMO_CREATION_LIMIT = 1000000;
  uint256 private startingPrice = 0.001 ether;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;


   
   
   
  mapping (uint256 => address) public colorIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public colorIndexToApproved;

   
  mapping (uint256 => uint256) private colorIndexToPrice;

   
  address public ceoAddress;

   
  uint256 public promoCreatedCount;

   
  struct Color{
    uint8 R;
    uint8 G;
    uint8 B;
    string name;
  }

   
  Color[] private colors;


   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  function CryptoColors() public {
    ceoAddress = msg.sender;
  }

   

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
   
   
   
  function approve(address _to, uint256 _tokenId) public {
     
    require(_owns(msg.sender, _tokenId));

    colorIndexToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoColor(uint256 _R, uint256 _G, uint256 _B, string _name, address _owner, uint256 _price) public onlyCEO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address colorOwner = _owner;
    if (colorOwner == address(0)) {
      colorOwner = ceoAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createColor(_R, _G, _B, _name, colorOwner, _price);
  }

   
  function createContractColor(uint256 _R, uint256 _G, uint256 _B, string _name) public onlyCEO {
    _createColor(_R, _G, _B, _name, address(this), startingPrice);
  }

   
   
  function getColor(uint256 _tokenId) public view returns (uint256 R, uint256 G, uint256 B, string colorName, uint256 sellingPrice, address owner) {
    Color storage col = colors[_tokenId];

    R = col.R;
    G = col.G;
    B = col.B;
    colorName = col.name;
    sellingPrice = colorIndexToPrice[_tokenId];
    owner = colorIndexToOwner[_tokenId];
  }

   
   
   
  function ownerOf(uint256 _tokenId) public view returns (address owner) {
    owner = colorIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCEO {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = colorIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = colorIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 93), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 93);
    } else if (sellingPrice < secondStepLimit) {
       
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 93);
    } else {
       
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 93);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

    ColorSold(_tokenId, sellingPrice, colorIndexToPrice[_tokenId], oldOwner, newOwner, colors[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return colorIndexToPrice[_tokenId];
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
      uint256 totalcolors = totalSupply();
      uint256 resultIndex = 0;

      uint256 colorId;
      for (colorId = 0; colorId <= totalcolors; colorId++) {
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

   
   
   
   
  function transfer(address _to, uint256 _tokenId) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _tokenId) public {
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

   
  function _createColor(uint256 _R, uint256 _G, uint256 _B, string _name, address _owner, uint256 _price) private {
    require(_R == uint256(uint8(_R)));
    require(_G == uint256(uint8(_G)));
    require(_B == uint256(uint8(_B)));

    Color memory _color = Color({
        R: uint8(_R),
        G: uint8(_G),
        B: uint8(_B),
        name: _name
    });

    uint256 newColorId = colors.push(_color) - 1;

    require(newColorId == uint256(uint32(newColorId)));

    Released(newColorId, _name, _owner);

    colorIndexToPrice[newColorId] = _price;

     
     
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
}