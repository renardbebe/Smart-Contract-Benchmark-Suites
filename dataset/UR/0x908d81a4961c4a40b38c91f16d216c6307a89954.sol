 

 

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

 

pragma solidity 0.5.8;

 
library MerkleProof {
     
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash < proofElement) {
                 
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                 
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
         
        return computedHash == root;
    }
}

 

pragma solidity 0.5.8;



 
contract V12Voting {
    using SafeMath for uint256;

     
    bytes32 constant public NO_CHANGE = 0x9c7e52ebd85b19725c2fa45fea14ef32d24aa2665b667e9be796bb2811b936fc;
     
    bytes32 constant public DUAL_TOKEN = 0x0524f98cf62601e849aa545adff164c0f9b0303697043eddaf6d59d4fb4e4736;
     
    bytes32 constant public TX_SPLIT = 0x84501b56c2648bdca07999c3b30e6edba0fa8c3178028b395e92f9bb53b4beba;

     
    mapping(bytes32 => bool) public votingOption;

     
    string public ipfs;

     
    mapping (address => bytes32) public votes;
    mapping (bytes32 => uint256) public votingResult;

     
    uint256 public expirationDate;

     
    bytes32 public merkleTreeRoot;

     
    event NewVote(address indexed who, string vote, uint256 amount);

     
    constructor(
      bytes32 _merkleTreeRoot,
      string memory _ipfs,
      uint256 _expirationDate
    ) public {
        require(_expirationDate > block.timestamp, "wrong expiration date");
        merkleTreeRoot = _merkleTreeRoot;
        ipfs = _ipfs;
        expirationDate = _expirationDate;

        votingOption[NO_CHANGE] = true;
        votingOption[DUAL_TOKEN] = true;
        votingOption[TX_SPLIT] = true;
    }

     
    function vote(string calldata _vote, uint256 _amount, bytes32[] calldata _proof) external {
        require(canVote(msg.sender), "already voted");
        require(isVotingOpen(), "voting finished");
        bytes32 hashOfVote = keccak256(abi.encodePacked(_vote));
        require(votingOption[hashOfVote], "invalid vote option");
        bytes32 _leaf = keccak256(abi.encodePacked(keccak256(abi.encode(msg.sender, _amount))));
        require(verify(_proof, merkleTreeRoot, _leaf), "the proof is wrong");

        votes[msg.sender] = hashOfVote;
        votingResult[hashOfVote] = votingResult[hashOfVote].add(_amount);

        emit NewVote(msg.sender, _vote, _amount);
    }

     
    function votingPercentages(uint256 _expectedVotingAmount) external view returns(
        uint256 noChangePercent,
        uint256 noChangeVotes,
        uint256 dualTokenPercent,
        uint256 dualTokenVotes,
        uint256 txSplitPercent,
        uint256 txSplitVotes,
        uint256 totalVoted,
        uint256 turnoutPercent
    ) {
        noChangeVotes = votingResult[NO_CHANGE];
        dualTokenVotes = votingResult[DUAL_TOKEN];
        txSplitVotes = votingResult[TX_SPLIT];
        totalVoted = noChangeVotes.add(dualTokenVotes).add(txSplitVotes);

        uint256 oneHundredPercent = 10000;
        noChangePercent = noChangeVotes.mul(oneHundredPercent).div(totalVoted);
        dualTokenPercent = dualTokenVotes.mul(oneHundredPercent).div(totalVoted);
        txSplitPercent = oneHundredPercent.sub(noChangePercent).sub(dualTokenPercent);

        turnoutPercent = totalVoted.mul(oneHundredPercent).div(_expectedVotingAmount);

    }

     
    function isVotingOpen() public view returns(bool) {
        return block.timestamp <= expirationDate;
    }

     
    function canVote(address _who) public view returns(bool) {
        return votes[_who] == bytes32(0);
    }

     
    function verify(bytes32[] memory _proof, bytes32 _root, bytes32 _leaf) public pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf);
    }
}