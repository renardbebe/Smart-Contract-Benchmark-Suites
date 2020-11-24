 

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

contract SuperHeroeToken is ERC721 {
 
   
 
   
  event Birth(uint256 tokenId, string name, address owner);
 
   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
 
   
   
  event Transfer(address from, address to, uint256 tokenId);
 
   
 
   
  string public constant NAME = "EtherSuperHeroe";  
  string public constant SYMBOL = "SHT";  
 
  uint256 private startingPrice = 0.05 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 100;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;
 
   
 
   
   
  mapping (uint256 => address) public personIndexToOwner;
 
   
   
  mapping (address => uint256) private ownershipTokenCount;
 
   
   
   
  mapping (uint256 => address) public personIndexToApproved;
 
   
  mapping (uint256 => uint256) private personIndexToPrice;
 
   
  address public ceoAddress;
  address public cooAddress;
 
  uint256 public promoCreatedCount;
 
   
  struct Person {
    string name;    
  }
 
  Person[] private persons;
 
   
   
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
 
   
  function SuperHeroeToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }
 
   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));
 
    personIndexToApproved[_tokenId] = _to;
 
    Approval(msg.sender, _to, _tokenId);
  }
 
   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoPerson(address _owner, string _name, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);
 
    address personOwner = _owner;
    if (personOwner == address(0)) {
      personOwner = cooAddress;
    }
 
    if (_price <= 0) {
      _price = startingPrice;
    }
 
    promoCreatedCount++;
    _createPerson(_name, personOwner, _price);
  }
 
   
  function createContractPerson(string _name, uint256 _price) public onlyCOO {
    if (_price <= 0) {
      _price = startingPrice;
    }    
    _createPerson(_name, address(this), _price);
  }
 
   
   
  function getPerson(uint256 _tokenId) public view returns (
    string personName,
    uint256 sellingPrice,
    address owner
  ) {
    Person storage person = persons[_tokenId];
    personName = person.name;
    sellingPrice = personIndexToPrice[_tokenId];
    owner = personIndexToOwner[_tokenId];
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
    owner = personIndexToOwner[_tokenId];
    require(owner != address(0));
  }
 
  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }
 
   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = personIndexToOwner[_tokenId];
    address newOwner = msg.sender;
 
    uint256 sellingPrice = personIndexToPrice[_tokenId];
 
     
    require(oldOwner != newOwner);
 
     
    require(_addressNotNull(newOwner));
 
     
    require(msg.value >= sellingPrice);
 
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
 
     
    if (sellingPrice < firstStepLimit) {
       
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
       
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
       
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }
 
    _transfer(oldOwner, newOwner, _tokenId);
 
     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }
 
    TokenSold(_tokenId, sellingPrice, personIndexToPrice[_tokenId], oldOwner, newOwner, persons[_tokenId].name);
 
    msg.sender.transfer(purchaseExcess);
  }
 
  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return personIndexToPrice[_tokenId];
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
    address oldOwner = personIndexToOwner[_tokenId];
 
     
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
      uint256 totalPersons = totalSupply();
      uint256 resultIndex = 0;
 
      uint256 personId;
      for (personId = 0; personId <= totalPersons; personId++) {
        if (personIndexToOwner[personId] == _owner) {
          result[resultIndex] = personId;
          resultIndex++;
        }
      }
      return result;
    }
  }
 
   
   
  function totalSupply() public view returns (uint256 total) {
    return persons.length;
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
    return personIndexToApproved[_tokenId] == _to;
  }
 
   
  function _createPerson(string _name, address _owner, uint256 _price) private {
    Person memory _person = Person({
      name: _name
    });
    uint256 newPersonId = persons.push(_person) - 1;
 
     
     
    require(newPersonId == uint256(uint32(newPersonId)));
 
    Birth(newPersonId, _name, _owner);
 
    personIndexToPrice[newPersonId] = _price;
 
     
     
    _transfer(address(0), _owner, newPersonId);
  }
 
   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == personIndexToOwner[_tokenId];
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
     
    personIndexToOwner[_tokenId] = _to;
 
     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete personIndexToApproved[_tokenId];
    }
 
     
    Transfer(_from, _to, _tokenId);
  }
}