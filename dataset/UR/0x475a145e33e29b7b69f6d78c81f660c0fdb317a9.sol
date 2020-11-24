 

pragma solidity 0.5.10;



 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 
contract Governance {
    using SafeMath for uint256;

    mapping(bytes32 => Proposal) public proposals;
    bytes32[] public proposalsHashes;
    uint256 public proposalsCount;

    mapping(address => bool) public isVoter;
    address[] public voters;
    uint256 public votersCount;

    struct Proposal {
        bool finished;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) votedFor;
        mapping(address => bool) votedAgainst;
        address targetContract;
        bytes transaction;
    }

    event ProposalStarted(bytes32 proposalHash);
    event ProposalFinished(bytes32 proposalHash);
    event ProposalExecuted(bytes32 proposalHash);
    event Vote(bytes32 proposalHash, bool vote, uint256 yesVotes, uint256 noVotes, uint256 votersCount);
    event VoterAdded(address voter);
    event VoterDeleted(address voter);

     
    constructor() public {
        voters.push(msg.sender);
        isVoter[msg.sender] = true;
        proposalsCount = 0;
        votersCount = 1;
    }

     
    modifier onlyVoter() {
        require(isVoter[msg.sender], "Should be voter");
        _;
    }

     
    modifier onlyMe() {
        require(msg.sender == address(this), "Call only via Governance");
        _;
    }

     
    function newProposal( address _targetContract, bytes memory _transaction ) public onlyVoter {
        require(_targetContract != address(0), "Address must be non-zero");
        require(_transaction.length >= 4, "Tx must be 4+ bytes");
         
        bytes32 _proposalHash = keccak256(abi.encodePacked(_targetContract, _transaction, now));
        require(proposals[_proposalHash].transaction.length == 0, "The poll has already been initiated");
        proposals[_proposalHash].targetContract = _targetContract;
        proposals[_proposalHash].transaction = _transaction;
        proposalsHashes.push(_proposalHash);
        proposalsCount = proposalsCount.add(1);
        emit ProposalStarted(_proposalHash);
    }

     
    function vote(bytes32 _proposalHash, bool _yes) public onlyVoter {  
        require(!proposals[_proposalHash].finished, "Already finished");
        require(!proposals[_proposalHash].votedFor[msg.sender], "Already voted");
        require(!proposals[_proposalHash].votedAgainst[msg.sender], "Already voted");
        if (_yes) {
            proposals[_proposalHash].yesVotes = proposals[_proposalHash].yesVotes.add(1);
            proposals[_proposalHash].votedFor[msg.sender] = true;
        } else {
            proposals[_proposalHash].noVotes = proposals[_proposalHash].noVotes.add(1);
            proposals[_proposalHash].votedAgainst[msg.sender] = true;
        }
        emit Vote(
            _proposalHash,
            _yes,
            proposals[_proposalHash].yesVotes,
            proposals[_proposalHash].noVotes,
            votersCount
        );
        if (proposals[_proposalHash].yesVotes > votersCount.div(2)) {
            executeProposal(_proposalHash);
            finishProposal(_proposalHash);
        } else if (proposals[_proposalHash].noVotes >= (votersCount + 1).div(2)) {
            finishProposal(_proposalHash);
        }
    }

 
    function getVoted(bytes32 _proposalHash, address _address) public view returns (bool, bool) {
        bool isVoted = proposals[_proposalHash].votedFor[_address] ||
            proposals[_proposalHash].votedAgainst[_address];
        bool side = proposals[_proposalHash].votedFor[_address];
        return (isVoted, side);
    }

     
    function addVoter(address _address) public onlyMe {
        require(_address != address(0), "Need non-zero address");
        require(!isVoter[_address], "Already in voters list");
        voters.push(_address);
        isVoter[_address] = true;
        votersCount = votersCount.add(1);
        emit VoterAdded(_address);
    }

     
    function delVoter(address _address) public onlyMe {
        require(isVoter[_address], "Not in voters list");
        require(votersCount > 1, "Can not delete single voter");
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _address) {
                if (voters.length > 1) {
                    voters[i] = voters[voters.length - 1];
                }
                voters.length--;  
                isVoter[_address] = false;
                votersCount = votersCount.sub(1);
                emit VoterDeleted(_address);
                break;
            }
        }
    }

     
    function executeProposal(bytes32 _proposalHash) internal {
        require(!proposals[_proposalHash].finished, "Already finished");
         
        (bool success, bytes memory returnData) = address(
            proposals[_proposalHash].targetContract).call(proposals[_proposalHash].transaction
        );
        require(success, string(returnData));
        emit ProposalExecuted(_proposalHash);
    }

     
    function finishProposal(bytes32 _proposalHash) internal {
        require(!proposals[_proposalHash].finished, "Already finished");
        proposals[_proposalHash].finished = true;
        emit ProposalFinished(_proposalHash);
    }
}