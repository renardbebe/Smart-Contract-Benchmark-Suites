 

pragma solidity ^0.4.19;


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


contract SVLightBallotBox {
     

     
    address public owner;

     
    bool public testMode = false;

     
    struct Ballot {
        bytes32 ballotData;
        address sender;
         
         
        uint32 blockN;
    }

     
     
    mapping (uint256 => Ballot) public ballotMap;
    mapping (uint256 => bytes32) public associatedPubkeys;
    uint256 public nVotesCast = 0;

     
    mapping (address => uint256) public voterToBallotID;

     
     
     

     
    bytes32 public ballotEncryptionSeckey;
    bool seckeyRevealed = false;

     
    uint64 public startTime;
    uint64 public endTime;
    uint64 public creationBlock;
    uint64 public startingBlockAround;

     
    bytes32 public specHash;
    bool public useEncryption;

     
    bool public deprecated = false;

     
    event CreatedBallot(address _creator, uint64[2] _openPeriod, bool _useEncryption, bytes32 _specHash);
    event SuccessfulPkVote(address voter, bytes32 ballot, bytes32 pubkey);
    event SuccessfulVote(address voter, bytes32 ballot);
    event SeckeyRevealed(bytes32 secretKey);
    event TestingEnabled();
    event Error(string error);
    event DeprecatedContract();
    event SetOwner(address _owner);


     

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier ballotOpen {
        require(uint64(block.timestamp) >= startTime && uint64(block.timestamp) < endTime);
        _;
    }

    modifier onlyTesting {
        require(testMode);
        _;
    }

    modifier isTrue(bool _b) {
        require(_b == true);
        _;
    }

    modifier isFalse(bool _b) {
        require(_b == false);
        _;
    }

     

    uint16 constant F_USE_ENC = 0;
    uint16 constant F_TESTING = 1;
     
     
     
    function SVLightBallotBox(bytes32 _specHash, uint64[2] openPeriod, bool[2] flags) public {
        owner = msg.sender;

         
         
        startTime = max(openPeriod[0], uint64(block.timestamp));
        endTime = openPeriod[1];
        useEncryption = flags[F_USE_ENC];
        specHash = _specHash;
        creationBlock = uint64(block.number);
         
        startingBlockAround = uint64((startTime - block.timestamp) / 15 + block.number);

        if (flags[F_TESTING]) {
            testMode = true;
            TestingEnabled();
        }

        CreatedBallot(msg.sender, [startTime, endTime], useEncryption, specHash);
    }

     
    function submitBallotWithPk(bytes32 encryptedBallot, bytes32 senderPubkey) isTrue(useEncryption) ballotOpen public {
        addBallotAndVoterWithPk(encryptedBallot, senderPubkey);
        SuccessfulPkVote(msg.sender, encryptedBallot, senderPubkey);
    }

    function submitBallotNoPk(bytes32 ballot) isFalse(useEncryption) ballotOpen public {
        addBallotAndVoterNoPk(ballot);
        SuccessfulVote(msg.sender, ballot);
    }

     
    function addBallotAndVoterWithPk(bytes32 encryptedBallot, bytes32 senderPubkey) internal {
        uint256 ballotNumber = addBallotAndVoterNoPk(encryptedBallot);
        associatedPubkeys[ballotNumber] = senderPubkey;
    }

    function addBallotAndVoterNoPk(bytes32 encryptedBallot) internal returns (uint256) {
        uint256 ballotNumber = nVotesCast;
        ballotMap[ballotNumber] = Ballot(encryptedBallot, msg.sender, uint32(block.number));
        voterToBallotID[msg.sender] = ballotNumber;
        nVotesCast += 1;
        return ballotNumber;
    }

     
    function revealSeckey(bytes32 _secKey) onlyOwner public {
        require(block.timestamp > endTime);

        ballotEncryptionSeckey = _secKey;
        seckeyRevealed = true;  
        SeckeyRevealed(_secKey);
    }

    function getEncSeckey() public constant returns (bytes32) {
        return ballotEncryptionSeckey;
    }

     
    function setEndTime(uint64 newEndTime) onlyTesting onlyOwner public {
        endTime = newEndTime;
    }

    function setDeprecated() onlyOwner public {
        deprecated = true;
        DeprecatedContract();
    }

    function setOwner(address newOwner) onlyOwner public {
        owner = newOwner;
        SetOwner(newOwner);
    }

     
    function max(uint64 a, uint64 b) pure internal returns(uint64) {
        if (a > b) {
            return a;
        }
        return b;
    }
}


 
 
 
 
 

contract SVLightIndexShim {

    address public owner;

    struct Ballot {
        bytes32 specHash;
        bytes32 extraData;
        address votingContract;
        uint64 startTs;
    }

    struct Democ {
        string name;
        address admin;
        Ballot[] ballots;
    }

    mapping (bytes32 => Democ) public democs;
    bytes32[] public democList;

    bool public paymentEnabled = false;

    SVLightIndexShim prevIndex;

     

    event PaymentMade(uint128[2] valAndRemainder);
    event DemocInit(string name, bytes32 democHash, address admin);
    event BallotInit(bytes32 specHash, uint64[2] openPeriod, bool[2] flags);
    event BallotAdded(bytes32 democHash, bytes32 specHash, bytes32 extraData, address votingContract);
    event SetFees(uint128[2] _newFees);
    event PaymentEnabled(bool _feeEnabled);

     

    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

     


     
    constructor(SVLightIndexShim _prevIndex) public {
        owner = msg.sender;
        prevIndex = _prevIndex;

        bytes32 democHash;
        bytes32 specHash;
        bytes32 extraData;
        address votingContract;
        uint64 startTime;

        for (uint i = 0; i < prevIndex.nDemocs(); i++) {
            democHash = prevIndex.democList(i);
            democList.push(democHash);
             
            democs[democHash].admin = msg.sender;

            for (uint j = 0; j < prevIndex.nBallots(democHash); j++) {
                (specHash, extraData, votingContract, startTime) = prevIndex.getNthBallot(democHash, j);
                democs[democHash].ballots.push(Ballot(specHash, extraData, votingContract, startTime));
            }
        }
    }

     

    function nDemocs() public constant returns (uint256) {
        return democList.length;
    }

     

    function setOwner(address _owner) onlyBy(owner) public {
        owner = _owner;
    }

    function setDemocAdminEmergency(bytes32 democHash, address newAdmin) onlyBy(owner) public {
        democs[democHash].admin = newAdmin;
    }

     

    function getDemocInfo(bytes32 democHash) public constant returns (string name, address admin, uint256 nBallots) {
         
        return ("SWM Governance", democs[democHash].admin, democs[democHash].ballots.length);
    }

    function setAdmin(bytes32 democHash, address newAdmin) onlyBy(democs[democHash].admin) public {
        democs[democHash].admin = newAdmin;
    }

    function nBallots(bytes32 democHash) public constant returns (uint256) {
        return democs[democHash].ballots.length;
    }

    function getNthBallot(bytes32 democHash, uint256 n) public constant returns (bytes32 specHash, bytes32 extraData, address votingContract, uint64 startTime) {
        return (democs[democHash].ballots[n].specHash, democs[democHash].ballots[n].extraData, democs[democHash].ballots[n].votingContract, democs[democHash].ballots[n].startTs);
    }

     

    function _commitBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, address votingContract, uint64 startTs) internal {
        democs[democHash].ballots.push(Ballot(specHash, extraData, votingContract, startTs));
        BallotAdded(democHash, specHash, extraData, votingContract);
    }

    function addBallot(bytes32 democHash, bytes32 extraData, address votingContract)
                      onlyBy(democs[democHash].admin)
                      public
                      {
        SVLightBallotBox bb = SVLightBallotBox(votingContract);
        bytes32 specHash = bb.specHash();
        uint64 startTs = bb.startTime();
        _commitBallot(democHash, specHash, extraData, votingContract, startTs);
    }

    function deployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData,
                          uint64[2] openPeriod, bool[2] flags)
                          onlyBy(democs[democHash].admin)
                          public payable {
         
         
        uint64 startTs = max(openPeriod[0], uint64(block.timestamp));
        SVLightBallotBox votingContract = new SVLightBallotBox(specHash, [startTs, openPeriod[1]], flags);
        votingContract.setOwner(msg.sender);
        _commitBallot(democHash, specHash, extraData, address(votingContract), startTs);
        BallotInit(specHash, [startTs, openPeriod[1]], flags);
    }

     
    function max(uint64 a, uint64 b) pure internal returns(uint64) {
        if (a > b) {
            return a;
        }
        return b;
    }
}