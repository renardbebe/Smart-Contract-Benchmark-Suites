 

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

 
contract EtherPizza is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
  uint256 private startingPrice = 0.001 ether;

   
  string public constant NAME = "CrypoPizzas";  
  string public constant SYMBOL = "CryptoPizza";  

   

   
   
  mapping (uint256 => address) public pizzaIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public pizzaIndexToApproved;

   
  mapping (uint256 => uint256) private pizzaIndexToPrice;

   
   
  mapping (uint256 => uint256) private pizzaIndexToPreviousPrice;

   
  mapping (uint256 => address[5]) private pizzaIndexToPreviousOwners;


   
  address public ceoAddress;
  address public cooAddress;

   
  struct Pizza {
    string name;
  }

  Pizza[] private pizzas;

   
   
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

   
  function EtherPizza() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    pizzaIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createContractPizza(string _name) public onlyCOO {
    _createPizza(_name, address(this), startingPrice);
  }

   
   
  function getPizza(uint256 _tokenId) public view returns (
    string pizzaName,
    uint256 sellingPrice,
    address owner,
    uint256 previousPrice,
    address[5] previousOwners
  ) {
    Pizza storage pizza = pizzas[_tokenId];
    pizzaName = pizza.name;
    sellingPrice = pizzaIndexToPrice[_tokenId];
    owner = pizzaIndexToOwner[_tokenId];
    previousPrice = pizzaIndexToPreviousPrice[_tokenId];
    previousOwners = pizzaIndexToPreviousOwners[_tokenId];
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
    owner = pizzaIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = pizzaIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    address[5] storage previousOwners = pizzaIndexToPreviousOwners[_tokenId];

    uint256 sellingPrice = pizzaIndexToPrice[_tokenId];
    uint256 previousPrice = pizzaIndexToPreviousPrice[_tokenId];
     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 priceDelta = SafeMath.sub(sellingPrice, previousPrice);
    uint256 ownerPayout = SafeMath.add(previousPrice, SafeMath.mul(SafeMath.div(priceDelta, 100), 40));


    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    pizzaIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 100);
    pizzaIndexToPreviousPrice[_tokenId] = sellingPrice;

    uint256 strangePrice = uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10));


     
     
    if (oldOwner != address(this)) {
       
      oldOwner.transfer(ownerPayout);
    } else {
      strangePrice = SafeMath.add(ownerPayout, strangePrice);
    }

     
    for (uint i = 0; i < 5; i++) {
        if (previousOwners[i] != address(this)) {
            previousOwners[i].transfer(uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10)));
        } else {
            strangePrice = SafeMath.add(strangePrice, uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10)));
        }
    }
    ceoAddress.transfer(strangePrice);

    _transfer(oldOwner, newOwner, _tokenId);

     

    msg.sender.transfer(purchaseExcess);
  }






  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return pizzaIndexToPrice[_tokenId];
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
    address oldOwner = pizzaIndexToOwner[_tokenId];

     
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
      uint256 totalPizzas = totalSupply();
      uint256 resultIndex = 0;
      uint256 pizzaId;
      for (pizzaId = 0; pizzaId <= totalPizzas; pizzaId++) {
        if (pizzaIndexToOwner[pizzaId] == _owner) {
          result[resultIndex] = pizzaId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return pizzas.length;
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
    return pizzaIndexToApproved[_tokenId] == _to;
  }

   
  function _createPizza(string _name, address _owner, uint256 _price) private {
    Pizza memory _pizza = Pizza({
      name: _name
    });
    uint256 newPizzaId = pizzas.push(_pizza) - 1;

     
     
    require(newPizzaId == uint256(uint32(newPizzaId)));

    Birth(newPizzaId, _name, _owner);

    pizzaIndexToPrice[newPizzaId] = _price;
    pizzaIndexToPreviousPrice[newPizzaId] = 0;
    pizzaIndexToPreviousOwners[newPizzaId] =
        [address(this), address(this), address(this), address(this)];

     
     
    _transfer(address(0), _owner, newPizzaId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == pizzaIndexToOwner[_tokenId];
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
     
    pizzaIndexToOwner[_tokenId] = _to;
     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete pizzaIndexToApproved[_tokenId];
    }
     
    pizzaIndexToPreviousOwners[_tokenId][4]=pizzaIndexToPreviousOwners[_tokenId][3];
    pizzaIndexToPreviousOwners[_tokenId][3]=pizzaIndexToPreviousOwners[_tokenId][2];
    pizzaIndexToPreviousOwners[_tokenId][2]=pizzaIndexToPreviousOwners[_tokenId][1];
    pizzaIndexToPreviousOwners[_tokenId][1]=pizzaIndexToPreviousOwners[_tokenId][0];
     
    if (_from != address(0)) {
        pizzaIndexToPreviousOwners[_tokenId][0]=_from;
    } else {
        pizzaIndexToPreviousOwners[_tokenId][0]=address(this);
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