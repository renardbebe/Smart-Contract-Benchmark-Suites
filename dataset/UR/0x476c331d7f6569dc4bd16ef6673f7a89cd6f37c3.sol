 

pragma solidity ^0.4.18;  

 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public view returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}


contract PoliticianToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
   
  event ContractUpgrade(address newContract);

   

   
  string public constant NAME = "CryptoPoliticians";  
  string public constant SYMBOL = "POLITICIAN";  
  bool private erc721Enabled = false;
  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;
  uint256 private thirdStepLimit = 2.0 ether;

   

   
   
  mapping (uint256 => address) public politicianIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public politicianIndexToApproved;

   
  mapping (uint256 => uint256) private politicianIndexToPrice;


   
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

   
  struct Politician {

     
    string name;

  }

  Politician[] private politicians;

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  modifier onlyERC721() {
    require(erc721Enabled);
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

   
  function PoliticianToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public onlyERC721 {
     
    require(_owns(msg.sender, _tokenId));

    politicianIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoPolitician(address _owner, string _name, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address politicianOwner = _owner;

    if (politicianOwner == address(0)) {
      politicianOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createPolitician(_name, politicianOwner, _price);
  }

   
  function createContractPolitician(string _name) public onlyCOO {
    _createPolitician(_name, address(this), startingPrice);
  }

   
   
  function getPolitician(uint256 _tokenId) public view returns (
    string politicianName,
    uint256 sellingPrice,
    address owner
  ) {
    Politician storage politician = politicians[_tokenId];
    politicianName = politician.name;
    sellingPrice = politicianIndexToPrice[_tokenId];
    owner = politicianIndexToOwner[_tokenId];
  }

  function changePoliticianName(uint256 _tokenId, string _name) public onlyCOO {
    require(_tokenId < politicians.length);
    politicians[_tokenId].name = _name;
  }

   
  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = politicianIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  function withdrawFunds(address _to, uint256 amount) public onlyCLevel {
    _withdrawFunds(_to, amount);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = politicianIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = politicianIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      politicianIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
       
      politicianIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 94);
    } else if (sellingPrice < thirdStepLimit) {
       
      politicianIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 94);
    } else {
       
      politicianIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, politicianIndexToPrice[_tokenId], oldOwner, newOwner,
      politicians[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return politicianIndexToPrice[_tokenId];
  }

   
  function enableERC721() public onlyCEO {
    erc721Enabled = true;
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
   
  function setCOO(address _newCOO) public onlyCOO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = politicianIndexToOwner[_tokenId];

     
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
      uint256 totalPoliticians = totalSupply();
      uint256 resultIndex = 0;

      uint256 politicianId;
      for (politicianId = 0; politicianId <= totalPoliticians; politicianId++) {
        if (politicianIndexToOwner[politicianId] == _owner) {
          result[resultIndex] = politicianId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return politicians.length;
  }

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public onlyERC721 {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public onlyERC721 {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return politicianIndexToApproved[_tokenId] == _to;
  }

   
  function _createPolitician(string _name, address _owner, uint256 _price) private {
    Politician memory _politician = Politician({
      name: _name
    });
    uint256 newPoliticianId = politicians.push(_politician) - 1;

     
     
    require(newPoliticianId == uint256(uint32(newPoliticianId)));

    Birth(newPoliticianId, _name, _owner);

    politicianIndexToPrice[newPoliticianId] = _price;

     
     
    _transfer(address(0), _owner, newPoliticianId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == politicianIndexToOwner[_tokenId];
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
     
    politicianIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete politicianIndexToApproved[_tokenId];
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