 

pragma solidity ^0.4.20;  



 
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


contract AVStarsToken is ERC721 {
  using SafeMath for uint256;
   

   
  event Birth(
    uint256 tokenId, 
    string name, 
    uint64 satisfaction,
    uint64 cooldownTime,
    string slogan,
    address owner);

   
  event TokenSold(
    uint256 tokenId, 
    uint256 oldPrice, 
    uint256 newPrice, 
    address prevOwner, 
    address winner, 
    string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

  event MoreActivity(uint256 tokenId, address Owner, uint64 startTime, uint64 cooldownTime, uint256 _type);
  event ChangeSlogan(string slogan);

   

   
  string public constant NAME = "AVStars";  
  string public constant SYMBOL = "AVS";  

  uint256 private startingPrice = 0.3 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 30000;
  uint256 private firstStepLimit =  1.6 ether;
   

   
   
  mapping (uint256 => address) public personIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public personIndexToApproved;

   
  mapping (uint256 => uint256) private personIndexToPrice;


   
  address public ceoAddress;
  address public cooAddress;
  uint256 public promoCreatedCount;
  bool isPaused;
    

   
  struct Person {
    string name;
    uint256 satisfaction;
    uint64 cooldownTime;
    string slogan;
    uint256 basePrice;
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

   
  function AVStarsToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    isPaused = false;
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

   
  function createPromoPerson(
    address _owner, 
    string _name, 
    uint64 _satisfaction,
    uint64 _cooldownTime,
    string _slogan,
    uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address personOwner = _owner;
    if (personOwner == address(0)) {
      personOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createPerson(
      _name, 
      _satisfaction,
      _cooldownTime,
      _slogan,
      personOwner, 
      _price);
  }

   
  function createContractPerson(string _name) public onlyCOO {
    _createPerson(
      _name,
      0,
      uint64(now),
      "", 
      address(this), 
      startingPrice);
  }

   
   
  function getPerson(uint256 _tokenId) public view returns (
    string personName,
    uint64 satisfaction,
    uint64 cooldownTime,
    string slogan,
    uint256 basePrice,
    uint256 sellingPrice,
    address owner
  ) {
    Person storage person = persons[_tokenId];
    personName = person.name;
    satisfaction = uint64(person.satisfaction);
    cooldownTime = uint64(person.cooldownTime);
    slogan = person.slogan;
    basePrice = person.basePrice;
    sellingPrice = personIndexToPrice[_tokenId];
    owner = personIndexToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

   
  function pauseGame() public onlyCLevel {
      isPaused = true;
  }
  function unPauseGame() public onlyCLevel {
      isPaused = false;
  }
  function GetIsPauded() public view returns(bool) {
     return(isPaused);
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
    require(isPaused == false);
    address oldOwner = personIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = personIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);
    require(_addressNotNull(newOwner));
    require(msg.value >= sellingPrice);

    Person storage person = persons[_tokenId];
    require(person.cooldownTime<uint64(now));
    uint256 payment = sellingPrice.mul(95).div(100);
    uint256 devCut = msg.value.sub(payment);

     
    if (sellingPrice < firstStepLimit) {
       
      person.basePrice = personIndexToPrice[_tokenId];
      personIndexToPrice[_tokenId] = sellingPrice.mul(300).div(200);
      
    } else {
       
      person.satisfaction = person.satisfaction.mul(50).div(100);
      person.basePrice = personIndexToPrice[_tokenId];
      personIndexToPrice[_tokenId] = sellingPrice.mul(120).div(100);
      person.cooldownTime = uint64(now + 15 minutes);
    }

    _transfer(oldOwner, newOwner, _tokenId);
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); 
    }
    ceoAddress.transfer(devCut);
    TokenSold(_tokenId, sellingPrice, personIndexToPrice[_tokenId], oldOwner, newOwner, persons[_tokenId].name);
  }

  function activity(uint256 _tokenId, uint256 _type) public payable {
    require(isPaused == false);
    require(personIndexToOwner[_tokenId] == msg.sender);
    require(personIndexToPrice[_tokenId] >= 2000000000000000000);
    require(_type <= 2);
    uint256 _hours;

     
    if ( _type == 0 ) {
      _hours = 6;
    } else if (_type == 1) {
      _hours = 12;
    } else {
      _hours = 48;
    }

    uint256 payment = personIndexToPrice[_tokenId].div(80).mul(_hours);
    require(msg.value >= payment);
    uint64 startTime;

    Person storage person = persons[_tokenId];
    
    person.satisfaction += _hours.mul(1);
    if (person.satisfaction > 100) {
      person.satisfaction = 100;
    }
    uint256 newPrice;
    person.basePrice = person.basePrice.add(payment);
    newPrice = person.basePrice.mul(120+uint256(person.satisfaction)).div(100);
    personIndexToPrice[_tokenId] = newPrice;
    if (person.cooldownTime > now) {
      startTime = person.cooldownTime;
      person.cooldownTime = startTime +  uint64(_hours) * 1 hours;
      
    } else {
      startTime = uint64(now);
      person.cooldownTime = startTime+ uint64(_hours) * 1 hours;
    }
    ceoAddress.transfer(msg.value);
    MoreActivity(_tokenId, msg.sender, startTime, person.cooldownTime, _type);
  }

  function modifySlogan(uint256 _tokenId, string _slogan) public payable {
    require(personIndexToOwner[_tokenId]==msg.sender);
    Person storage person = persons[_tokenId];
    person.slogan = _slogan;
    msg.sender.transfer(msg.value);
    ChangeSlogan(person.slogan);
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

   
  function _createPerson(
    string _name,     
    uint64 _satisfaction,
    uint64 _cooldownTime,
    string _slogan,
    address _owner, 
    uint256 _basePrice) private {
    Person memory _person = Person({
      name: _name,
      satisfaction: _satisfaction,
      cooldownTime: _cooldownTime,
      slogan:_slogan,
      basePrice:_basePrice
    });
    uint256 newPersonId = persons.push(_person) - 1;

     
     
    require(newPersonId == uint256(uint32(newPersonId)));

    Birth(
      newPersonId, 
      _name, 
      _satisfaction,
      _cooldownTime,
      _slogan,
      _owner);

    personIndexToPrice[newPersonId] = _basePrice;

     
     
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