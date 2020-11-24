 

pragma solidity ^0.4.18;

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

contract CryptoNFT is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
  uint256 internal startingPrice = 0.01 ether;

   
   

   
   
  mapping (uint256 => address) public personIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public personIndexToApproved;

   
  mapping (uint256 => uint256) internal personIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

   
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

   
  function CryptoNFT() public {
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

  

   
  function createContractPerson(string _name) public onlyCOO {
    _createPerson(_name, address(this), startingPrice);
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


   
   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = personIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCEO {
    _payout(_to, this.balance);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = personIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = personIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = calcPaymentToOldOwner(sellingPrice);
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    personIndexToPrice[_tokenId] = calcNextSellingPrice(sellingPrice);

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, personIndexToPrice[_tokenId], oldOwner, newOwner, persons[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function calcPaymentToOldOwner(uint256 sellingPrice) internal returns (uint256 payToOldOwner);
  function calcNextSellingPrice(uint256 currentSellingPrice) internal returns (uint256 newSellingPrice);

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

   
  function _createPerson(string _name, address _owner, uint256 _price) internal {
    Person memory _person = Person({
      name: _name
    });
    uint256 newPersonId = persons.push(_person) - 1;

     
     
    require(newPersonId == uint256(uint32(newPersonId)));

    Birth(newPersonId, _name, _owner);

    personIndexToPrice[newPersonId] = _price;

     
     
    _transfer(address(0), _owner, newPersonId);
  }

   
  function _owns(address claimant, uint256 _tokenId) internal view returns (bool) {
    return claimant == personIndexToOwner[_tokenId];
  }

   
  function _payout(address _to, uint256 amount) internal {
    require(amount<=this.balance);
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
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

contract EtherAthlete is CryptoNFT {
     
    string public constant NAME = "EtherAthlete";  
    string public constant SYMBOL = "EAT";  

    uint256 private constant PROMO_CREATION_LIMIT = 5000;
    uint256 public promoCreatedCount;

    bool public allowPriceUpdate;

     
    uint256 private firstStepLimit =  0.32 ether;
    uint256 private secondStepLimit = 2.8629151 ether;

    uint256 private defaultIncreasePercent = 200;
    uint256 private fsIncreasePercent = 155;
    uint256 private ssIncreasePercent = 130;

    uint256 private defaultPlayerPercent = 7500;
    uint256 private fsPlayerPercent = 8400;
    uint256 private ssPlayerPercent = 9077;

     
    address public charityAddress;
    uint256 private charityPercent = 3;
    uint256 public charityBalance;


     
    function EtherAthlete() public {
        allowPriceUpdate = false;
        charityAddress = msg.sender;
        charityBalance = 0 ether;
    }
    
     

     
    function name() public pure returns (string) {
        return NAME;
    }
     
    function symbol() public pure returns (string) {
        return SYMBOL;
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

    function setAllowPriceUpdate(bool _bValue) public onlyCOO {
        allowPriceUpdate = _bValue;
    }

     
     
     
    function calcPaymentToOldOwner(uint256 sellingPrice) internal returns (uint256 payToOldOwner) {
        if (sellingPrice <= firstStepLimit) {
             
            payToOldOwner = uint256(SafeMath.div(SafeMath.mul(sellingPrice, defaultPlayerPercent),10000));
        } else if (sellingPrice <= secondStepLimit) {
             
            payToOldOwner = uint256(SafeMath.div(SafeMath.mul(sellingPrice, fsPlayerPercent),10000));
        } else {
             
            payToOldOwner = uint256(SafeMath.div(SafeMath.mul(sellingPrice, ssPlayerPercent),10000));
        }

         
        uint256 gainToHouse = SafeMath.sub(sellingPrice, payToOldOwner);
        charityBalance = SafeMath.add(charityBalance, SafeMath.div(SafeMath.mul(gainToHouse, charityPercent),100));
    }

     
     
    function calcNextSellingPrice(uint256 currentSellingPrice) internal returns (uint256 newSellingPrice) {
        if (currentSellingPrice < firstStepLimit) {
             
            newSellingPrice = SafeMath.div(SafeMath.mul(currentSellingPrice, defaultIncreasePercent), 100);
        } else if (currentSellingPrice < secondStepLimit) {
             
            newSellingPrice = SafeMath.div(SafeMath.mul(currentSellingPrice, fsIncreasePercent), 100);
        } else {
             
            newSellingPrice = SafeMath.div(SafeMath.mul(currentSellingPrice, ssIncreasePercent), 100);
        }
    }

    function setCharityAddress(address _charityAddress) public onlyCEO {
        charityAddress = _charityAddress;
    }

    function payout(address _to) public onlyCEO {
        uint256 amountToCharity = charityBalance;
        uint256 amount = SafeMath.sub(this.balance, charityBalance);
        charityBalance = 0;
        _payout(charityAddress, amountToCharity);
        _payout(_to, amount);
    }

    function updateTokenSellingPrice(uint256 _tokenId, uint256 sellingPrice) public {
        require(allowPriceUpdate);
        require(_owns(msg.sender, _tokenId));
        require(sellingPrice < personIndexToPrice[_tokenId]);
        require(sellingPrice >= startingPrice);
        personIndexToPrice[_tokenId] = sellingPrice;
    }
}