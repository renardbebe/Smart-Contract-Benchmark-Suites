 

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

contract CryptoAllStars is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoAllStars";  
  string public constant SYMBOL = "AllStarToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 10000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint public currentGen = 0;

   

   
   
  mapping (uint256 => address) public allStarIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public allStarIndexToApproved;

   
  mapping (uint256 => uint256) private allStarIndexToPrice;

   
  address public ceo = 0x047F606fD5b2BaA5f5C6c4aB8958E45CB6B054B7;
  address public cfo = 0xed8eFE0C11E7f13Be0B9d2CD5A675095739664d6;

  uint256 public promoCreatedCount;

   
  struct AllStar {
    string name;
    uint gen;
  }

  AllStar[] private allStars;

   
   
  modifier onlyCeo() {
    require(msg.sender == ceo);
    _;
  }

  modifier onlyManagement() {
    require(msg.sender == ceo || msg.sender == cfo);
    _;
  }

   
  function evolveGeneration(uint _newGen) public onlyManagement {
    currentGen = _newGen;
  }
 
   
   
   
   

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    allStarIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createPromoAllStar(address _owner, string _name, uint256 _price) public onlyCeo {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address allStarOwner = _owner;
    if (allStarOwner == address(0)) {
      allStarOwner = ceo;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createAllStar(_name, allStarOwner, _price);
  }

   
  function createContractAllStar(string _name) public onlyCeo {
    _createAllStar(_name, msg.sender, startingPrice );
  }

   
   
  function getAllStar(uint256 _tokenId) public view returns (
    string allStarName,
    uint allStarGen,
    uint256 sellingPrice,
    address owner
  ) {
    AllStar storage allStar = allStars[_tokenId];
    allStarName = allStar.name;
    allStarGen = allStar.gen;
    sellingPrice = allStarIndexToPrice[_tokenId];
    owner = allStarIndexToOwner[_tokenId];
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
    owner = allStarIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout() public onlyManagement {
    _payout();
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = allStarIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = allStarIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 92), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      allStarIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
   } else {
       
      allStarIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, allStarIndexToPrice[_tokenId], oldOwner, newOwner, allStars[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return allStarIndexToPrice[_tokenId];
  }

   
   
  function setOwner(address _newOwner) public onlyCeo {
    require(_newOwner != address(0));

    ceo = _newOwner;
  }

   function setCFO(address _newCFO) public onlyCeo {
    require(_newCFO != address(0));

    cfo = _newCFO;
  }


   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = allStarIndexToOwner[_tokenId];

     
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
      uint256 totalAllStars = totalSupply();
      uint256 resultIndex = 0;

      uint256 allStarId;
      for (allStarId = 0; allStarId <= totalAllStars; allStarId++) {
        if (allStarIndexToOwner[allStarId] == _owner) {
          result[resultIndex] = allStarId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return allStars.length;
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
    return allStarIndexToApproved[_tokenId] == _to;
  }

   
  function _createAllStar(string _name, address _owner, uint256 _price) private {
    AllStar memory _allStar = AllStar({
      name: _name,
      gen: currentGen
    });
    uint256 newAllStarId = allStars.push(_allStar) - 1;

     
     
    require(newAllStarId == uint256(uint32(newAllStarId)));

    Birth(newAllStarId, _name, _owner);

    allStarIndexToPrice[newAllStarId] = _price;

     
     
    _transfer(address(0), _owner, newAllStarId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == allStarIndexToOwner[_tokenId];
  }

   
  function _payout() private {
      uint blnc = this.balance;
      ceo.transfer(SafeMath.div(SafeMath.mul(blnc, 75), 100));
      cfo.transfer(SafeMath.div(SafeMath.mul(blnc, 25), 100));
    
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    allStarIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete allStarIndexToApproved[_tokenId];
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