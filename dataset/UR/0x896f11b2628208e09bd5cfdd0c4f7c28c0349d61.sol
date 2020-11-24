 

pragma solidity ^0.4.24;

 

 
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

 

 
 
 
 
 
 
 
 

 
 


pragma solidity ^0.4.24;



contract CoinPledge is Ownable {

  using SafeMath for uint256;

  uint constant daysToResolve = 7 days;
  uint constant bonusPercentage = 50;
  uint constant serviceFeePercentage = 10;
  uint constant minBonus = 1 finney;

  struct Challenge {
    address user;
    string name;
    uint value;
    address mentor;
    uint startDate;
    uint time;
    uint mentorFee;

    bool successed;
    bool resolved;
  }

  struct User {
    address addr;
    string name;
  }

   
  event NewChallenge(
    uint indexed challengeId,
    address indexed user,
    string name,
    uint value,
    address indexed mentor,
    uint startDate,
    uint time,
    uint mentorFee
  );

  event ChallengeResolved(
    uint indexed challengeId,
    address indexed user,
    address indexed mentor,
    bool decision
  );

  event BonusFundChanged(
    address indexed user,
    uint value
  );

  event NewUsername(
    address indexed addr,
    string name
  );


  event Donation(
    string name,
    string url,
    uint value,
    uint timestamp
  );

   
  bool public isGameOver;

   
  Challenge[] public challenges;

  mapping(uint => address) public challengeToUser;
  mapping(address => uint) public userToChallengeCount;

  mapping(uint => address) public challengeToMentor;
  mapping(address => uint) public mentorToChallengeCount;

   
  mapping(address => User) public users;
  address[] public allUsers;
  mapping(string => address) private usernameToAddress;
  
   
  mapping(address => uint) public bonusFund;

   
  modifier gameIsNotOver() {
    require(!isGameOver, "Game should be not over");
    _;
  }

   
  modifier gameIsOver() {
    require(isGameOver, "Game should be over");
    _;
  }

   
  function getBonusFund(address user)
  external
  view
  returns(uint) {
    return bonusFund[user];
  }

   
  function getUsersCount()
  external
  view
  returns(uint) {
    return allUsers.length;
  }

   
  function getChallengesForUser(address user)
  external
  view
  returns(uint[]) {
    require(userToChallengeCount[user] > 0, "Has zero challenges");

    uint[] memory result = new uint[](userToChallengeCount[user]);
    uint counter = 0;
    for (uint i = 0; i < challenges.length; i++) {
      if (challengeToUser[i] == user)
      {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

   
  function getChallengesForMentor(address mentor)
  external
  view
  returns(uint[]) {
    require(mentorToChallengeCount[mentor] > 0, "Has zero challenges");

    uint[] memory result = new uint[](mentorToChallengeCount[mentor]);
    uint counter = 0;
    for (uint i = 0; i < challenges.length; i++) {
      if (challengeToMentor[i] == mentor)
      {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }
  
   
  function gameOver()
  external
  gameIsNotOver
  onlyOwner {
    isGameOver = true;
  }

   
  function setUsername(string name)
  external
  gameIsNotOver {
    require(bytes(name).length > 2, "Provide a name longer than 2 chars");
    require(bytes(name).length <= 32, "Provide a name shorter than 33 chars");
    require(users[msg.sender].addr == address(0x0), "You already have a name");
    require(usernameToAddress[name] == address(0x0), "Name already taken");

    users[msg.sender] = User(msg.sender, name);
    usernameToAddress[name] = msg.sender;
    allUsers.push(msg.sender);

    emit NewUsername(msg.sender, name);
  }

   
  function createChallenge(string name, string mentor, uint time, uint mentorFee)
  external
  payable
  gameIsNotOver
  returns (uint retId) {
    require(msg.value >= 0.01 ether, "Has to stake more than 0.01 ether");
    require(mentorFee >= 0 ether, "Can't be negative");
    require(mentorFee <= msg.value, "Can't be bigger than stake");
    require(bytes(mentor).length > 0, "Has to be a mentor");
    require(usernameToAddress[mentor] != address(0x0), "Mentor has to be registered");
    require(time > 0, "Time has to be greater than zero");

    address mentorAddr = usernameToAddress[mentor];

    require(msg.sender != mentorAddr, "Can't be mentor to yourself");

    uint startDate = block.timestamp;
    uint id = challenges.push(Challenge(msg.sender, name, msg.value, mentorAddr, startDate, time, mentorFee, false, false)) - 1;

    challengeToUser[id] = msg.sender;
    userToChallengeCount[msg.sender]++;

    challengeToMentor[id] = mentorAddr;
    mentorToChallengeCount[mentorAddr]++;

    emit NewChallenge(id, msg.sender, name, msg.value, mentorAddr, startDate, time, mentorFee);

    return id;
  }

   
  function resolveChallenge(uint challengeId, bool decision)
  external
  gameIsNotOver {
    Challenge storage challenge = challenges[challengeId];
    
    require(challenge.resolved == false, "Challenge already resolved.");

     
    if(block.timestamp < (challenge.startDate + challenge.time + daysToResolve))
      require(challenge.mentor == msg.sender, "You are not the mentor for this challenge.");
    else require((challenge.user == msg.sender) || (challenge.mentor == msg.sender), "You are not the user or mentor for this challenge.");

    uint mentorFee;
    uint serviceFee;
    
    address user = challengeToUser[challengeId];
    address mentor = challengeToMentor[challengeId];

     
    challenge.successed = decision;
    challenge.resolved = true;

    uint remainingValue = challenge.value;

     
    if(challenge.mentorFee > 0) {
      serviceFee = challenge.mentorFee.div(100).mul(serviceFeePercentage);
      mentorFee = challenge.mentorFee.div(100).mul(100 - serviceFeePercentage);
    }
    
    if(challenge.mentorFee > 0)
      remainingValue = challenge.value.sub(challenge.mentorFee);

    uint valueToPay;

    if(decision) {
       
      valueToPay = remainingValue;
       
      uint currentBonus = bonusFund[user];
      if(currentBonus > 0)
      {
        uint bonusValue = bonusFund[user].div(100).mul(bonusPercentage);
        if(currentBonus <= minBonus)
          bonusValue = currentBonus;
        bonusFund[user] -= bonusValue;
        emit BonusFundChanged(user, bonusFund[user]);

        valueToPay += bonusValue;
      }
    }
    else {
      bonusFund[user] += remainingValue;
      emit BonusFundChanged(user, bonusFund[user]);
    }

     
    if(valueToPay > 0)
      user.transfer(valueToPay);

    if(mentorFee > 0)
      mentor.transfer(mentorFee);

    if(serviceFee > 0)
      owner().transfer(serviceFee);

    emit ChallengeResolved(challengeId, user, mentor, decision);
  }

  function withdraw()
  external
  gameIsOver {
    require(bonusFund[msg.sender] > 0, "You do not have any funds");

    uint funds = bonusFund[msg.sender];
    bonusFund[msg.sender] = 0;
    msg.sender.transfer(funds);
  }

  function donate(string name, string url)
  external
  payable
  gameIsNotOver {
    owner().transfer(msg.value);
    emit Donation(name, url, msg.value, block.timestamp);
  }
}