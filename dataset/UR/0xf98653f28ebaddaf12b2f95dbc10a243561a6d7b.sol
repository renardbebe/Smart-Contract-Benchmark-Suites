 

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.4;



 

contract Reputation is Ownable {

    uint8 public decimals = 18;              
     
    event Mint(address indexed _to, uint256 _amount);
     
    event Burn(address indexed _from, uint256 _amount);

       
       
       
    struct Checkpoint {

     
        uint128 fromBlock;

           
        uint128 value;
    }

       
       
       
    mapping (address => Checkpoint[]) balances;

       
    Checkpoint[] totalSupplyHistory;

     
    constructor(
    ) public
    {
    }

     
     
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }

   
   
   
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

       
       
       
       
    function balanceOfAt(address _owner, uint256 _blockNumber)
    public view returns (uint256)
    {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
           
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

       
       
       
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
           
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

       
       
       
       
    function mint(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint256 previousBalanceTo = balanceOf(_user);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_user], previousBalanceTo + _amount);
        emit Mint(_user, _amount);
        return true;
    }

       
       
       
       
    function burn(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        uint256 amountBurned = _amount;
        uint256 previousBalanceFrom = balanceOf(_user);
        if (previousBalanceFrom < amountBurned) {
            amountBurned = previousBalanceFrom;
        }
        updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
        updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
        emit Burn(_user, amountBurned);
        return true;
    }

   
   
   

       
       
       
       
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) {
            return 0;
        }

           
        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

           
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

       
       
       
       
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value) internal {
        require(uint128(_value) == _value);  
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
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

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.4;







contract AbsoluteVote is IntVoteInterface {
    using SafeMath for uint;

    struct Parameters {
        uint256 precReq;  
        address voteOnBehalf;  
                               
    }

    struct Voter {
        uint256 vote;  
        uint256 reputation;  
    }

    struct Proposal {
        bytes32 organizationId;  
        bool open;  
        address callbacks;
        uint256 numOfChoices;
        bytes32 paramsHash;  
        uint256 totalVotes;
        mapping(uint=>uint) votes;
        mapping(address=>Voter) voters;
    }

    event AVVoteProposal(bytes32 indexed _proposalId, bool _isProxyVote);

    mapping(bytes32=>Parameters) public parameters;   
    mapping(bytes32=>Proposal) public proposals;  
    mapping(bytes32=>address) public organizations;

    uint256 public constant MAX_NUM_OF_CHOICES = 10;
    uint256 public proposalsCnt;  

   
    modifier votable(bytes32 _proposalId) {
        require(proposals[_proposalId].open);
        _;
    }

     
    function propose(uint256 _numOfChoices, bytes32 _paramsHash, address, address _organization)
        external
        returns(bytes32)
    {
         
        require(parameters[_paramsHash].precReq > 0);
        require(_numOfChoices > 0 && _numOfChoices <= MAX_NUM_OF_CHOICES);
         
        bytes32 proposalId = keccak256(abi.encodePacked(this, proposalsCnt));
        proposalsCnt = proposalsCnt.add(1);
         
        Proposal memory proposal;
        proposal.numOfChoices = _numOfChoices;
        proposal.paramsHash = _paramsHash;
        proposal.callbacks = msg.sender;
        proposal.organizationId = keccak256(abi.encodePacked(msg.sender, _organization));
        proposal.open = true;
        proposals[proposalId] = proposal;
        if (organizations[proposal.organizationId] == address(0)) {
            if (_organization == address(0)) {
                organizations[proposal.organizationId] = msg.sender;
            } else {
                organizations[proposal.organizationId] = _organization;
            }
        }
        emit NewProposal(proposalId, organizations[proposal.organizationId], _numOfChoices, msg.sender, _paramsHash);
        return proposalId;
    }

     
    function vote(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 _amount,
        address _voter)
        external
        votable(_proposalId)
        returns(bool)
        {

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
        cancelVoteInternal(_proposalId, msg.sender);
    }

     
    function execute(bytes32 _proposalId) external votable(_proposalId) returns(bool) {
        return _execute(_proposalId);
    }

   
    function getNumberOfChoices(bytes32 _proposalId) external view returns(uint256) {
        return proposals[_proposalId].numOfChoices;
    }

   
    function voteInfo(bytes32 _proposalId, address _voter) external view returns(uint, uint) {
        Voter memory voter = proposals[_proposalId].voters[_voter];
        return (voter.vote, voter.reputation);
    }

     
    function voteStatus(bytes32 _proposalId, uint256 _choice) external view returns(uint256) {
        return proposals[_proposalId].votes[_choice];
    }

     
    function isVotable(bytes32 _proposalId) external view returns(bool) {
        return  proposals[_proposalId].open;
    }

     
    function isAbstainAllow() external pure returns(bool) {
        return true;
    }

     
    function getAllowedRangeOfChoices() external pure returns(uint256 min, uint256 max) {
        return (0, MAX_NUM_OF_CHOICES);
    }

     
    function setParameters(uint256 _precReq, address _voteOnBehalf) public returns(bytes32) {
        require(_precReq <= 100 && _precReq > 0);
        bytes32 hashedParameters = getParametersHash(_precReq, _voteOnBehalf);
        parameters[hashedParameters] = Parameters({
            precReq: _precReq,
            voteOnBehalf: _voteOnBehalf
        });
        return hashedParameters;
    }

     
    function getParametersHash(uint256 _precReq, address _voteOnBehalf) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_precReq, _voteOnBehalf));
    }

    function cancelVoteInternal(bytes32 _proposalId, address _voter) internal {
        Proposal storage proposal = proposals[_proposalId];
        Voter memory voter = proposal.voters[_voter];
        proposal.votes[voter.vote] = (proposal.votes[voter.vote]).sub(voter.reputation);
        proposal.totalVotes = (proposal.totalVotes).sub(voter.reputation);
        delete proposal.voters[_voter];
        emit CancelVoting(_proposalId, organizations[proposal.organizationId], _voter);
    }

    function deleteProposal(bytes32 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        for (uint256 cnt = 0; cnt <= proposal.numOfChoices; cnt++) {
            delete proposal.votes[cnt];
        }
        delete proposals[_proposalId];
    }

     
    function _execute(bytes32 _proposalId) internal votable(_proposalId) returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalReputation =
        VotingMachineCallbacksInterface(proposal.callbacks).getTotalReputationSupply(_proposalId);
        uint256 precReq = parameters[proposal.paramsHash].precReq;
         
        for (uint256 cnt = 0; cnt <= proposal.numOfChoices; cnt++) {
            if (proposal.votes[cnt] > (totalReputation/100)*precReq) {
                Proposal memory tmpProposal = proposal;
                deleteProposal(_proposalId);
                emit ExecuteProposal(_proposalId, organizations[tmpProposal.organizationId], cnt, totalReputation);
                return ProposalExecuteInterface(tmpProposal.callbacks).executeProposal(_proposalId, int(cnt));
            }
        }
        return false;
    }

     
    function internalVote(bytes32 _proposalId, address _voter, uint256 _vote, uint256 _rep) internal returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
         
        require(_vote <= proposal.numOfChoices);
         
        uint256 reputation = VotingMachineCallbacksInterface(proposal.callbacks).reputationOf(_voter, _proposalId);
        require(reputation > 0, "_voter must have reputation");
        require(reputation >= _rep);
        uint256 rep = _rep;
        if (rep == 0) {
            rep = reputation;
        }
         
        if (proposal.voters[_voter].reputation != 0) {
            cancelVoteInternal(_proposalId, _voter);
        }
         
        proposal.votes[_vote] = rep.add(proposal.votes[_vote]);
        proposal.totalVotes = rep.add(proposal.totalVotes);
        proposal.voters[_voter] = Voter({
            reputation: rep,
            vote: _vote
        });
         
        emit VoteProposal(_proposalId, organizations[proposal.organizationId], _voter, _vote, rep);
        emit AVVoteProposal(_proposalId, (_voter != msg.sender));
         
        return _execute(_proposalId);
    }
}

 

pragma solidity ^0.5.4;




contract QuorumVote is AbsoluteVote {
     
    function execute(bytes32 _proposalId) external votable(_proposalId) returns(bool) {
        return _execute(_proposalId);
    }

     
    function _execute(bytes32 _proposalId) internal votable(_proposalId) returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalReputation =
        VotingMachineCallbacksInterface(proposal.callbacks).getTotalReputationSupply(_proposalId);
        uint256 precReq = parameters[proposal.paramsHash].precReq;

         
        if (proposal.totalVotes > (totalReputation/100)*precReq) {
            uint256 max;
            uint256 maxInd;
            for (uint256 cnt = 0; cnt <= proposal.numOfChoices; cnt++) {
                if (proposal.votes[cnt] > max) {
                    max = proposal.votes[cnt];
                    maxInd = cnt;
                }
            }
            Proposal memory tmpProposal = proposal;
            deleteProposal(_proposalId);
            emit ExecuteProposal(_proposalId, organizations[tmpProposal.organizationId], maxInd, totalReputation);
            ProposalExecuteInterface(tmpProposal.callbacks).executeProposal(_proposalId, int(maxInd));
            return true;
        }
        return false;
    }
}