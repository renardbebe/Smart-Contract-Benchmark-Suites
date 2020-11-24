 

pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


contract SwarmVotingMVP {
     

     
    address public owner;

     
    bool public testMode = false;

     
     
    mapping(uint256 => bytes32) public encryptedBallots;
    mapping(uint256 => bytes32) public associatedPubkeys;
    mapping(uint256 => address) public associatedAddresses;
    uint256 public nVotesCast = 0;

     
    mapping(address => uint256) public voterToBallotID;

     
    bytes32 public ballotEncryptionPubkey;

     
    bytes32 public ballotEncryptionSeckey;
    bool seckeyRevealed = false;

     
    uint256 public startTime;
    uint256 public endTime;

     
    mapping(address => bool) public bannedAddresses;
     
    address public swarmFundAddress = 0x8Bf7b2D536D286B9c5Ad9d99F608e9E214DE63f0;


     
    event CreatedBallot(address creator, uint256 start, uint256 end, bytes32 encPubkey);
    event FailedVote(address voter, string reason);
    event SuccessfulVote(address voter, bytes32 ballot, bytes32 pubkey);
    event SeckeyRevealed(bytes32 secretKey);
    event TestingEnabled();
    event Error(string error);


     

    modifier notBanned {
        if (!bannedAddresses[msg.sender]) {   
            _;
        } else {
            Error("Banned address");
        }
    }

    modifier onlyOwner {
        if (msg.sender == owner) {   
            _;
        } else {
            Error("Not owner");
        }
    }

    modifier ballotOpen {
        if (block.timestamp > startTime && block.timestamp < endTime) {
            _;
        } else {
            Error("Ballot not open");
        }
    }

    modifier onlyTesting {
        if (testMode) {
            _;
        } else {
            Error("Testing disabled");
        }
    }

     

     
    function SwarmVotingMVP(uint256 _startTime, uint256 _endTime, bytes32 _encPK, bool enableTesting) public {
        owner = msg.sender;

        startTime = _startTime;
        endTime = _endTime;
        ballotEncryptionPubkey = _encPK;

        bannedAddresses[swarmFundAddress] = true;

        if (enableTesting) {
            testMode = true;
            TestingEnabled();
        }
    }

     
    function submitBallot(bytes32 encryptedBallot, bytes32 senderPubkey) notBanned ballotOpen public {
        addBallotAndVoter(encryptedBallot, senderPubkey);
    }

     
    function addBallotAndVoter(bytes32 encryptedBallot, bytes32 senderPubkey) internal {
        uint256 ballotNumber = nVotesCast;
        encryptedBallots[ballotNumber] = encryptedBallot;
        associatedPubkeys[ballotNumber] = senderPubkey;
        associatedAddresses[ballotNumber] = msg.sender;
        voterToBallotID[msg.sender] = ballotNumber;
        nVotesCast += 1;
        SuccessfulVote(msg.sender, encryptedBallot, senderPubkey);
    }

     
    function revealSeckey(bytes32 _secKey) onlyOwner public {
        require(block.timestamp > endTime);

        ballotEncryptionSeckey = _secKey;
        seckeyRevealed = true;   
        SeckeyRevealed(_secKey);
    }

     
    function getEncPubkey() public constant returns (bytes32) {
        return ballotEncryptionPubkey;
    }

    function getEncSeckey() public constant returns (bytes32) {
        return ballotEncryptionSeckey;
    }

    function getBallotOptions() public pure returns (uint8[2][4]) {
         
         
        return [
            [8, 42],
            [42, 8],
            [16, 42],
            [4, 84]
        ];
    }
    
     
    function getBallotOptNumber() public pure returns (uint256) {
        return 4;
    }

     
    function setEndTime(uint256 newEndTime) onlyTesting onlyOwner public {
        endTime = newEndTime;
    }

    function banAddress(address _addr) onlyTesting onlyOwner public {
        bannedAddresses[_addr] = true;
    }
}