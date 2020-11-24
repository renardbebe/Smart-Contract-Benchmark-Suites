 

pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;



 
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


contract ParameterStore {
     
    event ProposalCreated(
        uint256 proposalID,
        address indexed proposer,
        uint256 requestID,
        string key,
        bytes32 value,
        bytes metadataHash
    );
    event Initialized();
    event ParameterSet(string name, bytes32 key, bytes32 value);
    event ProposalAccepted(uint256 proposalID, string key, bytes32 value);


     
    using SafeMath for uint256;

    address owner;
    bool public initialized;
    mapping(bytes32 => bytes32) public params;

     
    struct Proposal {
        address gatekeeper;
        uint256 requestID;
        string key;
        bytes32 value;
        bytes metadataHash;
        bool executed;
    }

     
    Proposal[] public proposals;

     
     
    constructor(string[] memory _names, bytes32[] memory _values) public {
        owner = msg.sender;
        require(_names.length == _values.length, "All inputs must have the same length");

        for (uint i = 0; i < _names.length; i++) {
            string memory name = _names[i];
            set(name, _values[i]);
        }
    }

     
    function init() public {
        require(msg.sender == owner, "Only the owner can initialize the ParameterStore");
        require(initialized == false, "Contract has already been initialized");

        initialized = true;

         
         
        require(getAsAddress("gatekeeperAddress") != address(0), "Missing gatekeeper");

        emit Initialized();
    }

     

     
    function get(string memory _name) public view returns (bytes32 value) {
        require(initialized, "Contract has not yet been initialized");
        return params[keccak256(abi.encodePacked(_name))];
    }

     
    function getAsUint(string memory _name) public view returns(uint256) {
        bytes32 value = get(_name);
        return uint256(value);
    }

     
    function getAsAddress(string memory _name) public view returns (address) {
        bytes32 value = get(_name);
        return address(uint256(value));
    }

     
     
    function set(string memory _name, bytes32 _value) private {
        bytes32 key = keccak256(abi.encodePacked(_name));
        params[key] = _value;
        emit ParameterSet(_name, key, _value);
    }

     
    function setInitialValue(string memory _name, bytes32 _value) public {
        require(msg.sender == owner, "Only the owner can set initial values");
        require(initialized == false, "Cannot set values after initialization");

        set(_name, _value);
    }

    function _createProposal(Gatekeeper gatekeeper, string memory key, bytes32 value, bytes memory metadataHash) internal returns(uint256) {
        require(metadataHash.length > 0, "metadataHash cannot be empty");

        Proposal memory p = Proposal({
            gatekeeper: address(gatekeeper),
            requestID: 0,
            key: key,
            value: value,
            metadataHash: metadataHash,
            executed: false
        });

         
         
         
        uint requestID = gatekeeper.requestPermission(metadataHash);
        p.requestID = requestID;
        uint proposalID = proposalCount();
        proposals.push(p);

        emit ProposalCreated(proposalID, msg.sender, requestID, key, value, metadataHash);
        return proposalID;
    }

     
    function createProposal(string calldata key, bytes32 value, bytes calldata metadataHash) external returns(uint256) {
        require(initialized, "Contract has not yet been initialized");

        Gatekeeper gatekeeper = _gatekeeper();
        return _createProposal(gatekeeper, key, value, metadataHash);
    }

     
    function createManyProposals(
        string[] calldata keys,
        bytes32[] calldata values,
        bytes[] calldata metadataHashes
    ) external {
        require(initialized, "Contract has not yet been initialized");
        require(
            keys.length == values.length && values.length == metadataHashes.length,
            "All inputs must have the same length"
        );

        Gatekeeper gatekeeper = _gatekeeper();
        for (uint i = 0; i < keys.length; i++) {
            string memory key = keys[i];
            bytes32 value = values[i];
            bytes memory metadataHash = metadataHashes[i];
            _createProposal(gatekeeper, key, value, metadataHash);
        }
    }

     
    function setValue(uint256 proposalID) public returns(bool) {
        require(proposalID < proposalCount(), "Invalid proposalID");
        require(initialized, "Contract has not yet been initialized");

        Proposal memory p = proposals[proposalID];
        Gatekeeper gatekeeper = Gatekeeper(p.gatekeeper);

        require(gatekeeper.hasPermission(p.requestID), "Proposal has not been approved");
        require(p.executed == false, "Proposal already executed");

        proposals[proposalID].executed = true;

        set(p.key, p.value);

        emit ProposalAccepted(proposalID, p.key, p.value);
        return true;
    }

    function proposalCount() public view returns(uint256) {
        return proposals.length;
    }

    function _gatekeeper() private view returns(Gatekeeper) {
        address gatekeeperAddress = getAsAddress("gatekeeperAddress");
        require(gatekeeperAddress != address(0), "Missing gatekeeper");
        return Gatekeeper(gatekeeperAddress);
    }
}

 
interface IDonationReceiver {
    event Donation(address indexed payer, address indexed donor, uint numTokens, bytes metadataHash);

    function donate(address donor, uint tokens, bytes calldata metadataHash) external returns(bool);
}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Gatekeeper {
     
    event PermissionRequested(
        uint256 indexed epochNumber,
        address indexed resource,
        uint requestID,
        bytes metadataHash
    );
    event SlateCreated(uint slateID, address indexed recommender, uint[] requestIDs, bytes metadataHash);
    event SlateStaked(uint slateID, address indexed staker, uint numTokens);
    event VotingTokensDeposited(address indexed voter, uint numTokens);
    event VotingTokensWithdrawn(address indexed voter, uint numTokens);
    event VotingRightsDelegated(address indexed voter, address delegate);
    event BallotCommitted(
        uint indexed epochNumber,
        address indexed committer,
        address indexed voter,
        uint numTokens,
        bytes32 commitHash
    );
    event BallotRevealed(uint indexed epochNumber, address indexed voter, uint numTokens);
    event ContestAutomaticallyFinalized(
        uint256 indexed epochNumber,
        address indexed resource,
        uint256 winningSlate
    );
    event ContestFinalizedWithoutWinner(uint indexed epochNumber, address indexed resource);
    event VoteFinalized(
        uint indexed epochNumber,
        address indexed resource,
        uint winningSlate,
        uint winnerVotes,
        uint totalVotes
    );
    event VoteFailed(
        uint indexed epochNumber,
        address indexed resource,
        uint leadingSlate,
        uint leaderVotes,
        uint runnerUpSlate,
        uint runnerUpVotes,
        uint totalVotes
    );
    event RunoffFinalized(
        uint indexed epochNumber,
        address indexed resource,
        uint winningSlate,
        uint winnerVotes,
        uint losingSlate,
        uint loserVotes
    );
    event StakeWithdrawn(uint slateID, address indexed staker, uint numTokens);

     
    using SafeMath for uint256;

    uint constant ONE_WEEK = 604800;

     
    uint public startTime;
    uint public constant EPOCH_LENGTH = ONE_WEEK * 13;
    uint public constant SLATE_SUBMISSION_PERIOD_START = ONE_WEEK;
    uint public constant COMMIT_PERIOD_START = ONE_WEEK * 11;
    uint public constant REVEAL_PERIOD_START = ONE_WEEK * 12;

     
    ParameterStore public parameters;

     
    IERC20 public token;

     
    struct Request {
        bytes metadataHash;
         
        address resource;
        bool approved;
        uint expirationTime;
        uint epochNumber;
    }

     
    Request[] public requests;

     
    enum SlateStatus {
        Unstaked,
        Staked,
        Accepted
    }

    struct Slate {
        address recommender;
        bytes metadataHash;
        mapping(uint => bool) requestIncluded;
        uint[] requests;
        SlateStatus status;
         
        address staker;
        uint stake;
         
        uint256 epochNumber;
        address resource;
    }

     
    Slate[] public slates;

     
    mapping(address => uint) public voteTokenBalance;

     
    mapping(address => address) public delegate;

     
    struct VoteCommitment {
        bytes32 commitHash;
        uint numTokens;
        bool committed;
        bool revealed;
    }

     
    struct SlateVotes {
        uint firstChoiceVotes;
         
        mapping(uint => uint) secondChoiceVotes;
        uint totalSecondChoiceVotes;
    }

    enum ContestStatus {
        Empty,
        NoContest,
        Active,
        Finalized
    }

    struct Contest {
        ContestStatus status;

         
        uint[] slates;
        uint[] stakedSlates;
        uint256 lastStaked;

         
        mapping(uint => SlateVotes) votes;
        uint256 stakesDonated;

         
        uint voteLeader;
        uint voteRunnerUp;
        uint256 leaderVotes;
        uint256 runnerUpVotes;
        uint256 totalVotes;

         
        uint winner;
    }

     
    mapping(address => address) public incumbent;

     
    struct Ballot {
         
        mapping(address => Contest) contests;
         
        bool created;

         
        mapping(address => VoteCommitment) commitments;
    }

     
     
    mapping(uint => Ballot) public ballots;


     
     
    constructor(uint _startTime, ParameterStore _parameters, IERC20 _token) public {
        require(address(_parameters) != address(0), "Parameter store address cannot be zero");
        parameters = _parameters;

        require(address(_token) != address(0), "Token address cannot be zero");
        token = _token;

        startTime = _startTime;
    }

     
     
    function currentEpochNumber() public view returns(uint) {
        uint elapsed = now.sub(startTime);
        uint epoch = elapsed.div(EPOCH_LENGTH);

        return epoch;
    }

     
    function epochStart(uint256 epoch) public view returns(uint) {
        return startTime.add(EPOCH_LENGTH.mul(epoch));
    }


     
     
    function recommendSlate(
        address resource,
        uint[] memory requestIDs,
        bytes memory metadataHash
    )
        public returns(uint)
    {
        require(isCurrentGatekeeper(), "Not current gatekeeper");
        require(slateSubmissionPeriodActive(resource), "Submission period not active");
        require(metadataHash.length > 0, "metadataHash cannot be empty");

        uint256 epochNumber = currentEpochNumber();

         
        Slate memory s = Slate({
            recommender: msg.sender,
            metadataHash: metadataHash,
            requests: requestIDs,
            status: SlateStatus.Unstaked,
            staker: address(0),
            stake: 0,
            epochNumber: epochNumber,
            resource: resource
        });

         
        uint slateID = slateCount();
        slates.push(s);

         
        for (uint i = 0; i < requestIDs.length; i++) {
            uint requestID = requestIDs[i];
            require(requestID < requestCount(), "Invalid requestID");

            Request memory r = requests[requestID];
             
            require(r.resource == resource, "Resource does not match");

             
            require(r.epochNumber == epochNumber, "Invalid epoch");

             
            require(slates[slateID].requestIncluded[requestID] == false, "Duplicate requests are not allowed");
            slates[slateID].requestIncluded[requestID] = true;
        }

         
        ballots[epochNumber].contests[resource].slates.push(slateID);

        emit SlateCreated(slateID, msg.sender, requestIDs, metadataHash);
        return slateID;
    }

     
    function slateRequests(uint slateID) public view returns(uint[] memory) {
        return slates[slateID].requests;
    }

     
    function stakeTokens(uint slateID) public returns(bool) {
        require(isCurrentGatekeeper(), "Not current gatekeeper");
        require(slateID < slateCount(), "No slate exists with that slateID");
        require(slates[slateID].status == SlateStatus.Unstaked, "Slate has already been staked");

        address staker = msg.sender;

         
        uint stakeAmount = parameters.getAsUint("slateStakeAmount");
        require(token.balanceOf(staker) >= stakeAmount, "Insufficient token balance");

        Slate storage slate = slates[slateID];

         
        require(slateSubmissionPeriodActive(slate.resource), "Submission period not active");
        uint256 epochNumber = currentEpochNumber();
        assert(slate.epochNumber == epochNumber);

         
         
        slate.staker = staker;
        slate.stake = stakeAmount;
        slate.status = SlateStatus.Staked;
        require(token.transferFrom(staker, address(this), stakeAmount), "Failed to transfer tokens");

         
         
        Contest storage contest = ballots[slate.epochNumber].contests[slate.resource];
        contest.stakedSlates.push(slateID);
         
        contest.lastStaked = now.sub(epochStart(epochNumber));

        uint256 numSlates = contest.stakedSlates.length;
        if (numSlates == 1) {
            contest.status = ContestStatus.NoContest;
        } else {
            contest.status = ContestStatus.Active;
        }

        emit SlateStaked(slateID, staker, stakeAmount);
        return true;
    }


     
    function withdrawStake(uint slateID) public returns(bool) {
        require(slateID < slateCount(), "No slate exists with that slateID");

         
        Slate memory slate = slates[slateID];

        require(slate.status == SlateStatus.Accepted, "Slate has not been accepted");
        require(msg.sender == slate.staker, "Only the original staker can withdraw this stake");
        require(slate.stake > 0, "Stake has already been withdrawn");

         
        slates[slateID].stake = 0;
        require(token.transfer(slate.staker, slate.stake), "Failed to transfer tokens");

        emit StakeWithdrawn(slateID, slate.staker, slate.stake);
        return true;
    }

     
    function depositVoteTokens(uint numTokens) public returns(bool) {
        require(isCurrentGatekeeper(), "Not current gatekeeper");
        address voter = msg.sender;

         
        require(token.balanceOf(msg.sender) >= numTokens, "Insufficient token balance");

         
        uint originalBalance = voteTokenBalance[voter];
        voteTokenBalance[voter] = originalBalance.add(numTokens);

         
        require(token.transferFrom(voter, address(this), numTokens), "Failed to transfer tokens");

        emit VotingTokensDeposited(voter, numTokens);
        return true;
    }

     
    function withdrawVoteTokens(uint numTokens) public returns(bool) {
        require(commitPeriodActive() == false, "Tokens locked during voting");

        address voter = msg.sender;

        uint votingRights = voteTokenBalance[voter];
        require(votingRights >= numTokens, "Insufficient vote token balance");

         
        voteTokenBalance[voter] = votingRights.sub(numTokens);

        require(token.transfer(voter, numTokens), "Failed to transfer tokens");

        emit VotingTokensWithdrawn(voter, numTokens);
        return true;
    }


     
    function delegateVotingRights(address _delegate) public returns(bool) {
        address voter = msg.sender;
        require(voter != _delegate, "Delegate and voter cannot be equal");

        delegate[voter] = _delegate;

        emit VotingRightsDelegated(voter, _delegate);
        return true;
    }

     
    function commitBallot(address voter, bytes32 commitHash, uint numTokens) public {
        uint epochNumber = currentEpochNumber();

        require(commitPeriodActive(), "Commit period not active");

        require(didCommit(epochNumber, voter) == false, "Voter has already committed for this ballot");
        require(commitHash != 0, "Cannot commit zero hash");

        address committer = msg.sender;

         
        if (committer != voter) {
            require(committer == delegate[voter], "Not a delegate");
            require(voteTokenBalance[voter] >= numTokens, "Insufficient tokens");
        } else {
             
            if (voteTokenBalance[voter] < numTokens) {
                uint remainder = numTokens.sub(voteTokenBalance[voter]);
                depositVoteTokens(remainder);
            }
        }

        assert(voteTokenBalance[voter] >= numTokens);

         
        Ballot storage ballot = ballots[epochNumber];
        VoteCommitment memory commitment = VoteCommitment({
            commitHash: commitHash,
            numTokens: numTokens,
            committed: true,
            revealed: false
        });

        ballot.commitments[voter] = commitment;

        emit BallotCommitted(epochNumber, committer, voter, numTokens, commitHash);
    }

     
    function didCommit(uint epochNumber, address voter) public view returns(bool) {
        return ballots[epochNumber].commitments[voter].committed;
    }

     
    function getCommitHash(uint epochNumber, address voter) public view returns(bytes32) {
        VoteCommitment memory v = ballots[epochNumber].commitments[voter];
        require(v.committed, "Voter has not committed for this ballot");

        return v.commitHash;
    }

     
    function revealBallot(
        uint256 epochNumber,
        address voter,
        address[] memory resources,
        uint[] memory firstChoices,
        uint[] memory secondChoices,
        uint salt
    ) public {
        uint256 epochTime = now.sub(epochStart(epochNumber));
        require(
            (REVEAL_PERIOD_START <= epochTime) && (epochTime < EPOCH_LENGTH),
            "Reveal period not active"
        );

        require(voter != address(0), "Voter address cannot be zero");
        require(resources.length == firstChoices.length, "All inputs must have the same length");
        require(firstChoices.length == secondChoices.length, "All inputs must have the same length");

        require(didCommit(epochNumber, voter), "Voter has not committed");
        require(didReveal(epochNumber, voter) == false, "Voter has already revealed");


         
        bytes memory buf;
        uint votes = resources.length;
        for (uint i = 0; i < votes; i++) {
            buf = abi.encodePacked(
                buf,
                resources[i],
                firstChoices[i],
                secondChoices[i]
            );
        }
        buf = abi.encodePacked(buf, salt);
        bytes32 hashed = keccak256(buf);

        Ballot storage ballot = ballots[epochNumber];

         
        VoteCommitment memory v = ballot.commitments[voter];
        require(hashed == v.commitHash, "Submitted ballot does not match commitment");

         
        for (uint i = 0; i < votes; i++) {
            address resource = resources[i];

             
            Contest storage contest = ballot.contests[resource];

             
            uint firstChoice = firstChoices[i];
            uint secondChoice = secondChoices[i];

             
            if (slates[firstChoice].status == SlateStatus.Staked) {
                SlateVotes storage firstChoiceSlate = contest.votes[firstChoice];
                contest.totalVotes = contest.totalVotes.add(v.numTokens);
                uint256 newCount = firstChoiceSlate.firstChoiceVotes.add(v.numTokens);

                 
                if (firstChoice == contest.voteLeader) {
                     
                    contest.leaderVotes = newCount;
                } else if (newCount > contest.leaderVotes) {
                     
                    contest.voteRunnerUp = contest.voteLeader;
                    contest.runnerUpVotes = contest.leaderVotes;

                    contest.voteLeader = firstChoice;
                    contest.leaderVotes = newCount;
                } else if (newCount > contest.runnerUpVotes) {
                     
                    contest.voteRunnerUp = firstChoice;
                    contest.runnerUpVotes = newCount;
                }

                firstChoiceSlate.firstChoiceVotes = newCount;

                 
                if (slates[secondChoice].status == SlateStatus.Staked) {
                    SlateVotes storage secondChoiceSlate = contest.votes[secondChoice];
                    secondChoiceSlate.totalSecondChoiceVotes = secondChoiceSlate.totalSecondChoiceVotes.add(v.numTokens);
                    firstChoiceSlate.secondChoiceVotes[secondChoice] = firstChoiceSlate.secondChoiceVotes[secondChoice].add(v.numTokens);
                }
            }
        }

         
        ballot.commitments[voter].revealed = true;

        emit BallotRevealed(epochNumber, voter, v.numTokens);
    }

     
    function revealManyBallots(
        uint256 epochNumber,
        address[] memory _voters,
        bytes[] memory _ballots,
        uint[] memory _salts
    ) public {
        uint numBallots = _voters.length;
        require(
            _salts.length == _voters.length && _ballots.length == _voters.length,
            "Inputs must have the same length"
        );

        for (uint i = 0; i < numBallots; i++) {
             
            (
                address[] memory resources,
                uint[] memory firstChoices,
                uint[] memory secondChoices
            ) = abi.decode(_ballots[i], (address[], uint[], uint[]));

            revealBallot(epochNumber, _voters[i], resources, firstChoices, secondChoices, _salts[i]);
        }
    }

     
    function getFirstChoiceVotes(uint epochNumber, address resource, uint slateID) public view returns(uint) {
        SlateVotes storage v = ballots[epochNumber].contests[resource].votes[slateID];
        return v.firstChoiceVotes;
    }

     
    function getSecondChoiceVotes(uint epochNumber, address resource, uint slateID) public view returns(uint) {
         
        Contest storage contest = ballots[epochNumber].contests[resource];
        uint numSlates = contest.stakedSlates.length;
        uint votes = 0;
        for (uint i = 0; i < numSlates; i++) {
            uint otherSlateID = contest.stakedSlates[i];
            if (otherSlateID != slateID) {
                SlateVotes storage v = contest.votes[otherSlateID];
                 
                votes = votes.add(v.secondChoiceVotes[slateID]);
            }
        }
        return votes;
    }

     
    function didReveal(uint epochNumber, address voter) public view returns(bool) {
        return ballots[epochNumber].commitments[voter].revealed;
    }

     
    function finalizeContest(uint epochNumber, address resource) public {
        require(isCurrentGatekeeper(), "Not current gatekeeper");

         
        require(currentEpochNumber() > epochNumber, "Contest epoch still active");

         
        Contest storage contest = ballots[epochNumber].contests[resource];
        require(contest.status == ContestStatus.Active || contest.status == ContestStatus.NoContest,
            "Either no contest is in progress for this resource, or it has been finalized");

         
        if (contest.status == ContestStatus.NoContest) {
            uint256 winningSlate = contest.stakedSlates[0];
            assert(slates[winningSlate].status == SlateStatus.Staked);

            contest.winner = winningSlate;
            contest.status = ContestStatus.Finalized;

            acceptSlate(winningSlate);
            emit ContestAutomaticallyFinalized(epochNumber, resource, winningSlate);
            return;
        }

         
        if (contest.totalVotes > 0) {
            uint256 winnerVotes = contest.leaderVotes;

             
             
            if (winnerVotes.mul(2) > contest.totalVotes) {
                contest.winner = contest.voteLeader;
                acceptSlate(contest.winner);

                contest.status = ContestStatus.Finalized;
                emit VoteFinalized(epochNumber, resource, contest.winner, winnerVotes, contest.totalVotes);
            } else {
                emit VoteFailed(epochNumber, resource, contest.voteLeader, winnerVotes, contest.voteRunnerUp, contest.runnerUpVotes, contest.totalVotes);
                _finalizeRunoff(epochNumber, resource);
            }
        } else {
             
            contest.status = ContestStatus.Finalized;
            emit ContestFinalizedWithoutWinner(epochNumber, resource);
            return;
        }
    }

     
    function contestStatus(uint epochNumber, address resource) public view returns(ContestStatus) {
        return ballots[epochNumber].contests[resource].status;
    }

     
    function contestSlates(uint epochNumber, address resource) public view returns(uint[] memory) {
        return ballots[epochNumber].contests[resource].slates;
    }


     
    function contestDetails(uint256 epochNumber, address resource) external view
        returns(
            ContestStatus status,
            uint256[] memory allSlates,
            uint256[] memory stakedSlates,
            uint256 lastStaked,
            uint256 voteWinner,
            uint256 voteRunnerUp,
            uint256 winner
        ) {
        Contest memory c =  ballots[epochNumber].contests[resource];

        status = c.status;
        allSlates = c.slates;
        stakedSlates = c.stakedSlates;
        lastStaked = c.lastStaked;
        voteWinner = c.voteLeader;
        voteRunnerUp = c.voteRunnerUp;
        winner = c.winner;
    }

     
    function _finalizeRunoff(uint epochNumber, address resource) internal {
        require(isCurrentGatekeeper(), "Not current gatekeeper");

        Contest storage contest = ballots[epochNumber].contests[resource];

        uint voteLeader = contest.voteLeader;
        uint voteRunnerUp = contest.voteRunnerUp;

         
         
        SlateVotes storage leader = contest.votes[voteLeader];
        SlateVotes storage runnerUp = contest.votes[voteRunnerUp];

        uint256 secondChoiceVotesForLeader = leader.totalSecondChoiceVotes
            .sub(runnerUp.secondChoiceVotes[voteLeader]).sub(leader.secondChoiceVotes[voteLeader]);

        uint256 secondChoiceVotesForRunnerUp = runnerUp.totalSecondChoiceVotes
            .sub(leader.secondChoiceVotes[voteRunnerUp]).sub(runnerUp.secondChoiceVotes[voteRunnerUp]);

        uint256 leaderTotal = contest.leaderVotes.add(secondChoiceVotesForLeader);
        uint256 runnerUpTotal = contest.runnerUpVotes.add(secondChoiceVotesForRunnerUp);


         
        uint runoffWinner = 0;
        uint runoffWinnerVotes = 0;
        uint runoffLoser = 0;
        uint runoffLoserVotes = 0;

         
        if ((leaderTotal > runnerUpTotal) ||
           ((leaderTotal == runnerUpTotal) &&
            (voteLeader < voteRunnerUp)
            )) {
            runoffWinner = voteLeader;
            runoffWinnerVotes = leaderTotal;
            runoffLoser = voteRunnerUp;
            runoffLoserVotes = runnerUpTotal;
        } else {
            runoffWinner = voteRunnerUp;
            runoffWinnerVotes = runnerUpTotal;
            runoffLoser = voteLeader;
            runoffLoserVotes = leaderTotal;
        }

         
        contest.winner = runoffWinner;
        contest.status = ContestStatus.Finalized;
        acceptSlate(runoffWinner);

        emit RunoffFinalized(epochNumber, resource, runoffWinner, runoffWinnerVotes, runoffLoser, runoffLoserVotes);
    }


     
    function donateChallengerStakes(uint256 epochNumber, address resource, uint256 startIndex, uint256 count) public {
        Contest storage contest = ballots[epochNumber].contests[resource];
        require(contest.status == ContestStatus.Finalized, "Contest is not finalized");

        uint256 numSlates = contest.stakedSlates.length;
        require(contest.stakesDonated != numSlates, "All stakes donated");

         
        require(startIndex == contest.stakesDonated, "Invalid start index");

        uint256 endIndex = startIndex.add(count);
        require(endIndex <= numSlates, "Invalid end index");

        address stakeDonationAddress = parameters.getAsAddress("stakeDonationAddress");
        IDonationReceiver donationReceiver = IDonationReceiver(stakeDonationAddress);
        bytes memory stakeDonationHash = "Qmepxeh4KVkyHYgt3vTjmodB5RKZgUEmdohBZ37oKXCUCm";

        for (uint256 i = startIndex; i < endIndex; i++) {
            uint256 slateID = contest.stakedSlates[i];
            Slate storage slate = slates[slateID];
            if (slate.status != SlateStatus.Accepted) {
                uint256 donationAmount = slate.stake;
                slate.stake = 0;

                 
                if (donationAmount > 0) {
                    require(
                        token.approve(address(donationReceiver), donationAmount),
                        "Failed to approve Gatekeeper to spend tokens"
                    );
                    donationReceiver.donate(address(this), donationAmount, stakeDonationHash);
                }
            }
        }

         
        contest.stakesDonated = endIndex;
    }

     
    function getWinningSlate(uint epochNumber, address resource) public view returns(uint) {
        Contest storage c = ballots[epochNumber].contests[resource];
        require(c.status == ContestStatus.Finalized, "Vote is not finalized yet");

        return c.winner;
    }


     
     
    function requestPermission(bytes memory metadataHash) public returns(uint) {
        require(isCurrentGatekeeper(), "Not current gatekeeper");
        require(metadataHash.length > 0, "metadataHash cannot be empty");
        address resource = msg.sender;
        uint256 epochNumber = currentEpochNumber();

        require(slateSubmissionPeriodActive(resource), "Submission period not active");

         
        uint256 expirationTime = epochStart(epochNumber.add(2));

         
        Request memory r = Request({
            metadataHash: metadataHash,
            resource: resource,
            approved: false,
            expirationTime: expirationTime,
            epochNumber: epochNumber
        });

         
        uint requestID = requestCount();
        requests.push(r);

        emit PermissionRequested(epochNumber, resource, requestID, metadataHash);
        return requestID;
    }

     
    function acceptSlate(uint slateID) private {
         
        Slate storage s = slates[slateID];
        s.status = SlateStatus.Accepted;

         
        if (incumbent[s.resource] != s.recommender) {
            incumbent[s.resource] = s.recommender;
        }

         
        uint[] memory requestIDs = s.requests;
        for (uint i = 0; i < requestIDs.length; i++) {
            uint requestID = requestIDs[i];
            requests[requestID].approved = true;
        }
    }

     
    function hasPermission(uint requestID) public view returns(bool) {
        return requests[requestID].approved && now < requests[requestID].expirationTime;
    }


     
    function slateCount() public view returns(uint256) {
        return slates.length;
    }

    function requestCount() public view returns (uint256) {
        return requests.length;
    }

     
    function slateSubmissionDeadline(uint256 epochNumber, address resource) public view returns(uint256) {
        Contest memory contest = ballots[epochNumber].contests[resource];
        uint256 offset = (contest.lastStaked.add(COMMIT_PERIOD_START)).div(2);

        return epochStart(epochNumber).add(offset);
    }

     
    function slateSubmissionPeriodActive(address resource) public view returns(bool) {
        uint256 epochNumber = currentEpochNumber();
        uint256 start = epochStart(epochNumber).add(SLATE_SUBMISSION_PERIOD_START);
        uint256 end = slateSubmissionDeadline(epochNumber, resource);

        return (start <= now) && (now < end);
    }

     
    function commitPeriodActive() private view returns(bool) {
        uint256 epochTime = now.sub(epochStart(currentEpochNumber()));
        return (COMMIT_PERIOD_START <= epochTime) && (epochTime < REVEAL_PERIOD_START);
    }

     
    function isCurrentGatekeeper() public view returns(bool) {
        return parameters.getAsAddress("gatekeeperAddress") == address(this);
    }
}