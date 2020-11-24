 

pragma solidity ^0.4.18;

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 
contract Ownable {
  address public owner;

  mapping (address => bool) public admins;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
    admins[owner] = true;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }

  function changeAdmin(address _newAdmin, bool _approved) onlyOwner public {
    admins[_newAdmin] = _approved;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract ArkToken is ERC721, Ownable {
  using SafeMath for uint256;

   
  uint256 private totalTokens;
  uint256 public developerCut;

   
  mapping (uint256 => Animal) public arkData;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => uint256) public babies;
  
   
  mapping (uint256 => uint256[2]) public babyMommas;
  
   
  mapping (uint256 => uint256) public mates;

   
  mapping (uint256 => uint256) public babyMakinPrice;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  mapping (address => uint256) public birtherBalances; 

   
  event Purchase(uint256 indexed _tokenId, address indexed _buyer, address indexed _seller, uint256 _purchasePrice);
  event Birth(address indexed _birther, uint256 indexed _mom, uint256 _dad, uint256 indexed _baby);

   
  uint256 private firstCap  = 0.5 ether;
  uint256 private secondCap = 1.0 ether;
  uint256 private thirdCap  = 1.5 ether;
  uint256 private finalCap  = 3.0 ether;

   
  struct Animal {
    uint256 price;          
    uint256 lastPrice;      
    address owner;          
    address birther;        
    uint256 birtherPct;     
    uint8 gender;           
  }

  function createToken(uint256 _tokenId, uint256 _startingPrice, uint256 _cut, address _owner, uint8 _gender) onlyAdmin() public {
     
    require(_startingPrice > 0);
     
    require(arkData[_tokenId].price == 0);
    
     
    Animal storage curAnimal = arkData[_tokenId];

    curAnimal.owner = _owner;
    curAnimal.price = _startingPrice;
    curAnimal.lastPrice = _startingPrice;
    curAnimal.gender = _gender;
    curAnimal.birther = _owner;
    curAnimal.birtherPct = _cut;

     
    _mint(_owner, _tokenId);
  }

  function createMultiple (uint256[] _itemIds, uint256[] _prices, uint256[] _cuts, address[] _owners, uint8[] _genders) onlyAdmin() external {
    for (uint256 i = 0; i < _itemIds.length; i++) {
      createToken(_itemIds[i], _prices[i], _cuts[i], _owners[i], _genders[i]);
    }
  }

  function createBaby(uint256 _dad, uint256 _mom, uint256 _baby, uint256 _price) public onlyAdmin() 
  {
      mates[_mom] = _dad;
      mates[_dad] = _mom;
      babies[_mom] = _baby;
      babyMommas[_baby] = [_mom, _dad];
      babyMakinPrice[_baby] = _price;
  }
  
  function createBabies(uint256[] _dads, uint256[] _moms, uint256[] _babies, uint256[] _prices) external onlyAdmin() {
      require(_moms.length == _babies.length && _babies.length == _dads.length);
      for (uint256 i = 0; i < _moms.length; i++) {
          createBaby(_dads[i], _moms[i], _babies[i], _prices[i]);
      }
  }

   
  function getNextPrice (uint256 _price) private view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(150).div(95);
    } else if (_price < secondCap) {
      return _price.mul(135).div(96);
    } else if (_price < thirdCap) {
      return _price.mul(125).div(97);
    } else if (_price < finalCap) {
      return _price.mul(117).div(97);
    } else {
      return _price.mul(115).div(98);
    }
  }

   
  function buyToken(uint256 _tokenId) public 
    payable
    isNotContract(msg.sender)
  {

     
    Animal storage animal = arkData[_tokenId];
    uint256 price = animal.price;
    address oldOwner = animal.owner;
    address newOwner = msg.sender;
    uint256 excess = msg.value.sub(price);

     
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);
    require(oldOwner != address(0) && oldOwner != address(1));  
    
    uint256 totalCut = price.mul(4).div(100);
    
    uint256 birtherCut = price.mul(animal.birtherPct).div(1000);  
    birtherBalances[animal.birther] = birtherBalances[animal.birther].add(birtherCut);
    
    uint256 devCut = totalCut.sub(birtherCut);
    developerCut = developerCut.add(devCut);

    transferToken(oldOwner, newOwner, _tokenId);

     
    Purchase(_tokenId, newOwner, oldOwner, price);

     
    animal.price = getNextPrice(price);
    animal.lastPrice = price;

     
    oldOwner.transfer(price.sub(totalCut));
     
    if (excess > 0) {
      newOwner.transfer(excess);
    }
    
    checkBirth(_tokenId);
  }
  
   
  function checkBirth(uint256 _tokenId)
    internal
  {
    uint256 mom = 0;
    
     
    if (arkData[_tokenId].gender == 0) {
      mom = mates[_tokenId];
    } else {
      mom = _tokenId;
    }
    
    if (babies[mom] > 0) {
      if (tokenOwner[mates[_tokenId]] == msg.sender) {
         
        uint256 sumPrice = arkData[_tokenId].lastPrice + arkData[mates[_tokenId]].lastPrice;
        if (sumPrice >= babyMakinPrice[babies[mom]]) {
          autoBirth(babies[mom]);
          
          Birth(msg.sender, mom, mates[mom], babies[mom]);
          babyMakinPrice[babies[mom]] = 0;
          babies[mom] = 0;
          mates[mates[mom]] = 0;
          mates[mom] = 0;
        }
      }
    }
  }
  
   
  function autoBirth(uint256 _baby)
    internal
  {
    Animal storage animal = arkData[_baby];
    animal.birther = msg.sender;
    transferToken(animal.owner, msg.sender, _baby);
  }

   
  function transferToken(address _from, address _to, uint256 _tokenId) internal {
     
    require(tokenExists(_tokenId));

     
    require(arkData[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

     
    clearApproval(_from, _tokenId);

     
    removeToken(_from, _tokenId);

     
    addToken(_to, _tokenId);

    
    Transfer(_from, _to, _tokenId);
  }

   
  function withdraw(uint256 _amount) public onlyAdmin() {
    if (_amount == 0) { 
      _amount = developerCut; 
    }
    developerCut = developerCut.sub(_amount);
    owner.transfer(_amount);
  }

   
  function withdrawBalance(address _beneficiary) external {
    uint256 payout = birtherBalances[_beneficiary];
    birtherBalances[_beneficiary] = 0;
    _beneficiary.transfer(payout);
  }

   
  function getArkData (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _nextPrice, uint256 _mate, 
           address _birther, uint8 _gender, uint256 _baby, uint256 _babyPrice) 
  {
    Animal memory animal = arkData[_tokenId];
    uint256 baby;
    if (animal.gender == 1) baby = babies[_tokenId];
    else baby = babies[mates[_tokenId]];
    
    return (animal.owner, animal.price, getNextPrice(animal.price), mates[_tokenId], 
            animal.birther, animal.gender, baby, babyMakinPrice[baby]);
  }
  
   
  function getBabyMakinPrice(uint256 _babyId) external view
  returns (uint256 price)
  {
    price = babyMakinPrice[_babyId];
  }

   
  function getBabyMommas(uint256 _babyId) external view
  returns (uint256[2] parents)
  {
    parents = babyMommas[_babyId];
  }
  
   
  function getBirthCut(uint256 _tokenId) external view
  returns (uint256 birthCut)
  {
    birthCut = arkData[_tokenId].birtherPct;
  }

   
  function checkBalance(address _owner) external view returns (uint256) {
    return birtherBalances[_owner];
  }

   
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return arkData[_tokenId].price > 0;
  }

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier isNotContract(address _buyer) {
    uint size;
    assembly { size := extcodesize(_buyer) }
    require(size == 0);
    _;
  }


   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }
  
   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal isNotContract(_to) {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }


     
  function _mint(address _to, uint256 _tokenId) internal {
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    arkData[_tokenId].owner = _to;
    
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }

  function name() public pure returns (string _name) {
    return "EthersArk Token";
  }

  function symbol() public pure returns (string _symbol) {
    return "EARK";
  }

}