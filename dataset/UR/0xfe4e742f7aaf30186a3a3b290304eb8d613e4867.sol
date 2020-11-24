 

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
  function getLevel(uint256 tokenId) external view returns (uint256);
  function getGenes(uint256 tokenId) external view returns (uint256);
  function getRace(uint256 tokenId) external view returns (uint256);
  function lock(uint256 tokenId, uint256 lockedTo, bool onlyFreeze) external returns (bool);
  function unlock(uint256 tokenId) external returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
  function addWin(uint256 tokenId, uint winsCount, uint levelUp) external returns (bool);
  function addLoss(uint256 tokenId, uint256 lossesCount, uint levelDown) external returns (bool);
}

 
interface CHR {
   
  function burn(address _from, uint256 _amount) external returns (bool);
}


contract Fights is Ownable, ServiceRole, ReentrancyGuard, CanReclaimToken {
  using SafeMath for uint256;

  event SetFightInterval(uint startsFrom, uint pastFightsCount, uint fightsInterval, uint fightPeriod, uint applicationPeriod, uint betsPeriod);
  event EnterArena(uint tokenId, uint fightId, uint startsAt, uint level, uint enemyRace);
  event ChangeEnemy(uint tokenId, uint fightId, uint enemyRace);
  event LeaveArena(uint tokenId, uint fightId, Result result, uint level);
  event StartFight(uint fightId, uint startAt);
  event RemoveFight(uint fightId);
  event FightResult(uint fightId, uint[] races, uint[] values);
  event FinishFight(uint fightId, uint startedAt, uint finishedAt, uint startCheckedAt, uint finishCheckedAt);

  HEROES public heroes;
  CHR public coin;

  enum Result {QUAIL, WIN, LOSS, DRAW}

  struct Fighter {
    uint index;
    bool exists;
    uint race;
    uint level;
    uint enemyRace;
    bool finished;
  }

  struct Race {
    uint index;
    bool exists;
    uint count;  
    uint enemyCount;  
    uint levelSum;  
     
    mapping(uint => uint) levelCount;  
     
     
     
     
    int32 result;
  }

  struct Fight {
    uint startedAt;
    uint finishedAt;
    uint startCheckedAt;
    uint finishCheckedAt;
     
    mapping(uint => uint) arena;
     
    mapping(uint => Fighter) fighters;
    uint fightersCount;
     
    mapping(uint => Race) races;
     
    mapping(uint => uint) raceList;
    uint raceCount;
  }


   
  uint[] public fightsList;
   
  mapping(uint => uint[]) public characterFights;

   
   
   
  mapping(uint => Fight) fights;

   
  struct FightInterval {
    uint fightsInterval;
    uint startsFrom;
    uint fightsCount;  
    uint betsPeriod;
    uint applicationPeriod;
    uint fightPeriod;
  }

   
   
  FightInterval[] public intervalHistory;

  uint public constant FightEpoch = 1542240000;  
  uint public minBetsLevel = 5;
  bool public allowEnterDuringBets = true;

  modifier onlyOwnerOf(uint256 _tokenId) {
    require(heroes.ownerOf(_tokenId) == msg.sender);
    _;
  }

  constructor(HEROES _heroes, CHR _coin) public {
    require(address(_heroes) != address(0));
    require(address(_coin) != address(0));
    heroes = _heroes;
    coin = _coin;

     
     
     
     

    intervalHistory.push(FightInterval({
      fightPeriod: 5 * 60 * 60,  
      startsFrom : FightEpoch,
      fightsCount : 0,
      fightsInterval : 12 * 60 * 60,  
      betsPeriod : 2 * 60 * 60,  
      applicationPeriod : 11 * 60 * 60  
      }));
  }

   
  function() external payable {
    require(msg.value > 0);
    address(heroes).transfer(msg.value);
  }

  function addService(address account) public onlyOwner {
    _addService(account);
  }

  function removeService(address account) public onlyOwner {
    _removeService(account);
  }


   
  function setFightInterval(uint _fightsInterval, uint _applicationPeriod, uint _betsPeriod, uint _fightPeriod) external onlyOwner {
    FightInterval memory i = _getFightIntervalAt(now);
     
     
    uint intervalsCount = (now - i.startsFrom) / i.fightsInterval + 1;
    FightInterval memory ni = FightInterval({
      fightsInterval : _fightsInterval,
      startsFrom : i.startsFrom + i.fightsInterval * intervalsCount,
      fightsCount : intervalsCount + i.fightsCount,
      applicationPeriod : _applicationPeriod,
      betsPeriod : _betsPeriod,
      fightPeriod : _fightPeriod
      });
    intervalHistory.push(ni);
    emit SetFightInterval(ni.startsFrom, ni.fightsCount, _fightsInterval, _fightPeriod, _applicationPeriod, _betsPeriod);
  }

   
  function setParameters(uint _minBetsLevel, bool _allowEnterDuringBets) external onlyOwner {
    minBetsLevel = _minBetsLevel;
    allowEnterDuringBets = _allowEnterDuringBets;
  }

  function enterArena(uint _tokenId, uint _enemyRace) public onlyOwnerOf(_tokenId) {
     
    require(isAllowed(_tokenId));
    uint intervalId = _getFightIntervalIdAt(now);
    FightInterval memory i = intervalHistory[intervalId];
    uint nextStartsAt = _getFightStartsAt(intervalId, 1);
     
    require(now >= nextStartsAt - i.applicationPeriod);
     
    require(now < nextStartsAt - (allowEnterDuringBets ? 0 : i.betsPeriod));

    uint nextFightId = getFightId(intervalId, 1);
    Fight storage f = fights[nextFightId];
     
 

     
    require(!f.fighters[_tokenId].exists);

    uint level = heroes.getLevel(_tokenId);
    uint race = heroes.getRace(_tokenId);
    require(race != _enemyRace);

     
    if (f.startedAt == 0) {
      f.startedAt = nextStartsAt;
      fightsList.push(nextFightId);
      emit StartFight(nextFightId, nextStartsAt);
       
    }

     
    f.fighters[_tokenId] = Fighter({
      exists : true,
      finished : false,
      index : f.fightersCount,
      race : race,
      enemyRace : _enemyRace,
      level: level
      });
    f.arena[f.fightersCount++] = _tokenId;
     
    characterFights[_tokenId].push(nextFightId);

    Race storage r = f.races[race];
    if (!r.exists) {
      r.exists = true;
      r.index = f.raceCount;
      f.raceList[f.raceCount++] = race;
    }
    r.count++;
     
     
    if (level >= minBetsLevel) {
       
      if (r.levelCount[level] == 0) {
         
        r.levelSum = r.levelSum.add(level);
      }
       
      r.levelCount[level]++;
    }
     
     
    Race storage er = f.races[_enemyRace];
    if (!er.exists) {
      er.exists = true;
      er.index = f.raceCount;
      f.raceList[f.raceCount++] = _enemyRace;
    }
    er.enemyCount++;

     
    require(heroes.lock(_tokenId, nextStartsAt + i.fightPeriod, false));
    emit EnterArena(_tokenId, nextFightId, nextStartsAt, level, _enemyRace);

  }


  function changeEnemy(uint _tokenId, uint _enemyRace) public onlyOwnerOf(_tokenId) {
    uint fightId = characterLastFightId(_tokenId);

     
    require(fightId != 0);
    Fight storage f = fights[fightId];
    Fighter storage fr = f.fighters[_tokenId];
     
     
    require(fr.exists);
     
    require(!fr.finished);

     
    require(fr.enemyRace != _enemyRace);

    FightInterval memory i = _getFightIntervalAt(f.startedAt);

     
     
     
    require(now >= f.startedAt - i.applicationPeriod && now < f.startedAt - i.betsPeriod && f.finishedAt != 0);

    fr.enemyRace = _enemyRace;

     
    Race storage er_old = f.races[fr.enemyRace];
    er_old.enemyCount--;

    if (er_old.count == 0 && er_old.enemyCount == 0) {
      f.races[f.raceList[--f.raceCount]].index = er_old.index;
      f.raceList[er_old.index] = f.raceList[f.raceCount];
      delete f.arena[f.raceCount];
      delete f.races[fr.enemyRace];
    }

     
     
    Race storage er_new = f.races[_enemyRace];
    if (!er_new.exists) {
      er_new.index = f.raceCount;
      f.raceList[f.raceCount++] = _enemyRace;
    }
    er_new.enemyCount++;
    emit ChangeEnemy(_tokenId, fightId, _enemyRace);
  }

  function reenterArena(uint _tokenId, uint _enemyRace, bool _useCoin) public onlyOwnerOf(_tokenId) {
    uint fightId = characterLastFightId(_tokenId);
     
    require(fightId != 0);
    Fight storage f = fights[fightId];
    Fighter storage fr = f.fighters[_tokenId];
     
     
    require(fr.exists);
     
 

     
    require(!fr.finished);

     
    require(f.finishedAt != 0 && now > f.finishedAt);

    Result result = Result.QUAIL;

     
    if (f.races[f.fighters[_tokenId].race].result > f.races[f.fighters[_tokenId].enemyRace].result) {
      result = Result.WIN;
       
      heroes.addWin(_tokenId, 1, 1);
    } else if (f.races[f.fighters[_tokenId].race].result < f.races[f.fighters[_tokenId].enemyRace].result) {
      result = Result.LOSS;
       
      if (_useCoin) {
        require(coin.burn(heroes.ownerOf(_tokenId), 1));
         
        heroes.addLoss(_tokenId, 1, 0);
      } else {
         
        heroes.addLoss(_tokenId, 1, 1);
      }
    } else {
       
 
    }
    fr.finished = true;

    emit LeaveArena(_tokenId, fightId, result, fr.level);
     
    enterArena(_tokenId, _enemyRace);
  }


   
  function leaveArena(uint _tokenId, bool _useCoin) public onlyOwnerOf(_tokenId) {
    uint fightId = characterLastFightId(_tokenId);

     
    require(fightId != 0);
    Fight storage f = fights[fightId];
    Fighter storage fr = f.fighters[_tokenId];
     
     
    require(fr.exists);

     
     

     
    require(!fr.finished);

    FightInterval memory i = _getFightIntervalAt(f.startedAt);

     
    require(now < f.startedAt - i.betsPeriod || (f.finishedAt != 0 && now > f.finishedAt));
    Result result = Result.QUAIL;
     
    if (f.finishedAt == 0) {

      Race storage r = f.races[fr.race];
       
      if (fr.level >= minBetsLevel) {
         
        r.levelCount[fr.level]--;
         
        if (r.levelCount[fr.level] == 0) {
          r.levelSum = r.levelSum.sub(fr.level);
        }
      }
      r.count--;

      Race storage er = f.races[fr.enemyRace];
      er.enemyCount--;

       
      if (r.count == 0 && r.enemyCount == 0) {
        f.races[f.raceList[--f.raceCount]].index = r.index;
        f.raceList[r.index] = f.raceList[f.raceCount];
        delete f.arena[f.raceCount];
        delete f.races[fr.race];
      }
      if (er.count == 0 && er.enemyCount == 0) {
          f.races[f.raceList[--f.raceCount]].index = er.index;
        f.raceList[er.index] = f.raceList[f.raceCount];
        delete f.arena[f.raceCount];
        delete f.races[fr.enemyRace];
      }

       
      f.fighters[f.arena[--f.fightersCount]].index = fr.index;
      f.arena[fr.index] = f.arena[f.fightersCount];
      delete f.arena[f.fightersCount];
      delete f.fighters[_tokenId];
       
      delete characterFights[_tokenId][characterFights[_tokenId].length--];

       
      if (f.fightersCount == 0) {
        delete fights[fightId];
        emit RemoveFight(fightId);
      }
    } else {

       
      if (f.races[f.fighters[_tokenId].race].result > f.races[f.fighters[_tokenId].enemyRace].result) {
        result = Result.WIN;
        heroes.addWin(_tokenId, 1, 1);
      } else if (f.races[f.fighters[_tokenId].race].result < f.races[f.fighters[_tokenId].enemyRace].result) {
        result = Result.LOSS;
         
        if (_useCoin) {
           
          require(coin.burn(heroes.ownerOf(_tokenId), 1));
           
          heroes.addLoss(_tokenId, 1, 0);
        } else {
          heroes.addLoss(_tokenId, 1, 1);
        }
      } else {
         
        result = Result.DRAW;
      }

      fr.finished = true;
    }
     
    require(heroes.unlock(_tokenId));
    emit LeaveArena(_tokenId, fightId, result, fr.level);

  }

  function fightsCount() public view returns (uint) {
    return fightsList.length;
  }

   
  function getCurrentFightId() public view returns (uint) {
    return getFightId(_getFightIntervalIdAt(now), 0);
  }

  function getNextFightId() public view returns (uint) {
    return getFightId(_getFightIntervalIdAt(now), 1);
  }

  function getFightId(uint intervalId, uint nextShift) internal view returns (uint) {
    FightInterval memory i = intervalHistory[intervalId];
    return (now - i.startsFrom) / i.fightsInterval + i.fightsCount + nextShift;
  }

  function characterFightsCount(uint _tokenId) public view returns (uint) {
    return characterFights[_tokenId].length;
  }

  function characterLastFightId(uint _tokenId) public view returns (uint) {
     
    return characterFights[_tokenId].length > 0 ? characterFights[_tokenId][characterFights[_tokenId].length - 1] : 0;
  }

  function characterLastFight(uint _tokenId) public view returns (
    uint index,
    uint race,
    uint level,
    uint enemyRace,
    bool finished
  ) {
    return getFightFighter(characterLastFightId(_tokenId), _tokenId);
  }

  function getFightFighter(uint _fightId, uint _tokenId) public view returns (
    uint index,
    uint race,
    uint level,
    uint enemyRace,
    bool finished
  ) {
    Fighter memory fr = fights[_fightId].fighters[_tokenId];
    return (fr.index, fr.race, fr.level, fr.enemyRace, fr.finished);
  }

  function getFightArenaFighter(uint _fightId, uint _fighterIndex) public view returns (
    uint tokenId,
    uint race,
    uint level,
    uint enemyRace,
    bool finished
  ) {
    uint _tokenId = fights[_fightId].arena[_fighterIndex];
    Fighter memory fr = fights[_fightId].fighters[_tokenId];
    return (_tokenId, fr.race, fr.level, fr.enemyRace, fr.finished);
  }

  function getFightRaces(uint _fightId) public view returns(uint[]) {
    Fight storage f = fights[_fightId];
    if (f.startedAt == 0) return;
    uint[] memory r = new uint[](f.raceCount);
    for(uint i; i < f.raceCount; i++) {
      r[i] = f.raceList[i];
    }
    return r;
  }

  function getFightRace(uint _fightId, uint _race) external view returns (
    uint index,
    uint count,  
    uint enemyCount,  
    int32 result
  ){
    Race memory r = fights[_fightId].races[_race];
    return (r.index, r.count, r.enemyCount, r.result);
  }

  function getFightRaceLevelStat(uint _fightId, uint _race, uint _level) external view returns (
    uint levelCount,  
    uint levelSum  
  ){
    Race storage r = fights[_fightId].races[_race];
    return (r.levelCount[_level], r.levelSum);
  }

  function getFightResult(uint _fightId, uint _tokenId) public view returns (Result) {
 
     
    Fight storage f = fights[_fightId];
    Fighter storage fr = f.fighters[_tokenId];
     
    if (!fr.exists) {
      return Result.QUAIL;
    }
 
    return f.races[fr.race].result > f.races[fr.enemyRace].result ? Result.WIN : f.races[fr.race].result < f.races[fr.enemyRace].result ? Result.LOSS : Result.DRAW;
  }


  function isAllowed(uint tokenId) public view returns (bool) {
    uint fightId = characterLastFightId(tokenId);
    return fightId == 0 ? true : fights[fightId].fighters[tokenId].finished;
  }

  function getCurrentFight() public view returns (
    uint256 fightId,
    uint256 startedAt,
    uint256 finishedAt,
    uint256 startCheckedAt,
    uint256 finishCheckedAt,
    uint256 fightersCount,
    uint256 raceCount
  ) {
    fightId = getCurrentFightId();
    (startedAt, finishedAt, startCheckedAt, finishCheckedAt, fightersCount, raceCount) = getFight(fightId);
  }

  function getNextFight() public view returns (
    uint256 fightId,
    uint256 startedAt,
    uint256 finishedAt,
    uint256 startCheckedAt,
    uint256 finishCheckedAt,
    uint256 fightersCount,
    uint256 raceCount
  ) {
    fightId = getNextFightId();
    (startedAt, finishedAt, startCheckedAt, finishCheckedAt, fightersCount, raceCount) = getFight(fightId);
  }

  function getFight(uint _fightId) public view returns (
    uint256 startedAt,
    uint256 finishedAt,
    uint256 startCheckedAt,
    uint256 finishCheckedAt,
    uint256 fightersCount,
    uint256 raceCount
  ) {
    Fight memory f = fights[_fightId];
    return (f.startedAt, f.finishedAt, f.startCheckedAt, f.finishCheckedAt, f.fightersCount, f.raceCount);
  }

  function getNextFightInterval() external view returns (
    uint fightId,
    uint currentTime,
    uint applicationStartAt,
    uint betsStartAt,
    uint fightStartAt,
    uint fightFinishAt
  ) {
    uint intervalId = _getFightIntervalIdAt(now);
    fightId = getFightId(intervalId, 1);
    (currentTime, applicationStartAt, betsStartAt, fightStartAt, fightFinishAt) = _getFightInterval(intervalId, 1);
  }

  function getCurrentFightInterval() external view returns (
    uint fightId,
    uint currentTime,
    uint applicationStartAt,
    uint betsStartAt,
    uint fightStartAt,
    uint fightFinishAt
  ) {
    uint intervalId = _getFightIntervalIdAt(now);
    fightId = getFightId(intervalId, 0);
    (currentTime, applicationStartAt, betsStartAt, fightStartAt, fightFinishAt) = _getFightInterval(intervalId, 0);
  }

  function _getFightInterval(uint intervalId, uint nextShift) internal view returns (
 
    uint currentTime,
    uint applicationStartAt,
    uint betsStartAt,
    uint fightStartAt,
    uint fightFinishAt
  ) {

    fightStartAt = _getFightStartsAt(intervalId, nextShift);

    FightInterval memory i = intervalHistory[intervalId];
    currentTime = now;
    applicationStartAt = fightStartAt - i.applicationPeriod;
    betsStartAt = fightStartAt - i.betsPeriod;
    fightFinishAt = fightStartAt + i.fightPeriod;
  }

  function _getFightStartsAt(uint intervalId, uint nextShift) internal view returns (uint) {
    FightInterval memory i = intervalHistory[intervalId];
    uint intervalsCount = (now - i.startsFrom) / i.fightsInterval + nextShift;
    return i.startsFrom + i.fightsInterval * intervalsCount;
  }


  function getCurrentIntervals() external view returns (
    uint fightsInterval,
    uint fightPeriod,
    uint applicationPeriod,
    uint betsPeriod
  ) {
    FightInterval memory i = _getFightIntervalAt(now);
    fightsInterval = i.fightsInterval;
    fightPeriod = i.fightPeriod;
    applicationPeriod = i.applicationPeriod;
    betsPeriod = i.betsPeriod;
  }


  function _getFightIntervalAt(uint _time)  internal view returns (FightInterval memory) {
    return intervalHistory[_getFightIntervalIdAt(_time)];
  }


  function _getFightIntervalIdAt(uint _time)  internal view returns (uint) {
    require(intervalHistory.length>0);
     

     
    if (_time >= intervalHistory[intervalHistory.length - 1].startsFrom)
      return intervalHistory.length - 1;
    if (_time < intervalHistory[0].startsFrom) return 0;

     
    uint min = 0;
    uint max = intervalHistory.length - 1;
    while (max > min) {
      uint mid = (max + min + 1) / 2;
      if (intervalHistory[mid].startsFrom <= _time) {
        min = mid;
      } else {
        max = mid - 1;
      }
    }
    return min;
  }


   
   
   
   
  function setFightResult(uint fightId, uint count, uint[] packedRaces, uint[] packedResults) public onlyService {
    require(packedRaces.length == packedResults.length);
    require(packedRaces.length * 8 >= count);

    Fight storage f = fights[fightId];
    require(f.startedAt != 0 && f.finishedAt == 0);

     
    for (uint i = 0; i < count; i++) {
 
        f.races[_upack(packedRaces[i / 8], i % 8)].result = int32(_upack(packedResults[i / 8], i % 8));
 
    }
    emit FightResult(fightId, packedRaces, packedResults);

  }

   
  function finishFight(uint fightId, uint startCheckedAt, uint finishCheckedAt) public onlyService {
    Fight storage f = fights[fightId];
    require(f.startedAt != 0 && f.finishedAt == 0);
    FightInterval memory i = _getFightIntervalAt(f.startedAt);
     
    require(now >= f.startedAt + i.fightPeriod);
    f.finishedAt = now;
    f.startCheckedAt = startCheckedAt;
    f.finishCheckedAt = finishCheckedAt;
    emit FinishFight(fightId, f.startedAt, f.finishedAt, startCheckedAt, finishCheckedAt);
  }

   
  function _upack(uint _v, uint _n) internal pure returns (uint) {
     
    return (_v >> (32 * _n)) & 0xFFFFFFFF;
  }

   
  function _puck(uint _v, uint _n, uint _x) internal pure returns (uint) {
     
     
    return _v & ~(0xFFFFFFFF << (32 * _n)) | ((_x & 0xFFFFFFFF) << (32 * _n));
  }
}