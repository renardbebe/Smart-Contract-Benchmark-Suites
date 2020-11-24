 

pragma solidity 0.4.24;

 

contract EventRegistry {
    address[] verityEvents;
    mapping(address => bool) verityEventsMap;

    mapping(address => address[]) userEvents;

    event NewVerityEvent(address eventAddress);

    function registerEvent() public {
        verityEvents.push(msg.sender);
        verityEventsMap[msg.sender] = true;
        emit NewVerityEvent(msg.sender);
    }

    function getUserEvents() public view returns(address[]) {
        return userEvents[msg.sender];
    }

    function addEventToUser(address _user) external {
        require(verityEventsMap[msg.sender]);

        userEvents[_user].push(msg.sender);
    }

    function getEventsLength() public view returns(uint) {
        return verityEvents.length;
    }

    function getEventsByIds(uint[] _ids) public view returns(uint[], address[]) {
        address[] memory _events = new address[](_ids.length);

        for(uint i = 0; i < _ids.length; ++i) {
            _events[i] = verityEvents[_ids[i]];
        }

        return (_ids, _events);
    }

    function getUserEventsLength(address _user)
        public
        view
        returns(uint)
    {
        return userEvents[_user].length;
    }

    function getUserEventsByIds(address _user, uint[] _ids)
        public
        view
        returns(uint[], address[])
    {
        address[] memory _events = new address[](_ids.length);

        for(uint i = 0; i < _ids.length; ++i) {
            _events[i] = userEvents[_user][_ids[i]];
        }

        return (_ids, _events);
    }
}

 

 
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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract VerityToken is StandardToken {
  string public name = "VerityToken";
  string public symbol = "VTY";
  uint8 public decimals = 18;
  uint public INITIAL_SUPPLY = 500000000 * 10 ** uint(decimals);

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}

 

contract VerityEvent {
     
    address public owner;

     
    address public tokenAddress;

     
    address public eventRegistryAddress;

     
    address[] eventResolvers;

     
     
     
    enum ValidationState {
        WaitingForRewards,
        Validating,
        Finished
    }
    ValidationState validationState = ValidationState.WaitingForRewards;

    struct RewardsValidation {
        address currentMasterNode;
        string rewardsHash;
        uint approvalCount;
        uint rejectionCount;
        string[] altHashes;
        mapping(address => uint) votersRound;
        mapping(string => address[]) altHashVotes;
        mapping(string => bool) rejectedHashes;
    }
    RewardsValidation rewardsValidation;

     
    uint public rewardsValidationRound;

     
     
    mapping(address => bool) participants;
    address[] participantsIndex;

    enum RewardType {
        Ether,
        Token
    }
    RewardType rewardType;

     
    mapping(address => mapping(uint => uint)) rewards;
    address[] rewardsIndex;

     
    uint applicationStartTime;

     
    uint applicationEndTime;

     
    uint eventStartTime;

     
    uint eventEndTime;

     
    string ipfsEventHash;

     
     
    uint leftoversRecoverableAfter;

     
    uint public stakingAmount;

    struct Dispute {
        uint amount;
        uint timeout;
        uint round;
        uint expiresAt;
        uint multiplier;
        mapping(address => bool) disputers;
        address currentDisputer;
    }
    Dispute dispute;

    uint defaultDisputeTimeExtension = 1800;  

    string public eventName;

     
    string public dataFeedHash;

    bytes32[] results;

    enum RewardsDistribution {
        Linear,  
        Exponential  
    }

    struct ConsensusRules {
        uint minTotalVotes;
        uint minConsensusVotes;
        uint minConsensusRatio;
        uint minParticipantRatio;
        uint maxParticipants;
        RewardsDistribution rewardsDistribution;
    }
    ConsensusRules consensusRules;

     
     
     
     
     
     
     
     
     
     
     
    enum EventStates {
        Waiting,
        Application,
        Running,
        DisputeTimeout,
        Reward,
        Failed
    }
    EventStates eventState = EventStates.Waiting;

    event StateTransition(EventStates newState);
    event JoinEvent(address wallet);
    event ClaimReward(address recipient);
    event Error(string description);
    event EventFailed(string description);
    event ValidationStarted(uint validationRound);
    event ValidationRestart(uint validationRound);
    event DisputeTriggered(address byAddress);
    event ClaimStake(address recipient);

    constructor(
        string _eventName,
        uint _applicationStartTime,
        uint _applicationEndTime,
        uint _eventStartTime,
        uint _eventRunTime,  
        address _tokenAddress,
        address _registry,
        address[] _eventResolvers,
        uint _leftoversRecoverableAfter,  
        uint[6] _consensusRules,  
        uint _stakingAmount,
        uint[3] _disputeRules,  
        string _ipfsEventHash
    )
        public
        payable
    {
        require(_applicationStartTime < _applicationEndTime);
        require(_eventStartTime > _applicationEndTime, "Event can't start before applications close.");

        applicationStartTime = _applicationStartTime;
        applicationEndTime = _applicationEndTime;
        tokenAddress = _tokenAddress;

        eventName = _eventName;
        eventStartTime = _eventStartTime;
        eventEndTime = _eventStartTime + _eventRunTime;

        eventResolvers = _eventResolvers;

        owner = msg.sender;
        leftoversRecoverableAfter = _leftoversRecoverableAfter;

        rewardsValidationRound = 1;
        rewardsValidation.currentMasterNode = eventResolvers[0];

        stakingAmount = _stakingAmount;

        ipfsEventHash = _ipfsEventHash;

        setConsensusRules(_consensusRules);
        setDisputeData(_disputeRules);

        eventRegistryAddress = _registry;

        EventRegistry(eventRegistryAddress).registerEvent();
    }

     
     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
    modifier onlyCurrentMaster() {
        require(
            msg.sender == rewardsValidation.currentMasterNode,
            "Not a designated master node."
        );
        _;
    }

     
     
     
    modifier onlyParticipating() {
        require(
            isParticipating(msg.sender),
            "Not participating."
        );
        _;
    }

     
     
     
     
     
     
     
    modifier onlyState(EventStates _state) {
        require(
            _state == eventState,
            "Not possible in current event state."
        );
        _;
    }

     
     
     
     
     
    modifier timedStateTransition() {
        if (eventState == EventStates.Waiting && now >= applicationStartTime) {
            advanceState();
        }

        if (eventState == EventStates.Application && now >= applicationEndTime) {
            if (participantsIndex.length < consensusRules.minTotalVotes) {
                markAsFailed("Not enough users joined for required minimum votes.");
            } else {
                advanceState();
            }
        }

        if (eventState == EventStates.DisputeTimeout && now >= dispute.expiresAt) {
            advanceState();
        }
        _;
    }

    modifier onlyChangeableState() {
        require(
            uint(eventState) < uint(EventStates.Reward),
            "Event state can't be modified anymore."
        );
        _;
    }

    modifier onlyAfterLefroversCanBeRecovered() {
        require(now >= leftoversRecoverableAfter);
        _;
    }

    modifier canValidateRewards(uint forRound) {
        require(
            isNode(msg.sender) && !isMasterNode(),
            "Not a valid sender address."
        );

        require(
            validationState == ValidationState.Validating,
            "Not validating rewards."
        );

        require(
            forRound == rewardsValidationRound,
            "Validation round mismatch."
        );

        require(
            rewardsValidation.votersRound[msg.sender] < rewardsValidationRound,
            "Already voted for this round."
        );
        _;
    }

     
     
    function() public payable {}

     
     
     
     
     
    function joinEvent()
        public
        timedStateTransition
    {
        if (isParticipating(msg.sender)) {
            emit Error("You are already participating.");
            return;
        }

        if (eventState != EventStates.Application) {
            emit Error("You can only join in the Application state.");
            return;
        }

        if (
            stakingAmount > 0 &&
            VerityToken(tokenAddress).allowance(msg.sender, address(this)) < stakingAmount
        ) {
            emit Error("Not enough tokens staked.");
            return;
        }

        if (stakingAmount > 0) {
            VerityToken(tokenAddress).transferFrom(msg.sender, address(this), stakingAmount);
        }
        participants[msg.sender] = true;
        participantsIndex.push(msg.sender);
        EventRegistry(eventRegistryAddress).addEventToUser(msg.sender);
        emit JoinEvent(msg.sender);
    }

     
     
     
    function isParticipating(address _user) public view returns(bool) {
        return participants[_user];
    }

    function getParticipants() public view returns(address[]) {
        return participantsIndex;
    }

    function getEventTimes() public view returns(uint[5]) {
        return [
            applicationStartTime,
            applicationEndTime,
            eventStartTime,
            eventEndTime,
            leftoversRecoverableAfter
        ];
    }

     
     
     
     
     
     
     
    function setRewards(
        address[] _addresses,
        uint[] _etherRewards,
        uint[] _tokenRewards
    )
        public
        onlyCurrentMaster
        timedStateTransition
        onlyState(EventStates.Running)
    {
        require(
            _addresses.length == _etherRewards.length &&
            _addresses.length == _tokenRewards.length
        );

        require(
            validationState == ValidationState.WaitingForRewards,
            "Not possible in this validation state."
        );

        for (uint i = 0; i < _addresses.length; ++i) {
            rewards[_addresses[i]][uint(RewardType.Ether)] = _etherRewards[i];
            rewards[_addresses[i]][uint(RewardType.Token)] = _tokenRewards[i];
            rewardsIndex.push(_addresses[i]);
        }
    }

     
    function markRewardsSet(string rewardsHash)
        public
        onlyCurrentMaster
        timedStateTransition
        onlyState(EventStates.Running)
    {
        require(
            validationState == ValidationState.WaitingForRewards,
            "Not possible in this validation state."
        );

        rewardsValidation.rewardsHash = rewardsHash;
        rewardsValidation.approvalCount = 1;
        validationState = ValidationState.Validating;
        emit ValidationStarted(rewardsValidationRound);
    }

     
    function approveRewards(uint validationRound)
        public
        onlyState(EventStates.Running)
        canValidateRewards(validationRound)
    {
        ++rewardsValidation.approvalCount;
        rewardsValidation.votersRound[msg.sender] = rewardsValidationRound;
        checkApprovalRatio();
    }

     
    function rejectRewards(uint validationRound, string altHash)
        public
        onlyState(EventStates.Running)
        canValidateRewards(validationRound)
    {
        ++rewardsValidation.rejectionCount;
        rewardsValidation.votersRound[msg.sender] = rewardsValidationRound;

        if (!rewardsValidation.rejectedHashes[altHash]) {
            rewardsValidation.altHashes.push(altHash);
            rewardsValidation.altHashVotes[altHash].push(msg.sender);
        }

        checkRejectionRatio();
    }

     
    function triggerDispute()
        public
        timedStateTransition
        onlyParticipating
        onlyState(EventStates.DisputeTimeout)
    {
        require(
            VerityToken(tokenAddress).allowance(msg.sender, address(this)) >=
            dispute.amount * dispute.multiplier**dispute.round,
            "Not enough tokens staked for dispute."
        );

        require(
            dispute.disputers[msg.sender] == false,
            "Already triggered a dispute."
        );

         
        dispute.amount = dispute.amount * dispute.multiplier**dispute.round;
        ++dispute.round;
        dispute.disputers[msg.sender] = true;
        dispute.currentDisputer = msg.sender;

         
        VerityToken(tokenAddress).transferFrom(msg.sender, address(this), dispute.amount);

         
        deleteValidationData();
        deleteRewards();
        eventState = EventStates.Application;
        applicationEndTime = eventStartTime = now + defaultDisputeTimeExtension;
        eventEndTime = eventStartTime + defaultDisputeTimeExtension;

         
         
        consensusRules.minConsensusRatio += (100 - consensusRules.minConsensusRatio) * 100 / 1000;
         
        uint votesIncrease = consensusRules.minTotalVotes * 100 / 1000;
        consensusRules.minTotalVotes += votesIncrease;
        consensusRules.minConsensusVotes += votesIncrease * consensusRules.minConsensusRatio / 100;

        emit DisputeTriggered(msg.sender);
    }

     
    function checkApprovalRatio() private {
        if (approvalRatio() >= consensusRules.minConsensusRatio) {
            validationState = ValidationState.Finished;
            dispute.expiresAt = now + dispute.timeout;
            advanceState();
        }
    }

     
    function checkRejectionRatio() private {
        if (rejectionRatio() >= (100 - consensusRules.minConsensusRatio)) {
            rejectCurrentValidation();
        }
    }

     
    function rejectCurrentValidation() private {
        rewardsValidation.rejectedHashes[rewardsValidation.rewardsHash] = true;

         
        if (
            rewardsValidation.approvalCount + rewardsValidationRound - 1 >
            rewardsValidation.rejectionCount - rewardsValidation.altHashes.length + 1
        ) {
            markAsFailed("Consensus can't be reached");
        } else {
            restartValidation();
        }
    }

    function restartValidation() private {
        ++rewardsValidationRound;
        rewardsValidation.currentMasterNode = rewardsValidation.altHashVotes[rewardsValidation.altHashes[0]][0];

        deleteValidationData();
        deleteRewards();

        emit ValidationRestart(rewardsValidationRound);
    }

     
    function deleteRewards() private {
        for (uint j = 0; j < rewardsIndex.length; ++j) {
            rewards[rewardsIndex[j]][uint(RewardType.Ether)] = 0;
            rewards[rewardsIndex[j]][uint(RewardType.Token)] = 0;
        }
        delete rewardsIndex;
    }

     
    function deleteValidationData() private {
        rewardsValidation.approvalCount = 0;
        rewardsValidation.rejectionCount = 0;
        for (uint i = 0; i < rewardsValidation.altHashes.length; ++i) {
            delete rewardsValidation.altHashVotes[rewardsValidation.altHashes[i]];
        }
        delete rewardsValidation.altHashes;
        validationState = ValidationState.WaitingForRewards;
    }

     
    function approvalRatio() private view returns(uint) {
        return rewardsValidation.approvalCount * 100 / eventResolvers.length;
    }

     
    function rejectionRatio() private view returns(uint) {
        return rewardsValidation.rejectionCount * 100 / eventResolvers.length;
    }

     
    function getEventResolvers() public view returns(address[]) {
        return eventResolvers;
    }

     
    function isMasterNode() public view returns(bool) {
        return rewardsValidation.currentMasterNode == msg.sender;
    }

    function isNode(address node) private view returns(bool) {
        for(uint i = 0; i < eventResolvers.length; ++i) {
            if(eventResolvers[i] == node) {
                return true;
            }
        }
        return false;
    }

     
     
     
    function getReward()
        public
        view
        returns(uint[2])
    {
        return [
            rewards[msg.sender][uint(RewardType.Ether)],
            rewards[msg.sender][uint(RewardType.Token)]
        ];
    }

     
    function getRewardsIndex() public view returns(address[]) {
        return rewardsIndex;
    }

     
     
    function getRewards(address[] _addresses)
        public
        view
        returns(uint[], uint[])
    {
        uint[] memory ethRewards = new uint[](_addresses.length);
        uint[] memory tokenRewards = new uint[](_addresses.length);

        for(uint i = 0; i < _addresses.length; ++i) {
            ethRewards[i] = rewards[_addresses[i]][uint(RewardType.Ether)];
            tokenRewards[i] = rewards[_addresses[i]][uint(RewardType.Token)];
        }

        return (ethRewards, tokenRewards);
    }

     
     
     
     
    function claimReward()
        public
        onlyParticipating
        timedStateTransition
        onlyState(EventStates.Reward)
    {
        uint etherReward = rewards[msg.sender][uint(RewardType.Ether)];
        uint tokenReward = rewards[msg.sender][uint(RewardType.Token)];

        if (etherReward == 0 && tokenReward == 0) {
            emit Error("You do not have any rewards to claim.");
            return;
        }

        if (
            address(this).balance < rewards[msg.sender][uint(RewardType.Ether)] ||
            VerityToken(tokenAddress).balanceOf(address(this)) < rewards[msg.sender][uint(RewardType.Token)]
        ) {
            emit Error("Critical error: not enough balance to pay out reward. Contact Verity.");
            return;
        }

        rewards[msg.sender][uint(RewardType.Ether)] = 0;
        rewards[msg.sender][uint(RewardType.Token)] = 0;

        msg.sender.transfer(etherReward);
        if (tokenReward > 0) {
            VerityToken(tokenAddress).transfer(msg.sender, tokenReward);
        }

        emit ClaimReward(msg.sender);
    }

    function claimFailed()
        public
        onlyParticipating
        timedStateTransition
        onlyState(EventStates.Failed)
    {
        require(
            stakingAmount > 0,
            "No stake to claim"
        );

        VerityToken(tokenAddress).transfer(msg.sender, stakingAmount);
        participants[msg.sender] = false;
        emit ClaimStake(msg.sender);
    }

    function setDataFeedHash(string _hash) public onlyOwner {
        dataFeedHash = _hash;
    }

    function setResults(bytes32[] _results)
        public
        onlyCurrentMaster
        timedStateTransition
        onlyState(EventStates.Running)
    {
        results = _results;
    }

    function getResults() public view returns(bytes32[]) {
        return results;
    }

    function getState() public view returns(uint) {
        return uint(eventState);
    }

    function getBalance() public view returns(uint[2]) {
        return [
            address(this).balance,
            VerityToken(tokenAddress).balanceOf(address(this))
        ];
    }

     
     
    function getConsensusRules() public view returns(uint[6]) {
        return [
            consensusRules.minTotalVotes,
            consensusRules.minConsensusVotes,
            consensusRules.minConsensusRatio,
            consensusRules.minParticipantRatio,
            consensusRules.maxParticipants,
            uint(consensusRules.rewardsDistribution)
        ];
    }

     
     
    function getDisputeData() public view returns(uint[4], address) {
        return ([
            dispute.amount,
            dispute.timeout,
            dispute.multiplier,
            dispute.round
        ], dispute.currentDisputer);
    }

    function recoverLeftovers()
        public
        onlyOwner
        onlyAfterLefroversCanBeRecovered
    {
        owner.transfer(address(this).balance);
        uint tokenBalance = VerityToken(tokenAddress).balanceOf(address(this));
        VerityToken(tokenAddress).transfer(owner, tokenBalance);
    }

     
    function advanceState() private onlyChangeableState {
        eventState = EventStates(uint(eventState) + 1);
        emit StateTransition(eventState);
    }

     
    function setConsensusRules(uint[6] rules) private {
        consensusRules.minTotalVotes = rules[0];
        consensusRules.minConsensusVotes = rules[1];
        consensusRules.minConsensusRatio = rules[2];
        consensusRules.minParticipantRatio = rules[3];
        consensusRules.maxParticipants = rules[4];
        consensusRules.rewardsDistribution = RewardsDistribution(rules[5]);
    }

    function markAsFailed(string description) private onlyChangeableState {
        eventState = EventStates.Failed;
        emit EventFailed(description);
    }

    function setDisputeData(uint[3] rules) private {
        uint _multiplier = rules[2];
        if (_multiplier <= 1) {
            _multiplier = 1;
        }

        dispute.amount = rules[0];
        dispute.timeout = rules[1];
        dispute.multiplier = _multiplier;
        dispute.round = 0;
    }
}