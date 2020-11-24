 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract CanReclaimToken is Ownable {

   
  function reclaimToken(IERC20 token) external onlyOwner {
    if (address(token) == address(0)) {
      owner().transfer(address(this).balance);
      return;
    }
    uint256 balance = token.balanceOf(this);
    token.transfer(owner(), balance);
  }

}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract ServiceRole {
  using Roles for Roles.Role;

  event ServiceAdded(address indexed account);
  event ServiceRemoved(address indexed account);

  Roles.Role private services;

  constructor() internal {
    _addService(msg.sender);
  }

  modifier onlyService() {
    require(isService(msg.sender));
    _;
  }

  function isService(address account) public view returns (bool) {
    return services.has(account);
  }

  function renounceService() public {
    _removeService(msg.sender);
  }

  function _addService(address account) internal {
    services.add(account);
    emit ServiceAdded(account);
  }

  function _removeService(address account) internal {
    services.remove(account);
    emit ServiceRemoved(account);
  }
}

 

interface HEROES {
  function mint(address to, uint256 genes, uint256 level)  external returns (uint);
}

 
interface CHR {
  function mint(address _to, uint256 _amount) external returns (bool);
}

contract SaleFix is Ownable, ServiceRole, ReentrancyGuard, CanReclaimToken {
  using SafeMath for uint256;

  event ItemUpdate(uint256 indexed itemId, uint256 genes, uint256 level, uint256 price, uint256 count);
  event Sold(address indexed to, uint256 indexed tokenId, uint256 indexed itemId, uint256 genes, uint256 level, uint256 price);
  event CoinReward(uint256 code, uint256 coins);
  event EthReward(uint256 code, uint256 eth);
  event CoinRewardGet(uint256 code, uint256 coins);
  event EthRewardGet(uint256 code, uint256 eth);
  event Income(address source, uint256 amount);

  HEROES public heroes;
  CHR public coin;

   
  struct Item {
    bool exists;
    uint256 index;
    uint256 genes;
    uint256 level;
    uint256 price;
    uint256 count;
  }

   
  mapping(uint256 => Item) items;
   
  mapping(uint256 => uint) public market;
  uint256 public marketSize;

  uint256 public lastItemId;


   
  struct Affiliate {
    uint256 affCode;
    uint256 coinsToMint;
    uint256 ethToSend;
    uint256 coinsMinted;
    uint256 ethSent;
    bool active;
  }

  struct AffiliateReward {
    uint256 coins;
     
    uint256 percent;
  }

   
  struct StaffReward {
     
    uint256 coins;
    uint256 percent;
    uint256 index;
    bool exists;
  }

   
   
  mapping (uint256 => StaffReward) public staffReward;
   
  mapping (uint256 => uint) public staffList;
  uint256 public staffCount;

   
  mapping(uint256 => Affiliate) public affiliates;
  mapping(uint256 => bool) public vipAffiliates;
  AffiliateReward[] public affLevelReward;
  AffiliateReward[] public vipAffLevelReward;

   
  uint256 public totalReserved;

  constructor(HEROES _heroes, CHR _coin) public {
    require(address(_heroes) != address(0));
    require(address(_coin) != address(0));
    heroes = _heroes;
    coin = _coin;

    affLevelReward.push(AffiliateReward({coins : 2, percent : 0}));  
    affLevelReward.push(AffiliateReward({coins : 1, percent : 1000}));  
    affLevelReward.push(AffiliateReward({coins : 0, percent : 500}));  
  
    vipAffLevelReward.push(AffiliateReward({coins : 2, percent : 0}));  
    vipAffLevelReward.push(AffiliateReward({coins : 1, percent : 2000}));  
    vipAffLevelReward.push(AffiliateReward({coins : 0, percent : 1000}));  
  }

   
  function() external payable {
    require(msg.value > 0);
    _flushBalance();
  }

  function _flushBalance() private {
    uint256 balance = address(this).balance.sub(totalReserved);
    if (balance > 0) {
      address(heroes).transfer(balance);
      emit Income(address(this), balance);
    }
  }

  function addService(address account) public onlyOwner {
    _addService(account);
  }

  function removeService(address account) public onlyOwner {
    _removeService(account);
  }

 
 
 
 


  function setAffiliateLevel(uint256 _level, uint256 _rewardCoins, uint256 _rewardPercent) external onlyOwner {
    require(_level < affLevelReward.length);
    AffiliateReward storage rew = affLevelReward[_level];
    rew.coins = _rewardCoins;
    rew.percent = _rewardPercent;
  }


  function incAffiliateLevel(uint256 _rewardCoins, uint256 _rewardPercent) external onlyOwner {
    affLevelReward.push(AffiliateReward({coins : _rewardCoins, percent : _rewardPercent}));
  }

  function decAffiliateLevel() external onlyOwner {
    delete affLevelReward[affLevelReward.length--];
  }

  function affLevelsCount() external view returns (uint) {
    return affLevelReward.length;
  }

  function setVipAffiliateLevel(uint256 _level, uint256 _rewardCoins, uint256 _rewardPercent) external onlyOwner {
    require(_level < vipAffLevelReward.length);
    AffiliateReward storage rew = vipAffLevelReward[_level];
    rew.coins = _rewardCoins;
    rew.percent = _rewardPercent;
  }

  function incVipAffiliateLevel(uint256 _rewardCoins, uint256 _rewardPercent) external onlyOwner {
    vipAffLevelReward.push(AffiliateReward({coins : _rewardCoins, percent : _rewardPercent}));
  }

  function decVipAffiliateLevel() external onlyOwner {
    delete vipAffLevelReward[vipAffLevelReward.length--];
  }

  function vipAffLevelsCount() external view returns (uint) {
    return vipAffLevelReward.length;
  }

  function addVipAffiliates(address[] _affiliates) external onlyOwner {
    require(_affiliates.length > 0);
    for(uint256 i = 0; i < _affiliates.length; i++) {
      vipAffiliates[_getAffCode(uint(_affiliates[i]))] = true;
    }
  }

  function delVipAffiliates(address[] _affiliates) external onlyOwner {
    require(_affiliates.length > 0);
    for(uint256 i = 0; i < _affiliates.length; i++) {
      delete vipAffiliates[_getAffCode(uint(_affiliates[i]))];
    }
  }

  function addStaff(address _staff, uint256 _percent) external onlyOwner {
    require(_staff != address(0) && _percent > 0);
    uint256 affCode = _getAffCode(uint(_staff));
    StaffReward storage sr = staffReward[affCode];
    if (!sr.exists) {
      sr.exists = true;
      sr.index = staffCount;
      staffList[staffCount++] = affCode;
    }
    sr.percent = _percent;
  }

  function delStaff(address _staff) external onlyOwner {
    require(_staff != address(0));
    uint256 affCode = _getAffCode(uint(_staff));
    StaffReward storage sr = staffReward[affCode];
    require(sr.exists);

    staffReward[staffList[--staffCount]].index = staffReward[affCode].index;
    staffList[staffReward[affCode].index] = staffList[staffCount];
    delete staffList[staffCount];
    delete staffReward[affCode];
  }

   

  function addItem(uint256 genes, uint256 level, uint256 price, uint256 count) external onlyService {
    items[++lastItemId] = Item({
      exists : true,
      index : marketSize,
      genes : genes,
      level : level,
      price : price,
      count : count
      });
    market[marketSize++] = lastItemId;
    emit ItemUpdate(lastItemId, genes, level,  price, count);
  }

  function delItem(uint256 itemId) external onlyService {
    require(items[itemId].exists);
    items[market[--marketSize]].index = items[itemId].index;
    market[items[itemId].index] = market[marketSize];
    delete market[marketSize];
    delete items[itemId];
    emit ItemUpdate(itemId, 0, 0, 0, 0);
  }

  function setPrice(uint256 itemId, uint256 price) external onlyService {
    Item memory i = items[itemId];
    require(i.exists);
    require(i.price != price);
    i.price = price;
    emit ItemUpdate(itemId, i.genes, i.level, i.price, i.count);
  }

  function setCount(uint256 itemId, uint256 count) external onlyService {
    Item storage i = items[itemId];
    require(i.exists);
    require(i.count != count);
    i.count = count;
    emit ItemUpdate(itemId, i.genes, i.level, i.price, i.count);
  }

  function getItem(uint256 itemId) external view returns (uint256 genes, uint256 level, uint256 price, uint256 count) {
    Item memory i = items[itemId];
    require(i.exists);
    return (i.genes, i.level, i.price, i.count);
  }


   

  function myAffiliateCode() public view returns (uint) {
    return _getAffCode(uint(msg.sender));
  }

  function _getAffCode(uint256 _a) internal pure returns (uint) {
    return (_a ^ (_a >> 80)) & 0xFFFFFFFFFFFFFFFFFFFF;
  }

  function buyItem(uint256 itemId, uint256 _affCode) public payable returns (uint256 tokenId) {
    Item memory i = items[itemId];
    require(i.exists);
    require(i.count > 0);
    require(msg.value == i.price);

     
    i.count--;
    tokenId = heroes.mint(msg.sender, i.genes, i.level);

    emit ItemUpdate(itemId, i.genes, i.level, i.price, i.count);
    emit Sold(msg.sender, tokenId, itemId, i.genes, i.level, i.price);

     
    uint256 _pCode = _getAffCode(uint(msg.sender));
    Affiliate storage p = affiliates[_pCode];

     
    if (!p.active) {
      p.active = true;
    }

     

     
     
    if (_affCode != 0 && _affCode != _pCode && _affCode != p.affCode) {
         
        p.affCode = _affCode;
    }

     
    _distributeAffiliateReward(i.price, _pCode, 0);

     
    _distributeStaffReward(i.price, _pCode);

    _flushBalance();
  }

  function _distributeAffiliateReward(uint256 _sum, uint256 _affCode, uint256 _level) internal {
    Affiliate storage aff = affiliates[_affCode];
    AffiliateReward storage ar = vipAffiliates[_affCode] ? vipAffLevelReward[_level] : affLevelReward[_level];
    if (ar.coins > 0) {
      aff.coinsToMint = aff.coinsToMint.add(ar.coins);
      emit CoinReward(_affCode, ar.coins);
    }
    if (ar.percent > 0) {
      uint256 pcnt = _getPercent(_sum, ar.percent);
      aff.ethToSend = aff.ethToSend.add(pcnt);
      totalReserved = totalReserved.add(pcnt);
      emit EthReward(_affCode, pcnt);
    }
    if (++_level < affLevelReward.length && aff.affCode != 0) {
      _distributeAffiliateReward(_sum, aff.affCode, _level);
    }
  }

   
  function _distributeStaffReward(uint256 _sum, uint256 _affCode) internal {
    for (uint256 i = 0; i < staffCount; i++) {
      if (_affCode != staffList[i]) {
        Affiliate storage aff = affiliates[staffList[i]];
        StaffReward memory sr = staffReward[staffList[i]];
        if (sr.coins > 0) {
          aff.coinsToMint = aff.coinsToMint.add(sr.coins);
          emit CoinReward(_affCode, sr.coins);
        }
        if (sr.percent > 0) {
          uint256 pcnt = _getPercent(_sum, sr.percent);
          aff.ethToSend = aff.ethToSend.add(pcnt);
          totalReserved = totalReserved.add(pcnt);
          emit EthReward(_affCode, pcnt);
        }
      }
    }
  }

   
  function getReward() external nonReentrant {
     
    uint256 _pCode = _getAffCode(uint(msg.sender));
    Affiliate storage p = affiliates[_pCode];
    require(p.active);

     
    if (p.coinsToMint > 0) {
      require(coin.mint(msg.sender, p.coinsToMint));
      p.coinsMinted = p.coinsMinted.add(p.coinsToMint);
      emit CoinRewardGet(_pCode, p.coinsToMint);
      p.coinsToMint = 0;
    }
     
    if (p.ethToSend > 0) {
      msg.sender.transfer(p.ethToSend);
      p.ethSent = p.ethSent.add(p.ethToSend);
      totalReserved = totalReserved.sub(p.ethToSend);
      emit EthRewardGet(_pCode, p.ethToSend);
      p.ethToSend = 0;
    }
  }

   
   
  function _getPercent(uint256 _v, uint256 _p) internal pure returns (uint)    {
    return _v.mul(_p).div(10000);
  }
}