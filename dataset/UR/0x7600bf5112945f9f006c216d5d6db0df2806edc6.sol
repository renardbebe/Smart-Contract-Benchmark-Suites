 

 
pragma solidity ^0.4.24;

library ExtendedMath {
    function limitLessThan(uint a, uint b) internal pure returns(uint c) {
        if (a > b) return b;
        return a;
    }
}

library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0);
        return a % b;
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

contract ERC20Basic {
    function totalSupply() public view returns(uint256);

    function balanceOf(address _who) public view returns(uint256);

    function transfer(address _to, uint256 _value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns(uint256);

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);

    function approve(address _spender, uint256 _value) public returns(bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BasicToken is ERC20Basic {
    using SafeMath
    for uint256;

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;

     
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns(bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
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
    returns(uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns(bool) {
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
    returns(bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

interface IcaelumVoting {
    function getTokenProposalDetails() external view returns(address, uint, uint, uint);
    function getExpiry() external view returns (uint);
    function getContractType () external view returns (uint);
}

contract abstractCaelum {
    function isMasternodeOwner(address _candidate) public view returns(bool);
    function addToWhitelist(address _ad, uint _amount, uint daysAllowed) internal;
    function addMasternode(address _candidate) internal returns(uint);
    function deleteMasternode(uint entityAddress) internal returns(bool success);
    function getLastPerUser(address _candidate) public view returns (uint);
    function getMiningReward() public view returns(uint);
}

contract NewTokenProposal is IcaelumVoting {

    enum VOTE_TYPE {TOKEN, TEAM}

    VOTE_TYPE public contractType = VOTE_TYPE.TOKEN;
    address contractAddress;
    uint requiredAmount;
    uint validUntil;
    uint votingDurationInDays;

     
    constructor(address _contract, uint _amount, uint _valid, uint _voteDuration) public {
        require(_voteDuration >= 14 && _voteDuration <= 50, "Proposed voting duration does not meet requirements");

        contractAddress = _contract;
        requiredAmount = _amount;
        validUntil = _valid;
        votingDurationInDays = _voteDuration;
    }

     
    function getTokenProposalDetails() public view returns(address, uint, uint, uint) {
        return (contractAddress, requiredAmount, validUntil, uint(contractType));
    }

     
    function getExpiry() external view returns (uint) {
        return votingDurationInDays;
    }

     
    function getContractType () external view returns (uint){
        return uint(contractType);
    }
}

contract NewMemberProposal is IcaelumVoting {

    enum VOTE_TYPE {TOKEN, TEAM}
    VOTE_TYPE public contractType = VOTE_TYPE.TEAM;

    address memberAddress;
    uint totalMasternodes;
    uint votingDurationInDays;

     
    constructor(address _contract, uint _total, uint _voteDuration) public {
        require(_voteDuration >= 14 && _voteDuration <= 50, "Proposed voting duration does not meet requirements");
        memberAddress = _contract;
        totalMasternodes = _total;
        votingDurationInDays = _voteDuration;
    }

     
    function getTokenProposalDetails() public view returns(address, uint, uint, uint) {
        return (memberAddress, totalMasternodes, 0, uint(contractType));
    }

     
    function getExpiry() external view returns (uint) {
        return votingDurationInDays;
    }

     
    function getContractType () external view returns (uint){
        return uint(contractType);
    }
}

contract CaelumVotings is Ownable {
    using SafeMath for uint;

    enum VOTE_TYPE {TOKEN, TEAM}

    struct Proposals {
        address tokenContract;
        uint totalVotes;
        uint proposedOn;
        uint acceptedOn;
        VOTE_TYPE proposalType;
    }

    struct Voters {
        bool isVoter;
        address owner;
        uint[] votedFor;
    }

    uint MAJORITY_PERCENTAGE_NEEDED = 60;
    uint MINIMUM_VOTERS_NEEDED = 10;
    bool public proposalPending;

    mapping(uint => Proposals) public proposalList;
    mapping (address => Voters) public voterMap;
    mapping(uint => address) public voterProposals;
    uint public proposalCounter;
    uint public votersCount;
    uint public votersCountTeam;

     
    function isMasternodeOwner(address _candidate) public view returns(bool);
    function addToWhitelist(address _ad, uint _amount, uint daysAllowed) internal;
    function addMasternode(address _candidate) internal returns(uint);
    function updateMasternodeAsTeamMember(address _member) internal returns (bool);
    function isTeamMember (address _candidate) public view returns (bool);
    
    event NewProposal(uint ProposalID);
    event ProposalAccepted(uint ProposalID);

     
    function pushProposal(address _contract) onlyOwner public returns (uint) {
        if(proposalCounter != 0)
        require (pastProposalTimeRules (), "You need to wait 90 days before submitting a new proposal.");
        require (!proposalPending, "Another proposal is pending.");

        uint _contractType = IcaelumVoting(_contract).getContractType();
        proposalList[proposalCounter] = Proposals(_contract, 0, now, 0, VOTE_TYPE(_contractType));

        emit NewProposal(proposalCounter);
        
        proposalCounter++;
        proposalPending = true;

        return proposalCounter.sub(1);
    }

     
    function handleLastProposal () internal returns (uint) {
        uint _ID = proposalCounter.sub(1);

        proposalList[_ID].acceptedOn = now;
        proposalPending = false;

        address _address;
        uint _required;
        uint _valid;
        uint _type;
        (_address, _required, _valid, _type) = getTokenProposalDetails(_ID);

        if(_type == uint(VOTE_TYPE.TOKEN)) {
            addToWhitelist(_address,_required,_valid);
        }

        if(_type == uint(VOTE_TYPE.TEAM)) {
            if(_required != 0) {
                for (uint i = 0; i < _required; i++) {
                    addMasternode(_address);
                }
            } else {
                addMasternode(_address);
            }
            updateMasternodeAsTeamMember(_address);
        }
        
        emit ProposalAccepted(_ID);
        
        return _ID;
    }

     
    function discardRejectedProposal() onlyOwner public returns (bool) {
        require(proposalPending);
        require (LastProposalCanDiscard());
        proposalPending = false;
        return (true);
    }

     
    function LastProposalCanDiscard () public view returns (bool) {
        
        uint daysBeforeDiscard = IcaelumVoting(proposalList[proposalCounter - 1].tokenContract).getExpiry();
        uint entryDate = proposalList[proposalCounter - 1].proposedOn;
        uint expiryDate = entryDate + (daysBeforeDiscard * 1 days);

        if (now >= expiryDate)
        return true;
    }

     
    function getTokenProposalDetails(uint proposalID) public view returns(address, uint, uint, uint) {
        return IcaelumVoting(proposalList[proposalID].tokenContract).getTokenProposalDetails();
    }

     
    function pastProposalTimeRules() public view returns (bool) {
        uint lastProposal = proposalList[proposalCounter - 1].proposedOn;
        if (now >= lastProposal + 90 days)
        return true;
    }


     
    function becomeVoter() public  {
        require (isMasternodeOwner(msg.sender), "User has no masternodes");
        require (!voterMap[msg.sender].isVoter, "User Already voted for this proposal");

        voterMap[msg.sender].owner = msg.sender;
        voterMap[msg.sender].isVoter = true;
        votersCount = votersCount + 1;

        if (isTeamMember(msg.sender))
        votersCountTeam = votersCountTeam + 1;
    }

     
    function voteProposal(uint proposalID) public returns (bool success) {
        require(voterMap[msg.sender].isVoter, "Sender not listed as voter");
        require(proposalID >= 0, "No proposal was selected.");
        require(proposalID <= proposalCounter, "Proposal out of limits.");
        require(voterProposals[proposalID] != msg.sender, "Already voted.");


        if(proposalList[proposalID].proposalType == VOTE_TYPE.TEAM) {
            require (isTeamMember(msg.sender), "Restricted for team members");
            voterProposals[proposalID] = msg.sender;
            proposalList[proposalID].totalVotes++;

            if(reachedMajorityForTeam(proposalID)) {
                 
                 
                handleLastProposal();
                return true;
            }
        } else {
            require(votersCount >= MINIMUM_VOTERS_NEEDED, "Not enough voters in existence to push a proposal");
            voterProposals[proposalID] = msg.sender;
            proposalList[proposalID].totalVotes++;

            if(reachedMajority(proposalID)) {
                 
                 
                handleLastProposal();
                return true;
            }
        }


    }

     
    function reachedMajority (uint proposalID) public view returns (bool) {
        uint getProposalVotes = proposalList[proposalID].totalVotes;
        if (getProposalVotes >= majority())
        return true;
    }

     
    function majority () internal view returns (uint) {
        uint a = (votersCount * MAJORITY_PERCENTAGE_NEEDED );
        return a / 100;
    }

     
    function reachedMajorityForTeam (uint proposalID) public view returns (bool) {
        uint getProposalVotes = proposalList[proposalID].totalVotes;
        if (getProposalVotes >= majorityForTeam())
        return true;
    }

     
    function majorityForTeam () internal view returns (uint) {
        uint a = (votersCountTeam * MAJORITY_PERCENTAGE_NEEDED );
        return a / 100;
    }

}

contract CaelumFundraise is Ownable, BasicToken, abstractCaelum {

     

    uint AMOUNT_FOR_MASTERNODE = 50 ether;
    uint SPOTS_RESERVED = 10;
    uint COUNTER;
    bool fundraiseClosed = false;

     
    function() payable public {
        require(msg.value == AMOUNT_FOR_MASTERNODE && msg.value != 0);
        receivedFunds();
    }

     
    function buyMasternode () payable public {
        require(msg.value == AMOUNT_FOR_MASTERNODE && msg.value != 0);
        receivedFunds();
    }

     
    function receivedFunds() internal {
        require(!fundraiseClosed);
        require (COUNTER <= SPOTS_RESERVED);
        owner.transfer(msg.value);
        addMasternode(msg.sender);
    }

}

contract CaelumAcceptERC20 is Ownable, CaelumVotings, abstractCaelum { 
    using SafeMath for uint;

    address[] public tokensList;
    bool setOwnContract = true;

    struct _whitelistTokens {
        address tokenAddress;
        bool active;
        uint requiredAmount;
        uint validUntil;
        uint timestamp;
    }

    mapping(address => mapping(address => uint)) public tokens;
    mapping(address => _whitelistTokens) acceptedTokens;

    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);

     
    function getMiningReward() public view returns(uint) {
        return 50 * 1e8;
    }


     
    function addOwnToken() onlyOwner public returns (bool) {
        require(setOwnContract);
        addToWhitelist(this, 5000 * 1e8, 36500);
        setOwnContract = false;
        return true;
    }

     
     
    function addToWhitelist(address _token, uint _amount, uint daysAllowed) internal {
        _whitelistTokens storage newToken = acceptedTokens[_token];
        newToken.tokenAddress = _token;
        newToken.requiredAmount = _amount;
        newToken.timestamp = now;
        newToken.validUntil = now + (daysAllowed * 1 days);
        newToken.active = true;

        tokensList.push(_token);
    }

     
    function isAcceptedToken(address _ad) internal view returns(bool) {
        return acceptedTokens[_ad].active;
    }

     
    function getAcceptedTokenAmount(address _ad) internal view returns(uint) {
        return acceptedTokens[_ad].requiredAmount;
    }

     
    function isValid(address _ad) internal view returns(bool) {
        uint endTime = acceptedTokens[_ad].validUntil;
        if (block.timestamp < endTime) return true;
        return false;
    }

     
    function listAcceptedTokens() public view returns(address[]) {
        return tokensList;
    }

     
    function getTokenDetails(address token) public view returns(address ad,uint required, bool active, uint valid) {
        return (acceptedTokens[token].tokenAddress, acceptedTokens[token].requiredAmount,acceptedTokens[token].active, acceptedTokens[token].validUntil);
    }

     
    function depositCollateral(address token, uint amount) public {
        require(isAcceptedToken(token), "ERC20 not authorised");   
        require(amount == getAcceptedTokenAmount(token));          
        require(isValid(token));                                   

        tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);

        require(StandardToken(token).transferFrom(msg.sender, this, amount), "error with token");
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);

        addMasternode(msg.sender);
    }

     
    function withdrawCollateral(address token, uint amount) public {
        require(token != 0);  
        require(isAcceptedToken(token), "ERC20 not authorised");  
        require(isMasternodeOwner(msg.sender));  
        require(tokens[token][msg.sender] == amount);  

        uint amountToWithdraw = tokens[token][msg.sender];
        tokens[token][msg.sender] = 0;

        deleteMasternode(getLastPerUser(msg.sender));

        if (!StandardToken(token).transfer(msg.sender, amountToWithdraw)) revert();
        emit Withdraw(token, msg.sender, amountToWithdraw, amountToWithdraw);
    }

}

contract CaelumMasternode is CaelumFundraise, CaelumAcceptERC20{
    using SafeMath for uint;

    bool onTestnet = false;
    bool genesisAdded = false;

    uint  masternodeRound;
    uint  masternodeCandidate;
    uint  masternodeCounter;
    uint  masternodeEpoch;
    uint  miningEpoch;

    uint rewardsProofOfWork;
    uint rewardsMasternode;
    uint rewardsGlobal = 50 * 1e8;

    uint MINING_PHASE_DURATION_BLOCKS = 4500;

    struct MasterNode {
        address accountOwner;
        bool isActive;
        bool isTeamMember;
        uint storedIndex;
        uint startingRound;
        uint[] indexcounter;
    }

    uint[] userArray;
    address[] userAddressArray;

    mapping(uint => MasterNode) userByIndex;  
    mapping(address => MasterNode) userByAddress;  
    mapping(address => uint) userAddressIndex;

    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);

    event NewMasternode(address candidateAddress, uint timeStamp);
    event RemovedMasternode(address candidateAddress, uint timeStamp);

     
    function addGenesis(address _genesis, bool _team) onlyOwner public {
        require(!genesisAdded);

        addMasternode(_genesis);

        if (_team) {
            updateMasternodeAsTeamMember(msg.sender);
        }

    }

     
    function closeGenesis() onlyOwner public {
        genesisAdded = true;  
    }

     
    function addMasternode(address _candidate) internal returns(uint) {
        userByIndex[masternodeCounter].accountOwner = _candidate;
        userByIndex[masternodeCounter].isActive = true;
        userByIndex[masternodeCounter].startingRound = masternodeRound + 1;
        userByIndex[masternodeCounter].storedIndex = masternodeCounter;

        userByAddress[_candidate].accountOwner = _candidate;
        userByAddress[_candidate].indexcounter.push(masternodeCounter);

        userArray.push(userArray.length);
        masternodeCounter++;

        emit NewMasternode(_candidate, now);
        return masternodeCounter - 1;  
    }

     
    function updateMasternode(uint _candidate) internal returns(bool) {
        userByIndex[_candidate].startingRound++;
        return true;
    }

     
    function updateMasternodeAsTeamMember(address _member) internal returns (bool) {
        userByAddress[_member].isTeamMember = true;
        return (true);
    }

     
    function isTeamMember (address _member) public view returns (bool) {
        if (userByAddress[_member].isTeamMember)
        return true;
    }

     
    function deleteMasternode(uint _masternodeID) internal returns(bool success) {

        uint rowToDelete = userByIndex[_masternodeID].storedIndex;
        uint keyToMove = userArray[userArray.length - 1];

        userByIndex[_masternodeID].isActive = userByIndex[_masternodeID].isActive = (false);
        userArray[rowToDelete] = keyToMove;
        userByIndex[keyToMove].storedIndex = rowToDelete;
        userArray.length = userArray.length - 1;

        removeFromUserCounter(_masternodeID);

        emit RemovedMasternode(userByIndex[_masternodeID].accountOwner, now);

        return true;
    }

     
    function isPartOf(uint mnid) public view returns (address) {
        return userByIndex[mnid].accountOwner;
    }

     
    function removeFromUserCounter(uint index)  internal returns(uint[]) {
        address belong = isPartOf(index);

        if (index >= userByAddress[belong].indexcounter.length) return;

        for (uint i = index; i<userByAddress[belong].indexcounter.length-1; i++){
            userByAddress[belong].indexcounter[i] = userByAddress[belong].indexcounter[i+1];
        }

        delete userByAddress[belong].indexcounter[userByAddress[belong].indexcounter.length-1];
        userByAddress[belong].indexcounter.length--;
        return userByAddress[belong].indexcounter;
    }

     
    function setMasternodeCandidate() internal returns(address) {

        uint hardlimitCounter = 0;

        while (getFollowingCandidate() == 0x0) {
             
            require(hardlimitCounter < 6, "Failsafe switched on");
             
            if (hardlimitCounter == 5) return (0);
            masternodeRound = masternodeRound + 1;
            masternodeCandidate = 0;
            hardlimitCounter++;
        }

        if (masternodeCandidate == masternodeCounter - 1) {
            masternodeRound = masternodeRound + 1;
            masternodeCandidate = 0;
        }

        for (uint i = masternodeCandidate; i < masternodeCounter; i++) {
            if (userByIndex[i].isActive) {
                if (userByIndex[i].startingRound == masternodeRound) {
                    updateMasternode(i);
                    masternodeCandidate = i;
                    return (userByIndex[i].accountOwner);
                }
            }
        }

        masternodeRound = masternodeRound + 1;
        return (0);

    }

     
    function getFollowingCandidate() internal view returns(address _address) {
        uint tmpRound = masternodeRound;
        uint tmpCandidate = masternodeCandidate;

        if (tmpCandidate == masternodeCounter - 1) {
            tmpRound = tmpRound + 1;
            tmpCandidate = 0;
        }

        for (uint i = masternodeCandidate; i < masternodeCounter; i++) {
            if (userByIndex[i].isActive) {
                if (userByIndex[i].startingRound == tmpRound) {
                    tmpCandidate = i;
                    return (userByIndex[i].accountOwner);
                }
            }
        }

        tmpRound = tmpRound + 1;
        return (0);
    }

     
    function belongsToUser(address userAddress) public view returns(uint[]) {
        return (userByAddress[userAddress].indexcounter);
    }

     
    function isMasternodeOwner(address _candidate) public view returns(bool) {
        if(userByAddress[_candidate].indexcounter.length <= 0) return false;
        if (userByAddress[_candidate].accountOwner == _candidate)
        return true;
    }

     
    function getLastPerUser(address _candidate) public view returns (uint) {
        return userByAddress[_candidate].indexcounter[userByAddress[_candidate].indexcounter.length - 1];
    }


     
    function calculateRewardStructures() internal {
         
        uint _global_reward_amount = getMiningReward();
        uint getStageOfMining = miningEpoch / MINING_PHASE_DURATION_BLOCKS * 10;

        if (getStageOfMining < 10) {
            rewardsProofOfWork = _global_reward_amount / 100 * 5;
            rewardsMasternode = 0;
            return;
        }

        if (getStageOfMining > 90) {
            rewardsProofOfWork = _global_reward_amount / 100 * 2;
            rewardsMasternode = _global_reward_amount / 100 * 98;
            return;
        }

        uint _mnreward = (_global_reward_amount / 100) * getStageOfMining;
        uint _powreward = (_global_reward_amount - _mnreward);

        setBaseRewards(_powreward, _mnreward);
    }

    function setBaseRewards(uint _pow, uint _mn) internal {
        rewardsMasternode = _mn;
        rewardsProofOfWork = _pow;
    }

     
    function _arrangeMasternodeFlow() internal {
        calculateRewardStructures();
        setMasternodeCandidate();
        miningEpoch++;
    }

     
    function _emergencyLoop() onlyOwner public {
        calculateRewardStructures();
        setMasternodeCandidate();
        miningEpoch++;
    }

    function masternodeInfo(uint index) public view returns
    (
        address,
        bool,
        uint,
        uint
    )
    {
        return (
            userByIndex[index].accountOwner,
            userByIndex[index].isActive,
            userByIndex[index].storedIndex,
            userByIndex[index].startingRound
        );
    }

    function contractProgress() public view returns
    (
        uint epoch,
        uint candidate,
        uint round,
        uint miningepoch,
        uint globalreward,
        uint powreward,
        uint masternodereward,
        uint usercounter
    )
    {
        return (
            masternodeEpoch,
            masternodeCandidate,
            masternodeRound,
            miningEpoch,
            getMiningReward(),
            rewardsProofOfWork,
            rewardsMasternode,
            masternodeCounter
        );
    }

}

contract CaelumMiner is StandardToken, CaelumMasternode {
    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol = "CLM";
    string public name = "Caelum Token";
    uint8 public decimals = 8;
    uint256 public totalSupply = 2100000000000000;

    uint public latestDifficultyPeriodStarted;
    uint public epochCount;
    uint public baseMiningReward = 50;
    uint public blocksPerReadjustment = 512;
    uint public _MINIMUM_TARGET = 2 ** 16;
    uint public _MAXIMUM_TARGET = 2 ** 234;
    uint public rewardEra = 0;

    uint public maxSupplyForEra;
    uint public MAX_REWARD_ERA = 39;
    uint public MINING_RATE_FACTOR = 60;  
     
    uint public MAX_ADJUSTMENT_PERCENT = 100;
    uint public TARGET_DIVISOR = 2000;
    uint public QUOTIENT_LIMIT = TARGET_DIVISOR.div(2);
    mapping(bytes32 => bytes32) solutionForChallenge;
    mapping(address => mapping(address => uint)) allowed;

    bytes32 public challengeNumber;
    uint public difficulty;
    uint public tokensMinted;


    struct Statistics {
        address lastRewardTo;
        uint lastRewardAmount;
        uint lastRewardEthBlockNumber;
        uint lastRewardTimestamp;
    }

    Statistics public statistics;
    
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
    event RewardMasternode(address candidate, uint amount);

    constructor() public {
        tokensMinted = 0;
        maxSupplyForEra = totalSupply.div(2);
        difficulty = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        _newEpoch(0);

        balances[msg.sender] = balances[msg.sender].add(420000 * 1e8);  
        emit Transfer(this, msg.sender, 420000 * 1e8);
    }

    function mint(uint256 nonce, bytes32 challenge_digest) public returns(bool success) {
         
        _hash(nonce, challenge_digest);

        _arrangeMasternodeFlow();

        uint rewardAmount = _reward();
        uint rewardMasternode = _reward_masternode();

        tokensMinted += rewardAmount.add(rewardMasternode);

        uint epochCounter = _newEpoch(nonce);

        _adjustDifficulty();

        statistics = Statistics(msg.sender, rewardAmount, block.number, now);

        emit Mint(msg.sender, rewardAmount, epochCounter, challengeNumber);

        return true;
    }

    function _newEpoch(uint256 nonce) internal returns(uint) {

        if (tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < MAX_REWARD_ERA) {
            rewardEra = rewardEra + 1;
        }
        maxSupplyForEra = totalSupply - totalSupply.div(2 ** (rewardEra + 1));
        epochCount = epochCount.add(1);
        challengeNumber = blockhash(block.number - 1);
        return (epochCount);
    }

    function _hash(uint256 nonce, bytes32 challenge_digest) internal returns(bytes32 digest) {
        digest = keccak256(challengeNumber, msg.sender, nonce);
        if (digest != challenge_digest) revert();
        if (uint256(digest) > difficulty) revert();
        bytes32 solution = solutionForChallenge[challengeNumber];
        solutionForChallenge[challengeNumber] = digest;
        if (solution != 0x0) revert();  
    }

    function _reward() internal returns(uint) {

        uint _pow = rewardsProofOfWork;

        balances[msg.sender] = balances[msg.sender].add(_pow);
        emit Transfer(this, msg.sender, _pow);

        return _pow;
    }

    function _reward_masternode() internal returns(uint) {

        uint _mnReward = rewardsMasternode;
        if (masternodeCounter == 0) return 0;

        address _mnCandidate = userByIndex[masternodeCandidate].accountOwner;
        if (_mnCandidate == 0x0) return 0;

        balances[_mnCandidate] = balances[_mnCandidate].add(_mnReward);
        emit Transfer(this, _mnCandidate, _mnReward);

        emit RewardMasternode(_mnCandidate, _mnReward);

        return _mnReward;
    }


     
    function _adjustDifficulty() internal returns(uint) {
         
        if (epochCount % blocksPerReadjustment != 0) {
            return difficulty;
        }

        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
         
         
        uint epochsMined = blocksPerReadjustment;
        uint targetEthBlocksPerDiffPeriod = epochsMined * MINING_RATE_FACTOR;
         
        if (ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod) {
            uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(MAX_ADJUSTMENT_PERCENT)).div(ethBlocksSinceLastDifficultyPeriod);
            uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(QUOTIENT_LIMIT);
             
             
            difficulty = difficulty.sub(difficulty.div(TARGET_DIVISOR).mul(excess_block_pct_extra));  
        } else {
            uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(MAX_ADJUSTMENT_PERCENT)).div(targetEthBlocksPerDiffPeriod);
            uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(QUOTIENT_LIMIT);  
             
            difficulty = difficulty.add(difficulty.div(TARGET_DIVISOR).mul(shortage_block_pct_extra));  
        }
        latestDifficultyPeriodStarted = block.number;
        if (difficulty < _MINIMUM_TARGET)  
        {
            difficulty = _MINIMUM_TARGET;
        }
        if (difficulty > _MAXIMUM_TARGET)  
        {
            difficulty = _MAXIMUM_TARGET;
        }
    }
     
    function getChallengeNumber() public view returns(bytes32) {
        return challengeNumber;
    }
     
    function getMiningDifficulty() public view returns(uint) {
        return _MAXIMUM_TARGET.div(difficulty);
    }

    function getMiningTarget() public view returns(uint) {
        return difficulty;
    }

    function getMiningReward() public view returns(uint) {
        return (baseMiningReward * 1e8).div(2 ** rewardEra);
    }

     
    function getMintDigest(
        uint256 nonce,
        bytes32 challenge_digest,
        bytes32 challenge_number
    )
    public view returns(bytes32 digesttest) {
        bytes32 digest = keccak256(challenge_number, msg.sender, nonce);
        return digest;
    }
     
    function checkMintSolution(
        uint256 nonce,
        bytes32 challenge_digest,
        bytes32 challenge_number,
        uint testTarget
    )
    public view returns(bool success) {
        bytes32 digest = keccak256(challenge_number, msg.sender, nonce);
        if (uint256(digest) > testTarget) revert();
        return (digest == challenge_digest);
    }
}