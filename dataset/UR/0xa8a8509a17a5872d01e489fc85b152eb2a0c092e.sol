 

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


 
 
 
 
 

contract SVLightIndex {

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

     
    mapping (address => bool) public democWhitelist;
     
    mapping (address => bool) public ballotWhitelist;

     
    address public payTo;
     
    uint128 public democFee = 0.05 ether;  
    mapping (address => uint128) democFeeFor;
    uint128 public ballotFee = 0.01 ether;  
    mapping (address => uint128) ballotFeeFor;
    bool public paymentEnabled = true;

    uint8 constant PAY_DEMOC = 0;
    uint8 constant PAY_BALLOT = 1;

    function getPaymentParams(uint8 paymentType) internal constant returns (bool, uint128, uint128) {
        if (paymentType == PAY_DEMOC) {
            return (democWhitelist[msg.sender], democFee, democFeeFor[msg.sender]);
        } else if (paymentType == PAY_BALLOT) {
            return (ballotWhitelist[msg.sender], ballotFee, ballotFeeFor[msg.sender]);
        } else {
            assert(false);
        }
    }

     

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

    modifier payReq(uint8 paymentType) {
         
        bool wl;
        uint128 genFee;
        uint128 feeFor;
        (wl, genFee, feeFor) = getPaymentParams(paymentType);
         
        uint128 v = 1000 ether;
         
        if (paymentEnabled && !wl) {
            v = feeFor;
            if (v == 0){
                 
                v = genFee;
            }
            require(msg.value >= v);

             
            uint128 remainder = uint128(msg.value) - v;
            payTo.transfer(v);  
            if (!msg.sender.send(remainder)){
                payTo.transfer(remainder);
            }
            PaymentMade([v, remainder]);
        }

         
        _;
    }


     


     
    function SVLightIndex() public {
        owner = msg.sender;
        payTo = msg.sender;
    }

     

    function nDemocs() public constant returns (uint256) {
        return democList.length;
    }

     

    function setPayTo(address newPayTo) onlyBy(owner) public {
        payTo = newPayTo;
    }

    function setEth(uint128[2] newFees) onlyBy(owner) public {
        democFee = newFees[PAY_DEMOC];
        ballotFee = newFees[PAY_BALLOT];
        SetFees([democFee, ballotFee]);
    }

    function setOwner(address _owner) onlyBy(owner) public {
        owner = _owner;
    }

    function setPaymentEnabled(bool _enabled) onlyBy(owner) public {
        paymentEnabled = _enabled;
        PaymentEnabled(_enabled);
    }

    function setWhitelistDemoc(address addr, bool _free) onlyBy(owner) public {
        democWhitelist[addr] = _free;
    }

    function setWhitelistBallot(address addr, bool _free) onlyBy(owner) public {
        ballotWhitelist[addr] = _free;
    }

    function setFeeFor(address addr, uint128[2] fees) onlyBy(owner) public {
        democFeeFor[addr] = fees[PAY_DEMOC];
        ballotFeeFor[addr] = fees[PAY_BALLOT];
    }

     

    function initDemoc(string democName) payReq(PAY_DEMOC) public payable returns (bytes32) {
        bytes32 democHash = keccak256(democName, msg.sender, democList.length, this);
        democList.push(democHash);
        democs[democHash].name = democName;
        democs[democHash].admin = msg.sender;
        DemocInit(democName, democHash, msg.sender);
        return democHash;
    }

    function getDemocInfo(bytes32 democHash) public constant returns (string name, address admin, uint256 nBallots) {
        return (democs[democHash].name, democs[democHash].admin, democs[democHash].ballots.length);
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
                      payReq(PAY_BALLOT)
                      public
                      payable
                      {
        SVLightBallotBox bb = SVLightBallotBox(votingContract);
        bytes32 specHash = bb.specHash();
        uint64 startTs = bb.startTime();
        _commitBallot(democHash, specHash, extraData, votingContract, startTs);
    }

    function deployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData,
                          uint64[2] openPeriod, bool[2] flags)
                          onlyBy(democs[democHash].admin)
                          payReq(PAY_BALLOT)
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