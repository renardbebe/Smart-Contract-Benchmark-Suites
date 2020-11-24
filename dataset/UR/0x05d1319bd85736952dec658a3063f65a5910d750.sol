 

pragma solidity ^0.4.24;

 
 
 

contract DigitalGame {
   

  uint constant MIN_BET_MONEY = 1 finney;
  uint constant MAX_BET_MONEY = 10 ether;
  uint constant MIN_BET_NUMBER = 2;
  uint constant MAX_STAGE = 5;

   
   
   
   
  uint constant FIRST_GENERATION_REWARD = 5;
  uint constant SECOND_GENERATION_REWARD = 3;
  uint constant THIRD_GENERATION_REWARD = 2;

  address public OWNER_ADDR;
  address public RECOMM_ADDR;
  address public SPARE_RECOMM_ADDR;

  uint public lastStage;
  uint public lastRound;

   

  struct UserRecomm {
    address addr;
  }

  struct StageInfo {
    uint round;
    bytes32 seedHash;
    uint userNumber;
    uint amount;
    uint lastTime;
  }

  struct UserBet {
    address addr;
    uint amount;
    uint[] content;
    uint count;
    uint createAt;
  }
  
  address[] private userRecomms;
  UserBet[] private WaitAwardBets;

   

  mapping(uint => StageInfo) public stages;
  mapping(address => address) public users;
  mapping(uint => UserBet[]) public userBets;
  mapping(uint => mapping(uint => mapping(address => bool))) private userBetAddrs;

   

  event eventUserBet(
    string eventType,
    address addr,
    uint amount,
    uint stage,
    uint round,
    uint count,
    uint[] content,
    uint createAt
  );

  event eventLottery(
    string eventType,
    uint stage,
    uint round,
    uint[] lotteryContent,
    uint createAt
  );

  event eventDividend(
    string eventType,
    address addr,
    uint amount,
    uint stage,
    uint round,
    uint count,
    uint[] content,
    uint level,
    address recommAddr,
    uint recommReward,
    uint createAt
  );

  event eventReward(
    string eventType,
    address addr,
    uint amount,
    uint stage,
    uint round,
    uint count,
    uint[] content,
    uint[] lotteryContent,
    uint reward,
    uint createAt
  );

   

  modifier checkBetTime(uint lastTime) {
    require(now <= lastTime + 5 minutes, 'Current time is not allowed to bet');
    _;
  }

  modifier checkRewardTime(uint lastTime) {
    require(
      now >= lastTime + 10 minutes,
      'Current time is not allowed to reward'
    );
    _;
  }

  modifier isSecretNumber(uint stage, string seed) {
    require(
      keccak256(abi.encodePacked(seed)) == stages[stage].seedHash,
      'Encrypted numbers are illegal'
    );
    _;
  }

  modifier verifyStage(uint stage) {
    require(
      stage >= 1 && stage <= MAX_STAGE,
      'Stage no greater than 5 (MAX_STAGE)'
    );
    _;
  }

  modifier verifySeedHash(uint stage, bytes32 seedHash) {
    require(
      stages[stage].seedHash == seedHash && seedHash != 0,
      'The hash of the stage is illegal'
    );
    _;
  }

  modifier onlyOwner() {
    require(OWNER_ADDR == msg.sender, 'Permission denied');
    _;
  }

  constructor() public {
    for (uint i = 1; i <= MAX_STAGE; i++) {
      stages[i].round = 1;
      stages[i].seedHash = 0x0;
      stages[i].userNumber = 0;
      stages[i].amount = 0;
      stages[i].lastTime = now;
    }

    OWNER_ADDR = msg.sender;
    RECOMM_ADDR = msg.sender;
    SPARE_RECOMM_ADDR = msg.sender;

    lastStage = 1;
    lastRound = 1;
  }

  function bet(
    uint stage,
    uint round,
    uint[] content,
    uint count,
    address recommAddr,
    bytes32 seedHash
  ) public
  payable
  verifyStage(stage)
  verifySeedHash(stage, seedHash)
  checkBetTime(stages[stage].lastTime) {
    require(stages[stage].round == round, 'Round illegal');
    require(content.length == 3, 'The bet is 3 digits');

    require((
        msg.value >= MIN_BET_MONEY
            && msg.value <= MAX_BET_MONEY
            && msg.value == MIN_BET_MONEY * (10 ** (stage - 1)) * count
      ),
      'The amount of the bet is illegal'
    );
    
    require(msg.sender != recommAddr, 'The recommender cannot be himself');
    
    
    if (users[msg.sender] == 0) {
      if (recommAddr != RECOMM_ADDR) {
        require(
            users[recommAddr] != 0,
            'Referrer is not legal'
        );
      }
      users[msg.sender] = recommAddr;
    }

    generateUserRelation(msg.sender, 3);
    require(userRecomms.length <= 3, 'User relationship error');

    sendInviteDividends(stage, round, count, content);

    if (!userBetAddrs[stage][stages[stage].round][msg.sender]) {
      stages[stage].userNumber++;
      userBetAddrs[stage][stages[stage].round][msg.sender] = true;
    }

    userBets[stage].push(UserBet(
      msg.sender,
      msg.value,
      content,
      count,
      now
    ));

    emit eventUserBet(
      'userBet',
      msg.sender,
      msg.value,
      stage,
      round,
      count,
      content,
      now
    );
  }

  function generateUserRelation(
    address addr,
    uint generation
  ) private returns(bool) {
    userRecomms.push(users[addr]);
    if (users[addr] != RECOMM_ADDR && users[addr] != 0 && generation > 1) {
        generateUserRelation(users[addr], generation - 1);
    }
  }

  function sendInviteDividends(
    uint stage,
    uint round,
    uint count,
    uint[] content
  ) private {
    uint[3] memory GENERATION_REWARD = [
      FIRST_GENERATION_REWARD,
      SECOND_GENERATION_REWARD,
      THIRD_GENERATION_REWARD
    ];
    uint recomms = 0;
    for (uint j = 0; j < userRecomms.length; j++) {
      recomms += msg.value * GENERATION_REWARD[j] / 1000;
      userRecomms[j].transfer(msg.value * GENERATION_REWARD[j] / 1000);

      emit eventDividend(
        'dividend',
        msg.sender,
        msg.value,
        stage,
        round,
        count,
        content,
        j,
        userRecomms[j],
        msg.value * GENERATION_REWARD[j] / 1000,
        now
      );
    }

    stages[stage].amount += (msg.value - recomms);
    delete userRecomms;
  }

  function distributionReward(
    uint stage,
    string seed,
    bytes32 seedHash
  ) public
  checkRewardTime(stages[stage].lastTime)
  isSecretNumber(stage, seed)
  verifyStage(stage)
  onlyOwner {
    if (stages[stage].userNumber >= MIN_BET_NUMBER) {
      uint[] memory randoms = generateRandom(
        seed,
        stage,
        userBets[stage].length
      );
      require(randoms.length == 3, 'Random number is illegal');

      bool isReward = CalcWinnersAndReward(randoms, stage);

      emit eventLottery(
        'lottery',
        stage,
        stages[stage].round,
        randoms,
        now
      );

      if (isReward) {
        stages[stage].amount = 0;
        
        lastStage = stage;
        lastRound = stages[stage].round;
      }
      
      delete userBets[stage];
      
      stages[stage].round += 1;
      stages[stage].userNumber = 0;
      stages[stage].seedHash = seedHash;
      
      stages[stage].lastTime = now + 5 minutes;
    } else {
      stages[stage].lastTime = now;
    }
  }

  function CalcWinnersAndReward(
    uint[] randoms,
    uint stage
  ) private onlyOwner returns(bool) {
    uint counts = 0;
    for (uint i = 0; i < userBets[stage].length; i++) {
      if (randoms[0] == userBets[stage][i].content[0]
        && randoms[1] == userBets[stage][i].content[1]
        && randoms[2] == userBets[stage][i].content[2]) {
        counts = counts + userBets[stage][i].count;
        WaitAwardBets.push(UserBet(
          userBets[stage][i].addr,
          userBets[stage][i].amount,
          userBets[stage][i].content,
          userBets[stage][i].count,
          userBets[stage][i].createAt
        ));
      }
    }
    if (WaitAwardBets.length == 0) {
      for (uint j = 0; j < userBets[stage].length; j++) {
        if ((randoms[0] == userBets[stage][j].content[0]
            && randoms[1] == userBets[stage][j].content[1])
              || (randoms[1] == userBets[stage][j].content[1]
            && randoms[2] == userBets[stage][j].content[2])
              || (randoms[0] == userBets[stage][j].content[0]
            && randoms[2] == userBets[stage][j].content[2])) {
          counts += userBets[stage][j].count;
          WaitAwardBets.push(UserBet(
            userBets[stage][j].addr,
            userBets[stage][j].amount,
            userBets[stage][j].content,
            userBets[stage][j].count,
            userBets[stage][j].createAt
          ));
        }
      }
    }
    if (WaitAwardBets.length == 0) {
      for (uint k = 0; k < userBets[stage].length; k++) {
        if (randoms[0] == userBets[stage][k].content[0]
            || randoms[1] == userBets[stage][k].content[1]
            || randoms[2] == userBets[stage][k].content[2]) {
          counts += userBets[stage][k].count;
          WaitAwardBets.push(UserBet(
            userBets[stage][k].addr,
            userBets[stage][k].amount,
            userBets[stage][k].content,
            userBets[stage][k].count,
            userBets[stage][k].createAt
          ));
        }
      }
    }

    uint extractReward = stages[stage].amount / 100;
    RECOMM_ADDR.transfer(extractReward);
    SPARE_RECOMM_ADDR.transfer(extractReward);
    OWNER_ADDR.transfer(extractReward);

    if (WaitAwardBets.length != 0) {
      issueReward(stage, extractReward, randoms, counts);
      delete WaitAwardBets;
      return true;
    }
    stages[stage].amount = stages[stage].amount - extractReward - extractReward - extractReward;
    return false;
  }
  
  function issueReward(
    uint stage,
    uint extractReward,
    uint[] randoms,
    uint counts
  ) private onlyOwner {
    uint userAward = stages[stage].amount - extractReward - extractReward - extractReward;
    for (uint m = 0; m < WaitAwardBets.length; m++) {
      uint reward = userAward * WaitAwardBets[m].count / counts;
      WaitAwardBets[m].addr.transfer(reward);

      emit eventReward(
        'reward',
        WaitAwardBets[m].addr,
        WaitAwardBets[m].amount,
        stage,
        stages[stage].round,
        WaitAwardBets[m].count,
        WaitAwardBets[m].content,
        randoms,
        reward,
        now
      );
    }
  }

  function generateRandom(
    string seed,
    uint stage,
    uint betNum
  ) private view onlyOwner
  isSecretNumber(stage, seed) returns(uint[]) {
    uint[] memory randoms = new uint[](3);
    for (uint i = 0; i < 3; i++) {
      randoms[i] = uint(
        keccak256(abi.encodePacked(betNum, block.difficulty, seed, now, i))
      ) % 9 + 1;
    }
    return randoms;
  }

  function setSeedHash(uint stage, bytes32 seedHash) public onlyOwner {
    require(
      stages[stage].seedHash == 0,
      'No need to set seed hash'
    );
    stages[stage].seedHash = seedHash;
  }

  function setDefaultRecommAddr(address _RECOMM_ADDR) public onlyOwner {
    RECOMM_ADDR = _RECOMM_ADDR;
  }

  function setSpareRecommAddr(address _SPARE_RECOMM_ADDR) public onlyOwner {
    SPARE_RECOMM_ADDR = _SPARE_RECOMM_ADDR;
  }

  function getDefaultRecommAddr() public view returns(address) {
    return RECOMM_ADDR;
  }

  function getSpareRecommAddr() public view returns(address) {
    return SPARE_RECOMM_ADDR;
  }
}