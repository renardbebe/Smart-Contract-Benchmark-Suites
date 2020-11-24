 

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


contract EtherCityToken is ERC721 {

   

   
  event CityCreated(uint256 tokenId, string name, string country, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name, string country);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "EtherCities";  
  string public constant SYMBOL = "EtherCityToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.005 ether;
  uint256 private secondStepLimit = 0.055 ether;
  uint256 private thirdStepLimit = 0.5 ether;
  uint256 private fourthStepLimit = 10.0 ether;

   

   
   
  mapping (uint256 => address) public cityIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public cityIndexToApproved;

   
  mapping (uint256 => uint256) private cityIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
  struct City {
    string name;
    string country;
  }

  City[] private cities;

   
   
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

   
  function EtherCityToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    cityIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoCity(address _owner, string _name, string _country, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address cityOwner = _owner;
    if (cityOwner == address(0)) {
      cityOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createCity(_name, _country, cityOwner, _price);
  }

   
  function createContractCity(string _name, string _country) public onlyCOO {
    _createCity(_name, _country, address(this), startingPrice);
  }

   
   
  function getCity(uint256 _tokenId) public view returns (
    string cityName,
    string country,
    uint256 sellingPrice,
    address owner
  ) {
    City storage city = cities[_tokenId];
    cityName = city.name;
    country = city.country;
    sellingPrice = cityIndexToPrice[_tokenId];
    owner = cityIndexToOwner[_tokenId];
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
    owner = cityIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = cityIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = cityIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 95), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      cityIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 95);
    } else if (sellingPrice < secondStepLimit) {
       
      cityIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 135), 95);
    } else if (sellingPrice < thirdStepLimit) {
       
      cityIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 95);
    } else if (sellingPrice < fourthStepLimit) {
       
      cityIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 118), 95);
    } else {
       
      cityIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 113), 95);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, cityIndexToPrice[_tokenId], oldOwner, newOwner, cities[_tokenId].name, cities[_tokenId].country);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return cityIndexToPrice[_tokenId];
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
    address oldOwner = cityIndexToOwner[_tokenId];

     
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
      uint256 totalCities = totalSupply();
      uint256 resultIndex = 0;

      uint256 cityId;
      for (cityId = 0; cityId <= totalCities; cityId++) {
        if (cityIndexToOwner[cityId] == _owner) {
          result[resultIndex] = cityId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return cities.length;
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
    return cityIndexToApproved[_tokenId] == _to;
  }

   
  function _createCity(string _name, string _country, address _owner, uint256 _price) private {
    City memory _city = City({
      name: _name,
      country: _country
    });
    uint256 newCityId = cities.push(_city) - 1;

     
     
    require(newCityId == uint256(uint32(newCityId)));

    CityCreated(newCityId, _name, _country, _owner);

    cityIndexToPrice[newCityId] = _price;

     
     
    _transfer(address(0), _owner, newCityId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == cityIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  function _withdrawFunds(address _to, uint256 amount) private {
    require(this.balance >= amount);
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
    }
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    cityIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete cityIndexToApproved[_tokenId];
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