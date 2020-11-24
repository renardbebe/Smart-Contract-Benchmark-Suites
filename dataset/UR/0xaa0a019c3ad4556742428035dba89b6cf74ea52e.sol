 

contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract EIP20 is EIP20Interface {

    uint256 constant MAX_UINT256 = 2**256 - 1;

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

     function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

library DLL {

  uint constant NULL_NODE_ID = 0;

  struct Node {
    uint next;
    uint prev;
  }

  struct Data {
    mapping(uint => Node) dll;
  }

  function isEmpty(Data storage self) public view returns (bool) {
    return getStart(self) == NULL_NODE_ID;
  }

  function contains(Data storage self, uint _curr) public view returns (bool) {
    if (isEmpty(self) || _curr == NULL_NODE_ID) {
      return false;
    } 

    bool isSingleNode = (getStart(self) == _curr) && (getEnd(self) == _curr);
    bool isNullNode = (getNext(self, _curr) == NULL_NODE_ID) && (getPrev(self, _curr) == NULL_NODE_ID);
    return isSingleNode || !isNullNode;
  }

  function getNext(Data storage self, uint _curr) public view returns (uint) {
    return self.dll[_curr].next;
  }

  function getPrev(Data storage self, uint _curr) public view returns (uint) {
    return self.dll[_curr].prev;
  }

  function getStart(Data storage self) public view returns (uint) {
    return getNext(self, NULL_NODE_ID);
  }

  function getEnd(Data storage self) public view returns (uint) {
    return getPrev(self, NULL_NODE_ID);
  }

   
  function insert(Data storage self, uint _prev, uint _curr, uint _next) public {
    require(_curr != NULL_NODE_ID);
    require(_prev == NULL_NODE_ID || contains(self, _prev));

    remove(self, _curr);

    require(getNext(self, _prev) == _next);

    self.dll[_curr].prev = _prev;
    self.dll[_curr].next = _next;

    self.dll[_prev].next = _curr;
    self.dll[_next].prev = _curr;
  }

  function remove(Data storage self, uint _curr) public {
    if (!contains(self, _curr)) {
      return;
    }

    uint next = getNext(self, _curr);
    uint prev = getPrev(self, _curr);

    self.dll[next].prev = prev;
    self.dll[prev].next = next;

    delete self.dll[_curr];
  }
}

library AttributeStore {
    struct Data {
        mapping(bytes32 => uint) store;
    }

    function getAttribute(Data storage self, bytes32 _UUID, string _attrName)
    public view returns (uint) {
        bytes32 key = keccak256(_UUID, _attrName);
        return self.store[key];
    }

    function setAttribute(Data storage self, bytes32 _UUID, string _attrName, uint _attrVal)
    public {
        bytes32 key = keccak256(_UUID, _attrName);
        self.store[key] = _attrVal;
    }
}

contract PLCRVoting {

     
     
     

    event VoteCommitted(address voter, uint pollID, uint numTokens);
    event VoteRevealed(address voter, uint pollID, uint numTokens, uint choice);
    event PollCreated(uint voteQuorum, uint commitDuration, uint revealDuration, uint pollID);
    event VotingRightsGranted(address voter, uint numTokens);
    event VotingRightsWithdrawn(address voter, uint numTokens);

     
     
     

    using AttributeStore for AttributeStore.Data;
    using DLL for DLL.Data;

    struct Poll {
        uint commitEndDate;      
        uint revealEndDate;      
        uint voteQuorum;	     
        uint votesFor;		     
        uint votesAgainst;       
    }
    
     
     
     

    uint constant public INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    mapping(uint => Poll) public pollMap;  
    mapping(address => uint) public voteTokenBalance;  

    mapping(address => DLL.Data) dllMap;
    AttributeStore.Data store;

    EIP20 public token;

     
     
     

     
    function PLCRVoting(address _tokenAddr) public {
        token = EIP20(_tokenAddr);
        pollNonce = INITIAL_POLL_NONCE;
    }

     
     
     

     
    function requestVotingRights(uint _numTokens) external {
        require(token.balanceOf(msg.sender) >= _numTokens);
        require(token.transferFrom(msg.sender, this, _numTokens));
        voteTokenBalance[msg.sender] += _numTokens;
        VotingRightsGranted(msg.sender, _numTokens);
    }

     
    function withdrawVotingRights(uint _numTokens) external {
        uint availableTokens = voteTokenBalance[msg.sender] - getLockedTokens(msg.sender);
        require(availableTokens >= _numTokens);
        require(token.transfer(msg.sender, _numTokens));
        voteTokenBalance[msg.sender] -= _numTokens;
        VotingRightsWithdrawn(msg.sender, _numTokens);
    }

     
    function rescueTokens(uint _pollID) external {
        require(pollEnded(_pollID));
        require(!hasBeenRevealed(msg.sender, _pollID));

        dllMap[msg.sender].remove(_pollID);
    }

     
     
     

     
    function commitVote(uint _pollID, bytes32 _secretHash, uint _numTokens, uint _prevPollID) external {
        require(commitPeriodActive(_pollID));
        require(voteTokenBalance[msg.sender] >= _numTokens);  
        require(_pollID != 0);                 

         
         
        require(_prevPollID == 0 || getCommitHash(msg.sender, _prevPollID) != 0);

        uint nextPollID = dllMap[msg.sender].getNext(_prevPollID);

         
        nextPollID = (nextPollID == _pollID) ? dllMap[msg.sender].getNext(_pollID) : nextPollID;

        require(validPosition(_prevPollID, nextPollID, msg.sender, _numTokens));
        dllMap[msg.sender].insert(_prevPollID, _pollID, nextPollID);

        bytes32 UUID = attrUUID(msg.sender, _pollID);

        store.setAttribute(UUID, "numTokens", _numTokens);
        store.setAttribute(UUID, "commitHash", uint(_secretHash));

        VoteCommitted(msg.sender, _pollID, _numTokens);
    }

     
    function validPosition(uint _prevID, uint _nextID, address _voter, uint _numTokens) public constant returns (bool valid) {
        bool prevValid = (_numTokens >= getNumTokens(_voter, _prevID));
         
        bool nextValid = (_numTokens <= getNumTokens(_voter, _nextID) || _nextID == 0); 
        return prevValid && nextValid;
    }

     
    function revealVote(uint _pollID, uint _voteOption, uint _salt) external {
         
        require(revealPeriodActive(_pollID));
        require(!hasBeenRevealed(msg.sender, _pollID));                         
        require(keccak256(_voteOption, _salt) == getCommitHash(msg.sender, _pollID));  

        uint numTokens = getNumTokens(msg.sender, _pollID); 

        if (_voteOption == 1)  
            pollMap[_pollID].votesFor += numTokens;
        else
            pollMap[_pollID].votesAgainst += numTokens;
        
        dllMap[msg.sender].remove(_pollID);  

        VoteRevealed(msg.sender, _pollID, numTokens, _voteOption);
    }

     
    function getNumPassingTokens(address _voter, uint _pollID, uint _salt) public constant returns (uint correctVotes) {
        require(pollEnded(_pollID));
        require(hasBeenRevealed(_voter, _pollID));

        uint winningChoice = isPassed(_pollID) ? 1 : 0;
        bytes32 winnerHash = keccak256(winningChoice, _salt);
        bytes32 commitHash = getCommitHash(_voter, _pollID);

        require(winnerHash == commitHash);

        return getNumTokens(_voter, _pollID);
    }

     
     
     

     
    function startPoll(uint _voteQuorum, uint _commitDuration, uint _revealDuration) public returns (uint pollID) {
        pollNonce = pollNonce + 1;

        pollMap[pollNonce] = Poll({
            voteQuorum: _voteQuorum,
            commitEndDate: block.timestamp + _commitDuration,
            revealEndDate: block.timestamp + _commitDuration + _revealDuration,
            votesFor: 0,
            votesAgainst: 0
        });

        PollCreated(_voteQuorum, _commitDuration, _revealDuration, pollNonce);
        return pollNonce;
    }
 
     
    function isPassed(uint _pollID) constant public returns (bool passed) {
        require(pollEnded(_pollID));

        Poll memory poll = pollMap[_pollID];
        return (100 * poll.votesFor) > (poll.voteQuorum * (poll.votesFor + poll.votesAgainst));
    }

     
     
     

     
    function getTotalNumberOfTokensForWinningOption(uint _pollID) constant public returns (uint numTokens) {
        require(pollEnded(_pollID));

        if (isPassed(_pollID))
            return pollMap[_pollID].votesFor;
        else
            return pollMap[_pollID].votesAgainst;
    }

     
    function pollEnded(uint _pollID) constant public returns (bool ended) {
        require(pollExists(_pollID));

        return isExpired(pollMap[_pollID].revealEndDate);
    }

     
    function commitPeriodActive(uint _pollID) constant public returns (bool active) {
        require(pollExists(_pollID));

        return !isExpired(pollMap[_pollID].commitEndDate);
    }

     
    function revealPeriodActive(uint _pollID) constant public returns (bool active) {
        require(pollExists(_pollID));

        return !isExpired(pollMap[_pollID].revealEndDate) && !commitPeriodActive(_pollID);
    }

     
    function hasBeenRevealed(address _voter, uint _pollID) constant public returns (bool revealed) {
        require(pollExists(_pollID));

        return !dllMap[_voter].contains(_pollID);
    }

     
    function pollExists(uint _pollID) constant public returns (bool exists) {
        uint commitEndDate = pollMap[_pollID].commitEndDate;
        uint revealEndDate = pollMap[_pollID].revealEndDate;

        assert(!(commitEndDate == 0 && revealEndDate != 0));
        assert(!(commitEndDate != 0 && revealEndDate == 0));

        if(commitEndDate == 0 || revealEndDate == 0) { return false; }
        return true;
    }

     
     
     

     
    function getCommitHash(address _voter, uint _pollID) constant public returns (bytes32 commitHash) { 
        return bytes32(store.getAttribute(attrUUID(_voter, _pollID), "commitHash"));    
    } 

     
    function getNumTokens(address _voter, uint _pollID) constant public returns (uint numTokens) {
        return store.getAttribute(attrUUID(_voter, _pollID), "numTokens");
    }

     
    function getLastNode(address _voter) constant public returns (uint pollID) {
        return dllMap[_voter].getPrev(0);
    }

     
    function getLockedTokens(address _voter) constant public returns (uint numTokens) {
        return getNumTokens(_voter, getLastNode(_voter));
    }

     
    function getInsertPointForNumTokens(address _voter, uint _numTokens)
    constant public returns (uint prevNode) {
      uint nodeID = getLastNode(_voter);
      uint tokensInNode = getNumTokens(_voter, nodeID);

      while(tokensInNode != 0) {
        tokensInNode = getNumTokens(_voter, nodeID);
        if(tokensInNode < _numTokens) {
          return nodeID;
        }
        nodeID = dllMap[_voter].getPrev(nodeID);
      }

      return nodeID;
    }
 
     
     
     

     
    function isExpired(uint _terminationDate) constant public returns (bool expired) {
        return (block.timestamp > _terminationDate);
    }

     
    function attrUUID(address _user, uint _pollID) public pure returns (bytes32 UUID) {
        return keccak256(_user, _pollID);
    }
}

contract Parameterizer {

   
   
   

  event _ReparameterizationProposal(address proposer, string name, uint value, bytes32 propID);
  event _NewChallenge(address challenger, bytes32 propID, uint pollID);


   
   
   

  struct ParamProposal {
    uint appExpiry;
    uint challengeID;
    uint deposit;
    string name;
    address owner;
    uint processBy;
    uint value;
  }

  struct Challenge {
    uint rewardPool;         
    address challenger;      
    bool resolved;           
    uint stake;              
    uint winningTokens;      
    mapping(address => bool) tokenClaims;
  }

   
   
   

  mapping(bytes32 => uint) public params;

   
  mapping(uint => Challenge) public challenges;
 
   
  mapping(bytes32 => ParamProposal) public proposals; 

   
  EIP20 public token;
  PLCRVoting public voting;
  uint public PROCESSBY = 604800;  

   
   
   

   
  function Parameterizer( 
    address _tokenAddr,
    address _plcrAddr,
    uint _minDeposit,
    uint _pMinDeposit,
    uint _applyStageLen,
    uint _pApplyStageLen,
    uint _commitStageLen,
    uint _pCommitStageLen,
    uint _revealStageLen,
    uint _pRevealStageLen,
    uint _dispensationPct,
    uint _pDispensationPct,
    uint _voteQuorum,
    uint _pVoteQuorum
    ) public {
      token = EIP20(_tokenAddr);
      voting = PLCRVoting(_plcrAddr);

      set("minDeposit", _minDeposit);
      set("pMinDeposit", _pMinDeposit);
      set("applyStageLen", _applyStageLen);
      set("pApplyStageLen", _pApplyStageLen);
      set("commitStageLen", _commitStageLen);
      set("pCommitStageLen", _pCommitStageLen);
      set("revealStageLen", _revealStageLen);
      set("pRevealStageLen", _pRevealStageLen);
      set("dispensationPct", _dispensationPct);
      set("pDispensationPct", _pDispensationPct);
      set("voteQuorum", _voteQuorum);
      set("pVoteQuorum", _pVoteQuorum);
  }

   
   
   

   
  function proposeReparameterization(string _name, uint _value) public returns (bytes32) {
    uint deposit = get("pMinDeposit");
    bytes32 propID = keccak256(_name, _value);

    require(!propExists(propID));  
    require(get(_name) != _value);  
    require(token.transferFrom(msg.sender, this, deposit));  

     
    proposals[propID] = ParamProposal({
      appExpiry: now + get("pApplyStageLen"),
      challengeID: 0,
      deposit: deposit,
      name: _name,
      owner: msg.sender,
      processBy: now + get("pApplyStageLen") + get("pCommitStageLen") +
        get("pRevealStageLen") + PROCESSBY,
      value: _value
    });

    _ReparameterizationProposal(msg.sender, _name, _value, propID);
    return propID;
  }

   
  function challengeReparameterization(bytes32 _propID) public returns (uint challengeID) {
    ParamProposal memory prop = proposals[_propID];
    uint deposit = get("pMinDeposit");

    require(propExists(_propID) && prop.challengeID == 0); 

     
    require(token.transferFrom(msg.sender, this, deposit));
     
    uint pollID = voting.startPoll(
      get("pVoteQuorum"),
      get("pCommitStageLen"),
      get("pRevealStageLen")
    );

    challenges[pollID] = Challenge({
      challenger: msg.sender,
      rewardPool: ((100 - get("pDispensationPct")) * deposit) / 100, 
      stake: deposit,
      resolved: false,
      winningTokens: 0
    });

    proposals[_propID].challengeID = pollID;        

    _NewChallenge(msg.sender, _propID, pollID);
    return pollID;
  }

   
  function processProposal(bytes32 _propID) public {
    ParamProposal storage prop = proposals[_propID];

    if (canBeSet(_propID)) {
      set(prop.name, prop.value);
    } else if (challengeCanBeResolved(_propID)) {
      resolveChallenge(_propID);
    } else if (now > prop.processBy) {
      require(token.transfer(prop.owner, prop.deposit));
    } else {
      revert();
    }

    delete proposals[_propID];
  }

   
  function claimReward(uint _challengeID, uint _salt) public {
     
    require(challenges[_challengeID].tokenClaims[msg.sender] == false);
    require(challenges[_challengeID].resolved == true);

    uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID, _salt);
    uint reward = voterReward(msg.sender, _challengeID, _salt);

     
     
    challenges[_challengeID].winningTokens -= voterTokens;
    challenges[_challengeID].rewardPool -= reward;

    require(token.transfer(msg.sender, reward));
    
     
    challenges[_challengeID].tokenClaims[msg.sender] = true;
  }

   
   
   

   
  function voterReward(address _voter, uint _challengeID, uint _salt)
  public view returns (uint) {
    uint winningTokens = challenges[_challengeID].winningTokens;
    uint rewardPool = challenges[_challengeID].rewardPool;
    uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID, _salt);
    return (voterTokens * rewardPool) / winningTokens;
  }

   
  function canBeSet(bytes32 _propID) view public returns (bool) {
    ParamProposal memory prop = proposals[_propID];

    return (now > prop.appExpiry && now < prop.processBy && prop.challengeID == 0);
  }

   
  function propExists(bytes32 _propID) view public returns (bool) {
    return proposals[_propID].processBy > 0;
  }

   
  function challengeCanBeResolved(bytes32 _propID) view public returns (bool) {
    ParamProposal memory prop = proposals[_propID];
    Challenge memory challenge = challenges[prop.challengeID];

    return (prop.challengeID > 0 && challenge.resolved == false &&
            voting.pollEnded(prop.challengeID));
  }

   
  function challengeWinnerReward(uint _challengeID) public view returns (uint) {
    if(voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {
       
      return 2 * challenges[_challengeID].stake;
    }
    
    return (2 * challenges[_challengeID].stake) - challenges[_challengeID].rewardPool;
  }

   
  function get(string _name) public view returns (uint value) {
    return params[keccak256(_name)];
  }

   
   
   

   
  function resolveChallenge(bytes32 _propID) private {
    ParamProposal memory prop = proposals[_propID];
    Challenge storage challenge = challenges[prop.challengeID];

     
    uint reward = challengeWinnerReward(prop.challengeID);

    if (voting.isPassed(prop.challengeID)) {  
      if(prop.processBy > now) {
        set(prop.name, prop.value);
      }
      require(token.transfer(prop.owner, reward));
    } 
    else {  
      require(token.transfer(challenges[prop.challengeID].challenger, reward));
    }

    challenge.winningTokens =
      voting.getTotalNumberOfTokensForWinningOption(prop.challengeID);
    challenge.resolved = true;
  }

   
  function set(string _name, uint _value) private {
    params[keccak256(_name)] = _value;
  }
}
contract Registry {

     
     
     

    event _Application(bytes32 listingHash, uint deposit, string data);
    event _Challenge(bytes32 listingHash, uint deposit, uint pollID, string data);
    event _Deposit(bytes32 listingHash, uint added, uint newTotal);
    event _Withdrawal(bytes32 listingHash, uint withdrew, uint newTotal);
    event _NewListingWhitelisted(bytes32 listingHash);
    event _ApplicationRemoved(bytes32 listingHash);
    event _ListingRemoved(bytes32 listingHash);
    event _ChallengeFailed(uint challengeID);
    event _ChallengeSucceeded(uint challengeID);
    event _RewardClaimed(address voter, uint challengeID, uint reward);

    struct Listing {
        uint applicationExpiry;  
        bool whitelisted;        
        address owner;           
        uint unstakedDeposit;    
        uint challengeID;        
    }

    struct Challenge {
        uint rewardPool;         
        address challenger;      
        bool resolved;           
        uint stake;              
        uint totalTokens;        
        mapping(address => bool) tokenClaims;  
    }

     
    mapping(uint => Challenge) public challenges;

     
    mapping(bytes32 => Listing) public listings;

     
    EIP20 public token;
    PLCRVoting public voting;
    Parameterizer public parameterizer;
    string public version = '1';

     
     
     

     
    function Registry(
        address _tokenAddr,
        address _plcrAddr,
        address _paramsAddr
    ) public {
        token = EIP20(_tokenAddr);
        voting = PLCRVoting(_plcrAddr);
        parameterizer = Parameterizer(_paramsAddr);
    }

     
     
     

     
    function apply(bytes32 _listingHash, uint _amount, string _data) external {
        require(!isWhitelisted(_listingHash));
        require(!appWasMade(_listingHash));
        require(_amount >= parameterizer.get("minDeposit"));

         
        Listing storage listingHash = listings[_listingHash];
        listingHash.owner = msg.sender;

         
        require(token.transferFrom(listingHash.owner, this, _amount));

         
        listingHash.applicationExpiry = block.timestamp + parameterizer.get("applyStageLen");
        listingHash.unstakedDeposit = _amount;

        _Application(_listingHash, _amount, _data);
    }

     
    function deposit(bytes32 _listingHash, uint _amount) external {
        Listing storage listingHash = listings[_listingHash];

        require(listingHash.owner == msg.sender);
        require(token.transferFrom(msg.sender, this, _amount));

        listingHash.unstakedDeposit += _amount;

        _Deposit(_listingHash, _amount, listingHash.unstakedDeposit);
    }

     
    function withdraw(bytes32 _listingHash, uint _amount) external {
        Listing storage listingHash = listings[_listingHash];

        require(listingHash.owner == msg.sender);
        require(_amount <= listingHash.unstakedDeposit);
        require(listingHash.unstakedDeposit - _amount >= parameterizer.get("minDeposit"));

        require(token.transfer(msg.sender, _amount));

        listingHash.unstakedDeposit -= _amount;

        _Withdrawal(_listingHash, _amount, listingHash.unstakedDeposit);
    }

     
    function exit(bytes32 _listingHash) external {
        Listing storage listingHash = listings[_listingHash];

        require(msg.sender == listingHash.owner);
        require(isWhitelisted(_listingHash));

         
        require(listingHash.challengeID == 0 || challenges[listingHash.challengeID].resolved);

         
        resetListing(_listingHash);
    }

     
     
     

     
    function challenge(bytes32 _listingHash, string _data) external returns (uint challengeID) {
        bytes32 listingHashHash = _listingHash;
        Listing storage listingHash = listings[listingHashHash];
        uint deposit = parameterizer.get("minDeposit");

         
        require(appWasMade(_listingHash) || listingHash.whitelisted);
         
        require(listingHash.challengeID == 0 || challenges[listingHash.challengeID].resolved);

        if (listingHash.unstakedDeposit < deposit) {
             
            resetListing(_listingHash);
            return 0;
        }

         
        require(token.transferFrom(msg.sender, this, deposit));

         
        uint pollID = voting.startPoll(
            parameterizer.get("voteQuorum"),
            parameterizer.get("commitStageLen"),
            parameterizer.get("revealStageLen")
        );

        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: ((100 - parameterizer.get("dispensationPct")) * deposit) / 100,
            stake: deposit,
            resolved: false,
            totalTokens: 0
        });

         
        listings[listingHashHash].challengeID = pollID;

         
        listings[listingHashHash].unstakedDeposit -= deposit;

        _Challenge(_listingHash, deposit, pollID, _data);
        return pollID;
    }

     
    function updateStatus(bytes32 _listingHash) public {
        if (canBeWhitelisted(_listingHash)) {
          whitelistApplication(_listingHash);
          _NewListingWhitelisted(_listingHash);
        } else if (challengeCanBeResolved(_listingHash)) {
          resolveChallenge(_listingHash);
        } else {
          revert();
        }
    }

     
     
     

     
    function claimReward(uint _challengeID, uint _salt) public {
         
        require(challenges[_challengeID].tokenClaims[msg.sender] == false);
        require(challenges[_challengeID].resolved == true);

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID, _salt);
        uint reward = voterReward(msg.sender, _challengeID, _salt);

         
         
        challenges[_challengeID].totalTokens -= voterTokens;
        challenges[_challengeID].rewardPool -= reward;

        require(token.transfer(msg.sender, reward));

         
        challenges[_challengeID].tokenClaims[msg.sender] = true;

        _RewardClaimed(msg.sender, _challengeID, reward);
    }

     
     
     

     
    function voterReward(address _voter, uint _challengeID, uint _salt)
    public view returns (uint) {
        uint totalTokens = challenges[_challengeID].totalTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID, _salt);
        return (voterTokens * rewardPool) / totalTokens;
    }

     
    function canBeWhitelisted(bytes32 _listingHash) view public returns (bool) {
        bytes32 listingHashHash = _listingHash;
        uint challengeID = listings[listingHashHash].challengeID;

         
         
         
         
        if (
            appWasMade(_listingHash) &&
            listings[listingHashHash].applicationExpiry < now &&
            !isWhitelisted(_listingHash) &&
            (challengeID == 0 || challenges[challengeID].resolved == true)
        ) { return true; }

        return false;
    }

     
    function isWhitelisted(bytes32 _listingHash) view public returns (bool whitelisted) {
        return listings[_listingHash].whitelisted;
    }

     
    function appWasMade(bytes32 _listingHash) view public returns (bool exists) {
        return listings[_listingHash].applicationExpiry > 0;
    }

     
    function challengeExists(bytes32 _listingHash) view public returns (bool) {
        bytes32 listingHashHash = _listingHash;
        uint challengeID = listings[listingHashHash].challengeID;

        return (listings[listingHashHash].challengeID > 0 && !challenges[challengeID].resolved);
    }

     
    function challengeCanBeResolved(bytes32 _listingHash) view public returns (bool) {
        bytes32 listingHashHash = _listingHash;
        uint challengeID = listings[listingHashHash].challengeID;

        require(challengeExists(_listingHash));

        return voting.pollEnded(challengeID);
    }

     
    function determineReward(uint _challengeID) public view returns (uint) {
        require(!challenges[_challengeID].resolved && voting.pollEnded(_challengeID));

         
        if (voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {
            return 2 * challenges[_challengeID].stake;
        }

        return (2 * challenges[_challengeID].stake) - challenges[_challengeID].rewardPool;
    }

     
    function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
      return challenges[_challengeID].tokenClaims[_voter];
    }

     
     
     

     
    function resolveChallenge(bytes32 _listingHash) private {
        bytes32 listingHashHash = _listingHash;
        uint challengeID = listings[listingHashHash].challengeID;

         
         
        uint reward = determineReward(challengeID);

         
        bool wasWhitelisted = isWhitelisted(_listingHash);

         
        if (voting.isPassed(challengeID)) {
            whitelistApplication(_listingHash);
             
            listings[listingHashHash].unstakedDeposit += reward;

            _ChallengeFailed(challengeID);
            if (!wasWhitelisted) { _NewListingWhitelisted(_listingHash); }
        }
         
        else {
            resetListing(_listingHash);
             
            require(token.transfer(challenges[challengeID].challenger, reward));

            _ChallengeSucceeded(challengeID);
            if (wasWhitelisted) { _ListingRemoved(_listingHash); }
            else { _ApplicationRemoved(_listingHash); }
        }

         
        challenges[challengeID].resolved = true;

         
        challenges[challengeID].totalTokens =
            voting.getTotalNumberOfTokensForWinningOption(challengeID);
    }

     
    function whitelistApplication(bytes32 _listingHash) private {
        listings[_listingHash].whitelisted = true;
    }

     
    function resetListing(bytes32 _listingHash) private {
        bytes32 listingHashHash = _listingHash;
        Listing storage listingHash = listings[listingHashHash];

         
        if (listingHash.unstakedDeposit > 0)
            require(token.transfer(listingHash.owner, listingHash.unstakedDeposit));

        delete listings[listingHashHash];
    }
}