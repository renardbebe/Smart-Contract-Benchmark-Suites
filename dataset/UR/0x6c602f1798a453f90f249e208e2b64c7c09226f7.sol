 

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

 

interface HEROES {
  function getLevel(uint256 tokenId) external view returns (uint256);
  function getGenes(uint256 tokenId) external view returns (uint256);
  function getRace(uint256 tokenId) external view returns (uint256);
  function lock(uint256 tokenId, uint256 lockedTo, bool onlyFreeze) external returns (bool);
  function unlock(uint256 tokenId) external returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
  function isCallerAgentOf(uint tokenId) external view returns (bool);
  function addWin(uint256 tokenId, uint winsCount, uint levelUp) external returns (bool);
  function addLoss(uint256 tokenId, uint256 lossesCount, uint levelDown) external returns (bool);
}


contract Mentoring is Ownable, ReentrancyGuard, CanReclaimToken  {
  using SafeMath for uint256;

  event BecomeMentor(uint256 indexed mentorId);
  event BreakMentoring(uint256 indexed mentorId);
  event ChangeLevelPrice(uint256 indexed mentorId, uint256 newLevelPrice);
  event Income(address source, uint256 amount);

  event StartLecture(uint256 indexed lectureId,
    uint256 indexed mentorId,
    uint256 indexed studentId,
    uint256 mentorLevel,
    uint256 studentLevel,
    uint256 levelUp,
    uint256 levelPrice,
    uint256 startedAt,
    uint256 endsAt);

 

  struct Lecture {
    uint256 mentorId;
    uint256 studentId;
    uint256 mentorLevel;
    uint256 studentLevel;
    uint256 levelUp;
    uint256 levelPrice;
 
    uint256 startedAt;
    uint256 endsAt;
  }

  HEROES public heroes;

  uint256 public fee = 290;  
  uint256 public levelUpTime = 20 minutes;

  mapping(uint256 => uint256) internal prices;

  Lecture[] internal lectures;
   
  mapping(uint256 => uint256[]) studentToLecture;
  mapping(uint256 => uint256[]) mentorToLecture;

  modifier onlyOwnerOf(uint256 _tokenId) {
    require(heroes.ownerOf(_tokenId) == msg.sender);
    _;
  }

  constructor (HEROES _heroes) public {
    require(address(_heroes) != address(0));
    heroes = _heroes;

     
    lectures.length = 1;
  }

   
  function() external payable {
    require(msg.value > 0);
    _flushBalance();
  }

  function _flushBalance() private {
    uint256 balance = address(this).balance;
    if (balance > 0) {
      address(heroes).transfer(balance);
      emit Income(address(this), balance);
    }
  }


  function _distributePayment(address _account, uint256 _amount) internal {
    uint256 pcnt = _getPercent(_amount, fee);
    uint256 amount = _amount.sub(pcnt);
    _account.transfer(amount);
  }

   
  function setFee(uint256 _fee) external onlyOwner
  {
    fee = _fee;
  }

   

   

  function setLevelUpTime(uint256 _newLevelUpTime) external onlyOwner
  {
    levelUpTime = _newLevelUpTime;
  }

  function isMentor(uint256 _mentorId) public view returns (bool)
  {
     
    return heroes.isCallerAgentOf(_mentorId);  
  }

  function inStudying(uint256 _tokenId) public view returns (bool) {
    return now <= lectures[getLastLectureIdAsStudent(_tokenId)].endsAt;
  }

  function inMentoring(uint256 _tokenId) public view returns (bool) {
    return now <= lectures[getLastLectureIdAsMentor(_tokenId)].endsAt;
  }

  function inLecture(uint256 _tokenId) public view returns (bool)
  {
    return inMentoring(_tokenId) || inStudying(_tokenId);
  }

   
  function becomeMentor(uint256 _mentorId, uint256 _levelPrice) external onlyOwnerOf(_mentorId) {
    require(_levelPrice > 0);
    require(heroes.lock(_mentorId, 0, false));
    prices[_mentorId] = _levelPrice;
    emit BecomeMentor(_mentorId);
    emit ChangeLevelPrice(_mentorId, _levelPrice);
  }

   
  function changeLevelPrice(uint256 _mentorId, uint256 _levelPrice) external onlyOwnerOf(_mentorId) {
    require(_levelPrice > 0);
    require(isMentor(_mentorId));
    prices[_mentorId] = _levelPrice;
    emit ChangeLevelPrice(_mentorId, _levelPrice);
  }

   
  function breakMentoring(uint256 _mentorId) external onlyOwnerOf(_mentorId)
  {
    require(heroes.unlock(_mentorId));
    emit BreakMentoring(_mentorId);
  }

  function getMentor(uint256 _mentorId) external view returns (uint256 level, uint256 price) {
    require(isMentor(_mentorId));
    return (heroes.getLevel(_mentorId), prices[_mentorId]);
  }

  function _calcLevelIncrease(uint256 _mentorLevel, uint256 _studentLevel) internal pure returns (uint256) {
    if (_mentorLevel < _studentLevel) {
      return 0;
    }
    uint256 levelDiff = _mentorLevel - _studentLevel;
    return (levelDiff >> 1) + (levelDiff & 1);
  }

   
  function calcCost(uint256 _mentorId, uint256 _studentId) external view returns (uint256) {
    uint256 levelUp = _calcLevelIncrease(heroes.getLevel(_mentorId), heroes.getLevel(_studentId));
    return levelUp.mul(prices[_mentorId]);
  }

  function isRaceSuitable(uint256 _mentorId, uint256 _studentId) public view returns (bool) {
    uint256 mentorRace = heroes.getGenes(_mentorId) & 0xFFFF;
    uint256 studentRace = heroes.getGenes(_studentId) & 0xFFFF;
    return (mentorRace == 1 || mentorRace == studentRace);
  }

   
  function startLecture(uint256 _mentorId, uint256 _studentId) external payable onlyOwnerOf(_studentId) {
    require(isMentor(_mentorId));

     
    require(isRaceSuitable(_mentorId, _studentId));

    uint256 mentorLevel = heroes.getLevel(_mentorId);
    uint256 studentLevel = heroes.getLevel(_studentId);

    uint256 levelUp = _calcLevelIncrease(mentorLevel, studentLevel);
    require(levelUp > 0);

     
    uint256 cost = levelUp.mul(prices[_mentorId]);
    require(cost == msg.value);

    Lecture memory lecture = Lecture({
      mentorId : _mentorId,
      studentId : _studentId,
      mentorLevel: mentorLevel,
      studentLevel: studentLevel,
      levelUp: levelUp,
      levelPrice : prices[_mentorId],
      startedAt : now,
      endsAt : now + levelUp.mul(levelUpTime)
      });

     
    require(heroes.lock(_mentorId, lecture.endsAt, true));

     
    require(heroes.lock(_studentId, lecture.endsAt, true));


     
     
    uint256 lectureId = lectures.push(lecture) - 1;

    studentToLecture[_studentId].push(lectureId);
    mentorToLecture[_mentorId].push(lectureId);

    heroes.addWin(_studentId, 0, levelUp);

    emit StartLecture(
      lectureId,
      _mentorId,
      _studentId,
      lecture.mentorLevel,
      lecture.studentLevel,
      lecture.levelUp,
      lecture.levelPrice,
      lecture.startedAt,
      lecture.endsAt
    );

    _distributePayment(heroes.ownerOf(_mentorId), cost);

    _flushBalance();
  }

  function lectureExists(uint256 _lectureId) public view returns (bool)
  {
    return (_lectureId > 0 && _lectureId < lectures.length);
  }

  function getLecture(uint256 lectureId) external view returns (
    uint256 mentorId,
    uint256 studentId,
    uint256 mentorLevel,
    uint256 studentLevel,
    uint256 levelUp,
    uint256 levelPrice,
    uint256 cost,
    uint256 startedAt,
    uint256 endsAt)
  {
    require(lectureExists(lectureId));
    Lecture memory l = lectures[lectureId];
    return (l.mentorId, l.studentId, l.mentorLevel, l.studentLevel, l.levelUp, l.levelPrice, l.levelUp.mul(l.levelPrice), l.startedAt, l.endsAt);
  }

  function getLastLectureIdAsMentor(uint256 _tokenId) public view returns (uint256) {
    return mentorToLecture[_tokenId].length > 0 ? mentorToLecture[_tokenId][mentorToLecture[_tokenId].length - 1] : 0;
  }
  function getLastLectureIdAsStudent(uint256 _tokenId) public view returns (uint256) {
    return studentToLecture[_tokenId].length > 0 ? studentToLecture[_tokenId][studentToLecture[_tokenId].length - 1] : 0;
  }
 

  function getLastLecture(uint256 tokenId) external view returns (
    uint256 lectureId,
    uint256 mentorId,
    uint256 studentId,
    uint256 mentorLevel,
    uint256 studentLevel,
    uint256 levelUp,
    uint256 levelPrice,
    uint256 cost,
    uint256 startedAt,
    uint256 endsAt)
  {
    uint256 mentorLectureId = getLastLectureIdAsMentor(tokenId);
    uint256 studentLectureId = getLastLectureIdAsStudent(tokenId);
    lectureId = studentLectureId > mentorLectureId ? studentLectureId : mentorLectureId;
    require(lectureExists(lectureId));
    Lecture storage l = lectures[lectureId];
    return (lectureId, l.mentorId, l.studentId, l.mentorLevel, l.studentLevel, l.levelUp, l.levelPrice, l.levelUp.mul(l.levelPrice), l.startedAt, l.endsAt);
  }

   
   
  function _getPercent(uint256 _v, uint256 _p) internal pure returns (uint)    {
    return _v.mul(_p).div(10000);
  }
}