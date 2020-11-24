 

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

 

contract EIP20Interface {
     
     
    function totalSupply() public view returns (uint256 supply);

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

contract CanCheckERC165 {
    bytes4 constant InvalidID = 0xffffffff;
    bytes4 constant ERC165ID = 0x01ffc9a7;
    function doesContractImplementInterface(address _contract, bytes4 _interfaceId) external view returns (bool) {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, ERC165ID);
        if ((success==0)||(result==0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, InvalidID);
        if ((success==0)||(result!=0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if ((success==1)&&(result==1)) {
            return true;
        }
        return false;
    }

    function noThrowCall(address _contract, bytes4 _interfaceId) internal view returns (uint256 success, uint256 result) {
        bytes4 erc165ID = ERC165ID;

        assembly {
                let x := mload(0x40)                
                mstore(x, erc165ID)                 
                mstore(add(x, 0x04), _interfaceId)  

                success := staticcall(
                                    30000,          
                                    _contract,      
                                    x,              
                                    0x20,           
                                    x,              
                                    0x20)           

                result := mload(x)                  
        }
    }
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

     
     
     

    event _VoteCommitted(uint indexed pollID, uint numTokens, address indexed voter);
    event _VoteRevealed(uint indexed pollID, uint numTokens, uint votesFor, uint votesAgainst, uint indexed choice, address indexed voter);
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

    EIP20Interface public token;

     
    constructor(address _token) public {
        require(_token != 0);

        token = EIP20Interface(_token);
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
        require(keccak256(abi.encodePacked(_voteOption, _salt)) == getCommitHash(msg.sender, _pollID));  

        uint numTokens = getNumTokens(msg.sender, _pollID);

        if (_voteOption == 1) { 
            pollMap[_pollID].votesFor += numTokens;
        } else {
            pollMap[_pollID].votesAgainst += numTokens;
        }

        dllMap[msg.sender].remove(_pollID);  
        pollMap[_pollID].didReveal[msg.sender] = true;

        emit _VoteRevealed(_pollID, numTokens, pollMap[_pollID].votesFor, pollMap[_pollID].votesAgainst, _voteOption, msg.sender);
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
        bytes32 winnerHash = keccak256(abi.encodePacked(winningChoice, _salt));
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
            if (tokensInNode <= _numTokens) {  
                if (nodeID == _pollID) {
                     
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
        return keccak256(abi.encodePacked(_user, _pollID));
    }
}

 

contract Parameterizer is Ownable, CanCheckERC165 {

   
   
   

  event _ReparameterizationProposal(string name, uint value, bytes32 propID, uint deposit, uint appEndDate);
  event _NewChallenge(bytes32 indexed propID, uint challengeID, uint commitEndDate, uint revealEndDate);
  event _ProposalAccepted(bytes32 indexed propID, string name, uint value);
  event _ProposalExpired(bytes32 indexed propID);
  event _ChallengeSucceeded(bytes32 indexed propID, uint indexed challengeID, uint rewardPool, uint totalTokens);
  event _ChallengeFailed(bytes32 indexed propID, uint indexed challengeID, uint rewardPool, uint totalTokens);
  event _RewardClaimed(uint indexed challengeID, uint reward);


   
   
   

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

   
  EIP20Interface public token;
  PLCRVoting public voting;
  uint public PROCESSBY = 604800;  

  string constant NEW_REGISTRY = "_newRegistry";
  bytes32 constant NEW_REGISTRY_KEC = keccak256(abi.encodePacked(NEW_REGISTRY));
  bytes32 constant DISPENSATION_PCT_KEC = keccak256(abi.encodePacked("dispensationPct"));
  bytes32 constant P_DISPENSATION_PCT_KEC = keccak256(abi.encodePacked("pDispensationPct"));

   
  bytes4 public REGISTRY_INTERFACE_REQUIREMENT;

   
   
   

   
  constructor(
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
    uint _pVoteQuorum,
    bytes4 _newRegistryIface
    ) Ownable() public {
      token = EIP20Interface(_tokenAddr);
      voting = PLCRVoting(_plcrAddr);
      REGISTRY_INTERFACE_REQUIREMENT = _newRegistryIface;

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
    bytes32 propID = keccak256(abi.encodePacked(_name, _value));
    bytes32 _nameKec = keccak256(abi.encodePacked(_name));

    if (_nameKec == DISPENSATION_PCT_KEC ||
       _nameKec == P_DISPENSATION_PCT_KEC) {
        require(_value <= 100);
    }

    if(keccak256(abi.encodePacked(_name)) == NEW_REGISTRY_KEC) {
      require(getNewRegistry() == address(0));
      require(_value != 0);
      require(msg.sender == owner);
      require((_value & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff) == _value);  
      require(this.doesContractImplementInterface(address(_value), REGISTRY_INTERFACE_REQUIREMENT));
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

    emit _ReparameterizationProposal(_name, _value, propID, deposit, proposals[propID].appExpiry);
    return propID;
  }

   
  function getNewRegistry() public view returns (address) {
     
    return address(params[NEW_REGISTRY_KEC]);  
  }

   
  function challengeReparameterization(bytes32 _propID) public returns (uint) {
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

    (uint commitEndDate, uint revealEndDate,,,) = voting.pollMap(pollID);

    emit _NewChallenge(_propID, pollID, commitEndDate, revealEndDate);
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

     
     
    challenges[_challengeID].winningTokens = challenges[_challengeID].winningTokens.sub(voterTokens);
    challenges[_challengeID].rewardPool = challenges[_challengeID].rewardPool.sub(reward);

     
    challenges[_challengeID].tokenClaims[msg.sender] = true;

    emit _RewardClaimed(_challengeID, reward);
    require(token.transfer(msg.sender, reward));
  }

   
   
   

   
  function voterReward(address _voter, uint _challengeID, uint _salt)
  public view returns (uint) {
    uint winningTokens = challenges[_challengeID].winningTokens;
    uint rewardPool = challenges[_challengeID].rewardPool;
    uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID, _salt);
    return voterTokens.mul(rewardPool).div(winningTokens);
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
       
      return challenges[_challengeID].stake.mul(2);
    }

    return challenges[_challengeID].stake.mul(2).sub(challenges[_challengeID].rewardPool);
  }

   
  function get(string _name) public view returns (uint value) {
    return params[keccak256(abi.encodePacked(_name))];
  }

   
  function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
    return challenges[_challengeID].tokenClaims[_voter];
  }

   
   
   

   
  function resolveChallenge(bytes32 _propID) private {
    ParamProposal memory prop = proposals[_propID];
    Challenge storage challenge = challenges[prop.challengeID];

     
    uint reward = challengeWinnerReward(prop.challengeID);

    challenge.winningTokens =
      voting.getTotalNumberOfTokensForWinningOption(prop.challengeID);
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

   
  function set(string _name, uint _value) private {
    params[keccak256(abi.encodePacked(_name))] = _value;
  }
}

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

contract SupercedesRegistry is ERC165 {
    function canReceiveListing(bytes32 listingHash, uint applicationExpiry, bool whitelisted, address owner, uint unstakedDeposit, uint challengeID) external view returns (bool);
    function receiveListing(bytes32 listingHash, uint applicationExpiry, bool whitelisted, address owner, uint unstakedDeposit, uint challengeID) external;
    function getSupercedesRegistryInterfaceID() public pure returns (bytes4) {
        SupercedesRegistry i;
        return i.canReceiveListing.selector ^ i.receiveListing.selector;
    }
}

contract HumanRegistry {

     
     
     

    event _Application(bytes32 indexed listingHash, uint deposit, uint appEndDate, string data);
    event _Challenge(bytes32 indexed listingHash, uint challengeID, uint deposit, string data);
    event _Deposit(bytes32 indexed listingHash, uint added, uint newTotal);
    event _Withdrawal(bytes32 indexed listingHash, uint withdrew, uint newTotal);
    event _ApplicationWhitelisted(bytes32 indexed listingHash);
    event _ApplicationRemoved(bytes32 indexed listingHash);
    event _ListingRemoved(bytes32 indexed listingHash);
    event _ListingWithdrawn(bytes32 indexed listingHash);
    event _TouchAndRemoved(bytes32 indexed listingHash);
    event _ChallengeFailed(bytes32 indexed listingHash, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _ChallengeSucceeded(bytes32 indexed listingHash, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _RewardClaimed(uint indexed challengeID, uint reward, address voter);
    event _ListingMigrated(bytes32 indexed listingHash, address newRegistry);

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

     
    mapping (address => bool) public humans;

     
    mapping(uint => Challenge) public challenges;

     
    mapping(bytes32 => Listing) public listings;

     
    mapping(address => uint) public numApplications;

     
    mapping(address => uint) public totalStaked;

     
    EIP20Interface public token;
    PLCRVoting public voting;
    Parameterizer public parameterizer;
    string public constant version = "1";

     
     
     

     
    constructor(
        address _tokenAddr,
        address _plcrAddr,
        address _paramsAddr
    ) public {
        token = EIP20Interface(_tokenAddr);
        voting = PLCRVoting(_plcrAddr);
        parameterizer = Parameterizer(_paramsAddr);
    }

     
     
     

     
    function apply(bytes32 _listingHash, uint _amount, string _data) onlyIfCurrentRegistry external {
        require(!isWhitelisted(_listingHash));
        require(!appWasMade(_listingHash));
        require(_amount >= parameterizer.get("minDeposit"));

         
        Listing storage listing = listings[_listingHash];
        listing.owner = msg.sender;

         
        listing.applicationExpiry = block.timestamp.add(parameterizer.get("applyStageLen"));
        listing.unstakedDeposit = _amount;

         
        numApplications[listing.owner] = numApplications[listing.owner].add(1);

         
        totalStaked[listing.owner] = totalStaked[listing.owner].add(_amount);

         
        require(token.transferFrom(listing.owner, this, _amount));
        emit _Application(_listingHash, _amount, listing.applicationExpiry, _data);
    }

     
    function deposit(bytes32 _listingHash, uint _amount) external {
        Listing storage listing = listings[_listingHash];

        require(listing.owner == msg.sender);

        listing.unstakedDeposit = listing.unstakedDeposit.add(_amount);

         
        totalStaked[listing.owner] = totalStaked[listing.owner].add(_amount);

        require(token.transferFrom(msg.sender, this, _amount));

        emit _Deposit(_listingHash, _amount, listing.unstakedDeposit);
    }

     
    function withdraw(bytes32 _listingHash, uint _amount) external {
        Listing storage listing = listings[_listingHash];

        require(listing.owner == msg.sender);
        require(_amount <= listing.unstakedDeposit);
        require(listing.unstakedDeposit.sub(_amount) >= parameterizer.get("minDeposit"));

        listing.unstakedDeposit = listing.unstakedDeposit.sub(_amount);

        require(token.transfer(msg.sender, _amount));

        emit _Withdrawal(_listingHash, _amount, listing.unstakedDeposit);
    }

     
    function exit(bytes32 _listingHash) external {
        Listing storage listing = listings[_listingHash];

        require(msg.sender == listing.owner);
        require(isWhitelisted(_listingHash));

         
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);

         
        resetListing(_listingHash);
        emit _ListingWithdrawn(_listingHash);
    }

     
     
     

     
    function challenge(bytes32 _listingHash, uint _deposit, string _data) onlyIfCurrentRegistry external returns (uint challengeID) {
        Listing storage listing = listings[_listingHash];
        uint minDeposit = parameterizer.get("minDeposit");

         
        require(appWasMade(_listingHash) || listing.whitelisted);
         
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);

        if (listing.unstakedDeposit < minDeposit) {
             
            resetListing(_listingHash);
            emit _TouchAndRemoved(_listingHash);
            return 0;
        }

         
        uint pollID = voting.startPoll(
            parameterizer.get("voteQuorum"),
            parameterizer.get("commitStageLen"),
            parameterizer.get("revealStageLen")
        );

        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: ((100 - parameterizer.get("dispensationPct")) * _deposit) / 100,
            stake: _deposit,
            resolved: false,
            totalTokens: 0
        });

         
        listing.challengeID = pollID;

         
        require(_deposit >= minDeposit && _deposit <= listing.unstakedDeposit);

         
        listing.unstakedDeposit = listing.unstakedDeposit.sub(_deposit);

         
        require(token.transferFrom(msg.sender, this, _deposit));

        emit _Challenge(_listingHash, pollID, _deposit, _data);
        return pollID;
    }

     
    function updateStatus(bytes32 _listingHash) public {
        if (canBeWhitelisted(_listingHash)) {
          whitelistApplication(_listingHash);
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

         
         
        challenges[_challengeID].totalTokens = challenges[_challengeID].totalTokens.sub(voterTokens);
        challenges[_challengeID].rewardPool = challenges[_challengeID].rewardPool.sub(reward);

         
        challenges[_challengeID].tokenClaims[msg.sender] = true;

        require(token.transfer(msg.sender, reward));

        emit _RewardClaimed(_challengeID, reward, msg.sender);
    }

     
     
     

     
    function voterReward(address _voter, uint _challengeID, uint _salt)
    public view returns (uint) {
        uint totalTokens = challenges[_challengeID].totalTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID, _salt);
        return (voterTokens * rewardPool) / totalTokens;
    }

     
    function canBeWhitelisted(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

         
         
         
         
        if (
            appWasMade(_listingHash) &&
            listings[_listingHash].applicationExpiry < now &&
            !isWhitelisted(_listingHash) &&
            (challengeID == 0 || challenges[challengeID].resolved == true)
        ) {
          return true;
        }

        return false;
    }

     
    function isHuman(address _who) view public returns (bool human) {
        return humans[_who];
    }

     
    function isWhitelisted(bytes32 _listingHash) view public returns (bool whitelisted) {
        return listings[_listingHash].whitelisted;
    }

     
    function appWasMade(bytes32 _listingHash) view public returns (bool exists) {
        return listings[_listingHash].applicationExpiry > 0;
    }

     
    function challengeExists(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

        return (challengeID > 0 && !challenges[challengeID].resolved);
    }

     
    function challengeCanBeResolved(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

        require(challengeExists(_listingHash));

        return voting.pollEnded(challengeID);
    }

     
    function determineReward(uint _challengeID) public view returns (uint) {
        require(!challenges[_challengeID].resolved && voting.pollEnded(_challengeID));

         
        if (voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {
            return challenges[_challengeID].stake.mul(2);
        }

        return (challenges[_challengeID].stake).mul(2).sub(challenges[_challengeID].rewardPool);
    }

     
    function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
      return challenges[_challengeID].tokenClaims[_voter];
    }

     
     
     

     
    function resolveChallenge(bytes32 _listingHash) private {
        uint challengeID = listings[_listingHash].challengeID;

         
         
        uint reward = determineReward(challengeID);

         
        challenges[challengeID].resolved = true;

         
        challenges[challengeID].totalTokens =
            voting.getTotalNumberOfTokensForWinningOption(challengeID);

         
        if (voting.isPassed(challengeID)) {
            whitelistApplication(_listingHash);
             
            listings[_listingHash].unstakedDeposit = listings[_listingHash].unstakedDeposit.add(reward);

            totalStaked[listings[_listingHash].owner] = totalStaked[listings[_listingHash].owner].add(reward);

            emit _ChallengeFailed(_listingHash, challengeID, challenges[challengeID].rewardPool, challenges[challengeID].totalTokens);
        }
         
        else {
            resetListing(_listingHash);
             
            require(token.transfer(challenges[challengeID].challenger, reward));

            emit _ChallengeSucceeded(_listingHash, challengeID, challenges[challengeID].rewardPool, challenges[challengeID].totalTokens);
        }
    }

     
    function whitelistApplication(bytes32 _listingHash) private {
        Listing storage listing = listings[_listingHash];

        if (!listing.whitelisted) {
            emit _ApplicationWhitelisted(_listingHash);
        }
        listing.whitelisted = true;

         
        humans[listing.owner] = true;
    }

     
    function resetListing(bytes32 _listingHash) private {
        Listing storage listing = listings[_listingHash];

         
        if (listing.whitelisted) {
            emit _ListingRemoved(_listingHash);
        } else {
            emit _ApplicationRemoved(_listingHash);
        }

         
        address owner = listing.owner;
        uint unstakedDeposit = listing.unstakedDeposit;
        delete listings[_listingHash];

         
        delete humans[owner];

         
        if (unstakedDeposit > 0){
            require(token.transfer(owner, unstakedDeposit));
        }
    }

     
    modifier onlyIfCurrentRegistry() {
        require(parameterizer.getNewRegistry() == address(0));
        _;
    }

     
    modifier onlyIfOutdatedRegistry() {
        require(parameterizer.getNewRegistry() != address(0));
        _;
    }

     
    function listingExists(bytes32 listingHash) public view returns (bool) {
        return listings[listingHash].owner != address(0);
    }

     
    function migrateListing(bytes32 listingHash) onlyIfOutdatedRegistry public {
      require(listingExists(listingHash));  
      require(!challengeExists(listingHash));  

      address newRegistryAddress = parameterizer.getNewRegistry();
      SupercedesRegistry newRegistry = SupercedesRegistry(newRegistryAddress);
      Listing storage listing = listings[listingHash];

      require(newRegistry.canReceiveListing(
        listingHash, listing.applicationExpiry,
        listing.whitelisted, listing.owner,
        listing.unstakedDeposit, listing.challengeID
      ));

      token.approve(newRegistry, listing.unstakedDeposit);
      newRegistry.receiveListing(
        listingHash, listing.applicationExpiry,
        listing.whitelisted, listing.owner,
        listing.unstakedDeposit, listing.challengeID
      );
      delete listings[listingHash];
      emit _ListingMigrated(listingHash, newRegistryAddress);
    }
}