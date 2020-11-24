 

 

pragma solidity ^0.5.0;

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity ^0.5.4;

interface IntVoteInterface {
     
     
    modifier onlyProposalOwner(bytes32 _proposalId) {revert(); _;}
    modifier votable(bytes32 _proposalId) {revert(); _;}

    event NewProposal(
        bytes32 indexed _proposalId,
        address indexed _organization,
        uint256 _numOfChoices,
        address _proposer,
        bytes32 _paramsHash
    );

    event ExecuteProposal(bytes32 indexed _proposalId,
        address indexed _organization,
        uint256 _decision,
        uint256 _totalReputation
    );

    event VoteProposal(
        bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _voter,
        uint256 _vote,
        uint256 _reputation
    );

    event CancelProposal(bytes32 indexed _proposalId, address indexed _organization );
    event CancelVoting(bytes32 indexed _proposalId, address indexed _organization, address indexed _voter);

     
    function propose(
        uint256 _numOfChoices,
        bytes32 _proposalParameters,
        address _proposer,
        address _organization
        ) external returns(bytes32);

    function vote(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 _rep,
        address _voter
    )
    external
    returns(bool);

    function cancelVote(bytes32 _proposalId) external;

    function getNumberOfChoices(bytes32 _proposalId) external view returns(uint256);

    function isVotable(bytes32 _proposalId) external view returns(bool);

     
    function voteStatus(bytes32 _proposalId, uint256 _choice) external view returns(uint256);

     
    function isAbstainAllow() external pure returns(bool);

     
    function getAllowedRangeOfChoices() external pure returns(uint256 min, uint256 max);
}

 

pragma solidity ^0.5.4;

 


library RealMath {

     
    uint256 constant private REAL_BITS = 256;

     
    uint256 constant private REAL_FBITS = 40;

     
    uint256 constant private REAL_ONE = uint256(1) << REAL_FBITS;

     
    function pow(uint256 realBase, uint256 exponent) internal pure returns (uint256) {

        uint256 tempRealBase = realBase;
        uint256 tempExponent = exponent;

         
        uint256 realResult = REAL_ONE;
        while (tempExponent != 0) {
             
            if ((tempExponent & 0x1) == 0x1) {
                 
                realResult = mul(realResult, tempRealBase);
            }
                 
            tempExponent = tempExponent >> 1;
            if (tempExponent != 0) {
                 
                tempRealBase = mul(tempRealBase, tempRealBase);
            }
        }

         
        return realResult;
    }

     
    function fraction(uint216 numerator, uint216 denominator) internal pure returns (uint256) {
        return div(uint256(numerator) * REAL_ONE, uint256(denominator) * REAL_ONE);
    }

     
    function mul(uint256 realA, uint256 realB) private pure returns (uint256) {
         
         
        uint256 res = realA * realB;
        require(res/realA == realB, "RealMath mul overflow");
        return (res >> REAL_FBITS);
    }

     
    function div(uint256 realNumerator, uint256 realDenominator) private pure returns (uint256) {
         
         
        return uint256((uint256(realNumerator) * REAL_ONE) / uint256(realDenominator));
    }

}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.4;


interface VotingMachineCallbacksInterface {
    function mintReputation(uint256 _amount, address _beneficiary, bytes32 _proposalId) external returns(bool);
    function burnReputation(uint256 _amount, address _owner, bytes32 _proposalId) external returns(bool);

    function stakingTokenTransfer(IERC20 _stakingToken, address _beneficiary, uint256 _amount, bytes32 _proposalId)
    external
    returns(bool);

    function getTotalReputationSupply(bytes32 _proposalId) external view returns(uint256);
    function reputationOf(address _owner, bytes32 _proposalId) external view returns(uint256);
    function balanceOfStakingToken(IERC20 _stakingToken, bytes32 _proposalId) external view returns(uint256);
}

 

pragma solidity ^0.5.4;

interface ProposalExecuteInterface {
    function executeProposal(bytes32 _proposalId, int _decision) external returns(bool);
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.4;











 
contract GenesisProtocolLogic is IntVoteInterface {
    using SafeMath for uint256;
    using Math for uint256;
    using RealMath for uint216;
    using RealMath for uint256;
    using Address for address;

    enum ProposalState { None, ExpiredInQueue, Executed, Queued, PreBoosted, Boosted, QuietEndingPeriod}
    enum ExecutionState { None, QueueBarCrossed, QueueTimeOut, PreBoostedBarCrossed, BoostedTimeOut, BoostedBarCrossed}

     
    struct Parameters {
        uint256 queuedVoteRequiredPercentage;  
        uint256 queuedVotePeriodLimit;  
        uint256 boostedVotePeriodLimit;  
        uint256 preBoostedVotePeriodLimit;  
                                           
        uint256 thresholdConst;  
                                 
        uint256 limitExponentValue; 
                                    
        uint256 quietEndingPeriod;  
        uint256 proposingRepReward; 
        uint256 votersReputationLossRatio; 
                                           
        uint256 minimumDaoBounty;
        uint256 daoBountyConst; 
                                
        uint256 activationTime; 
         
        address voteOnBehalf;
    }

    struct Voter {
        uint256 vote;  
        uint256 reputation;  
        bool preBoosted;
    }

    struct Staker {
        uint256 vote;  
        uint256 amount;  
        uint256 amount4Bounty; 
    }

    struct Proposal {
        bytes32 organizationId;  
        address callbacks;     
        ProposalState state;
        uint256 winningVote;  
        address proposer;
         
        uint256 currentBoostedVotePeriodLimit;
        bytes32 paramsHash;
        uint256 daoBountyRemain;  
        uint256 daoBounty;
        uint256 totalStakes; 
        uint256 confidenceThreshold;
        uint256 secondsFromTimeOutTillExecuteBoosted;
        uint[3] times;  
                        
                        
        bool daoRedeemItsWinnings;
         
        mapping(uint256   =>  uint256    ) votes;
         
        mapping(uint256   =>  uint256    ) preBoostedVotes;
         
        mapping(address =>  Voter    ) voters;
         
        mapping(uint256   =>  uint256    ) stakes;
         
        mapping(address  => Staker   ) stakers;
    }

    event Stake(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _staker,
        uint256 _vote,
        uint256 _amount
    );

    event Redeem(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event RedeemDaoBounty(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event RedeemReputation(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event StateChange(bytes32 indexed _proposalId, ProposalState _proposalState);
    event GPExecuteProposal(bytes32 indexed _proposalId, ExecutionState _executionState);
    event ExpirationCallBounty(bytes32 indexed _proposalId, address indexed _beneficiary, uint256 _amount);
    event ConfidenceLevelChange(bytes32 indexed _proposalId, uint256 _confidenceThreshold);

    mapping(bytes32=>Parameters) public parameters;   
    mapping(bytes32=>Proposal) public proposals;  
    mapping(bytes32=>uint) public orgBoostedProposalsCnt;
            
    mapping(bytes32        => address     ) public organizations;
           
    mapping(bytes32           => uint256              ) public averagesDownstakesOfBoosted;
    uint256 constant public NUM_OF_CHOICES = 2;
    uint256 constant public NO = 2;
    uint256 constant public YES = 1;
    uint256 public proposalsCnt;  
    IERC20 public stakingToken;
    address constant private GEN_TOKEN_ADDRESS = 0x543Ff227F64Aa17eA132Bf9886cAb5DB55DCAddf;
    uint256 constant private MAX_BOOSTED_PROPOSALS = 4096;

     
    constructor(IERC20 _stakingToken) public {
       
       
       
       
       
        if (address(GEN_TOKEN_ADDRESS).isContract()) {
            stakingToken = IERC20(GEN_TOKEN_ADDRESS);
        } else {
            stakingToken = _stakingToken;
        }
    }

   
    modifier votable(bytes32 _proposalId) {
        require(_isVotable(_proposalId));
        _;
    }

     
    function propose(uint256, bytes32 _paramsHash, address _proposer, address _organization)
        external
        returns(bytes32)
    {
       
        require(now > parameters[_paramsHash].activationTime, "not active yet");
         
        require(parameters[_paramsHash].queuedVoteRequiredPercentage >= 50);
         
        bytes32 proposalId = keccak256(abi.encodePacked(this, proposalsCnt));
        proposalsCnt = proposalsCnt.add(1);
          
        Proposal memory proposal;
        proposal.callbacks = msg.sender;
        proposal.organizationId = keccak256(abi.encodePacked(msg.sender, _organization));

        proposal.state = ProposalState.Queued;
         
        proposal.times[0] = now; 
        proposal.currentBoostedVotePeriodLimit = parameters[_paramsHash].boostedVotePeriodLimit;
        proposal.proposer = _proposer;
        proposal.winningVote = NO;
        proposal.paramsHash = _paramsHash;
        if (organizations[proposal.organizationId] == address(0)) {
            if (_organization == address(0)) {
                organizations[proposal.organizationId] = msg.sender;
            } else {
                organizations[proposal.organizationId] = _organization;
            }
        }
         
        uint256 daoBounty =
        parameters[_paramsHash].daoBountyConst.mul(averagesDownstakesOfBoosted[proposal.organizationId]).div(100);
        proposal.daoBountyRemain = daoBounty.max(parameters[_paramsHash].minimumDaoBounty);
        proposals[proposalId] = proposal;
        proposals[proposalId].stakes[NO] = proposal.daoBountyRemain; 

        emit NewProposal(proposalId, organizations[proposal.organizationId], NUM_OF_CHOICES, _proposer, _paramsHash);
        return proposalId;
    }

     
    function executeBoosted(bytes32 _proposalId) external returns(uint256 expirationCallBounty) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Boosted || proposal.state == ProposalState.QuietEndingPeriod,
        "proposal state in not Boosted nor QuietEndingPeriod");
        require(_execute(_proposalId), "proposal need to expire");

        proposal.secondsFromTimeOutTillExecuteBoosted =
         
        now.sub(proposal.currentBoostedVotePeriodLimit.add(proposal.times[1]));

        expirationCallBounty = calcExecuteCallBounty(_proposalId);
        proposal.totalStakes = proposal.totalStakes.sub(expirationCallBounty);
        require(stakingToken.transfer(msg.sender, expirationCallBounty), "transfer to msg.sender failed");
        emit ExpirationCallBounty(_proposalId, msg.sender, expirationCallBounty);
    }

     
    function setParameters(
        uint[11] calldata _params,  
        address _voteOnBehalf
    )
    external
    returns(bytes32)
    {
        require(_params[0] <= 100 && _params[0] >= 50, "50 <= queuedVoteRequiredPercentage <= 100");
        require(_params[4] <= 16000 && _params[4] > 1000, "1000 < thresholdConst <= 16000");
        require(_params[7] <= 100, "votersReputationLossRatio <= 100");
        require(_params[2] >= _params[5], "boostedVotePeriodLimit >= quietEndingPeriod");
        require(_params[8] > 0, "minimumDaoBounty should be > 0");
        require(_params[9] > 0, "daoBountyConst should be > 0");

        bytes32 paramsHash = getParametersHash(_params, _voteOnBehalf);
         
        uint256 limitExponent = 172; 
        uint256 j = 2;
        for (uint256 i = 2000; i < 16000; i = i*2) {
            if ((_params[4] > i) && (_params[4] <= i*2)) {
                limitExponent = limitExponent/j;
                break;
            }
            j++;
        }

        parameters[paramsHash] = Parameters({
            queuedVoteRequiredPercentage: _params[0],
            queuedVotePeriodLimit: _params[1],
            boostedVotePeriodLimit: _params[2],
            preBoostedVotePeriodLimit: _params[3],
            thresholdConst:uint216(_params[4]).fraction(uint216(1000)),
            limitExponentValue:limitExponent,
            quietEndingPeriod: _params[5],
            proposingRepReward: _params[6],
            votersReputationLossRatio:_params[7],
            minimumDaoBounty:_params[8],
            daoBountyConst:_params[9],
            activationTime:_params[10],
            voteOnBehalf:_voteOnBehalf
        });
        return paramsHash;
    }

     
      
    function redeem(bytes32 _proposalId, address _beneficiary) public returns (uint[3] memory rewards) {
        Proposal storage proposal = proposals[_proposalId];
        require((proposal.state == ProposalState.Executed)||(proposal.state == ProposalState.ExpiredInQueue),
        "Proposal should be Executed or ExpiredInQueue");
        Parameters memory params = parameters[proposal.paramsHash];
         
        Staker storage staker = proposal.stakers[_beneficiary];
        uint256 totalWinningStakes = proposal.stakes[proposal.winningVote];
        uint256 totalStakesLeftAfterCallBounty =
        proposal.stakes[NO].add(proposal.stakes[YES]).sub(calcExecuteCallBounty(_proposalId));
        if (staker.amount > 0) {

            if (proposal.state == ProposalState.ExpiredInQueue) {
                 
                rewards[0] = staker.amount;
            } else if (staker.vote == proposal.winningVote) {
                if (staker.vote == YES) {
                    if (proposal.daoBounty < totalStakesLeftAfterCallBounty) {
                        uint256 _totalStakes = totalStakesLeftAfterCallBounty.sub(proposal.daoBounty);
                        rewards[0] = (staker.amount.mul(_totalStakes))/totalWinningStakes;
                    }
                } else {
                    rewards[0] = (staker.amount.mul(totalStakesLeftAfterCallBounty))/totalWinningStakes;
                }
            }
            staker.amount = 0;
        }
             
        if (proposal.daoRedeemItsWinnings == false &&
            _beneficiary == organizations[proposal.organizationId] &&
            proposal.state != ProposalState.ExpiredInQueue &&
            proposal.winningVote == NO) {
            rewards[0] =
            rewards[0]
            .add((proposal.daoBounty.mul(totalStakesLeftAfterCallBounty))/totalWinningStakes)
            .sub(proposal.daoBounty);
            proposal.daoRedeemItsWinnings = true;
        }

         
        Voter storage voter = proposal.voters[_beneficiary];
        if ((voter.reputation != 0) && (voter.preBoosted)) {
            if (proposal.state == ProposalState.ExpiredInQueue) {
               
                rewards[1] = ((voter.reputation.mul(params.votersReputationLossRatio))/100);
            } else if (proposal.winningVote == voter.vote) {
                uint256 lostReputation;
                if (proposal.winningVote == YES) {
                    lostReputation = proposal.preBoostedVotes[NO];
                } else {
                    lostReputation = proposal.preBoostedVotes[YES];
                }
                lostReputation = (lostReputation.mul(params.votersReputationLossRatio))/100;
                rewards[1] = ((voter.reputation.mul(params.votersReputationLossRatio))/100)
                .add((voter.reputation.mul(lostReputation))/proposal.preBoostedVotes[proposal.winningVote]);
            }
            voter.reputation = 0;
        }
         
        if ((proposal.proposer == _beneficiary)&&(proposal.winningVote == YES)&&(proposal.proposer != address(0))) {
            rewards[2] = params.proposingRepReward;
            proposal.proposer = address(0);
        }
        if (rewards[0] != 0) {
            proposal.totalStakes = proposal.totalStakes.sub(rewards[0]);
            require(stakingToken.transfer(_beneficiary, rewards[0]), "transfer to beneficiary failed");
            emit Redeem(_proposalId, organizations[proposal.organizationId], _beneficiary, rewards[0]);
        }
        if (rewards[1].add(rewards[2]) != 0) {
            VotingMachineCallbacksInterface(proposal.callbacks)
            .mintReputation(rewards[1].add(rewards[2]), _beneficiary, _proposalId);
            emit RedeemReputation(
            _proposalId,
            organizations[proposal.organizationId],
            _beneficiary,
            rewards[1].add(rewards[2])
            );
        }
    }

     
    function redeemDaoBounty(bytes32 _proposalId, address _beneficiary)
    public
    returns(uint256 redeemedAmount, uint256 potentialAmount) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Executed);
        uint256 totalWinningStakes = proposal.stakes[proposal.winningVote];
        Staker storage staker = proposal.stakers[_beneficiary];
        if (
            (staker.amount4Bounty > 0)&&
            (staker.vote == proposal.winningVote)&&
            (proposal.winningVote == YES)&&
            (totalWinningStakes != 0)) {
             
                potentialAmount = (staker.amount4Bounty * proposal.daoBounty)/totalWinningStakes;
            }
        if ((potentialAmount != 0)&&
            (VotingMachineCallbacksInterface(proposal.callbacks)
            .balanceOfStakingToken(stakingToken, _proposalId) >= potentialAmount)) {
            staker.amount4Bounty = 0;
            proposal.daoBountyRemain = proposal.daoBountyRemain.sub(potentialAmount);
            require(
            VotingMachineCallbacksInterface(proposal.callbacks)
            .stakingTokenTransfer(stakingToken, _beneficiary, potentialAmount, _proposalId));
            redeemedAmount = potentialAmount;
            emit RedeemDaoBounty(_proposalId, organizations[proposal.organizationId], _beneficiary, redeemedAmount);
        }
    }

     
    function calcExecuteCallBounty(bytes32 _proposalId) public view returns(uint256) {
        uint maxRewardSeconds = 1500;
        uint rewardSeconds =
        uint256(maxRewardSeconds).min(proposals[_proposalId].secondsFromTimeOutTillExecuteBoosted);
        return rewardSeconds.mul(proposals[_proposalId].stakes[YES]).div(maxRewardSeconds*10);
    }

     
    function shouldBoost(bytes32 _proposalId) public view returns(bool) {
        Proposal memory proposal = proposals[_proposalId];
        return (_score(_proposalId) > threshold(proposal.paramsHash, proposal.organizationId));
    }

     
    function threshold(bytes32 _paramsHash, bytes32 _organizationId) public view returns(uint256) {
        uint256 power = orgBoostedProposalsCnt[_organizationId];
        Parameters storage params = parameters[_paramsHash];

        if (power > params.limitExponentValue) {
            power = params.limitExponentValue;
        }

        return params.thresholdConst.pow(power);
    }

   
    function getParametersHash(
        uint[11] memory _params, 
        address _voteOnBehalf
    )
        public
        pure
        returns(bytes32)
        {
         
        return keccak256(
            abi.encodePacked(
            keccak256(
            abi.encodePacked(
                _params[0],
                _params[1],
                _params[2],
                _params[3],
                _params[4],
                _params[5],
                _params[6],
                _params[7],
                _params[8],
                _params[9],
                _params[10])
            ),
            _voteOnBehalf
        ));
    }

     
      
    function _execute(bytes32 _proposalId) internal votable(_proposalId) returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        Proposal memory tmpProposal = proposal;
        uint256 totalReputation =
        VotingMachineCallbacksInterface(proposal.callbacks).getTotalReputationSupply(_proposalId);
         
        uint256 executionBar = (totalReputation/100) * params.queuedVoteRequiredPercentage;
        ExecutionState executionState = ExecutionState.None;
        uint256 averageDownstakesOfBoosted;
        uint256 confidenceThreshold;

        if (proposal.votes[proposal.winningVote] > executionBar) {
          
            if (proposal.state == ProposalState.Queued) {
                executionState = ExecutionState.QueueBarCrossed;
            } else if (proposal.state == ProposalState.PreBoosted) {
                executionState = ExecutionState.PreBoostedBarCrossed;
            } else {
                executionState = ExecutionState.BoostedBarCrossed;
            }
            proposal.state = ProposalState.Executed;
        } else {
            if (proposal.state == ProposalState.Queued) {
                 
                if ((now - proposal.times[0]) >= params.queuedVotePeriodLimit) {
                    proposal.state = ProposalState.ExpiredInQueue;
                    proposal.winningVote = NO;
                    executionState = ExecutionState.QueueTimeOut;
                } else {
                    confidenceThreshold = threshold(proposal.paramsHash, proposal.organizationId);
                    if (_score(_proposalId) > confidenceThreshold) {
                         
                        proposal.state = ProposalState.PreBoosted;
                         
                        proposal.times[2] = now;
                        proposal.confidenceThreshold = confidenceThreshold;
                    }
                }
            }

            if (proposal.state == ProposalState.PreBoosted) {
                confidenceThreshold = threshold(proposal.paramsHash, proposal.organizationId);
               
                if ((now - proposal.times[2]) >= params.preBoostedVotePeriodLimit) {
                    if (_score(_proposalId) > confidenceThreshold) {
                        if (orgBoostedProposalsCnt[proposal.organizationId] < MAX_BOOSTED_PROPOSALS) {
                          
                            proposal.state = ProposalState.Boosted;
                          
                            proposal.times[1] = now;
                            orgBoostedProposalsCnt[proposal.organizationId]++;
                          
                            averageDownstakesOfBoosted = averagesDownstakesOfBoosted[proposal.organizationId];
                           
                            averagesDownstakesOfBoosted[proposal.organizationId] =
                                uint256(int256(averageDownstakesOfBoosted) +
                                ((int256(proposal.stakes[NO])-int256(averageDownstakesOfBoosted))/
                                int256(orgBoostedProposalsCnt[proposal.organizationId])));
                        }
                    } else {
                        proposal.state = ProposalState.Queued;
                    }
                } else {  
                    uint256 proposalScore = _score(_proposalId);
                    if (proposalScore <= proposal.confidenceThreshold.min(confidenceThreshold)) {
                        proposal.state = ProposalState.Queued;
                    } else if (proposal.confidenceThreshold > proposalScore) {
                        proposal.confidenceThreshold = confidenceThreshold;
                        emit ConfidenceLevelChange(_proposalId, confidenceThreshold);
                    }
                }
            }
        }

        if ((proposal.state == ProposalState.Boosted) ||
            (proposal.state == ProposalState.QuietEndingPeriod)) {
             
            if ((now - proposal.times[1]) >= proposal.currentBoostedVotePeriodLimit) {
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.BoostedTimeOut;
            }
        }

        if (executionState != ExecutionState.None) {
            if ((executionState == ExecutionState.BoostedTimeOut) ||
                (executionState == ExecutionState.BoostedBarCrossed)) {
                orgBoostedProposalsCnt[tmpProposal.organizationId] =
                orgBoostedProposalsCnt[tmpProposal.organizationId].sub(1);
                 
                uint256 boostedProposals = orgBoostedProposalsCnt[tmpProposal.organizationId];
                if (boostedProposals == 0) {
                    averagesDownstakesOfBoosted[proposal.organizationId] = 0;
                } else {
                    averageDownstakesOfBoosted = averagesDownstakesOfBoosted[proposal.organizationId];
                    averagesDownstakesOfBoosted[proposal.organizationId] =
                    (averageDownstakesOfBoosted.mul(boostedProposals+1).sub(proposal.stakes[NO]))/boostedProposals;
                }
            }
            emit ExecuteProposal(
            _proposalId,
            organizations[proposal.organizationId],
            proposal.winningVote,
            totalReputation
            );
            emit GPExecuteProposal(_proposalId, executionState);
            ProposalExecuteInterface(proposal.callbacks).executeProposal(_proposalId, int(proposal.winningVote));
            proposal.daoBounty = proposal.daoBountyRemain;
        }
        if (tmpProposal.state != proposal.state) {
            emit StateChange(_proposalId, proposal.state);
        }
        return (executionState != ExecutionState.None);
    }

     
    function _stake(bytes32 _proposalId, uint256 _vote, uint256 _amount, address _staker) internal returns(bool) {
         
        require(_vote <= NUM_OF_CHOICES && _vote > 0, "wrong vote value");
        require(_amount > 0, "staking amount should be >0");

        if (_execute(_proposalId)) {
            return true;
        }
        Proposal storage proposal = proposals[_proposalId];

        if ((proposal.state != ProposalState.PreBoosted) &&
            (proposal.state != ProposalState.Queued)) {
            return false;
        }

         
        Staker storage staker = proposal.stakers[_staker];
        if ((staker.amount > 0) && (staker.vote != _vote)) {
            return false;
        }

        uint256 amount = _amount;
        require(stakingToken.transferFrom(_staker, address(this), amount), "fail transfer from staker");
        proposal.totalStakes = proposal.totalStakes.add(amount);  
        staker.amount = staker.amount.add(amount);
         
         
        require(staker.amount <= 0x100000000000000000000000000000000, "staking amount is too high");
        require(proposal.totalStakes <= uint256(0x100000000000000000000000000000000).sub(proposal.daoBountyRemain),
                "total stakes is too high");

        if (_vote == YES) {
            staker.amount4Bounty = staker.amount4Bounty.add(amount);
        }
        staker.vote = _vote;

        proposal.stakes[_vote] = amount.add(proposal.stakes[_vote]);
        emit Stake(_proposalId, organizations[proposal.organizationId], _staker, _vote, _amount);
        return _execute(_proposalId);
    }

     
      
    function internalVote(bytes32 _proposalId, address _voter, uint256 _vote, uint256 _rep) internal returns(bool) {
        require(_vote <= NUM_OF_CHOICES && _vote > 0, "0 < _vote <= 2");
        if (_execute(_proposalId)) {
            return true;
        }

        Parameters memory params = parameters[proposals[_proposalId].paramsHash];
        Proposal storage proposal = proposals[_proposalId];

         
        uint256 reputation = VotingMachineCallbacksInterface(proposal.callbacks).reputationOf(_voter, _proposalId);
        require(reputation > 0, "_voter must have reputation");
        require(reputation >= _rep, "reputation >= _rep");
        uint256 rep = _rep;
        if (rep == 0) {
            rep = reputation;
        }
         
        if (proposal.voters[_voter].reputation != 0) {
            return false;
        }
         
        proposal.votes[_vote] = rep.add(proposal.votes[_vote]);
         
         
        if ((proposal.votes[_vote] > proposal.votes[proposal.winningVote]) ||
            ((proposal.votes[NO] == proposal.votes[proposal.winningVote]) &&
            proposal.winningVote == YES)) {
            if (proposal.state == ProposalState.Boosted &&
             
                ((now - proposal.times[1]) >= (params.boostedVotePeriodLimit - params.quietEndingPeriod))||
                proposal.state == ProposalState.QuietEndingPeriod) {
                 
                if (proposal.state != ProposalState.QuietEndingPeriod) {
                    proposal.currentBoostedVotePeriodLimit = params.quietEndingPeriod;
                    proposal.state = ProposalState.QuietEndingPeriod;
                    emit StateChange(_proposalId, proposal.state);
                }
                 
                proposal.times[1] = now;
            }
            proposal.winningVote = _vote;
        }
        proposal.voters[_voter] = Voter({
            reputation: rep,
            vote: _vote,
            preBoosted:((proposal.state == ProposalState.PreBoosted) || (proposal.state == ProposalState.Queued))
        });
        if ((proposal.state == ProposalState.PreBoosted) || (proposal.state == ProposalState.Queued)) {
            proposal.preBoostedVotes[_vote] = rep.add(proposal.preBoostedVotes[_vote]);
            uint256 reputationDeposit = (params.votersReputationLossRatio.mul(rep))/100;
            VotingMachineCallbacksInterface(proposal.callbacks).burnReputation(reputationDeposit, _voter, _proposalId);
        }
        emit VoteProposal(_proposalId, organizations[proposal.organizationId], _voter, _vote, rep);
        return _execute(_proposalId);
    }

     
    function _score(bytes32 _proposalId) internal view returns(uint256) {
        Proposal storage proposal = proposals[_proposalId];
         
        return uint216(proposal.stakes[YES]).fraction(uint216(proposal.stakes[NO]));
    }

     
    function _isVotable(bytes32 _proposalId) internal view returns(bool) {
        ProposalState pState = proposals[_proposalId].state;
        return ((pState == ProposalState.PreBoosted)||
                (pState == ProposalState.Boosted)||
                (pState == ProposalState.QuietEndingPeriod)||
                (pState == ProposalState.Queued)
        );
    }
}

 

pragma solidity ^0.5.4;




 
contract GenesisProtocol is IntVoteInterface, GenesisProtocolLogic {
    using ECDSA for bytes32;

     
     
    bytes32 public constant DELEGATION_HASH_EIP712 =
    keccak256(abi.encodePacked(
    "address GenesisProtocolAddress",
    "bytes32 ProposalId",
    "uint256 Vote",
    "uint256 AmountToStake",
    "uint256 Nonce"
    ));

    mapping(address=>uint256) public stakesNonce;  

     
    constructor(IERC20 _stakingToken)
    public
     
    GenesisProtocolLogic(_stakingToken) {
    }

     
    function stake(bytes32 _proposalId, uint256 _vote, uint256 _amount) external returns(bool) {
        return _stake(_proposalId, _vote, _amount, msg.sender);
    }

     
    function stakeWithSignature(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 _amount,
        uint256 _nonce,
        uint256 _signatureType,
        bytes calldata _signature
        )
        external
        returns(bool)
        {
         
        bytes32 delegationDigest;
        if (_signatureType == 2) {
            delegationDigest = keccak256(
                abi.encodePacked(
                    DELEGATION_HASH_EIP712, keccak256(
                        abi.encodePacked(
                        address(this),
                        _proposalId,
                        _vote,
                        _amount,
                        _nonce)
                    )
                )
            );
        } else {
            delegationDigest = keccak256(
                        abi.encodePacked(
                        address(this),
                        _proposalId,
                        _vote,
                        _amount,
                        _nonce)
                    ).toEthSignedMessageHash();
        }
        address staker = delegationDigest.recover(_signature);
         
        require(staker != address(0), "staker address cannot be 0");
        require(stakesNonce[staker] == _nonce);
        stakesNonce[staker] = stakesNonce[staker].add(1);
        return _stake(_proposalId, _vote, _amount, staker);
    }

     
    function vote(bytes32 _proposalId, uint256 _vote, uint256 _amount, address _voter)
    external
    votable(_proposalId)
    returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        address voter;
        if (params.voteOnBehalf != address(0)) {
            require(msg.sender == params.voteOnBehalf);
            voter = _voter;
        } else {
            voter = msg.sender;
        }
        return internalVote(_proposalId, voter, _vote, _amount);
    }

   
    function cancelVote(bytes32 _proposalId) external votable(_proposalId) {
        
        return;
    }

     
    function execute(bytes32 _proposalId) external votable(_proposalId) returns(bool) {
        return _execute(_proposalId);
    }

   
    function getNumberOfChoices(bytes32) external view returns(uint256) {
        return NUM_OF_CHOICES;
    }

     
    function getProposalTimes(bytes32 _proposalId) external view returns(uint[3] memory times) {
        return proposals[_proposalId].times;
    }

     
    function voteInfo(bytes32 _proposalId, address _voter) external view returns(uint, uint) {
        Voter memory voter = proposals[_proposalId].voters[_voter];
        return (voter.vote, voter.reputation);
    }

     
    function voteStatus(bytes32 _proposalId, uint256 _choice) external view returns(uint256) {
        return proposals[_proposalId].votes[_choice];
    }

     
    function isVotable(bytes32 _proposalId) external view returns(bool) {
        return _isVotable(_proposalId);
    }

     
    function proposalStatus(bytes32 _proposalId) external view returns(uint256, uint256, uint256, uint256) {
        return (
                proposals[_proposalId].preBoostedVotes[YES],
                proposals[_proposalId].preBoostedVotes[NO],
                proposals[_proposalId].stakes[YES],
                proposals[_proposalId].stakes[NO]
        );
    }

   
    function getProposalOrganization(bytes32 _proposalId) external view returns(bytes32) {
        return (proposals[_proposalId].organizationId);
    }

     
    function getStaker(bytes32 _proposalId, address _staker) external view returns(uint256, uint256) {
        return (proposals[_proposalId].stakers[_staker].vote, proposals[_proposalId].stakers[_staker].amount);
    }

     
    function voteStake(bytes32 _proposalId, uint256 _vote) external view returns(uint256) {
        return proposals[_proposalId].stakes[_vote];
    }

   
    function winningVote(bytes32 _proposalId) external view returns(uint256) {
        return proposals[_proposalId].winningVote;
    }

     
    function state(bytes32 _proposalId) external view returns(ProposalState) {
        return proposals[_proposalId].state;
    }

    
    function isAbstainAllow() external pure returns(bool) {
        return false;
    }

     
    function getAllowedRangeOfChoices() external pure returns(uint256 min, uint256 max) {
        return (YES, NO);
    }

     
    function score(bytes32 _proposalId) public view returns(uint256) {
        return  _score(_proposalId);
    }
}