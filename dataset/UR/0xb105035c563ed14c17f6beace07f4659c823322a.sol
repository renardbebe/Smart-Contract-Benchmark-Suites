 

pragma solidity 0.4.24;

contract BBFarmEvents {
    event BallotCreatedWithID(uint ballotId);
    event BBFarmInit(bytes4 namespace);
    event Sponsorship(uint ballotId, uint value);
    event Vote(uint indexed ballotId, bytes32 vote, address voter, bytes extra);
}

library BBLib {
    using BytesLib for bytes;

     
    uint256 constant BB_VERSION = 6;
     

     
    uint16 constant USE_ETH = 1;           
    uint16 constant USE_SIGNED = 2;        
    uint16 constant USE_NO_ENC = 4;        
    uint16 constant USE_ENC = 8;           

     
    uint16 constant IS_BINDING = 8192;     
    uint16 constant IS_OFFICIAL = 16384;   
    uint16 constant USE_TESTING = 32768;   

     
    uint32 constant MAX_UINT32 = 0xFFFFFFFF;

     

     
    struct Vote {
        bytes32 voteData;
        bytes32 castTsAndSender;
        bytes extra;
    }

    struct Sponsor {
        address sender;
        uint amount;
    }

     
    event CreatedBallot(bytes32 _specHash, uint64 startTs, uint64 endTs, uint16 submissionBits);
    event SuccessfulVote(address indexed voter, uint voteId);
    event SeckeyRevealed(bytes32 secretKey);
    event TestingEnabled();
    event DeprecatedContract();


     


    struct DB {
         
         
        mapping (uint256 => Vote) votes;
        uint256 nVotesCast;

         
         
         
        mapping (address => uint32) sequenceNumber;

         
         
         

         
        bytes32 ballotEncryptionSeckey;

         
         
         
        uint256 packed;

         
        bytes32 specHash;
         
        bytes16 extraData;

         
        Sponsor[] sponsors;
        IxIface index;

         
        bool deprecated;

        address ballotOwner;
        uint256 creationTs;
    }


     
    function requireBallotClosed(DB storage db) internal view {
        require(now > BPackedUtils.packedToEndTime(db.packed), "!b-closed");
    }

    function requireBallotOpen(DB storage db) internal view {
        uint64 _n = uint64(now);
        uint64 startTs;
        uint64 endTs;
        (, startTs, endTs) = BPackedUtils.unpackAll(db.packed);
        require(_n >= startTs && _n < endTs, "!b-open");
        require(db.deprecated == false, "b-deprecated");
    }

    function requireBallotOwner(DB storage db) internal view {
        require(msg.sender == db.ballotOwner, "!b-owner");
    }

    function requireTesting(DB storage db) internal view {
        require(isTesting(BPackedUtils.packedToSubmissionBits(db.packed)), "!testing");
    }

     

    function getVersion() external pure returns (uint) {
         
         
         
        return BB_VERSION;
    }

     

     
     
    function init(DB storage db, bytes32 _specHash, uint256 _packed, IxIface ix, address ballotOwner, bytes16 extraData) external {
        require(db.specHash == bytes32(0), "b-exists");

        db.index = ix;
        db.ballotOwner = ballotOwner;

        uint64 startTs;
        uint64 endTs;
        uint16 sb;
        (sb, startTs, endTs) = BPackedUtils.unpackAll(_packed);

        bool _testing = isTesting(sb);
        if (_testing) {
            emit TestingEnabled();
        } else {
            require(endTs > now, "bad-end-time");

             
             
             
             
            require(sb & 0x1ff2 == 0, "bad-sb");

             
            bool okaySubmissionBits = 1 == (isEthNoEnc(sb) ? 1 : 0) + (isEthWithEnc(sb) ? 1 : 0);
            require(okaySubmissionBits, "!valid-sb");

             
             
            startTs = startTs > now ? startTs : uint64(now);
        }
        require(_specHash != bytes32(0), "null-specHash");
        db.specHash = _specHash;

        db.packed = BPackedUtils.pack(sb, startTs, endTs);
        db.creationTs = now;

        if (extraData != bytes16(0)) {
            db.extraData = extraData;
        }

        emit CreatedBallot(db.specHash, startTs, endTs, sb);
    }

     

    function logSponsorship(DB storage db, uint value) internal {
        db.sponsors.push(Sponsor(msg.sender, value));
    }

     

    function getVote(DB storage db, uint id) internal view returns (bytes32 voteData, address sender, bytes extra, uint castTs) {
        return (db.votes[id].voteData, address(db.votes[id].castTsAndSender), db.votes[id].extra, uint(db.votes[id].castTsAndSender) >> 160);
    }

    function getSequenceNumber(DB storage db, address voter) internal view returns (uint32) {
        return db.sequenceNumber[voter];
    }

    function getTotalSponsorship(DB storage db) internal view returns (uint total) {
        for (uint i = 0; i < db.sponsors.length; i++) {
            total += db.sponsors[i].amount;
        }
    }

    function getSponsor(DB storage db, uint i) external view returns (address sender, uint amount) {
        sender = db.sponsors[i].sender;
        amount = db.sponsors[i].amount;
    }

     

     
     
     
     
    function submitVote(DB storage db, bytes32 voteData, bytes extra) external {
        _addVote(db, voteData, msg.sender, extra);
         
         
         
        if (db.sequenceNumber[msg.sender] != MAX_UINT32) {
             
            db.sequenceNumber[msg.sender] = MAX_UINT32;
        }
    }

     
    function submitProxyVote(DB storage db, bytes32[5] proxyReq, bytes extra) external returns (address voter) {
         
         

        bytes32 r = proxyReq[0];
        bytes32 s = proxyReq[1];
        uint8 v = uint8(proxyReq[2][0]);
         
         
        bytes31 proxyReq2 = bytes31(uint248(proxyReq[2]));
         
        bytes32 ballotId = proxyReq[3];
        bytes32 voteData = proxyReq[4];

         
        bytes memory signed = abi.encodePacked(proxyReq2, ballotId, voteData, extra);
        bytes32 msgHash = keccak256(signed);
         
        voter = ecrecover(msgHash, v, r, s);

         
         
         
        uint32 sequence = uint32(proxyReq2);   
        _proxyReplayProtection(db, voter, sequence);

        _addVote(db, voteData, voter, extra);
    }

    function _addVote(DB storage db, bytes32 voteData, address sender, bytes extra) internal returns (uint256 id) {
        requireBallotOpen(db);

        id = db.nVotesCast;
        db.votes[id].voteData = voteData;
         
        db.votes[id].castTsAndSender = bytes32(sender) ^ bytes32(now << 160);
        if (extra.length > 0) {
            db.votes[id].extra = extra;
        }
        db.nVotesCast += 1;
        emit SuccessfulVote(sender, id);
    }

    function _proxyReplayProtection(DB storage db, address voter, uint32 sequence) internal {
         
         
         
        require(db.sequenceNumber[voter] < sequence, "bad-sequence-n");
        db.sequenceNumber[voter] = sequence;
    }

     

    function setEndTime(DB storage db, uint64 newEndTime) external {
        uint16 sb;
        uint64 sTs;
        (sb, sTs,) = BPackedUtils.unpackAll(db.packed);
        db.packed = BPackedUtils.pack(sb, sTs, newEndTime);
    }

    function revealSeckey(DB storage db, bytes32 sk) internal {
        db.ballotEncryptionSeckey = sk;
        emit SeckeyRevealed(sk);
    }

     

     
    uint16 constant SETTINGS_MASK = 0xFFFF ^ USE_TESTING ^ IS_OFFICIAL ^ IS_BINDING;

    function isEthNoEnc(uint16 submissionBits) pure internal returns (bool) {
        return checkFlags(submissionBits, USE_ETH | USE_NO_ENC);
    }

    function isEthWithEnc(uint16 submissionBits) pure internal returns (bool) {
        return checkFlags(submissionBits, USE_ETH | USE_ENC);
    }

    function isOfficial(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & IS_OFFICIAL) == IS_OFFICIAL;
    }

    function isBinding(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & IS_BINDING) == IS_BINDING;
    }

    function isTesting(uint16 submissionBits) pure internal returns (bool) {
        return (submissionBits & USE_TESTING) == USE_TESTING;
    }

    function qualifiesAsCommunityBallot(uint16 submissionBits) pure internal returns (bool) {
         
         
         
        return (submissionBits & (IS_BINDING | IS_OFFICIAL | USE_ENC)) == 0;
    }

    function checkFlags(uint16 submissionBits, uint16 expected) pure internal returns (bool) {
         
        uint16 sBitsNoSettings = submissionBits & SETTINGS_MASK;
         
        return sBitsNoSettings == expected;
    }
}

library BPackedUtils {

     
    uint256 constant sbMask        = 0xffffffffffffffffffffffffffff0000ffffffffffffffffffffffffffffffff;
    uint256 constant startTimeMask = 0xffffffffffffffffffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 constant endTimeMask   = 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000;

    function packedToSubmissionBits(uint256 packed) internal pure returns (uint16) {
        return uint16(packed >> 128);
    }

    function packedToStartTime(uint256 packed) internal pure returns (uint64) {
        return uint64(packed >> 64);
    }

    function packedToEndTime(uint256 packed) internal pure returns (uint64) {
        return uint64(packed);
    }

    function unpackAll(uint256 packed) internal pure returns (uint16 submissionBits, uint64 startTime, uint64 endTime) {
        submissionBits = uint16(packed >> 128);
        startTime = uint64(packed >> 64);
        endTime = uint64(packed);
    }

    function pack(uint16 sb, uint64 st, uint64 et) internal pure returns (uint256 packed) {
        return uint256(sb) << 128 | uint256(st) << 64 | uint256(et);
    }

    function setSB(uint256 packed, uint16 newSB) internal pure returns (uint256) {
        return (packed & sbMask) | uint256(newSB) << 128;
    }

     
     
     

     
     
     
}

interface CommAuctionIface {
    function getNextPrice(bytes32 democHash) external view returns (uint);
    function noteBallotDeployed(bytes32 democHash) external;

     

    function upgradeMe(address newSC) external;
}

library IxLib {
     

     

    function getPayTo(IxIface ix) internal view returns (address) {
        return ix.getPayments().getPayTo();
    }

     

    function getBBFarmFromBallotID(IxIface ix, uint256 ballotId) internal view returns (BBFarmIface) {
        bytes4 bbNamespace = bytes4(ballotId >> 48);
        uint8 bbFarmId = ix.getBBFarmID(bbNamespace);
        return ix.getBBFarm(bbFarmId);
    }

     

    function getGDemocsN(IxIface ix) internal view returns (uint256) {
        return ix.getBackend().getGDemocsN();
    }

    function getGDemoc(IxIface ix, uint256 n) internal view returns (bytes32) {
        return ix.getBackend().getGDemoc(n);
    }

    function getGErc20ToDemocs(IxIface ix, address erc20) internal view returns (bytes32[] democHashes) {
        return ix.getBackend().getGErc20ToDemocs(erc20);
    }

     

    function accountInGoodStanding(IxIface ix, bytes32 democHash) internal view returns (bool) {
        return ix.getPayments().accountInGoodStanding(democHash);
    }

    function accountPremiumAndInGoodStanding(IxIface ix, bytes32 democHash) internal view returns (bool) {
        IxPaymentsIface payments = ix.getPayments();
        return payments.accountInGoodStanding(democHash) && payments.getPremiumStatus(democHash);
    }

    function payForDemocracy(IxIface ix, bytes32 democHash) internal {
        ix.getPayments().payForDemocracy.value(msg.value)(democHash);
    }

     

    function getDOwner(IxIface ix, bytes32 democHash) internal view returns (address) {
        return ix.getBackend().getDOwner(democHash);
    }

    function isDEditor(IxIface ix, bytes32 democHash, address editor) internal view returns (bool) {
        return ix.getBackend().isDEditor(democHash, editor);
    }

    function getDBallotsN(IxIface ix, bytes32 democHash) internal view returns (uint256) {
        return ix.getBackend().getDBallotsN(democHash);
    }

    function getDBallotID(IxIface ix, bytes32 democHash, uint256 n) internal view returns (uint256) {
        return ix.getBackend().getDBallotID(democHash, n);
    }

    function getDInfo(IxIface ix, bytes32 democHash) internal view returns (address erc20, address admin, uint256 _nBallots) {
        return ix.getBackend().getDInfo(democHash);
    }

    function getDErc20(IxIface ix, bytes32 democHash) internal view returns (address erc20) {
        return ix.getBackend().getDErc20(democHash);
    }

    function getDHash(IxIface ix, bytes13 prefix) internal view returns (bytes32) {
        return ix.getBackend().getDHash(prefix);
    }

    function getDCategoriesN(IxIface ix, bytes32 democHash) internal view returns (uint) {
        return ix.getBackend().getDCategoriesN(democHash);
    }

    function getDCategory(IxIface ix, bytes32 democHash, uint categoryId) internal view returns (bool, bytes32, bool, uint) {
        return ix.getBackend().getDCategory(democHash, categoryId);
    }

    function getDArbitraryData(IxIface ix, bytes32 democHash, bytes key) external view returns (bytes) {
        return ix.getBackend().getDArbitraryData(democHash, key);
    }
}

contract SVBallotConsts {
     
    uint16 constant USE_ETH = 1;           
    uint16 constant USE_SIGNED = 2;        
    uint16 constant USE_NO_ENC = 4;        
    uint16 constant USE_ENC = 8;           

     
    uint16 constant IS_BINDING = 8192;     
    uint16 constant IS_OFFICIAL = 16384;   
    uint16 constant USE_TESTING = 32768;   
}

contract safeSend {
    bool private txMutex3847834;

     
     
    function doSafeSend(address toAddr, uint amount) internal {
        doSafeSendWData(toAddr, "", amount);
    }

    function doSafeSendWData(address toAddr, bytes data, uint amount) internal {
        require(txMutex3847834 == false, "ss-guard");
        txMutex3847834 = true;
         
         
         
        require(toAddr.call.value(amount)(data), "ss-failed");
        txMutex3847834 = false;
    }
}

contract payoutAllC is safeSend {
    address private _payTo;

    event PayoutAll(address payTo, uint value);

    constructor(address initPayTo) public {
         
        assert(initPayTo != address(0));
        _payTo = initPayTo;
    }

    function _getPayTo() internal view returns (address) {
        return _payTo;
    }

    function _setPayTo(address newPayTo) internal {
        _payTo = newPayTo;
    }

    function payoutAll() external {
        address a = _getPayTo();
        uint bal = address(this).balance;
        doSafeSend(a, bal);
        emit PayoutAll(a, bal);
    }
}

contract payoutAllCSettable is payoutAllC {
    constructor (address initPayTo) payoutAllC(initPayTo) public {
    }

    function setPayTo(address) external;
    function getPayTo() external view returns (address) {
        return _getPayTo();
    }
}

contract owned {
    address public owner;

    event OwnerChanged(address newOwner);

    modifier only_owner() {
        require(msg.sender == owner, "only_owner: forbidden");
        _;
    }

    modifier owner_or(address addr) {
        require(msg.sender == addr || msg.sender == owner, "!owner-or");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address newOwner) only_owner() external {
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
}

contract CanReclaimToken is owned {

     
    function reclaimToken(ERC20Interface token) external only_owner {
        uint256 balance = token.balanceOf(this);
        require(token.approve(owner, balance));
    }

}

contract CommunityAuctionSimple is owned {
     
    uint public commBallotPriceWei = 1666666666000000;

    struct Record {
        bytes32 democHash;
        uint ts;
    }

    mapping (address => Record[]) public ballotLog;
    mapping (address => address) public upgrades;

    function getNextPrice(bytes32) external view returns (uint) {
        return commBallotPriceWei;
    }

    function noteBallotDeployed(bytes32 d) external {
        require(upgrades[msg.sender] == address(0));
        ballotLog[msg.sender].push(Record(d, now));
    }

    function upgradeMe(address newSC) external {
        require(upgrades[msg.sender] == address(0));
        upgrades[msg.sender] = newSC;
    }

    function getBallotLogN(address a) external view returns (uint) {
        return ballotLog[a].length;
    }

    function setPriceWei(uint newPrice) only_owner() external {
        commBallotPriceWei = newPrice;
    }
}

contract controlledIface {
    function controller() external view returns (address);
}

contract hasAdmins is owned {
    mapping (uint => mapping (address => bool)) admins;
    uint public currAdminEpoch = 0;
    bool public adminsDisabledForever = false;
    address[] adminLog;

    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed oldAdmin);
    event AdminEpochInc();
    event AdminDisabledForever();

    modifier only_admin() {
        require(adminsDisabledForever == false, "admins must not be disabled");
        require(isAdmin(msg.sender), "only_admin: forbidden");
        _;
    }

    constructor() public {
        _setAdmin(msg.sender, true);
    }

    function isAdmin(address a) view public returns (bool) {
        return admins[currAdminEpoch][a];
    }

    function getAdminLogN() view external returns (uint) {
        return adminLog.length;
    }

    function getAdminLog(uint n) view external returns (address) {
        return adminLog[n];
    }

    function upgradeMeAdmin(address newAdmin) only_admin() external {
         
        require(msg.sender != owner, "owner cannot upgrade self");
        _setAdmin(msg.sender, false);
        _setAdmin(newAdmin, true);
    }

    function setAdmin(address a, bool _givePerms) only_admin() external {
        require(a != msg.sender && a != owner, "cannot change your own (or owner's) permissions");
        _setAdmin(a, _givePerms);
    }

    function _setAdmin(address a, bool _givePerms) internal {
        admins[currAdminEpoch][a] = _givePerms;
        if (_givePerms) {
            emit AdminAdded(a);
            adminLog.push(a);
        } else {
            emit AdminRemoved(a);
        }
    }

     
    function incAdminEpoch() only_owner() external {
        currAdminEpoch++;
        admins[currAdminEpoch][msg.sender] = true;
        emit AdminEpochInc();
    }

     
     
    function disableAdminForever() internal {
        currAdminEpoch++;
        adminsDisabledForever = true;
        emit AdminDisabledForever();
    }
}

contract EnsOwnerProxy is hasAdmins {
    bytes32 public ensNode;
    ENSIface public ens;
    PublicResolver public resolver;

     
    constructor(bytes32 _ensNode, ENSIface _ens, PublicResolver _resolver) public {
        ensNode = _ensNode;
        ens = _ens;
        resolver = _resolver;
    }

    function setAddr(address addr) only_admin() external {
        _setAddr(addr);
    }

    function _setAddr(address addr) internal {
        resolver.setAddr(ensNode, addr);
    }

    function returnToOwner() only_owner() external {
        ens.setOwner(ensNode, owner);
    }

    function fwdToENS(bytes data) only_owner() external {
        require(address(ens).call(data), "fwding to ens failed");
    }

    function fwdToResolver(bytes data) only_owner() external {
        require(address(resolver).call(data), "fwding to resolver failed");
    }
}

contract permissioned is owned, hasAdmins {
    mapping (address => bool) editAllowed;
    bool public adminLockdown = false;

    event PermissionError(address editAddr);
    event PermissionGranted(address editAddr);
    event PermissionRevoked(address editAddr);
    event PermissionsUpgraded(address oldSC, address newSC);
    event SelfUpgrade(address oldSC, address newSC);
    event AdminLockdown();

    modifier only_editors() {
        require(editAllowed[msg.sender], "only_editors: forbidden");
        _;
    }

    modifier no_lockdown() {
        require(adminLockdown == false, "no_lockdown: check failed");
        _;
    }


    constructor() owned() hasAdmins() public {
    }


    function setPermissions(address e, bool _editPerms) no_lockdown() only_admin() external {
        editAllowed[e] = _editPerms;
        if (_editPerms)
            emit PermissionGranted(e);
        else
            emit PermissionRevoked(e);
    }

    function upgradePermissionedSC(address oldSC, address newSC) no_lockdown() only_admin() external {
        editAllowed[oldSC] = false;
        editAllowed[newSC] = true;
        emit PermissionsUpgraded(oldSC, newSC);
    }

     
    function upgradeMe(address newSC) only_editors() external {
        editAllowed[msg.sender] = false;
        editAllowed[newSC] = true;
        emit SelfUpgrade(msg.sender, newSC);
    }

    function hasPermissions(address a) public view returns (bool) {
        return editAllowed[a];
    }

    function doLockdown() external only_owner() no_lockdown() {
        disableAdminForever();
        adminLockdown = true;
        emit AdminLockdown();
    }
}

contract upgradePtr {
    address ptr = address(0);

    modifier not_upgraded() {
        require(ptr == address(0), "upgrade pointer is non-zero");
        _;
    }

    function getUpgradePointer() view external returns (address) {
        return ptr;
    }

    function doUpgradeInternal(address nextSC) internal {
        ptr = nextSC;
    }
}

interface ERC20Interface {
     
    function totalSupply() constant external returns (uint256 _totalSupply);

     
    function balanceOf(address _owner) constant external returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ixEvents {
    event PaymentMade(uint[2] valAndRemainder);
    event AddedBBFarm(uint8 bbFarmId);
    event SetBackend(bytes32 setWhat, address newSC);
    event DeprecatedBBFarm(uint8 bbFarmId);
    event CommunityBallot(bytes32 democHash, uint256 ballotId);
    event ManuallyAddedBallot(bytes32 democHash, uint256 ballotId, uint256 packed);
     
    event BallotCreatedWithID(uint ballotId);
    event BBFarmInit(bytes4 namespace);
}

contract ixBackendEvents {
    event NewDemoc(bytes32 democHash);
    event ManuallyAddedDemoc(bytes32 democHash, address erc20);
    event NewBallot(bytes32 indexed democHash, uint ballotN);
    event DemocOwnerSet(bytes32 indexed democHash, address owner);
    event DemocEditorSet(bytes32 indexed democHash, address editor, bool canEdit);
    event DemocEditorsWiped(bytes32 indexed democHash);
    event DemocErc20Set(bytes32 indexed democHash, address erc20);
    event DemocDataSet(bytes32 indexed democHash, bytes32 keyHash);
    event DemocCatAdded(bytes32 indexed democHash, uint catId);
    event DemocCatDeprecated(bytes32 indexed democHash, uint catId);
    event DemocCommunityBallotsEnabled(bytes32 indexed democHash, bool enabled);
    event DemocErc20OwnerClaimDisabled(bytes32 indexed democHash);
    event DemocClaimed(bytes32 indexed democHash);
    event EmergencyDemocOwner(bytes32 indexed democHash, address newOwner);
}

library SafeMath {
    function subToZero(uint a, uint b) internal pure returns (uint) {
        if (a < b) {   
            return 0;
        }
        return a - b;
    }
}

contract ixPaymentEvents {
    event UpgradedToPremium(bytes32 indexed democHash);
    event GrantedAccountTime(bytes32 indexed democHash, uint additionalSeconds, bytes32 ref);
    event AccountPayment(bytes32 indexed democHash, uint additionalSeconds);
    event SetCommunityBallotFee(uint amount);
    event SetBasicCentsPricePer30Days(uint amount);
    event SetPremiumMultiplier(uint8 multiplier);
    event DowngradeToBasic(bytes32 indexed democHash);
    event UpgradeToPremium(bytes32 indexed democHash);
    event SetExchangeRate(uint weiPerCent);
    event FreeExtension(bytes32 democHash);
    event SetBallotsPer30Days(uint amount);
    event SetFreeExtension(bytes32 democHash, bool hasFreeExt);
    event SetDenyPremium(bytes32 democHash, bool isPremiumDenied);
    event SetPayTo(address payTo);
    event SetMinorEditsAddr(address minorEditsAddr);
    event SetMinWeiForDInit(uint amount);
}

interface hasVersion {
    function getVersion() external pure returns (uint);
}

contract BBFarmIface is BBFarmEvents, permissioned, hasVersion, payoutAllC {
     

    function getNamespace() external view returns (bytes4);
    function getBBLibVersion() external view returns (uint256);
    function getNBallots() external view returns (uint256);

     

     
    function initBallot( bytes32 specHash
                       , uint256 packed
                       , IxIface ix
                       , address bbAdmin
                       , bytes24 extraData
                       ) external returns (uint ballotId);

     

    function sponsor(uint ballotId) external payable;

     

    function submitVote(uint ballotId, bytes32 vote, bytes extra) external;
    function submitProxyVote(bytes32[5] proxyReq, bytes extra) external;

     

    function getDetails(uint ballotId, address voter) external view returns
            ( bool hasVoted
            , uint nVotesCast
            , bytes32 secKey
            , uint16 submissionBits
            , uint64 startTime
            , uint64 endTime
            , bytes32 specHash
            , bool deprecated
            , address ballotOwner
            , bytes16 extraData);

    function getVote(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra);
    function getTotalSponsorship(uint ballotId) external view returns (uint);
    function getSponsorsN(uint ballotId) external view returns (uint);
    function getSponsor(uint ballotId, uint sponsorN) external view returns (address sender, uint amount);
    function getCreationTs(uint ballotId) external view returns (uint);

     
    function revealSeckey(uint ballotId, bytes32 sk) external;
    function setEndTime(uint ballotId, uint64 newEndTime) external;   
    function setDeprecated(uint ballotId) external;
    function setBallotOwner(uint ballotId, address newOwner) external;
}

contract BBFarm is BBFarmIface {
    using BBLib for BBLib.DB;
    using IxLib for IxIface;

     
    bytes4 constant NAMESPACE = 0x00000001;
     
    uint256 constant BALLOT_ID_MASK = 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint constant VERSION = 2;

    mapping (uint224 => BBLib.DB) dbs;
     
     
    uint nBallots = 0;

     

    modifier req_namespace(uint ballotId) {
         
        require(bytes4(ballotId >> 224) == NAMESPACE, "bad-namespace");
        _;
    }

     

    constructor() payoutAllC(msg.sender) public {
         
         
        assert(BBLib.getVersion() == 6);
        emit BBFarmInit(NAMESPACE);
    }

     

    function _getPayTo() internal view returns (address) {
        return owner;
    }

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

     

    function getNamespace() external view returns (bytes4) {
        return NAMESPACE;
    }

    function getBBLibVersion() external view returns (uint256) {
        return BBLib.getVersion();
    }

    function getNBallots() external view returns (uint256) {
        return nBallots;
    }

     

    function getDb(uint ballotId) internal view returns (BBLib.DB storage) {
         
        return dbs[uint224(ballotId)];
    }

     

    function initBallot( bytes32 specHash
                       , uint256 packed
                       , IxIface ix
                       , address bbAdmin
                       , bytes24 extraData
                ) only_editors() external returns (uint ballotId) {
         
        ballotId = uint224(specHash) ^ (uint256(NAMESPACE) << 224);
         
        getDb(ballotId).init(specHash, packed, ix, bbAdmin, bytes16(uint128(extraData)));
        nBallots += 1;

        emit BallotCreatedWithID(ballotId);
    }

     

    function sponsor(uint ballotId) external payable {
        BBLib.DB storage db = getDb(ballotId);
        db.logSponsorship(msg.value);
        doSafeSend(db.index.getPayTo(), msg.value);
        emit Sponsorship(ballotId, msg.value);
    }

     

    function submitVote(uint ballotId, bytes32 vote, bytes extra) req_namespace(ballotId) external {
        getDb(ballotId).submitVote(vote, extra);
        emit Vote(ballotId, vote, msg.sender, extra);
    }

    function submitProxyVote(bytes32[5] proxyReq, bytes extra) req_namespace(uint256(proxyReq[3])) external {
         
         
        uint ballotId = uint256(proxyReq[3]);
        address voter = getDb(ballotId).submitProxyVote(proxyReq, extra);
        bytes32 vote = proxyReq[4];
        emit Vote(ballotId, vote, voter, extra);
    }

     

     
     
    function getDetails(uint ballotId, address voter) external view returns
            ( bool hasVoted
            , uint nVotesCast
            , bytes32 secKey
            , uint16 submissionBits
            , uint64 startTime
            , uint64 endTime
            , bytes32 specHash
            , bool deprecated
            , address ballotOwner
            , bytes16 extraData) {
        BBLib.DB storage db = getDb(ballotId);
        uint packed = db.packed;
        return (
            db.getSequenceNumber(voter) > 0,
            db.nVotesCast,
            db.ballotEncryptionSeckey,
            BPackedUtils.packedToSubmissionBits(packed),
            BPackedUtils.packedToStartTime(packed),
            BPackedUtils.packedToEndTime(packed),
            db.specHash,
            db.deprecated,
            db.ballotOwner,
            db.extraData
        );
    }

    function getVote(uint ballotId, uint voteId) external view returns (bytes32 voteData, address sender, bytes extra) {
        (voteData, sender, extra, ) = getDb(ballotId).getVote(voteId);
    }

    function getSequenceNumber(uint ballotId, address voter) external view returns (uint32 sequence) {
        return getDb(ballotId).getSequenceNumber(voter);
    }

    function getTotalSponsorship(uint ballotId) external view returns (uint) {
        return getDb(ballotId).getTotalSponsorship();
    }

    function getSponsorsN(uint ballotId) external view returns (uint) {
        return getDb(ballotId).sponsors.length;
    }

    function getSponsor(uint ballotId, uint sponsorN) external view returns (address sender, uint amount) {
        return getDb(ballotId).getSponsor(sponsorN);
    }

    function getCreationTs(uint ballotId) external view returns (uint) {
        return getDb(ballotId).creationTs;
    }

     

     
    function revealSeckey(uint ballotId, bytes32 sk) external {
        BBLib.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.requireBallotClosed();
        db.revealSeckey(sk);
    }

     
    function setEndTime(uint ballotId, uint64 newEndTime) external {
        BBLib.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.requireTesting();
        db.setEndTime(newEndTime);
    }

    function setDeprecated(uint ballotId) external {
        BBLib.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.deprecated = true;
    }

    function setBallotOwner(uint ballotId, address newOwner) external {
        BBLib.DB storage db = getDb(ballotId);
        db.requireBallotOwner();
        db.ballotOwner = newOwner;
    }
}

contract IxIface is hasVersion,
                    ixPaymentEvents,
                    ixBackendEvents,
                    ixEvents,
                    SVBallotConsts,
                    owned,
                    CanReclaimToken,
                    upgradePtr,
                    payoutAllC {

     
    function addBBFarm(BBFarmIface bbFarm) external returns (uint8 bbFarmId);
    function setABackend(bytes32 toSet, address newSC) external;
    function deprecateBBFarm(uint8 bbFarmId, BBFarmIface _bbFarm) external;

     
    function getPayments() external view returns (IxPaymentsIface);
    function getBackend() external view returns (IxBackendIface);
    function getBBFarm(uint8 bbFarmId) external view returns (BBFarmIface);
    function getBBFarmID(bytes4 bbNamespace) external view returns (uint8 bbFarmId);
    function getCommAuction() external view returns (CommAuctionIface);

     
    function dInit(address defualtErc20, bool disableErc20OwnerClaim) external payable returns (bytes32);

     
    function setDEditor(bytes32 democHash, address editor, bool canEdit) external;
    function setDNoEditors(bytes32 democHash) external;
    function setDOwner(bytes32 democHash, address newOwner) external;
    function dOwnerErc20Claim(bytes32 democHash) external;
    function setDErc20(bytes32 democHash, address newErc20) external;
    function dAddCategory(bytes32 democHash, bytes32 categoryName, bool hasParent, uint parent) external;
    function dDeprecateCategory(bytes32 democHash, uint categoryId) external;
    function dUpgradeToPremium(bytes32 democHash) external;
    function dDowngradeToBasic(bytes32 democHash) external;
    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) external;
    function dDisableErc20OwnerClaim(bytes32 democHash) external;

     
     

     
     
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed) external;
    function dDeployCommunityBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint128 packedTimes) external payable;
    function dDeployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint256 packed) external payable;
}

contract SVIndex is IxIface {
    uint256 constant VERSION = 2;

     
    bytes4 constant OWNER_SIG = 0x8da5cb5b;
     
    bytes4 constant CONTROLLER_SIG = 0xf77c4791;

     

    IxBackendIface backend;
    IxPaymentsIface payments;
    EnsOwnerProxy public ensOwnerPx;
    BBFarmIface[] bbFarms;
    CommAuctionIface commAuction;
     
    mapping (bytes4 => uint8) bbFarmIdLookup;
    mapping (uint8 => bool) deprecatedBBFarms;

     

    modifier onlyDemocOwner(bytes32 democHash) {
        require(msg.sender == backend.getDOwner(democHash), "!d-owner");
        _;
    }

    modifier onlyDemocEditor(bytes32 democHash) {
        require(backend.isDEditor(democHash, msg.sender), "!d-editor");
        _;
    }

     

     
    constructor( IxBackendIface _b
               , IxPaymentsIface _pay
               , EnsOwnerProxy _ensOwnerPx
               , BBFarmIface _bbFarm0
               , CommAuctionIface _commAuction
               ) payoutAllC(msg.sender) public {
        backend = _b;
        payments = _pay;
        ensOwnerPx = _ensOwnerPx;
        _addBBFarm(0x0, _bbFarm0);
        commAuction = _commAuction;
    }

     

    function _getPayTo() internal view returns (address) {
        return payments.getPayTo();
    }

     

    function doUpgrade(address nextSC) only_owner() not_upgraded() external {
        doUpgradeInternal(nextSC);
        backend.upgradeMe(nextSC);
        payments.upgradeMe(nextSC);
        ensOwnerPx.setAddr(nextSC);
        ensOwnerPx.upgradeMeAdmin(nextSC);
        commAuction.upgradeMe(nextSC);

        for (uint i = 0; i < bbFarms.length; i++) {
            bbFarms[i].upgradeMe(nextSC);
        }
    }

    function _addBBFarm(bytes4 bbNamespace, BBFarmIface _bbFarm) internal returns (uint8 bbFarmId) {
        uint256 bbFarmIdLong = bbFarms.length;
        require(bbFarmIdLong < 2**8, "too-many-farms");
        bbFarmId = uint8(bbFarmIdLong);

        bbFarms.push(_bbFarm);
        bbFarmIdLookup[bbNamespace] = bbFarmId;
        emit AddedBBFarm(bbFarmId);
    }

     
    function addBBFarm(BBFarmIface bbFarm) only_owner() external returns (uint8 bbFarmId) {
        bytes4 bbNamespace = bbFarm.getNamespace();

        require(bbNamespace != bytes4(0), "bb-farm-namespace");
        require(bbFarmIdLookup[bbNamespace] == 0 && bbNamespace != bbFarms[0].getNamespace(), "bb-namespace-used");

        bbFarmId = _addBBFarm(bbNamespace, bbFarm);
    }

    function setABackend(bytes32 toSet, address newSC) only_owner() external {
        emit SetBackend(toSet, newSC);
        if (toSet == bytes32("payments")) {
            payments = IxPaymentsIface(newSC);
        } else if (toSet == bytes32("backend")) {
            backend = IxBackendIface(newSC);
        } else if (toSet == bytes32("commAuction")) {
            commAuction = CommAuctionIface(newSC);
        } else {
            revert("404");
        }
    }

    function deprecateBBFarm(uint8 bbFarmId, BBFarmIface _bbFarm) only_owner() external {
        require(address(_bbFarm) != address(0));
        require(bbFarms[bbFarmId] == _bbFarm);
        deprecatedBBFarms[bbFarmId] = true;
        emit DeprecatedBBFarm(bbFarmId);
    }

     

    function getPayments() external view returns (IxPaymentsIface) {
        return payments;
    }

    function getBackend() external view returns (IxBackendIface) {
        return backend;
    }

    function getBBFarm(uint8 bbFarmId) external view returns (BBFarmIface) {
        return bbFarms[bbFarmId];
    }

    function getBBFarmID(bytes4 bbNamespace) external view returns (uint8 bbFarmId) {
        return bbFarmIdLookup[bbNamespace];
    }

    function getCommAuction() external view returns (CommAuctionIface) {
        return commAuction;
    }

     

    function getVersion() external pure returns (uint256) {
        return VERSION;
    }

     

    function dInit(address defaultErc20, bool disableErc20OwnerClaim) not_upgraded() external payable returns (bytes32) {
        require(msg.value >= payments.getMinWeiForDInit());
        bytes32 democHash = backend.dInit(defaultErc20, msg.sender, disableErc20OwnerClaim);
        payments.payForDemocracy.value(msg.value)(democHash);
        return democHash;
    }

     

    function setDEditor(bytes32 democHash, address editor, bool canEdit) onlyDemocOwner(democHash) external {
        backend.setDEditor(democHash, editor, canEdit);
    }

    function setDNoEditors(bytes32 democHash) onlyDemocOwner(democHash) external {
        backend.setDNoEditors(democHash);
    }

    function setDOwner(bytes32 democHash, address newOwner) onlyDemocOwner(democHash) external {
        backend.setDOwner(democHash, newOwner);
    }

    function dOwnerErc20Claim(bytes32 democHash) external {
        address erc20 = backend.getDErc20(democHash);
         
         
         
        if (erc20.call.gas(3000)(OWNER_SIG)) {
            require(msg.sender == owned(erc20).owner.gas(3000)(), "!erc20-owner");
        } else if (erc20.call.gas(3000)(CONTROLLER_SIG)) {
            require(msg.sender == controlledIface(erc20).controller.gas(3000)(), "!erc20-controller");
        } else {
            revert();
        }
         
        backend.setDOwnerFromClaim(democHash, msg.sender);
    }

    function setDErc20(bytes32 democHash, address newErc20) onlyDemocOwner(democHash) external {
        backend.setDErc20(democHash, newErc20);
    }

    function dAddCategory(bytes32 democHash, bytes32 catName, bool hasParent, uint parent) onlyDemocEditor(democHash) external {
        backend.dAddCategory(democHash, catName, hasParent, parent);
    }

    function dDeprecateCategory(bytes32 democHash, uint catId) onlyDemocEditor(democHash) external {
        backend.dDeprecateCategory(democHash, catId);
    }

    function dUpgradeToPremium(bytes32 democHash) onlyDemocOwner(democHash) external {
        payments.upgradeToPremium(democHash);
    }

    function dDowngradeToBasic(bytes32 democHash) onlyDemocOwner(democHash) external {
        payments.downgradeToBasic(democHash);
    }

    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external {
        if (msg.sender == backend.getDOwner(democHash)) {
            backend.dSetArbitraryData(democHash, key, value);
        } else if (backend.isDEditor(democHash, msg.sender)) {
            backend.dSetEditorArbitraryData(democHash, key, value);
        } else {
            revert();
        }
    }

    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) onlyDemocOwner(democHash) external {
        backend.dSetCommunityBallotsEnabled(democHash, enabled);
    }

     
    function dDisableErc20OwnerClaim(bytes32 democHash) onlyDemocOwner(democHash) external {
        backend.dDisableErc20OwnerClaim(democHash);
    }

     
     
     
     
     

     

     
     
     
     
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed)
                      only_owner()
                      external {

        _addBallot(democHash, ballotId, packed, false);
        emit ManuallyAddedBallot(democHash, ballotId, packed);
    }


    function _deployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint packed, bool checkLimit, bool alreadySentTx) internal returns (uint ballotId) {
        require(BBLib.isTesting(BPackedUtils.packedToSubmissionBits(packed)) == false, "b-testing");

         
        uint8 bbFarmId = uint8(extraData[0]);
        require(deprecatedBBFarms[bbFarmId] == false, "bb-dep");
        BBFarmIface _bbFarm = bbFarms[bbFarmId];

         
         
         
         
         
        bool countTowardsLimit = checkLimit;
        bool performedSend;
        if (checkLimit) {
            uint64 endTime = BPackedUtils.packedToEndTime(packed);
            (countTowardsLimit, performedSend) = _basicBallotLimitOperations(democHash, _bbFarm);
            _accountOkayChecks(democHash, endTime);
        }

        if (!performedSend && msg.value > 0 && alreadySentTx == false) {
             
            doSafeSend(msg.sender, msg.value);
        }

        ballotId = _bbFarm.initBallot(
            specHash,
            packed,
            this,
            msg.sender,
             
             
             
             
            bytes24(uint192(extraData)));

        _addBallot(democHash, ballotId, packed, countTowardsLimit);
    }

    function dDeployCommunityBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint128 packedTimes) external payable {
        uint price = commAuction.getNextPrice(democHash);
        require(msg.value >= price, "!cb-fee");

        doSafeSend(payments.getPayTo(), price);
        doSafeSend(msg.sender, msg.value - price);

        bool canProceed = backend.getDCommBallotsEnabled(democHash) || !payments.accountInGoodStanding(democHash);
        require(canProceed, "!cb-enabled");

        uint256 packed = BPackedUtils.setSB(uint256(packedTimes), (USE_ETH | USE_NO_ENC));

        uint ballotId = _deployBallot(democHash, specHash, extraData, packed, false, true);
        commAuction.noteBallotDeployed(democHash);

        emit CommunityBallot(democHash, ballotId);
    }

     
    function dDeployBallot(bytes32 democHash, bytes32 specHash, bytes32 extraData, uint256 packed)
                          onlyDemocEditor(democHash)
                          external payable {

        _deployBallot(democHash, specHash, extraData, packed, true, false);
    }

     
    function _addBallot(bytes32 democHash, uint256 ballotId, uint256 packed, bool countTowardsLimit) internal {
         
        backend.dAddBallot(democHash, ballotId, packed, countTowardsLimit);
    }

     
    function _accountOkayChecks(bytes32 democHash, uint64 endTime) internal view {
         
         
        uint secsLeft = payments.getSecondsRemaining(democHash);
         
        uint256 secsToEndTime = endTime - now;
         
        require(secsLeft * 2 > secsToEndTime, "unpaid");
    }

    function _basicBallotLimitOperations(bytes32 democHash, BBFarmIface _bbFarm) internal returns (bool shouldCount, bool performedSend) {
         
         
        if (payments.getPremiumStatus(democHash) == false) {
            uint nBallotsAllowed = payments.getBasicBallotsPer30Days();
            uint nBallotsBasicCounted = backend.getDCountedBasicBallotsN(democHash);

             
            if (nBallotsAllowed > nBallotsBasicCounted) {
                 
                return (true, false);
            }

             
             
             
             
             
             
             
            uint earlyBallotId = backend.getDCountedBasicBallotID(democHash, nBallotsBasicCounted - nBallotsAllowed);
            uint earlyBallotTs = _bbFarm.getCreationTs(earlyBallotId);

             
             
            if (earlyBallotTs < now - 30 days) {
                return (true, false);
            }

             
             
             
             
            uint extraBallotFee = payments.getBasicExtraBallotFeeWei();
            require(msg.value >= extraBallotFee, "!extra-b-fee");

             
             
            uint remainder = msg.value - extraBallotFee;
            doSafeSend(address(payments), extraBallotFee);
            doSafeSend(msg.sender, remainder);
            emit PaymentMade([extraBallotFee, remainder]);
             
             
            return (false, true);

        } else {   
            return (false, false);
        }
    }
}

contract IxBackendIface is hasVersion, ixBackendEvents, permissioned, payoutAllC {
     
    function getGDemocsN() external view returns (uint);
    function getGDemoc(uint id) external view returns (bytes32);
    function getGErc20ToDemocs(address erc20) external view returns (bytes32[] democHashes);

     
    function dAdd(bytes32 democHash, address erc20, bool disableErc20OwnerClaim) external;
    function emergencySetDOwner(bytes32 democHash, address newOwner) external;

     
    function dInit(address defaultErc20, address initOwner, bool disableErc20OwnerClaim) external returns (bytes32 democHash);
    function setDOwner(bytes32 democHash, address newOwner) external;
    function setDOwnerFromClaim(bytes32 democHash, address newOwner) external;
    function setDEditor(bytes32 democHash, address editor, bool canEdit) external;
    function setDNoEditors(bytes32 democHash) external;
    function setDErc20(bytes32 democHash, address newErc20) external;
    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dSetEditorArbitraryData(bytes32 democHash, bytes key, bytes value) external;
    function dAddCategory(bytes32 democHash, bytes32 categoryName, bool hasParent, uint parent) external;
    function dDeprecateCategory(bytes32 democHash, uint catId) external;
    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) external;
    function dDisableErc20OwnerClaim(bytes32 democHash) external;

     
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) external;

     
    function getDOwner(bytes32 democHash) external view returns (address);
    function isDEditor(bytes32 democHash, address editor) external view returns (bool);
    function getDHash(bytes13 prefix) external view returns (bytes32);
    function getDInfo(bytes32 democHash) external view returns (address erc20, address owner, uint256 nBallots);
    function getDErc20(bytes32 democHash) external view returns (address);
    function getDArbitraryData(bytes32 democHash, bytes key) external view returns (bytes value);
    function getDEditorArbitraryData(bytes32 democHash, bytes key) external view returns (bytes value);
    function getDBallotsN(bytes32 democHash) external view returns (uint256);
    function getDBallotID(bytes32 democHash, uint n) external view returns (uint ballotId);
    function getDCountedBasicBallotsN(bytes32 democHash) external view returns (uint256);
    function getDCountedBasicBallotID(bytes32 democHash, uint256 n) external view returns (uint256);
    function getDCategoriesN(bytes32 democHash) external view returns (uint);
    function getDCategory(bytes32 democHash, uint catId) external view returns (bool deprecated, bytes32 name, bool hasParent, uint parent);
    function getDCommBallotsEnabled(bytes32 democHash) external view returns (bool);
    function getDErc20OwnerClaimEnabled(bytes32 democHash) external view returns (bool);
}

contract SVIndexBackend is IxBackendIface {
    uint constant VERSION = 2;

    struct Democ {
        address erc20;
        address owner;
        bool communityBallotsDisabled;
        bool erc20OwnerClaimDisabled;
        uint editorEpoch;
        mapping (uint => mapping (address => bool)) editors;
        uint256[] allBallots;
        uint256[] includedBasicBallots;   

    }

    struct BallotRef {
        bytes32 democHash;
        uint ballotId;
    }

    struct Category {
        bool deprecated;
        bytes32 name;
        bool hasParent;
        uint parent;
    }

    struct CategoriesIx {
        uint nCategories;
        mapping(uint => Category) categories;
    }

    mapping (bytes32 => Democ) democs;
    mapping (bytes32 => CategoriesIx) democCategories;
    mapping (bytes13 => bytes32) democPrefixToHash;
    mapping (address => bytes32[]) erc20ToDemocs;
    bytes32[] democList;

     
     
     
     
    mapping (bytes32 => mapping (bytes32 => bytes)) arbitraryData;

     

    constructor() payoutAllC(msg.sender) public {
         
    }

     

    function _getPayTo() internal view returns (address) {
        return owner;
    }

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

     

    function getGDemocsN() external view returns (uint) {
        return democList.length;
    }

    function getGDemoc(uint id) external view returns (bytes32) {
        return democList[id];
    }

    function getGErc20ToDemocs(address erc20) external view returns (bytes32[] democHashes) {
        return erc20ToDemocs[erc20];
    }

     

    function _addDemoc(bytes32 democHash, address erc20, address initOwner, bool disableErc20OwnerClaim) internal {
        democList.push(democHash);
        Democ storage d = democs[democHash];
        d.erc20 = erc20;
        if (disableErc20OwnerClaim) {
            d.erc20OwnerClaimDisabled = true;
        }
         
        assert(democPrefixToHash[bytes13(democHash)] == bytes32(0));
        democPrefixToHash[bytes13(democHash)] = democHash;
        erc20ToDemocs[erc20].push(democHash);
        _setDOwner(democHash, initOwner);
        emit NewDemoc(democHash);
    }

     

    function dAdd(bytes32 democHash, address erc20, bool disableErc20OwnerClaim) only_owner() external {
        _addDemoc(democHash, erc20, msg.sender, disableErc20OwnerClaim);
        emit ManuallyAddedDemoc(democHash, erc20);
    }

     

    function emergencySetDOwner(bytes32 democHash, address newOwner) only_owner() external {
        _setDOwner(democHash, newOwner);
        emit EmergencyDemocOwner(democHash, newOwner);
    }

     

    function dInit(address defaultErc20, address initOwner, bool disableErc20OwnerClaim) only_editors() external returns (bytes32 democHash) {
         
         
        democHash = keccak256(abi.encodePacked(democList.length, blockhash(block.number-1), defaultErc20, now));
        _addDemoc(democHash, defaultErc20, initOwner, disableErc20OwnerClaim);
    }

    function _setDOwner(bytes32 democHash, address newOwner) internal {
        Democ storage d = democs[democHash];
        uint epoch = d.editorEpoch;
        d.owner = newOwner;
         
        d.editors[epoch][d.owner] = false;
         
        d.editors[epoch][newOwner] = true;
        emit DemocOwnerSet(democHash, newOwner);
    }

    function setDOwner(bytes32 democHash, address newOwner) only_editors() external {
        _setDOwner(democHash, newOwner);
    }

    function setDOwnerFromClaim(bytes32 democHash, address newOwner) only_editors() external {
        Democ storage d = democs[democHash];
         
        require(d.erc20OwnerClaimDisabled == false, "!erc20-claim");
         
        d.owner = newOwner;
        d.editors[d.editorEpoch][newOwner] = true;
         
        d.erc20OwnerClaimDisabled = true;
        emit DemocOwnerSet(democHash, newOwner);
        emit DemocClaimed(democHash);
    }

    function setDEditor(bytes32 democHash, address editor, bool canEdit) only_editors() external {
        Democ storage d = democs[democHash];
        d.editors[d.editorEpoch][editor] = canEdit;
        emit DemocEditorSet(democHash, editor, canEdit);
    }

    function setDNoEditors(bytes32 democHash) only_editors() external {
        democs[democHash].editorEpoch += 1;
        emit DemocEditorsWiped(democHash);
    }

    function setDErc20(bytes32 democHash, address newErc20) only_editors() external {
        democs[democHash].erc20 = newErc20;
        erc20ToDemocs[newErc20].push(democHash);
        emit DemocErc20Set(democHash, newErc20);
    }

    function dSetArbitraryData(bytes32 democHash, bytes key, bytes value) only_editors() external {
        bytes32 k = keccak256(key);
        arbitraryData[democHash][k] = value;
        emit DemocDataSet(democHash, k);
    }

    function dSetEditorArbitraryData(bytes32 democHash, bytes key, bytes value) only_editors() external {
        bytes32 k = keccak256(_calcEditorKey(key));
        arbitraryData[democHash][k] = value;
        emit DemocDataSet(democHash, k);
    }

    function dAddCategory(bytes32 democHash, bytes32 name, bool hasParent, uint parent) only_editors() external {
        uint catId = democCategories[democHash].nCategories;
        democCategories[democHash].categories[catId].name = name;
        if (hasParent) {
            democCategories[democHash].categories[catId].hasParent = true;
            democCategories[democHash].categories[catId].parent = parent;
        }
        democCategories[democHash].nCategories += 1;
        emit DemocCatAdded(democHash, catId);
    }

    function dDeprecateCategory(bytes32 democHash, uint catId) only_editors() external {
        democCategories[democHash].categories[catId].deprecated = true;
        emit DemocCatDeprecated(democHash, catId);
    }

    function dSetCommunityBallotsEnabled(bytes32 democHash, bool enabled) only_editors() external {
        democs[democHash].communityBallotsDisabled = !enabled;
        emit DemocCommunityBallotsEnabled(democHash, enabled);
    }

    function dDisableErc20OwnerClaim(bytes32 democHash) only_editors() external {
        democs[democHash].erc20OwnerClaimDisabled = true;
        emit DemocErc20OwnerClaimDisabled(democHash);
    }

     

    function _commitBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) internal {
        uint16 subBits;
        subBits = BPackedUtils.packedToSubmissionBits(packed);

        uint localBallotId = democs[democHash].allBallots.length;
        democs[democHash].allBallots.push(ballotId);

         
        if (countTowardsLimit) {
            democs[democHash].includedBasicBallots.push(ballotId);
        }

        emit NewBallot(democHash, localBallotId);
    }

     
    function dAddBallot(bytes32 democHash, uint ballotId, uint256 packed, bool countTowardsLimit) only_editors() external {
        _commitBallot(democHash, ballotId, packed, countTowardsLimit);
    }

     

    function getDOwner(bytes32 democHash) external view returns (address) {
        return democs[democHash].owner;
    }

    function isDEditor(bytes32 democHash, address editor) external view returns (bool) {
        Democ storage d = democs[democHash];
         
        return d.editors[d.editorEpoch][editor] || editor == d.owner;
    }

    function getDHash(bytes13 prefix) external view returns (bytes32) {
        return democPrefixToHash[prefix];
    }

    function getDInfo(bytes32 democHash) external view returns (address erc20, address owner, uint256 nBallots) {
        return (democs[democHash].erc20, democs[democHash].owner, democs[democHash].allBallots.length);
    }

    function getDErc20(bytes32 democHash) external view returns (address) {
        return democs[democHash].erc20;
    }

    function getDArbitraryData(bytes32 democHash, bytes key) external view returns (bytes) {
        return arbitraryData[democHash][keccak256(key)];
    }

    function getDEditorArbitraryData(bytes32 democHash, bytes key) external view returns (bytes) {
        return arbitraryData[democHash][keccak256(_calcEditorKey(key))];
    }

    function getDBallotsN(bytes32 democHash) external view returns (uint256) {
        return democs[democHash].allBallots.length;
    }

    function getDBallotID(bytes32 democHash, uint256 n) external view returns (uint ballotId) {
        return democs[democHash].allBallots[n];
    }

    function getDCountedBasicBallotsN(bytes32 democHash) external view returns (uint256) {
        return democs[democHash].includedBasicBallots.length;
    }

    function getDCountedBasicBallotID(bytes32 democHash, uint256 n) external view returns (uint256) {
        return democs[democHash].includedBasicBallots[n];
    }

    function getDCategoriesN(bytes32 democHash) external view returns (uint) {
        return democCategories[democHash].nCategories;
    }

    function getDCategory(bytes32 democHash, uint catId) external view returns (bool deprecated, bytes32 name, bool hasParent, uint256 parent) {
        deprecated = democCategories[democHash].categories[catId].deprecated;
        name = democCategories[democHash].categories[catId].name;
        hasParent = democCategories[democHash].categories[catId].hasParent;
        parent = democCategories[democHash].categories[catId].parent;
    }

    function getDCommBallotsEnabled(bytes32 democHash) external view returns (bool) {
        return !democs[democHash].communityBallotsDisabled;
    }

    function getDErc20OwnerClaimEnabled(bytes32 democHash) external view returns (bool) {
        return !democs[democHash].erc20OwnerClaimDisabled;
    }

     

    function _calcEditorKey(bytes key) internal pure returns (bytes) {
        return abi.encodePacked("editor.", key);
    }
}

contract IxPaymentsIface is hasVersion, ixPaymentEvents, permissioned, CanReclaimToken, payoutAllCSettable {
     
    function emergencySetOwner(address newOwner) external;

     
    function weiBuysHowManySeconds(uint amount) public view returns (uint secs);
    function weiToCents(uint w) public view returns (uint);
    function centsToWei(uint c) public view returns (uint);

     
    function payForDemocracy(bytes32 democHash) external payable;
    function doFreeExtension(bytes32 democHash) external;
    function downgradeToBasic(bytes32 democHash) external;
    function upgradeToPremium(bytes32 democHash) external;

     
    function accountInGoodStanding(bytes32 democHash) external view returns (bool);
    function getSecondsRemaining(bytes32 democHash) external view returns (uint);
    function getPremiumStatus(bytes32 democHash) external view returns (bool);
    function getFreeExtension(bytes32 democHash) external view returns (bool);
    function getAccount(bytes32 democHash) external view returns (bool isPremium, uint lastPaymentTs, uint paidUpTill, bool hasFreeExtension);
    function getDenyPremium(bytes32 democHash) external view returns (bool);

     
    function giveTimeToDemoc(bytes32 democHash, uint additionalSeconds, bytes32 ref) external;

     
    function setPayTo(address) external;
    function setMinorEditsAddr(address) external;
    function setBasicCentsPricePer30Days(uint amount) external;
    function setBasicBallotsPer30Days(uint amount) external;
    function setPremiumMultiplier(uint8 amount) external;
    function setWeiPerCent(uint) external;
    function setFreeExtension(bytes32 democHash, bool hasFreeExt) external;
    function setDenyPremium(bytes32 democHash, bool isPremiumDenied) external;
    function setMinWeiForDInit(uint amount) external;

     
    function getBasicCentsPricePer30Days() external view returns(uint);
    function getBasicExtraBallotFeeWei() external view returns (uint);
    function getBasicBallotsPer30Days() external view returns (uint);
    function getPremiumMultiplier() external view returns (uint8);
    function getPremiumCentsPricePer30Days() external view returns (uint);
    function getWeiPerCent() external view returns (uint weiPerCent);
    function getUsdEthExchangeRate() external view returns (uint centsPerEth);
    function getMinWeiForDInit() external view returns (uint);

     
    function getPaymentLogN() external view returns (uint);
    function getPaymentLog(uint n) external view returns (bool _external, bytes32 _democHash, uint _seconds, uint _ethValue);
}

contract SVPayments is IxPaymentsIface {
    uint constant VERSION = 2;

    struct Account {
        bool isPremium;
        uint lastPaymentTs;
        uint paidUpTill;
        uint lastUpgradeTs;   
    }

    struct PaymentLog {
        bool _external;
        bytes32 _democHash;
        uint _seconds;
        uint _ethValue;
    }

     
     
    address public minorEditsAddr;

     
    uint basicCentsPricePer30Days = 125000;  
    uint basicBallotsPer30Days = 10;
    uint8 premiumMultiplier = 5;
    uint weiPerCent = 0.000016583747 ether;   

    uint minWeiForDInit = 1;   

    mapping (bytes32 => Account) accounts;
    PaymentLog[] payments;

     
    mapping (bytes32 => bool) denyPremium;
     
    mapping (bytes32 => bool) freeExtension;


     
     
     
     
    address public emergencyAdmin;
    function emergencySetOwner(address newOwner) external {
        require(msg.sender == emergencyAdmin, "!emergency-owner");
        owner = newOwner;
    }
     


    constructor(address _emergencyAdmin) payoutAllCSettable(msg.sender) public {
        emergencyAdmin = _emergencyAdmin;
        assert(_emergencyAdmin != address(0));
    }

     

    function getVersion() external pure returns (uint) {
        return VERSION;
    }

    function() payable public {
        _getPayTo().transfer(msg.value);
    }

    function _modAccountBalance(bytes32 democHash, uint additionalSeconds) internal {
        uint prevPaidTill = accounts[democHash].paidUpTill;
        if (prevPaidTill < now) {
            prevPaidTill = now;
        }

        accounts[democHash].paidUpTill = prevPaidTill + additionalSeconds;
        accounts[democHash].lastPaymentTs = now;
    }

     

    function weiBuysHowManySeconds(uint amount) public view returns (uint) {
        uint centsPaid = weiToCents(amount);
         
        uint monthsOffsetPaid = ((10 ** 18) * centsPaid) / basicCentsPricePer30Days;
        uint secondsOffsetPaid = monthsOffsetPaid * (30 days);
        uint additionalSeconds = secondsOffsetPaid / (10 ** 18);
        return additionalSeconds;
    }

    function weiToCents(uint w) public view returns (uint) {
        return w / weiPerCent;
    }

    function centsToWei(uint c) public view returns (uint) {
        return c * weiPerCent;
    }

     

    function payForDemocracy(bytes32 democHash) external payable {
        require(msg.value > 0, "need to send some ether to make payment");

        uint additionalSeconds = weiBuysHowManySeconds(msg.value);

        if (accounts[democHash].isPremium) {
            additionalSeconds /= premiumMultiplier;
        }

        if (additionalSeconds >= 1) {
            _modAccountBalance(democHash, additionalSeconds);
        }
        payments.push(PaymentLog(false, democHash, additionalSeconds, msg.value));
        emit AccountPayment(democHash, additionalSeconds);

        _getPayTo().transfer(msg.value);
    }

    function doFreeExtension(bytes32 democHash) external {
        require(freeExtension[democHash], "!free");
        uint newPaidUpTill = now + 60 days;
        accounts[democHash].paidUpTill = newPaidUpTill;
        emit FreeExtension(democHash);
    }

    function downgradeToBasic(bytes32 democHash) only_editors() external {
        require(accounts[democHash].isPremium, "!premium");
        accounts[democHash].isPremium = false;
         
        uint paidTill = accounts[democHash].paidUpTill;
        uint timeRemaining = SafeMath.subToZero(paidTill, now);
         
        if (timeRemaining > 0) {
             
             
            require(accounts[democHash].lastUpgradeTs < (now - 24 hours), "downgrade-too-soon");
            timeRemaining *= premiumMultiplier;
            accounts[democHash].paidUpTill = now + timeRemaining;
        }
        emit DowngradeToBasic(democHash);
    }

    function upgradeToPremium(bytes32 democHash) only_editors() external {
        require(denyPremium[democHash] == false, "upgrade-denied");
        require(!accounts[democHash].isPremium, "!basic");
        accounts[democHash].isPremium = true;
         
        uint paidTill = accounts[democHash].paidUpTill;
        uint timeRemaining = SafeMath.subToZero(paidTill, now);
         
        if (timeRemaining > 0) {
            timeRemaining /= premiumMultiplier;
            accounts[democHash].paidUpTill = now + timeRemaining;
        }
        accounts[democHash].lastUpgradeTs = now;
        emit UpgradedToPremium(democHash);
    }

     

    function accountInGoodStanding(bytes32 democHash) external view returns (bool) {
        return accounts[democHash].paidUpTill >= now;
    }

    function getSecondsRemaining(bytes32 democHash) external view returns (uint) {
        return SafeMath.subToZero(accounts[democHash].paidUpTill, now);
    }

    function getPremiumStatus(bytes32 democHash) external view returns (bool) {
        return accounts[democHash].isPremium;
    }

    function getFreeExtension(bytes32 democHash) external view returns (bool) {
        return freeExtension[democHash];
    }

    function getAccount(bytes32 democHash) external view returns (bool isPremium, uint lastPaymentTs, uint paidUpTill, bool hasFreeExtension) {
        isPremium = accounts[democHash].isPremium;
        lastPaymentTs = accounts[democHash].lastPaymentTs;
        paidUpTill = accounts[democHash].paidUpTill;
        hasFreeExtension = freeExtension[democHash];
    }

    function getDenyPremium(bytes32 democHash) external view returns (bool) {
        return denyPremium[democHash];
    }

     

    function giveTimeToDemoc(bytes32 democHash, uint additionalSeconds, bytes32 ref) owner_or(minorEditsAddr) external {
        _modAccountBalance(democHash, additionalSeconds);
        payments.push(PaymentLog(true, democHash, additionalSeconds, 0));
        emit GrantedAccountTime(democHash, additionalSeconds, ref);
    }

     

    function setPayTo(address newPayTo) only_owner() external {
        _setPayTo(newPayTo);
        emit SetPayTo(newPayTo);
    }

    function setMinorEditsAddr(address a) only_owner() external {
        minorEditsAddr = a;
        emit SetMinorEditsAddr(a);
    }

    function setBasicCentsPricePer30Days(uint amount) only_owner() external {
        basicCentsPricePer30Days = amount;
        emit SetBasicCentsPricePer30Days(amount);
    }

    function setBasicBallotsPer30Days(uint amount) only_owner() external {
        basicBallotsPer30Days = amount;
        emit SetBallotsPer30Days(amount);
    }

    function setPremiumMultiplier(uint8 m) only_owner() external {
        premiumMultiplier = m;
        emit SetPremiumMultiplier(m);
    }

    function setWeiPerCent(uint wpc) owner_or(minorEditsAddr) external {
        weiPerCent = wpc;
        emit SetExchangeRate(wpc);
    }

    function setFreeExtension(bytes32 democHash, bool hasFreeExt) owner_or(minorEditsAddr) external {
        freeExtension[democHash] = hasFreeExt;
        emit SetFreeExtension(democHash, hasFreeExt);
    }

    function setDenyPremium(bytes32 democHash, bool isPremiumDenied) owner_or(minorEditsAddr) external {
        denyPremium[democHash] = isPremiumDenied;
        emit SetDenyPremium(democHash, isPremiumDenied);
    }

    function setMinWeiForDInit(uint amount) owner_or(minorEditsAddr) external {
        minWeiForDInit = amount;
        emit SetMinWeiForDInit(amount);
    }

     

    function getBasicCentsPricePer30Days() external view returns (uint) {
        return basicCentsPricePer30Days;
    }

    function getBasicExtraBallotFeeWei() external view returns (uint) {
        return centsToWei(basicCentsPricePer30Days / basicBallotsPer30Days);
    }

    function getBasicBallotsPer30Days() external view returns (uint) {
        return basicBallotsPer30Days;
    }

    function getPremiumMultiplier() external view returns (uint8) {
        return premiumMultiplier;
    }

    function getPremiumCentsPricePer30Days() external view returns (uint) {
        return _premiumPricePer30Days();
    }

    function _premiumPricePer30Days() internal view returns (uint) {
        return uint(premiumMultiplier) * basicCentsPricePer30Days;
    }

    function getWeiPerCent() external view returns (uint) {
        return weiPerCent;
    }

    function getUsdEthExchangeRate() external view returns (uint) {
         
        return 1 ether / weiPerCent;
    }

    function getMinWeiForDInit() external view returns (uint) {
        return minWeiForDInit;
    }

     

    function getPaymentLogN() external view returns (uint) {
        return payments.length;
    }

    function getPaymentLog(uint n) external view returns (bool _external, bytes32 _democHash, uint _seconds, uint _ethValue) {
        _external = payments[n]._external;
        _democHash = payments[n]._democHash;
        _seconds = payments[n]._seconds;
        _ethValue = payments[n]._ethValue;
    }
}

interface SvEnsIface {
     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
}

interface ENSIface {
     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
}

contract PublicResolver {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
    }

    ENSIface ens;

    mapping (bytes32 => Record) records;

    modifier only_owner(bytes32 node) {
        require(ens.owner(node) == msg.sender);
        _;
    }

     
    constructor(ENSIface ensAddr) public {
        ens = ensAddr;
    }

     
    function setAddr(bytes32 node, address addr) public only_owner(node) {
        records[node].addr = addr;
        emit AddrChanged(node, addr);
    }

     
    function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
        records[node].content = hash;
        emit ContentChanged(node, hash);
    }

     
    function setName(bytes32 node, string name) public only_owner(node) {
        records[node].name = name;
        emit NameChanged(node, name);
    }

     
    function setABI(bytes32 node, uint256 contentType, bytes data) public only_owner(node) {
         
        require(((contentType - 1) & contentType) == 0);

        records[node].abis[contentType] = data;
        emit ABIChanged(node, contentType);
    }

     
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) public only_owner(node) {
        records[node].pubkey = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

     
    function setText(bytes32 node, string key, string value) public only_owner(node) {
        records[node].text[key] = value;
        emit TextChanged(node, key, key);
    }

     
    function text(bytes32 node, string key) public view returns (string) {
        return records[node].text[key];
    }

     
    function pubkey(bytes32 node) public view returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

     
    function ABI(bytes32 node, uint256 contentTypes) public view returns (uint256 contentType, bytes data) {
        Record storage record = records[node];
        for (contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

     
    function name(bytes32 node) public view returns (string) {
        return records[node].name;
    }

     
    function content(bytes32 node) public view returns (bytes32) {
        return records[node].content;
    }

     
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

     
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == CONTENT_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID ||
        interfaceID == ABI_INTERFACE_ID ||
        interfaceID == PUBKEY_INTERFACE_ID ||
        interfaceID == TEXT_INTERFACE_ID ||
        interfaceID == INTERFACE_META_ID;
    }
}

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes) {
        bytes memory tempBytes;

        assembly {
             
             
            tempBytes := mload(0x40)

             
             
            let length := mload(_preBytes)
            mstore(tempBytes, length)

             
             
             
            let mc := add(tempBytes, 0x20)
             
             
            let end := add(mc, length)

            for {
                 
                 
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                 
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                 
                 
                mstore(mc, mload(cc))
            }

             
             
             
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

             
             
            mc := end
             
             
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

             
             
             
             
             
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)  
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
             
             
             
            let fslot := sload(_preBytes_slot)
             
             
             
             
             
             
             
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
             
             
             
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                 
                 
                 
                sstore(
                    _preBytes_slot,
                     
                     
                    add(
                         
                         
                        fslot,
                        add(
                            mul(
                                div(
                                     
                                    mload(add(_postBytes, 0x20)),
                                     
                                    exp(0x100, sub(32, mlength))
                                ),
                                 
                                 
                                exp(0x100, sub(32, newlength))
                            ),
                             
                             
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                 
                 
                 
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                 
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                 
                 
                 
                 
                 
                 
                 
                 

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                 
                mstore(0x0, _preBytes_slot)
                 
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                 
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                 
                 
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                 
                 
                tempBytes := mload(0x40)

                 
                 
                 
                 
                 
                 
                 
                 
                let lengthmod := and(_length, 31)

                 
                 
                 
                 
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                     
                     
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                 
                 
                mstore(0x40, and(add(mc, 31), not(31)))
            }
             
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

             
            switch eq(length, mload(_postBytes))
            case 1 {
                 
                 
                 
                 
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                 
                 
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                     
                    if iszero(eq(mload(mc), mload(cc))) {
                         
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                 
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
             
            let fslot := sload(_preBytes_slot)
             
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

             
            switch eq(slength, mlength)
            case 1 {
                 
                 
                 
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                         
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                             
                            success := 0
                        }
                    }
                    default {
                         
                         
                         
                         
                        let cb := 1

                         
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                         
                         
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                 
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                 
                success := 0
            }
        }

        return success;
    }
}