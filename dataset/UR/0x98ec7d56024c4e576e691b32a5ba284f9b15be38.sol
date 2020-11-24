 

pragma solidity ^0.4.18;

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract CountryToken {
  function getCountryData (uint256 _tokenId) external view returns (address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice, uint256 _payout);
}

 
contract CityToken is ERC721, Ownable {
  using SafeMath for uint256;

  address cAddress = 0x0c507D48C0cd1232B82aA950d487d01Cfc6442Db;
  
  CountryToken countryContract = CountryToken(cAddress);

   
  uint32 constant COUNTRY_IDX = 100;
  uint256 constant COUNTRY_PAYOUT = 15;  

   
  uint256 private totalTokens;
  uint256[] private listedCities;
  uint256 public devOwed;
  uint256 public poolTotal;
  uint256 public lastPurchase;

   
  mapping (uint256 => City) public cityData;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  mapping (address => uint256) private payoutBalances; 

   
  mapping (uint256 => uint256) private countryWithdrawn;

   
  event CityPurchased(uint256 indexed _tokenId, address indexed _owner, uint256 _purchasePrice);

   
  uint256 private firstCap  = 0.12 ether;
  uint256 private secondCap = 0.5 ether;
  uint256 private thirdCap  = 1.5 ether;

   
  struct City {
      uint256 price;          
      uint256 lastPrice;      
      uint256 payout;         
      uint256 withdrawn;      
      address owner;          
  }

   
   function createPromoListing(uint256 _tokenId, uint256 _startingPrice, uint256 _payoutPercentage) onlyOwner() public {
     uint256 countryId = _tokenId % COUNTRY_IDX;
     address countryOwner;
     uint256 price;
     (countryOwner,,price,,) = countryContract.getCountryData(countryId);
     require (countryOwner != address(0));

     if (_startingPrice == 0) {
       if (price >= thirdCap) _startingPrice = price.div(80);
       else if (price >= secondCap) _startingPrice = price.div(75);
       else _startingPrice = 0.002 ether;
     }

     createListing(_tokenId, _startingPrice, _payoutPercentage, countryOwner);
   }

   
  function createListing(uint256 _tokenId, uint256 _startingPrice, uint256 _payoutPercentage, address _owner) onlyOwner() public {

     
    require(_startingPrice > 0);
     
    require(cityData[_tokenId].price == 0);
    
     
    City storage newCity = cityData[_tokenId];

    newCity.owner = _owner;
    newCity.price = _startingPrice;
    newCity.lastPrice = 0;
    newCity.payout = _payoutPercentage;

     
    listedCities.push(_tokenId);
    
     
    _mint(_owner, _tokenId);
  }

  function createMultiple (uint256[] _itemIds, uint256[] _prices, uint256[] _payouts, address _owner) onlyOwner() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      createListing(_itemIds[i], _prices[i], _payouts[i], _owner);
    }
  }

   
  function getNextPrice (uint256 _price) private view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(200).div(94);
    } else if (_price < secondCap) {
      return _price.mul(135).div(95);
    } else if (_price < thirdCap) {
      return _price.mul(118).div(96);
    } else {
      return _price.mul(115).div(97);
    }
  }

  function calculatePoolCut (uint256 _price) public view returns (uint256 _poolCut) {
    if (_price < firstCap) {
      return _price.mul(10).div(100);  
    } else if (_price < secondCap) {
      return _price.mul(9).div(100);  
    } else if (_price < thirdCap) {
      return _price.mul(8).div(100);  
    } else {
      return _price.mul(7).div(100);  
    }
  }

   
  function purchaseCity(uint256 _tokenId) public 
    payable
    isNotContract(msg.sender)
  {

     
    City storage city = cityData[_tokenId];
    uint256 price = city.price;
    address oldOwner = city.owner;
    address newOwner = msg.sender;

     
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);

    uint256 excess = msg.value.sub(price);

     
    uint256 profit = price.sub(city.lastPrice);
    uint256 poolCut = calculatePoolCut(profit);
    poolTotal += poolCut;

     
    uint256 devCut = price.mul(3).div(100);
    devOwed = devOwed.add(devCut);

    transferCity(oldOwner, newOwner, _tokenId);

     
    city.lastPrice = price;
    city.price = getNextPrice(price);

     
    CityPurchased(_tokenId, newOwner, price);

     
    oldOwner.transfer(price.sub(devCut.add(poolCut)));

     
    uint256 countryId = _tokenId % COUNTRY_IDX;
    address countryOwner;
    (countryOwner,,,,) = countryContract.getCountryData(countryId);
    require (countryOwner != address(0));
    countryOwner.transfer(poolCut.mul(COUNTRY_PAYOUT).div(100));

     
    if (excess > 0) {
      newOwner.transfer(excess);
    }

     
    lastPurchase = now;

  }

   
  function transferCity(address _from, address _to, uint256 _tokenId) internal {

     
    require(tokenExists(_tokenId));

     
    require(cityData[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

     
    updateSinglePayout(_from, _tokenId);

     
    clearApproval(_from, _tokenId);

     
    removeToken(_from, _tokenId);

     
    cityData[_tokenId].owner = _to;
    addToken(_to, _tokenId);

    
    Transfer(_from, _to, _tokenId);
  }

   
  function withdraw() onlyOwner public {
    owner.transfer(devOwed);
    devOwed = 0;
  }

   
  function setPayout(uint256 _itemId, uint256 _newPayout) onlyOwner public {
    City storage city = cityData[_itemId];
    city.payout = _newPayout;
  }

   
  function updatePayout(address _owner) public {
    uint256[] memory cities = ownedTokens[_owner];
    uint256 owed;
    for (uint256 i = 0; i < cities.length; i++) {
        uint256 totalCityOwed = poolTotal * cityData[cities[i]].payout / 10000;
        uint256 cityOwed = totalCityOwed.sub(cityData[cities[i]].withdrawn);
        owed += cityOwed;
        
        cityData[cities[i]].withdrawn += cityOwed;
    }
    payoutBalances[_owner] += owed;
  }

   
  function updateSinglePayout(address _owner, uint256 _itemId) internal {
    uint256 totalCityOwed = poolTotal * cityData[_itemId].payout / 10000;
    uint256 cityOwed = totalCityOwed.sub(cityData[_itemId].withdrawn);
        
    cityData[_itemId].withdrawn += cityOwed;
    payoutBalances[_owner] += cityOwed;
  }

   
  function withdrawRent(address _owner) public {
      updatePayout(_owner);
      uint256 payout = payoutBalances[_owner];
      payoutBalances[_owner] = 0;
      _owner.transfer(payout);
  }

  function getRentOwed(address _owner) public view returns (uint256 owed) {
    updatePayout(_owner);
    return payoutBalances[_owner];
  }

   
  function getCityData (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _nextPrice, uint256 _payout, address _cOwner, uint256 _cPrice, uint256 _cPayout) 
  {
    City memory city = cityData[_tokenId];
    address countryOwner;
    uint256 countryPrice;
    uint256 countryPayout;
    (countryOwner,,countryPrice,,countryPayout) = countryContract.getCountryData(_tokenId % COUNTRY_IDX);
    return (city.owner, city.price, getNextPrice(city.price), city.payout, countryOwner, countryPrice, countryPayout);
  }

   
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return cityData[_tokenId].price > 0;
  }

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier isNotContract(address _buyer) {
    uint size;
    assembly { size := extcodesize(_buyer) }
    require(size == 0);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }
  
   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal isNotContract(_to) {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    updateSinglePayout(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }


     
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    cityData[_tokenId].owner = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }

  function name() public pure returns (string _name) {
    return "EtherCities.io City";
  }

  function symbol() public pure returns (string _symbol) {
    return "EC";
  }

}