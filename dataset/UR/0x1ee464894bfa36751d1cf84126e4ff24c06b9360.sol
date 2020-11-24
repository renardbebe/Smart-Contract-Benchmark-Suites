 

pragma solidity ^0.4.23;


 
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



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 


library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList{
        mapping (uint256 => mapping (bool => uint256)) list;
    }

     
     
    function listExists(LinkedList storage self)
        public
        view returns (bool)
    {
         
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

     
     
     
    function nodeExists(LinkedList storage self, uint256 _node)
        public
        view returns (bool)
    {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

     
     
    function sizeOf(LinkedList storage self) public view returns (uint256 numElements) {
        bool exists;
        uint256 i;
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

     
     
     
    function getNode(LinkedList storage self, uint256 _node)
        public view returns (bool,uint256,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0,0);
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

     
     
     
     
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        public view returns (bool,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

     
     
     
     
     
     
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        public view returns (uint256)
    {
        if (sizeOf(self) == 0) { return 0; }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

     
     
     
     
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) private  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

     
     
     
     
     
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

     
     
     
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return 0; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

     
     
     
     
    function push(LinkedList storage self, uint256 _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }

     
     
     
    function pop(LinkedList storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}
 
 


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





 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
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
        mapping(address => uint) voteOptions;  
    }

     
     
     

    uint constant public INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    mapping(uint => Poll) public pollMap;  
    mapping(address => uint) public voteTokenBalance;  

    mapping(address => DLL.Data) dllMap;
    AttributeStore.Data store;

    EIP20Interface public token;

     
    function init(address _token) public {
        require(_token != address(0) && address(token) == address(0));

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
        pollMap[_pollID].voteOptions[msg.sender] = _voteOption;

        emit _VoteRevealed(_pollID, numTokens, pollMap[_pollID].votesFor, pollMap[_pollID].votesAgainst, _voteOption, msg.sender, _salt);
    }

     
    function revealVotes(uint[] _pollIDs, uint[] _voteOptions, uint[] _salts) external {
         
        require(_pollIDs.length == _voteOptions.length);
        require(_pollIDs.length == _salts.length);

         
        for (uint i = 0; i < _pollIDs.length; i++) {
            revealVote(_pollIDs[i], _voteOptions[i], _salts[i]);
        }
    }

     
    function getNumPassingTokens(address _voter, uint _pollID) public constant returns (uint correctVotes) {
        require(pollEnded(_pollID));
        require(pollMap[_pollID].didReveal[_voter]);

        uint winningChoice = isPassed(_pollID) ? 1 : 0;
        uint voterVoteOption = pollMap[_pollID].voteOptions[_voter];

        require(voterVoteOption == winningChoice, "Voter revealed, but not in the majority");

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
        return keccak256(abi.encodePacked(_user, _pollID));
    }
}








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

     
    EIP20Interface public token;
    PLCRVoting public voting;
    uint public PROCESSBY = 604800;  

     
    function init(
        address _token,
        address _plcr,
        uint[] _parameters
    ) public {
        require(_token != 0 && address(token) == 0);
        require(_plcr != 0 && address(voting) == 0);

        token = EIP20Interface(_token);
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

         
        set("exitTimeDelay", _parameters[12]);

         
        set("exitPeriodLen", _parameters[13]);
    }

     
     
     

     
    function proposeReparameterization(string _name, uint _value) public returns (bytes32) {
        uint deposit = get("pMinDeposit");
        bytes32 propID = keccak256(abi.encodePacked(_name, _value));

        if (keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked("dispensationPct")) ||
            keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked("pDispensationPct"))) {
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

        (uint commitEndDate, uint revealEndDate,,,) = voting.pollMap(pollID);

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

     
    function claimReward(uint _challengeID) public {
        Challenge storage challenge = challenges[_challengeID];
         
        require(challenge.tokenClaims[msg.sender] == false);
        require(challenge.resolved == true);

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID);
        uint reward = voterReward(msg.sender, _challengeID);

         
         
        challenge.winningTokens -= voterTokens;
        challenge.rewardPool -= reward;

         
        challenge.tokenClaims[msg.sender] = true;

        emit _RewardClaimed(_challengeID, reward, msg.sender);
        require(token.transfer(msg.sender, reward));
    }

     
    function claimRewards(uint[] _challengeIDs) public {
         
        for (uint i = 0; i < _challengeIDs.length; i++) {
            claimReward(_challengeIDs[i]);
        }
    }

     
     
     

     
    function voterReward(address _voter, uint _challengeID)
    public view returns (uint) {
        uint winningTokens = challenges[_challengeID].winningTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID);
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
        return params[keccak256(abi.encodePacked(_name))];
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

     
    function set(string _name, uint _value) private {
        params[keccak256(abi.encodePacked(_name))] = _value;
    }
}




contract Registry {

     
     
     

    event _Application(bytes32 indexed listingHash, uint deposit, uint appEndDate, string data, address indexed applicant);
    event _Challenge(bytes32 indexed listingHash, uint challengeID, string data, uint commitEndDate, uint revealEndDate, address indexed challenger);
    event _Deposit(bytes32 indexed listingHash, uint added, uint newTotal, address indexed owner);
    event _Withdrawal(bytes32 indexed listingHash, uint withdrew, uint newTotal, address indexed owner);
    event _ApplicationWhitelisted(bytes32 indexed listingHash);
    event _ApplicationRemoved(bytes32 indexed listingHash);
    event _ListingRemoved(bytes32 indexed listingHash);
    event _ListingWithdrawn(bytes32 indexed listingHash, address indexed owner);
    event _TouchAndRemoved(bytes32 indexed listingHash);
    event _ChallengeFailed(bytes32 indexed listingHash, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _ChallengeSucceeded(bytes32 indexed listingHash, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _RewardClaimed(uint indexed challengeID, uint reward, address indexed voter);
    event _ExitInitialized(bytes32 indexed listingHash, uint exitTime, uint exitDelayEndDate, address indexed owner);

    using SafeMath for uint;

    struct Listing {
        uint applicationExpiry;  
        bool whitelisted;        
        address owner;           
        uint unstakedDeposit;    
        uint challengeID;        
	uint exitTime;		 
        uint exitTimeExpiry;     
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

     
    EIP20Interface public token;
    PLCRVoting public voting;
    Parameterizer public parameterizer;
    string public name;

     
    function init(address _token, address _voting, address _parameterizer, string _name) public {
        require(_token != 0 && address(token) == 0);
        require(_voting != 0 && address(voting) == 0);
        require(_parameterizer != 0 && address(parameterizer) == 0);

        token = EIP20Interface(_token);
        voting = PLCRVoting(_voting);
        parameterizer = Parameterizer(_parameterizer);
        name = _name;
    }

     
     
     

     
    function apply(bytes32 _listingHash, uint _amount, string _data) external {
        require(!isWhitelisted(_listingHash));
        require(!appWasMade(_listingHash));
        require(_amount >= parameterizer.get("minDeposit"));

         
        Listing storage listing = listings[_listingHash];
        listing.owner = msg.sender;

         
        listing.applicationExpiry = block.timestamp.add(parameterizer.get("applyStageLen"));
        listing.unstakedDeposit = _amount;

         
        require(token.transferFrom(listing.owner, this, _amount));

        emit _Application(_listingHash, _amount, listing.applicationExpiry, _data, msg.sender);
    }

     
    function deposit(bytes32 _listingHash, uint _amount) external {
        Listing storage listing = listings[_listingHash];

        require(listing.owner == msg.sender);

        listing.unstakedDeposit += _amount;
        require(token.transferFrom(msg.sender, this, _amount));

        emit _Deposit(_listingHash, _amount, listing.unstakedDeposit, msg.sender);
    }

     
    function withdraw(bytes32 _listingHash, uint _amount) external {
        Listing storage listing = listings[_listingHash];

        require(listing.owner == msg.sender);
        require(_amount <= listing.unstakedDeposit);
        require(listing.unstakedDeposit - _amount >= parameterizer.get("minDeposit"));

        listing.unstakedDeposit -= _amount;
        require(token.transfer(msg.sender, _amount));

        emit _Withdrawal(_listingHash, _amount, listing.unstakedDeposit, msg.sender);
    }

     
    function initExit(bytes32 _listingHash) external {
        Listing storage listing = listings[_listingHash];

        require(msg.sender == listing.owner);
        require(isWhitelisted(_listingHash));
         
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);

         
        require(listing.exitTime == 0 || now > listing.exitTimeExpiry);

         
        listing.exitTime = now.add(parameterizer.get("exitTimeDelay"));
	 
	listing.exitTimeExpiry = listing.exitTime.add(parameterizer.get("exitPeriodLen"));
        emit _ExitInitialized(_listingHash, listing.exitTime,
            listing.exitTimeExpiry, msg.sender);
    }

     
    function finalizeExit(bytes32 _listingHash) external {
        Listing storage listing = listings[_listingHash];

        require(msg.sender == listing.owner);
        require(isWhitelisted(_listingHash));
         
        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);

         
        require(listing.exitTime > 0);
         
	require(listing.exitTime < now && now < listing.exitTimeExpiry);

        resetListing(_listingHash);
        emit _ListingWithdrawn(_listingHash, msg.sender);
    }

     
     
     

     
    function challenge(bytes32 _listingHash, string _data) external returns (uint challengeID) {
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

         
        require(token.transferFrom(msg.sender, this, minDeposit));

        (uint commitEndDate, uint revealEndDate,,,) = voting.pollMap(pollID);

        emit _Challenge(_listingHash, pollID, _data, commitEndDate, revealEndDate, msg.sender);
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

     
    function updateStatuses(bytes32[] _listingHashes) public {
         
        for (uint i = 0; i < _listingHashes.length; i++) {
            updateStatus(_listingHashes[i]);
        }
    }

     
     
     

     
    function claimReward(uint _challengeID) public {
        Challenge storage challengeInstance = challenges[_challengeID];
         
         
        require(challengeInstance.tokenClaims[msg.sender] == false);
        require(challengeInstance.resolved == true);

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID);
        uint reward = voterTokens.mul(challengeInstance.rewardPool)
                      .div(challengeInstance.totalTokens);

         
         
        challengeInstance.totalTokens -= voterTokens;
        challengeInstance.rewardPool -= reward;

         
        challengeInstance.tokenClaims[msg.sender] = true;

        require(token.transfer(msg.sender, reward));

        emit _RewardClaimed(_challengeID, reward, msg.sender);
    }

     
    function claimRewards(uint[] _challengeIDs) public {
         
        for (uint i = 0; i < _challengeIDs.length; i++) {
            claimReward(_challengeIDs[i]);
        }
    }

     
     
     

     
    function voterReward(address _voter, uint _challengeID)
    public view returns (uint) {
        uint totalTokens = challenges[_challengeID].totalTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID);
        return voterTokens.mul(rewardPool).div(totalTokens);
    }

     
    function canBeWhitelisted(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

         
         
         
         
        if (
            appWasMade(_listingHash) &&
            listings[_listingHash].applicationExpiry < now &&
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
        uint challengeID = listings[_listingHash].challengeID;

        return (listings[_listingHash].challengeID > 0 && !challenges[challengeID].resolved);
    }

     
    function challengeCanBeResolved(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

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
        uint challengeID = listings[_listingHash].challengeID;

         
         
        uint reward = determineReward(challengeID);

         
        challenges[challengeID].resolved = true;

         
        challenges[challengeID].totalTokens =
            voting.getTotalNumberOfTokensForWinningOption(challengeID);

         
        if (voting.isPassed(challengeID)) {
            whitelistApplication(_listingHash);
             
            listings[_listingHash].unstakedDeposit += reward;

            emit _ChallengeFailed(_listingHash, challengeID, challenges[challengeID].rewardPool, challenges[challengeID].totalTokens);
        }
         
        else {
            resetListing(_listingHash);
             
            require(token.transfer(challenges[challengeID].challenger, reward));

            emit _ChallengeSucceeded(_listingHash, challengeID, challenges[challengeID].rewardPool, challenges[challengeID].totalTokens);
        }
    }

     
    function whitelistApplication(bytes32 _listingHash) private {
        if (!listings[_listingHash].whitelisted) { emit _ApplicationWhitelisted(_listingHash); }
        listings[_listingHash].whitelisted = true;
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

         
        if (unstakedDeposit > 0){
            require(token.transfer(owner, unstakedDeposit));
        }
    }
}


 



  









 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}








 
contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

   
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

   
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

   
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }

}


contract QuantstampBountyData is Whitelist {

  using SafeMath for uint256;
  using LinkedListLib for LinkedListLib.LinkedList;

   
  uint256 constant internal NULL = 0;
  uint256 constant internal HEAD = 0;
  bool constant internal PREV = false;
  bool constant internal NEXT = true;


  uint256 constant internal NUMBER_OF_PHASES = 3;

  struct Bounty {
    address submitter;
    string contractAddress;
    uint256 size;  
    uint256 minVotes;  
    uint256 duration;  
    uint256 judgeDeposit;  
    uint256 hunterDeposit;  
    uint256 initiationTimestamp;  
    bool remainingFeesWithdrawn;  
    uint256 numApprovedBugs;
  }

   
  struct Bug {
    address hunter;  
    uint256 bountyId;  
    string bugDescription;  
    uint256 numTokens;  
    uint256 pollId;  
  }

   
  struct BugCommit {
    address hunter;   
    uint256 bountyId;   
    bytes32 bugDescriptionHash;   
    uint256 commitTimestamp;   
    uint256 revealStartTimestamp;   
    uint256 revealEndTimestamp;   
    uint256 numTokens;   
  }

  mapping (uint256 => Bounty) public bounties;

   
  mapping (uint256 => uint256) public pollIdToBugId;

   
  uint256 private bountyCounter;

   
  uint256 private bugCounter;

   
   
  StandardToken public token;

   
  RestrictedPLCRVoting public voting;

   
  Parameterizer public parameterizer;

   
  mapping (address => LinkedListLib.LinkedList) private hunterReportedBugs;
  mapping (address => uint256) public hunterReportedBugsCount;

   
  constructor (address tokenAddress, address votingAddress, address parameterizerAddress) public {
    require(tokenAddress != address(0));
    require(votingAddress != address(0));
    require(parameterizerAddress != address(0));
    token = StandardToken(tokenAddress);
    voting = RestrictedPLCRVoting(votingAddress);
    parameterizer = Parameterizer(parameterizerAddress);
  }

   
   
   
  mapping(uint256 => LinkedListLib.LinkedList) private bugLists;

   
  mapping(uint256 => BugCommit) public bugCommitMap;

   
  mapping(uint256 => Bug) public bugs;

  function addBugCommitment(address hunter,
                            uint256 bountyId,
                            bytes32 bugDescriptionHash,
                            uint256 hunterDeposit) public onlyWhitelisted returns (uint256) {
    bugCounter = bugCounter.add(1);
    bugCommitMap[bugCounter] = BugCommit({
      hunter: hunter,
      bountyId: bountyId,
      bugDescriptionHash: bugDescriptionHash,
      commitTimestamp: block.timestamp,
      revealStartTimestamp: getBountyRevealPhaseStartTimestamp(bountyId),
      revealEndTimestamp: getBountyRevealPhaseEndTimestamp(bountyId),
      numTokens: hunterDeposit
    });
    return bugCounter;
  }

  function addBug(uint256 bugId, string bugDescription, uint256 pollId) public onlyWhitelisted returns (bool) {
     
    bugs[bugId] = Bug({
      hunter: bugCommitMap[bugId].hunter,
      bountyId: bugCommitMap[bugId].bountyId,
      bugDescription: bugDescription,
      numTokens: bugCommitMap[bugId].numTokens,
      pollId: pollId
    });
     
    bugLists[bugCommitMap[bugId].bountyId].push(bugId, PREV);
    pollIdToBugId[pollId] = bugId;
    return true;
  }

  function addBounty (address submitter,
                      string contractAddress,
                      uint256 size,
                      uint256 minVotes,
                      uint256 duration,
                      uint256 judgeDeposit,
                      uint256 hunterDeposit) public onlyWhitelisted returns(uint256) {
    bounties[++bountyCounter] = Bounty(submitter,
                                        contractAddress,
                                        size,
                                        minVotes,
                                        duration,
                                        judgeDeposit,
                                        hunterDeposit,
                                        block.timestamp,
                                        false,
                                        0);
    return bountyCounter;
  }

  function removeBugCommitment(uint256 bugId) public onlyWhitelisted returns (bool) {
    delete bugCommitMap[bugId];
    return true;
  }

   
  function updateNumApprovedBugs(uint256 pollId, bool wasPassing, bool isPassing, bool wasEnoughVotes) public {
    require(msg.sender == address(voting));
    uint256 bountyId = getBugBountyId(getBugIdFromPollId(pollId));

    if (wasEnoughVotes) {
      if (!wasPassing && isPassing) {
        bounties[bountyId].numApprovedBugs = bounties[bountyId].numApprovedBugs.add(1);
      } else if (wasPassing && !isPassing) {
        bounties[bountyId].numApprovedBugs = bounties[bountyId].numApprovedBugs.sub(1);
      }
    } else if (voting.isEnoughVotes(pollId) && isPassing) {
      bounties[bountyId].numApprovedBugs = bounties[bountyId].numApprovedBugs.add(1);
    }
  }

   
  function getNumApprovedBugs(uint256 bountyId) public view returns (uint256) {
    return bounties[bountyId].numApprovedBugs;
  }

   
  function setBountyRemainingFeesWithdrawn (uint256 bountyId) public onlyWhitelisted {
    bounties[bountyId].remainingFeesWithdrawn = true;
  }

  function addBugToHunter (address hunter, uint256 bugId) public onlyWhitelisted {
    hunterReportedBugs[hunter].push(bugId, PREV);
    hunterReportedBugsCount[hunter] = hunterReportedBugsCount[hunter].add(1);
  }

  function removeBugFromHunter (address hunter, uint256 bugId) public onlyWhitelisted returns (bool) {
    if (hunterReportedBugs[hunter].remove(bugId) != 0) {
      hunterReportedBugsCount[hunter] = hunterReportedBugsCount[hunter].sub(1);
      bugs[bugId].hunter = 0x0;
      return true;
    }
    return false;
  }

  function getListHeadConstant () public pure returns(uint256 head) {
    return HEAD;
  }

  function getBountySubmitter (uint256 bountyId) public view returns(address) {
    return bounties[bountyId].submitter;
  }

  function getBountyContractAddress (uint256 bountyId) public view returns(string) {
    return bounties[bountyId].contractAddress;
  }

  function getBountySize (uint256 bountyId) public view returns(uint256) {
    return bounties[bountyId].size;
  }

  function getBountyMinVotes (uint256 bountyId) public view returns(uint256) {
    return bounties[bountyId].minVotes;
  }

  function getBountyDuration (uint256 bountyId) public view returns(uint256) {
    return bounties[bountyId].duration;
  }

  function getBountyJudgeDeposit (uint256 bountyId) public view returns(uint256) {
    return bounties[bountyId].judgeDeposit;
  }

  function getBountyHunterDeposit (uint256 bountyId) public view returns(uint256) {
    return bounties[bountyId].hunterDeposit;
  }

  function getBountyInitiationTimestamp (uint256 bountyId) public view returns(uint256) {
    return bounties[bountyId].initiationTimestamp;
  }

  function getBountyCommitPhaseEndTimestamp (uint256 bountyId) public view returns(uint256) {
    return bounties[bountyId].initiationTimestamp.add(getBountyDuration(bountyId).div(NUMBER_OF_PHASES));
  }

  function getBountyRevealPhaseStartTimestamp (uint256 bountyId) public view returns(uint256) {
    return getBountyCommitPhaseEndTimestamp(bountyId).add(1);
  }

  function getBountyRevealPhaseEndTimestamp (uint256 bountyId) public view returns(uint256) {
    return getBountyCommitPhaseEndTimestamp(bountyId).add(getBountyDuration(bountyId).div(NUMBER_OF_PHASES));
  }

  function getBountyJudgePhaseStartTimestamp (uint256 bountyId) public view returns(uint256) {
    return getBountyRevealPhaseEndTimestamp(bountyId).add(1);
  }

  function getBountyJudgePhaseEndTimestamp (uint256 bountyId) public view returns(uint256) {
    return bounties[bountyId].initiationTimestamp.add(getBountyDuration(bountyId));
  }

  function getBountyJudgeCommitPhaseEndTimestamp (uint256 bountyId) public view returns(uint256) {
    uint256 judgePhaseDuration = getBountyDuration(bountyId).div(NUMBER_OF_PHASES);
    return getBountyJudgePhaseStartTimestamp(bountyId).add(judgePhaseDuration.div(2));
  }

  function getBountyJudgeRevealDuration (uint256 bountyId) public view returns(uint256) {
    return getBountyJudgePhaseEndTimestamp(bountyId).sub(getBountyJudgeCommitPhaseEndTimestamp(bountyId));
  }

  function isCommitPeriod (uint256 bountyId) public view returns(bool) {
    return block.timestamp >= bounties[bountyId].initiationTimestamp && block.timestamp <= getBountyCommitPhaseEndTimestamp(bountyId);
  }

  function isRevealPeriod (uint256 bountyId) public view returns(bool) {
    return block.timestamp >= getBountyRevealPhaseStartTimestamp(bountyId) && block.timestamp <= getBountyRevealPhaseEndTimestamp(bountyId);
  }

  function isJudgingPeriod (uint256 bountyId) public view returns(bool) {
    return block.timestamp >= getBountyJudgePhaseStartTimestamp(bountyId) && block.timestamp <= getBountyJudgePhaseEndTimestamp(bountyId);
  }

  function getBountyRemainingFeesWithdrawn (uint256 bountyId) public view returns(bool) {
    return bounties[bountyId].remainingFeesWithdrawn;
  }

  function getBugCommitCommitter(uint256 bugCommitId) public view returns (address) {
    return bugCommitMap[bugCommitId].hunter;
  }

  function getBugCommitBountyId(uint256 bugCommitId) public view returns (uint256) {
    return bugCommitMap[bugCommitId].bountyId;
  }

  function getBugCommitBugDescriptionHash(uint256 bugCommitId) public view returns (bytes32) {
    return bugCommitMap[bugCommitId].bugDescriptionHash;
  }

  function getBugCommitCommitTimestamp(uint256 bugCommitId) public view returns (uint256) {
    return bugCommitMap[bugCommitId].commitTimestamp;
  }

  function getBugCommitRevealStartTimestamp(uint256 bugCommitId) public view returns (uint256) {
    return bugCommitMap[bugCommitId].revealStartTimestamp;
  }

  function getBugCommitRevealEndTimestamp(uint256 bugCommitId) public view returns (uint256) {
    return bugCommitMap[bugCommitId].revealEndTimestamp;
  }

  function getBugCommitNumTokens(uint256 bugCommitId) public view returns (uint256) {
    return bugCommitMap[bugCommitId].numTokens;
  }

  function bugRevealPeriodActive(uint256 bugCommitId) public view returns (bool) {
    return bugCommitMap[bugCommitId].revealStartTimestamp <= block.timestamp && block.timestamp <= bugCommitMap[bugCommitId].revealEndTimestamp;
  }

  function bugRevealPeriodExpired(uint256 bugCommitId) public view returns (bool) {
    return block.timestamp > bugCommitMap[bugCommitId].revealEndTimestamp;
  }

  function bugRevealDelayPeriodActive(uint256 bugCommitId) public view returns (bool) {
    return block.timestamp < bugCommitMap[bugCommitId].revealStartTimestamp;
  }

  function bountyActive(uint256 bountyId) public view returns (bool) {
    return block.timestamp <= getBountyInitiationTimestamp(bountyId).add(getBountyDuration(bountyId));
  }

  function getHunterReportedBugsCount (address hunter) public view returns (uint256) {
    return hunterReportedBugsCount[hunter];
  }

   
  function getBugBountyId(uint256 bugId) public view returns (uint256) {
    return bugs[bugId].bountyId;
  }

  function getBugHunter(uint256 bugId) public view returns (address) {
    return bugs[bugId].hunter;
  }

  function getBugDescription(uint256 bugId) public view returns (string) {
    return bugs[bugId].bugDescription;
  }

  function getBugNumTokens(uint256 bugId) public view returns (uint256) {
    return bugs[bugId].numTokens;
  }

  function getBugPollId(uint256 bugId) public view returns (uint256) {
    return bugs[bugId].pollId;
  }

  function getFirstRevealedBug(uint256 bountyId) public view returns (bool, uint256, string) {
    return getNextRevealedBug(bountyId, HEAD);
  }

  function getBugIdFromPollId(uint256 pollId) public view returns (uint256) {
    return pollIdToBugId[pollId];
  }

   
  function getNextRevealedBug(uint256 bountyId, uint256 previousBugId) public view returns (bool, uint256, string) {
    if (!bugLists[bountyId].listExists()) {
      return (false, 0, "");
    }
    uint256 bugId;
    bool exists;
    (exists, bugId) = bugLists[bountyId].getAdjacent(previousBugId, NEXT);
    if (!exists || bugId == 0) {
      return (false, 0, "");
    }
    string memory bugDescription = bugs[bugId].bugDescription;
    return (true, bugId, bugDescription);
  }

   
  function getNextBugFromHunter(address hunter, uint256 previousBugId) public view returns (bool, uint256) {
    if (!hunterReportedBugs[hunter].listExists()) {
      return (false, 0);
    }
    uint256 bugId;
    bool exists;
    (exists, bugId) = hunterReportedBugs[hunter].getAdjacent(previousBugId, NEXT);
    if (!exists || bugId == 0) {
      return (false, 0);
    }
    return (true, bugId);
  }

   
  function canClaimJudgeAward(address judge, uint256 bugId) public view returns (bool) {
     
     
    uint256 pollId = getBugPollId(bugId);
    bool pollHasConcluded = voting.pollExists(pollId) && voting.pollEnded(pollId);
     
     
    bool votedWithMajority = pollHasConcluded && voting.isEnoughVotes(pollId) &&
      (voting.isPassed(pollId) && voting.hasVotedAffirmatively(judge, pollId) ||
      !voting.isPassed(pollId) && !voting.hasVotedAffirmatively(judge, pollId));
     
    bool alreadyClaimed = voting.hasVoterClaimedReward(judge, pollId);
     
    bool bountyStillActive = bountyActive(getBugBountyId(bugId));
    return votedWithMajority && !alreadyClaimed && !bountyStillActive;
  }
}




 
contract RestrictedPLCRVoting is PLCRVoting, Whitelist {

  using SafeMath for uint256;
  using LinkedListLib for LinkedListLib.LinkedList;

   
  uint256 constant internal NULL = 0;
  uint256 constant internal HEAD = 0;
  bool constant internal PREV = false;
  bool constant internal NEXT = true;

   
  Registry public judgeRegistry;

  QuantstampBountyData public bountyData;

   
  mapping(uint256 => bool) isRestrictedPoll;

   
  mapping(uint256 => uint256) minimumVotes;

   
  mapping(uint256 => uint256) judgeDeposit;

   
  mapping(address => mapping(uint256 => bool)) private voterHasClaimedReward;

   
   
  mapping(address => mapping(uint256 => bool)) private votedAffirmatively;

   
  mapping (address => LinkedListLib.LinkedList) private voterPolls;
  mapping (address => uint256) public voterPollsCount;

  event LogPollRestricted(uint256 pollId);

   
  function initialize(address _token, address _registry, address _bountyData) public {
    require(_token != 0 && address(token) == 0);
    require(_registry != 0 && address(judgeRegistry) == 0);
    require(_bountyData != 0 && address(bountyData) == 0);
    bountyData = QuantstampBountyData(_bountyData);
    token = EIP20Interface(_token);
    judgeRegistry = Registry(_registry);
    pollNonce = INITIAL_POLL_NONCE;
  }

   
  function isJudge(address addr) public view returns(bool) {
    return judgeRegistry.isWhitelisted(bytes32(uint256(addr) << 96));
  }

   
  function restrictPoll(uint256 _pollId, uint256 _minimumVotes, uint256 _judgeDepositAmount) public onlyWhitelisted {
    isRestrictedPoll[_pollId] = true;
    minimumVotes[_pollId] = _minimumVotes;
    judgeDeposit[_pollId] = _judgeDepositAmount;
    emit LogPollRestricted(_pollId);
  }

   
  function setVoterClaimedReward(address _voter, uint256 _pollID) public onlyWhitelisted {
    voterHasClaimedReward[_voter][_pollID] = true;
  }

   
  function isEnoughVotes(uint256 _pollId) public view returns (bool) {
    return pollMap[_pollId].votesFor.add(pollMap[_pollId].votesAgainst) >= minimumVotes[_pollId].mul(judgeDeposit[_pollId]);
  }

   

   
  function init(address _token) public {
    require(false);
  }

   
  function commitVote(uint256 _pollID, bytes32 _secretHash, uint256 _numTokens, uint256 _prevPollID) public {
    if (isRestrictedPoll[_pollID]) {
      require(isJudge(msg.sender));
       
       
      require(_numTokens == judgeDeposit[_pollID]);
      require(bountyData.isJudgingPeriod(bountyData.getBugBountyId(bountyData.getBugIdFromPollId(_pollID))));
    }
    super.commitVote(_pollID, _secretHash, _numTokens, _prevPollID);
  }

   
  function revealVote(uint256 _pollID, uint256 _voteOption, uint256 _salt) public {
    address voter = msg.sender;
     
    if (_voteOption == 1) {
      votedAffirmatively[voter][_pollID] = true;
    }
     
    require(!voterPolls[voter].nodeExists(_pollID));
    bool wasPassing = isPassing(_pollID);
    bool wasEnoughVotes = isEnoughVotes(_pollID);
    voterPolls[voter].push(_pollID, PREV);
    voterPollsCount[voter] = voterPollsCount[voter].add(1);
    super.revealVote(_pollID, _voteOption, _salt);
    bool voteIsPassing = isPassing(_pollID);
    bountyData.updateNumApprovedBugs(_pollID, wasPassing, voteIsPassing, wasEnoughVotes);
  }

  function removePollFromVoter (address _voter, uint256 _pollID) public onlyWhitelisted returns (bool) {
    if (voterPolls[_voter].remove(_pollID) != 0) {
      voterPollsCount[_voter] = voterPollsCount[_voter] - 1;
      return true;
    }
    return false;
  }

   
  function isPassing(uint _pollID) public view returns (bool) {
    Poll memory poll = pollMap[_pollID];
    return (100 * poll.votesFor) > (poll.voteQuorum * (poll.votesFor + poll.votesAgainst));
  }

   
  function getTotalNumberOfTokensForWinningOption(uint _pollID) constant public returns (uint256) {
    if (isRestrictedPoll[_pollID] && !isEnoughVotes(_pollID)) {
      return 0;
    }
    return super.getTotalNumberOfTokensForWinningOption(_pollID);
  }

   
  function getNumPassingTokens(address _voter, uint _pollID) public constant returns (uint256) {
    if (isRestrictedPoll[_pollID] && !isEnoughVotes(_pollID)) {
      return 0;
    }
    return super.getNumPassingTokens(_voter, _pollID);
  }

   
  function isPassed(uint _pollID) constant public returns (bool) {
    if (isRestrictedPoll[_pollID] && !isEnoughVotes(_pollID)) {
      return false;
    }
    return super.isPassed(_pollID);
  }

   
  function hasVoterClaimedReward(address _voter, uint256 _pollID) public view returns (bool) {
    return voterHasClaimedReward[_voter][_pollID];
  }

   
  function hasVotedAffirmatively(address _voter, uint256 _pollID) public view returns (bool) {
    return votedAffirmatively[_voter][_pollID];
  }

   
  function getVoterPollsCount (address _voter) public view returns (uint256) {
    return voterPollsCount[_voter];
  }

  function getListHeadConstant () public pure returns(uint256 head) {
    return HEAD;
  }

   
  function getNextPollFromVoter(address _voter, uint256 _prevPollID) public view returns (bool, uint256) {
    if (!voterPolls[_voter].listExists()) {
      return (false, 0);
    }
    uint256 pollID;
    bool exists;
    (exists, pollID) = voterPolls[_voter].getAdjacent(_prevPollID, NEXT);
    if (!exists || pollID == 0) {
      return (false, 0);
    }
    return (true, pollID);
  }
}