 

pragma solidity ^0.4.19;
 

contract SafeMath {
   

  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b);
    return c;
  }
}

contract Token {

   
  function totalSupply() public constant returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) public returns (bool success) {
     
     
     
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
     
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
     
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
     
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) public balances;

  mapping (address => mapping (address => uint256)) public allowed;

  uint256 public totalSupply;

}

contract ReserveToken is StandardToken, SafeMath {
  string public name;
  string public symbol;
  uint public decimals = 18;
  address public minter;

  event Create(address account, uint amount);
  event Destroy(address account, uint amount);

  function ReserveToken(string name_, string symbol_) public {
    name = name_;
    symbol = symbol_;
    minter = msg.sender;
  }

  function create(address account, uint amount) public {
    require(msg.sender == minter);
    balances[account] = safeAdd(balances[account], amount);
    totalSupply = safeAdd(totalSupply, amount);
    Create(account, amount);
  }

  function destroy(address account, uint amount) public {
    require(msg.sender == minter);
    require(balances[account] >= amount);
    balances[account] = safeSub(balances[account], amount);
    totalSupply = safeSub(totalSupply, amount);
    Destroy(account, amount);
  }
}

contract Challenge is SafeMath {

  uint public fee = 10 * (10 ** 16);  
  uint public blockPeriod = 6000;  
  uint public blockNumber;  
  bool public funded;  
  address public witnessJury;  
  address public token;  
  address public user1;  
  address public user2;  
  string public key1;  
  string public key2;  
  uint public amount;  
  address public host;  
  string public hostKey;  
  string public witnessJuryKey;  
  uint public witnessJuryRequestNum;  
  uint public winner;  
  bool public rescued;  
  bool public juryCalled;  
  address public referrer;  

  event NewChallenge(uint amount, address user1, string key1);
  event Fund();
  event Respond(address user2, string key2);
  event Host(address host, string hostKey);
  event SetWitnessJuryKey(uint witnessJuryRequestNum, string witnessJuryKey);
  event RequestJury();
  event Resolve(uint winner, bool wasContested, uint winnerAmount, uint hostAmount, uint witnessJuryAmount);
  event Rescue();

  function Challenge(address witnessJury_, address token_, uint amount_, address user1_, string key1_, uint blockPeriod_, address referrer_) public {
    require(amount_ > 0);
    blockPeriod = blockPeriod_;
    witnessJury = witnessJury_;
    token = token_;
    user1 = user1_;
    key1 = key1_;
    amount = amount_;
    referrer = referrer_;
    blockNumber = block.number;
    NewChallenge(amount, user1, key1);
  }

  function fund() public {
     
    require(!funded);
    require(!rescued);
    require(msg.sender == user1);
    require(Token(token).transferFrom(user1, this, amount));
    funded = true;
    blockNumber = block.number;
    Fund();
  }

  function respond(address user2_, string key2_) public {
     
    require(user2 == 0x0);
    require(msg.sender == user2_);
    require(funded);
    require(!rescued);
    user2 = user2_;
    key2 = key2_;
    blockNumber = block.number;
    require(Token(token).transferFrom(user2, this, amount));
    Respond(user2, key2);
  }

  function host(string hostKey_) public {
    require(host == 0x0);
    require(!rescued);
    host = msg.sender;
    hostKey = hostKey_;
    blockNumber = block.number;
    Host(host, hostKey);
  }

  function setWitnessJuryKey(string witnessJuryKey_) public {
    require(witnessJuryRequestNum == 0);
    require(msg.sender == host);
    require(!rescued);
    witnessJuryRequestNum = WitnessJury(witnessJury).numRequests() + 1;
    witnessJuryKey = witnessJuryKey_;
    blockNumber = block.number;
    WitnessJury(witnessJury).newRequest(witnessJuryKey, this);
    SetWitnessJuryKey(witnessJuryRequestNum, witnessJuryKey);
  }

  function requestJury() public {
    require(!juryCalled);
    require(msg.sender == user1 || msg.sender == user2);
    require(!rescued);
    require(winner == 0);
    require(WitnessJury(witnessJury).getWinner1(witnessJuryRequestNum) != 0 && WitnessJury(witnessJury).getWinner2(witnessJuryRequestNum) != 0);
    juryCalled = true;
    blockNumber = block.number;
    WitnessJury(witnessJury).juryNeeded(witnessJuryRequestNum);
    RequestJury();
  }

  function resolve(uint witnessJuryRequestNum_, bool juryContested, address[] majorityJurors, uint winner_, address witness1, address witness2, uint witnessJuryRewardPercentage) public {
    require(winner == 0);
    require(witnessJuryRequestNum_ == witnessJuryRequestNum);
    require(msg.sender == witnessJury);
    require(winner_ == 1 || winner_ == 2);
    require(!rescued);
    require(block.number > blockNumber + blockPeriod);
    uint totalFee = safeMul(safeMul(amount, 2), fee) / (1 ether);
    uint winnerAmount = safeSub(safeMul(amount, 2), totalFee);
    uint witnessJuryAmount = safeMul(totalFee, witnessJuryRewardPercentage) / (1 ether);
    uint hostAmount = safeSub(totalFee, witnessJuryAmount);
    uint flipWinner = winner_ == 1 ? 2 : 1;
    winner = juryContested ? flipWinner : winner_;
    if (winnerAmount > 0) {
      require(Token(token).transfer(winner == 1 ? user1 : user2, winnerAmount));
    }
    if (referrer != 0x0 && hostAmount / 2 > 0) {
      require(Token(token).transfer(host, hostAmount / 2));
      require(Token(token).transfer(referrer, hostAmount / 2));
    } else if (referrer == 0 && hostAmount > 0) {
      require(Token(token).transfer(host, hostAmount));
    }
    if (!juryContested && witnessJuryAmount / 2 > 0) {
      require(Token(token).transfer(witness1, witnessJuryAmount / 2));
      require(Token(token).transfer(witness2, witnessJuryAmount / 2));
    } else if (juryContested && witnessJuryAmount / majorityJurors.length > 0) {
      for (uint i = 0; i < majorityJurors.length; i++) {
        require(Token(token).transfer(majorityJurors[i], witnessJuryAmount / majorityJurors.length));
      }
    }
    uint excessBalance = Token(token).balanceOf(this);
    if (excessBalance > 0) {
      require(Token(token).transfer(0x0, excessBalance));
    }
    Resolve(winner, juryContested, winnerAmount, hostAmount, witnessJuryAmount);
  }

  function rescue() public {
    require(!rescued);
    require(funded);
    require(block.number > blockNumber + blockPeriod * 10);
    require(msg.sender == user1 || msg.sender == user2);
    require(winner == 0);
    rescued = true;
    if (user2 != 0x0) {
      require(Token(token).transfer(user1, amount));
      require(Token(token).transfer(user2, amount));
    } else {
      require(Token(token).transfer(user1, amount));
    }
    Rescue();
  }

}

contract ChallengeFactory is SafeMath {

  address witnessJury;
  address token;

  mapping(uint => Challenge) public challenges;
  uint numChallenges;

  event NewChallenge(address addr, uint amount, address user, string key);

  function ChallengeFactory(address witnessJury_, address token_) public {
    witnessJury = witnessJury_;
    token = token_;
  }

  function newChallenge(uint amount, address user, string key, address referrer) public {
    numChallenges = safeAdd(numChallenges, 1);
    uint blockPeriod = 6000;
    challenges[numChallenges] = new Challenge(witnessJury, token, amount, user, key, blockPeriod, referrer);
    NewChallenge(address(challenges[numChallenges]), amount, user, key);
  }

}

contract WitnessJury is SafeMath {
  mapping(address => uint) public balances;  
  uint public limit = 10 ** 16;  
  uint public numWitnessesBeforeLimit = 100;  
  uint public totalBalance;  
  uint public numWitnesses;  
  uint public blockPeriod = 6000;  
  uint public desiredWitnesses = 2;  
  uint public desiredJurors = 3;  
  uint public penalty = 50 * (10 ** 16);  
  address public token;  
  mapping(uint => Request) public requests;  
  uint public numRequests;  
  mapping(uint => uint) public requestsPerBlockGroup;  
  uint public drmVolumeCap = 10000;  
  uint public drmMinFee = 25 * (10 ** 16);  
  uint public drmMaxFee = 50 * (10 ** 16);  
  mapping(uint => bool) public juryNeeded;  
  mapping(uint => mapping(address => bool)) public juryVoted;  
  mapping(uint => uint) public juryYesCount;  
  mapping(uint => uint) public juryNoCount;  
  mapping(uint => address[]) public juryYesVoters;  
  mapping(uint => address[]) public juryNoVoters;  

  struct Request {
    string key;  
    address witness1;  
    address witness2;  
    string answer1;  
    string answer2;  
    uint winner1;  
    uint winner2;  
    uint fee;  
    address challenge;  
    uint blockNumber;  
  }

  event Deposit(uint amount);
  event Withdraw(uint amount);
  event ReduceToLimit(address witness, uint amount);
  event Report(uint requestNum, string answer, uint winner);
  event NewRequest(uint requestNum, string key);
  event JuryNeeded(uint requestNum);
  event JuryVote(uint requestNum, address juror, bool vote);
  event Resolve(uint requestNum);
  event JuryContested(uint requestNum);

  function WitnessJury(address token_) public {
    token = token_;
  }

  function balanceOf(address user) public constant returns(uint) {
    return balances[user];
  }

  function reduceToLimit(address witness) public {
    require(witness == msg.sender);
    uint amount = balances[witness];
    uint limitAmount = safeMul(totalBalance, limit) / (1 ether);
    if (amount > limitAmount && numWitnesses > numWitnessesBeforeLimit) {
      uint excess = safeSub(amount, limitAmount);
      balances[witness] = safeSub(amount, excess);
      totalBalance = safeSub(totalBalance, excess);
      require(Token(token).transfer(witness, excess));
      ReduceToLimit(witness, excess);
    }
  }

  function deposit(uint amount) public {
     
    require(amount > 0);
    if (balances[msg.sender] == 0) {
      numWitnesses = safeAdd(numWitnesses, 1);
    }
    balances[msg.sender] = safeAdd(balances[msg.sender], amount);
    totalBalance = safeAdd(totalBalance, amount);
    require(Token(token).transferFrom(msg.sender, this, amount));
    Deposit(amount);
  }

  function withdraw(uint amount) public {
    require(amount > 0);
    require(amount <= balances[msg.sender]);
    balances[msg.sender] = safeSub(balances[msg.sender], amount);
    totalBalance = safeSub(totalBalance, amount);
    if (balances[msg.sender] == 0) {
      numWitnesses = safeSub(numWitnesses, 1);
    }
    require(Token(token).transfer(msg.sender, amount));
    Withdraw(amount);
  }

  function isWitness(uint requestNum, address witness) public constant returns(bool) {
     
    bytes32 hash = sha256(this, requestNum, requests[requestNum].key);
    uint rand = uint(sha256(requestNum, hash, witness)) % 1000000000;
    return (
      rand * totalBalance < 1000000000 * desiredWitnesses * balances[witness] ||
      block.number > requests[requestNum].blockNumber + blockPeriod
    );
  }

  function isJuror(uint requestNum, address juror) public constant returns(bool) {
     
    bytes32 hash = sha256(1, this, requestNum, requests[requestNum].key);
    uint rand = uint(sha256(requestNum, hash, juror)) % 1000000000;
    return (
      rand * totalBalance < 1000000000 * desiredWitnesses * balances[juror]
    );
  }

  function newRequest(string key, address challenge) public {
    numRequests = safeAdd(numRequests, 1);
    require(requests[numRequests].challenge == 0x0);
    requests[numRequests].blockNumber = block.number;
    requests[numRequests].challenge = challenge;
    requests[numRequests].key = key;
    requestsPerBlockGroup[block.number / blockPeriod] = safeAdd(requestsPerBlockGroup[block.number / blockPeriod], 1);
    uint recentNumRequests = requestsPerBlockGroup[block.number / blockPeriod];
    if (recentNumRequests < drmVolumeCap) {
      requests[numRequests].fee = safeAdd(safeMul(safeMul(recentNumRequests, recentNumRequests), safeSub(drmMaxFee, drmMinFee)) / safeMul(drmVolumeCap, drmVolumeCap), drmMinFee);
    } else {
      requests[numRequests].fee = drmMaxFee;
    }
    NewRequest(numRequests, key);
  }

  function report(uint requestNum, string answer, uint winner) public {
    require(requests[requestNum].challenge != 0x0);
    require(requests[requestNum].witness1 == 0x0 || requests[requestNum].witness2 == 0x0);
    require(requests[requestNum].witness1 != msg.sender);
    require(isWitness(requestNum, msg.sender));
    reportLogic(requestNum, answer, winner);
    Report(requestNum, answer, winner);
  }

  function reportLogic(uint requestNum, string answer, uint winner) private {
    reduceToLimit(msg.sender);
    if (requests[requestNum].witness1 == 0x0) {
      requests[requestNum].witness1 = msg.sender;
      requests[requestNum].answer1 = answer;
      requests[requestNum].winner1 = winner;
    } else if (requests[requestNum].witness2 == 0x0) {
      requests[requestNum].witness2 = msg.sender;
      requests[requestNum].answer2 = answer;
      requests[requestNum].winner2 = winner;
    }
  }

  function juryNeeded(uint requestNum) public {
    require(msg.sender == requests[requestNum].challenge);
    require(!juryNeeded[requestNum]);
    juryNeeded[requestNum] = true;
    JuryNeeded(requestNum);
  }

  function juryVote(uint requestNum, bool vote) public {
    require(!juryVoted[requestNum][msg.sender]);
    require(juryNeeded[requestNum]);
    require(safeAdd(juryYesCount[requestNum], juryNoCount[requestNum]) < desiredJurors);
    require(isJuror(requestNum, msg.sender));
    juryVoted[requestNum][msg.sender] = true;
    if (vote) {
      juryYesCount[requestNum] = safeAdd(juryYesCount[requestNum], 1);
      juryYesVoters[requestNum].push(msg.sender);
    } else {
      juryNoCount[requestNum] = safeAdd(juryNoCount[requestNum], 1);
      juryNoVoters[requestNum].push(msg.sender);
    }
    JuryVote(requestNum, msg.sender, vote);
  }

  function resolve(uint requestNum) public {
    bool juryContested = juryYesCount[requestNum] > juryNoCount[requestNum] && safeAdd(juryYesCount[requestNum], juryNoCount[requestNum]) == desiredJurors;
    Challenge(requests[requestNum].challenge).resolve(
      requestNum,
      juryContested,
      juryYesCount[requestNum] > juryNoCount[requestNum] ? juryYesVoters[requestNum] : juryNoVoters[requestNum],
      requests[requestNum].winner1,
      requests[requestNum].witness1,
      requests[requestNum].witness2,
      requests[requestNum].fee
    );
    if (juryContested) {
      uint penalty1 = safeMul(balances[requests[requestNum].witness1], penalty) / (1 ether);
      uint penalty2 = safeMul(balances[requests[requestNum].witness2], penalty) / (1 ether);
      balances[requests[requestNum].witness1] = safeSub(balances[requests[requestNum].witness1], penalty1);
      balances[requests[requestNum].witness2] = safeSub(balances[requests[requestNum].witness2], penalty2);
      require(Token(token).transfer(requests[requestNum].witness1, penalty1));
      require(Token(token).transfer(requests[requestNum].witness2, penalty2));
      JuryContested(requestNum);
    }
    Resolve(requestNum);
  }

  function getWinner1(uint requestNum) public constant returns(uint) {
    return requests[requestNum].winner1;
  }

  function getWinner2(uint requestNum) public constant returns(uint) {
    return requests[requestNum].winner2;
  }

  function getRequest(uint requestNum) public constant returns(string, address, address, string, string, uint, address) {
    return (requests[requestNum].key,
            requests[requestNum].witness1,
            requests[requestNum].witness2,
            requests[requestNum].answer1,
            requests[requestNum].answer2,
            requests[requestNum].fee,
            requests[requestNum].challenge);
  }
}