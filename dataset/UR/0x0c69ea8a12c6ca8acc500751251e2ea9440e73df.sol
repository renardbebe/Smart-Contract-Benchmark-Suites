 

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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}


 
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

   
  uint256 private totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
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
    require(owner != address(0));
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

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
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

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
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
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract AccessDeposit is Claimable {

   
  mapping(address => bool) private depositAccess;

   
  modifier onlyAccessDeposit {
    require(msg.sender == owner || depositAccess[msg.sender] == true);
    _;
  }

   
  function grantAccessDeposit(address _address)
    onlyOwner
    public
  {
    depositAccess[_address] = true;
  }

   
  function revokeAccessDeposit(address _address)
    onlyOwner
    public
  {
    depositAccess[_address] = false;
  }

}


 
contract AccessDeploy is Claimable {

   
  mapping(address => bool) private deployAccess;

   
  modifier onlyAccessDeploy {
    require(msg.sender == owner || deployAccess[msg.sender] == true);
    _;
  }

   
  function grantAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = true;
  }

   
  function revokeAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = false;
  }

}

 
contract AccessMint is Claimable {

   
  mapping(address => bool) private mintAccess;

   
  modifier onlyAccessMint {
    require(msg.sender == owner || mintAccess[msg.sender] == true);
    _;
  }

   
  function grantAccessMint(address _address)
    onlyOwner
    public
  {
    mintAccess[_address] = true;
  }

   
  function revokeAccessMint(address _address)
    onlyOwner
    public
  {
    mintAccess[_address] = false;
  }

}


 
contract Gold is StandardToken, Claimable, AccessMint {

  string public constant name = "Gold";
  string public constant symbol = "G";
  uint8 public constant decimals = 18;

   
  event Mint(
    address indexed _to,
    uint256 indexed _tokenId
  );

   
  function mint(address _to, uint256 _amount) 
    onlyAccessMint
    public 
    returns (bool) 
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

}


 
contract CryptoSagaCard is ERC721Token, Claimable, AccessMint {

  string public constant name = "CryptoSaga Card";
  string public constant symbol = "CARD";

   
  mapping(uint256 => uint8) public tokenIdToRank;

   
  uint256 public numberOfTokenId;

   
  CryptoSagaCardSwap private swapContract;

   
  event CardSwap(address indexed _by, uint256 _tokenId, uint256 _rewardId);

   
  function setCryptoSagaCardSwapContract(address _contractAddress)
    public
    onlyOwner
  {
    swapContract = CryptoSagaCardSwap(_contractAddress);
  }

  function rankOf(uint256 _tokenId) 
    public view
    returns (uint8)
  {
    return tokenIdToRank[_tokenId];
  }

   
  function mint(address _beneficiary, uint256 _amount, uint8 _rank)
    onlyAccessMint
    public
  {
    for (uint256 i = 0; i < _amount; i++) {
      _mint(_beneficiary, numberOfTokenId);
      tokenIdToRank[numberOfTokenId] = _rank;
      numberOfTokenId ++;
    }
  }

   
   
  function swap(uint256 _tokenId)
    onlyOwnerOf(_tokenId)
    public
    returns (uint256)
  {
    require(address(swapContract) != address(0));

    var _rank = tokenIdToRank[_tokenId];
    var _rewardId = swapContract.swapCardForReward(this, _rank);
    CardSwap(ownerOf(_tokenId), _tokenId, _rewardId);
    _burn(_tokenId);
    return _rewardId;
  }

}


 
contract CryptoSagaCardSwap is Ownable {

   
  address internal cardAddess;

   
  modifier onlyCard {
    require(msg.sender == cardAddess);
    _;
  }
  
   
  function setCardContract(address _contractAddress)
    public
    onlyOwner
  {
    cardAddess = _contractAddress;
  }

   
   
  function swapCardForReward(address _by, uint8 _rank)
    onlyCard
    public 
    returns (uint256);

}


 
contract CryptoSagaHero is ERC721Token, Claimable, Pausable, AccessMint, AccessDeploy, AccessDeposit {

  string public constant name = "CryptoSaga Hero";
  string public constant symbol = "HERO";
  
  struct HeroClass {
     
    string className;
     
    uint8 classRank;
     
    uint8 classRace;
     
    uint32 classAge;
     
    uint8 classType;

     
    uint32 maxLevel; 
     
    uint8 aura; 

     
     
    uint32[5] baseStats;
     
     
    uint32[5] minIVForStats;
     
     
    uint32[5] maxIVForStats;
    
     
    uint32 currentNumberOfInstancedHeroes;
  }
    
  struct HeroInstance {
     
    uint32 heroClassId;
    
     
    string heroName;
    
     
    uint32 currentLevel;
     
    uint32 currentExp;

     
    uint32 lastLocationId;
     
    uint256 availableAt;

     
     
    uint32[5] currentStats;
     
     
     
    uint32[5] ivForStats;
  }

   
   
  uint32 public requiredExpIncreaseFactor = 100;

   
   
  uint256 public requiredGoldIncreaseFactor = 1000000000000000000;

   
  mapping(uint32 => HeroClass) public heroClasses;
   
  uint32 public numberOfHeroClasses;

   
   
  mapping(uint256 => HeroInstance) public tokenIdToHeroInstance;
   
  uint256 public numberOfTokenIds;

   
  Gold public goldContract;

   
  mapping(address => uint256) public addressToGoldDeposit;

   
  uint32 private seed = 0;

   
  event DefineType(
    address indexed _by,
    uint32 indexed _typeId,
    string _className
  );

   
  event LevelUp(
    address indexed _by,
    uint256 indexed _tokenId,
    uint32 _newLevel
  );

   
  event Deploy(
    address indexed _by,
    uint256 indexed _tokenId,
    uint32 _locationId,
    uint256 _duration
  );

   
  function getClassInfo(uint32 _classId)
    external view
    returns (string className, uint8 classRank, uint8 classRace, uint32 classAge, uint8 classType, uint32 maxLevel, uint8 aura, uint32[5] baseStats, uint32[5] minIVs, uint32[5] maxIVs) 
  {
    var _cl = heroClasses[_classId];
    return (_cl.className, _cl.classRank, _cl.classRace, _cl.classAge, _cl.classType, _cl.maxLevel, _cl.aura, _cl.baseStats, _cl.minIVForStats, _cl.maxIVForStats);
  }

   
  function getClassName(uint32 _classId)
    external view
    returns (string)
  {
    return heroClasses[_classId].className;
  }

   
  function getClassRank(uint32 _classId)
    external view
    returns (uint8)
  {
    return heroClasses[_classId].classRank;
  }

   
  function getClassMintCount(uint32 _classId)
    external view
    returns (uint32)
  {
    return heroClasses[_classId].currentNumberOfInstancedHeroes;
  }

   
  function getHeroInfo(uint256 _tokenId)
    external view
    returns (uint32 classId, string heroName, uint32 currentLevel, uint32 currentExp, uint32 lastLocationId, uint256 availableAt, uint32[5] currentStats, uint32[5] ivs, uint32 bp)
  {
    HeroInstance memory _h = tokenIdToHeroInstance[_tokenId];
    var _bp = _h.currentStats[0] + _h.currentStats[1] + _h.currentStats[2] + _h.currentStats[3] + _h.currentStats[4];
    return (_h.heroClassId, _h.heroName, _h.currentLevel, _h.currentExp, _h.lastLocationId, _h.availableAt, _h.currentStats, _h.ivForStats, _bp);
  }

   
  function getHeroClassId(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].heroClassId;
  }

   
  function getHeroName(uint256 _tokenId)
    external view
    returns (string)
  {
    return tokenIdToHeroInstance[_tokenId].heroName;
  }

   
  function getHeroLevel(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].currentLevel;
  }
  
   
  function getHeroLocation(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].lastLocationId;
  }

   
  function getHeroAvailableAt(uint256 _tokenId)
    external view
    returns (uint256)
  {
    return tokenIdToHeroInstance[_tokenId].availableAt;
  }

   
  function getHeroBP(uint256 _tokenId)
    public view
    returns (uint32)
  {
    var _tmp = tokenIdToHeroInstance[_tokenId].currentStats;
    return (_tmp[0] + _tmp[1] + _tmp[2] + _tmp[3] + _tmp[4]);
  }

   
  function getHeroRequiredGoldForLevelUp(uint256 _tokenId)
    public view
    returns (uint256)
  {
    return (uint256(2) ** (tokenIdToHeroInstance[_tokenId].currentLevel / 10)) * requiredGoldIncreaseFactor;
  }

   
  function getHeroRequiredExpForLevelUp(uint256 _tokenId)
    public view
    returns (uint32)
  {
    return ((tokenIdToHeroInstance[_tokenId].currentLevel + 2) * requiredExpIncreaseFactor);
  }

   
  function getGoldDepositOfAddress(address _address)
    external view
    returns (uint256)
  {
    return addressToGoldDeposit[_address];
  }

   
  function getTokenIdOfAddressAndIndex(address _address, uint256 _index)
    external view
    returns (uint256)
  {
    return tokensOf(_address)[_index];
  }

   
  function getTotalBPOfAddress(address _address)
    external view
    returns (uint32)
  {
    var _tokens = tokensOf(_address);
    uint32 _totalBP = 0;
    for (uint256 i = 0; i < _tokens.length; i ++) {
      _totalBP += getHeroBP(_tokens[i]);
    }
    return _totalBP;
  }

   
  function setHeroName(uint256 _tokenId, string _name)
    onlyOwnerOf(_tokenId)
    public
  {
    tokenIdToHeroInstance[_tokenId].heroName = _name;
  }

   
  function setGoldContract(address _contractAddress)
    onlyOwner
    public
  {
    goldContract = Gold(_contractAddress);
  }

   
  function setRequiredExpIncreaseFactor(uint32 _value)
    onlyOwner
    public
  {
    requiredExpIncreaseFactor = _value;
  }

   
  function setRequiredGoldIncreaseFactor(uint256 _value)
    onlyOwner
    public
  {
    requiredGoldIncreaseFactor = _value;
  }

   
  function CryptoSagaHero(address _goldAddress)
    public
  {
    require(_goldAddress != address(0));

     
    setGoldContract(_goldAddress);

     
     
    defineType("Archangel", 4, 1, 13540, 0, 99, 3, [uint32(74), 75, 57, 99, 95], [uint32(8), 6, 8, 5, 5], [uint32(8), 10, 10, 6, 6]);
    defineType("Shadowalker", 3, 4, 134, 1, 75, 4, [uint32(45), 35, 60, 80, 40], [uint32(3), 2, 10, 4, 5], [uint32(5), 5, 10, 7, 5]);
    defineType("Pyromancer", 2, 0, 14, 2, 50, 1, [uint32(50), 28, 17, 40, 35], [uint32(5), 3, 2, 3, 3], [uint32(8), 4, 3, 4, 5]);
    defineType("Magician", 1, 3, 224, 2, 30, 0, [uint32(35), 15, 25, 25, 30], [uint32(3), 1, 2, 2, 2], [uint32(5), 2, 3, 3, 3]);
    defineType("Farmer", 0, 0, 59, 0, 15, 2, [uint32(10), 22, 8, 15, 25], [uint32(1), 2, 1, 1, 2], [uint32(1), 3, 1, 2, 3]);
  }

   
  function defineType(string _className, uint8 _classRank, uint8 _classRace, uint32 _classAge, uint8 _classType, uint32 _maxLevel, uint8 _aura, uint32[5] _baseStats, uint32[5] _minIVForStats, uint32[5] _maxIVForStats)
    onlyOwner
    public
  {
    require(_classRank < 5);
    require(_classType < 3);
    require(_aura < 5);
    require(_minIVForStats[0] <= _maxIVForStats[0] && _minIVForStats[1] <= _maxIVForStats[1] && _minIVForStats[2] <= _maxIVForStats[2] && _minIVForStats[3] <= _maxIVForStats[3] && _minIVForStats[4] <= _maxIVForStats[4]);

    HeroClass memory _heroType = HeroClass({
      className: _className,
      classRank: _classRank,
      classRace: _classRace,
      classAge: _classAge,
      classType: _classType,
      maxLevel: _maxLevel,
      aura: _aura,
      baseStats: _baseStats,
      minIVForStats: _minIVForStats,
      maxIVForStats: _maxIVForStats,
      currentNumberOfInstancedHeroes: 0
    });

     
    heroClasses[numberOfHeroClasses] = _heroType;

     
    DefineType(msg.sender, numberOfHeroClasses, _heroType.className);

     
    numberOfHeroClasses ++;

  }

   
  function mint(address _owner, uint32 _heroClassId)
    onlyAccessMint
    public
    returns (uint256)
  {
    require(_owner != address(0));
    require(_heroClassId < numberOfHeroClasses);

     
    var _heroClassInfo = heroClasses[_heroClassId];

     
    _mint(_owner, numberOfTokenIds);

     
    uint32[5] memory _ivForStats;
    uint32[5] memory _initialStats;
    for (uint8 i = 0; i < 5; i++) {
      _ivForStats[i] = (random(_heroClassInfo.maxIVForStats[i] + 1, _heroClassInfo.minIVForStats[i]));
      _initialStats[i] = _heroClassInfo.baseStats[i] + _ivForStats[i];
    }

     
    HeroInstance memory _heroInstance = HeroInstance({
      heroClassId: _heroClassId,
      heroName: "",
      currentLevel: 1,
      currentExp: 0,
      lastLocationId: 0,
      availableAt: now,
      currentStats: _initialStats,
      ivForStats: _ivForStats
    });

     
    tokenIdToHeroInstance[numberOfTokenIds] = _heroInstance;

     
     
    numberOfTokenIds ++;

      
    _heroClassInfo.currentNumberOfInstancedHeroes ++;

    return numberOfTokenIds - 1;
  }

   
   
  function deploy(uint256 _tokenId, uint32 _locationId, uint256 _duration)
    onlyAccessDeploy
    public
    returns (bool)
  {
     
    require(ownerOf(_tokenId) != address(0));

    var _heroInstance = tokenIdToHeroInstance[_tokenId];

     
    require(_heroInstance.availableAt <= now);

    _heroInstance.lastLocationId = _locationId;
    _heroInstance.availableAt = now + _duration;

     
    Deploy(msg.sender, _tokenId, _locationId, _duration);
  }

   
   
  function addExp(uint256 _tokenId, uint32 _exp)
    onlyAccessDeploy
    public
    returns (bool)
  {
     
    require(ownerOf(_tokenId) != address(0));

    var _heroInstance = tokenIdToHeroInstance[_tokenId];

    var _newExp = _heroInstance.currentExp + _exp;

     
    require(_newExp == uint256(uint128(_newExp)));

    _heroInstance.currentExp += _newExp;

  }

   
   
  function addDeposit(address _to, uint256 _amount)
    onlyAccessDeposit
    public
  {
     
    addressToGoldDeposit[_to] += _amount;
  }

   
   
  function levelUp(uint256 _tokenId)
    onlyOwnerOf(_tokenId) whenNotPaused
    public
  {

     
    var _heroInstance = tokenIdToHeroInstance[_tokenId];

     
    require(_heroInstance.availableAt <= now);

     
    var _heroClassInfo = heroClasses[_heroInstance.heroClassId];

     
    require(_heroInstance.currentLevel < _heroClassInfo.maxLevel);

     
    var requiredExp = getHeroRequiredExpForLevelUp(_tokenId);

     
    require(_heroInstance.currentExp >= requiredExp);

     
    var requiredGold = getHeroRequiredGoldForLevelUp(_tokenId);

     
    var _ownerOfToken = ownerOf(_tokenId);

     
    require(addressToGoldDeposit[_ownerOfToken] >= requiredGold);

     
    _heroInstance.currentLevel += 1;

     
    for (uint8 i = 0; i < 5; i++) {
      _heroInstance.currentStats[i] = _heroClassInfo.baseStats[i] + (_heroInstance.currentLevel - 1) * _heroInstance.ivForStats[i];
    }
    
     
    _heroInstance.currentExp -= requiredExp;

     
    addressToGoldDeposit[_ownerOfToken] -= requiredGold;

     
    LevelUp(msg.sender, _tokenId, _heroInstance.currentLevel);
  }

   
  function transferDeposit(uint256 _amount)
    whenNotPaused
    public
  {
    require(goldContract.allowance(msg.sender, this) >= _amount);

     
    if (goldContract.transferFrom(msg.sender, this, _amount)) {
        
      addressToGoldDeposit[msg.sender] += _amount;
    }
  }

   
  function withdrawDeposit(uint256 _amount)
    public
  {
    require(addressToGoldDeposit[msg.sender] >= _amount);

     
    if (goldContract.transfer(msg.sender, _amount)) {
       
      addressToGoldDeposit[msg.sender] -= _amount;
    }
  }

   
  function random(uint32 _upper, uint32 _lower)
    private
    returns (uint32)
  {
    require(_upper > _lower);

    seed = uint32(keccak256(keccak256(block.blockhash(block.number), seed), now));
    return seed % (_upper - _lower) + _lower;
  }

}


 
contract CryptoSagaCorrectedHeroStats {

   
  CryptoSagaHero private heroContract;

   
  function CryptoSagaCorrectedHeroStats(address _heroContractAddress)
    public
  {
    heroContract = CryptoSagaHero(_heroContractAddress);
  }

   
  function getCorrectedStats(uint256 _tokenId)
    external view
    returns (uint32 currentLevel, uint32 currentExp, uint32[5] currentStats, uint32[5] ivs, uint32 bp)
  {
    var (, , _currentLevel, _currentExp, , , _currentStats, _ivs, ) = heroContract.getHeroInfo(_tokenId);
    
    if (_currentLevel != 1) {
      for (uint8 i = 0; i < 5; i ++) {
        _currentStats[i] += _ivs[i];
      }
    }

    var _bp = _currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4];
    return (_currentLevel, _currentExp, _currentStats, _ivs, _bp);
  }

   
  function getCorrectedTotalBPOfAddress(address _address)
    external view
    returns (uint32)
  {
    var _balance = heroContract.balanceOf(_address);

    uint32 _totalBP = 0;

    for (uint256 i = 0; i < _balance; i ++) {
      var (, , _currentLevel, , , , _currentStats, _ivs, ) = heroContract.getHeroInfo(heroContract.getTokenIdOfAddressAndIndex(_address, i));
      if (_currentLevel != 1) {
        for (uint8 j = 0; j < 5; j ++) {
          _currentStats[j] += _ivs[j];
        }
      }
      _totalBP += (_currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4]);
    }

    return _totalBP;
  }

   
  function getCorrectedTotalBPOfTokens(uint256[] _tokens)
    external view
    returns (uint32)
  {
    uint32 _totalBP = 0;

    for (uint256 i = 0; i < _tokens.length; i ++) {
      var (, , _currentLevel, , , , _currentStats, _ivs, ) = heroContract.getHeroInfo(_tokens[i]);
      if (_currentLevel != 1) {
        for (uint8 j = 0; j < 5; j ++) {
          _currentStats[j] += _ivs[j];
        }
      }
      _totalBP += (_currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4]);
    }

    return _totalBP;
  }
}


 
contract CryptoSagaDungeonProgress is Claimable, AccessDeploy {

   
  mapping(address => uint32[25]) public addressToProgress;

   
  function getProgressOfAddressAndId(address _address, uint32 _id)
    external view
    returns (uint32)
  {
    var _progressList = addressToProgress[_address];
    return _progressList[_id];
  }

   
  function incrementProgressOfAddressAndId(address _address, uint32 _id)
    onlyAccessDeploy
    public
  {
    var _progressList = addressToProgress[_address];
    _progressList[_id]++;
    addressToProgress[_address] = _progressList;
  }
}


 
contract CryptoSagaDungeonVer1 is Claimable, Pausable {

  struct EnemyCombination {
     
    bool isPersonalized;
     
    uint32[4] enemySlotClassIds;
  }

  struct PlayRecord {
     
    uint32 initialSeed;
     
    uint32 progress;
     
    uint256[4] tokenIds;
     
    uint32[8] unitClassIds;
     
    uint32[8] unitLevels;
     
    uint32 expReward;
     
    uint256 goldReward;
  }

   
   
  struct TurnInfo {
     
    uint8 turnLength;
     
    uint8[8] turnOrder;
     
    uint8[24] defenderList;
     
    uint32[24] damageList;
     
    uint32[4] originalExps;
  }

   
  CryptoSagaDungeonProgress private progressContract;

   
  CryptoSagaHero private heroContract;

   
  CryptoSagaCorrectedHeroStats private correctedHeroContract;

   
  Gold public goldContract;

   
  CryptoSagaCard public cardContract;

   
   
  uint32 public locationId = 0;

   
  uint256 public coolDungeon = 900;

   
  uint256 public coolHero = 3600;

   
  uint32 public expReward = 100;

   
  uint256 public goldReward = 1000000000000000000;

   
  uint32 public previousDungeonId;

   
  uint32 public requiredProgressOfPreviousDungeon;

   
  bool public isTurnDataSaved = true;

   
  mapping(address => EnemyCombination) public addressToEnemyCombination;

   
  mapping(address => uint256) public addressToPlayRecordDateTime;

   
  mapping(address => PlayRecord) public addressToPlayRecord;

   
  mapping(address => TurnInfo) public addressToTurnInfo;

   
  uint32[] public possibleMobClasses;

   
   
  EnemyCombination public initialEnemyCombination;

   
  uint32 private seed = 0;

   
  event TryDungeon(
    address indexed _by,
    uint32 _tryingProgress,
    uint32 _progress,
    bool _isSuccess
  );

   
  function getEnemyCombinationOfAddress(address _address)
    external view
    returns (uint32[4])
  {
     
     
    var _enemyCombination = addressToEnemyCombination[_address];
    if (_enemyCombination.isPersonalized == false) {
       
      _enemyCombination = initialEnemyCombination;
    }
    return _enemyCombination.enemySlotClassIds;
  }

   
  function getInitialEnemyCombination()
    external view
    returns (uint32[4])
  {
    return initialEnemyCombination.enemySlotClassIds;
  }

   
  function getLastPlayDateTime(address _address)
    external view
    returns (uint256 dateTime)
  {
    return addressToPlayRecordDateTime[_address];
  }

   
  function getPlayRecord(address _address)
    external view
    returns (uint32 initialSeed, uint32 progress, uint256[4] heroTokenIds, uint32[8] uintClassIds, uint32[8] unitLevels, uint32 expRewardGiven, uint256 goldRewardGiven, uint8 turnLength, uint8[8] turnOrder, uint8[24] defenderList, uint32[24] damageList)
  {
    PlayRecord memory _p = addressToPlayRecord[_address];
    TurnInfo memory _t = addressToTurnInfo[_address];
    return (_p.initialSeed, _p.progress, _p.tokenIds, _p.unitClassIds, _p.unitLevels, _p.expReward, _p.goldReward, _t.turnLength, _t.turnOrder, _t.defenderList, _t.damageList);
  }

   
  function getPlayRecordNoTurnData(address _address)
    external view
    returns (uint32 initialSeed, uint32 progress, uint256[4] heroTokenIds, uint32[8] uintClassIds, uint32[8] unitLevels, uint32 expRewardGiven, uint256 goldRewardGiven)
  {
    PlayRecord memory _p = addressToPlayRecord[_address];
    return (_p.initialSeed, _p.progress, _p.tokenIds, _p.unitClassIds, _p.unitLevels, _p.expReward, _p.goldReward);
  }

   
  function setLocationId(uint32 _value)
    onlyOwner
    public
  {
    locationId = _value;
  }

   
  function setCoolDungeon(uint32 _value)
    onlyOwner
    public
  {
    coolDungeon = _value;
  }

   
  function setCoolHero(uint32 _value)
    onlyOwner
    public
  {
    coolHero = _value;
  }

   
  function setExpReward(uint32 _value)
    onlyOwner
    public
  {
    expReward = _value;
  }

   
  function setGoldReward(uint256 _value)
    onlyOwner
    public
  {
    goldReward = _value;
  }

   
  function setIsTurnDataSaved(bool _value)
    onlyOwner
    public
  {
    isTurnDataSaved = _value;
  }

   
  function setInitialEnemyCombination(uint32[4] _enemySlotClassIds)
    onlyOwner
    public
  {
    initialEnemyCombination.isPersonalized = false;
    initialEnemyCombination.enemySlotClassIds = _enemySlotClassIds;
  }

   
  function setPreviousDungeoonId(uint32 _dungeonId)
    onlyOwner
    public
  {
    previousDungeonId = _dungeonId;
  }

   
  function setRequiredProgressOfPreviousDungeon(uint32 _progress)
    onlyOwner
    public
  {
    requiredProgressOfPreviousDungeon = _progress;
  }

   
  function setPossibleMobs(uint32[] _classIds)
    onlyOwner
    public
  {
    possibleMobClasses = _classIds;
  }

   
  function CryptoSagaDungeonVer1(address _progressAddress, address _heroContractAddress, address _correctedHeroContractAddress, address _cardContractAddress, address _goldContractAddress, uint32 _locationId, uint256 _coolDungeon, uint256 _coolHero, uint32 _expReward, uint256 _goldReward, uint32 _previousDungeonId, uint32 _requiredProgressOfPreviousDungeon, uint32[4] _enemySlotClassIds, bool _isTurnDataSaved)
    public
  {
    progressContract = CryptoSagaDungeonProgress(_progressAddress);
    heroContract = CryptoSagaHero(_heroContractAddress);
    correctedHeroContract = CryptoSagaCorrectedHeroStats(_correctedHeroContractAddress);
    cardContract = CryptoSagaCard(_cardContractAddress);
    goldContract = Gold(_goldContractAddress);
    
    locationId = _locationId;
    coolDungeon = _coolDungeon;
    coolHero = _coolHero;
    expReward = _expReward;
    goldReward = _goldReward;

    previousDungeonId = _previousDungeonId;
    requiredProgressOfPreviousDungeon = _requiredProgressOfPreviousDungeon;

    initialEnemyCombination.isPersonalized = false;
    initialEnemyCombination.enemySlotClassIds = _enemySlotClassIds;
    
    isTurnDataSaved = _isTurnDataSaved;
  }
  
   
  function enterDungeon(uint256[4] _tokenIds, uint32 _tryingProgress)
    whenNotPaused
    public
  {
     
    require(_tokenIds[0] == 0 || (_tokenIds[0] != _tokenIds[1] && _tokenIds[0] != _tokenIds[2] && _tokenIds[0] != _tokenIds[3]));
    require(_tokenIds[1] == 0 || (_tokenIds[1] != _tokenIds[0] && _tokenIds[1] != _tokenIds[2] && _tokenIds[1] != _tokenIds[3]));
    require(_tokenIds[2] == 0 || (_tokenIds[2] != _tokenIds[0] && _tokenIds[2] != _tokenIds[1] && _tokenIds[2] != _tokenIds[3]));
    require(_tokenIds[3] == 0 || (_tokenIds[3] != _tokenIds[0] && _tokenIds[3] != _tokenIds[1] && _tokenIds[3] != _tokenIds[2]));

     
    if (requiredProgressOfPreviousDungeon != 0) {
      require(progressContract.getProgressOfAddressAndId(msg.sender, previousDungeonId) >= requiredProgressOfPreviousDungeon);
    }

     
    require(_tryingProgress > 0);

     
    require(_tryingProgress <= progressContract.getProgressOfAddressAndId(msg.sender, locationId) + 1);

     
    require(addressToPlayRecordDateTime[msg.sender] + coolDungeon <= now);

     
    require(checkOwnershipAndAvailability(msg.sender, _tokenIds));

     
    addressToPlayRecordDateTime[msg.sender] = now;

     
    seed += uint32(now);

     
    PlayRecord memory _playRecord;
    _playRecord.initialSeed = seed;
    _playRecord.progress = _tryingProgress;
    _playRecord.tokenIds[0] = _tokenIds[0];
    _playRecord.tokenIds[1] = _tokenIds[1];
    _playRecord.tokenIds[2] = _tokenIds[2];
    _playRecord.tokenIds[3] = _tokenIds[3];

     
    TurnInfo memory _turnInfo;

     

    uint32[5][8] memory _unitStats;  
    uint8[2][8] memory _unitTypesAuras;  

     
    if (_tokenIds[0] != 0) {
      _playRecord.unitClassIds[0] = heroContract.getHeroClassId(_tokenIds[0]);
      (_playRecord.unitLevels[0], _turnInfo.originalExps[0], _unitStats[0], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[0]);
      (, , , , _unitTypesAuras[0][0], , _unitTypesAuras[0][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[0]);
    }
    if (_tokenIds[1] != 0) {
      _playRecord.unitClassIds[1] = heroContract.getHeroClassId(_tokenIds[1]);
      (_playRecord.unitLevels[1], _turnInfo.originalExps[1], _unitStats[1], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[1]);
      (, , , , _unitTypesAuras[1][0], , _unitTypesAuras[1][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[1]);
    }
    if (_tokenIds[2] != 0) {
      _playRecord.unitClassIds[2] = heroContract.getHeroClassId(_tokenIds[2]);
      (_playRecord.unitLevels[2], _turnInfo.originalExps[2], _unitStats[2], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[2]);
      (, , , , _unitTypesAuras[2][0], , _unitTypesAuras[2][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[2]);
    }
    if (_tokenIds[3] != 0) {
      _playRecord.unitClassIds[3] = heroContract.getHeroClassId(_tokenIds[3]);
      (_playRecord.unitLevels[3], _turnInfo.originalExps[3], _unitStats[3], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[3]);
      (, , , , _unitTypesAuras[3][0], , _unitTypesAuras[3][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[3]);
    }

     
     
    var _enemyCombination = addressToEnemyCombination[msg.sender];
    if (_enemyCombination.isPersonalized == false) {
       
      _enemyCombination = initialEnemyCombination;
    }

    uint32[5][8] memory _tmpEnemyBaseStatsAndIVs;  

     
    (, , , , _unitTypesAuras[4][0], , _unitTypesAuras[4][1], _tmpEnemyBaseStatsAndIVs[0], _tmpEnemyBaseStatsAndIVs[4], ) = heroContract.getClassInfo(_enemyCombination.enemySlotClassIds[0]);
    (, , , , _unitTypesAuras[5][0], , _unitTypesAuras[5][1], _tmpEnemyBaseStatsAndIVs[1], _tmpEnemyBaseStatsAndIVs[5], ) = heroContract.getClassInfo(_enemyCombination.enemySlotClassIds[1]);
    (, , , , _unitTypesAuras[6][0], , _unitTypesAuras[6][1], _tmpEnemyBaseStatsAndIVs[2], _tmpEnemyBaseStatsAndIVs[6], ) = heroContract.getClassInfo(_enemyCombination.enemySlotClassIds[2]);
    (, , , , _unitTypesAuras[7][0], , _unitTypesAuras[7][1], _tmpEnemyBaseStatsAndIVs[3], _tmpEnemyBaseStatsAndIVs[7], ) = heroContract.getClassInfo(_enemyCombination.enemySlotClassIds[3]);

    _playRecord.unitClassIds[4] = _enemyCombination.enemySlotClassIds[0];
    _playRecord.unitClassIds[5] = _enemyCombination.enemySlotClassIds[1];
    _playRecord.unitClassIds[6] = _enemyCombination.enemySlotClassIds[2];
    _playRecord.unitClassIds[7] = _enemyCombination.enemySlotClassIds[3];
    
     
    _playRecord.unitLevels[4] = _tryingProgress;
    _playRecord.unitLevels[5] = _tryingProgress;
    _playRecord.unitLevels[6] = _tryingProgress;
    _playRecord.unitLevels[7] = _tryingProgress;

     
    for (uint8 i = 0; i < 5; i ++) {
      _unitStats[4][i] = _tmpEnemyBaseStatsAndIVs[0][i] + _playRecord.unitLevels[4] * _tmpEnemyBaseStatsAndIVs[4][i];
      _unitStats[5][i] = _tmpEnemyBaseStatsAndIVs[1][i] + _playRecord.unitLevels[5] * _tmpEnemyBaseStatsAndIVs[5][i];
      _unitStats[6][i] = _tmpEnemyBaseStatsAndIVs[2][i] + _playRecord.unitLevels[6] * _tmpEnemyBaseStatsAndIVs[6][i];
      _unitStats[7][i] = _tmpEnemyBaseStatsAndIVs[3][i] + _playRecord.unitLevels[7] * _tmpEnemyBaseStatsAndIVs[7][i];
    }

     
    
     
    uint32[8] memory _unitAGLs;
    for (i = 0; i < 8; i ++) {
      _unitAGLs[i] = _unitStats[i][2];
    }
    _turnInfo.turnOrder = getOrder(_unitAGLs);
    
     
    _turnInfo.turnLength = 24;
    for (i = 0; i < 24; i ++) {
      if (_unitStats[4][4] == 0 && _unitStats[5][4] == 0 && _unitStats[6][4] == 0 && _unitStats[7][4] == 0) {
        _turnInfo.turnLength = i;
        break;
      } else if (_unitStats[0][4] == 0 && _unitStats[1][4] == 0 && _unitStats[2][4] == 0 && _unitStats[3][4] == 0) {
        _turnInfo.turnLength = i;
        break;
      }
      
      var _slotId = _turnInfo.turnOrder[(i % 8)];
      if (_slotId < 4 && _tokenIds[_slotId] == 0) {
         
         
        _turnInfo.defenderList[i] = 127;
      } else if (_unitStats[_slotId][4] == 0) {
         
         
        _turnInfo.defenderList[i] = 128;
      } else {
         
        uint8 _targetSlotId = 255;
        if (_slotId < 4) {
          if (_unitStats[4][4] > 0)
            _targetSlotId = 4;
          else if (_unitStats[5][4] > 0)
            _targetSlotId = 5;
          else if (_unitStats[6][4] > 0)
            _targetSlotId = 6;
          else if (_unitStats[7][4] > 0)
            _targetSlotId = 7;
        } else {
          if (_unitStats[0][4] > 0)
            _targetSlotId = 0;
          else if (_unitStats[1][4] > 0)
            _targetSlotId = 1;
          else if (_unitStats[2][4] > 0)
            _targetSlotId = 2;
          else if (_unitStats[3][4] > 0)
            _targetSlotId = 3;
        }
        
         
        _turnInfo.defenderList[i] = _targetSlotId;
        
         
        uint32 _damage = 10;
        if ((_unitStats[_slotId][0] * 150 / 100) > _unitStats[_targetSlotId][1])
          _damage = max((_unitStats[_slotId][0] * 150 / 100) - _unitStats[_targetSlotId][1], 10);
        else
          _damage = 10;

         
        if ((_unitStats[_slotId][3] * 150 / 100) > _unitStats[_targetSlotId][2]) {
          if (min(max(((_unitStats[_slotId][3] * 150 / 100) - _unitStats[_targetSlotId][2]), 75), 99) <= random(100, 0))
            _damage = _damage * 0;
        }
        else {
          if (75 <= random(100, 0))
            _damage = _damage * 0;
        }

         
        if (_unitStats[_slotId][3] > _unitStats[_targetSlotId][3]) {
          if (min(max((_unitStats[_slotId][3] - _unitStats[_targetSlotId][3]), 5), 75) > random(100, 0))
            _damage = _damage * 150 / 100;
        }
        else {
          if (5 > random(100, 0))
            _damage = _damage * 150 / 100;
        }

         
        if (_unitTypesAuras[_slotId][0] == 0 && _unitTypesAuras[_targetSlotId][0] == 1)  
          _damage = _damage * 125 / 100;
        else if (_unitTypesAuras[_slotId][0] == 1 && _unitTypesAuras[_targetSlotId][0] == 2)  
          _damage = _damage * 125 / 100;
        else if (_unitTypesAuras[_slotId][0] == 2 && _unitTypesAuras[_targetSlotId][0] == 0)  
          _damage = _damage * 125 / 100;

         
        if (_unitTypesAuras[_slotId][1] == 0 && _unitTypesAuras[_targetSlotId][1] == 1)  
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 1 && _unitTypesAuras[_targetSlotId][1] == 2)  
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 2 && _unitTypesAuras[_targetSlotId][1] == 0)  
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 3 && _unitTypesAuras[_targetSlotId][1] == 4)  
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 4 && _unitTypesAuras[_targetSlotId][1] == 3)  
          _damage = _damage * 150 / 100;
        
         
        if(_unitStats[_targetSlotId][4] > _damage)
          _unitStats[_targetSlotId][4] -= _damage;
        else
          _unitStats[_targetSlotId][4] = 0;

         
        _turnInfo.damageList[i] = _damage;
      }
    }
    
     

     
    if (_tokenIds[0] != 0)
      heroContract.deploy(_tokenIds[0], locationId, coolHero);
    if (_tokenIds[1] != 0)
      heroContract.deploy(_tokenIds[1], locationId, coolHero);
    if (_tokenIds[2] != 0)
      heroContract.deploy(_tokenIds[2], locationId, coolHero);
    if (_tokenIds[3] != 0)
      heroContract.deploy(_tokenIds[3], locationId, coolHero);

    uint8 _deadEnemies = 0;

     
    if (_unitStats[4][4] == 0)
      _deadEnemies ++;
    if (_unitStats[5][4] == 0)
      _deadEnemies ++;
    if (_unitStats[6][4] == 0)
      _deadEnemies ++;
    if (_unitStats[7][4] == 0)
      _deadEnemies ++;
      
    if (_deadEnemies == 4) {
       
      TryDungeon(msg.sender, _tryingProgress, progressContract.getProgressOfAddressAndId(msg.sender, locationId), true);
      
       
      if (_tryingProgress == progressContract.getProgressOfAddressAndId(msg.sender, locationId) + 1) {
         
        progressContract.incrementProgressOfAddressAndId(msg.sender, locationId);
         
        (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, _tryingProgress, _deadEnemies, false, _turnInfo.originalExps);
         
        if (_tryingProgress % 10 == 0) {
          cardContract.mint(msg.sender, 1, 3);
        }
      } else {
         
        (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, _tryingProgress, _deadEnemies, true, _turnInfo.originalExps);
      }

       
      createNewCombination(msg.sender);
    }
    else {
       
      TryDungeon(msg.sender, _tryingProgress, progressContract.getProgressOfAddressAndId(msg.sender, locationId), false);

       
      (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, _tryingProgress, _deadEnemies, false, _turnInfo.originalExps);
    }

     
    addressToPlayRecord[msg.sender] = _playRecord;

     
     
     
    if (isTurnDataSaved) {
      addressToTurnInfo[msg.sender] = _turnInfo;
    }
  }

   
  function checkOwnershipAndAvailability(address _playerAddress, uint256[4] _tokenIds)
    private view
    returns(bool)
  {
    if ((_tokenIds[0] == 0 || heroContract.ownerOf(_tokenIds[0]) == _playerAddress) && (_tokenIds[1] == 0 || heroContract.ownerOf(_tokenIds[1]) == _playerAddress) && (_tokenIds[2] == 0 || heroContract.ownerOf(_tokenIds[2]) == _playerAddress) && (_tokenIds[3] == 0 || heroContract.ownerOf(_tokenIds[3]) == _playerAddress)) {
      
       
      uint256[4] memory _heroAvailAts;
      if (_tokenIds[0] != 0)
        ( , , , , , _heroAvailAts[0], , , ) = heroContract.getHeroInfo(_tokenIds[0]);
      if (_tokenIds[1] != 0)
        ( , , , , , _heroAvailAts[1], , , ) = heroContract.getHeroInfo(_tokenIds[1]);
      if (_tokenIds[2] != 0)
        ( , , , , , _heroAvailAts[2], , , ) = heroContract.getHeroInfo(_tokenIds[2]);
      if (_tokenIds[3] != 0)
        ( , , , , , _heroAvailAts[3], , , ) = heroContract.getHeroInfo(_tokenIds[3]);

      if (_heroAvailAts[0] <= now && _heroAvailAts[1] <= now && _heroAvailAts[2] <= now && _heroAvailAts[3] <= now) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

   
   
  function createNewCombination(address _playerAddress)
    private
  {
    EnemyCombination memory _newCombination;
    _newCombination.isPersonalized = true;
    for (uint8 i = 0; i < 4; i++) {
      _newCombination.enemySlotClassIds[i] = possibleMobClasses[random(uint32(possibleMobClasses.length), 0)];
    }
    addressToEnemyCombination[_playerAddress] = _newCombination;
  }

   
  function giveReward(uint256[4] _heroes, uint32 _progress, uint8 _numberOfKilledEnemies, bool _isClearedBefore, uint32[4] _originalExps)
    private
    returns (uint32 expRewardGiven, uint256 goldRewardGiven)
  {
    uint256 _goldRewardGiven;
    uint32 _expRewardGiven;
    if (_numberOfKilledEnemies != 4) {
       
       
      _goldRewardGiven = goldReward / 25 * sqrt(_progress);
      _expRewardGiven = expReward * _numberOfKilledEnemies / 4 / 5 * sqrt(_progress / 4 + 1);
    } else if (_isClearedBefore == true) {
       
      _goldRewardGiven = goldReward / 5 * sqrt(_progress);
      _expRewardGiven = expReward / 5 * sqrt(_progress / 4 + 1);
    } else {
       
      _goldRewardGiven = goldReward * sqrt(_progress);
      _expRewardGiven = expReward * sqrt(_progress / 4 + 1);
    }

     
    goldContract.mint(msg.sender, _goldRewardGiven);
    
     
    if(_heroes[0] != 0)
      heroContract.addExp(_heroes[0], uint32(2)**32 - _originalExps[0] + _expRewardGiven);
    if(_heroes[1] != 0)
      heroContract.addExp(_heroes[1], uint32(2)**32 - _originalExps[1] + _expRewardGiven);
    if(_heroes[2] != 0)
      heroContract.addExp(_heroes[2], uint32(2)**32 - _originalExps[2] + _expRewardGiven);
    if(_heroes[3] != 0)
      heroContract.addExp(_heroes[3], uint32(2)**32 - _originalExps[3] + _expRewardGiven);

    return (_expRewardGiven, _goldRewardGiven);
  }

   
  function random(uint32 _upper, uint32 _lower)
    private
    returns (uint32)
  {
    require(_upper > _lower);

    seed = seed % uint32(1103515245) + 12345;
    return seed % (_upper - _lower) + _lower;
  }

   
  function getOrder(uint32[8] _by)
    private pure
    returns (uint8[8])
  {
    uint8[8] memory _order = [uint8(0), 1, 2, 3, 4, 5, 6, 7];
    for (uint8 i = 0; i < 8; i ++) {
      for (uint8 j = i + 1; j < 8; j++) {
        if (_by[i] < _by[j]) {
          uint32 tmp1 = _by[i];
          _by[i] = _by[j];
          _by[j] = tmp1;
          uint8 tmp2 = _order[i];
          _order[i] = _order[j];
          _order[j] = tmp2;
        }
      }
    }
    return _order;
  }

   
  function max(uint32 _value1, uint32 _value2)
    private pure
    returns (uint32)
  {
    if(_value1 >= _value2)
      return _value1;
    else
      return _value2;
  }

   
  function min(uint32 _value1, uint32 _value2)
    private pure
    returns (uint32)
  {
    if(_value2 >= _value1)
      return _value1;
    else
      return _value2;
  }

   
  function sqrt(uint32 _value) 
    private pure
    returns (uint32) 
  {
    uint32 z = (_value + 1) / 2;
    uint32 y = _value;
    while (z < y) {
      y = z;
      z = (_value / z + z) / 2;
    }
    return y;
  }

}