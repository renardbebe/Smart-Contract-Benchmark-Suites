 

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


contract PlaceToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoPlaces";
  string public constant SYMBOL = "PlaceToken";

  uint256 private startingPrice = 0.01 ether;
  uint256 private firstStepLimit =  0.8 ether;
  uint256 private secondStepLimit = 12 ether;

   

   
   
  mapping (uint256 => address) public placeIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public placeIndexToApproved;

   
  mapping (uint256 => uint256) private placeIndexToPrice;

   
  address public ceoAddress;

   
  struct Place {
    string name;
    string country;
    string owner_name;
  }

  Place[] private places;

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  function PlaceToken() public {
    ceoAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    placeIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  function createContractPlace(string _name, string _country) public onlyCEO {
    _createPlace(_name, _country, address(this), startingPrice);
  }

   
   
  function getPlace(uint256 _tokenId) public view returns (
    string placeName,
    string placeCountry,
    string placeOwnerName,
    uint256 sellingPrice,
    address owner
  ) {
    Place storage place = places[_tokenId];
    placeName = place.name;
    placeCountry = place.country;
    placeOwnerName = place.owner_name;
    sellingPrice = placeIndexToPrice[_tokenId];
    owner = placeIndexToOwner[_tokenId];
  }

  function setStartingPrice(uint256 _newStartingPrice) public onlyCEO {
    startingPrice = SafeMath.mul(_newStartingPrice, 1000000000000000000);
  }

  function getStartingPrice() public view returns (uint256) {
    return startingPrice;
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
    owner = placeIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCEO {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = placeIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = placeIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 90), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      placeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 90);
    } else if (sellingPrice < secondStepLimit) {
       
      placeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 130), 90);
    } else {
       
      placeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 90);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

    TokenSold(_tokenId, sellingPrice, placeIndexToPrice[_tokenId], oldOwner, newOwner, places[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return placeIndexToPrice[_tokenId];
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = placeIndexToOwner[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return places.length;
  }

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

  function setOwnerName(uint256 _tokenId, string _newName) public {
    require(_owns(msg.sender, _tokenId));

    Place storage place = places[_tokenId];
    place.owner_name = _newName;
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
    return placeIndexToApproved[_tokenId] == _to;
  }

   
  function _createPlace(string _name, string _country, address _owner, uint256 _price) private {
    Place memory _place = Place({
      name: _name,
      country: _country,
      owner_name: "None"
    });
    uint256 newPlaceId = places.push(_place) - 1;

     
     
    require(newPlaceId == uint256(uint32(newPlaceId)));

    Birth(newPlaceId, _name, _owner);

    placeIndexToPrice[newPlaceId] = _price;

     
     
    _transfer(address(0), _owner, newPlaceId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == placeIndexToOwner[_tokenId];
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
     
    placeIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete placeIndexToApproved[_tokenId];
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