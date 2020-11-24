 

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity^0.4.11;

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

    remove(self, _curr);

    require(_prev == NULL_NODE_ID || contains(self, _prev));
    require(_next == NULL_NODE_ID || contains(self, _next));

    require(getNext(self, _prev) == _next);
    require(getPrev(self, _next) == _prev);

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

 

 
pragma solidity^0.4.11;

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

 

pragma solidity ^0.4.24;

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

pragma solidity ^0.4.8;





 
contract PLCRVoting {

     
     
     

    event _VoteCommitted(uint indexed pollID, uint numTokens, address indexed voter);
    event _VoteRevealed(uint indexed pollID, uint numTokens, uint votesFor, uint votesAgainst, uint indexed choice, address indexed voter, uint salt);
    event _PollCreated(uint voteQuorum, uint commitEndDate, uint revealEndDate, uint indexed pollID, address indexed creator);
    event _VotingRightsGranted(uint numTokens, address indexed voter);
    event _VotingRightsWithdrawn(uint numTokens, address indexed voter);
    event _TokensRescued(uint indexed pollID, address indexed voter);

     
     
     

    using AttributeStore for AttributeStore.Data;
    using DLL for DLL.Data;
    using SafeMath for uint;

    struct Poll {
        uint commitEndDate;      
        uint revealEndDate;      
        uint voteQuorum;	     
        uint votesFor;		     
        uint votesAgainst;       
        mapping(address => bool) didCommit;   
        mapping(address => bool) didReveal;    
    }

     
     
     

    uint constant public INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    mapping(uint => Poll) public pollMap;  
    mapping(address => uint) public voteTokenBalance;  

    mapping(address => DLL.Data) dllMap;
    AttributeStore.Data store;

    IERC20 public token;

     
    constructor(address _token) public {
        require(_token != 0);

        token = IERC20(_token);
        pollNonce = INITIAL_POLL_NONCE;
    }

     
     
     

     
    function requestVotingRights(uint _numTokens) public {
        require(token.balanceOf(msg.sender) >= _numTokens);
        voteTokenBalance[msg.sender] += _numTokens;
        require(token.transferFrom(msg.sender, this, _numTokens));
        emit _VotingRightsGranted(_numTokens, msg.sender);
    }

     
    function withdrawVotingRights(uint _numTokens) external {
        uint availableTokens = voteTokenBalance[msg.sender].sub(getLockedTokens(msg.sender));
        require(availableTokens >= _numTokens);
        voteTokenBalance[msg.sender] -= _numTokens;
        require(token.transfer(msg.sender, _numTokens));
        emit _VotingRightsWithdrawn(_numTokens, msg.sender);
    }

     
    function rescueTokens(uint _pollID) public {
        require(isExpired(pollMap[_pollID].revealEndDate));
        require(dllMap[msg.sender].contains(_pollID));

        dllMap[msg.sender].remove(_pollID);
        emit _TokensRescued(_pollID, msg.sender);
    }

     
    function rescueTokensInMultiplePolls(uint[] _pollIDs) public {
         
        for (uint i = 0; i < _pollIDs.length; i++) {
            rescueTokens(_pollIDs[i]);
        }
    }

     
     
     

     
    function commitVote(uint _pollID, bytes32 _secretHash, uint _numTokens, uint _prevPollID) public {
        require(commitPeriodActive(_pollID));

         
         
        if (voteTokenBalance[msg.sender] < _numTokens) {
            uint remainder = _numTokens.sub(voteTokenBalance[msg.sender]);
            requestVotingRights(remainder);
        }

         
        require(voteTokenBalance[msg.sender] >= _numTokens);
         
        require(_pollID != 0);
         
        require(_secretHash != 0);

         
        require(_prevPollID == 0 || dllMap[msg.sender].contains(_prevPollID));

        uint nextPollID = dllMap[msg.sender].getNext(_prevPollID);

         
        if (nextPollID == _pollID) {
            nextPollID = dllMap[msg.sender].getNext(_pollID);
        }

        require(validPosition(_prevPollID, nextPollID, msg.sender, _numTokens));
        dllMap[msg.sender].insert(_prevPollID, _pollID, nextPollID);

        bytes32 UUID = attrUUID(msg.sender, _pollID);

        store.setAttribute(UUID, "numTokens", _numTokens);
        store.setAttribute(UUID, "commitHash", uint(_secretHash));

        pollMap[_pollID].didCommit[msg.sender] = true;
        emit _VoteCommitted(_pollID, _numTokens, msg.sender);
    }

     
    function commitVotes(uint[] _pollIDs, bytes32[] _secretHashes, uint[] _numsTokens, uint[] _prevPollIDs) external {
         
        require(_pollIDs.length == _secretHashes.length);
        require(_pollIDs.length == _numsTokens.length);
        require(_pollIDs.length == _prevPollIDs.length);

         
        for (uint i = 0; i < _pollIDs.length; i++) {
            commitVote(_pollIDs[i], _secretHashes[i], _numsTokens[i], _prevPollIDs[i]);
        }
    }

     
    function validPosition(uint _prevID, uint _nextID, address _voter, uint _numTokens) public constant returns (bool valid) {
        bool prevValid = (_numTokens >= getNumTokens(_voter, _prevID));
         
        bool nextValid = (_numTokens <= getNumTokens(_voter, _nextID) || _nextID == 0);
        return prevValid && nextValid;
    }

     
    function revealVote(uint _pollID, uint _voteOption, uint _salt) public {
         
        require(revealPeriodActive(_pollID));
        require(pollMap[_pollID].didCommit[msg.sender]);                          
        require(!pollMap[_pollID].didReveal[msg.sender]);                         
        require(keccak256(_voteOption, _salt) == getCommitHash(msg.sender, _pollID));  

        uint numTokens = getNumTokens(msg.sender, _pollID);

        if (_voteOption == 1) { 
            pollMap[_pollID].votesFor += numTokens;
        } else {
            pollMap[_pollID].votesAgainst += numTokens;
        }

        dllMap[msg.sender].remove(_pollID);  
        pollMap[_pollID].didReveal[msg.sender] = true;

        emit _VoteRevealed(_pollID, numTokens, pollMap[_pollID].votesFor, pollMap[_pollID].votesAgainst, _voteOption, msg.sender, _salt);
    }

     
    function revealVotes(uint[] _pollIDs, uint[] _voteOptions, uint[] _salts) external {
         
        require(_pollIDs.length == _voteOptions.length);
        require(_pollIDs.length == _salts.length);

         
        for (uint i = 0; i < _pollIDs.length; i++) {
            revealVote(_pollIDs[i], _voteOptions[i], _salts[i]);
        }
    }

     
    function getNumPassingTokens(address _voter, uint _pollID, uint _salt) public constant returns (uint correctVotes) {
        require(pollEnded(_pollID));
        require(pollMap[_pollID].didReveal[_voter]);

        uint winningChoice = isPassed(_pollID) ? 1 : 0;
        bytes32 winnerHash = keccak256(winningChoice, _salt);
        bytes32 commitHash = getCommitHash(_voter, _pollID);

        require(winnerHash == commitHash);

        return getNumTokens(_voter, _pollID);
    }

     
     
     

     
    function startPoll(uint _voteQuorum, uint _commitDuration, uint _revealDuration) public returns (uint pollID) {
        pollNonce = pollNonce + 1;

        uint commitEndDate = block.timestamp.add(_commitDuration);
        uint revealEndDate = commitEndDate.add(_revealDuration);

        pollMap[pollNonce] = Poll({
            voteQuorum: _voteQuorum,
            commitEndDate: commitEndDate,
            revealEndDate: revealEndDate,
            votesFor: 0,
            votesAgainst: 0
        });

        emit _PollCreated(_voteQuorum, commitEndDate, revealEndDate, pollNonce, msg.sender);
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

     
    function didCommit(address _voter, uint _pollID) constant public returns (bool committed) {
        require(pollExists(_pollID));

        return pollMap[_pollID].didCommit[_voter];
    }

     
    function didReveal(address _voter, uint _pollID) constant public returns (bool revealed) {
        require(pollExists(_pollID));

        return pollMap[_pollID].didReveal[_voter];
    }

     
    function pollExists(uint _pollID) constant public returns (bool exists) {
        return (_pollID != 0 && _pollID <= pollNonce);
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

     
    function getInsertPointForNumTokens(address _voter, uint _numTokens, uint _pollID)
    constant public returns (uint prevNode) {
       
      uint nodeID = getLastNode(_voter);
      uint tokensInNode = getNumTokens(_voter, nodeID);

       
      while(nodeID != 0) {
         
        tokensInNode = getNumTokens(_voter, nodeID);
        if(tokensInNode <= _numTokens) {  
          if(nodeID == _pollID) {
             
            nodeID = dllMap[_voter].getPrev(nodeID);
          }
           
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

 

pragma solidity^0.4.11;




contract Parameterizer {

     
     
     

    event _ReparameterizationProposal(string name, uint value, bytes32 propID, uint deposit, uint appEndDate, address indexed proposer);
    event _NewChallenge(bytes32 indexed propID, uint challengeID, uint commitEndDate, uint revealEndDate, address indexed challenger);
    event _ProposalAccepted(bytes32 indexed propID, string name, uint value);
    event _ProposalExpired(bytes32 indexed propID);
    event _ChallengeSucceeded(bytes32 indexed propID, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _ChallengeFailed(bytes32 indexed propID, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _RewardClaimed(uint indexed challengeID, uint reward, address indexed voter);


     
     
     

    using SafeMath for uint;

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

     
    IERC20 public token;
    PLCRVoting public voting;
    uint public PROCESSBY = 604800;  

     
    constructor(
        address _token,
        address _plcr,
        uint[] _parameters
    ) public {
        token = IERC20(_token);
        voting = PLCRVoting(_plcr);

         
        set("minDeposit", _parameters[0]);

         
        set("pMinDeposit", _parameters[1]);

         
        set("applyStageLen", _parameters[2]);

         
        set("pApplyStageLen", _parameters[3]);

         
        set("commitStageLen", _parameters[4]);

         
        set("pCommitStageLen", _parameters[5]);

         
        set("revealStageLen", _parameters[6]);

         
        set("pRevealStageLen", _parameters[7]);

         
        set("dispensationPct", _parameters[8]);

         
        set("pDispensationPct", _parameters[9]);

         
        set("voteQuorum", _parameters[10]);

         
        set("pVoteQuorum", _parameters[11]);
    }

     
     
     

     
    function proposeReparameterization(string _name, uint _value) public returns (bytes32) {
        uint deposit = get("pMinDeposit");
        bytes32 propID = keccak256(_name, _value);

        if (keccak256(_name) == keccak256("dispensationPct") ||
            keccak256(_name) == keccak256("pDispensationPct")) {
            require(_value <= 100);
        }

        require(!propExists(propID));  
        require(get(_name) != _value);  

         
        proposals[propID] = ParamProposal({
            appExpiry: now.add(get("pApplyStageLen")),
            challengeID: 0,
            deposit: deposit,
            name: _name,
            owner: msg.sender,
            processBy: now.add(get("pApplyStageLen"))
                .add(get("pCommitStageLen"))
                .add(get("pRevealStageLen"))
                .add(PROCESSBY),
            value: _value
        });

        require(token.transferFrom(msg.sender, this, deposit));  

        emit _ReparameterizationProposal(_name, _value, propID, deposit, proposals[propID].appExpiry, msg.sender);
        return propID;
    }

     
    function challengeReparameterization(bytes32 _propID) public returns (uint challengeID) {
        ParamProposal memory prop = proposals[_propID];
        uint deposit = prop.deposit;

        require(propExists(_propID) && prop.challengeID == 0);

         
        uint pollID = voting.startPoll(
            get("pVoteQuorum"),
            get("pCommitStageLen"),
            get("pRevealStageLen")
        );

        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: SafeMath.sub(100, get("pDispensationPct")).mul(deposit).div(100),
            stake: deposit,
            resolved: false,
            winningTokens: 0
        });

        proposals[_propID].challengeID = pollID;        

         
        require(token.transferFrom(msg.sender, this, deposit));

        var (commitEndDate, revealEndDate,) = voting.pollMap(pollID);

        emit _NewChallenge(_propID, pollID, commitEndDate, revealEndDate, msg.sender);
        return pollID;
    }

     
    function processProposal(bytes32 _propID) public {
        ParamProposal storage prop = proposals[_propID];
        address propOwner = prop.owner;
        uint propDeposit = prop.deposit;


         
         
        if (canBeSet(_propID)) {
             
             
            set(prop.name, prop.value);
            emit _ProposalAccepted(_propID, prop.name, prop.value);
            delete proposals[_propID];
            require(token.transfer(propOwner, propDeposit));
        } else if (challengeCanBeResolved(_propID)) {
             
            resolveChallenge(_propID);
        } else if (now > prop.processBy) {
             
            emit _ProposalExpired(_propID);
            delete proposals[_propID];
            require(token.transfer(propOwner, propDeposit));
        } else {
             
             
            revert();
        }

        assert(get("dispensationPct") <= 100);
        assert(get("pDispensationPct") <= 100);

         
        now.add(get("pApplyStageLen"))
            .add(get("pCommitStageLen"))
            .add(get("pRevealStageLen"))
            .add(PROCESSBY);

        delete proposals[_propID];
    }

     
    function claimReward(uint _challengeID, uint _salt) public {
         
        require(challenges[_challengeID].tokenClaims[msg.sender] == false);
        require(challenges[_challengeID].resolved == true);

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID, _salt);
        uint reward = voterReward(msg.sender, _challengeID, _salt);

         
         
        challenges[_challengeID].winningTokens -= voterTokens;
        challenges[_challengeID].rewardPool -= reward;

         
        challenges[_challengeID].tokenClaims[msg.sender] = true;

        emit _RewardClaimed(_challengeID, reward, msg.sender);
        require(token.transfer(msg.sender, reward));
    }

     
    function claimRewards(uint[] _challengeIDs, uint[] _salts) public {
         
        require(_challengeIDs.length == _salts.length);

         
        for (uint i = 0; i < _challengeIDs.length; i++) {
            claimReward(_challengeIDs[i], _salts[i]);
        }
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

        return (prop.challengeID > 0 && challenge.resolved == false && voting.pollEnded(prop.challengeID));
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

     
    function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
        return challenges[_challengeID].tokenClaims[_voter];
    }

     
     
     

     
    function resolveChallenge(bytes32 _propID) private {
        ParamProposal memory prop = proposals[_propID];
        Challenge storage challenge = challenges[prop.challengeID];

         
        uint reward = challengeWinnerReward(prop.challengeID);

        challenge.winningTokens = voting.getTotalNumberOfTokensForWinningOption(prop.challengeID);
        challenge.resolved = true;

        if (voting.isPassed(prop.challengeID)) {  
            if(prop.processBy > now) {
                set(prop.name, prop.value);
            }
            emit _ChallengeFailed(_propID, prop.challengeID, challenge.rewardPool, challenge.winningTokens);
            require(token.transfer(prop.owner, reward));
        }
        else {  
            emit _ChallengeSucceeded(_propID, prop.challengeID, challenge.rewardPool, challenge.winningTokens);
            require(token.transfer(challenges[prop.challengeID].challenger, reward));
        }
    }

     
    function set(string _name, uint _value) internal {
        params[keccak256(_name)] = _value;
    }
}

 

 
pragma solidity ^0.4.24;





contract AddressRegistry {

     
     
     

    event _Application(address indexed listingAddress, uint deposit, uint appEndDate, string data, address indexed applicant);
    event _Challenge(address indexed listingAddress, uint indexed challengeID, string data, uint commitEndDate, uint revealEndDate, address indexed challenger);
    event _Deposit(address indexed listingAddress, uint added, uint newTotal, address indexed owner);
    event _Withdrawal(address indexed listingAddress, uint withdrew, uint newTotal, address indexed owner);
    event _ApplicationWhitelisted(address indexed listingAddress);
    event _ApplicationRemoved(address indexed listingAddress);
    event _ListingRemoved(address indexed listingAddress);
    event _ListingWithdrawn(address indexed listingAddress);
    event _TouchAndRemoved(address indexed listingAddress);
    event _ChallengeFailed(address indexed listingAddress, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _ChallengeSucceeded(address indexed listingAddress, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _RewardClaimed(uint indexed challengeID, uint reward, address indexed voter);

    using SafeMath for uint;

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

     
    mapping(address => Listing) public listings;

     
    IERC20 public token;
    PLCRVoting public voting;
    Parameterizer public parameterizer;
    string public name;

     
    constructor(address _token, address _voting, address _parameterizer, string _name) public {
        require(_token != 0, "_token address is 0");
        require(_voting != 0, "_voting address is 0");
        require(_parameterizer != 0, "_parameterizer address is 0");

        token = IERC20(_token);
        voting = PLCRVoting(_voting);
        parameterizer = Parameterizer(_parameterizer);
        name = _name;
    }

     
     
     

     
    function apply(address listingAddress, uint _amount, string _data) public {
        require(!isWhitelisted(listingAddress), "Listing already whitelisted");
        require(!appWasMade(listingAddress), "Application already made for this address");
        require(_amount >= parameterizer.get("minDeposit"), "Deposit amount not above minDeposit");

         
        Listing storage listing = listings[listingAddress];
        listing.owner = msg.sender;

         
        listing.applicationExpiry = block.timestamp.add(parameterizer.get("applyStageLen"));
        listing.unstakedDeposit = _amount;

         
        require(token.transferFrom(listing.owner, this, _amount), "Token transfer failed");

        emit _Application(listingAddress, _amount, listing.applicationExpiry, _data, msg.sender);
    }

     
    function deposit(address listingAddress, uint _amount) external {
        Listing storage listing = listings[listingAddress];

        require(listing.owner == msg.sender, "Sender is not owner of Listing");

        listing.unstakedDeposit += _amount;
        require(token.transferFrom(msg.sender, this, _amount), "Token transfer failed");

        emit _Deposit(listingAddress, _amount, listing.unstakedDeposit, msg.sender);
    }

     
    function withdraw(address listingAddress, uint _amount) external {
        Listing storage listing = listings[listingAddress];

        require(listing.owner == msg.sender, "Sender is not owner of listing");
        require(_amount <= listing.unstakedDeposit, "Cannot withdraw more than current unstaked deposit");
        if (listing.challengeID == 0 || challenges[listing.challengeID].resolved) {  
          require(listing.unstakedDeposit - _amount >= parameterizer.get("minDeposit"), "Withdrawal prohibitied as it would put Listing unstaked deposit below minDeposit");
        }

        listing.unstakedDeposit -= _amount;
        require(token.transfer(msg.sender, _amount), "Token transfer failed");

        emit _Withdrawal(listingAddress, _amount, listing.unstakedDeposit, msg.sender);
    }

     
    function exit(address listingAddress) external {
        Listing storage listing = listings[listingAddress];

        require(msg.sender == listing.owner, "Sender is not owner of listing");
        require(isWhitelisted(listingAddress), "Listing must be whitelisted to be exited");

         
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved, "Listing must not have an active challenge to be exited");

         
        resetListing(listingAddress);
        emit _ListingWithdrawn(listingAddress);
    }

     
     
     

     
    function challenge(address listingAddress, string _data) public returns (uint challengeID) {
        Listing storage listing = listings[listingAddress];
        uint minDeposit = parameterizer.get("minDeposit");

         
        require(appWasMade(listingAddress) || listing.whitelisted, "Listing must be in application phase or already whitelisted to be challenged");
         
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved, "Listing must not have active challenge to be challenged");

        if (listing.unstakedDeposit < minDeposit) {
             
            resetListing(listingAddress);
            emit _TouchAndRemoved(listingAddress);
            return 0;
        }

         
        uint pollID = voting.startPoll(
            parameterizer.get("voteQuorum"),
            parameterizer.get("commitStageLen"),
            parameterizer.get("revealStageLen")
        );

        uint oneHundred = 100;  
        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: ((oneHundred.sub(parameterizer.get("dispensationPct"))).mul(minDeposit)).div(100),
            stake: minDeposit,
            resolved: false,
            totalTokens: 0
        });

         
        listing.challengeID = pollID;

         
        listing.unstakedDeposit -= minDeposit;

         
        require(token.transferFrom(msg.sender, this, minDeposit), "Token transfer failed");

        var (commitEndDate, revealEndDate,) = voting.pollMap(pollID);

        emit _Challenge(listingAddress, pollID, _data, commitEndDate, revealEndDate, msg.sender);
        return pollID;
    }

     
    function updateStatus(address listingAddress) public {
        if (canBeWhitelisted(listingAddress)) {
            whitelistApplication(listingAddress);
        } else if (challengeCanBeResolved(listingAddress)) {
            resolveChallenge(listingAddress);
        } else {
            revert();
        }
    }

     
    function updateStatuses(address[] listingAddresses) public {
         
        for (uint i = 0; i < listingAddresses.length; i++) {
            updateStatus(listingAddresses[i]);
        }
    }

     
     
     

     
    function claimReward(uint _challengeID, uint _salt) public {
         
        require(challenges[_challengeID].tokenClaims[msg.sender] == false, "Reward already claimed");
        require(challenges[_challengeID].resolved == true, "Challenge not yet resolved");

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID, _salt);
        uint reward = voterReward(msg.sender, _challengeID, _salt);

         
         
        challenges[_challengeID].totalTokens -= voterTokens;
        challenges[_challengeID].rewardPool -= reward;

         
        challenges[_challengeID].tokenClaims[msg.sender] = true;

        require(token.transfer(msg.sender, reward), "Token transfer failed");

        emit _RewardClaimed(_challengeID, reward, msg.sender);
    }

     
    function claimRewards(uint[] _challengeIDs, uint[] _salts) public {
         
        require(_challengeIDs.length == _salts.length, "Mismatch in length of _challengeIDs and _salts parameters");

         
        for (uint i = 0; i < _challengeIDs.length; i++) {
            claimReward(_challengeIDs[i], _salts[i]);
        }
    }

     
     
     

     
    function voterReward(address _voter, uint _challengeID, uint _salt)
    public view returns (uint) {
        uint totalTokens = challenges[_challengeID].totalTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID, _salt);
        return (voterTokens * rewardPool) / totalTokens;
    }

     
    function canBeWhitelisted(address listingAddress) view public returns (bool) {
        uint challengeID = listings[listingAddress].challengeID;

         
         
         
         
        if (
            appWasMade(listingAddress) &&
            listings[listingAddress].applicationExpiry < now &&
            !isWhitelisted(listingAddress) &&
            (challengeID == 0 || challenges[challengeID].resolved == true)
        ) { return true; }

        return false;
    }

     
    function isWhitelisted(address listingAddress) view public returns (bool whitelisted) {
        return listings[listingAddress].whitelisted;
    }

     
    function appWasMade(address listingAddress) view public returns (bool exists) {
        return listings[listingAddress].applicationExpiry > 0;
    }

     
    function challengeExists(address listingAddress) view public returns (bool) {
        uint challengeID = listings[listingAddress].challengeID;

        return (listings[listingAddress].challengeID > 0 && !challenges[challengeID].resolved);
    }

     
    function challengeCanBeResolved(address listingAddress) view public returns (bool) {
        uint challengeID = listings[listingAddress].challengeID;

        require(challengeExists(listingAddress), "Challenge does not exist for Listing");

        return voting.pollEnded(challengeID);
    }

     
    function determineReward(uint _challengeID) public view returns (uint) {
        require(!challenges[_challengeID].resolved, "Challenge already resolved");
        require(voting.pollEnded(_challengeID), "Poll for challenge has not ended");

         
        if (voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {
            return 2 * challenges[_challengeID].stake;
        }

        return (2 * challenges[_challengeID].stake) - challenges[_challengeID].rewardPool;
    }

     
    function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
        return challenges[_challengeID].tokenClaims[_voter];
    }

     
     
     

     
    function resolveChallenge(address listingAddress) internal {
        uint challengeID = listings[listingAddress].challengeID;

         
         
        uint reward = determineReward(challengeID);

         
        challenges[challengeID].resolved = true;

         
        challenges[challengeID].totalTokens =
            voting.getTotalNumberOfTokensForWinningOption(challengeID);

         
        if (voting.isPassed(challengeID)) {
            whitelistApplication(listingAddress);
             
            listings[listingAddress].unstakedDeposit += reward;

            emit _ChallengeFailed(listingAddress, challengeID, challenges[challengeID].rewardPool, challenges[challengeID].totalTokens);
        }
         
        else {
            resetListing(listingAddress);
             
            require(token.transfer(challenges[challengeID].challenger, reward), "Token transfer failure");

            emit _ChallengeSucceeded(listingAddress, challengeID, challenges[challengeID].rewardPool, challenges[challengeID].totalTokens);
        }
    }

     
    function whitelistApplication(address listingAddress) internal {
        if (!listings[listingAddress].whitelisted) { emit _ApplicationWhitelisted(listingAddress); }
        listings[listingAddress].whitelisted = true;
    }

     
    function resetListing(address listingAddress) internal {
        Listing storage listing = listings[listingAddress];

         
        if (listing.whitelisted) {
            emit _ListingRemoved(listingAddress);
        } else {
            emit _ApplicationRemoved(listingAddress);
        }

         
        address owner = listing.owner;
        uint unstakedDeposit = listing.unstakedDeposit;
        delete listings[listingAddress];

         
        if (unstakedDeposit > 0){
            require(token.transfer(owner, unstakedDeposit), "Token transfer failure");
        }
    }
}

 

pragma solidity ^0.4.24;


contract ContractAddressRegistry is AddressRegistry {

  modifier onlyContract(address contractAddress) {
    uint size;
    assembly { size := extcodesize(contractAddress) }
    require(size > 0, "Address is not a contract");
    _;
  }

  constructor(address _token, address _voting, address _parameterizer, string _name) public AddressRegistry(_token, _voting, _parameterizer, _name) {
  }

   
   
   

   
  function apply(address listingAddress, uint amount, string data) onlyContract(listingAddress) public {
    super.apply(listingAddress, amount, data);
  }
}

 

pragma solidity ^0.4.24;



contract RestrictedAddressRegistry is ContractAddressRegistry {

  modifier onlyContractOwner(address _contractAddress) {
    Ownable ownedContract = Ownable(_contractAddress);
    require(ownedContract.owner() == msg.sender, "Sender is not owner of contract");
    _;
  }

  constructor(address _token, address _voting, address _parameterizer, string _name) public ContractAddressRegistry(_token, _voting, _parameterizer, _name) {
  }

   
   
   

   
  function apply(address listingAddress, uint amount, string data) onlyContractOwner(listingAddress) public {
    super.apply(listingAddress, amount, data);
  }
}

 

pragma solidity ^0.4.19;

 
interface IGovernment {
  function getAppellate() public view returns (address);
  function getGovernmentController() public view returns (address);
  function get(string name) public view returns (uint);
}

 

pragma solidity ^0.4.23;

interface TokenTelemetryI {
  function onRequestVotingRights(address user, uint tokenAmount) external;
}

 

pragma solidity ^0.4.23;



 
contract CivilPLCRVoting is PLCRVoting {

  TokenTelemetryI public telemetry;

   
  constructor(address tokenAddr, address telemetryAddr) public PLCRVoting(tokenAddr) {
    require(telemetryAddr != 0);
    telemetry = TokenTelemetryI(telemetryAddr);
  }

   
  function requestVotingRights(uint _numTokens) public {
    super.requestVotingRights(_numTokens);
    telemetry.onRequestVotingRights(msg.sender, voteTokenBalance[msg.sender]);
  }

   
  function getNumLosingTokens(address _voter, uint _pollID, uint _salt) public view returns (uint correctVotes) {
    require(pollEnded(_pollID));
    require(pollMap[_pollID].didReveal[_voter]);

    uint losingChoice = isPassed(_pollID) ? 0 : 1;
    bytes32 loserHash = keccak256(losingChoice, _salt);
    bytes32 commitHash = getCommitHash(_voter, _pollID);

    require(loserHash == commitHash);

    return getNumTokens(_voter, _pollID);
  }

   
  function getTotalNumberOfTokensForLosingOption(uint _pollID) public view returns (uint numTokens) {
    require(pollEnded(_pollID));

    if (isPassed(_pollID))
      return pollMap[_pollID].votesAgainst;
    else
      return pollMap[_pollID].votesFor;
  }

}

 

pragma solidity ^0.4.19;


contract CivilParameterizer is Parameterizer {

   
  constructor(
    address tokenAddr,
    address plcrAddr,
    uint[] parameters
  ) public Parameterizer(tokenAddr, plcrAddr, parameters)
  {
    set("challengeAppealLen", parameters[12]);
    set("challengeAppealCommitLen", parameters[13]);
    set("challengeAppealRevealLen", parameters[14]);
  }
}

 

pragma solidity ^0.4.24;






 
contract CivilTCR is RestrictedAddressRegistry {

  event _AppealRequested(address indexed listingAddress, uint indexed challengeID, uint appealFeePaid, address requester, string data);
  event _AppealGranted(address indexed listingAddress, uint indexed challengeID, string data);
  event _FailedChallengeOverturned(address indexed listingAddress, uint indexed challengeID, uint rewardPool, uint totalTokens);
  event _SuccessfulChallengeOverturned(address indexed listingAddress, uint indexed challengeID, uint rewardPool, uint totalTokens);
  event _GrantedAppealChallenged(address indexed listingAddress, uint indexed challengeID, uint indexed appealChallengeID, string data);
  event _GrantedAppealOverturned(address indexed listingAddress, uint indexed challengeID, uint indexed appealChallengeID, uint rewardPool, uint totalTokens);
  event _GrantedAppealConfirmed(address indexed listingAddress, uint indexed challengeID, uint indexed appealChallengeID, uint rewardPool, uint totalTokens);
  event _GovernmentTransfered(address newGovernment);

  modifier onlyGovernmentController {
    require(msg.sender == government.getGovernmentController(), "sender was not the Government Controller");
    _;
  }

   
  modifier onlyAppellate {
    require(msg.sender == government.getAppellate(), "sender was not the Appellate");
    _;
  }

  CivilPLCRVoting public civilVoting;
  IGovernment public government;

   
  struct Appeal {
    address requester;
    uint appealFeePaid;
    uint appealPhaseExpiry;
    bool appealGranted;
    uint appealOpenToChallengeExpiry;
    uint appealChallengeID;
    bool overturned;
  }

  mapping(uint => uint) public challengeRequestAppealExpiries;
  mapping(uint => Appeal) public appeals;  

   
  constructor(
    IERC20 token,
    CivilPLCRVoting plcr,
    CivilParameterizer param,
    IGovernment govt
  ) public RestrictedAddressRegistry(token, address(plcr), address(param), "CivilTCR")
  {
    require(address(govt) != 0, "govt address was zero");
    require(govt.getGovernmentController() != 0, "govt.getGovernmentController address was 0");
    civilVoting = plcr;
    government = govt;
  }

   
   
   

   
  function apply(address listingAddress, uint amount, string data) public {
    super.apply(listingAddress, amount, data);
  }

   
  function requestAppeal(address listingAddress, string data) external {
    Listing storage listing = listings[listingAddress];
    require(voting.pollEnded(listing.challengeID), "Poll for listing challenge has not ended");
    require(challengeRequestAppealExpiries[listing.challengeID] > now, "Request Appeal phase is over"); // "Request Appeal Phase" active
    require(appeals[listing.challengeID].requester == address(0), "Appeal for this challenge has already been made");

    uint appealFee = government.get("appealFee");
    Appeal storage appeal = appeals[listing.challengeID];
    appeal.requester = msg.sender;
    appeal.appealFeePaid = appealFee;
    appeal.appealPhaseExpiry = now.add(government.get("judgeAppealLen"));
    require(token.transferFrom(msg.sender, this, appealFee), "Token transfer failed");
    emit _AppealRequested(listingAddress, listing.challengeID, appealFee, msg.sender, data);
  }

   
   
   

   
  function grantAppeal(address listingAddress, string data) external onlyAppellate {
    Listing storage listing = listings[listingAddress];
    Appeal storage appeal = appeals[listing.challengeID];
    require(appeal.appealPhaseExpiry > now, "Judge Appeal phase not active"); // "Judge Appeal Phase" active
    require(!appeal.appealGranted, "Appeal has already been granted");  

    appeal.appealGranted = true;
    appeal.appealOpenToChallengeExpiry = now.add(parameterizer.get("challengeAppealLen"));
    emit _AppealGranted(listingAddress, listing.challengeID, data);
  }

   
  function transferGovernment(IGovernment newGovernment) external onlyGovernmentController {
    require(address(newGovernment) != address(0), "New Government address is 0");
    government = newGovernment;
    emit _GovernmentTransfered(newGovernment);
  }

   
   
   
   

   
  function updateStatus(address listingAddress) public {
    if (canBeWhitelisted(listingAddress)) {
      whitelistApplication(listingAddress);
    } else if (challengeCanBeResolved(listingAddress)) {
      resolveChallenge(listingAddress);
    } else if (appealCanBeResolved(listingAddress)) {
      resolveAppeal(listingAddress);
    } else if (appealChallengeCanBeResolved(listingAddress)) {
      resolveAppealChallenge(listingAddress);
    } else {
      revert();
    }
  }

   
  function resolveAppeal(address listingAddress) internal {
    Listing listing = listings[listingAddress];
    Appeal appeal = appeals[listing.challengeID];
    if (appeal.appealGranted) {
       
      resolveOverturnedChallenge(listingAddress);
       
      require(token.transfer(appeal.requester, appeal.appealFeePaid), "Token transfer failed");
    } else {
       
      Challenge storage challenge = challenges[listing.challengeID];
      uint extraReward = appeal.appealFeePaid.div(2);
      challenge.rewardPool = challenge.rewardPool.add(extraReward);
      challenge.stake = challenge.stake.add(appeal.appealFeePaid.sub(extraReward));
       
      super.resolveChallenge(listingAddress);
    }
  }

   
   
   

   
  function challenge(address listingAddress, string data) public returns (uint challengeID) {
    uint id = super.challenge(listingAddress, data);
    if (id > 0) {
      uint challengeLength = parameterizer.get("commitStageLen").add(parameterizer.get("revealStageLen")).add(government.get("requestAppealLen"));
      challengeRequestAppealExpiries[id] = now.add(challengeLength);
    }
    return id;
  }

   
  function challengeGrantedAppeal(address listingAddress, string data) public returns (uint challengeID) {
    Listing storage listing = listings[listingAddress];
    Appeal storage appeal = appeals[listing.challengeID];
    require(appeal.appealGranted, "Appeal not granted");
    require(appeal.appealChallengeID == 0, "Appeal already challenged");
    require(appeal.appealOpenToChallengeExpiry > now, "Appeal no longer open to challenge");

    uint pollID = voting.startPoll(
      government.get("appealVotePercentage"),
      parameterizer.get("challengeAppealCommitLen"),
      parameterizer.get("challengeAppealRevealLen")
    );

    uint oneHundred = 100;
    uint reward = (oneHundred.sub(government.get("appealChallengeVoteDispensationPct"))).mul(appeal.appealFeePaid).div(oneHundred);
    challenges[pollID] = Challenge({
      challenger: msg.sender,
      rewardPool: reward,
      stake: appeal.appealFeePaid,
      resolved: false,
      totalTokens: 0
    });

    appeal.appealChallengeID = pollID;

    require(token.transferFrom(msg.sender, this, appeal.appealFeePaid), "Token transfer failed");
    emit _GrantedAppealChallenged(listingAddress, listing.challengeID, pollID, data);
    return pollID;
  }


   
  function resolveAppealChallenge(address listingAddress) internal {
    Listing storage listing = listings[listingAddress];
    uint challengeID = listings[listingAddress].challengeID;
    Appeal storage appeal = appeals[listing.challengeID];
    uint appealChallengeID = appeal.appealChallengeID;
    Challenge storage appealChallenge = challenges[appeal.appealChallengeID];

     
     
    uint reward = determineReward(appealChallengeID);

     
    appealChallenge.resolved = true;

     
    appealChallenge.totalTokens = voting.getTotalNumberOfTokensForWinningOption(appealChallengeID);

    if (voting.isPassed(appealChallengeID)) {  
      appeal.overturned = true;
      super.resolveChallenge(listingAddress);
      require(token.transfer(appealChallenge.challenger, reward), "Token transfer failed");
      emit _GrantedAppealOverturned(listingAddress, challengeID, appealChallengeID, appealChallenge.rewardPool, appealChallenge.totalTokens);
    } else {  
      resolveOverturnedChallenge(listingAddress);
      require(token.transfer(appeal.requester, reward), "Token transfer failed");
      emit _GrantedAppealConfirmed(listingAddress, challengeID, appealChallengeID, appealChallenge.rewardPool, appealChallenge.totalTokens);
    }
  }

   
  function claimReward(uint _challengeID, uint _salt) public {
     
    require(challenges[_challengeID].tokenClaims[msg.sender] == false, "Reward already claimed");
    require(challenges[_challengeID].resolved == true, "Challenge not yet resolved");

    uint voterTokens = getNumChallengeTokens(msg.sender, _challengeID, _salt);
    uint reward = voterReward(msg.sender, _challengeID, _salt);

     
     
    challenges[_challengeID].totalTokens = challenges[_challengeID].totalTokens.sub(voterTokens);
    challenges[_challengeID].rewardPool = challenges[_challengeID].rewardPool.sub(reward);

     
    challenges[_challengeID].tokenClaims[msg.sender] = true;

    require(token.transfer(msg.sender, reward), "Token transfer failed");

    emit _RewardClaimed(_challengeID, reward, msg.sender);
  }

   
  function getNumChallengeTokens(address voter, uint challengeID, uint salt) internal view returns (uint) {
     
    bool challengeOverturned = appeals[challengeID].appealGranted && !appeals[challengeID].overturned;
    if (challengeOverturned) {
      return civilVoting.getNumLosingTokens(voter, challengeID, salt);
    } else {
      return voting.getNumPassingTokens(voter, challengeID, salt);
    }
  }

   
  function determineReward(uint challengeID) public view returns (uint) {
     
    require(!challenges[challengeID].resolved, "Challenge already resolved");
    require(voting.pollEnded(challengeID), "Poll for challenge has not ended");
    bool challengeOverturned = appeals[challengeID].appealGranted && !appeals[challengeID].overturned;
     
    if (challengeOverturned) {
      if (civilVoting.getTotalNumberOfTokensForLosingOption(challengeID) == 0) {
        return 2 * challenges[challengeID].stake;
      }
    } else {
      if (voting.getTotalNumberOfTokensForWinningOption(challengeID) == 0) {
        return 2 * challenges[challengeID].stake;
      }
    }

    return (2 * challenges[challengeID].stake) - challenges[challengeID].rewardPool;
  }

   
  function voterReward(
    address voter,
    uint challengeID,
    uint salt
  ) public view returns (uint)
  {
    Challenge challenge = challenges[challengeID];
    uint totalTokens = challenge.totalTokens;
    uint rewardPool = challenge.rewardPool;
    uint voterTokens = getNumChallengeTokens(voter, challengeID, salt);
    return (voterTokens.mul(rewardPool)).div(totalTokens);
  }

   
  function whitelistApplication(address listingAddress) internal {
    super.whitelistApplication(listingAddress);
    listings[listingAddress].challengeID = 0;
  }

   
  function resolveOverturnedChallenge(address listingAddress) private {
    Listing storage listing = listings[listingAddress];
    uint challengeID = listing.challengeID;
    Challenge storage challenge = challenges[challengeID];
     
    uint reward = determineReward(challengeID);

    challenge.resolved = true;
     
    challenge.totalTokens = civilVoting.getTotalNumberOfTokensForLosingOption(challengeID);

     
    if (!voting.isPassed(challengeID)) {  
      whitelistApplication(listingAddress);
       
      listing.unstakedDeposit = listing.unstakedDeposit.add(reward);

      emit _SuccessfulChallengeOverturned(listingAddress, challengeID, challenge.rewardPool, challenge.totalTokens);
    } else {  
      resetListing(listingAddress);
       
      require(token.transfer(challenge.challenger, reward), "Token transfer failed");

      emit _FailedChallengeOverturned(listingAddress, challengeID, challenge.rewardPool, challenge.totalTokens);
    }
  }

   
  function challengeCanBeResolved(address listingAddress) view public returns (bool canBeResolved) {
    uint challengeID = listings[listingAddress].challengeID;
    require(challengeExists(listingAddress), "Challenge does not exist for listing");
    if (challengeRequestAppealExpiries[challengeID] > now) {
      return false;
    }
    return (appeals[challengeID].appealPhaseExpiry == 0);
  }

   
  function appealCanBeResolved(address listingAddress) view public returns (bool canBeResolved) {
    uint challengeID = listings[listingAddress].challengeID;
    Appeal appeal = appeals[challengeID];
    require(challengeExists(listingAddress), "Challenge does not exist for listing");
    if (appeal.appealPhaseExpiry == 0) {
      return false;
    }
    if (!appeal.appealGranted) {
      return appeal.appealPhaseExpiry < now;
    } else {
      return appeal.appealOpenToChallengeExpiry < now && appeal.appealChallengeID == 0;
    }
  }

   
  function appealChallengeCanBeResolved(address listingAddress) view public returns (bool canBeResolved) {
    uint challengeID = listings[listingAddress].challengeID;
    Appeal appeal = appeals[challengeID];
    require(challengeExists(listingAddress), "Challenge does not exist for listing");
    if (appeal.appealChallengeID == 0) {
      return false;
    }
    return voting.pollEnded(appeal.appealChallengeID);
  }
}