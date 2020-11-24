 

 
 
 

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
  function approve(address _to, uint _celebId) public;
  function balanceOf(address _owner) public view returns (uint balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint _celebId) public view returns (address addr);
  function takeOwnership(uint _celebId) public;
  function totalSupply() public view returns (uint total);
  function transferFrom(address _from, address _to, uint _celebId) public;
  function transfer(address _to, uint _celebId) public;

  event Transfer(address indexed from, address indexed to, uint celebId);
  event Approval(address indexed owner, address indexed approved, uint celebId);
}

contract KpopCeleb is ERC721 {
  using SafeMath for uint;

  address public author;
  address public coauthor;

  string public constant NAME = "KpopCeleb";
  string public constant SYMBOL = "KpopCeleb";

  uint public GROWTH_BUMP = 0.5 ether;
  uint public MIN_STARTING_PRICE = 0.002 ether;
  uint public PRICE_INCREASE_SCALE = 120;  

  struct Celeb {
    string name;
  }

  Celeb[] public celebs;

  mapping(uint => address) public celebIdToOwner;
  mapping(uint => uint) public celebIdToPrice;  
  mapping(address => uint) public userToNumCelebs;
  mapping(uint => address) public celebIdToApprovedRecipient;
  mapping(uint => uint[6]) public celebIdToTraitValues;
  mapping(uint => uint[6]) public celebIdToTraitBoosters;

  address public KPOP_ARENA_CONTRACT_ADDRESS = 0x0;

  event Transfer(address indexed from, address indexed to, uint celebId);
  event Approval(address indexed owner, address indexed approved, uint celebId);
  event CelebSold(uint celebId, uint oldPrice, uint newPrice, string celebName, address prevOwner, address newOwner);

  function KpopCeleb() public {
    author = msg.sender;
    coauthor = msg.sender;
  }

  function _transfer(address _from, address _to, uint _celebId) private {
    require(ownerOf(_celebId) == _from);
    require(!isNullAddress(_to));
    require(balanceOf(_from) > 0);

    uint prevBalances = balanceOf(_from) + balanceOf(_to);
    celebIdToOwner[_celebId] = _to;
    userToNumCelebs[_from]--;
    userToNumCelebs[_to]++;

     
    delete celebIdToApprovedRecipient[_celebId];

    Transfer(_from, _to, _celebId);

    assert(balanceOf(_from) + balanceOf(_to) == prevBalances);
  }

  function buy(uint _celebId) payable public {
    address prevOwner = ownerOf(_celebId);
    uint currentPrice = celebIdToPrice[_celebId];

    require(prevOwner != msg.sender);
    require(!isNullAddress(msg.sender));
    require(msg.value >= currentPrice);

     
    uint payment = uint(SafeMath.div(SafeMath.mul(currentPrice, 92), 100));
    uint leftover = SafeMath.sub(msg.value, currentPrice);
    uint newPrice;

    _transfer(prevOwner, msg.sender, _celebId);

    if (currentPrice < GROWTH_BUMP) {
      newPrice = SafeMath.mul(currentPrice, 2);
    } else {
      newPrice = SafeMath.div(SafeMath.mul(currentPrice, PRICE_INCREASE_SCALE), 100);
    }

    celebIdToPrice[_celebId] = newPrice;

    if (prevOwner != address(this)) {
      prevOwner.transfer(payment);
    }

    CelebSold(_celebId, currentPrice, newPrice,
      celebs[_celebId].name, prevOwner, msg.sender);

    msg.sender.transfer(leftover);
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return userToNumCelebs[_owner];
  }

  function ownerOf(uint _celebId) public view returns (address addr) {
    return celebIdToOwner[_celebId];
  }

  function totalSupply() public view returns (uint total) {
    return celebs.length;
  }

  function transfer(address _to, uint _celebId) public {
    _transfer(msg.sender, _to, _celebId);
  }

   

  function createCeleb(string _name, uint _price, uint[6] _traitValues, uint[6] _traitBoosters) public onlyAuthors {
    require(_price >= MIN_STARTING_PRICE);

    uint celebId = celebs.push(Celeb(_name)) - 1;
    celebIdToOwner[celebId] = author;
    celebIdToPrice[celebId] = _price;
    celebIdToTraitValues[celebId] = _traitValues;
    celebIdToTraitBoosters[celebId] = _traitBoosters;
    userToNumCelebs[author]++;
  }

  function updateCeleb(uint _celebId, uint[6] _traitValues, uint[6] _traitBoosters) public onlyAuthors {
    require(_celebId >= 0 && _celebId < totalSupply());

    celebIdToTraitValues[_celebId] = _traitValues;
    celebIdToTraitBoosters[_celebId] = _traitBoosters;
  }

  function withdraw(uint _amount, address _to) public onlyAuthors {
    require(!isNullAddress(_to));
    require(_amount <= this.balance);

    _to.transfer(_amount);
  }

  function withdrawAll() public onlyAuthors {
    require(author != 0x0);
    require(coauthor != 0x0);

    uint halfBalance = uint(SafeMath.div(this.balance, 2));

    author.transfer(halfBalance);
    coauthor.transfer(halfBalance);
  }

  function setCoAuthor(address _coauthor) public onlyAuthor {
    require(!isNullAddress(_coauthor));

    coauthor = _coauthor;
  }

  function setKpopArenaContractAddress(address _address) public onlyAuthors {
    require(!isNullAddress(_address));

    KPOP_ARENA_CONTRACT_ADDRESS = _address;
  }

  function updateTraits(uint _celebId) public onlyArena {
    require(_celebId < totalSupply());

    for (uint i = 0; i < 6; i++) {
      uint booster = celebIdToTraitBoosters[_celebId][i];
      celebIdToTraitValues[_celebId][i] = celebIdToTraitValues[_celebId][i].add(booster);
    }
  }

   

  function getCeleb(uint _celebId) public view returns (
    string name,
    uint price,
    address owner,
    uint[6] traitValues,
    uint[6] traitBoosters
  ) {
    name = celebs[_celebId].name;
    price = celebIdToPrice[_celebId];
    owner = celebIdToOwner[_celebId];
    traitValues = celebIdToTraitValues[_celebId];
    traitBoosters = celebIdToTraitBoosters[_celebId];
  }

   

  function approve(address _to, uint _celebId) public {
    require(msg.sender == ownerOf(_celebId));

    celebIdToApprovedRecipient[_celebId] = _to;

    Approval(msg.sender, _to, _celebId);
  }

  function transferFrom(address _from, address _to, uint _celebId) public {
    require(ownerOf(_celebId) == _from);
    require(isApproved(_to, _celebId));
    require(!isNullAddress(_to));

    _transfer(_from, _to, _celebId);
  }

  function takeOwnership(uint _celebId) public {
    require(!isNullAddress(msg.sender));
    require(isApproved(msg.sender, _celebId));

    address currentOwner = celebIdToOwner[_celebId];

    _transfer(currentOwner, msg.sender, _celebId);
  }

   

  function implementsERC721() public pure returns (bool) {
    return true;
  }

   

  modifier onlyAuthor() {
    require(msg.sender == author);
    _;
  }

  modifier onlyAuthors() {
    require(msg.sender == author || msg.sender == coauthor);
    _;
  }

  modifier onlyArena() {
    require(msg.sender == author || msg.sender == coauthor || msg.sender == KPOP_ARENA_CONTRACT_ADDRESS);
    _;
  }

   

  function setMinStartingPrice(uint _price) public onlyAuthors {
    MIN_STARTING_PRICE = _price;
  }

  function setGrowthBump(uint _bump) public onlyAuthors {
    GROWTH_BUMP = _bump;
  }

  function setPriceIncreaseScale(uint _scale) public onlyAuthors {
    PRICE_INCREASE_SCALE = _scale;
  }

   

  function isApproved(address _to, uint _celebId) private view returns (bool) {
    return celebIdToApprovedRecipient[_celebId] == _to;
  }

  function isNullAddress(address _addr) private pure returns (bool) {
    return _addr == 0x0;
  }
}