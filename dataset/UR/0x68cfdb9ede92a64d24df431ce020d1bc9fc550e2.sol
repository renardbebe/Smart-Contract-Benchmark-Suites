 

pragma solidity 0.4.25;

 
 
 
 
 
 
contract IContractId {
     
     
    function contractId() public pure returns (bytes32 id, uint256 version);
}

contract ShareholderRights is IContractId {

     
     
     

    enum VotingRule {
         
        NoVotingRights,
         
        Positive,
         
        Negative,
         
        Proportional
    }

     
     
     

    bytes32 private constant EMPTY_STRING_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

     
     
     

     
    bool public constant HAS_DRAG_ALONG_RIGHTS = true;
     
    bool public constant HAS_TAG_ALONG_RIGHTS = true;
     
    bool public constant HAS_GENERAL_INFORMATION_RIGHTS = true;
     
    VotingRule public GENERAL_VOTING_RULE;
     
    VotingRule public TAG_ALONG_VOTING_RULE;
     
    uint256 public LIQUIDATION_PREFERENCE_MULTIPLIER_FRAC;
     
    bool public HAS_FOUNDERS_VESTING;
     
    uint256 public GENERAL_VOTING_DURATION;
     
    uint256 public RESTRICTED_ACT_VOTING_DURATION;
     
    uint256 public VOTING_FINALIZATION_DURATION;
     
    uint256 public TOKENHOLDERS_QUORUM_FRAC = 10**17;  
     
    uint256 public VOTING_MAJORITY_FRAC = 10**17;  
     
    string public INVESTMENT_AGREEMENT_TEMPLATE_URL;

     
     
     

    constructor(
        VotingRule generalVotingRule,
        VotingRule tagAlongVotingRule,
        uint256 liquidationPreferenceMultiplierFrac,
        bool hasFoundersVesting,
        uint256 generalVotingDuration,
        uint256 restrictedActVotingDuration,
        uint256 votingFinalizationDuration,
        uint256 tokenholdersQuorumFrac,
        uint256 votingMajorityFrac,
        string investmentAgreementTemplateUrl
    )
        public
    {
         
        require(uint(generalVotingRule) < 4);
        require(uint(tagAlongVotingRule) < 4);
         
        require(tokenholdersQuorumFrac < 10**18);
        require(keccak256(abi.encodePacked(investmentAgreementTemplateUrl)) != EMPTY_STRING_HASH);

        GENERAL_VOTING_RULE = generalVotingRule;
        TAG_ALONG_VOTING_RULE = tagAlongVotingRule;
        LIQUIDATION_PREFERENCE_MULTIPLIER_FRAC = liquidationPreferenceMultiplierFrac;
        HAS_FOUNDERS_VESTING = hasFoundersVesting;
        GENERAL_VOTING_DURATION = generalVotingDuration;
        RESTRICTED_ACT_VOTING_DURATION = restrictedActVotingDuration;
        VOTING_FINALIZATION_DURATION = votingFinalizationDuration;
        TOKENHOLDERS_QUORUM_FRAC = tokenholdersQuorumFrac;
        VOTING_MAJORITY_FRAC = votingMajorityFrac;
        INVESTMENT_AGREEMENT_TEMPLATE_URL = investmentAgreementTemplateUrl;
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x7f46caed28b4e7a90dc4db9bba18d1565e6c4824f0dc1b96b3b88d730da56e57, 0);
    }
}

contract Math {

     
     
     

     
    function absDiff(uint256 v1, uint256 v2)
        internal
        pure
        returns(uint256)
    {
        return v1 > v2 ? v1 - v2 : v2 - v1;
    }

     
    function divRound(uint256 v, uint256 d)
        internal
        pure
        returns(uint256)
    {
        return add(v, d/2) / d;
    }

     
     
     
     
    function decimalFraction(uint256 amount, uint256 frac)
        internal
        pure
        returns(uint256)
    {
         
        return proportion(amount, frac, 10**18);
    }

     
     
    function proportion(uint256 amount, uint256 part, uint256 total)
        internal
        pure
        returns(uint256)
    {
        return divRound(mul(amount, part), total);
    }

     
     
     

    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

 
contract PlatformTerms is Math, IContractId {

     
     
     

     
    uint256 public constant PLATFORM_FEE_FRACTION = 3 * 10**16;
     
    uint256 public constant TOKEN_PARTICIPATION_FEE_FRACTION = 2 * 10**16;
     
     
     
    uint256 public constant PLATFORM_NEUMARK_SHARE = 2;  
     
    bool public constant IS_ICBM_INVESTOR_WHITELISTED = true;

     
    uint256 public constant MIN_TICKET_EUR_ULPS = 100 * 10**18;
     
     
     

     
    uint256 public constant DATE_TO_WHITELIST_MIN_DURATION = 5 days;
     
    uint256 public constant TOKEN_RATE_EXPIRES_AFTER = 4 hours;

     
    uint256 public constant MIN_WHITELIST_DURATION = 0 days;
    uint256 public constant MAX_WHITELIST_DURATION = 30 days;
    uint256 public constant MIN_PUBLIC_DURATION = 0 days;
    uint256 public constant MAX_PUBLIC_DURATION = 60 days;

     
    uint256 public constant MIN_OFFER_DURATION = 1 days;
     
    uint256 public constant MAX_OFFER_DURATION = 90 days;

    uint256 public constant MIN_SIGNING_DURATION = 14 days;
    uint256 public constant MAX_SIGNING_DURATION = 60 days;

    uint256 public constant MIN_CLAIM_DURATION = 7 days;
    uint256 public constant MAX_CLAIM_DURATION = 30 days;

     
     
     

     
    function calculateNeumarkDistribution(uint256 rewardNmk)
        public
        pure
        returns (uint256 platformNmk, uint256 investorNmk)
    {
         
        platformNmk = rewardNmk / PLATFORM_NEUMARK_SHARE;
         
        return (platformNmk, rewardNmk - platformNmk);
    }

    function calculatePlatformTokenFee(uint256 tokenAmount)
        public
        pure
        returns (uint256)
    {
         
        return proportion(tokenAmount, TOKEN_PARTICIPATION_FEE_FRACTION, 10**18);
    }

    function calculatePlatformFee(uint256 amount)
        public
        pure
        returns (uint256)
    {
        return decimalFraction(amount, PLATFORM_FEE_FRACTION);
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x95482babc4e32de6c4dc3910ee7ae62c8e427efde6bc4e9ce0d6d93e24c39323, 0);
    }
}

 
contract IAccessPolicy {

     
     
     

     
     
     
     
     
     
     
    function allowed(
        address subject,
        bytes32 role,
        address object,
        bytes4 verb
    )
        public
        returns (bool);
}

 
 
contract IAccessControlled {

     
     
     

     
    event LogAccessPolicyChanged(
        address controller,
        IAccessPolicy oldPolicy,
        IAccessPolicy newPolicy
    );

     
     
     

     
     
     
     
     
     
    function setAccessPolicy(IAccessPolicy newPolicy, address newAccessController)
        public;

    function accessPolicy()
        public
        constant
        returns (IAccessPolicy);

}

contract StandardRoles {

     
     
     

     
     
    bytes32 internal constant ROLE_ACCESS_CONTROLLER = 0xac42f8beb17975ed062dcb80c63e6d203ef1c2c335ced149dc5664cc671cb7da;
}

 
 
 
 
 
 
contract AccessControlled is IAccessControlled, StandardRoles {

     
     
     

    IAccessPolicy private _accessPolicy;

     
     
     

     
    modifier only(bytes32 role) {
        require(_accessPolicy.allowed(msg.sender, role, this, msg.sig));
        _;
    }

     
     
     

    constructor(IAccessPolicy policy) internal {
        require(address(policy) != 0x0);
        _accessPolicy = policy;
    }

     
     
     

     
     
     

    function setAccessPolicy(IAccessPolicy newPolicy, address newAccessController)
        public
        only(ROLE_ACCESS_CONTROLLER)
    {
         
         
         
        require(newPolicy.allowed(newAccessController, ROLE_ACCESS_CONTROLLER, this, msg.sig));

         
        IAccessPolicy oldPolicy = _accessPolicy;
        _accessPolicy = newPolicy;

         
        emit LogAccessPolicyChanged(msg.sender, oldPolicy, newPolicy);
    }

    function accessPolicy()
        public
        constant
        returns (IAccessPolicy)
    {
        return _accessPolicy;
    }
}

 
 
contract AccessRoles {

     
     
     

     
     
     

     
    bytes32 internal constant ROLE_NEUMARK_ISSUER = 0x921c3afa1f1fff707a785f953a1e197bd28c9c50e300424e015953cbf120c06c;

     
    bytes32 internal constant ROLE_NEUMARK_BURNER = 0x19ce331285f41739cd3362a3ec176edffe014311c0f8075834fdd19d6718e69f;

     
    bytes32 internal constant ROLE_SNAPSHOT_CREATOR = 0x08c1785afc57f933523bc52583a72ce9e19b2241354e04dd86f41f887e3d8174;

     
    bytes32 internal constant ROLE_TRANSFER_ADMIN = 0xb6527e944caca3d151b1f94e49ac5e223142694860743e66164720e034ec9b19;

     
    bytes32 internal constant ROLE_RECLAIMER = 0x0542bbd0c672578966dcc525b30aa16723bb042675554ac5b0362f86b6e97dc5;

     
    bytes32 internal constant ROLE_PLATFORM_OPERATOR_REPRESENTATIVE = 0xb2b321377653f655206f71514ff9f150d0822d062a5abcf220d549e1da7999f0;

     
    bytes32 internal constant ROLE_EURT_DEPOSIT_MANAGER = 0x7c8ecdcba80ce87848d16ad77ef57cc196c208fc95c5638e4a48c681a34d4fe7;

     
    bytes32 internal constant ROLE_IDENTITY_MANAGER = 0x32964e6bc50f2aaab2094a1d311be8bda920fc4fb32b2fb054917bdb153a9e9e;

     
    bytes32 internal constant ROLE_EURT_LEGAL_MANAGER = 0x4eb6b5806954a48eb5659c9e3982d5e75bfb2913f55199877d877f157bcc5a9b;

     
    bytes32 internal constant ROLE_UNIVERSE_MANAGER = 0xe8d8f8f9ea4b19a5a4368dbdace17ad71a69aadeb6250e54c7b4c7b446301738;

     
    bytes32 internal constant ROLE_GAS_EXCHANGE = 0x9fe43636e0675246c99e96d7abf9f858f518b9442c35166d87f0934abef8a969;

     
    bytes32 internal constant ROLE_TOKEN_RATE_ORACLE = 0xa80c3a0c8a5324136e4c806a778583a2a980f378bdd382921b8d28dcfe965585;
}

contract IEthereumForkArbiter {

     
     
     

    event LogForkAnnounced(
        string name,
        string url,
        uint256 blockNumber
    );

    event LogForkSigned(
        uint256 blockNumber,
        bytes32 blockHash
    );

     
     
     

    function nextForkName()
        public
        constant
        returns (string);

    function nextForkUrl()
        public
        constant
        returns (string);

    function nextForkBlockNumber()
        public
        constant
        returns (uint256);

    function lastSignedBlockNumber()
        public
        constant
        returns (uint256);

    function lastSignedBlockHash()
        public
        constant
        returns (bytes32);

    function lastSignedTimestamp()
        public
        constant
        returns (uint256);

}

 
contract IAgreement {

     
     
     

    event LogAgreementAccepted(
        address indexed accepter
    );

    event LogAgreementAmended(
        address contractLegalRepresentative,
        string agreementUri
    );

     
    function amendAgreement(string agreementUri) public;

     
     
    function currentAgreement()
        public
        constant
        returns
        (
            address contractLegalRepresentative,
            uint256 signedBlockTimestamp,
            string agreementUri,
            uint256 index
        );

     
     
    function pastAgreement(uint256 amendmentIndex)
        public
        constant
        returns
        (
            address contractLegalRepresentative,
            uint256 signedBlockTimestamp,
            string agreementUri,
            uint256 index
        );

     
     
    function agreementSignedAtBlock(address signatory)
        public
        constant
        returns (uint256 blockNo);

     
    function amendmentsCount()
        public
        constant
        returns (uint256);
}

 
contract Agreement is
    IAgreement,
    AccessControlled,
    AccessRoles
{

     
     
     

     
    struct SignedAgreement {
        address contractLegalRepresentative;
        uint256 signedBlockTimestamp;
        string agreementUri;
    }

     
     
     

    IEthereumForkArbiter private ETHEREUM_FORK_ARBITER;

     
     
     

     
    SignedAgreement[] private _amendments;

     
    mapping(address => uint256) private _signatories;

     
     
     

     
     
    modifier acceptAgreement(address accepter) {
        acceptAgreementInternal(accepter);
        _;
    }

    modifier onlyLegalRepresentative(address legalRepresentative) {
        require(mCanAmend(legalRepresentative));
        _;
    }

     
     
     

    constructor(IAccessPolicy accessPolicy, IEthereumForkArbiter forkArbiter)
        AccessControlled(accessPolicy)
        internal
    {
        require(forkArbiter != IEthereumForkArbiter(0x0));
        ETHEREUM_FORK_ARBITER = forkArbiter;
    }

     
     
     

    function amendAgreement(string agreementUri)
        public
        onlyLegalRepresentative(msg.sender)
    {
        SignedAgreement memory amendment = SignedAgreement({
            contractLegalRepresentative: msg.sender,
            signedBlockTimestamp: block.timestamp,
            agreementUri: agreementUri
        });
        _amendments.push(amendment);
        emit LogAgreementAmended(msg.sender, agreementUri);
    }

    function ethereumForkArbiter()
        public
        constant
        returns (IEthereumForkArbiter)
    {
        return ETHEREUM_FORK_ARBITER;
    }

    function currentAgreement()
        public
        constant
        returns
        (
            address contractLegalRepresentative,
            uint256 signedBlockTimestamp,
            string agreementUri,
            uint256 index
        )
    {
        require(_amendments.length > 0);
        uint256 last = _amendments.length - 1;
        SignedAgreement storage amendment = _amendments[last];
        return (
            amendment.contractLegalRepresentative,
            amendment.signedBlockTimestamp,
            amendment.agreementUri,
            last
        );
    }

    function pastAgreement(uint256 amendmentIndex)
        public
        constant
        returns
        (
            address contractLegalRepresentative,
            uint256 signedBlockTimestamp,
            string agreementUri,
            uint256 index
        )
    {
        SignedAgreement storage amendment = _amendments[amendmentIndex];
        return (
            amendment.contractLegalRepresentative,
            amendment.signedBlockTimestamp,
            amendment.agreementUri,
            amendmentIndex
        );
    }

    function agreementSignedAtBlock(address signatory)
        public
        constant
        returns (uint256 blockNo)
    {
        return _signatories[signatory];
    }

    function amendmentsCount()
        public
        constant
        returns (uint256)
    {
        return _amendments.length;
    }

     
     
     

     
    function acceptAgreementInternal(address accepter)
        internal
    {
        if(_signatories[accepter] == 0) {
            require(_amendments.length > 0);
            _signatories[accepter] = block.number;
            emit LogAgreementAccepted(accepter);
        }
    }

     
     
     

     
    function mCanAmend(address legalRepresentative)
        internal
        returns (bool)
    {
        return accessPolicy().allowed(legalRepresentative, ROLE_PLATFORM_OPERATOR_REPRESENTATIVE, this, msg.sig);
    }
}

 
 
contract IdentityRecord {

     
     
     

     
     
     
    struct IdentityClaims {
        bool isVerified;  
        bool isSophisticatedInvestor;  
        bool hasBankAccount;  
        bool accountFrozen;  
         
    }

     
     
     

     
    function deserializeClaims(bytes32 data) internal pure returns (IdentityClaims memory claims) {
         
        assembly {
            mstore(claims, and(data, 0x1))
            mstore(add(claims, 0x20), div(and(data, 0x2), 0x2))
            mstore(add(claims, 0x40), div(and(data, 0x4), 0x4))
            mstore(add(claims, 0x60), div(and(data, 0x8), 0x8))
        }
    }
}


 
 
contract IIdentityRegistry {

     
     
     

     
    event LogSetClaims(
        address indexed identity,
        bytes32 oldClaims,
        bytes32 newClaims
    );

     
     
     

     
    function getClaims(address identity) public constant returns (bytes32);

     
     
     
    function setClaims(address identity, bytes32 oldClaims, bytes32 newClaims) public;
}

 
 
 
 
 
contract KnownInterfaces {

     
     
     

     
     
     

     
     

     
    bytes4 internal constant KNOWN_INTERFACE_NEUMARK = 0xeb41a1bd;

     
    bytes4 internal constant KNOWN_INTERFACE_ETHER_TOKEN = 0x8cf73cf1;

     
    bytes4 internal constant KNOWN_INTERFACE_EURO_TOKEN = 0x83c3790b;

     
    bytes4 internal constant KNOWN_INTERFACE_IDENTITY_REGISTRY = 0x0a72e073;

     
    bytes4 internal constant KNOWN_INTERFACE_TOKEN_EXCHANGE_RATE_ORACLE = 0xc6e5349e;

     
    bytes4 internal constant KNOWN_INTERFACE_FEE_DISBURSAL = 0xf4c848e8;

     
    bytes4 internal constant KNOWN_INTERFACE_PLATFORM_PORTFOLIO = 0xaa1590d0;

     
    bytes4 internal constant KNOWN_INTERFACE_TOKEN_EXCHANGE = 0xddd7a521;

     
    bytes4 internal constant KNOWN_INTERFACE_GAS_EXCHANGE = 0x89dbc6de;

     
    bytes4 internal constant KNOWN_INTERFACE_ACCESS_POLICY = 0xb05049d9;

     
    bytes4 internal constant KNOWN_INTERFACE_EURO_LOCK = 0x2347a19e;

     
    bytes4 internal constant KNOWN_INTERFACE_ETHER_LOCK = 0x978a6823;

     
    bytes4 internal constant KNOWN_INTERFACE_ICBM_EURO_LOCK = 0x36021e14;

     
    bytes4 internal constant KNOWN_INTERFACE_ICBM_ETHER_LOCK = 0x0b58f006;

     
    bytes4 internal constant KNOWN_INTERFACE_ICBM_ETHER_TOKEN = 0xae8b50b9;

     
    bytes4 internal constant KNOWN_INTERFACE_ICBM_EURO_TOKEN = 0xc2c6cd72;

     
    bytes4 internal constant KNOWN_INTERFACE_ICBM_COMMITMENT = 0x7f2795ef;

     
    bytes4 internal constant KNOWN_INTERFACE_FORK_ARBITER = 0x2fe7778c;

     
    bytes4 internal constant KNOWN_INTERFACE_PLATFORM_TERMS = 0x75ecd7f8;

     
    bytes4 internal constant KNOWN_INTERFACE_UNIVERSE = 0xbf202454;

     
    bytes4 internal constant KNOWN_INTERFACE_COMMITMENT = 0xfa0e0c60;

     
    bytes4 internal constant KNOWN_INTERFACE_EQUITY_TOKEN_CONTROLLER = 0xfa30b2f1;

     
    bytes4 internal constant KNOWN_INTERFACE_EQUITY_TOKEN = 0xab9885bb;
}

contract IsContract {

     
     
     

    function isContract(address addr)
        internal
        constant
        returns (bool)
    {
        uint256 size;
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract NeumarkIssuanceCurve {

     
     
     

     
    uint256 private constant NEUMARK_CAP = 1500000000000000000000000000;

     
    uint256 private constant INITIAL_REWARD_FRACTION = 6500000000000000000;

     
    uint256 private constant ISSUANCE_LIMIT_EUR_ULPS = 8300000000000000000000000000;

     
    uint256 private constant LINEAR_APPROX_LIMIT_EUR_ULPS = 2100000000000000000000000000;
    uint256 private constant NEUMARKS_AT_LINEAR_LIMIT_ULPS = 1499832501287264827896539871;

    uint256 private constant TOT_LINEAR_NEUMARKS_ULPS = NEUMARK_CAP - NEUMARKS_AT_LINEAR_LIMIT_ULPS;
    uint256 private constant TOT_LINEAR_EUR_ULPS = ISSUANCE_LIMIT_EUR_ULPS - LINEAR_APPROX_LIMIT_EUR_ULPS;

     
     
     

     
     
     
    function incremental(uint256 totalEuroUlps, uint256 euroUlps)
        public
        pure
        returns (uint256 neumarkUlps)
    {
        require(totalEuroUlps + euroUlps >= totalEuroUlps);
        uint256 from = cumulative(totalEuroUlps);
        uint256 to = cumulative(totalEuroUlps + euroUlps);
         
         
        assert(to >= from);
        return to - from;
    }

     
     
     
    function incrementalInverse(uint256 totalEuroUlps, uint256 burnNeumarkUlps)
        public
        pure
        returns (uint256 euroUlps)
    {
        uint256 totalNeumarkUlps = cumulative(totalEuroUlps);
        require(totalNeumarkUlps >= burnNeumarkUlps);
        uint256 fromNmk = totalNeumarkUlps - burnNeumarkUlps;
        uint newTotalEuroUlps = cumulativeInverse(fromNmk, 0, totalEuroUlps);
         
        assert(totalEuroUlps >= newTotalEuroUlps);
        return totalEuroUlps - newTotalEuroUlps;
    }

     
     
     
     
     
    function incrementalInverse(uint256 totalEuroUlps, uint256 burnNeumarkUlps, uint256 minEurUlps, uint256 maxEurUlps)
        public
        pure
        returns (uint256 euroUlps)
    {
        uint256 totalNeumarkUlps = cumulative(totalEuroUlps);
        require(totalNeumarkUlps >= burnNeumarkUlps);
        uint256 fromNmk = totalNeumarkUlps - burnNeumarkUlps;
        uint newTotalEuroUlps = cumulativeInverse(fromNmk, minEurUlps, maxEurUlps);
         
        assert(totalEuroUlps >= newTotalEuroUlps);
        return totalEuroUlps - newTotalEuroUlps;
    }

     
     
     
    function cumulative(uint256 euroUlps)
        public
        pure
        returns(uint256 neumarkUlps)
    {
         
        if (euroUlps >= ISSUANCE_LIMIT_EUR_ULPS) {
            return NEUMARK_CAP;
        }
         
         
        if (euroUlps >= LINEAR_APPROX_LIMIT_EUR_ULPS) {
             
            return NEUMARKS_AT_LINEAR_LIMIT_ULPS + (TOT_LINEAR_NEUMARKS_ULPS * (euroUlps - LINEAR_APPROX_LIMIT_EUR_ULPS)) / TOT_LINEAR_EUR_ULPS;
        }

         
         
         
         
         
         
        uint256 d = 230769230769230769230769231;  
        uint256 term = NEUMARK_CAP;
        uint256 sum = 0;
        uint256 denom = d;
        do assembly {
             
             
            term  := div(mul(term, euroUlps), denom)
            sum   := add(sum, term)
            denom := add(denom, d)
             
            term  := div(mul(term, euroUlps), denom)
            sum   := sub(sum, term)
            denom := add(denom, d)
        } while (term != 0);
        return sum;
    }

     
     
     
     
     
     
     
    function cumulativeInverse(uint256 neumarkUlps, uint256 minEurUlps, uint256 maxEurUlps)
        public
        pure
        returns (uint256 euroUlps)
    {
        require(maxEurUlps >= minEurUlps);
        require(cumulative(minEurUlps) <= neumarkUlps);
        require(cumulative(maxEurUlps) >= neumarkUlps);
        uint256 min = minEurUlps;
        uint256 max = maxEurUlps;

         
        while (max > min) {
            uint256 mid = (max + min) / 2;
            uint256 val = cumulative(mid);
             
             
             
             
             
             
             
             
             
             
            if (val < neumarkUlps) {
                min = mid + 1;
            } else {
                max = mid;
            }
        }
         
         
         
         
         
         
         
         
        return max;
    }

    function neumarkCap()
        public
        pure
        returns (uint256)
    {
        return NEUMARK_CAP;
    }

    function initialRewardFraction()
        public
        pure
        returns (uint256)
    {
        return INITIAL_REWARD_FRACTION;
    }
}

contract IBasicToken {

     
     
     

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

     
     
     

     
     
    function totalSupply()
        public
        constant
        returns (uint256);

     
     
    function balanceOf(address owner)
        public
        constant
        returns (uint256 balance);

     
     
     
     
    function transfer(address to, uint256 amount)
        public
        returns (bool success);

}

 
 
 
 
 
 
 
contract Reclaimable is AccessControlled, AccessRoles {

     
     
     

    IBasicToken constant internal RECLAIM_ETHER = IBasicToken(0x0);

     
     
     

    function reclaim(IBasicToken token)
        public
        only(ROLE_RECLAIMER)
    {
        address reclaimer = msg.sender;
        if(token == RECLAIM_ETHER) {
            reclaimer.transfer(address(this).balance);
        } else {
            uint256 balance = token.balanceOf(this);
            require(token.transfer(reclaimer, balance));
        }
    }
}

 
 
contract ISnapshotable {

     
     
     

     
    event LogSnapshotCreated(uint256 snapshotId);

     
     
     

     
     
    function createSnapshot()
        public
        returns (uint256);

     
    function currentSnapshotId()
        public
        constant
        returns (uint256);
}

 
 
 
contract MSnapshotPolicy {

     
     
     

     
     
     
     
     
     
    function mAdvanceSnapshotId()
        internal
        returns (uint256);

     
     
    function mCurrentSnapshotId()
        internal
        constant
        returns (uint256);

}

 
 
contract Daily is MSnapshotPolicy {

     
     
     

     
    uint256 private MAX_TIMESTAMP = 3938453320844195178974243141571391;

     
     
     

     
     
    constructor(uint256 start) internal {
         
        if (start > 0) {
            uint256 base = dayBase(uint128(block.timestamp));
             
            require(start >= base);
             
            require(start < base + 2**128);
        }
    }

     
     
     

    function snapshotAt(uint256 timestamp)
        public
        constant
        returns (uint256)
    {
        require(timestamp < MAX_TIMESTAMP);

        return dayBase(uint128(timestamp));
    }

     
     
     

     
     
     

    function mAdvanceSnapshotId()
        internal
        returns (uint256)
    {
        return mCurrentSnapshotId();
    }

    function mCurrentSnapshotId()
        internal
        constant
        returns (uint256)
    {
         
        return dayBase(uint128(block.timestamp));
    }

    function dayBase(uint128 timestamp)
        internal
        pure
        returns (uint256)
    {
         
        return 2**128 * (uint256(timestamp) / 1 days);
    }
}

 
 
contract DailyAndSnapshotable is
    Daily,
    ISnapshotable
{

     
     
     

    uint256 private _currentSnapshotId;

     
     
     

     
     
    constructor(uint256 start)
        internal
        Daily(start)
    {
        if (start > 0) {
            _currentSnapshotId = start;
        }
    }

     
     
     

     
     
     

    function createSnapshot()
        public
        returns (uint256)
    {
        uint256 base = dayBase(uint128(block.timestamp));

        if (base > _currentSnapshotId) {
             
            _currentSnapshotId = base;
        } else {
             
            _currentSnapshotId += 1;
        }

         
        emit LogSnapshotCreated(_currentSnapshotId);
        return _currentSnapshotId;
    }

     
     
     

     
     
     

    function mAdvanceSnapshotId()
        internal
        returns (uint256)
    {
        uint256 base = dayBase(uint128(block.timestamp));

         
        if (base > _currentSnapshotId) {
            _currentSnapshotId = base;
            emit LogSnapshotCreated(base);
        }

        return _currentSnapshotId;
    }

    function mCurrentSnapshotId()
        internal
        constant
        returns (uint256)
    {
        uint256 base = dayBase(uint128(block.timestamp));

        return base > _currentSnapshotId ? base : _currentSnapshotId;
    }
}

contract ITokenMetadata {

     
     
     

    function symbol()
        public
        constant
        returns (string);

    function name()
        public
        constant
        returns (string);

    function decimals()
        public
        constant
        returns (uint8);
}

 
 
contract TokenMetadata is ITokenMetadata {

     
     
     

     
    string private NAME;

     
    string private SYMBOL;

     
    uint8 private DECIMALS;

     
    string private VERSION;

     
     
     

     
     
     
     
     
    constructor(
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        string version
    )
        public
    {
        NAME = tokenName;                                  
        SYMBOL = tokenSymbol;                              
        DECIMALS = decimalUnits;                           
        VERSION = version;
    }

     
     
     

    function name()
        public
        constant
        returns (string)
    {
        return NAME;
    }

    function symbol()
        public
        constant
        returns (string)
    {
        return SYMBOL;
    }

    function decimals()
        public
        constant
        returns (uint8)
    {
        return DECIMALS;
    }

    function version()
        public
        constant
        returns (string)
    {
        return VERSION;
    }
}

contract IERC20Allowance {

     
     
     

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

     
     
     

     
     
     
     
     
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256 remaining);

     
     
     
     
     
     
    function approve(address spender, uint256 amount)
        public
        returns (bool success);

     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool success);

}

contract IERC20Token is IBasicToken, IERC20Allowance {

}

 
 
contract MTokenAllowanceController {

     
     
     

     
     
     
     
     
     
    function mOnApprove(
        address owner,
        address spender,
        uint256 amount
    )
        internal
        returns (bool allow);

     
     
     
     
     
     
     
     
     
    function mAllowanceOverride(
        address owner,
        address spender
    )
        internal
        constant
        returns (uint256 allowance);
}

 
 
contract MTokenTransferController {

     
     
     

     
     
     
     
     
     
    function mOnTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        returns (bool allow);

}

 
 
 
contract MTokenController is MTokenTransferController, MTokenAllowanceController {
}

 
 
contract MTokenTransfer {

     
     
     

     
     
     
     
     
     
    function mTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal;
}

contract IERC677Callback {

     
     
     

     
     
     
    function receiveApproval(
        address from,
        uint256 amount,
        address token,  
        bytes data
    )
        public
        returns (bool success);

}

contract IERC677Allowance is IERC20Allowance {

     
     
     

     
     
     
     
     
     
     
    function approveAndCall(address spender, uint256 amount, bytes extraData)
        public
        returns (bool success);

}

contract IERC677Token is IERC20Token, IERC677Allowance {
}

 
 
 
 
 
contract TokenAllowance is
    MTokenTransfer,
    MTokenAllowanceController,
    IERC20Allowance,
    IERC677Token
{

     
     
     

     
     
    mapping (address => mapping (address => uint256)) private _allowed;

     
     
     

    constructor()
        internal
    {
    }

     
     
     

     
     
     

     
     
     
     
     
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256 remaining)
    {
        uint256 override = mAllowanceOverride(owner, spender);
        if (override > 0) {
            return override;
        }
        return _allowed[owner][spender];
    }

     
     
     
     
     
     
    function approve(address spender, uint256 amount)
        public
        returns (bool success)
    {
         
        require(mOnApprove(msg.sender, spender, amount));

         
         
         
         
        require((amount == 0 || _allowed[msg.sender][spender] == 0) && mAllowanceOverride(msg.sender, spender) == 0);

        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool success)
    {
        uint256 allowed = mAllowanceOverride(from, msg.sender);
        if (allowed == 0) {
             
            allowed = _allowed[from][msg.sender];
             
            _allowed[from][msg.sender] -= amount;
        }
        require(allowed >= amount);
        mTransfer(from, to, amount);
        return true;
    }

     
     
     

     
     
     
     
     
     
     
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes extraData
    )
        public
        returns (bool success)
    {
        require(approve(spender, amount));

        success = IERC677Callback(spender).receiveApproval(
            msg.sender,
            amount,
            this,
            extraData
        );
        require(success);

        return true;
    }

     
     
     

     
     
     

     
    function mAllowanceOverride(
        address  ,
        address  
    )
        internal
        constant
        returns (uint256)
    {
        return 0;
    }
}

 
 
 
 
 
contract Snapshot is MSnapshotPolicy {

     
     
     

     
     
     
    struct Values {

         
        uint256 snapshotId;

         
        uint256 value;
    }

     
     
     

    function hasValue(
        Values[] storage values
    )
        internal
        constant
        returns (bool)
    {
        return values.length > 0;
    }

     
    function hasValueAt(
        Values[] storage values,
        uint256 snapshotId
    )
        internal
        constant
        returns (bool)
    {
        require(snapshotId <= mCurrentSnapshotId());
        return values.length > 0 && values[0].snapshotId <= snapshotId;
    }

     
    function getValue(
        Values[] storage values,
        uint256 defaultValue
    )
        internal
        constant
        returns (uint256)
    {
        if (values.length == 0) {
            return defaultValue;
        } else {
            uint256 last = values.length - 1;
            return values[last].value;
        }
    }

     
     
     
     
    function getValueAt(
        Values[] storage values,
        uint256 snapshotId,
        uint256 defaultValue
    )
        internal
        constant
        returns (uint256)
    {
        require(snapshotId <= mCurrentSnapshotId());

         
        if (values.length == 0) {
            return defaultValue;
        }

         
        uint256 last = values.length - 1;
        uint256 lastSnapshot = values[last].snapshotId;
        if (snapshotId >= lastSnapshot) {
            return values[last].value;
        }
        uint256 firstSnapshot = values[0].snapshotId;
        if (snapshotId < firstSnapshot) {
            return defaultValue;
        }
         
        uint256 min = 0;
        uint256 max = last;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
             
            if (values[mid].snapshotId <= snapshotId) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return values[min].value;
    }

     
     
     
    function setValue(
        Values[] storage values,
        uint256 value
    )
        internal
    {
         

        uint256 currentSnapshotId = mAdvanceSnapshotId();
         
        bool empty = values.length == 0;
        if (empty) {
             
            values.push(
                Values({
                    snapshotId: currentSnapshotId,
                    value: value
                })
            );
            return;
        }

        uint256 last = values.length - 1;
        bool hasNewSnapshot = values[last].snapshotId < currentSnapshotId;
        if (hasNewSnapshot) {

             
            bool unmodified = values[last].value == value;
            if (unmodified) {
                return;
            }

             
            values.push(
                Values({
                    snapshotId: currentSnapshotId,
                    value: value
                })
            );
        } else {

             
            bool previousUnmodified = last > 0 && values[last - 1].value == value;
            if (previousUnmodified) {
                 
                delete values[last];
                values.length--;
                return;
            }

             
            values[last].value = value;
        }
    }
}

 
 
 
contract ITokenSnapshots {

     
     
     

     
     
     
     
     
    function totalSupplyAt(uint256 snapshotId)
        public
        constant
        returns(uint256);

     
     
     
     
    function balanceOfAt(address owner, uint256 snapshotId)
        public
        constant
        returns (uint256);

     
     
    function currentSnapshotId()
        public
        constant
        returns (uint256);
}

 
 
 
 
contract IClonedTokenParent is ITokenSnapshots {

     
     
     


     
     
    function parentToken()
        public
        constant
        returns(IClonedTokenParent parent);

     
    function parentSnapshotId()
        public
        constant
        returns(uint256 snapshotId);
}

 
 
 
 
contract BasicSnapshotToken is
    MTokenTransfer,
    MTokenTransferController,
    IClonedTokenParent,
    IBasicToken,
    Snapshot
{
     
     
     

     
     
    IClonedTokenParent private PARENT_TOKEN;

     
     
    uint256 private PARENT_SNAPSHOT_ID;

     
     
     

     
     
     
    mapping (address => Values[]) internal _balances;

     
    Values[] internal _totalSupplyValues;

     
     
     

     
     
     
     
     
     
     
     
    constructor(
        IClonedTokenParent parentToken,
        uint256 parentSnapshotId
    )
        Snapshot()
        internal
    {
        PARENT_TOKEN = parentToken;
        if (parentToken == address(0)) {
            require(parentSnapshotId == 0);
        } else {
            if (parentSnapshotId == 0) {
                require(parentToken.currentSnapshotId() > 0);
                PARENT_SNAPSHOT_ID = parentToken.currentSnapshotId() - 1;
            } else {
                PARENT_SNAPSHOT_ID = parentSnapshotId;
            }
        }
    }

     
     
     

     
     
     

     
     
    function totalSupply()
        public
        constant
        returns (uint256)
    {
        return totalSupplyAtInternal(mCurrentSnapshotId());
    }

     
     
    function balanceOf(address owner)
        public
        constant
        returns (uint256 balance)
    {
        return balanceOfAtInternal(owner, mCurrentSnapshotId());
    }

     
     
     
     
    function transfer(address to, uint256 amount)
        public
        returns (bool success)
    {
        mTransfer(msg.sender, to, amount);
        return true;
    }

     
     
     

    function totalSupplyAt(uint256 snapshotId)
        public
        constant
        returns(uint256)
    {
        return totalSupplyAtInternal(snapshotId);
    }

    function balanceOfAt(address owner, uint256 snapshotId)
        public
        constant
        returns (uint256)
    {
        return balanceOfAtInternal(owner, snapshotId);
    }

    function currentSnapshotId()
        public
        constant
        returns (uint256)
    {
        return mCurrentSnapshotId();
    }

     
     
     

    function parentToken()
        public
        constant
        returns(IClonedTokenParent parent)
    {
        return PARENT_TOKEN;
    }

     
    function parentSnapshotId()
        public
        constant
        returns(uint256 snapshotId)
    {
        return PARENT_SNAPSHOT_ID;
    }

     
     
     

     
     
    function allBalancesOf(address owner)
        external
        constant
        returns (uint256[2][])
    {
         

        Values[] storage values = _balances[owner];
        uint256[2][] memory balances = new uint256[2][](values.length);
        for(uint256 ii = 0; ii < values.length; ++ii) {
            balances[ii] = [values[ii].snapshotId, values[ii].value];
        }

        return balances;
    }

     
     
     

    function totalSupplyAtInternal(uint256 snapshotId)
        internal
        constant
        returns(uint256)
    {
        Values[] storage values = _totalSupplyValues;

         
        if (hasValueAt(values, snapshotId)) {
            return getValueAt(values, snapshotId, 0);
        }

         
        if (address(PARENT_TOKEN) != 0) {
            uint256 earlierSnapshotId = PARENT_SNAPSHOT_ID > snapshotId ? snapshotId : PARENT_SNAPSHOT_ID;
            return PARENT_TOKEN.totalSupplyAt(earlierSnapshotId);
        }

         
        return 0;
    }

     
    function balanceOfAtInternal(address owner, uint256 snapshotId)
        internal
        constant
        returns (uint256)
    {
        Values[] storage values = _balances[owner];

         
        if (hasValueAt(values, snapshotId)) {
            return getValueAt(values, snapshotId, 0);
        }

         
        if (PARENT_TOKEN != address(0)) {
            uint256 earlierSnapshotId = PARENT_SNAPSHOT_ID > snapshotId ? snapshotId : PARENT_SNAPSHOT_ID;
            return PARENT_TOKEN.balanceOfAt(owner, earlierSnapshotId);
        }

         
        return 0;
    }

     
     
     

     
     
     
     
     
     
    function mTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
    {
         
        require(to != address(0));
         
        require(parentToken() == address(0) || parentSnapshotId() < parentToken().currentSnapshotId());
         
        require(mOnTransfer(from, to, amount));

         
         
        uint256 previousBalanceFrom = balanceOf(from);
        require(previousBalanceFrom >= amount);

         
         
        uint256 newBalanceFrom = previousBalanceFrom - amount;
        setValue(_balances[from], newBalanceFrom);

         
         
        uint256 previousBalanceTo = balanceOf(to);
        uint256 newBalanceTo = previousBalanceTo + amount;
        assert(newBalanceTo >= previousBalanceTo);  
        setValue(_balances[to], newBalanceTo);

         
        emit Transfer(from, to, amount);
    }
}

 
 
contract MTokenMint {

     
     
     

     
     
     
     
    function mGenerateTokens(address owner, uint256 amount)
        internal;

     
     
     
     
    function mDestroyTokens(address owner, uint256 amount)
        internal;
}

 
 
contract MintableSnapshotToken is
    BasicSnapshotToken,
    MTokenMint
{

     
     
     

     
     
     
    constructor(
        IClonedTokenParent parentToken,
        uint256 parentSnapshotId
    )
        BasicSnapshotToken(parentToken, parentSnapshotId)
        internal
    {}

     
     
     
    function mGenerateTokens(address owner, uint256 amount)
        internal
    {
         
        require(owner != address(0));
         
        require(parentToken() == address(0) || parentSnapshotId() < parentToken().currentSnapshotId());

        uint256 curTotalSupply = totalSupply();
        uint256 newTotalSupply = curTotalSupply + amount;
        require(newTotalSupply >= curTotalSupply);  

        uint256 previousBalanceTo = balanceOf(owner);
        uint256 newBalanceTo = previousBalanceTo + amount;
        assert(newBalanceTo >= previousBalanceTo);  

        setValue(_totalSupplyValues, newTotalSupply);
        setValue(_balances[owner], newBalanceTo);

        emit Transfer(0, owner, amount);
    }

     
     
     
    function mDestroyTokens(address owner, uint256 amount)
        internal
    {
         
        require(parentToken() == address(0) || parentSnapshotId() < parentToken().currentSnapshotId());

        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply >= amount);

        uint256 previousBalanceFrom = balanceOf(owner);
        require(previousBalanceFrom >= amount);

        uint256 newTotalSupply = curTotalSupply - amount;
        uint256 newBalanceFrom = previousBalanceFrom - amount;
        setValue(_totalSupplyValues, newTotalSupply);
        setValue(_balances[owner], newBalanceFrom);

        emit Transfer(owner, 0, amount);
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract StandardSnapshotToken is
    MintableSnapshotToken,
    TokenAllowance
{
     
     
     

     
     
     
     
     
    constructor(
        IClonedTokenParent parentToken,
        uint256 parentSnapshotId
    )
        MintableSnapshotToken(parentToken, parentSnapshotId)
        TokenAllowance()
        internal
    {}
}

 
 
contract IERC223LegacyCallback {

     
     
     

    function onTokenTransfer(address from, uint256 amount, bytes data)
        public;

}

contract IERC223Token is IERC20Token, ITokenMetadata {

     
     
     

     
     
     
     
     


     
     

     
     
     

     
     
     

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool);
}

contract Neumark is
    AccessControlled,
    AccessRoles,
    Agreement,
    DailyAndSnapshotable,
    StandardSnapshotToken,
    TokenMetadata,
    IERC223Token,
    NeumarkIssuanceCurve,
    Reclaimable,
    IsContract
{

     
     
     

    string private constant TOKEN_NAME = "Neumark";

    uint8  private constant TOKEN_DECIMALS = 18;

    string private constant TOKEN_SYMBOL = "NEU";

    string private constant VERSION = "NMK_1.0";

     
     
     

     
    bool private _transferEnabled = false;

     
     
    uint256 private _totalEurUlps;

     
     
     

    event LogNeumarksIssued(
        address indexed owner,
        uint256 euroUlps,
        uint256 neumarkUlps
    );

    event LogNeumarksBurned(
        address indexed owner,
        uint256 euroUlps,
        uint256 neumarkUlps
    );

     
     
     

    constructor(
        IAccessPolicy accessPolicy,
        IEthereumForkArbiter forkArbiter
    )
        AccessRoles()
        Agreement(accessPolicy, forkArbiter)
        StandardSnapshotToken(
            IClonedTokenParent(0x0),
            0
        )
        TokenMetadata(
            TOKEN_NAME,
            TOKEN_DECIMALS,
            TOKEN_SYMBOL,
            VERSION
        )
        DailyAndSnapshotable(0)
        NeumarkIssuanceCurve()
        Reclaimable()
        public
    {}

     
     
     

     
     
     
    function issueForEuro(uint256 euroUlps)
        public
        only(ROLE_NEUMARK_ISSUER)
        acceptAgreement(msg.sender)
        returns (uint256)
    {
        require(_totalEurUlps + euroUlps >= _totalEurUlps);
        uint256 neumarkUlps = incremental(_totalEurUlps, euroUlps);
        _totalEurUlps += euroUlps;
        mGenerateTokens(msg.sender, neumarkUlps);
        emit LogNeumarksIssued(msg.sender, euroUlps, neumarkUlps);
        return neumarkUlps;
    }

     
     
    function distribute(address to, uint256 neumarkUlps)
        public
        only(ROLE_NEUMARK_ISSUER)
        acceptAgreement(to)
    {
        mTransfer(msg.sender, to, neumarkUlps);
    }

     
     
    function burn(uint256 neumarkUlps)
        public
        only(ROLE_NEUMARK_BURNER)
    {
        burnPrivate(neumarkUlps, 0, _totalEurUlps);
    }

     
    function burn(uint256 neumarkUlps, uint256 minEurUlps, uint256 maxEurUlps)
        public
        only(ROLE_NEUMARK_BURNER)
    {
        burnPrivate(neumarkUlps, minEurUlps, maxEurUlps);
    }

    function enableTransfer(bool enabled)
        public
        only(ROLE_TRANSFER_ADMIN)
    {
        _transferEnabled = enabled;
    }

    function createSnapshot()
        public
        only(ROLE_SNAPSHOT_CREATOR)
        returns (uint256)
    {
        return DailyAndSnapshotable.createSnapshot();
    }

    function transferEnabled()
        public
        constant
        returns (bool)
    {
        return _transferEnabled;
    }

    function totalEuroUlps()
        public
        constant
        returns (uint256)
    {
        return _totalEurUlps;
    }

    function incremental(uint256 euroUlps)
        public
        constant
        returns (uint256 neumarkUlps)
    {
        return incremental(_totalEurUlps, euroUlps);
    }

     
     
     

     
     
    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool)
    {
         
        BasicSnapshotToken.mTransfer(msg.sender, to, amount);

         
        if (isContract(to)) {
            IERC223LegacyCallback(to).onTokenTransfer(msg.sender, amount, data);
        }
        return true;
    }

     
     
     

     
     
     

    function mOnTransfer(
        address from,
        address,  
        uint256  
    )
        internal
        acceptAgreement(from)
        returns (bool allow)
    {
         
        return _transferEnabled || accessPolicy().allowed(msg.sender, ROLE_NEUMARK_ISSUER, this, msg.sig);
    }

    function mOnApprove(
        address owner,
        address,  
        uint256  
    )
        internal
        acceptAgreement(owner)
        returns (bool allow)
    {
        return true;
    }

     
     
     

    function burnPrivate(uint256 burnNeumarkUlps, uint256 minEurUlps, uint256 maxEurUlps)
        private
    {
        uint256 prevEuroUlps = _totalEurUlps;
         
        mDestroyTokens(msg.sender, burnNeumarkUlps);
        _totalEurUlps = cumulativeInverse(totalSupply(), minEurUlps, maxEurUlps);
         
        assert(prevEuroUlps >= _totalEurUlps);
        uint256 euroUlps = prevEuroUlps - _totalEurUlps;
        emit LogNeumarksBurned(msg.sender, euroUlps, burnNeumarkUlps);
    }
}

 
 
 
contract IERC223Callback {

     
     
     

    function tokenFallback(address from, uint256 amount, bytes data)
        public;

}

 
 
contract IFeeDisbursal is IERC223Callback {
     
}

 
 
contract IPlatformPortfolio is IERC223Callback {
     
}

contract ITokenExchangeRateOracle {
     
     
    function getExchangeRate(address numeratorToken, address denominatorToken)
        public
        constant
        returns (uint256 rateFraction, uint256 timestamp);

     
    function getExchangeRates(address[] numeratorTokens, address[] denominatorTokens)
        public
        constant
        returns (uint256[] rateFractions, uint256[] timestamps);
}

 
 
 
 
 
contract Universe is
    Agreement,
    IContractId,
    KnownInterfaces
{
     
     
     

     
     
    event LogSetSingleton(
        bytes4 interfaceId,
        address instance,
        address replacedInstance
    );

     
    event LogSetCollectionInterface(
        bytes4 interfaceId,
        address instance,
        bool isSet
    );

     
     
     

     
    mapping(bytes4 => address) private _singletons;

     
    mapping(bytes4 =>
        mapping(address => bool)) private _collections;  

     
    mapping(address => bytes4[]) private _instances;


     
     
     

    constructor(
        IAccessPolicy accessPolicy,
        IEthereumForkArbiter forkArbiter
    )
        Agreement(accessPolicy, forkArbiter)
        public
    {
        setSingletonPrivate(KNOWN_INTERFACE_ACCESS_POLICY, accessPolicy);
        setSingletonPrivate(KNOWN_INTERFACE_FORK_ARBITER, forkArbiter);
    }

     
     
     

     
    function getSingleton(bytes4 interfaceId)
        public
        constant
        returns (address)
    {
        return _singletons[interfaceId];
    }

    function getManySingletons(bytes4[] interfaceIds)
        public
        constant
        returns (address[])
    {
        address[] memory addresses = new address[](interfaceIds.length);
        uint256 idx;
        while(idx < interfaceIds.length) {
            addresses[idx] = _singletons[interfaceIds[idx]];
            idx += 1;
        }
        return addresses;
    }

     
    function isSingleton(bytes4 interfaceId, address instance)
        public
        constant
        returns (bool)
    {
        return _singletons[interfaceId] == instance;
    }

     
    function isInterfaceCollectionInstance(bytes4 interfaceId, address instance)
        public
        constant
        returns (bool)
    {
        return _collections[interfaceId][instance];
    }

    function isAnyOfInterfaceCollectionInstance(bytes4[] interfaceIds, address instance)
        public
        constant
        returns (bool)
    {
        uint256 idx;
        while(idx < interfaceIds.length) {
            if (_collections[interfaceIds[idx]][instance]) {
                return true;
            }
            idx += 1;
        }
        return false;
    }

     
    function getInterfacesOfInstance(address instance)
        public
        constant
        returns (bytes4[] interfaces)
    {
        return _instances[instance];
    }

     
    function setSingleton(bytes4 interfaceId, address instance)
        public
        only(ROLE_UNIVERSE_MANAGER)
    {
        setSingletonPrivate(interfaceId, instance);
    }

     
    function setManySingletons(bytes4[] interfaceIds, address[] instances)
        public
        only(ROLE_UNIVERSE_MANAGER)
    {
        require(interfaceIds.length == instances.length);
        uint256 idx;
        while(idx < interfaceIds.length) {
            setSingletonPrivate(interfaceIds[idx], instances[idx]);
            idx += 1;
        }
    }

     
    function setCollectionInterface(bytes4 interfaceId, address instance, bool set)
        public
        only(ROLE_UNIVERSE_MANAGER)
    {
        setCollectionPrivate(interfaceId, instance, set);
    }

     
    function setInterfaceInManyCollections(bytes4[] interfaceIds, address instance, bool set)
        public
        only(ROLE_UNIVERSE_MANAGER)
    {
        uint256 idx;
        while(idx < interfaceIds.length) {
            setCollectionPrivate(interfaceIds[idx], instance, set);
            idx += 1;
        }
    }

     
    function setCollectionsInterfaces(bytes4[] interfaceIds, address[] instances, bool[] set_flags)
        public
        only(ROLE_UNIVERSE_MANAGER)
    {
        require(interfaceIds.length == instances.length);
        require(interfaceIds.length == set_flags.length);
        uint256 idx;
        while(idx < interfaceIds.length) {
            setCollectionPrivate(interfaceIds[idx], instances[idx], set_flags[idx]);
            idx += 1;
        }
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x8b57bfe21a3ef4854e19d702063b6cea03fa514162f8ff43fde551f06372fefd, 0);
    }

     
     
     

    function accessPolicy() public constant returns (IAccessPolicy) {
        return IAccessPolicy(_singletons[KNOWN_INTERFACE_ACCESS_POLICY]);
    }

    function forkArbiter() public constant returns (IEthereumForkArbiter) {
        return IEthereumForkArbiter(_singletons[KNOWN_INTERFACE_FORK_ARBITER]);
    }

    function neumark() public constant returns (Neumark) {
        return Neumark(_singletons[KNOWN_INTERFACE_NEUMARK]);
    }

    function etherToken() public constant returns (IERC223Token) {
        return IERC223Token(_singletons[KNOWN_INTERFACE_ETHER_TOKEN]);
    }

    function euroToken() public constant returns (IERC223Token) {
        return IERC223Token(_singletons[KNOWN_INTERFACE_EURO_TOKEN]);
    }

    function etherLock() public constant returns (address) {
        return _singletons[KNOWN_INTERFACE_ETHER_LOCK];
    }

    function euroLock() public constant returns (address) {
        return _singletons[KNOWN_INTERFACE_EURO_LOCK];
    }

    function icbmEtherLock() public constant returns (address) {
        return _singletons[KNOWN_INTERFACE_ICBM_ETHER_LOCK];
    }

    function icbmEuroLock() public constant returns (address) {
        return _singletons[KNOWN_INTERFACE_ICBM_EURO_LOCK];
    }

    function identityRegistry() public constant returns (address) {
        return IIdentityRegistry(_singletons[KNOWN_INTERFACE_IDENTITY_REGISTRY]);
    }

    function tokenExchangeRateOracle() public constant returns (address) {
        return ITokenExchangeRateOracle(_singletons[KNOWN_INTERFACE_TOKEN_EXCHANGE_RATE_ORACLE]);
    }

    function feeDisbursal() public constant returns (address) {
        return IFeeDisbursal(_singletons[KNOWN_INTERFACE_FEE_DISBURSAL]);
    }

    function platformPortfolio() public constant returns (address) {
        return IPlatformPortfolio(_singletons[KNOWN_INTERFACE_PLATFORM_PORTFOLIO]);
    }

    function tokenExchange() public constant returns (address) {
        return _singletons[KNOWN_INTERFACE_TOKEN_EXCHANGE];
    }

    function gasExchange() public constant returns (address) {
        return _singletons[KNOWN_INTERFACE_GAS_EXCHANGE];
    }

    function platformTerms() public constant returns (address) {
        return _singletons[KNOWN_INTERFACE_PLATFORM_TERMS];
    }

     
     
     

    function setSingletonPrivate(bytes4 interfaceId, address instance)
        private
    {
        require(interfaceId != KNOWN_INTERFACE_UNIVERSE, "NF_UNI_NO_UNIVERSE_SINGLETON");
        address replacedInstance = _singletons[interfaceId];
         
        if (replacedInstance != instance) {
            dropInstance(replacedInstance, interfaceId);
            addInstance(instance, interfaceId);
            _singletons[interfaceId] = instance;
        }

        emit LogSetSingleton(interfaceId, instance, replacedInstance);
    }

    function setCollectionPrivate(bytes4 interfaceId, address instance, bool set)
        private
    {
         
        if (_collections[interfaceId][instance] == set) {
            return;
        }
        _collections[interfaceId][instance] = set;
        if (set) {
            addInstance(instance, interfaceId);
        } else {
            dropInstance(instance, interfaceId);
        }
        emit LogSetCollectionInterface(interfaceId, instance, set);
    }

    function addInstance(address instance, bytes4 interfaceId)
        private
    {
        if (instance == address(0)) {
             
            return;
        }
        bytes4[] storage current = _instances[instance];
        uint256 idx;
        while(idx < current.length) {
             
            if (current[idx] == interfaceId)
                return;
            idx += 1;
        }
         
        current.push(interfaceId);
    }

    function dropInstance(address instance, bytes4 interfaceId)
        private
    {
        if (instance == address(0)) {
             
            return;
        }
        bytes4[] storage current = _instances[instance];
        uint256 idx;
        uint256 last = current.length - 1;
        while(idx <= last) {
            if (current[idx] == interfaceId) {
                 
                if (idx < last) {
                     
                    current[idx] = current[last];
                }
                 
                current.length -= 1;
                return;
            }
            idx += 1;
        }
    }
}

 
contract ETODurationTerms is IContractId {

     
     
     

     
    uint32 public WHITELIST_DURATION;

     
    uint32 public PUBLIC_DURATION;

     
    uint32 public SIGNING_DURATION;

     
    uint32 public CLAIM_DURATION;

     
     
     

    constructor(
        uint32 whitelistDuration,
        uint32 publicDuration,
        uint32 signingDuration,
        uint32 claimDuration
    )
        public
    {
        WHITELIST_DURATION = whitelistDuration;
        PUBLIC_DURATION = publicDuration;
        SIGNING_DURATION = signingDuration;
        CLAIM_DURATION = claimDuration;
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x5fb50201b453799d95f8a80291b940f1c543537b95bff2e3c78c2e36070494c0, 0);
    }
}

 
contract ETOTokenTerms is IContractId {

     
     
     

     
    uint256 public MIN_NUMBER_OF_TOKENS;
     
    uint256 public MAX_NUMBER_OF_TOKENS;
     
    uint256 public TOKEN_PRICE_EUR_ULPS;
     
    uint256 public MAX_NUMBER_OF_TOKENS_IN_WHITELIST;
     
    uint256 public constant EQUITY_TOKENS_PER_SHARE = 10000;
     
    uint8 public constant EQUITY_TOKENS_PRECISION = 0;  


     
     
     

    constructor(
        uint256 minNumberOfTokens,
        uint256 maxNumberOfTokens,
        uint256 tokenPriceEurUlps,
        uint256 maxNumberOfTokensInWhitelist
    )
        public
    {
        require(maxNumberOfTokensInWhitelist <= maxNumberOfTokens);
        require(maxNumberOfTokens >= minNumberOfTokens);
         
        require(minNumberOfTokens >= EQUITY_TOKENS_PER_SHARE, "NF_ETO_TERMS_ONE_SHARE");

        MIN_NUMBER_OF_TOKENS = minNumberOfTokens;
        MAX_NUMBER_OF_TOKENS = maxNumberOfTokens;
        TOKEN_PRICE_EUR_ULPS = tokenPriceEurUlps;
        MAX_NUMBER_OF_TOKENS_IN_WHITELIST = maxNumberOfTokensInWhitelist;
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x591e791aab2b14c80194b729a2abcba3e8cce1918be4061be170e7223357ae5c, 0);
    }
}

 
 
 
contract ETOTerms is
    IdentityRecord,
    Math,
    IContractId
{

     
     
     

     
    struct WhitelistTicket {
         
        uint128 discountAmountEurUlps;
         
        uint128 fullTokenPriceFrac;
    }

     
     
     

    bytes32 private constant EMPTY_STRING_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    uint256 public constant MIN_QUALIFIED_INVESTOR_TICKET_EUR_ULPS = 100000 * 10**18;

     
     
     

     
    ETODurationTerms public DURATION_TERMS;
     
    ETOTokenTerms public TOKEN_TERMS;
     
    uint256 public EXISTING_COMPANY_SHARES;
     
    uint256 public SHARE_NOMINAL_VALUE_EUR_ULPS;
     
     
     
    uint256 public MIN_TICKET_EUR_ULPS;
     
    uint256 public MAX_TICKET_EUR_ULPS;
     
    uint256 public MAX_TICKET_SIMPLE_EUR_ULPS;
     
     
     
     
    bool public ENABLE_TRANSFERS_ON_SUCCESS;
     
     
    bool public ALLOW_RETAIL_INVESTORS;
     
    uint256 public WHITELIST_DISCOUNT_FRAC;
     
     
    uint256 public PUBLIC_DISCOUNT_FRAC;

     
     
    string public INVESTOR_OFFERING_DOCUMENT_URL;
     
    ShareholderRights public SHAREHOLDER_RIGHTS;

     
    string public EQUITY_TOKEN_NAME;
    string public EQUITY_TOKEN_SYMBOL;

     
    address public WHITELIST_MANAGER;
     
    IIdentityRegistry public IDENTITY_REGISTRY;
    Universe public UNIVERSE;

     
     
    uint256 private MIN_NUMBER_OF_TOKENS;
     
    uint256 private MAX_NUMBER_OF_TOKENS;
     
    uint256 private TOKEN_PRICE_EUR_ULPS;


     
     
     

     
    mapping (address => WhitelistTicket) private _whitelist;

     
     
     

    modifier onlyWhitelistManager() {
        require(msg.sender == WHITELIST_MANAGER);
        _;
    }

     
     
     

     
    event LogInvestorWhitelisted(
        address indexed investor,
        uint256 discountAmountEurUlps,
        uint256 fullTokenPriceFrac
    );

     
     
     

    constructor(
        Universe universe,
        ETODurationTerms durationTerms,
        ETOTokenTerms tokenTerms,
        uint256 existingCompanyShares,
        uint256 minTicketEurUlps,
        uint256 maxTicketEurUlps,
        bool allowRetailInvestors,
        bool enableTransfersOnSuccess,
        string investorOfferingDocumentUrl,
        ShareholderRights shareholderRights,
        string equityTokenName,
        string equityTokenSymbol,
        uint256 shareNominalValueEurUlps,
        uint256 whitelistDiscountFrac,
        uint256 publicDiscountFrac
    )
        public
    {
        require(durationTerms != address(0));
        require(tokenTerms != address(0));
        require(existingCompanyShares > 0);
        require(keccak256(abi.encodePacked(investorOfferingDocumentUrl)) != EMPTY_STRING_HASH);
        require(keccak256(abi.encodePacked(equityTokenName)) != EMPTY_STRING_HASH);
        require(keccak256(abi.encodePacked(equityTokenSymbol)) != EMPTY_STRING_HASH);
        require(shareholderRights != address(0));
         
         
        require(shareNominalValueEurUlps > 0);
        require(whitelistDiscountFrac >= 0 && whitelistDiscountFrac <= 99*10**16);
        require(publicDiscountFrac >= 0 && publicDiscountFrac <= 99*10**16);
        require(minTicketEurUlps<=maxTicketEurUlps);

         
        MIN_NUMBER_OF_TOKENS = tokenTerms.MIN_NUMBER_OF_TOKENS();
        MAX_NUMBER_OF_TOKENS = tokenTerms.MAX_NUMBER_OF_TOKENS();
        TOKEN_PRICE_EUR_ULPS = tokenTerms.TOKEN_PRICE_EUR_ULPS();

        DURATION_TERMS = durationTerms;
        TOKEN_TERMS = tokenTerms;
        EXISTING_COMPANY_SHARES = existingCompanyShares;
        MIN_TICKET_EUR_ULPS = minTicketEurUlps;
        MAX_TICKET_EUR_ULPS = maxTicketEurUlps;
        ALLOW_RETAIL_INVESTORS = allowRetailInvestors;
        ENABLE_TRANSFERS_ON_SUCCESS = enableTransfersOnSuccess;
        INVESTOR_OFFERING_DOCUMENT_URL = investorOfferingDocumentUrl;
        SHAREHOLDER_RIGHTS = shareholderRights;
        EQUITY_TOKEN_NAME = equityTokenName;
        EQUITY_TOKEN_SYMBOL = equityTokenSymbol;
        SHARE_NOMINAL_VALUE_EUR_ULPS = shareNominalValueEurUlps;
        WHITELIST_DISCOUNT_FRAC = whitelistDiscountFrac;
        PUBLIC_DISCOUNT_FRAC = publicDiscountFrac;
        WHITELIST_MANAGER = msg.sender;
        IDENTITY_REGISTRY = IIdentityRegistry(universe.identityRegistry());
        UNIVERSE = universe;
    }

     
     
     

     
     
    function calculateTokenAmount(uint256  , uint256 committedEurUlps)
        public
        constant
        returns (uint256 tokenAmountInt)
    {
         
        return committedEurUlps / calculatePriceFraction(10**18 - PUBLIC_DISCOUNT_FRAC);
    }

     
     
    function calculateEurUlpsAmount(uint256  , uint256 tokenAmountInt)
        public
        constant
        returns (uint256 committedEurUlps)
    {
         
        return mul(tokenAmountInt, calculatePriceFraction(10**18 - PUBLIC_DISCOUNT_FRAC));
    }

     
    function ESTIMATED_MIN_CAP_EUR_ULPS() public constant returns(uint256) {
        return calculateEurUlpsAmount(0, MIN_NUMBER_OF_TOKENS);
    }

     
    function ESTIMATED_MAX_CAP_EUR_ULPS() public constant returns(uint256) {
        return calculateEurUlpsAmount(0, MAX_NUMBER_OF_TOKENS);
    }

    function calculatePriceFraction(uint256 priceFrac) public constant returns(uint256) {
        if (priceFrac == 1) {
            return TOKEN_PRICE_EUR_ULPS;
        } else {
            return decimalFraction(priceFrac, TOKEN_PRICE_EUR_ULPS);
        }
    }

    function addWhitelisted(
        address[] investors,
        uint256[] discountAmountsEurUlps,
        uint256[] discountsFrac
    )
        external
        onlyWhitelistManager
    {
        require(investors.length == discountAmountsEurUlps.length);
        require(investors.length == discountsFrac.length);

        for (uint256 i = 0; i < investors.length; i += 1) {
            addWhitelistInvestorPrivate(investors[i], discountAmountsEurUlps[i], discountsFrac[i]);
        }
    }

    function whitelistTicket(address investor)
        public
        constant
        returns (bool isWhitelisted, uint256 discountAmountEurUlps, uint256 fullTokenPriceFrac)
    {
        WhitelistTicket storage wlTicket = _whitelist[investor];
        isWhitelisted = wlTicket.fullTokenPriceFrac > 0;
        discountAmountEurUlps = wlTicket.discountAmountEurUlps;
        fullTokenPriceFrac = wlTicket.fullTokenPriceFrac;
    }

     
    function calculateContribution(
        address investor,
        uint256 totalContributedEurUlps,
        uint256 existingInvestorContributionEurUlps,
        uint256 newInvestorContributionEurUlps,
        bool applyWhitelistDiscounts
    )
        public
        constant
        returns (
            bool isWhitelisted,
            bool isEligible,
            uint256 minTicketEurUlps,
            uint256 maxTicketEurUlps,
            uint256 equityTokenInt,
            uint256 fixedSlotEquityTokenInt
            )
    {
        (
            isWhitelisted,
            minTicketEurUlps,
            maxTicketEurUlps,
            equityTokenInt,
            fixedSlotEquityTokenInt
        ) = calculateContributionPrivate(
            investor,
            totalContributedEurUlps,
            existingInvestorContributionEurUlps,
            newInvestorContributionEurUlps,
            applyWhitelistDiscounts);
         
        IdentityClaims memory claims = deserializeClaims(IDENTITY_REGISTRY.getClaims(investor));
        isEligible = claims.isVerified && !claims.accountFrozen;
    }

    function equityTokensToShares(uint256 amount)
        public
        constant
        returns (uint256)
    {
        return divRound(amount, TOKEN_TERMS.EQUITY_TOKENS_PER_SHARE());
    }

     
    function requireValidTerms(PlatformTerms platformTerms)
        public
        constant
        returns (bool)
    {
         
        if (ALLOW_RETAIL_INVESTORS) {
             
            require(!ENABLE_TRANSFERS_ON_SUCCESS, "NF_MUST_DISABLE_TRANSFERS");
        } else {
             
            require(MIN_TICKET_EUR_ULPS >= MIN_QUALIFIED_INVESTOR_TICKET_EUR_ULPS, "NF_MIN_QUALIFIED_INVESTOR_TICKET");
        }
         
        require(MIN_TICKET_EUR_ULPS >= TOKEN_TERMS.TOKEN_PRICE_EUR_ULPS(), "NF_MIN_TICKET_LT_TOKEN_PRICE");
         
        require(ESTIMATED_MAX_CAP_EUR_ULPS() >= MIN_TICKET_EUR_ULPS, "NF_MAX_FUNDS_LT_MIN_TICKET");

        require(MIN_TICKET_EUR_ULPS >= platformTerms.MIN_TICKET_EUR_ULPS(), "NF_ETO_TERMS_MIN_TICKET_EUR_ULPS");
         
        require(DURATION_TERMS.WHITELIST_DURATION() >= platformTerms.MIN_WHITELIST_DURATION(), "NF_ETO_TERMS_WL_D_MIN");
        require(DURATION_TERMS.WHITELIST_DURATION() <= platformTerms.MAX_WHITELIST_DURATION(), "NF_ETO_TERMS_WL_D_MAX");

        require(DURATION_TERMS.PUBLIC_DURATION() >= platformTerms.MIN_PUBLIC_DURATION(), "NF_ETO_TERMS_PUB_D_MIN");
        require(DURATION_TERMS.PUBLIC_DURATION() <= platformTerms.MAX_PUBLIC_DURATION(), "NF_ETO_TERMS_PUB_D_MAX");

        uint256 totalDuration = DURATION_TERMS.WHITELIST_DURATION() + DURATION_TERMS.PUBLIC_DURATION();
        require(totalDuration >= platformTerms.MIN_OFFER_DURATION(), "NF_ETO_TERMS_TOT_O_MIN");
        require(totalDuration <= platformTerms.MAX_OFFER_DURATION(), "NF_ETO_TERMS_TOT_O_MAX");

        require(DURATION_TERMS.SIGNING_DURATION() >= platformTerms.MIN_SIGNING_DURATION(), "NF_ETO_TERMS_SIG_MIN");
        require(DURATION_TERMS.SIGNING_DURATION() <= platformTerms.MAX_SIGNING_DURATION(), "NF_ETO_TERMS_SIG_MAX");

        require(DURATION_TERMS.CLAIM_DURATION() >= platformTerms.MIN_CLAIM_DURATION(), "NF_ETO_TERMS_CLAIM_MIN");
        require(DURATION_TERMS.CLAIM_DURATION() <= platformTerms.MAX_CLAIM_DURATION(), "NF_ETO_TERMS_CLAIM_MAX");

        return true;
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x3468b14073c33fa00ee7f8a289b14f4a10c78ab72726033b27003c31c47b3f6a, 0);
    }

     
     
     

    function calculateContributionPrivate(
        address investor,
        uint256 totalContributedEurUlps,
        uint256 existingInvestorContributionEurUlps,
        uint256 newInvestorContributionEurUlps,
        bool applyWhitelistDiscounts
    )
        private
        constant
        returns (
            bool isWhitelisted,
            uint256 minTicketEurUlps,
            uint256 maxTicketEurUlps,
            uint256 equityTokenInt,
            uint256 fixedSlotEquityTokenInt
        )
    {
        uint256 discountedAmount;
        minTicketEurUlps = MIN_TICKET_EUR_ULPS;
        maxTicketEurUlps = MAX_TICKET_EUR_ULPS;
        WhitelistTicket storage wlTicket = _whitelist[investor];
         
        isWhitelisted = wlTicket.fullTokenPriceFrac > 0;
         
        if (applyWhitelistDiscounts) {
             
            maxTicketEurUlps = max(wlTicket.discountAmountEurUlps, maxTicketEurUlps);
             
            if (wlTicket.discountAmountEurUlps > 0) {
                minTicketEurUlps = min(wlTicket.discountAmountEurUlps, minTicketEurUlps);
            }
            if (existingInvestorContributionEurUlps < wlTicket.discountAmountEurUlps) {
                discountedAmount = min(newInvestorContributionEurUlps, wlTicket.discountAmountEurUlps - existingInvestorContributionEurUlps);
                 
                if (discountedAmount > 0) {
                     
                    fixedSlotEquityTokenInt = discountedAmount / calculatePriceFraction(wlTicket.fullTokenPriceFrac);
                }
            }
        }
         
        uint256 remainingAmount = newInvestorContributionEurUlps - discountedAmount;
        if (remainingAmount > 0) {
            if (applyWhitelistDiscounts && WHITELIST_DISCOUNT_FRAC > 0) {
                 
                equityTokenInt = remainingAmount / calculatePriceFraction(10**18 - WHITELIST_DISCOUNT_FRAC);
            } else {
                 
                equityTokenInt = calculateTokenAmount(totalContributedEurUlps + discountedAmount, remainingAmount);
            }
        }
         
        equityTokenInt += fixedSlotEquityTokenInt;

    }

    function addWhitelistInvestorPrivate(
        address investor,
        uint256 discountAmountEurUlps,
        uint256 fullTokenPriceFrac
    )
        private
    {
         
        require(investor != address(0));
        require(fullTokenPriceFrac > 0 && fullTokenPriceFrac <= 10**18, "NF_DISCOUNT_RANGE");
        require(discountAmountEurUlps < 2**128);


        _whitelist[investor] = WhitelistTicket({
            discountAmountEurUlps: uint128(discountAmountEurUlps),
            fullTokenPriceFrac: uint128(fullTokenPriceFrac)
        });

        emit LogInvestorWhitelisted(investor, discountAmountEurUlps, fullTokenPriceFrac);
    }

}