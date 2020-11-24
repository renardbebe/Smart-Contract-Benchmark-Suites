 

pragma solidity ^0.4.24;

contract CrabData {
  modifier crabDataLength(uint256[] memory _crabData) {
    require(_crabData.length == 8);
    _;
  }

  struct CrabPartData {
    uint256 hp;
    uint256 dps;
    uint256 blockRate;
    uint256 resistanceBonus;
    uint256 hpBonus;
    uint256 dpsBonus;
    uint256 blockBonus;
    uint256 mutiplierBonus;
  }

  function arrayToCrabPartData(
    uint256[] _partData
  ) 
    internal 
    pure 
    crabDataLength(_partData) 
    returns (CrabPartData memory _parsedData) 
  {
    _parsedData = CrabPartData(
      _partData[0],    
      _partData[1],    
      _partData[2],    
      _partData[3],    
      _partData[4],    
      _partData[5],    
      _partData[6],    
      _partData[7]);   
  }

  function crabPartDataToArray(CrabPartData _crabPartData) internal pure returns (uint256[] memory _resultData) {
    _resultData = new uint256[](8);
    _resultData[0] = _crabPartData.hp;
    _resultData[1] = _crabPartData.dps;
    _resultData[2] = _crabPartData.blockRate;
    _resultData[3] = _crabPartData.resistanceBonus;
    _resultData[4] = _crabPartData.hpBonus;
    _resultData[5] = _crabPartData.dpsBonus;
    _resultData[6] = _crabPartData.blockBonus;
    _resultData[7] = _crabPartData.mutiplierBonus;
  }
}

contract GeneSurgeon {
   
  uint256[] internal crabPartMultiplier = [0, 10**9, 10**6, 10**3, 1];

  function extractElementsFromGene(uint256 _gene) internal view returns (uint256[] memory _elements) {
    _elements = new uint256[](4);
    _elements[0] = _gene / crabPartMultiplier[1] / 100 % 10;
    _elements[1] = _gene / crabPartMultiplier[2] / 100 % 10;
    _elements[2] = _gene / crabPartMultiplier[3] / 100 % 10;
    _elements[3] = _gene / crabPartMultiplier[4] / 100 % 10;
  }

  function extractPartsFromGene(uint256 _gene) internal view returns (uint256[] memory _parts) {
    _parts = new uint256[](4);
    _parts[0] = _gene / crabPartMultiplier[1] % 100;
    _parts[1] = _gene / crabPartMultiplier[2] % 100;
    _parts[2] = _gene / crabPartMultiplier[3] % 100;
    _parts[3] = _gene / crabPartMultiplier[4] % 100;
  }
}

interface GenesisCrabInterface {
  function generateCrabGene(bool isPresale, bool hasLegendaryPart) external returns (uint256 _gene, uint256 _skin, uint256 _heartValue, uint256 _growthValue);
  function mutateCrabPart(uint256 _part, uint256 _existingPartGene, uint256 _legendaryPercentage) external returns (uint256);
  function generateCrabHeart() external view returns (uint256, uint256);
}

contract LevelCalculator {
  event LevelUp(address indexed tokenOwner, uint256 indexed tokenId, uint256 currentLevel, uint256 currentExp);
  event ExpGained(address indexed tokenOwner, uint256 indexed tokenId, uint256 currentLevel, uint256 currentExp);

  function expRequiredToReachLevel(uint256 _level) internal pure returns (uint256 _exp) {
    require(_level > 1);

    uint256 _expRequirement = 10;
    for(uint256 i = 2 ; i < _level ; i++) {
      _expRequirement += 12;
    }
    _exp = _expRequirement;
  }
}

contract Randomable {
   
  function _generateRandom(bytes32 seed) view internal returns (bytes32) {
    return keccak256(abi.encodePacked(blockhash(block.number-1), seed));
  }

  function _generateRandomNumber(bytes32 seed, uint256 max) view internal returns (uint256) {
    return uint256(_generateRandom(seed)) % max;
  }
}

contract CryptantCrabStoreInterface {
  function createAddress(bytes32 key, address value) external returns (bool);
  function createAddresses(bytes32[] keys, address[] values) external returns (bool);
  function updateAddress(bytes32 key, address value) external returns (bool);
  function updateAddresses(bytes32[] keys, address[] values) external returns (bool);
  function removeAddress(bytes32 key) external returns (bool);
  function removeAddresses(bytes32[] keys) external returns (bool);
  function readAddress(bytes32 key) external view returns (address);
  function readAddresses(bytes32[] keys) external view returns (address[]);
   
  function createBool(bytes32 key, bool value) external returns (bool);
  function createBools(bytes32[] keys, bool[] values) external returns (bool);
  function updateBool(bytes32 key, bool value) external returns (bool);
  function updateBools(bytes32[] keys, bool[] values) external returns (bool);
  function removeBool(bytes32 key) external returns (bool);
  function removeBools(bytes32[] keys) external returns (bool);
  function readBool(bytes32 key) external view returns (bool);
  function readBools(bytes32[] keys) external view returns (bool[]);
   
  function createBytes32(bytes32 key, bytes32 value) external returns (bool);
  function createBytes32s(bytes32[] keys, bytes32[] values) external returns (bool);
  function updateBytes32(bytes32 key, bytes32 value) external returns (bool);
  function updateBytes32s(bytes32[] keys, bytes32[] values) external returns (bool);
  function removeBytes32(bytes32 key) external returns (bool);
  function removeBytes32s(bytes32[] keys) external returns (bool);
  function readBytes32(bytes32 key) external view returns (bytes32);
  function readBytes32s(bytes32[] keys) external view returns (bytes32[]);
   
  function createUint256(bytes32 key, uint256 value) external returns (bool);
  function createUint256s(bytes32[] keys, uint256[] values) external returns (bool);
  function updateUint256(bytes32 key, uint256 value) external returns (bool);
  function updateUint256s(bytes32[] keys, uint256[] values) external returns (bool);
  function removeUint256(bytes32 key) external returns (bool);
  function removeUint256s(bytes32[] keys) external returns (bool);
  function readUint256(bytes32 key) external view returns (uint256);
  function readUint256s(bytes32[] keys) external view returns (uint256[]);
   
  function createInt256(bytes32 key, int256 value) external returns (bool);
  function createInt256s(bytes32[] keys, int256[] values) external returns (bool);
  function updateInt256(bytes32 key, int256 value) external returns (bool);
  function updateInt256s(bytes32[] keys, int256[] values) external returns (bool);
  function removeInt256(bytes32 key) external returns (bool);
  function removeInt256s(bytes32[] keys) external returns (bool);
  function readInt256(bytes32 key) external view returns (int256);
  function readInt256s(bytes32[] keys) external view returns (int256[]);
   
  function parseKey(bytes32 key) internal pure returns (bytes32);
  function parseKeys(bytes32[] _keys) internal pure returns (bytes32[]);
}

contract StoreRBAC {
   
  mapping(uint256 => mapping (uint256 => mapping(address => bool))) private stores;

   
  uint256 public constant STORE_RBAC = 1;
  uint256 public constant STORE_FUNCTIONS = 2;
  uint256 public constant STORE_KEYS = 3;
   
  uint256 public constant RBAC_ROLE_ADMIN = 1;  

   
  event RoleAdded(uint256 storeName, address addr, uint256 role);
  event RoleRemoved(uint256 storeName, address addr, uint256 role);

  constructor() public {
    addRole(STORE_RBAC, msg.sender, RBAC_ROLE_ADMIN);
  }

  function hasRole(uint256 storeName, address addr, uint256 role) public view returns (bool) {
    return stores[storeName][role][addr];
  }

  function checkRole(uint256 storeName, address addr, uint256 role) public view {
    require(hasRole(storeName, addr, role));
  }

  function addRole(uint256 storeName, address addr, uint256 role) internal {
    stores[storeName][role][addr] = true;

    emit RoleAdded(storeName, addr, role);
  }

  function removeRole(uint256 storeName, address addr, uint256 role) internal {
    stores[storeName][role][addr] = false;

    emit RoleRemoved(storeName, addr, role);
  }

  function adminAddRole(uint256 storeName, address addr, uint256 role) onlyAdmin public {
    addRole(storeName, addr, role);
  }

  function adminRemoveRole(uint256 storeName, address addr, uint256 role) onlyAdmin public {
    removeRole(storeName, addr, role);
  }

  modifier onlyRole(uint256 storeName, uint256 role) {
    checkRole(storeName, msg.sender, role);
    _;
  }

  modifier onlyAdmin() {
    checkRole(STORE_RBAC, msg.sender, RBAC_ROLE_ADMIN);
    _;
  }
}

contract FunctionProtection is StoreRBAC { 
   
  uint256 constant public FN_ROLE_CREATE = 2;  
  uint256 constant public FN_ROLE_UPDATE = 3;  
  uint256 constant public FN_ROLE_REMOVE = 4;  

  function canCreate() internal view returns (bool) {
    return hasRole(STORE_FUNCTIONS, msg.sender, FN_ROLE_CREATE);
  }
  
  function canUpdate() internal view returns (bool) {
    return hasRole(STORE_FUNCTIONS, msg.sender, FN_ROLE_UPDATE);
  }
  
  function canRemove() internal view returns (bool) {
    return hasRole(STORE_FUNCTIONS, msg.sender, FN_ROLE_REMOVE);
  }

   
  function applyAllPermission(address _address) external onlyAdmin {
    addRole(STORE_FUNCTIONS, _address, FN_ROLE_CREATE);
    addRole(STORE_FUNCTIONS, _address, FN_ROLE_UPDATE);
    addRole(STORE_FUNCTIONS, _address, FN_ROLE_REMOVE);
  }
}

contract CryptantCrabMarketStore is FunctionProtection {
   
  struct TradeRecord {
    uint256 tokenId;
    uint256 auctionId;
    uint256 price;
    uint48 time;
    address owner;
    address seller;
  }

   
  struct AuctionItem {
    uint256 tokenId;
    uint256 basePrice;
    address seller;
    uint48 startTime;
    uint48 endTime;
    uint8 state;               
    uint256[] bidIndexes;      
  }

  struct Bid {
    uint256 auctionId;
    uint256 price;
    uint48 time;
    address bidder;
  }

   
  struct WithdrawalRecord {
    uint256 auctionId;
    uint256 value;
    uint48 time;
    uint48 callTime;
    bool hasWithdrawn;
  }

   
  mapping(address => WithdrawalRecord[]) public withdrawalList;

   
  mapping(address => uint256) public lastWithdrawnIndex;

   
  TradeRecord[] public tradeRecords;

   
  AuctionItem[] public auctionItems;

  Bid[] public bidHistory;

  event TradeRecordAdded(address indexed seller, address indexed buyer, uint256 tradeId, uint256 price, uint256 tokenId, uint256 indexed auctionId);

  event AuctionItemAdded(address indexed seller, uint256 auctionId, uint256 basePrice, uint256 duration, uint256 tokenId);

  event AuctionBid(address indexed bidder, address indexed previousBidder, uint256 auctionId, uint256 bidPrice, uint256 bidIndex, uint256 tokenId, uint256 endTime);

  event PendingWithdrawalCleared(address indexed withdrawer, uint256 withdrawnAmount);

  constructor() public 
  {
     
     
    auctionItems.push(AuctionItem(0, 0, address(0), 0, 0, 0, new uint256[](1)));

     
     
    tradeRecords.push(TradeRecord(0, 0, 0, 0, address(0), address(0)));

     
     
    bidHistory.push(Bid(0, 0, uint48(0), address(0)));
  }

   
   
  function getWithdrawalList(address withdrawer) external view returns (
    uint256[] memory _auctionIds,
    uint256[] memory _values,
    uint256[] memory _times,
    uint256[] memory _callTimes,
    bool[] memory _hasWithdrawn
  ) {
    WithdrawalRecord[] storage withdrawalRecords = withdrawalList[withdrawer];
    _auctionIds = new uint256[](withdrawalRecords.length);
    _values = new uint256[](withdrawalRecords.length);
    _times = new uint256[](withdrawalRecords.length);
    _callTimes = new uint256[](withdrawalRecords.length);
    _hasWithdrawn = new bool[](withdrawalRecords.length);

    for(uint256 i = 0 ; i < withdrawalRecords.length ; i++) {
      WithdrawalRecord storage withdrawalRecord = withdrawalRecords[i];
      _auctionIds[i] = withdrawalRecord.auctionId;
      _values[i] = withdrawalRecord.value; 
      _times[i] = withdrawalRecord.time;
      _callTimes[i] = withdrawalRecord.callTime;
      _hasWithdrawn[i] = withdrawalRecord.hasWithdrawn;
    }
  }

  function getTradeRecord(uint256 _tradeId) external view returns (
    uint256 _tokenId,
    uint256 _auctionId,
    uint256 _price,
    uint256 _time,
    address _owner,
    address _seller
  ) {
    TradeRecord storage _tradeRecord = tradeRecords[_tradeId];
    _tokenId = _tradeRecord.tokenId;
    _auctionId = _tradeRecord.auctionId;
    _price = _tradeRecord.price;
    _time = _tradeRecord.time;
    _owner = _tradeRecord.owner;
    _seller = _tradeRecord.seller;
  }

  function totalTradeRecords() external view returns (uint256) {
    return tradeRecords.length - 1;  
  }

  function getPricesOfLatestTradeRecords(uint256 amount) external view returns (uint256[] memory _prices) {
    _prices = new uint256[](amount);
    uint256 startIndex = tradeRecords.length - amount;

    for(uint256 i = 0 ; i < amount ; i++) {
      _prices[i] = tradeRecords[startIndex + i].price;
    }
  }

  function getAuctionItem(uint256 _auctionId) external view returns (
    uint256 _tokenId,
    uint256 _basePrice,
    address _seller,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _state,
    uint256[] _bidIndexes
  ) {
    AuctionItem storage _auctionItem = auctionItems[_auctionId];
    _tokenId = _auctionItem.tokenId;
    _basePrice = _auctionItem.basePrice;
    _seller = _auctionItem.seller;
    _startTime = _auctionItem.startTime;
    _endTime = _auctionItem.endTime;
    _state = _auctionItem.state;
    _bidIndexes = _auctionItem.bidIndexes;
  }

  function getAuctionItems(uint256[] _auctionIds) external view returns (
    uint256[] _tokenId,
    uint256[] _basePrice,
    address[] _seller,
    uint256[] _startTime,
    uint256[] _endTime,
    uint256[] _state,
    uint256[] _lastBidId
  ) {
    _tokenId = new uint256[](_auctionIds.length);
    _basePrice = new uint256[](_auctionIds.length);
    _startTime = new uint256[](_auctionIds.length);
    _endTime = new uint256[](_auctionIds.length);
    _state = new uint256[](_auctionIds.length);
    _lastBidId = new uint256[](_auctionIds.length);
    _seller = new address[](_auctionIds.length);

    for(uint256 i = 0 ; i < _auctionIds.length ; i++) {
      AuctionItem storage _auctionItem = auctionItems[_auctionIds[i]];
      _tokenId[i] = (_auctionItem.tokenId);
      _basePrice[i] = (_auctionItem.basePrice);
      _seller[i] = (_auctionItem.seller);
      _startTime[i] = (_auctionItem.startTime);
      _endTime[i] = (_auctionItem.endTime);
      _state[i] = (_auctionItem.state);

      for(uint256 j = _auctionItem.bidIndexes.length - 1 ; j > 0 ; j--) {
        if(_auctionItem.bidIndexes[j] > 0) {
          _lastBidId[i] = _auctionItem.bidIndexes[j];
          break;
        }
      }
    }
  }

  function totalAuctionItems() external view returns (uint256) {
    return auctionItems.length - 1;  
  }

  function getBid(uint256 _bidId) external view returns (
    uint256 _auctionId,
    uint256 _price,
    uint256 _time,
    address _bidder
  ) {
    Bid storage _bid = bidHistory[_bidId];
    _auctionId = _bid.auctionId;
    _price = _bid.price;
    _time = _bid.time;
    _bidder = _bid.bidder;
  }

  function getBids(uint256[] _bidIds) external view returns (
    uint256[] _auctionId,
    uint256[] _price,
    uint256[] _time,
    address[] _bidder
  ) {
    _auctionId = new uint256[](_bidIds.length);
    _price = new uint256[](_bidIds.length);
    _time = new uint256[](_bidIds.length);
    _bidder = new address[](_bidIds.length);

    for(uint256 i = 0 ; i < _bidIds.length ; i++) {
      Bid storage _bid = bidHistory[_bidIds[i]];
      _auctionId[i] = _bid.auctionId;
      _price[i] = _bid.price;
      _time[i] = _bid.time;
      _bidder[i] = _bid.bidder;
    }
  }

   
  function addTradeRecord
  (
    uint256 _tokenId,
    uint256 _auctionId,
    uint256 _price,
    uint256 _time,
    address _buyer,
    address _seller
  ) 
  external 
  returns (uint256 _tradeId)
  {
    require(canUpdate());

    _tradeId = tradeRecords.length;
    tradeRecords.push(TradeRecord(_tokenId, _auctionId, _price, uint48(_time), _buyer, _seller));

    if(_auctionId > 0) {
      auctionItems[_auctionId].state = uint8(2);
    }

    emit TradeRecordAdded(_seller, _buyer, _tradeId, _price, _tokenId, _auctionId);
  }

  function addAuctionItem
  (
    uint256 _tokenId,
    uint256 _basePrice,
    address _seller,
    uint256 _endTime
  ) 
  external
  returns (uint256 _auctionId)
  {
    require(canUpdate());

    _auctionId = auctionItems.length;
    auctionItems.push(AuctionItem(
      _tokenId,
      _basePrice, 
      _seller, 
      uint48(now), 
      uint48(_endTime),
      0,
      new uint256[](21)));

    emit AuctionItemAdded(_seller, _auctionId, _basePrice, _endTime - now, _tokenId);
  }

  function updateAuctionTime(uint256 _auctionId, uint256 _time, uint256 _state) external {
    require(canUpdate());

    AuctionItem storage _auctionItem = auctionItems[_auctionId];
    _auctionItem.endTime = uint48(_time);
    _auctionItem.state = uint8(_state);
  }

  function addBidder(uint256 _auctionId, address _bidder, uint256 _price, uint256 _bidIndex) external {
    require(canUpdate());

    uint256 _bidId = bidHistory.length;
    bidHistory.push(Bid(_auctionId, _price, uint48(now), _bidder));

    AuctionItem storage _auctionItem = auctionItems[_auctionId];

     
     
    address _previousBidder = address(0);
    for(uint256 i = _auctionItem.bidIndexes.length - 1 ; i > 0 ; i--) {
      if(_auctionItem.bidIndexes[i] > 0) {
        Bid memory _previousBid = bidHistory[_auctionItem.bidIndexes[i]];
        _previousBidder = _previousBid.bidder;
        break;
      }
    }

    _auctionItem.bidIndexes[_bidIndex] = _bidId;

    emit AuctionBid(_bidder, _previousBidder, _auctionId, _price, _bidIndex, _auctionItem.tokenId, _auctionItem.endTime);
  }

  function addWithdrawal
  (
    address _withdrawer,
    uint256 _auctionId,
    uint256 _value,
    uint256 _callTime
  )
  external 
  {
    require(canUpdate());

    WithdrawalRecord memory _withdrawal = WithdrawalRecord(_auctionId, _value, uint48(now), uint48(_callTime), false); 
    withdrawalList[_withdrawer].push(_withdrawal);
  }

  function clearPendingWithdrawal(address _withdrawer) external returns (uint256 _withdrawnAmount) {
    require(canUpdate());

    WithdrawalRecord[] storage _withdrawalList = withdrawalList[_withdrawer];
    uint256 _lastWithdrawnIndex = lastWithdrawnIndex[_withdrawer];

    for(uint256 i = _lastWithdrawnIndex ; i < _withdrawalList.length ; i++) {
      WithdrawalRecord storage _withdrawalRecord = _withdrawalList[i];
      _withdrawalRecord.hasWithdrawn = true;
      _withdrawnAmount += _withdrawalRecord.value;
    }

     
    lastWithdrawnIndex[_withdrawer] = _withdrawalList.length - 1;

    emit PendingWithdrawalCleared(_withdrawer, _withdrawnAmount);
  }
}

library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract CryptantCrabBase is Ownable {
  GenesisCrabInterface public genesisCrab;
  CryptantCrabNFT public cryptantCrabToken;
  CryptantCrabStoreInterface public cryptantCrabStorage;

  constructor(address _genesisCrabAddress, address _cryptantCrabTokenAddress, address _cryptantCrabStorageAddress) public {
     
    
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);
  }

  function setAddresses(
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  external onlyOwner {
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);
  }

  function _setAddresses(
    address _genesisCrabAddress,
    address _cryptantCrabTokenAddress,
    address _cryptantCrabStorageAddress
  )
  internal 
  {
    if(_genesisCrabAddress != address(0)) {
      GenesisCrabInterface genesisCrabContract = GenesisCrabInterface(_genesisCrabAddress);
      genesisCrab = genesisCrabContract;
    }
    
    if(_cryptantCrabTokenAddress != address(0)) {
      CryptantCrabNFT cryptantCrabTokenContract = CryptantCrabNFT(_cryptantCrabTokenAddress);
      cryptantCrabToken = cryptantCrabTokenContract;
    }
    
    if(_cryptantCrabStorageAddress != address(0)) {
      CryptantCrabStoreInterface cryptantCrabStorageContract = CryptantCrabStoreInterface(_cryptantCrabStorageAddress);
      cryptantCrabStorage = cryptantCrabStorageContract;
    }
  }
}

contract CryptantCrabInformant is CryptantCrabBase{
  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabBase
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
     

  }

  function _getCrabData(uint256 _tokenId) internal view returns 
  (
    uint256 _gene, 
    uint256 _level, 
    uint256 _exp, 
    uint256 _mutationCount,
    uint256 _trophyCount,
    uint256 _heartValue,
    uint256 _growthValue
  ) {
    require(cryptantCrabStorage != address(0));

    bytes32[] memory keys = new bytes32[](7);
    uint256[] memory values;

    keys[0] = keccak256(abi.encodePacked(_tokenId, "gene"));
    keys[1] = keccak256(abi.encodePacked(_tokenId, "level"));
    keys[2] = keccak256(abi.encodePacked(_tokenId, "exp"));
    keys[3] = keccak256(abi.encodePacked(_tokenId, "mutationCount"));
    keys[4] = keccak256(abi.encodePacked(_tokenId, "trophyCount"));
    keys[5] = keccak256(abi.encodePacked(_tokenId, "heartValue"));
    keys[6] = keccak256(abi.encodePacked(_tokenId, "growthValue"));

    values = cryptantCrabStorage.readUint256s(keys);

     
    uint256 _processedHeartValue;
    for(uint256 i = 1 ; i <= 1000 ; i *= 10) {
      if(uint256(values[5]) / i % 10 > 0) {
        _processedHeartValue += i;
      }
    }

    _gene = values[0];
    _level = values[1];
    _exp = values[2];
    _mutationCount = values[3];
    _trophyCount = values[4];
    _heartValue = _processedHeartValue;
    _growthValue = values[6];
  }

  function _geneOfCrab(uint256 _tokenId) internal view returns (uint256 _gene) {
    require(cryptantCrabStorage != address(0));

    _gene = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, "gene")));
  }
}

contract CrabManager is CryptantCrabInformant, CrabData {
  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
     
  }

  function getCrabsOfOwner(address _owner) external view returns (uint256[]) {
    uint256 _balance = cryptantCrabToken.balanceOf(_owner);
    uint256[] memory _tokenIds = new uint256[](_balance);

    for(uint256 i = 0 ; i < _balance ; i++) {
      _tokenIds[i] = cryptantCrabToken.tokenOfOwnerByIndex(_owner, i);
    }

    return _tokenIds;
  }

  function getCrab(uint256 _tokenId) external view returns (
    uint256 _gene,
    uint256 _level,
    uint256 _exp,
    uint256 _mutationCount,
    uint256 _trophyCount,
    uint256 _heartValue,
    uint256 _growthValue,
    uint256 _fossilType
  ) {
    require(cryptantCrabToken.exists(_tokenId));

    (_gene, _level, _exp, _mutationCount, _trophyCount, _heartValue, _growthValue) = _getCrabData(_tokenId);
    _fossilType = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, "fossilType")));
  }

  function getCrabStats(uint256 _tokenId) external view returns (
    uint256 _hp,
    uint256 _dps,
    uint256 _block,
    uint256[] _partBonuses,
    uint256 _fossilAttribute
  ) {
    require(cryptantCrabToken.exists(_tokenId));

    uint256 _gene = _geneOfCrab(_tokenId);
    (_hp, _dps, _block) = _getCrabTotalStats(_gene);
    _partBonuses = _getCrabPartBonuses(_tokenId);
    _fossilAttribute = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, "fossilAttribute")));
  }

  function _getCrabTotalStats(uint256 _gene) internal view returns (
    uint256 _hp, 
    uint256 _dps,
    uint256 _blockRate
  ) {
    CrabPartData[] memory crabPartData = _getCrabPartData(_gene);

    for(uint256 i = 0 ; i < crabPartData.length ; i++) {
      _hp += crabPartData[i].hp;
      _dps += crabPartData[i].dps;
      _blockRate += crabPartData[i].blockRate;
    }
  }

  function _getCrabPartBonuses(uint256 _tokenId) internal view returns (uint256[] _partBonuses) {
    bytes32[] memory _keys = new bytes32[](4);
    _keys[0] = keccak256(abi.encodePacked(_tokenId, uint256(1), "partBonus"));
    _keys[1] = keccak256(abi.encodePacked(_tokenId, uint256(2), "partBonus"));
    _keys[2] = keccak256(abi.encodePacked(_tokenId, uint256(3), "partBonus"));
    _keys[3] = keccak256(abi.encodePacked(_tokenId, uint256(4), "partBonus"));
    _partBonuses = cryptantCrabStorage.readUint256s(_keys);
  }

  function _getCrabPartData(uint256 _gene) internal view returns (CrabPartData[] memory _crabPartData) {
    require(cryptantCrabToken != address(0));
    uint256[] memory _bodyData;
    uint256[] memory _legData;
    uint256[] memory _leftClawData;
    uint256[] memory _rightClawData;
    
    (_bodyData, _legData, _leftClawData, _rightClawData) = cryptantCrabToken.crabPartDataFromGene(_gene);

    _crabPartData = new CrabPartData[](4);
    _crabPartData[0] = arrayToCrabPartData(_bodyData);
    _crabPartData[1] = arrayToCrabPartData(_legData);
    _crabPartData[2] = arrayToCrabPartData(_leftClawData);
    _crabPartData[3] = arrayToCrabPartData(_rightClawData);
  }
}

contract CryptantCrabPurchasableLaunch is CryptantCrabInformant {
  using SafeMath for uint256;

  Transmuter public transmuter;

  event CrabHatched(address indexed owner, uint256 tokenId, uint256 gene, uint256 specialSkin, uint256 crabPrice, uint256 growthValue);
  event CryptantFragmentsAdded(address indexed cryptantOwner, uint256 amount, uint256 newBalance);
  event CryptantFragmentsRemoved(address indexed cryptantOwner, uint256 amount, uint256 newBalance);
  event Refund(address indexed refundReceiver, uint256 reqAmt, uint256 paid, uint256 refundAmt);

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress,
    address _transmuterAddress
  ) 
  public 
  CryptantCrabInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
     
    if(_transmuterAddress != address(0)) {
      _setTransmuterAddress(_transmuterAddress);
    }
  }

  function setAddresses(
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress,
    address _transmuterAddress
  ) 
  external onlyOwner {
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);

    if(_transmuterAddress != address(0)) {
      _setTransmuterAddress(_transmuterAddress);
    }
  }

  function _setTransmuterAddress(address _transmuterAddress) internal {
    Transmuter _transmuterContract = Transmuter(_transmuterAddress);
    transmuter = _transmuterContract;
  }

  function getCryptantFragments(address _sender) public view returns (uint256) {
    return cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_sender, "cryptant")));
  }

  function createCrab(uint256 _customTokenId, uint256 _crabPrice, uint256 _customGene, uint256 _customSkin, bool _hasLegendary) external onlyOwner {
    _createCrab(_customTokenId, _crabPrice, _customGene, _customSkin, _hasLegendary);
  }
  function _addCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).add(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsAdded(_cryptantOwner, _amount, _newBalance);
  }

  function _removeCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).sub(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsRemoved(_cryptantOwner, _amount, _newBalance);
  }

  function _createCrab(uint256 _tokenId, uint256 _crabPrice, uint256 _customGene, uint256 _customSkin, bool _hasLegendary) internal {
    uint256[] memory _values = new uint256[](8);
    bytes32[] memory _keys = new bytes32[](8);

    uint256 _gene;
    uint256 _specialSkin;
    uint256 _heartValue;
    uint256 _growthValue;
    if(_customGene == 0) {
      (_gene, _specialSkin, _heartValue, _growthValue) = genesisCrab.generateCrabGene(false, _hasLegendary);
    } else {
      _gene = _customGene;
    }

    if(_customSkin != 0) {
      _specialSkin = _customSkin;
    }

    (_heartValue, _growthValue) = genesisCrab.generateCrabHeart();
    
    cryptantCrabToken.mintToken(msg.sender, _tokenId, _specialSkin);

     
    _keys[0] = keccak256(abi.encodePacked(_tokenId, "gene"));
    _values[0] = _gene;

     
    _keys[1] = keccak256(abi.encodePacked(_tokenId, "level"));
    _values[1] = 1;

     
    _keys[2] = keccak256(abi.encodePacked(_tokenId, "heartValue"));
    _values[2] = _heartValue;

     
    _keys[3] = keccak256(abi.encodePacked(_tokenId, "growthValue"));
    _values[3] = _growthValue;

     
    uint256[] memory _partLegendaryBonuses = transmuter.generateBonusForGene(_gene);
     
    _keys[4] = keccak256(abi.encodePacked(_tokenId, uint256(1), "partBonus"));
    _values[4] = _partLegendaryBonuses[0];

     
    _keys[5] = keccak256(abi.encodePacked(_tokenId, uint256(2), "partBonus"));
    _values[5] = _partLegendaryBonuses[1];

     
    _keys[6] = keccak256(abi.encodePacked(_tokenId, uint256(3), "partBonus"));
    _values[6] = _partLegendaryBonuses[2];

     
    _keys[7] = keccak256(abi.encodePacked(_tokenId, uint256(4), "partBonus"));
    _values[7] = _partLegendaryBonuses[3];

    require(cryptantCrabStorage.createUint256s(_keys, _values));

    emit CrabHatched(msg.sender, _tokenId, _gene, _specialSkin, _crabPrice, _growthValue);
  }

  function _refundExceededValue(uint256 _senderValue, uint256 _requiredValue) internal {
    uint256 _exceededValue = _senderValue.sub(_requiredValue);

    if(_exceededValue > 0) {
      msg.sender.transfer(_exceededValue);

      emit Refund(msg.sender, _requiredValue, _senderValue, _exceededValue);
    } 
  }
}

contract CryptantInformant is CryptantCrabInformant {
  using SafeMath for uint256;

  event CryptantFragmentsAdded(address indexed cryptantOwner, uint256 amount, uint256 newBalance);
  event CryptantFragmentsRemoved(address indexed cryptantOwner, uint256 amount, uint256 newBalance);

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
     

  }

  function getCryptantFragments(address _sender) public view returns (uint256) {
    return cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_sender, "cryptant")));
  }

  function _addCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).add(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsAdded(_cryptantOwner, _amount, _newBalance);
  }

  function _removeCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).sub(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsRemoved(_cryptantOwner, _amount, _newBalance);
  }
}

contract Transmuter is CryptantInformant, GeneSurgeon, Randomable, LevelCalculator {
  event Xenografted(address indexed tokenOwner, uint256 recipientTokenId, uint256 donorTokenId, uint256 oldPartGene, uint256 newPartGene, uint256 oldPartBonus, uint256 newPartBonus, uint256 xenograftPart);
  event Mutated(address indexed tokenOwner, uint256 tokenId, uint256 partIndex, uint256 oldGene, uint256 newGene, uint256 oldPartBonus, uint256 newPartBonus, uint256 mutationCount);

   
  bytes4 internal constant NORMAL_FOSSIL_RELIC_PERCENTAGE = 0xcaf6fae2;
  bytes4 internal constant PIONEER_FOSSIL_RELIC_PERCENTAGE = 0x04988c65;
  bytes4 internal constant LEGENDARY_FOSSIL_RELIC_PERCENTAGE = 0x277e613a;
  bytes4 internal constant FOSSIL_ATTRIBUTE_COUNT = 0x06c475be;
  bytes4 internal constant LEGENDARY_BONUS_COUNT = 0x45025094;
  bytes4 internal constant LAST_PIONEER_TOKEN_ID = 0xe562bae2;

  mapping(bytes4 => uint256) internal internalUintVariable;

   
  mapping(uint256 => uint256[]) internal legendaryPartIndex;

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
     

     
     
    _setUint(NORMAL_FOSSIL_RELIC_PERCENTAGE, 5000);

     
    _setUint(PIONEER_FOSSIL_RELIC_PERCENTAGE, 50000);

     
    _setUint(LEGENDARY_FOSSIL_RELIC_PERCENTAGE, 50000);

     
     
    _setUint(FOSSIL_ATTRIBUTE_COUNT, 6);

     
     
    _setUint(LEGENDARY_BONUS_COUNT, 5);

     
    _setUint(LAST_PIONEER_TOKEN_ID, 1121);
  }

  function setPartIndex(uint256 _element, uint256[] _partIndexes) external onlyOwner {
    legendaryPartIndex[_element] = _partIndexes;
  }

  function getPartIndexes(uint256 _element) external view onlyOwner returns (uint256[] memory _partIndexes){
    _partIndexes = legendaryPartIndex[_element];
  }

  function getUint(bytes4 key) external view returns (uint256 value) {
    value = _getUint(key);
  }

  function setUint(bytes4 key, uint256 value) external onlyOwner {
    _setUint(key, value);
  }

  function _getUint(bytes4 key) internal view returns (uint256 value) {
    value = internalUintVariable[key];
  }

  function _setUint(bytes4 key, uint256 value) internal {
    internalUintVariable[key] = value;
  }

  function xenograft(uint256 _recipientTokenId, uint256 _donorTokenId, uint256 _xenograftPart) external {
     
     
     
     
     
     
     
    require(_xenograftPart != 1);   
    require(cryptantCrabToken.ownerOf(_recipientTokenId) == msg.sender);   
    require(cryptantCrabToken.ownerOf(_donorTokenId) == msg.sender);

     
     
    uint256[] memory _intValues = new uint256[](11);
    _intValues[0] = getCryptantFragments(msg.sender);
     
     
     
     
     
     
     
     
     
     
     

     
    require(_intValues[0] >= 5000);

     
    uint256[] memory _values;
    bytes32[] memory _keys = new bytes32[](6);

    _keys[0] = keccak256(abi.encodePacked(_recipientTokenId, "fossilType"));
    _keys[1] = keccak256(abi.encodePacked(_donorTokenId, "fossilType"));
    _keys[2] = keccak256(abi.encodePacked(_donorTokenId, _xenograftPart, "partBonus"));
    _keys[3] = keccak256(abi.encodePacked(_recipientTokenId, _xenograftPart, "partBonus"));
    _keys[4] = keccak256(abi.encodePacked(_recipientTokenId, "level"));
    _keys[5] = keccak256(abi.encodePacked(_recipientTokenId, "exp"));
    _values = cryptantCrabStorage.readUint256s(_keys);

    require(_values[0] == 0);
    require(_values[1] == 0);

    _intValues[1] = _values[2];
    _intValues[8] = _values[3];

     
     
    _intValues[9] = _values[4];
    _intValues[10] = _values[5];

     
    _intValues[10] += 8;

     
    uint256 _expRequired = expRequiredToReachLevel(_intValues[9] + 1);
    if(_intValues[10] >=_expRequired) {
       
      _intValues[9] += 1;

       
      _intValues[10] -= _expRequired;

      emit LevelUp(msg.sender, _recipientTokenId, _intValues[9], _intValues[10]);
    } else {
      emit ExpGained(msg.sender, _recipientTokenId, _intValues[9], _intValues[10]);
    }

     
    _intValues[2] = _geneOfCrab(_recipientTokenId);
    _intValues[3] = _geneOfCrab(_donorTokenId);

     
    _intValues[4] = _intValues[2] / crabPartMultiplier[_xenograftPart] % 1000;
    _intValues[5] = _intValues[3] / crabPartMultiplier[_xenograftPart] % 1000;
    
    int256 _partDiff = int256(_intValues[4]) - int256(_intValues[5]);
    _intValues[2] = uint256(int256(_intValues[2]) - (_partDiff * int256(crabPartMultiplier[_xenograftPart])));
    
    _values = new uint256[](6);
    _keys = new bytes32[](6);

     
    _keys[0] = keccak256(abi.encodePacked(_recipientTokenId, "gene"));
    _values[0] = _intValues[2];

     
    _keys[1] = keccak256(abi.encodePacked(_donorTokenId, "fossilAttribute"));
    _values[1] = _generateRandomNumber(bytes32(_intValues[2] + _intValues[3] + _xenograftPart), _getUint(FOSSIL_ATTRIBUTE_COUNT)) + 1;

    
     
    if(isLegendaryPart(_intValues[3], 1)) {
       
      _intValues[7] = 2;
    } else {
       
      _intValues[6] = _getUint(NORMAL_FOSSIL_RELIC_PERCENTAGE);

      if(_donorTokenId <= _getUint(LAST_PIONEER_TOKEN_ID)) {
        _intValues[6] = _getUint(PIONEER_FOSSIL_RELIC_PERCENTAGE);
      }

      if(isLegendaryPart(_intValues[3], 2) ||
        isLegendaryPart(_intValues[3], 3) || isLegendaryPart(_intValues[3], 4)) {
        _intValues[6] += _getUint(LEGENDARY_FOSSIL_RELIC_PERCENTAGE);
      }

       
       
       
      _intValues[7] = 1;
      if(_generateRandomNumber(bytes32(_intValues[3] + _xenograftPart), 100000) < _intValues[6]) {
        _intValues[7] = 2;
      }
    }

    _keys[2] = keccak256(abi.encodePacked(_donorTokenId, "fossilType"));
    _values[2] = _intValues[7];

     
    _keys[3] = keccak256(abi.encodePacked(_recipientTokenId, _xenograftPart, "partBonus"));
    _values[3] = _intValues[1];

     
    _keys[4] = keccak256(abi.encodePacked(_recipientTokenId, "level"));
    _values[4] = _intValues[9];

     
    _keys[5] = keccak256(abi.encodePacked(_recipientTokenId, "exp"));
    _values[5] = _intValues[10];

    require(cryptantCrabStorage.updateUint256s(_keys, _values));

    _removeCryptantFragments(msg.sender, 5000);

    emit Xenografted(msg.sender, _recipientTokenId, _donorTokenId, _intValues[4], _intValues[5], _intValues[8], _intValues[1], _xenograftPart);
  }

  function mutate(uint256 _tokenId, uint256 _partIndex) external {
     
    require(cryptantCrabToken.ownerOf(_tokenId) == msg.sender);
     
    require(_partIndex > 1 && _partIndex < 5);

     
     
     
    _removeCryptantFragments(msg.sender, 1000);

    bytes32[] memory _keys = new bytes32[](5);
    _keys[0] = keccak256(abi.encodePacked(_tokenId, "gene"));
    _keys[1] = keccak256(abi.encodePacked(_tokenId, "level"));
    _keys[2] = keccak256(abi.encodePacked(_tokenId, "exp"));
    _keys[3] = keccak256(abi.encodePacked(_tokenId, "mutationCount"));
    _keys[4] = keccak256(abi.encodePacked(_tokenId, _partIndex, "partBonus"));

    uint256[] memory _values = new uint256[](5);
    (_values[0], _values[1], _values[2], _values[3], , , ) = _getCrabData(_tokenId);

    uint256[] memory _partsGene = new uint256[](5);
    uint256 i;
    for(i = 1 ; i <= 4 ; i++) {
      _partsGene[i] = _values[0] / crabPartMultiplier[i] % 1000;
    }

     
    if(_values[3] > 170) {
      _values[3] = 170;
    }

    uint256 newPartGene = genesisCrab.mutateCrabPart(_partIndex, _partsGene[_partIndex], (30 + _values[3]) * 100);

     
    uint256 _oldPartBonus = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, _partIndex, "partBonus")));
    uint256 _partGene;   
    uint256 _newGene;
    for(i = 1 ; i <= 4 ; i++) {
      _partGene = _partsGene[i];

      if(i == _partIndex) {
        _partGene = newPartGene;
      }

      _newGene += _partGene * crabPartMultiplier[i];
    }

    if(isLegendaryPart(_newGene, _partIndex)) {
      _values[4] = _generateRandomNumber(bytes32(_newGene + _partIndex + _tokenId), _getUint(LEGENDARY_BONUS_COUNT)) + 1;
    }

     
    _partGene = _values[0];

     
    _values[0] = _newGene;

     
    _values[2] += 8;

     
    uint256 _expRequired = expRequiredToReachLevel(_values[1] + 1);
    if(_values[2] >=_expRequired) {
       
      _values[1] += 1;

       
      _values[2] -= _expRequired;

      emit LevelUp(msg.sender, _tokenId, _values[1], _values[2]);
    } else {
      emit ExpGained(msg.sender, _tokenId, _values[1], _values[2]);
    }

     
    _values[3] += 1;

    require(cryptantCrabStorage.updateUint256s(_keys, _values));

    emit Mutated(msg.sender, _tokenId, _partIndex, _partGene, _newGene, _oldPartBonus, _values[4], _values[3]);
  }

  function generateBonusForGene(uint256 _gene) external view returns (uint256[] _bonuses) {
    _bonuses = new uint256[](4);
    uint256[] memory _elements = extractElementsFromGene(_gene);
    uint256[] memory _parts = extractPartsFromGene(_gene);    
    uint256[] memory _legendaryParts;

    for(uint256 i = 0 ; i < 4 ; i++) {
      _legendaryParts = legendaryPartIndex[_elements[i]];

      for(uint256 j = 0 ; j < _legendaryParts.length ; j++) {
        if(_legendaryParts[j] == _parts[i]) {
           
          _bonuses[i] = _generateRandomNumber(bytes32(_gene + i), _getUint(LEGENDARY_BONUS_COUNT)) + 1;
          break;
        }
      }
    }
  }

   
  function isLegendaryPart(uint256 _gene, uint256 _part) internal view returns (bool) {
    uint256[] memory _legendaryParts = legendaryPartIndex[extractElementsFromGene(_gene)[_part - 1]];
    for(uint256 i = 0 ; i < _legendaryParts.length ; i++) {
      if(_legendaryParts[i] == extractPartsFromGene(_gene)[_part - 1]) {
        return true;
      }
    }
    return false;
  }
}

contract Withdrawable is Ownable {
  address public withdrawer;

   
  modifier onlyWithdrawer() {
    require(msg.sender == withdrawer);
    _;
  }

  function setWithdrawer(address _newWithdrawer) external onlyOwner {
    withdrawer = _newWithdrawer;
  }

   
  function withdraw(uint256 _amount) external onlyWithdrawer returns(bool) {
    require(_amount <= address(this).balance);
    withdrawer.transfer(_amount);
    return true;
  }
}

contract CryptantCrabMarket is CryptantCrabPurchasableLaunch, GeneSurgeon, Randomable, Withdrawable {
  event Purchased(address indexed owner, uint256 amount, uint256 cryptant, uint256 refund);
  event ReferralPurchase(address indexed referral, uint256 rewardAmount, address buyer);
  event CrabOnSaleStarted(address indexed seller, uint256 tokenId, uint256 sellingPrice, uint256 marketId, uint256 gene);
  event CrabOnSaleCancelled(address indexed seller, uint256 tokenId, uint256 marketId);
  event Traded(address indexed seller, address indexed buyer, uint256 tokenId, uint256 tradedPrice, uint256 marketId);    

  struct MarketItem {
    uint256 tokenId;
    uint256 sellingPrice;
    address seller;
    uint8 state;               
  }

  PrizePool public prizePool;

   
  bytes4 internal constant MARKET_PRICE_UPDATE_PERIOD = 0xf1305a10;
  bytes4 internal constant CURRENT_TOKEN_ID = 0x21339464;
  bytes4 internal constant REFERRAL_CUT = 0x40b0b13e;
  bytes4 internal constant PURCHASE_PRIZE_POOL_CUT = 0x7625c58a;
  bytes4 internal constant EXCHANGE_PRIZE_POOL_CUT = 0xb9e1adb0;
  bytes4 internal constant EXCHANGE_DEVELOPER_CUT = 0xfe9ad0eb;
  bytes4 internal constant LAST_TRANSACTION_PERIOD = 0x1a01d5bb;
  bytes4 internal constant LAST_TRANSACTION_PRICE = 0xf14adb6a;

   
  uint256 constant public initialCrabTradingPrice = 300 finney;
  
   
   
   
  uint256 constant public initialCryptantFragmentTradingPrice = 30 szabo;

  mapping(bytes4 => uint256) internal internalUintVariable;

   
  uint256[] public tradedPrices;

   
  MarketItem[] public marketItems;

   
   
  bytes4 public currentPrizePool = 0xadd5d43f;

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress,
    address _transmuterAddress,
    address _prizePoolAddress
  ) 
  public 
  CryptantCrabPurchasableLaunch
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress,
    _transmuterAddress
  ) {
     
    if(_prizePoolAddress != address(0)) {
      _setPrizePoolAddress(_prizePoolAddress);
    }
    
     
    _setUint(CURRENT_TOKEN_ID, 1121);

     
     
    _setUint(MARKET_PRICE_UPDATE_PERIOD, 14400);

     
     
    _setUint(REFERRAL_CUT, 10000);

     
     
    _setUint(PURCHASE_PRIZE_POOL_CUT, 20000);

     
     
    _setUint(EXCHANGE_PRIZE_POOL_CUT, 2000);

     
     
    _setUint(EXCHANGE_DEVELOPER_CUT, 2800);

     
     
    marketItems.push(MarketItem(0, 0, address(0), 0));
  }

  function _setPrizePoolAddress(address _prizePoolAddress) internal {
    PrizePool _prizePoolContract = PrizePool(_prizePoolAddress);
    prizePool = _prizePoolContract;
  }

  function setAddresses(
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress,
    address _transmuterAddress,
    address _prizePoolAddress
  ) 
  external onlyOwner {
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);

    if(_transmuterAddress != address(0)) {
      _setTransmuterAddress(_transmuterAddress);
    }

    if(_prizePoolAddress != address(0)) {
      _setPrizePoolAddress(_prizePoolAddress);
    }
  }

  function setCurrentPrizePool(bytes4 _newPrizePool) external onlyOwner {
    currentPrizePool = _newPrizePool;
  }

  function getUint(bytes4 key) external view returns (uint256 value) {
    value = _getUint(key);
  }

  function setUint(bytes4 key, uint256 value) external onlyOwner {
    _setUint(key, value);
  }

  function _getUint(bytes4 key) internal view returns (uint256 value) {
    value = internalUintVariable[key];
  }

  function _setUint(bytes4 key, uint256 value) internal {
    internalUintVariable[key] = value;
  }

  function purchase(uint256 _crabAmount, uint256 _cryptantFragmentAmount, address _referral) external payable {
    require(_crabAmount >= 0 && _crabAmount <= 10 );
    require(_cryptantFragmentAmount >= 0 && _cryptantFragmentAmount <= 10000);
    require(!(_crabAmount == 0 && _cryptantFragmentAmount == 0));
    require(_cryptantFragmentAmount % 1000 == 0);
    require(msg.sender != _referral);

     
    uint256 _singleCrabPrice = getCurrentCrabPrice();
    uint256 _totalCrabPrice = _singleCrabPrice * _crabAmount;
    uint256 _totalCryptantPrice = getCurrentCryptantFragmentPrice() * _cryptantFragmentAmount;
    uint256 _cryptantFragmentsGained = _cryptantFragmentAmount;

     
    if(_cryptantFragmentsGained == 10000) {
      _cryptantFragmentsGained += 2000;
    }

    uint256 _totalPrice = _totalCrabPrice + _totalCryptantPrice;
    uint256 _value = msg.value;

    require(_value >= _totalPrice);

     
     
    uint256 _currentTokenId = _getUint(CURRENT_TOKEN_ID);
    uint256 _crabWithLegendaryPart = 100;
    if(_crabAmount == 10) {
       
      _crabWithLegendaryPart = _generateRandomNumber(bytes32(_currentTokenId), 10);
    }

    for(uint256 i = 0 ; i < _crabAmount ; i++) {
       
       
      if(_currentTokenId == 5000) {
        _currentTokenId = 5500;
      }

      _currentTokenId++;
      _createCrab(_currentTokenId, _singleCrabPrice, 0, 0, _crabWithLegendaryPart == i);
      tradedPrices.push(_singleCrabPrice);
    }

    if(_cryptantFragmentsGained > 0) {
      _addCryptantFragments(msg.sender, (_cryptantFragmentsGained));
    }

    _setUint(CURRENT_TOKEN_ID, _currentTokenId);
    
     
    _refundExceededValue(_value, _totalPrice);

     
    if(_referral != address(0)) {
      uint256 _referralReward = _totalPrice * _getUint(REFERRAL_CUT) / 100000;
      _referral.transfer(_referralReward);
      emit ReferralPurchase(_referral, _referralReward, msg.sender);
    }

     
    uint256 _prizePoolAmount = _totalPrice * _getUint(PURCHASE_PRIZE_POOL_CUT) / 100000;
    prizePool.increasePrizePool.value(_prizePoolAmount)(currentPrizePool);

    _setUint(LAST_TRANSACTION_PERIOD, now / _getUint(MARKET_PRICE_UPDATE_PERIOD));
    _setUint(LAST_TRANSACTION_PRICE, _singleCrabPrice);

    emit Purchased(msg.sender, _crabAmount, _cryptantFragmentsGained, _value - _totalPrice);
  }

  function getCurrentPeriod() external view returns (uint256 _now, uint256 _currentPeriod) {
    _now = now;
    _currentPeriod = now / _getUint(MARKET_PRICE_UPDATE_PERIOD);
  }

  function getCurrentCrabPrice() public view returns (uint256) {
    if(totalCrabTraded() > 25) {
      uint256 _lastTransactionPeriod = _getUint(LAST_TRANSACTION_PERIOD);
      uint256 _lastTransactionPrice = _getUint(LAST_TRANSACTION_PRICE);

      if(_lastTransactionPeriod == now / _getUint(MARKET_PRICE_UPDATE_PERIOD) && _lastTransactionPrice != 0) {
        return _lastTransactionPrice;
      } else {
        uint256 totalPrice;
        for(uint256 i = 1 ; i <= 15 ; i++) {
          totalPrice += tradedPrices[tradedPrices.length - i];
        }

         
         
        return totalPrice / 15;
      }
    } else {
      return initialCrabTradingPrice;
    }
  }

  function getCurrentCryptantFragmentPrice() public view returns (uint256 _price) {
    if(totalCrabTraded() > 25) {
       
       
      return getCurrentCrabPrice() * 10 / 100000;
    } else {
      return initialCryptantFragmentTradingPrice;
    }
  }

   
  function totalCrabTraded() public view returns (uint256) {
    return tradedPrices.length;
  }

  function sellCrab(uint256 _tokenId, uint256 _sellingPrice) external {
    require(cryptantCrabToken.ownerOf(_tokenId) == msg.sender);
    require(_sellingPrice >= 50 finney && _sellingPrice <= 100 ether);

    marketItems.push(MarketItem(_tokenId, _sellingPrice, msg.sender, 1));

     
    cryptantCrabToken.transferFrom(msg.sender, address(this), _tokenId);

    uint256 _gene = _geneOfCrab(_tokenId);

    emit CrabOnSaleStarted(msg.sender, _tokenId, _sellingPrice, marketItems.length - 1, _gene);
  }

  function cancelOnSaleCrab(uint256 _marketId) external {
    MarketItem storage marketItem = marketItems[_marketId];

     
    require(marketItem.state == 1);

     
    marketItem.state = 2;

     
    require(marketItem.seller == msg.sender);

     
    cryptantCrabToken.transferFrom(address(this), msg.sender, marketItem.tokenId);

    emit CrabOnSaleCancelled(msg.sender, marketItem.tokenId, _marketId);
  }

  function buyCrab(uint256 _marketId) external payable {
    MarketItem storage marketItem = marketItems[_marketId];
    require(marketItem.state == 1);    
    require(marketItem.sellingPrice == msg.value);
    require(marketItem.seller != msg.sender);

    cryptantCrabToken.safeTransferFrom(address(this), msg.sender, marketItem.tokenId);

    uint256 _developerCut = msg.value * _getUint(EXCHANGE_DEVELOPER_CUT) / 100000;
    uint256 _prizePoolCut = msg.value * _getUint(EXCHANGE_PRIZE_POOL_CUT) / 100000;
    uint256 _sellerAmount = msg.value - _developerCut - _prizePoolCut;
    marketItem.seller.transfer(_sellerAmount);

     
    prizePool.increasePrizePool.value(_prizePoolCut)(currentPrizePool);

    uint256 _fossilType = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(marketItem.tokenId, "fossilType")));
    if(_fossilType > 0) {
      tradedPrices.push(marketItem.sellingPrice);
    }

    marketItem.state = 3;

    _setUint(LAST_TRANSACTION_PERIOD, now / _getUint(MARKET_PRICE_UPDATE_PERIOD));
    _setUint(LAST_TRANSACTION_PRICE, getCurrentCrabPrice());

    emit Traded(marketItem.seller, msg.sender, marketItem.tokenId, marketItem.sellingPrice, _marketId);
  }

  function() public payable {
    revert();
  }
}

contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

contract PrizePool is Ownable, Whitelist, HasNoEther {
  event PrizePoolIncreased(uint256 amountIncreased, bytes4 prizePool, uint256 currentAmount);
  event WinnerAdded(address winner, bytes4 prizeTitle, uint256 claimableAmount);
  event PrizedClaimed(address winner, bytes4 prizeTitle, uint256 claimedAmount);

   
   
  mapping(bytes4 => uint256) prizePools;

   
   
   
  mapping(address => mapping(bytes4 => uint256)) winners;

  constructor() public {

  }

  function increasePrizePool(bytes4 _prizePool) external payable onlyIfWhitelisted(msg.sender) {
    prizePools[_prizePool] += msg.value;

    emit PrizePoolIncreased(msg.value, _prizePool, prizePools[_prizePool]);
  }

  function addWinner(address _winner, bytes4 _prizeTitle, uint256 _claimableAmount) external onlyIfWhitelisted(msg.sender) {
    winners[_winner][_prizeTitle] = _claimableAmount;

    emit WinnerAdded(_winner, _prizeTitle, _claimableAmount);
  }

  function claimPrize(bytes4 _prizeTitle) external {
    uint256 _claimableAmount = winners[msg.sender][_prizeTitle];

    require(_claimableAmount > 0);

    msg.sender.transfer(_claimableAmount);

    winners[msg.sender][_prizeTitle] = 0;

    emit PrizedClaimed(msg.sender, _prizeTitle, _claimableAmount);
  }

  function claimableAmount(address _winner, bytes4 _prizeTitle) external view returns (uint256 _claimableAmount) {
    _claimableAmount = winners[_winner][_prizeTitle];
  }

  function prizePoolTotal(bytes4 _prizePool) external view returns (uint256 _prizePoolTotal) {
    _prizePoolTotal = prizePools[_prizePool];
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

contract ERC721Basic is ERC165 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}

contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

contract CryptantCrabNFT is ERC721Token, Whitelist, CrabData, GeneSurgeon {
  event CrabPartAdded(uint256 hp, uint256 dps, uint256 blockAmount);
  event GiftTransfered(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event DefaultMetadataURIChanged(string newUri);

   
  bytes4 internal constant CRAB_BODY = 0xc398430e;
  bytes4 internal constant CRAB_LEG = 0x889063b1;
  bytes4 internal constant CRAB_LEFT_CLAW = 0xdb6290a2;
  bytes4 internal constant CRAB_RIGHT_CLAW = 0x13453f89;

   
  mapping(bytes4 => mapping(uint256 => CrabPartData[])) internal crabPartData;

   
  mapping(uint256 => uint256) internal crabSpecialSkins;

   
  string public defaultMetadataURI = "https://www.cryptantcrab.io/md/";

  constructor(string _name, string _symbol) public ERC721Token(_name, _symbol) {
     
    initiateCrabPartData();
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));

    string memory _uri = tokenURIs[_tokenId];

    if(bytes(_uri).length == 0) {
      _uri = getMetadataURL(bytes(defaultMetadataURI), _tokenId);
    }

    return _uri;
  }

   
  function dataOfPart(uint256 _partIndex, uint256 _element, uint256 _setIndex) public view returns (uint256[] memory _resultData) {
    bytes4 _key;
    if(_partIndex == 1) {
      _key = CRAB_BODY;
    } else if(_partIndex == 2) {
      _key = CRAB_LEG;
    } else if(_partIndex == 3) {
      _key = CRAB_LEFT_CLAW;
    } else if(_partIndex == 4) {
      _key = CRAB_RIGHT_CLAW;
    } else {
      revert();
    }

    CrabPartData storage _crabPartData = crabPartData[_key][_element][_setIndex];

    _resultData = crabPartDataToArray(_crabPartData);
  }

   
  function giftToken(address _from, address _to, uint256 _tokenId) external {
    safeTransferFrom(_from, _to, _tokenId);

    emit GiftTransfered(_from, _to, _tokenId);
  }

   
  function mintToken(address _tokenOwner, uint256 _tokenId, uint256 _skinId) external onlyIfWhitelisted(msg.sender) {
    super._mint(_tokenOwner, _tokenId);

    if(_skinId > 0) {
      crabSpecialSkins[_tokenId] = _skinId;
    }
  }

   
  function crabPartDataFromGene(uint256 _gene) external view returns (
    uint256[] _bodyData,
    uint256[] _legData,
    uint256[] _leftClawData,
    uint256[] _rightClawData
  ) {
    uint256[] memory _parts = extractPartsFromGene(_gene);
    uint256[] memory _elements = extractElementsFromGene(_gene);

    _bodyData = dataOfPart(1, _elements[0], _parts[0]);
    _legData = dataOfPart(2, _elements[1], _parts[1]);
    _leftClawData = dataOfPart(3, _elements[2], _parts[2]);
    _rightClawData = dataOfPart(4, _elements[3], _parts[3]);
  }

   
  function setPartData(uint256 _partIndex, uint256 _element, uint256[] _partDataArray) external onlyOwner {
    CrabPartData memory _partData = arrayToCrabPartData(_partDataArray);

    bytes4 _key;
    if(_partIndex == 1) {
      _key = CRAB_BODY;
    } else if(_partIndex == 2) {
      _key = CRAB_LEG;
    } else if(_partIndex == 3) {
      _key = CRAB_LEFT_CLAW;
    } else if(_partIndex == 4) {
      _key = CRAB_RIGHT_CLAW;
    }

     
    if(crabPartData[_key][_element][1].hp == 0 && crabPartData[_key][_element][1].dps == 0) {
      crabPartData[_key][_element][1] = _partData;
    } else {
      crabPartData[_key][_element].push(_partData);
    }

    emit CrabPartAdded(_partDataArray[0], _partDataArray[1], _partDataArray[2]);
  }

   
  function setDefaultMetadataURI(string _defaultUri) external onlyOwner {
    defaultMetadataURI = _defaultUri;

    emit DefaultMetadataURIChanged(_defaultUri);
  }

   
  function setTokenURI(uint256 _tokenId, string _uri) external onlyIfWhitelisted(msg.sender) {
    _setTokenURI(_tokenId, _uri);
  }

   
  function specialSkinOfTokenId(uint256 _tokenId) external view returns (uint256) {
    return crabSpecialSkins[_tokenId];
  }

   
  function initiateCrabPartData() internal {
    require(crabPartData[CRAB_BODY][1].length == 0);

    for(uint256 i = 1 ; i <= 5 ; i++) {
      crabPartData[CRAB_BODY][i].length = 2;
      crabPartData[CRAB_LEG][i].length = 2;
      crabPartData[CRAB_LEFT_CLAW][i].length = 2;
      crabPartData[CRAB_RIGHT_CLAW][i].length = 2;
    }
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender) || whitelist(_spender);
  }

   
  function getMetadataURL(bytes _uri, uint256 _tokenId) internal pure returns (string) {
    uint256 _tmpTokenId = _tokenId;
    uint256 _tokenLength;

     
    do {
      _tokenLength++;
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

     
    bytes memory _result = new bytes(_uri.length + _tokenLength);

     
    for(uint256 i = 0 ; i < _uri.length ; i ++) {
      _result[i] = _uri[i];
    }

     
    uint256 lastIndex = _result.length - 1;
    for(_tmpTokenId = _tokenId ; _tmpTokenId > 0 ; _tmpTokenId /= 10) {
      _result[lastIndex--] = byte(48 + _tmpTokenId % 10);
    }

    return string(_result);
  }
}