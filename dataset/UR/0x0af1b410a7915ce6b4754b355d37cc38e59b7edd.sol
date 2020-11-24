 

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


contract AthleteToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoAthletes";  
  string public constant SYMBOL = "AthleteToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit = 0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;
  uint256 private thirdStepLimit = 5 ether;

   

   
  mapping (uint256 => address) public athleteIdToOwner;

   
  mapping (address => uint256) private ownershipTokenCount;

   
   
  mapping (uint256 => address) public athleteIdToApproved;

   
  mapping (uint256 => uint256) private athleteIdToPrice;

   
  address public roleAdminAddress;
  address public roleEditorAddress;

  uint256 public promoCreatedCount;

   
  struct Athlete {
    string name;
  }

  Athlete[] private athletes;

   
  
   
  modifier onlyAdmin() {
    require(msg.sender == roleAdminAddress);
    _;
  }

   
  modifier onlyEditor() {
    require(msg.sender == roleEditorAddress);
    _;
  }

   
  modifier onlyTeamLevel() {
    require(
      msg.sender == roleAdminAddress ||
      msg.sender == roleEditorAddress
    );
    _;
  }

   

  function AthleteToken() public {
    roleAdminAddress = msg.sender;
    roleEditorAddress = msg.sender;
  }

   

   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    athleteIdToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createAssignedAthlete(address _owner, string _name, uint256 _price) public onlyEditor {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address athleteOwner = _owner;
    if (athleteOwner == address(0)) {
      athleteOwner = roleEditorAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createAthlete(_name, athleteOwner, _price);
  }

   
  function createContractAthlete(string _name) public onlyEditor {
    _createAthlete(_name, address(this), startingPrice);
  }

   
   
  function getAthlete(uint256 _tokenId) public view returns (
    string athleteName,
    uint256 sellingPrice,
    address owner
  ) {
    Athlete storage athlete = athletes[_tokenId];
    athleteName = athlete.name;
    sellingPrice = athleteIdToPrice[_tokenId];
    owner = athleteIdToOwner[_tokenId];
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
    owner = athleteIdToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyTeamLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = athleteIdToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = athleteIdToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      athleteIdToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
       
      athleteIdToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
       
      athleteIdToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, athleteIdToPrice[_tokenId], oldOwner, newOwner, athletes[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return athleteIdToPrice[_tokenId];
  }

   
   
  function setAdmin(address _newAdmin) public onlyAdmin {
    require(_newAdmin != address(0));
    roleAdminAddress = _newAdmin;
  }

   
   
  function setEditor(address _newEditor) public onlyAdmin {
    require(_newEditor != address(0));
    roleEditorAddress = _newEditor;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = athleteIdToOwner[_tokenId];

     
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
      uint256 totalAthletes = totalSupply();
      uint256 resultIndex = 0;

      uint256 athleteId;
      for (athleteId = 0; athleteId <= totalAthletes; athleteId++) {
        if (athleteIdToOwner[athleteId] == _owner) {
          result[resultIndex] = athleteId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return athletes.length;
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
    return athleteIdToApproved[_tokenId] == _to;
  }

   
  function _createAthlete(string _name, address _owner, uint256 _price) private {
    Athlete memory _athlete = Athlete({
      name: _name
    });
    uint256 newAthleteId = athletes.push(_athlete) - 1;

     
     
    require(newAthleteId == uint256(uint32(newAthleteId)));

    Birth(newAthleteId, _name, _owner);

    athleteIdToPrice[newAthleteId] = _price;

     
     
    _transfer(address(0), _owner, newAthleteId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == athleteIdToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      roleAdminAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    athleteIdToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete athleteIdToApproved[_tokenId];
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