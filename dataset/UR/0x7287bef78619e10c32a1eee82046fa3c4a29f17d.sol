 

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

contract CryptoPornSmartContract is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoPorn";  
  string public constant SYMBOL = "CryptoPornSmartContract";  

  uint256 private startingPrice = 0.01 ether;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

   

   
   
  mapping (uint256 => address) public personIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public personIndexToApproved;

 
  address public ceoAddress;
  
   
  address[4] public cooAddresses;

   
  struct Person {
    string name;
    uint256 sellingPrice;
  }

  Person[] private persons;

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }
  
   
  modifier onlyCLevel() {
    require(msg.sender == ceoAddress ||
        msg.sender == cooAddresses[0] ||
        msg.sender == cooAddresses[1] ||
        msg.sender == cooAddresses[2] ||
        msg.sender == cooAddresses[3]);
    _;
  }
  
   
  function CryptoPornSmartContract() public {
    ceoAddress = msg.sender;
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

   
  function createNewPerson(address _owner, string _name, uint256 _factor) public onlyCLevel {
    address personOwner = _owner;
    uint256 price = startingPrice;
    if (!_addressNotNull(personOwner)) {
      personOwner = address(this);
    }

    if (_factor > 0) {
      price = price * _factor;
    }

    _createPerson(_name, personOwner, price);
  }

   
   
  function getPerson(uint256 _tokenId) public view returns (
    string personName,
    uint256 sellingPrice,
    address owner
  ) {
    Person storage person = persons[_tokenId];
    personName = person.name;
    sellingPrice = person.sellingPrice;
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

  function payout() public onlyCLevel {
    _payout();
  }

   
  function purchase(uint256 _tokenId) public payable {
    Person storage person = persons[_tokenId];
    uint256 oldSellintPrice = person.sellingPrice;
    address oldOwner = personIndexToOwner[_tokenId];
    address newOwner = msg.sender;

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= person.sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(person.sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, person.sellingPrice);

     
    if (person.sellingPrice < firstStepLimit) {
       
      person.sellingPrice = SafeMath.div(SafeMath.mul(person.sellingPrice, 200), 94);
    } else if (person.sellingPrice < secondStepLimit) {
       
      person.sellingPrice = SafeMath.div(SafeMath.mul(person.sellingPrice, 120), 94);
    } else {
       
      person.sellingPrice = SafeMath.div(SafeMath.mul(person.sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, oldSellintPrice, person.sellingPrice, oldOwner, newOwner, persons[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return persons[_tokenId].sellingPrice;
  }

   
   
   
   
   
  function setCOO(address _newCOO1, address _newCOO2, address _newCOO3, address _newCOO4) public onlyCEO {
    cooAddresses[0] = _newCOO1;
    cooAddresses[1] = _newCOO2;
    cooAddresses[2] = _newCOO3;
    cooAddresses[3] = _newCOO4;
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
      name: _name,
      sellingPrice: _price
    });
    uint256 newPersonId = persons.push(_person) - 1;

     
     
    require(newPersonId == uint256(uint32(newPersonId)));

    Birth(newPersonId, _name, _owner);

     
     
    _transfer(address(0), _owner, newPersonId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == personIndexToOwner[_tokenId];
  }

   
  function _payout() private {
    uint256 amount = SafeMath.div(this.balance, 4);
    cooAddresses[0].transfer(amount);
    cooAddresses[1].transfer(amount);
    cooAddresses[2].transfer(amount);
    cooAddresses[3].transfer(amount);
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    personIndexToOwner[_tokenId] = _to;

     
    if (_addressNotNull(_from)) {
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