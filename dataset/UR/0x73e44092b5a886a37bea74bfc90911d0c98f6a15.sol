 

pragma solidity 0.4.26;

 
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

     
    bytes32 internal constant ROLE_WHITELIST_ADMIN = 0xaef456e7c864418e1d2a40d996ca4febf3a7e317fe3af5a7ea4dda59033bbe5c;

     
    bytes32 internal constant ROLE_EURT_DEPOSIT_MANAGER = 0x7c8ecdcba80ce87848d16ad77ef57cc196c208fc95c5638e4a48c681a34d4fe7;

     
    bytes32 internal constant ROLE_IDENTITY_MANAGER = 0x32964e6bc50f2aaab2094a1d311be8bda920fc4fb32b2fb054917bdb153a9e9e;

     
    bytes32 internal constant ROLE_EURT_LEGAL_MANAGER = 0x4eb6b5806954a48eb5659c9e3982d5e75bfb2913f55199877d877f157bcc5a9b;

     
    bytes32 internal constant ROLE_UNIVERSE_MANAGER = 0xe8d8f8f9ea4b19a5a4368dbdace17ad71a69aadeb6250e54c7b4c7b446301738;

     
    bytes32 internal constant ROLE_GAS_EXCHANGE = 0x9fe43636e0675246c99e96d7abf9f858f518b9442c35166d87f0934abef8a969;

     
    bytes32 internal constant ROLE_TOKEN_RATE_ORACLE = 0xa80c3a0c8a5324136e4c806a778583a2a980f378bdd382921b8d28dcfe965585;

     
    bytes32 internal constant ROLE_DISBURSER = 0xd7ea6093d11d866c9e8449f8bffd9da1387c530ee40ad54f0641425bb0ca33b7;

     
    bytes32 internal constant ROLE_DISBURSAL_MANAGER = 0x677f87f7b7ef7c97e42a7e6c85c295cf020c9f11eea1e49f6bf847d7aeae1475;

     
    bytes32 internal constant ROLE_COMPANY_UPGRADE_ADMIN = 0xfef15747c403732d986b29a92a880d8f2fb886b99417c8bbef226f85885ca924;
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

contract IERC223Token is IERC20Token, ITokenMetadata {

     
     
     

     
     
     
     
     


     
     

     
     
     

     
     
     

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool);
}

contract IERC677Allowance is IERC20Allowance {

     
     
     

     
     
     
     
     
     
     
    function approveAndCall(address spender, uint256 amount, bytes extraData)
        public
        returns (bool success);

}

contract IERC677Token is IERC20Token, IERC677Allowance {
}

 
contract ITokenControllerHook {

     
     
     

    event LogChangeTokenController(
        address oldController,
        address newController,
        address by
    );

     
     
     

     
     
    function changeTokenController(address newController)
        public;

     
    function tokenController()
        public
        constant
        returns (address currentController);

}

 
contract IETOCommitmentStates {
     
     
     

     
    enum ETOState {
        Setup,  
        Whitelist,
        Public,
        Signing,
        Claim,
        Payout,  
        Refund  
    }

     
    uint256 constant internal ETO_STATES_COUNT = 7;
}

 
 
contract IETOCommitmentObserver is IETOCommitmentStates {
    function commitmentObserver() public constant returns (address);
    function onStateTransition(ETOState oldState, ETOState newState) public;
}

 
 
 
contract IERC223Callback {

     
     
     

    function tokenFallback(address from, uint256 amount, bytes data)
        public;

}

 
contract ITokenController {

     
     
     

     
     
     
    function onTransfer(address broker, address from, address to, uint256 amount)
        public
        constant
        returns (bool allow);

     
    function onApprove(address owner, address spender, uint256 amount)
        public
        constant
        returns (bool allow);

     
    function onGenerateTokens(address sender, address owner, uint256 amount)
        public
        constant
        returns (bool allow);

     
    function onDestroyTokens(address sender, address owner, uint256 amount)
        public
        constant
        returns (bool allow);

     
     
    function onChangeTokenController(address sender, address newController)
        public
        constant
        returns (bool);

     
     
     
     
     
     
    function onAllowance(address owner, address spender)
        public
        constant
        returns (uint256 allowanceOverride);
}

contract IEquityTokenController is
    IAgreement,
    ITokenController,
    IETOCommitmentObserver,
    IERC223Callback
{
     
     
    function onChangeNominee(address sender, address oldNominee, address newNominee)
        public
        constant
        returns (bool);
}

contract IEquityToken is
    IAgreement,
    IClonedTokenParent,
    IERC223Token,
    ITokenControllerHook
{
     
     
    function tokensPerShare() public constant returns (uint256);

     
    function sharesTotalSupply() public constant returns (uint256);

     
    function shareNominalValueUlps() public constant returns (uint256);

     
    function companyLegalRepresentative() public constant returns (address);

     
    function nominee() public constant returns (address);

     
    function changeNominee(address newNominee) public;

     
    function issueTokens(uint256 amount) public;

     
    function distributeTokens(address to, uint256 amount) public;

     
    function destroyTokens(uint256 amount) public;
}

 
 
contract IdentityRecord {

     
     
     

     
     
     
    struct IdentityClaims {
        bool isVerified;  
        bool isSophisticatedInvestor;  
        bool hasBankAccount;  
        bool accountFrozen;  
        bool requiresRegDAccreditation;  
        bool hasValidRegDAccreditation;  
         
    }

     
     
     

     
    function deserializeClaims(bytes32 data) internal pure returns (IdentityClaims memory claims) {
         
         
        assembly {
            mstore(claims, and(data, 0x1))
            mstore(add(claims, 0x20), div(and(data, 0x2), 0x2))
            mstore(add(claims, 0x40), div(and(data, 0x4), 0x4))
            mstore(add(claims, 0x60), div(and(data, 0x8), 0x8))
            mstore(add(claims, 0x80), div(and(data, 0x10), 0x10))
            mstore(add(claims, 0xA0), div(and(data, 0x20), 0x20))
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

     
    bytes4 internal constant KNOWN_INTERFACE_EURO_TOKEN_CONTROLLER = 0x33ac4661;

     
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

     
    bytes4 internal constant KNOWN_INTERFACE_PAYMENT_TOKEN = 0xb2a0042a;

     
    bytes4 internal constant KNOWN_INTERFACE_ETO_TERMS_CONSTRAINTS = 0xce2be4f5;
}

 
 
contract IMigrationTarget {

     
     
     

     
    function currentMigrationSource()
        public
        constant
        returns (address);
}

 
 
 
 
 
contract IMigrationSource {

     
     
     

    event LogMigrationEnabled(
        address target
    );

     
     
     

     
     
    function migrate()
        public;

     
     
    function enableMigration(IMigrationTarget migration)
        public;

     
    function currentMigrationTarget()
        public
        constant
        returns (IMigrationTarget);
}

 
 
contract MigrationSource is
    IMigrationSource,
    AccessControlled
{
     
     
     

     
    bytes32 private MIGRATION_ADMIN;

     
     
     

     
    IMigrationTarget internal _migration;

     
     
     

     
     
    modifier onlyMigrationEnabledOnce() {
        require(address(_migration) == 0);
        _;
    }

    modifier onlyMigrationEnabled() {
        require(address(_migration) != 0);
        _;
    }

     
     
     

    constructor(
        IAccessPolicy policy,
        bytes32 migrationAdminRole
    )
        AccessControlled(policy)
        internal
    {
        MIGRATION_ADMIN = migrationAdminRole;
    }

     
     
     

     
     
    function migrate()
        public;

     
     
    function enableMigration(IMigrationTarget migration)
        public
        onlyMigrationEnabledOnce()
        only(MIGRATION_ADMIN)
    {
         
        require(migration.currentMigrationSource() == address(this));
        _migration = migration;
        emit LogMigrationEnabled(_migration);
    }

     
    function currentMigrationTarget()
        public
        constant
        returns (IMigrationTarget)
    {
        return _migration;
    }
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

contract TrustlessTokenController is
    MTokenController
{
     
     
     

     
     
     

    function mOnTransfer(
        address  ,
        address  ,
        uint256  
    )
        internal
        returns (bool allow)
    {
        return true;
    }

    function mOnApprove(
        address  ,
        address  ,
        uint256  
    )
        internal
        returns (bool allow)
    {
        return true;
    }
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

 
 
contract MTokenTransfer {

     
     
     

     
     
     
     
     
     
    function mTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal;
}

 
contract BasicToken is
    MTokenTransfer,
    MTokenTransferController,
    IBasicToken,
    Math
{

     
     
     

    mapping(address => uint256) internal _balances;

    uint256 internal _totalSupply;

     
     
     

     
    function transfer(address to, uint256 amount)
        public
        returns (bool)
    {
        mTransfer(msg.sender, to, amount);
        return true;
    }

     
     
    function totalSupply()
        public
        constant
        returns (uint256)
    {
        return _totalSupply;
    }

     
    function balanceOf(address owner)
        public
        constant
        returns (uint256 balance)
    {
        return _balances[owner];
    }

     
     
     

     
     
     

    function mTransfer(address from, address to, uint256 amount)
        internal
    {
        require(to != address(0));
        require(mOnTransfer(from, to, amount));

        _balances[from] = sub(_balances[from], amount);
        _balances[to] = add(_balances[to], amount);
        emit Transfer(from, to, amount);
    }
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

 
contract StandardToken is
    IERC20Token,
    BasicToken,
    TokenAllowance
{

}

 
 
 
 
 
 
contract IContractId {
     
     
    function contractId() public pure returns (bytes32 id, uint256 version);
}

contract IWithdrawableToken {

     
     
     

     
     
    function withdraw(uint256 amount)
        public;
}

contract EtherToken is
    IsContract,
    IContractId,
    AccessControlled,
    StandardToken,
    TrustlessTokenController,
    IWithdrawableToken,
    TokenMetadata,
    IERC223Token,
    Reclaimable
{
     
     
     

    string private constant NAME = "Ether Token";

    string private constant SYMBOL = "ETH-T";

    uint8 private constant DECIMALS = 18;

     
     
     

    event LogDeposit(
        address indexed to,
        uint256 amount
    );

    event LogWithdrawal(
        address indexed from,
        uint256 amount
    );

    event LogWithdrawAndSend(
        address indexed from,
        address indexed to,
        uint256 amount
    );

     
     
     

    constructor(IAccessPolicy accessPolicy)
        AccessControlled(accessPolicy)
        StandardToken()
        TokenMetadata(NAME, DECIMALS, SYMBOL, "")
        Reclaimable()
        public
    {
    }

     
     
     

     
    function deposit()
        public
        payable
    {
        depositPrivate();
        emit Transfer(address(0), msg.sender, msg.value);
    }

     
     
     
     
     
    function depositAndTransfer(address transferTo, uint256 amount, bytes data)
        public
        payable
    {
        depositPrivate();
        transfer(transferTo, amount, data);
    }

     
    function withdraw(uint256 amount)
        public
    {
        withdrawPrivate(amount);
        msg.sender.transfer(amount);
    }

     
     
     
     
     
     
    function withdrawAndSend(address sendTo, uint256 amount)
        public
        payable
    {
         
        require(amount >= msg.value, "NF_ET_NO_DEPOSIT");
        if (amount > msg.value) {
            uint256 withdrawRemainder = amount - msg.value;
            withdrawPrivate(withdrawRemainder);
        }
        emit LogWithdrawAndSend(msg.sender, sendTo, amount);
        sendTo.transfer(amount);
    }

     
     
     

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool)
    {
        BasicToken.mTransfer(msg.sender, to, amount);

         
        if (isContract(to)) {
             
            IERC223Callback(to).tokenFallback(msg.sender, amount, data);
        }
        return true;
    }

     
     
     

     
     
     
    function reclaim(IBasicToken token)
        public
    {
         
        require(token != RECLAIM_ETHER);
        Reclaimable.reclaim(token);
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x75b86bc24f77738576716a36431588ae768d80d077231d1661c2bea674c6373a, 0);
    }


     
     
     

    function depositPrivate()
        private
    {
        _balances[msg.sender] = add(_balances[msg.sender], msg.value);
        _totalSupply = add(_totalSupply, msg.value);
        emit LogDeposit(msg.sender, msg.value);
    }

    function withdrawPrivate(uint256 amount)
        private
    {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = sub(_balances[msg.sender], amount);
        _totalSupply = sub(_totalSupply, amount);
        emit LogWithdrawal(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}

contract EuroToken is
    Agreement,
    IERC677Token,
    StandardToken,
    IWithdrawableToken,
    ITokenControllerHook,
    TokenMetadata,
    IERC223Token,
    IsContract,
    IContractId
{
     
     
     

    string private constant NAME = "Euro Token";

    string private constant SYMBOL = "EUR-T";

    uint8 private constant DECIMALS = 18;

     
     
     

    ITokenController private _tokenController;

     
     
     

     
     
    event LogDeposit(
        address indexed to,
        address by,
        uint256 amount,
        bytes32 reference
    );

     
    event LogWithdrawal(
        address indexed from,
        uint256 amount
    );

     
    event LogWithdrawSettled(
        address from,
        address by,  
        uint256 amount,  
        uint256 originalAmount,  
        bytes32 withdrawTxHash,  
        bytes32 reference  
    );

     
    event LogDestroy(
        address indexed from,
        address by,
        uint256 amount
    );

     
     
     

    modifier onlyIfDepositAllowed(address to, uint256 amount) {
        require(_tokenController.onGenerateTokens(msg.sender, to, amount));
        _;
    }

    modifier onlyIfWithdrawAllowed(address from, uint256 amount) {
        require(_tokenController.onDestroyTokens(msg.sender, from, amount));
        _;
    }

     
     
     

    constructor(
        IAccessPolicy accessPolicy,
        IEthereumForkArbiter forkArbiter,
        ITokenController tokenController
    )
        Agreement(accessPolicy, forkArbiter)
        StandardToken()
        TokenMetadata(NAME, DECIMALS, SYMBOL, "")
        public
    {
        require(tokenController != ITokenController(0x0));
        _tokenController = tokenController;
    }

     
     
     

     
     
     
    function deposit(address to, uint256 amount, bytes32 reference)
        public
        only(ROLE_EURT_DEPOSIT_MANAGER)
        onlyIfDepositAllowed(to, amount)
        acceptAgreement(to)
    {
        require(to != address(0));
        _balances[to] = add(_balances[to], amount);
        _totalSupply = add(_totalSupply, amount);
        emit LogDeposit(to, msg.sender, amount, reference);
        emit Transfer(address(0), to, amount);
    }

     
     
     
    function depositMany(address[] to, uint256[] amount, bytes32[] reference)
        public
    {
        require(to.length == amount.length);
        require(to.length == reference.length);
        for (uint256 i = 0; i < to.length; i++) {
            deposit(to[i], amount[i], reference[i]);
        }
    }

     
     
     
    function withdraw(uint256 amount)
        public
        onlyIfWithdrawAllowed(msg.sender, amount)
        acceptAgreement(msg.sender)
    {
        destroyTokensPrivate(msg.sender, amount);
        emit LogWithdrawal(msg.sender, amount);
    }

     
     
     
    function settleWithdraw(address from, uint256 amount, uint256 originalAmount, bytes32 withdrawTxHash, bytes32 reference)
        public
        only(ROLE_EURT_DEPOSIT_MANAGER)
    {
        emit LogWithdrawSettled(from, msg.sender, amount, originalAmount, withdrawTxHash, reference);
    }

     
     
     
     
    function destroy(address owner, uint256 amount)
        public
        only(ROLE_EURT_LEGAL_MANAGER)
    {
        destroyTokensPrivate(owner, amount);
        emit LogDestroy(owner, msg.sender, amount);
    }

     
     
     

    function changeTokenController(address newController)
        public
    {
        require(_tokenController.onChangeTokenController(msg.sender, newController));
        _tokenController = ITokenController(newController);
        emit LogChangeTokenController(_tokenController, newController, msg.sender);
    }

    function tokenController()
        public
        constant
        returns (address)
    {
        return _tokenController;
    }

     
     
     
    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool success)
    {
        return ierc223TransferInternal(msg.sender, to, amount, data);
    }

     
     
     
     
     
     
    function depositAndTransfer(
        address depositTo,
        address transferTo,
        uint256 depositAmount,
        uint256 transferAmount,
        bytes data,
        bytes32 reference
    )
        public
        returns (bool success)
    {
        deposit(depositTo, depositAmount, reference);
        return ierc223TransferInternal(depositTo, transferTo, transferAmount, data);
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0xfb5c7e43558c4f3f5a2d87885881c9b10ff4be37e3308579c178bf4eaa2c29cd, 0);
    }

     
     
     

     
     
     

    function mOnTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        acceptAgreement(from)
        returns (bool allow)
    {
        address broker = msg.sender;
        if (broker != from) {
             
            bool isDepositor = accessPolicy().allowed(msg.sender, ROLE_EURT_DEPOSIT_MANAGER, this, msg.sig);
             
            if (isDepositor) {
                broker = from;
            }
        }
        return _tokenController.onTransfer(broker, from, to, amount);
    }

    function mOnApprove(
        address owner,
        address spender,
        uint256 amount
    )
        internal
        acceptAgreement(owner)
        returns (bool allow)
    {
        return _tokenController.onApprove(owner, spender, amount);
    }

    function mAllowanceOverride(
        address owner,
        address spender
    )
        internal
        constant
        returns (uint256)
    {
        return _tokenController.onAllowance(owner, spender);
    }

     
     
     

     
    function mCanAmend(address legalRepresentative)
        internal
        returns (bool)
    {
        return accessPolicy().allowed(legalRepresentative, ROLE_EURT_LEGAL_MANAGER, this, msg.sig);
    }

     
     
     

    function destroyTokensPrivate(address owner, uint256 amount)
        private
    {
        require(_balances[owner] >= amount);
        _balances[owner] = sub(_balances[owner], amount);
        _totalSupply = sub(_totalSupply, amount);
        emit Transfer(owner, address(0), amount);
    }

     
    function ierc223TransferInternal(address from, address to, uint256 amount, bytes data)
        private
        returns (bool success)
    {
        BasicToken.mTransfer(from, to, amount);

         
        if (isContract(to)) {
             
            IERC223Callback(to).tokenFallback(from, amount, data);
        }
        return true;
    }
}

 
contract Serialization {

     
     
     
    function decodeAddress(bytes b)
        internal
        pure
        returns (address a)
    {
        require(b.length == 20);
        assembly {
             
            a := and(mload(add(b, 20)), 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    function decodeAddressUInt256(bytes b)
        internal
        pure
        returns (address a, uint256 i)
    {
        require(b.length == 52);
        assembly {
             
            a := and(mload(add(b, 20)), 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            i := mload(add(b, 52))
        }
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

 
 
contract ERC223LegacyCallbackCompat {

     
     
     

    function onTokenTransfer(address wallet, uint256 amount, bytes data)
        public
    {
        tokenFallback(wallet, amount, data);
    }

    function tokenFallback(address wallet, uint256 amount, bytes data)
        public;

}

 
contract IFeeDisbursalController is
    IContractId
{


     
     
     

     
    function onAccept(address  , address  , address claimer)
        public
        constant
        returns (bool allow);

     
    function onReject(address  , address  , address claimer)
        public
        constant
        returns (bool allow);

     
    function onDisburse(address token, address disburser, uint256 amount, address proRataToken, uint256 recycleAfterPeriod)
        public
        constant
        returns (bool allow);

     
    function onRecycle(address token, address  , address[] investors, uint256 until)
        public
        constant
        returns (bool allow);

     
    function onChangeFeeDisbursalController(address sender, IFeeDisbursalController newController)
        public
        constant
        returns (bool);

}

 
 
contract IFeeDisbursal is
    IERC223Callback,
    IERC677Callback,
    IERC223LegacyCallback,
    ERC223LegacyCallbackCompat,
    IContractId
    {

     
     
     

    event LogDisbursalCreated(
        address indexed proRataToken,
        address indexed token,
        uint256 amount,
        uint256 recycleAfterDuration,
        address disburser,
        uint256 index
    );

    event LogDisbursalAccepted(
        address indexed claimer,
        address token,
        address proRataToken,
        uint256 amount,
        uint256 nextIndex
    );

    event LogDisbursalRejected(
        address indexed claimer,
        address token,
        address proRataToken,
        uint256 amount,
        uint256 nextIndex
    );

    event LogFundsRecycled(
        address indexed proRataToken,
        address indexed token,
        uint256 amount,
        address by
    );

    event LogChangeFeeDisbursalController(
        address oldController,
        address newController,
        address by
    );

     
     
     
    struct Disbursal {
         
        uint256 snapshotId;
         
        uint256 amount;
         
        uint128 recycleableAfterTimestamp;
         
        uint128 disbursalTimestamp;
         
        address disburser;
    }

     
     
     
    uint256 internal constant UINT256_MAX = 2**256 - 1;


     
     
     

     
     
     
     
    function getDisbursal(address token, address proRataToken, uint256 index)
        public
        constant
    returns (
        uint256 snapshotId,
        uint256 amount,
        uint256 recycleableAfterTimestamp,
        uint256 disburseTimestamp,
        address disburser
        );

     
     
     
     
    function getNonClaimableDisbursals(address token, address proRataToken)
        public
        constant
        returns (uint256[3][] memory disbursals);

     
     
     
    function getDisbursalCount(address token, address proRataToken)
        public
        constant
        returns (uint256);

     
     
     
     
    function accept(address token, ITokenSnapshots proRataToken, uint256 until)
        public;

     
     
     
    function acceptMultipleByToken(address[] tokens, ITokenSnapshots proRataToken)
        public;

     
     
     
     
    function acceptMultipleByProRataToken(address token, ITokenSnapshots[] proRataTokens)
        public;

     
     
     
     
    function reject(address token, ITokenSnapshots proRataToken, uint256 until)
        public;

     
     
     
     
     
     
    function claimable(address token, ITokenSnapshots proRataToken, address claimer, uint256 until)
        public
        constant
        returns (uint256 claimableAmount, uint256 totalAmount, uint256 recycleableAfterTimestamp, uint256 firstIndex);

     
     
     
     
     
     
    function claimableMutipleByToken(address[] tokens, ITokenSnapshots proRataToken, address claimer)
        public
        constant
        returns (uint256[4][] claimables);

     
     
     
     
     
    function claimableMutipleByProRataToken(address token, ITokenSnapshots[] proRataTokens, address claimer)
        public
        constant
        returns (uint256[4][] claimables);


     
     
     
     
     
    function recycle(address token, ITokenSnapshots proRataToken, address[] investors, uint256 until)
        public;

     
     
     
     
     
    function recycleable(address token, ITokenSnapshots proRataToken, address[] investors, uint256 until)
        public
        constant
        returns (uint256);

     
    function feeDisbursalController()
        public
        constant
        returns (IFeeDisbursalController);

     
    function changeFeeDisbursalController(IFeeDisbursalController newController)
        public;
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

 
 
contract MigrationTarget is
    IMigrationTarget
{
     
     
     

     
    modifier onlyMigrationSource() {
        require(msg.sender == currentMigrationSource(), "NF_INV_SOURCE");
        _;
    }
}

 
 
 
contract ICBMLockedAccountMigration is
    MigrationTarget
{
     
     
     

     
    function migrateInvestor(
        address investor,
        uint256 balance,
        uint256 neumarksDue,
        uint256 unlockDate
    )
        public;

}

 
 
contract ICBMRoles {

     
     
     

     
     
     

     
    bytes32 internal constant ROLE_LOCKED_ACCOUNT_ADMIN = 0x4675da546d2d92c5b86c4f726a9e61010dce91cccc2491ce6019e78b09d2572e;
}

contract TimeSource {

     
     
     

    function currentTime() internal constant returns (uint256) {
        return block.timestamp;
    }
}

contract ICBMLockedAccount is
    AccessControlled,
    ICBMRoles,
    TimeSource,
    Math,
    IsContract,
    MigrationSource,
    IERC677Callback,
    Reclaimable
{

     
     
     

     
    enum LockState {
         
        Uncontrolled,
         
        AcceptingLocks,
         
        AcceptingUnlocks,
         
        ReleaseAll
    }

     
    struct Account {
         
        uint256 balance;
         
        uint256 neumarksDue;
         
        uint256 unlockDate;
    }

     
     
     

     
     
    IERC677Token private ASSET_TOKEN;

    Neumark private NEUMARK;

     
    uint256 private LOCK_PERIOD;

     
    uint256 private PENALTY_FRACTION;

     
     
     

     
    uint256 private _totalLockedAmount;

     
    uint256 internal _totalInvestors;

     
    LockState private _lockState;

     
    address private _controller;

     
    address private _penaltyDisbursalAddress;

     
    mapping(address => Account) internal _accounts;

     
     
     

     
     
     
     
    event LogFundsLocked(
        address indexed investor,
        uint256 amount,
        uint256 neumarks
    );

     
     
     
     
    event LogFundsUnlocked(
        address indexed investor,
        uint256 amount,
        uint256 neumarks
    );

     
     
     
     
     
     
    event LogPenaltyDisbursed(
        address indexed disbursalPoolAddress,
        uint256 amount,
        address assetToken,
        address investor
    );

     
    event LogLockStateTransition(
        LockState oldState,
        LockState newState
    );

    event LogInvestorMigrated(
        address indexed investor,
        uint256 amount,
        uint256 neumarks,
        uint256 unlockDate
    );

     
     
     

    modifier onlyController() {
        require(msg.sender == address(_controller));
        _;
    }

    modifier onlyState(LockState state) {
        require(_lockState == state);
        _;
    }

    modifier onlyStates(LockState state1, LockState state2) {
        require(_lockState == state1 || _lockState == state2);
        _;
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
    constructor(
        IAccessPolicy policy,
        IERC677Token assetToken,
        Neumark neumark,
        address penaltyDisbursalAddress,
        uint256 lockPeriod,
        uint256 penaltyFraction
    )
        MigrationSource(policy, ROLE_LOCKED_ACCOUNT_ADMIN)
        Reclaimable()
        public
    {
        ASSET_TOKEN = assetToken;
        NEUMARK = neumark;
        LOCK_PERIOD = lockPeriod;
        PENALTY_FRACTION = penaltyFraction;
        _penaltyDisbursalAddress = penaltyDisbursalAddress;
    }

     
     
     

     
     
     
     
     
    function lock(address investor, uint256 amount, uint256 neumarks)
        public
        onlyState(LockState.AcceptingLocks)
        onlyController()
    {
        require(amount > 0);
         
        assert(ASSET_TOKEN.transferFrom(msg.sender, address(this), amount));

        Account storage account = _accounts[investor];
        account.balance = addBalance(account.balance, amount);
        account.neumarksDue = add(account.neumarksDue, neumarks);

        if (account.unlockDate == 0) {
             
            _totalInvestors += 1;
            account.unlockDate = currentTime() + LOCK_PERIOD;
        }
        emit LogFundsLocked(investor, amount, neumarks);
    }

     
     
     
    function unlock()
        public
        onlyStates(LockState.AcceptingUnlocks, LockState.ReleaseAll)
    {
        unlockInvestor(msg.sender);
    }

     
     
     
    function receiveApproval(
        address from,
        uint256,  
        address _token,
        bytes _data
    )
        public
        onlyState(LockState.AcceptingUnlocks)
        returns (bool)
    {
        require(msg.sender == _token);
        require(_data.length == 0);

         
        require(_token == address(NEUMARK));

         
         
        unlockInvestor(from);

         
         
        return true;
    }

     
     
    function controllerFailed()
        public
        onlyState(LockState.AcceptingLocks)
        onlyController()
    {
        changeState(LockState.ReleaseAll);
    }

     
    function controllerSucceeded()
        public
        onlyState(LockState.AcceptingLocks)
        onlyController()
    {
        changeState(LockState.AcceptingUnlocks);
    }

    function setController(address controller)
        public
        only(ROLE_LOCKED_ACCOUNT_ADMIN)
        onlyState(LockState.Uncontrolled)
    {
        _controller = controller;
        changeState(LockState.AcceptingLocks);
    }

     
     
     
    function setPenaltyDisbursal(address penaltyDisbursalAddress)
        public
        only(ROLE_LOCKED_ACCOUNT_ADMIN)
    {
        require(penaltyDisbursalAddress != address(0));

         
        _penaltyDisbursalAddress = penaltyDisbursalAddress;
    }

    function assetToken()
        public
        constant
        returns (IERC677Token)
    {
        return ASSET_TOKEN;
    }

    function neumark()
        public
        constant
        returns (Neumark)
    {
        return NEUMARK;
    }

    function lockPeriod()
        public
        constant
        returns (uint256)
    {
        return LOCK_PERIOD;
    }

    function penaltyFraction()
        public
        constant
        returns (uint256)
    {
        return PENALTY_FRACTION;
    }

    function balanceOf(address investor)
        public
        constant
        returns (uint256, uint256, uint256)
    {
        Account storage account = _accounts[investor];
        return (account.balance, account.neumarksDue, account.unlockDate);
    }

    function controller()
        public
        constant
        returns (address)
    {
        return _controller;
    }

    function lockState()
        public
        constant
        returns (LockState)
    {
        return _lockState;
    }

    function totalLockedAmount()
        public
        constant
        returns (uint256)
    {
        return _totalLockedAmount;
    }

    function totalInvestors()
        public
        constant
        returns (uint256)
    {
        return _totalInvestors;
    }

    function penaltyDisbursalAddress()
        public
        constant
        returns (address)
    {
        return _penaltyDisbursalAddress;
    }

     
     
     

     
     
     
     
     
     
    function enableMigration(IMigrationTarget migration)
        public
        onlyStates(LockState.AcceptingLocks, LockState.AcceptingUnlocks)
    {
         
        MigrationSource.enableMigration(migration);
    }

     
    function migrate()
        public
        onlyMigrationEnabled()
    {
         
        Account memory account = _accounts[msg.sender];

         
        if (account.balance == 0) {
            return;
        }

         
        removeInvestor(msg.sender, account.balance);

         
        assert(ASSET_TOKEN.approve(address(_migration), account.balance));
        ICBMLockedAccountMigration(_migration).migrateInvestor(
            msg.sender,
            account.balance,
            account.neumarksDue,
            account.unlockDate
        );
        emit LogInvestorMigrated(msg.sender, account.balance, account.neumarksDue, account.unlockDate);
    }

     
     
     

     
     
     
    function reclaim(IBasicToken token)
        public
    {
         
        require(token != ASSET_TOKEN);
        Reclaimable.reclaim(token);
    }

     
     
     

    function addBalance(uint256 balance, uint256 amount)
        internal
        returns (uint256)
    {
        _totalLockedAmount = add(_totalLockedAmount, amount);
        uint256 newBalance = balance + amount;
        return newBalance;
    }

     
     
     

    function subBalance(uint256 balance, uint256 amount)
        private
        returns (uint256)
    {
        _totalLockedAmount -= amount;
        return balance - amount;
    }

    function removeInvestor(address investor, uint256 balance)
        private
    {
        subBalance(balance, balance);
        _totalInvestors -= 1;
        delete _accounts[investor];
    }

    function changeState(LockState newState)
        private
    {
        assert(newState != _lockState);
        emit LogLockStateTransition(_lockState, newState);
        _lockState = newState;
    }

     
     
     
     
     
     
    function unlockInvestor(address investor)
        private
    {
         
        Account memory accountInMem = _accounts[investor];

         
        if (accountInMem.balance == 0) {
            return;
        }
         
        removeInvestor(investor, accountInMem.balance);

         
        if (_lockState == LockState.AcceptingUnlocks) {
             
             
            require(NEUMARK.transferFrom(investor, address(this), accountInMem.neumarksDue));

             
            NEUMARK.burn(accountInMem.neumarksDue);

             
            if (currentTime() < accountInMem.unlockDate) {
                require(_penaltyDisbursalAddress != address(0));
                uint256 penalty = decimalFraction(accountInMem.balance, PENALTY_FRACTION);

                 
                if (isContract(_penaltyDisbursalAddress)) {
                    require(
                        ASSET_TOKEN.approveAndCall(_penaltyDisbursalAddress, penalty, "")
                    );
                } else {
                     
                    assert(ASSET_TOKEN.transfer(_penaltyDisbursalAddress, penalty));
                }
                emit LogPenaltyDisbursed(_penaltyDisbursalAddress, penalty, ASSET_TOKEN, investor);
                accountInMem.balance -= penalty;
            }
        }
        if (_lockState == LockState.ReleaseAll) {
            accountInMem.neumarksDue = 0;
        }
         
        assert(ASSET_TOKEN.transfer(investor, accountInMem.balance));
        emit LogFundsUnlocked(investor, accountInMem.balance, accountInMem.neumarksDue);
    }
}

contract LockedAccount is
    Agreement,
    Math,
    Serialization,
    ICBMLockedAccountMigration,
    IdentityRecord,
    KnownInterfaces,
    Reclaimable,
    IContractId
{
     
     
     

     
    struct Account {
         
        uint112 balance;
         
        uint112 neumarksDue;
         
        uint32 unlockDate;
    }

     
     
     
     
     
    struct Destination {
         
        address investor;
         
        uint112 amount;
    }

     
     
     

     
    IERC223Token private PAYMENT_TOKEN;

    Neumark private NEUMARK;

     
    uint256 private LOCK_PERIOD;

     
    uint256 private PENALTY_FRACTION;

     
    Universe private UNIVERSE;

     
    ICBMLockedAccount private MIGRATION_SOURCE;

     
    IERC677Token private OLD_PAYMENT_TOKEN;

     
     
     

     
    uint112 private _totalLockedAmount;

     
    uint256 internal _totalInvestors;

     
    mapping(address => Account) internal _accounts;

     
    mapping(address => mapping(address => Account)) internal _commitments;

     
    mapping(address => Destination[]) private _destinations;

     
     
     

     
     
     
     
     
    event LogFundsCommitted(
        address indexed investor,
        address indexed commitment,
        uint256 amount,
        uint256 neumarks
    );

     
     
     
     
    event LogFundsUnlocked(
        address indexed investor,
        uint256 amount,
        uint256 neumarks
    );

     
     
     
     
    event LogFundsLocked(
        address indexed investor,
        uint256 amount,
        uint256 neumarks
    );

     
     
     
     
     

     
     
     
     
     
    event LogFundsRefunded(
        address indexed investor,
        address indexed commitment,
        uint256 amount,
        uint256 neumarks
    );

     
     
     
     
     
     
    event LogPenaltyDisbursed(
        address indexed disbursalPoolAddress,
        address indexed investor,
        uint256 amount,
        address paymentToken
    );

     
    event LogMigrationDestination(
        address indexed investor,
        address indexed destination,
        uint256 amount
    );

     
     
     

    modifier onlyIfCommitment(address commitment) {
         
        require(UNIVERSE.isInterfaceCollectionInstance(KNOWN_INTERFACE_COMMITMENT, commitment), "NF_LOCKED_ONLY_COMMITMENT");
        _;
    }

     
     
     

     
     
     
     
    constructor(
        Universe universe,
        Neumark neumark,
        IERC223Token paymentToken,
        ICBMLockedAccount migrationSource
    )
        Agreement(universe.accessPolicy(), universe.forkArbiter())
        Reclaimable()
        public
    {
        PAYMENT_TOKEN = paymentToken;
        MIGRATION_SOURCE = migrationSource;
        OLD_PAYMENT_TOKEN = MIGRATION_SOURCE.assetToken();
        UNIVERSE = universe;
        NEUMARK = neumark;
        LOCK_PERIOD = migrationSource.lockPeriod();
        PENALTY_FRACTION = migrationSource.penaltyFraction();
         
         
        require(keccak256(abi.encodePacked(ITokenMetadata(OLD_PAYMENT_TOKEN).symbol())) == keccak256(abi.encodePacked(PAYMENT_TOKEN.symbol())));
    }

     
     
     

     
     
     
     
     
    function transfer(address commitment, uint256 amount, bytes  )
        public
        onlyIfCommitment(commitment)
    {
        require(amount > 0, "NF_LOCKED_NO_ZERO");
        Account storage account = _accounts[msg.sender];
         
        require(account.balance >= amount, "NF_LOCKED_NO_FUNDS");
         
        uint112 unlockedNmkUlps = uint112(
            proportion(
                account.neumarksDue,
                amount,
                account.balance
            )
        );
        account.balance = subBalance(account.balance, uint112(amount));
         
        account.neumarksDue -= unlockedNmkUlps;
         
        Account storage investment = _commitments[address(commitment)][msg.sender];
        investment.balance += uint112(amount);
        investment.neumarksDue += unlockedNmkUlps;
         
        assert(PAYMENT_TOKEN.transfer(commitment, amount, abi.encodePacked(msg.sender)));
        emit LogFundsCommitted(msg.sender, commitment, amount, unlockedNmkUlps);
    }

     
     
     
    function unlock()
        public
    {
        unlockInvestor(msg.sender);
    }

     
     
     
    function receiveApproval(address from, uint256, address _token, bytes _data)
        public
        returns (bool)
    {
        require(msg.sender == _token);
        require(_data.length == 0);
         
        require(_token == address(NEUMARK), "NF_ONLY_NEU");
         
         
        unlockInvestor(from);
        return true;
    }

     
     
     
     
    function refunded(address investor)
        public
    {
        Account memory investment = _commitments[msg.sender][investor];
         
        if (investment.balance == 0)
            return;
         
        delete _commitments[msg.sender][investor];
        Account storage account = _accounts[investor];
         
        require(account.unlockDate > 0, "NF_LOCKED_ACCOUNT_LIQUIDATED");
         
        account.balance = addBalance(account.balance, investment.balance);
        account.neumarksDue = add112(account.neumarksDue, investment.neumarksDue);
         
        assert(PAYMENT_TOKEN.transferFrom(msg.sender, address(this), investment.balance));
        emit LogFundsRefunded(investor, msg.sender, investment.balance, investment.neumarksDue);
    }

     
     
    function claimed(address investor) public {
        delete _commitments[msg.sender][investor];
    }

     
    function pendingCommitments(address commitment, address investor)
        public
        constant
        returns (uint256 balance, uint256 neumarkDue)
    {
        Account storage i = _commitments[commitment][investor];
        return (i.balance, i.neumarksDue);
    }

     
     
     

    function migrateInvestor(
        address investor,
        uint256 balance256,
        uint256 neumarksDue256,
        uint256 unlockDate256
    )
        public
        onlyMigrationSource()
    {
         
        require(balance256 < 2**112, "NF_OVR");
        uint112 balance = uint112(balance256);
        assert(neumarksDue256 < 2**112);
        uint112 neumarksDue = uint112(neumarksDue256);
        assert(unlockDate256 < 2**32);
        uint32 unlockDate = uint32(unlockDate256);

         
        require(OLD_PAYMENT_TOKEN.transferFrom(msg.sender, address(this), balance));
        IWithdrawableToken(OLD_PAYMENT_TOKEN).withdraw(balance);
         
        if (PAYMENT_TOKEN == UNIVERSE.etherToken()) {
             
            EtherToken(PAYMENT_TOKEN).deposit.value(balance)();
        } else {
            EuroToken(PAYMENT_TOKEN).deposit(this, balance, 0x0);
        }
        Destination[] storage destinations = _destinations[investor];
        if (destinations.length == 0) {
             
            lock(investor, balance, neumarksDue, unlockDate);
        } else {
             
            uint256 idx;
            while(idx < destinations.length) {
                Destination storage destination = destinations[idx];
                 
                uint112 partialAmount = destination.amount == 0 ? balance : destination.amount;
                require(partialAmount <= balance, "NF_LOCKED_ACCOUNT_SPLIT_OVERSPENT");
                 
                uint112 partialNmkUlps = uint112(
                    proportion(
                        neumarksDue,
                        partialAmount,
                        balance
                    )
                );
                 
                balance -= partialAmount;
                 
                neumarksDue -= partialNmkUlps;
                 
                lock(destination.investor, partialAmount, partialNmkUlps, unlockDate);
                idx += 1;
            }
             
            require(balance == 0, "NF_LOCKED_ACCOUNT_SPLIT_UNDERSPENT");
            assert(neumarksDue == 0);
             
            delete _destinations[investor];
        }
    }

     
     
     
    function setInvestorMigrationWallet(address destinationWallet)
        public
    {
        Destination[] storage destinations = _destinations[msg.sender];
         
        if(destinations.length > 0) {
            delete _destinations[msg.sender];
        }
         
        addDestination(destinations, destinationWallet, 0);
    }

     
     
    function setInvestorMigrationWallets(address[] wallets, uint112[] amounts)
        public
    {
        require(wallets.length == amounts.length);
        Destination[] storage destinations = _destinations[msg.sender];
         
        if(destinations.length > 0) {
            delete _destinations[msg.sender];
        }
        uint256 idx;
        while(idx < wallets.length) {
            addDestination(destinations, wallets[idx], amounts[idx]);
            idx += 1;
        }
    }

     
    function getInvestorMigrationWallets(address investor)
        public
        constant
        returns (address[] wallets, uint112[] amounts)
    {
        Destination[] storage destinations = _destinations[investor];
        wallets = new address[](destinations.length);
        amounts = new uint112[](destinations.length);
        uint256 idx;
        while(idx < destinations.length) {
            wallets[idx] = destinations[idx].investor;
            amounts[idx] = destinations[idx].amount;
            idx += 1;
        }
    }

     
     
     

    function currentMigrationSource()
        public
        constant
        returns (address)
    {
        return address(MIGRATION_SOURCE);
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x15fbe12e85e3698f22c35480f7c66bc38590bb8cfe18cbd6dc3d49355670e561, 0);
    }

     
     
     
    function ()
        public
        payable
    {
        require(msg.sender == address(OLD_PAYMENT_TOKEN));
    }

     
     
     

     
     
     
    function reclaim(IBasicToken token)
        public
    {
         
        require(token != PAYMENT_TOKEN, "NO_PAYMENT_TOKEN_RECLAIM");
        Reclaimable.reclaim(token);
    }

     
     
     

    function paymentToken()
        public
        constant
        returns (IERC223Token)
    {
        return PAYMENT_TOKEN;
    }

    function neumark()
        public
        constant
        returns (Neumark)
    {
        return NEUMARK;
    }

    function lockPeriod()
        public
        constant
        returns (uint256)
    {
        return LOCK_PERIOD;
    }

    function penaltyFraction()
        public
        constant
        returns (uint256)
    {
        return PENALTY_FRACTION;
    }

    function balanceOf(address investor)
        public
        constant
        returns (uint256 balance, uint256 neumarksDue, uint32 unlockDate)
    {
        Account storage account = _accounts[investor];
        return (account.balance, account.neumarksDue, account.unlockDate);
    }

    function totalLockedAmount()
        public
        constant
        returns (uint256)
    {
        return _totalLockedAmount;
    }

    function totalInvestors()
        public
        constant
        returns (uint256)
    {
        return _totalInvestors;
    }

     
     
     

    function addBalance(uint112 balance, uint112 amount)
        internal
        returns (uint112)
    {
        _totalLockedAmount = add112(_totalLockedAmount, amount);
         
        return balance + amount;
    }

     
     
     

    function subBalance(uint112 balance, uint112 amount)
        private
        returns (uint112)
    {
        _totalLockedAmount = sub112(_totalLockedAmount, amount);
        return sub112(balance, amount);
    }

    function removeInvestor(address investor, uint112 balance)
        private
    {
        subBalance(balance, balance);
        _totalInvestors -= 1;
        delete _accounts[investor];
    }

     
     
     
     
     
    function unlockInvestor(address investor)
        private
    {
         
        Account memory accountInMem = _accounts[investor];

         
        if (accountInMem.balance == 0) {
            return;
        }
         
        removeInvestor(investor, accountInMem.balance);

         
         
        require(NEUMARK.transferFrom(investor, address(this), accountInMem.neumarksDue));

         
        NEUMARK.burn(accountInMem.neumarksDue);

         
        if (block.timestamp < accountInMem.unlockDate) {
            address penaltyDisbursalAddress = UNIVERSE.feeDisbursal();
            require(penaltyDisbursalAddress != address(0));
            uint112 penalty = uint112(decimalFraction(accountInMem.balance, PENALTY_FRACTION));
             
            assert(PAYMENT_TOKEN.transfer(penaltyDisbursalAddress, penalty, abi.encodePacked(NEUMARK)));
            emit LogPenaltyDisbursed(penaltyDisbursalAddress, investor, penalty, PAYMENT_TOKEN);
            accountInMem.balance -= penalty;
        }
         
        assert(PAYMENT_TOKEN.transfer(investor, accountInMem.balance, ""));
        emit LogFundsUnlocked(investor, accountInMem.balance, accountInMem.neumarksDue);
    }

     
     
     
     
     
     
    function lock(address investor, uint112 amount, uint112 neumarks, uint32 unlockDate)
        private
        acceptAgreement(investor)
    {
        require(amount > 0);
        Account storage account = _accounts[investor];
        if (account.unlockDate == 0) {
             
            _totalInvestors += 1;
        }

         
        account.balance = addBalance(account.balance, amount);
        account.neumarksDue = add112(account.neumarksDue, neumarks);
         
         
        if (unlockDate > account.unlockDate) {
            account.unlockDate = unlockDate;
        }

        emit LogFundsLocked(investor, amount, neumarks);
    }

    function addDestination(Destination[] storage destinations, address wallet, uint112 amount)
        private
    {
         
        IIdentityRegistry identityRegistry = IIdentityRegistry(UNIVERSE.identityRegistry());
        IdentityClaims memory claims = deserializeClaims(identityRegistry.getClaims(wallet));
        require(claims.isVerified && !claims.accountFrozen, "NF_DEST_NO_VERIFICATION");
        if (wallet != msg.sender) {
             
            (,,uint256 unlockDate) = MIGRATION_SOURCE.balanceOf(wallet);
            require(unlockDate == 0, "NF_DEST_NO_SQUATTING");
        }

        destinations.push(
            Destination({investor: wallet, amount: amount})
        );
        emit LogMigrationDestination(msg.sender, wallet, amount);
    }

    function sub112(uint112 a, uint112 b) internal pure returns (uint112)
    {
        assert(b <= a);
        return a - b;
    }

    function add112(uint112 a, uint112 b) internal pure returns (uint112)
    {
        uint112 c = a + b;
        assert(c >= a);
        return c;
    }
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
     
    uint256 public SHAREHOLDERS_VOTING_QUORUM_FRAC;
     
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
        uint256 shareholdersVotingQuorumFrac,
        uint256 votingMajorityFrac,
        string investmentAgreementTemplateUrl
    )
        public
    {
         
        require(uint(generalVotingRule) < 4);
        require(uint(tagAlongVotingRule) < 4);
         
        require(shareholdersVotingQuorumFrac <= 10**18);
        require(keccak256(abi.encodePacked(investmentAgreementTemplateUrl)) != EMPTY_STRING_HASH);

        GENERAL_VOTING_RULE = generalVotingRule;
        TAG_ALONG_VOTING_RULE = tagAlongVotingRule;
        LIQUIDATION_PREFERENCE_MULTIPLIER_FRAC = liquidationPreferenceMultiplierFrac;
        HAS_FOUNDERS_VESTING = hasFoundersVesting;
        GENERAL_VOTING_DURATION = generalVotingDuration;
        RESTRICTED_ACT_VOTING_DURATION = restrictedActVotingDuration;
        VOTING_FINALIZATION_DURATION = votingFinalizationDuration;
        SHAREHOLDERS_VOTING_QUORUM_FRAC = shareholdersVotingQuorumFrac;
        VOTING_MAJORITY_FRAC = votingMajorityFrac;
        INVESTMENT_AGREEMENT_TEMPLATE_URL = investmentAgreementTemplateUrl;
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x7f46caed28b4e7a90dc4db9bba18d1565e6c4824f0dc1b96b3b88d730da56e57, 0);
    }
}

 
 
 
 

 
contract PlatformTerms is Math, IContractId {

     
     
     

     
    uint256 public constant PLATFORM_FEE_FRACTION = 3 * 10**16;
     
    uint256 public constant TOKEN_PARTICIPATION_FEE_FRACTION = 2 * 10**16;
     
     
     
    uint256 public constant PLATFORM_NEUMARK_SHARE = 2;  
     
    bool public constant IS_ICBM_INVESTOR_WHITELISTED = true;

     
    uint256 public constant TOKEN_RATE_EXPIRES_AFTER = 4 hours;

     
    uint256 public constant DEFAULT_DISBURSAL_RECYCLE_AFTER_DURATION = 4 * 365 days;

     
     
     

     
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
         
         
        return divRound(tokenAmount, 50);
    }

     
    function calculateAmountWithoutFee(uint256 tokenAmountWithFee)
        public
        pure
        returns (uint256)
    {
         
        return divRound(mul(tokenAmountWithFee, 50), 51);
    }

    function calculatePlatformFee(uint256 amount)
        public
        pure
        returns (uint256)
    {
        return decimalFraction(amount, PLATFORM_FEE_FRACTION);
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x95482babc4e32de6c4dc3910ee7ae62c8e427efde6bc4e9ce0d6d93e24c39323, 2);
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

 
contract ETOTermsConstraints is IContractId {


     
     
     
    enum OfferingDocumentType {
        Memorandum,
        Prospectus
    }

    enum OfferingDocumentSubType {
        Regular,
        Lean
    }

    enum AssetType {
        Security,
        VMA  
    }

     
     
     

     
    uint256 public constant DATE_TO_WHITELIST_MIN_DURATION = 7 days;

     
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

     
    bool public CAN_SET_TRANSFERABILITY;

     
    bool public HAS_NOMINEE;

     
    uint256 public MIN_TICKET_SIZE_EUR_ULPS;
     
    uint256 public MAX_TICKET_SIZE_EUR_ULPS;
     
    uint256 public MIN_INVESTMENT_AMOUNT_EUR_ULPS;
     
    uint256 public MAX_INVESTMENT_AMOUNT_EUR_ULPS;

     
    string public NAME;

     
    OfferingDocumentType public OFFERING_DOCUMENT_TYPE;
    OfferingDocumentSubType public OFFERING_DOCUMENT_SUB_TYPE;

     
    string public JURISDICTION;

     
    AssetType public ASSET_TYPE;

     
    address public TOKEN_OFFERING_OPERATOR;


     
     
     

    constructor(
        bool canSetTransferability,
        bool hasNominee,
        uint256 minTicketSizeEurUlps,
        uint256 maxTicketSizeEurUlps,
        uint256 minInvestmentAmountEurUlps,
        uint256 maxInvestmentAmountEurUlps,
        string name,
        OfferingDocumentType offeringDocumentType,
        OfferingDocumentSubType offeringDocumentSubType,
        string jurisdiction,
        AssetType assetType,
        address tokenOfferingOperator
    )
        public
    {
        require(maxTicketSizeEurUlps == 0 || minTicketSizeEurUlps<=maxTicketSizeEurUlps);
        require(maxInvestmentAmountEurUlps == 0 || minInvestmentAmountEurUlps<=maxInvestmentAmountEurUlps);
        require(maxInvestmentAmountEurUlps == 0 || minTicketSizeEurUlps<=maxInvestmentAmountEurUlps);
        require(assetType != AssetType.VMA || !canSetTransferability);
        require(tokenOfferingOperator != address(0x0));

        CAN_SET_TRANSFERABILITY = canSetTransferability;
        HAS_NOMINEE = hasNominee;
        MIN_TICKET_SIZE_EUR_ULPS = minTicketSizeEurUlps;
        MAX_TICKET_SIZE_EUR_ULPS = maxTicketSizeEurUlps;
        MIN_INVESTMENT_AMOUNT_EUR_ULPS = minInvestmentAmountEurUlps;
        MAX_INVESTMENT_AMOUNT_EUR_ULPS = maxInvestmentAmountEurUlps;
        NAME = name;
        OFFERING_DOCUMENT_TYPE = offeringDocumentType;
        OFFERING_DOCUMENT_SUB_TYPE = offeringDocumentSubType;
        JURISDICTION = jurisdiction;
        ASSET_TYPE = assetType;
        TOKEN_OFFERING_OPERATOR = tokenOfferingOperator;
    }

     
     
     
    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0xce2be4f5f23c4a6f67ed925fce56afa57c9c8b274b4dfca8d0b1104aa4a6b53a, 0);
    }

}

 
 
 


 
contract ETOTokenTerms is Math, IContractId {

     
     
     

    bytes32 private constant EMPTY_STRING_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
     
    uint8 public constant EQUITY_TOKENS_PRECISION = 0;  

     
     
     

     
    string public EQUITY_TOKEN_NAME;
    string public EQUITY_TOKEN_SYMBOL;

     
    uint256 public MIN_NUMBER_OF_TOKENS;
     
    uint256 public MAX_NUMBER_OF_TOKENS;
     
    uint256 public TOKEN_PRICE_EUR_ULPS;
     
    uint256 public MAX_NUMBER_OF_TOKENS_IN_WHITELIST;
     
     
    uint256 public SHARE_NOMINAL_VALUE_ULPS;
     
    uint256 public SHARE_NOMINAL_VALUE_EUR_ULPS;
     
    uint256 public EQUITY_TOKENS_PER_SHARE;


     
     
     

    constructor(
        string equityTokenName,
        string equityTokenSymbol,
        uint256 minNumberOfTokens,
        uint256 maxNumberOfTokens,
        uint256 tokenPriceEurUlps,
        uint256 maxNumberOfTokensInWhitelist,
        uint256 shareNominalValueUlps,
        uint256 shareNominalValueEurUlps,
        uint256 equityTokensPerShare
    )
        public
    {
        require(maxNumberOfTokens >= maxNumberOfTokensInWhitelist, "NF_WL_TOKENS_GT_MAX_TOKENS");
        require(maxNumberOfTokens >= minNumberOfTokens, "NF_MIN_TOKENS_GT_MAX_TOKENS");
         
        require(minNumberOfTokens >= equityTokensPerShare, "NF_ETO_TERMS_ONE_SHARE");
         
        require(maxNumberOfTokens % equityTokensPerShare == 0, "NF_MAX_TOKENS_FULL_SHARES");
        require(shareNominalValueUlps > 0);
        require(shareNominalValueEurUlps > 0);
        require(equityTokensPerShare > 0);
        require(keccak256(abi.encodePacked(equityTokenName)) != EMPTY_STRING_HASH);
        require(keccak256(abi.encodePacked(equityTokenSymbol)) != EMPTY_STRING_HASH);
         
        require(maxNumberOfTokens < 2**56, "NF_TOO_MANY_TOKENS");
        require(mul(tokenPriceEurUlps, maxNumberOfTokens) < 2**112, "NF_TOO_MUCH_FUNDS_COLLECTED");

        MIN_NUMBER_OF_TOKENS = minNumberOfTokens;
        MAX_NUMBER_OF_TOKENS = maxNumberOfTokens;
        TOKEN_PRICE_EUR_ULPS = tokenPriceEurUlps;
        MAX_NUMBER_OF_TOKENS_IN_WHITELIST = maxNumberOfTokensInWhitelist;
        SHARE_NOMINAL_VALUE_EUR_ULPS = shareNominalValueEurUlps;
        SHARE_NOMINAL_VALUE_ULPS = shareNominalValueUlps;
        EQUITY_TOKEN_NAME = equityTokenName;
        EQUITY_TOKEN_SYMBOL = equityTokenSymbol;
        EQUITY_TOKENS_PER_SHARE = equityTokensPerShare;
    }

     
     
     

    function SHARE_PRICE_EUR_ULPS() public constant returns (uint256) {
        return mul(TOKEN_PRICE_EUR_ULPS, EQUITY_TOKENS_PER_SHARE);
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x591e791aab2b14c80194b729a2abcba3e8cce1918be4061be170e7223357ae5c, 1);
    }
}

 
 
 
 
 
 
 
 
 
 


 
 
 
contract ETOTerms is
    AccessControlled,
    AccessRoles,
    IdentityRecord,
    Math,
    IContractId,
    KnownInterfaces
{

     
     
     

     
    struct WhitelistTicket {
         
        uint128 discountAmountEurUlps;
         
        uint128 fullTokenPriceFrac;
    }

     
     
     

    bytes32 private constant EMPTY_STRING_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

     
     
     

     
    ETODurationTerms public DURATION_TERMS;
     
    ETOTokenTerms public TOKEN_TERMS;
     
    string public SHARE_CAPITAL_CURRENCY_CODE;
     
    uint256 public EXISTING_SHARE_CAPITAL;
     
     
     
    uint256 public MIN_TICKET_EUR_ULPS;
     
    uint256 public MAX_TICKET_EUR_ULPS;
     
     
     
     
    bool public ENABLE_TRANSFERS_ON_SUCCESS;
     
    uint256 public WHITELIST_DISCOUNT_FRAC;
     
     
    uint256 public PUBLIC_DISCOUNT_FRAC;
     
    uint256 public ALLOWS_REGD_INVESTORS;

     
     
    string public INVESTOR_OFFERING_DOCUMENT_URL;
     
    ShareholderRights public SHAREHOLDER_RIGHTS;

     
    IIdentityRegistry public IDENTITY_REGISTRY;
    Universe public UNIVERSE;
     
    ETOTermsConstraints public ETO_TERMS_CONSTRAINTS;
     
    uint256 public MAX_AVAILABLE_TOKENS;
     
    uint256 public MAX_AVAILABLE_TOKENS_IN_WHITELIST;

     
    uint256 private TOKEN_PRICE_EUR_ULPS;
     
    uint256 private EQUITY_TOKENS_PER_SHARE;


     
     
     

     
    mapping (address => WhitelistTicket) private _whitelist;

     
     
     

     
    event LogInvestorWhitelisted(
        address indexed investor,
        uint256 discountAmountEurUlps,
        uint256 fullTokenPriceFrac
    );

     
     
     

    constructor(
        Universe universe,
        ETODurationTerms durationTerms,
        ETOTokenTerms tokenTerms,
        string shareCapitalCurrencyCode,
        uint256 existingShareCapital,
        uint256 minTicketEurUlps,
        uint256 maxTicketEurUlps,
        bool enableTransfersOnSuccess,
        string investorOfferingDocumentUrl,
        ShareholderRights shareholderRights,
        uint256 whitelistDiscountFrac,
        uint256 publicDiscountFrac,
        ETOTermsConstraints etoTermsConstraints
    )
        AccessControlled(universe.accessPolicy())
        public
    {
        require(durationTerms != address(0));
        require(tokenTerms != address(0));
        require(existingShareCapital > 0);
        require(keccak256(abi.encodePacked(investorOfferingDocumentUrl)) != EMPTY_STRING_HASH);
        require(keccak256(abi.encodePacked(shareCapitalCurrencyCode)) != EMPTY_STRING_HASH);
        require(shareholderRights != address(0));
         
        require(shareholderRights.HAS_GENERAL_INFORMATION_RIGHTS());
        require(whitelistDiscountFrac >= 0 && whitelistDiscountFrac <= 99*10**16, "NF_DISCOUNT_RANGE");
        require(publicDiscountFrac >= 0 && publicDiscountFrac <= 99*10**16, "NF_DISCOUNT_RANGE");
        require(minTicketEurUlps<=maxTicketEurUlps);
        require(tokenTerms.EQUITY_TOKENS_PRECISION() == 0);

        require(universe.isInterfaceCollectionInstance(KNOWN_INTERFACE_ETO_TERMS_CONSTRAINTS, etoTermsConstraints), "NF_TERMS_NOT_IN_UNIVERSE");
         
        ETO_TERMS_CONSTRAINTS = etoTermsConstraints;

         
        TOKEN_PRICE_EUR_ULPS = tokenTerms.TOKEN_PRICE_EUR_ULPS();
        EQUITY_TOKENS_PER_SHARE = tokenTerms.EQUITY_TOKENS_PER_SHARE();

        DURATION_TERMS = durationTerms;
        TOKEN_TERMS = tokenTerms;
        SHARE_CAPITAL_CURRENCY_CODE = shareCapitalCurrencyCode;
        EXISTING_SHARE_CAPITAL = existingShareCapital;
        MIN_TICKET_EUR_ULPS = minTicketEurUlps;
        MAX_TICKET_EUR_ULPS = maxTicketEurUlps;
        ENABLE_TRANSFERS_ON_SUCCESS = enableTransfersOnSuccess;
        INVESTOR_OFFERING_DOCUMENT_URL = investorOfferingDocumentUrl;
        SHAREHOLDER_RIGHTS = shareholderRights;
        WHITELIST_DISCOUNT_FRAC = whitelistDiscountFrac;
        PUBLIC_DISCOUNT_FRAC = publicDiscountFrac;
        IDENTITY_REGISTRY = IIdentityRegistry(universe.identityRegistry());
        UNIVERSE = universe;

         
        MAX_AVAILABLE_TOKENS = calculateAvailableTokens(tokenTerms.MAX_NUMBER_OF_TOKENS());
        MAX_AVAILABLE_TOKENS_IN_WHITELIST = min(MAX_AVAILABLE_TOKENS, tokenTerms.MAX_NUMBER_OF_TOKENS_IN_WHITELIST());

         
        requireValidTerms();
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

    function calculatePriceFraction(uint256 priceFrac) public constant returns(uint256) {
        if (priceFrac == 1) {
            return TOKEN_PRICE_EUR_ULPS;
        } else {
            return decimalFraction(priceFrac, TOKEN_PRICE_EUR_ULPS);
        }
    }

     
    function equityTokensToShares(uint256 amount)
        public
        constant
        returns (uint256)
    {
        return proportion(amount, 10**18, EQUITY_TOKENS_PER_SHARE);
    }

    function addWhitelisted(
        address[] investors,
        uint256[] discountAmountsEurUlps,
        uint256[] discountsFrac
    )
        external
        only(ROLE_WHITELIST_ADMIN)
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
         
        isEligible = claims.isVerified && !claims.accountFrozen && !claims.requiresRegDAccreditation;
    }

     
    function requireValidTerms()
        public
        constant
        returns (bool)
    {
         
        uint256 minTokens = TOKEN_TERMS.MIN_NUMBER_OF_TOKENS();
        require(MAX_AVAILABLE_TOKENS >= minTokens, "NF_AVAILABLE_TOKEN_LT_MIN_TOKENS");
         
        require(MIN_TICKET_EUR_ULPS >= TOKEN_TERMS.TOKEN_PRICE_EUR_ULPS(), "NF_MIN_TICKET_LT_TOKEN_PRICE");
         
        uint256 estimatedMaxCap = calculateEurUlpsAmount(0, MAX_AVAILABLE_TOKENS);
        require(estimatedMaxCap >= MIN_TICKET_EUR_ULPS, "NF_MAX_FUNDS_LT_MIN_TICKET");
         
        uint256 constraintsMaxInvestment = ETO_TERMS_CONSTRAINTS.MAX_INVESTMENT_AMOUNT_EUR_ULPS();
        uint256 estimatedMinCap = calculateEurUlpsAmount(0, minTokens);
        require(constraintsMaxInvestment == 0 || estimatedMinCap <= constraintsMaxInvestment, "NF_MIN_CAP_GT_PROD_MAX_CAP");
         
        require(MIN_TICKET_EUR_ULPS >= ETO_TERMS_CONSTRAINTS.MIN_TICKET_SIZE_EUR_ULPS(), "NF_ETO_TERMS_MIN_TICKET_EUR_ULPS");
        uint256 constraintsMaxTicket = ETO_TERMS_CONSTRAINTS.MAX_TICKET_SIZE_EUR_ULPS();
        require(
            constraintsMaxTicket == 0 ||  
            (MAX_TICKET_EUR_ULPS <= constraintsMaxTicket),  
            "NF_ETO_TERMS_MAX_TICKET_EUR_ULPS"
        );

         
        require(!ENABLE_TRANSFERS_ON_SUCCESS || ETO_TERMS_CONSTRAINTS.CAN_SET_TRANSFERABILITY(), "NF_ETO_TERMS_ENABLE_TRANSFERS_ON_SUCCESS");

         
        require(DURATION_TERMS.WHITELIST_DURATION() >= ETO_TERMS_CONSTRAINTS.MIN_WHITELIST_DURATION(), "NF_ETO_TERMS_WL_D_MIN");
        require(DURATION_TERMS.WHITELIST_DURATION() <= ETO_TERMS_CONSTRAINTS.MAX_WHITELIST_DURATION(), "NF_ETO_TERMS_WL_D_MAX");

        require(DURATION_TERMS.PUBLIC_DURATION() >= ETO_TERMS_CONSTRAINTS.MIN_PUBLIC_DURATION(), "NF_ETO_TERMS_PUB_D_MIN");
        require(DURATION_TERMS.PUBLIC_DURATION() <= ETO_TERMS_CONSTRAINTS.MAX_PUBLIC_DURATION(), "NF_ETO_TERMS_PUB_D_MAX");

        uint256 totalDuration = DURATION_TERMS.WHITELIST_DURATION() + DURATION_TERMS.PUBLIC_DURATION();
        require(totalDuration >= ETO_TERMS_CONSTRAINTS.MIN_OFFER_DURATION(), "NF_ETO_TERMS_TOT_O_MIN");
        require(totalDuration <= ETO_TERMS_CONSTRAINTS.MAX_OFFER_DURATION(), "NF_ETO_TERMS_TOT_O_MAX");

        require(DURATION_TERMS.SIGNING_DURATION() >= ETO_TERMS_CONSTRAINTS.MIN_SIGNING_DURATION(), "NF_ETO_TERMS_SIG_MIN");
        require(DURATION_TERMS.SIGNING_DURATION() <= ETO_TERMS_CONSTRAINTS.MAX_SIGNING_DURATION(), "NF_ETO_TERMS_SIG_MAX");

        require(DURATION_TERMS.CLAIM_DURATION() >= ETO_TERMS_CONSTRAINTS.MIN_CLAIM_DURATION(), "NF_ETO_TERMS_CLAIM_MIN");
        require(DURATION_TERMS.CLAIM_DURATION() <= ETO_TERMS_CONSTRAINTS.MAX_CLAIM_DURATION(), "NF_ETO_TERMS_CLAIM_MAX");

        return true;
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x3468b14073c33fa00ee7f8a289b14f4a10c78ab72726033b27003c31c47b3f6a, 3);
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
         
        require((fullTokenPriceFrac > 0 || discountAmountEurUlps == 0) && fullTokenPriceFrac <= 10**18, "NF_DISCOUNT_RANGE");
        require(discountAmountEurUlps < 2**128);


        _whitelist[investor] = WhitelistTicket({
            discountAmountEurUlps: uint128(discountAmountEurUlps),
            fullTokenPriceFrac: uint128(fullTokenPriceFrac)
        });

        emit LogInvestorWhitelisted(investor, discountAmountEurUlps, fullTokenPriceFrac);
    }

    function calculateAvailableTokens(uint256 amountWithFee)
        private
        constant
        returns (uint256)
    {
        return PlatformTerms(UNIVERSE.platformTerms()).calculateAmountWithoutFee(amountWithFee);
    }
}

 
 
 
 
contract ICommitment is
    IAgreement,
    IERC223Callback
{

     
     
     

     
     
     
     
     
    event LogFundsCommitted(
        address indexed investor,
        address wallet,
        address paymentToken,
        uint256 amount,
        uint256 baseCurrencyEquivalent,
        uint256 grantedAmount,
        address assetToken,
        uint256 neuReward
    );

     
     
     

     
    function finalized() public constant returns (bool);

     
    function success() public constant returns (bool);

     
    function failed() public constant returns (bool);

     
    function totalInvestment()
        public
        constant
        returns (
            uint256 totalEquivEurUlps,
            uint256 totalTokensInt,
            uint256 totalInvestors
        );

     
     
     
     
    function tokenFallback(address investor, uint256 amount, bytes data)
        public;

}

 
contract IETOCommitment is
    ICommitment,
    IETOCommitmentStates
{

     
     
     

     
    event LogStateTransition(
        uint32 oldState,
        uint32 newState,
        uint32 timestamp
    );

     
     
    event LogTokensClaimed(
        address indexed investor,
        address indexed assetToken,
        uint256 amount,
        uint256 nmkReward
    );

     
     
     
    event LogFundsRefunded(
        address indexed investor,
        address indexed paymentToken,
        uint256 amount
    );

     
    event LogTermsSet(
        address companyLegalRep,
        address etoTerms,
        address equityToken
    );

     
    event LogETOStartDateSet(
        address companyLegalRep,
        uint256 previousTimestamp,
        uint256 newTimestamp
    );

     
    event LogSigningStarted(
        address nominee,
        address companyLegalRep,
        uint256 newShares,
        uint256 capitalIncreaseUlps
    );

     
    event LogCompanySignedAgreement(
        address companyLegalRep,
        address nominee,
        string signedInvestmentAgreementUrl
    );

     
    event LogNomineeConfirmedAgreement(
        address nominee,
        address companyLegalRep,
        string signedInvestmentAgreementUrl
    );

     
    event LogRefundStarted(
        address assetToken,
        uint256 totalTokenAmountInt,
        uint256 totalRewardNmkUlps
    );

     
     
     

     
     
     

     
    function state() public constant returns (ETOState);

     
    function startOf(ETOState s) public constant returns (uint256);

     
    function commitmentObserver() public constant returns (IETOCommitmentObserver);

     
     
     

     
    function refund() external;

     
    function claim() external;

     
    function payout() external;


     
     
     

    function etoTerms() public constant returns (ETOTerms);

     
    function equityToken() public constant returns (IEquityToken);

     
    function nominee() public constant returns (address);

    function companyLegalRep() public constant returns (address);

     
     
    function signedInvestmentAgreementUrl() public constant returns (string);

     
     
    function contributionSummary()
        public
        constant
        returns (
            uint256 newShares, uint256 capitalIncreaseEurUlps,
            uint256 additionalContributionEth, uint256 additionalContributionEurUlps,
            uint256 tokenParticipationFeeInt, uint256 platformFeeEth, uint256 platformFeeEurUlps,
            uint256 sharePriceEurUlps
        );

     
    function investorTicket(address investor)
        public
        constant
        returns (
            uint256 equivEurUlps,
            uint256 rewardNmkUlps,
            uint256 equityTokenInt,
            uint256 sharesInt,
            uint256 tokenPrice,
            uint256 neuRate,
            uint256 amountEth,
            uint256 amountEurUlps,
            bool claimOrRefundSettled,
            bool usedLockedAccount
        );
}

contract METOStateMachineObserver is IETOCommitmentStates {
     
     
     
    function mBeforeStateTransition(ETOState oldState, ETOState newState)
        internal
        constant
        returns (ETOState newStateOverride);

     
    function mAfterTransition(ETOState oldState, ETOState newState)
        internal;

     
    function mAdavanceLogicState(ETOState oldState)
        internal
        constant
        returns (ETOState);
}

 
 
 
 
 
 
 
contract ETOTimedStateMachine is
    IETOCommitment,
    METOStateMachineObserver
{

     
     
     

     

     
     
     

     
    uint32[] private ETO_STATE_DURATIONS;

     
    IETOCommitmentObserver private COMMITMENT_OBSERVER;

     
     
     

     
    ETOState private _state = ETOState.Setup;

     
     
    uint32[7] internal _pastStateTransitionTimes;

     
     
     

     
     
     
    modifier withStateTransition() {
         
        advanceTimedState();
         
        _;
         
        advanceLogicState();
    }

    modifier onlyState(ETOState state) {
        require(_state == state);
        _;
    }

    modifier onlyStates(ETOState state0, ETOState state1) {
        require(_state == state0 || _state == state1);
        _;
    }

     
     

     
     
     

     
    function handleStateTransitions()
        public
    {
        advanceTimedState();
    }

     
     
     

     
    function finalized()
        public
        constant
        returns (bool)
    {
        return (_state == ETOState.Refund || _state == ETOState.Payout || _state == ETOState.Claim);
    }

     
    function success()
        public
        constant
        returns (bool)
    {
        return (_state == ETOState.Claim || _state == ETOState.Payout);
    }

     
    function failed()
        public
        constant
        returns (bool)
    {
        return _state == ETOState.Refund;
    }

     
     
     

    function state()
        public
        constant
        returns (ETOState)
    {
        return _state;
    }

    function startOf(ETOState s)
        public
        constant
        returns (uint256)
    {
        return startOfInternal(s);
    }

     
    function timedState()
        external
        constant
        returns (ETOState)
    {
         
        advanceTimedState();
        return _state;
    }

    function startOfStates()
        public
        constant
        returns (uint256[7] startOfs)
    {
         
        for(uint256 ii = 0;ii<ETO_STATES_COUNT;ii += 1) {
            startOfs[ii] = startOfInternal(ETOState(ii));
        }
    }

    function commitmentObserver() public constant returns (IETOCommitmentObserver) {
        return COMMITMENT_OBSERVER;
    }

     
     
     

    function setupStateMachine(ETODurationTerms durationTerms, IETOCommitmentObserver observer)
        internal
    {
        require(COMMITMENT_OBSERVER == address(0), "NF_STM_SET_ONCE");
        require(observer != address(0));

        COMMITMENT_OBSERVER = observer;
        ETO_STATE_DURATIONS = [
            0, durationTerms.WHITELIST_DURATION(), durationTerms.PUBLIC_DURATION(), durationTerms.SIGNING_DURATION(),
            durationTerms.CLAIM_DURATION(), 0, 0
            ];
    }

    function runStateMachine(uint32 startDate)
        internal
    {
         
        _pastStateTransitionTimes[uint32(ETOState.Setup)] = startDate;
    }

    function startOfInternal(ETOState s)
        internal
        constant
        returns (uint256)
    {
         
        if (s == ETOState.Setup) {
            return 0;
        }

         
         
         
         

         
        if (s == ETOState.Refund) {
            return _state == s ? _pastStateTransitionTimes[uint32(_state)] : 0;
        }
         
        if (uint32(s) - 1 <= uint32(_state)) {
            return _pastStateTransitionTimes[uint32(s) - 1];
        }
         
        uint256 currStateExpiration = _pastStateTransitionTimes[uint32(_state)];
         
         
         
        for (uint256 stateIdx = uint32(_state) + 1; stateIdx < uint32(s); stateIdx++) {
            currStateExpiration += ETO_STATE_DURATIONS[stateIdx];
        }
        return currStateExpiration;
    }

     
     
     

     
     
     
    function advanceTimedState()
        private
    {
         
        if (_pastStateTransitionTimes[uint32(ETOState.Setup)] == 0) {
            return;
        }

        uint256 t = block.timestamp;
        if (_state == ETOState.Setup && t >= startOfInternal(ETOState.Whitelist)) {
            transitionTo(ETOState.Whitelist);
        }
        if (_state == ETOState.Whitelist && t >= startOfInternal(ETOState.Public)) {
            transitionTo(ETOState.Public);
        }
        if (_state == ETOState.Public && t >= startOfInternal(ETOState.Signing)) {
            transitionTo(ETOState.Signing);
        }
         
         
        if (_state == ETOState.Signing && t >= startOfInternal(ETOState.Claim)) {
            transitionTo(ETOState.Refund);
        }
         
        if (_state == ETOState.Claim && t >= startOfInternal(ETOState.Payout)) {
            transitionTo(ETOState.Payout);
        }
    }

     
     
    function advanceLogicState()
        private
    {
        ETOState newState = mAdavanceLogicState(_state);
        if (_state != newState) {
            transitionTo(newState);
             
            advanceLogicState();
        }
    }

     
    function transitionTo(ETOState newState)
        private
    {
        ETOState oldState = _state;
        ETOState effectiveNewState = mBeforeStateTransition(oldState, newState);
         

        _state = effectiveNewState;
         
        uint32 deadline = _pastStateTransitionTimes[uint256(oldState)];
         
        if (uint32(block.timestamp) < deadline) {
            deadline = uint32(block.timestamp);
        }
         
        _pastStateTransitionTimes[uint256(oldState)] = deadline;
         
        _pastStateTransitionTimes[uint256(effectiveNewState)] = deadline + ETO_STATE_DURATIONS[uint256(effectiveNewState)];
         
        mAfterTransition(oldState, effectiveNewState);
        assert(_state == effectiveNewState);
         
        COMMITMENT_OBSERVER.onStateTransition(oldState, effectiveNewState);
        emit LogStateTransition(uint32(oldState), uint32(effectiveNewState), deadline);
    }

     
}

 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
contract ETOCommitment is
    AccessControlled,
    Agreement,
    ETOTimedStateMachine,
    Math,
    Serialization,
    IContractId,
    KnownInterfaces
{

     
     
     

     
     
    struct InvestmentTicket {
         
         
        uint96 equivEurUlps;
         
        uint96 rewardNmkUlps;
         
        uint96 equityTokenInt;
         
        uint96 amountEth;
         
        uint96 amountEurUlps;
         
        bool claimOrRefundSettled;
         
        bool usedLockedAccount;
         
    }

     
     
     

     
    Universe private UNIVERSE;
     
    Neumark private NEUMARK;
     
    IERC223Token private ETHER_TOKEN;
     
    IERC223Token private EURO_TOKEN;
     
    LockedAccount private ETHER_LOCK;
    LockedAccount private EURO_LOCK;
     
    IEquityToken private EQUITY_TOKEN;
     
    ITokenExchangeRateOracle private CURRENCY_RATES;

     
    uint256 private MIN_NUMBER_OF_TOKENS;
     
    uint256 private MAX_AVAILABLE_TOKENS;
     
    uint256 private MAX_AVAILABLE_TOKENS_IN_WHITELIST;
     
    uint256 private MIN_TICKET_TOKENS;
     
    uint128 private PLATFORM_NEUMARK_SHARE;
     
    uint128 private TOKEN_RATE_EXPIRES_AFTER;
     
    uint256 private MAX_INVESTMENT_AMOUNT_EUR_ULPS;
     
    uint256 private MIN_TICKET_EUR_ULPS;

     
    address private COMPANY_LEGAL_REPRESENTATIVE;
     
    address private NOMINEE;

     
    ETOTerms private ETO_TERMS;
     
    ETOTermsConstraints public ETO_TERMS_CONSTRAINTS;
     
    PlatformTerms private PLATFORM_TERMS;
     
    address public TOKEN_OFFERING_OPERATOR;

     
     
     

     
    mapping (address => InvestmentTicket) private _tickets;

     
     
    uint112 private _totalEquivEurUlps;
     
    uint56 private _totalTokensInt;
     
    uint56 private _totalFixedSlotsTokensInt;
     
    uint32 private _totalInvestors;

     
    bytes32 private _nomineeSignedInvestmentAgreementUrlHash;

     
     
    uint112 private _additionalContributionEth;
     
     
    uint112 private _additionalContributionEurUlps;

     
     
    uint64 private _newShares;
     
    uint64 private _tokenParticipationFeeInt;
     
    uint112 private _platformFeeEth;
     
    uint112 private _platformFeeEurUlps;

     
    string private _signedInvestmentAgreementUrl;

     
     
     

    modifier onlyCompany() {
        require(msg.sender == COMPANY_LEGAL_REPRESENTATIVE);
        _;
    }

    modifier onlyNominee() {
        require(msg.sender == NOMINEE);
        _;
    }

    modifier onlyWithAgreement {
        require(amendmentsCount() > 0);
        _;
    }

     
     
     

     
    event LogAdditionalContribution(
        address companyLegalRep,
        address paymentToken,
        uint256 amount
    );

     
    event LogPlatformNeuReward(
        address tokenOfferingOperator,
        uint256 totalRewardNmkUlps,
        uint256 platformRewardNmkUlps
    );

     
    event LogPlatformFeePayout(
        address paymentToken,
        address disbursalPool,
        uint256 amount
    );

     
    event LogPlatformPortfolioPayout(
        address assetToken,
        address platformPortfolio,
        uint256 amount
    );

     
     
     

     
    constructor(
        Universe universe,
        address nominee,
        address companyLegalRep,
        ETOTerms etoTerms,
        IEquityToken equityToken
    )
        Agreement(universe.accessPolicy(), universe.forkArbiter())
        ETOTimedStateMachine()
        public
    {
        UNIVERSE = universe;
        PLATFORM_TERMS = PlatformTerms(universe.platformTerms());

        require(equityToken.decimals() == etoTerms.TOKEN_TERMS().EQUITY_TOKENS_PRECISION());
        require(nominee != address(0) && companyLegalRep != address(0));

        ETO_TERMS_CONSTRAINTS = etoTerms.ETO_TERMS_CONSTRAINTS();
        TOKEN_OFFERING_OPERATOR = ETO_TERMS_CONSTRAINTS.TOKEN_OFFERING_OPERATOR();

        COMPANY_LEGAL_REPRESENTATIVE = companyLegalRep;
        NOMINEE = nominee;
        PLATFORM_NEUMARK_SHARE = uint128(PLATFORM_TERMS.PLATFORM_NEUMARK_SHARE());
        TOKEN_RATE_EXPIRES_AFTER = uint128(PLATFORM_TERMS.TOKEN_RATE_EXPIRES_AFTER());

        NEUMARK = universe.neumark();
        ETHER_TOKEN = universe.etherToken();
        EURO_TOKEN = universe.euroToken();
        ETHER_LOCK = LockedAccount(universe.etherLock());
        EURO_LOCK = LockedAccount(universe.euroLock());
        CURRENCY_RATES = ITokenExchangeRateOracle(universe.tokenExchangeRateOracle());

        ETO_TERMS = etoTerms;
        EQUITY_TOKEN = equityToken;

        MIN_TICKET_EUR_ULPS = etoTerms.MIN_TICKET_EUR_ULPS();
        MAX_AVAILABLE_TOKENS = etoTerms.MAX_AVAILABLE_TOKENS();
        MAX_AVAILABLE_TOKENS_IN_WHITELIST = etoTerms.MAX_AVAILABLE_TOKENS_IN_WHITELIST();
        MIN_NUMBER_OF_TOKENS = etoTerms.TOKEN_TERMS().MIN_NUMBER_OF_TOKENS();
        MIN_TICKET_TOKENS = etoTerms.calculateTokenAmount(0, MIN_TICKET_EUR_ULPS);

        MAX_INVESTMENT_AMOUNT_EUR_ULPS = ETO_TERMS_CONSTRAINTS.MAX_INVESTMENT_AMOUNT_EUR_ULPS();
         
        if (MAX_INVESTMENT_AMOUNT_EUR_ULPS == 0) {
            MAX_INVESTMENT_AMOUNT_EUR_ULPS -= 1;
        }
        setupStateMachine(
            ETO_TERMS.DURATION_TERMS(),
            IETOCommitmentObserver(EQUITY_TOKEN.tokenController())
        );
    }

     
     
     

     
    function setStartDate(
        ETOTerms etoTerms,
        IEquityToken equityToken,
        uint256 startDate
    )
        external
        onlyCompany
        onlyWithAgreement
        withStateTransition()
        onlyState(ETOState.Setup)
    {
        require(etoTerms == ETO_TERMS);
        require(equityToken == EQUITY_TOKEN);
        assert(startDate < 0xFFFFFFFF);
         
        require(
            startDate > block.timestamp && startDate - block.timestamp > ETO_TERMS_CONSTRAINTS.DATE_TO_WHITELIST_MIN_DURATION(),
            "NF_ETO_DATE_TOO_EARLY");
         
        uint256 startAt = startOfInternal(ETOState.Whitelist);
         
        require(
            startAt == 0 || (startAt - block.timestamp > ETO_TERMS_CONSTRAINTS.DATE_TO_WHITELIST_MIN_DURATION()),
            "NF_ETO_START_TOO_SOON");
        runStateMachine(uint32(startDate));
         

        emit LogTermsSet(msg.sender, address(etoTerms), address(equityToken));
        emit LogETOStartDateSet(msg.sender, startAt, startDate);
    }

    function companySignsInvestmentAgreement(string signedInvestmentAgreementUrl)
        public
        withStateTransition()
        onlyState(ETOState.Signing)
        onlyCompany
    {
        _signedInvestmentAgreementUrl = signedInvestmentAgreementUrl;
        emit LogCompanySignedAgreement(msg.sender, NOMINEE, signedInvestmentAgreementUrl);
    }

    function nomineeConfirmsInvestmentAgreement(string signedInvestmentAgreementUrl)
        public
        withStateTransition()
        onlyState(ETOState.Signing)
        onlyNominee
    {
        bytes32 nomineeHash = keccak256(abi.encodePacked(signedInvestmentAgreementUrl));
        require(keccak256(abi.encodePacked(_signedInvestmentAgreementUrl)) == nomineeHash, "NF_INV_HASH");
         
        _nomineeSignedInvestmentAgreementUrlHash = nomineeHash;
        emit LogNomineeConfirmedAgreement(msg.sender, COMPANY_LEGAL_REPRESENTATIVE, signedInvestmentAgreementUrl);
    }

     
     
     

     
     
    function tokenFallback(address wallet, uint256 amount, bytes data)
        public
        withStateTransition()
        onlyStates(ETOState.Whitelist, ETOState.Public)
    {
         
        require(msg.sender == address(ETHER_TOKEN) || msg.sender == address(EURO_TOKEN), "NF_ETO_UNK_TOKEN");
        address investor = wallet;
         
        if (wallet == address(ETHER_LOCK) || wallet == address(EURO_LOCK)) {
             
            investor = decodeAddress(data);
        }
         
        uint256 equivEurUlps = msg.sender == address(EURO_TOKEN) ? amount : convertToEurEquiv(amount);
         
        acceptAgreementInternal(investor);
         
        (,,,,
            uint256 equityTokenInt,
            uint256 fixedSlotEquityTokenInt,
            uint256 investorNmk) = issueTokens(investor, wallet, equivEurUlps);

         
        bool firstTimeInvestment = updateInvestorTicket(
            investor,
            wallet,
            equivEurUlps,
            investorNmk,
            equityTokenInt,
            amount
        );

         
        updateTotalInvestment(
            equityTokenInt,
            fixedSlotEquityTokenInt,
            equivEurUlps,
            amount,
            firstTimeInvestment
        );

         
        emit LogFundsCommitted(
            investor,
            wallet,
            msg.sender,
            amount,
            equivEurUlps,
            equityTokenInt,
            EQUITY_TOKEN,
            investorNmk
        );
    }

     
     
     

    function claim()
        external
        withStateTransition()
        onlyStates(ETOState.Claim, ETOState.Payout)

    {
        claimTokensPrivate(msg.sender);
    }

    function refund()
        external
        withStateTransition()
        onlyState(ETOState.Refund)

    {
        refundTokensPrivate(msg.sender);
    }

    function payout()
        external
        withStateTransition()
        onlyState(ETOState.Payout)
    {
         
    }

     
     
     

     
     
     

    function signedInvestmentAgreementUrl()
        public
        constant
        returns (string)
    {
        return _signedInvestmentAgreementUrl;
    }

    function contributionSummary()
        public
        constant
        returns (
            uint256 newShares, uint256 capitalIncreaseUlps,
            uint256 additionalContributionEth, uint256 additionalContributionEurUlps,
            uint256 tokenParticipationFeeInt, uint256 platformFeeEth, uint256 platformFeeEurUlps,
            uint256 sharePriceEurUlps
        )
    {
        return (
            _newShares, _newShares * ETO_TERMS.TOKEN_TERMS().SHARE_NOMINAL_VALUE_ULPS(),
            _additionalContributionEth, _additionalContributionEurUlps,
            _tokenParticipationFeeInt, _platformFeeEth, _platformFeeEurUlps,
            _newShares == 0 ? 0 : divRound(_totalEquivEurUlps, _newShares)
        );
    }

    function etoTerms() public constant returns (ETOTerms) {
        return ETO_TERMS;
    }

    function equityToken() public constant returns (IEquityToken) {
        return EQUITY_TOKEN;
    }

    function nominee() public constant returns (address) {
        return NOMINEE;
    }

    function companyLegalRep() public constant returns (address) {
        return COMPANY_LEGAL_REPRESENTATIVE;
    }

    function singletons()
        public
        constant
        returns (
            address tokenOfferingOperator,
            address universe,
            address platformTerms
            )
    {
        tokenOfferingOperator = TOKEN_OFFERING_OPERATOR;
        universe = UNIVERSE;
        platformTerms = PLATFORM_TERMS;
    }

    function totalInvestment()
        public
        constant
        returns (
            uint256 totalEquivEurUlps,
            uint256 totalTokensInt,
            uint256 totalInvestors
            )
    {
        return (_totalEquivEurUlps, _totalTokensInt, _totalInvestors);
    }

    function calculateContribution(address investor, bool fromIcbmWallet, uint256 newInvestorContributionEurUlps)
        external
        constant
         
        withStateTransition()
        returns (
            bool isWhitelisted,
            bool isEligible,
            uint256 minTicketEurUlps,
            uint256 maxTicketEurUlps,
            uint256 equityTokenInt,
            uint256 neuRewardUlps,
            bool maxCapExceeded,
            uint256 spentAmountEurUlps
            )
    {
        InvestmentTicket storage ticket = _tickets[investor];
        uint256 fixedSlotsEquityTokenInt;
        (
            isWhitelisted,
            isEligible,
            minTicketEurUlps,
            maxTicketEurUlps,
            equityTokenInt,
            fixedSlotsEquityTokenInt
        ) = ETO_TERMS.calculateContribution(
            investor,
            _totalEquivEurUlps,
            ticket.equivEurUlps,
            newInvestorContributionEurUlps,
             
            state() == ETOState.Whitelist
        );
        isWhitelisted = isWhitelisted || fromIcbmWallet;
        if (!fromIcbmWallet) {
            (,neuRewardUlps) = calculateNeumarkDistribution(NEUMARK.incremental(newInvestorContributionEurUlps));
        }
         
        maxCapExceeded = isCapExceeded(state() == ETOState.Whitelist, equityTokenInt, fixedSlotsEquityTokenInt, newInvestorContributionEurUlps);
         
        spentAmountEurUlps = newInvestorContributionEurUlps;
    }

    function investorTicket(address investor)
        public
        constant
        returns (
            uint256 equivEurUlps,
            uint256 rewardNmkUlps,
            uint256 equityTokenInt,
            uint256 sharesFrac,
            uint256 tokenPrice,
            uint256 neuRate,
            uint256 amountEth,
            uint256 amountEurUlps,
            bool claimedOrRefunded,
            bool usedLockedAccount
        )
    {
        InvestmentTicket storage ticket = _tickets[investor];
         
        equivEurUlps = ticket.equivEurUlps;
        rewardNmkUlps = ticket.rewardNmkUlps;
        equityTokenInt = ticket.equityTokenInt;
        sharesFrac = ETO_TERMS.equityTokensToShares(ticket.equityTokenInt);
        tokenPrice = equityTokenInt > 0 ? equivEurUlps / equityTokenInt : 0;
        neuRate = rewardNmkUlps > 0 ? proportion(equivEurUlps, 10**18, rewardNmkUlps) : 0;
        amountEth = ticket.amountEth;
        amountEurUlps = ticket.amountEurUlps;
        claimedOrRefunded = ticket.claimOrRefundSettled;
        usedLockedAccount = ticket.usedLockedAccount;
    }

     
     
     
     
    function recycle(address[] tokens)
        public
        onlyState(ETOState.Payout)
    {
        IFeeDisbursal disbursal = IFeeDisbursal(UNIVERSE.feeDisbursal());
        for (uint256 i = 0; i < tokens.length; i += 1) {
            address token = tokens[i];
            disbursal.reject(token, NEUMARK, 256**2-1);
        }
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x70ef68fc8c585f9edc7af1bfac26c4b1b9e98ba05cf5ddd99e4b3dc46ea70073, 2);
    }

     
     
     

     
     
     

    function mAdavanceLogicState(ETOState oldState)
        internal
        constant
        returns (ETOState)
    {
         
         
         
        bool capExceeded = isCapExceeded(false, MIN_TICKET_TOKENS + 1, 0, MIN_TICKET_EUR_ULPS);
        if (capExceeded) {
            if (oldState == ETOState.Whitelist) {
                return ETOState.Public;
            }
            if (oldState == ETOState.Public) {
                return ETOState.Signing;
            }
        }
        if (oldState == ETOState.Signing && _nomineeSignedInvestmentAgreementUrlHash != bytes32(0)) {
            return ETOState.Claim;
        }
        return oldState;
    }

    function mBeforeStateTransition(ETOState  , ETOState newState)
        internal
        constant
        returns (ETOState)
    {
         
         
        if (newState == ETOState.Signing && _totalTokensInt < MIN_NUMBER_OF_TOKENS) {
            return ETOState.Refund;
        }
         
         
         
         

        return newState;
    }

    function mAfterTransition(ETOState  , ETOState newState)
        internal
    {
        if (newState == ETOState.Signing) {
            onSigningTransition();
        }
        if (newState == ETOState.Claim) {
            onClaimTransition();
        }
        if (newState == ETOState.Refund) {
            onRefundTransition();
        }
        if (newState == ETOState.Payout) {
            onPayoutTransition();
        }
    }

     
     
     

    function mCanAmend(address legalRepresentative)
        internal
        returns (bool)
    {
        return legalRepresentative == NOMINEE && startOfInternal(ETOState.Whitelist) == 0;
    }

     
     
     

     
    function calculateNeumarkDistribution(uint256 rewardNmk)
        private
        constant
        returns (uint256 platformNmk, uint256 investorNmk)
    {
         
        platformNmk = rewardNmk / PLATFORM_NEUMARK_SHARE;
         
        return (platformNmk, rewardNmk - platformNmk);
    }

     
    function onSigningTransition()
        private
    {
        ETOTokenTerms tokenTerms = ETO_TERMS.TOKEN_TERMS();
         
        uint256 tokensPerShare = tokenTerms.EQUITY_TOKENS_PER_SHARE();
         
         
         
         
         
        uint256 tokenParticipationFeeInt;
        if (_totalTokensInt == MAX_AVAILABLE_TOKENS) {
            uint256 maxTokens = tokenTerms.MAX_NUMBER_OF_TOKENS();
             
             
            tokenParticipationFeeInt = maxTokens - MAX_AVAILABLE_TOKENS;
        } else {
            tokenParticipationFeeInt = PLATFORM_TERMS.calculatePlatformTokenFee(_totalTokensInt);
             
            uint256 tokensRemainder = (_totalTokensInt + tokenParticipationFeeInt) % tokensPerShare;
            if (tokensRemainder > 0) {
                 
                tokenParticipationFeeInt += tokensPerShare - tokensRemainder;
            }
        }
         
        uint256 totalIssuedTokens = _totalTokensInt + tokenParticipationFeeInt;
         
         
         
         
         
        _newShares = uint64(totalIssuedTokens / tokensPerShare);
         
        _tokenParticipationFeeInt = uint64(tokenParticipationFeeInt);
         
         
         
        _platformFeeEth = uint112(PLATFORM_TERMS.calculatePlatformFee(_additionalContributionEth));
        _platformFeeEurUlps = uint112(PLATFORM_TERMS.calculatePlatformFee(_additionalContributionEurUlps));
         
        _additionalContributionEth -= _platformFeeEth;
        _additionalContributionEurUlps -= _platformFeeEurUlps;
         
        uint256 capitalIncreaseEurUlps = tokenTerms.SHARE_NOMINAL_VALUE_EUR_ULPS() * _newShares;
         
         
        uint112 availableCapitalEurUlps = uint112(min(capitalIncreaseEurUlps, _additionalContributionEurUlps));
        assert(EURO_TOKEN.transfer(NOMINEE, availableCapitalEurUlps, ""));
         
        _additionalContributionEurUlps -= availableCapitalEurUlps;
         
        uint256 capitalIncreaseUlps = tokenTerms.SHARE_NOMINAL_VALUE_ULPS() * _newShares;
        emit LogSigningStarted(NOMINEE, COMPANY_LEGAL_REPRESENTATIVE, _newShares, capitalIncreaseUlps);
    }

     
    function onClaimTransition()
        private
    {
         
        uint256 rewardNmk = NEUMARK.balanceOf(this);
        (uint256 platformNmk,) = calculateNeumarkDistribution(rewardNmk);
         
        assert(NEUMARK.transfer(TOKEN_OFFERING_OPERATOR, platformNmk, ""));
         
        if (_additionalContributionEth > 0) {
            assert(ETHER_TOKEN.transfer(COMPANY_LEGAL_REPRESENTATIVE, _additionalContributionEth, ""));
        }

        if (_additionalContributionEurUlps > 0) {
            assert(EURO_TOKEN.transfer(COMPANY_LEGAL_REPRESENTATIVE, _additionalContributionEurUlps, ""));
        }
         
        EQUITY_TOKEN.issueTokens(_tokenParticipationFeeInt);
        emit LogPlatformNeuReward(TOKEN_OFFERING_OPERATOR, rewardNmk, platformNmk);
        emit LogAdditionalContribution(COMPANY_LEGAL_REPRESENTATIVE, ETHER_TOKEN, _additionalContributionEth);
        emit LogAdditionalContribution(COMPANY_LEGAL_REPRESENTATIVE, EURO_TOKEN, _additionalContributionEurUlps);
    }

     
    function onRefundTransition()
        private
    {
         
        uint256 balanceNmk = NEUMARK.balanceOf(this);
        uint256 balanceTokenInt = EQUITY_TOKEN.balanceOf(this);
        if (balanceNmk > 0) {
            NEUMARK.burn(balanceNmk);
        }
         
        if (balanceTokenInt > 0) {
            EQUITY_TOKEN.destroyTokens(balanceTokenInt);
        }
        emit LogRefundStarted(EQUITY_TOKEN, balanceTokenInt, balanceNmk);
    }

     
    function onPayoutTransition()
        private
    {
         
        IFeeDisbursal disbursal = IFeeDisbursal(UNIVERSE.feeDisbursal());
        assert(disbursal != address(0));
        address platformPortfolio = UNIVERSE.platformPortfolio();
        assert(platformPortfolio != address(0));
        bytes memory serializedAddress = abi.encodePacked(address(NEUMARK));
        if (_platformFeeEth > 0) {
             
            assert(ETHER_TOKEN.transfer(disbursal, _platformFeeEth, serializedAddress));
        }
        if (_platformFeeEurUlps > 0) {
             
            assert(EURO_TOKEN.transfer(disbursal, _platformFeeEurUlps, serializedAddress));
        }
         
         
         
         
         
         
         
        EQUITY_TOKEN.distributeTokens(platformPortfolio, _tokenParticipationFeeInt);

        emit LogPlatformFeePayout(ETHER_TOKEN, disbursal, _platformFeeEth);
        emit LogPlatformFeePayout(EURO_TOKEN, disbursal, _platformFeeEurUlps);
        emit LogPlatformPortfolioPayout(EQUITY_TOKEN, platformPortfolio, _tokenParticipationFeeInt);
    }

    function issueTokens(
        address investor,
        address wallet,
        uint256 equivEurUlps
    )
        private
        returns (
            bool isWhitelisted,
            bool isEligible,
            uint256 minTicketEurUlps,
            uint256 maxTicketEurUlps,
            uint256 equityTokenInt,
            uint256 fixedSlotEquityTokenInt,
            uint256 investorNmk
        )
    {
         
        InvestmentTicket storage ticket = _tickets[investor];
         
        bool applyDiscounts = state() == ETOState.Whitelist;
         
        (
            isWhitelisted,
            isEligible,
            minTicketEurUlps,
            maxTicketEurUlps,
            equityTokenInt,
            fixedSlotEquityTokenInt
        ) = ETO_TERMS.calculateContribution(investor, _totalEquivEurUlps, ticket.equivEurUlps, equivEurUlps, applyDiscounts);
         
        require(isEligible, "NF_ETO_INV_NOT_ELIGIBLE");
         
        require(equivEurUlps + ticket.equivEurUlps >= minTicketEurUlps && equityTokenInt > 0, "NF_ETO_MIN_TICKET");
         
        require(equivEurUlps + ticket.equivEurUlps <= maxTicketEurUlps, "NF_ETO_MAX_TICKET");
         
        require(!isCapExceeded(applyDiscounts, equityTokenInt, fixedSlotEquityTokenInt, equivEurUlps), "NF_ETO_MAX_TOK_CAP");
         
         
         
        if (applyDiscounts) {
            require(isWhitelisted || wallet != investor, "NF_ETO_NOT_ON_WL");
        }
         
         
        if (wallet == investor) {
            (, investorNmk) = calculateNeumarkDistribution(NEUMARK.issueForEuro(equivEurUlps));
            if (investorNmk > 0) {
                 
                 
                 
                assert(investorNmk > PLATFORM_NEUMARK_SHARE - 1);
                investorNmk -= PLATFORM_NEUMARK_SHARE - 1;
            }
        }
         
        EQUITY_TOKEN.issueTokens(equityTokenInt);
    }

    function convertToEurEquiv(uint256 amountEth)
        private
        constant
        returns (uint256)
    {
         
        (uint256 rate, uint256 rateTimestamp) = CURRENCY_RATES.getExchangeRate(ETHER_TOKEN, EURO_TOKEN);
         
        require(block.timestamp - rateTimestamp < TOKEN_RATE_EXPIRES_AFTER, "NF_ETO_INVALID_ETH_RATE");
        return decimalFraction(amountEth, rate);
    }

    function updateInvestorTicket(
        address investor,
        address wallet,
        uint256 equivEurUlps,
        uint256 investorNmk,
        uint256 equityTokenInt,
        uint256 amount
    )
        private
        returns (bool firstTimeInvestor)
    {
        InvestmentTicket storage ticket = _tickets[investor];
        firstTimeInvestor = ticket.equivEurUlps == 0;
         
         
        uint256 newEquivEurUlps = ticket.equivEurUlps + equivEurUlps;
        require(newEquivEurUlps < 2**96, "NF_TICKET_EXCEEDS_MAX_EUR");
         
        uint96 newRewardNmkUlps = ticket.rewardNmkUlps + uint96(investorNmk);
         
        uint96 newEquityTokenInt = ticket.equityTokenInt + uint96(equityTokenInt);
         
         
        uint96 newAmountEth = ticket.amountEth;
        uint96 newAmountEurUlps = ticket.amountEurUlps;
        if (msg.sender == address(EURO_TOKEN)) {
            newAmountEurUlps += uint96(amount);
        } else {
            newAmountEth += uint96(amount);
        }
         
        bool usedLockedAccount = ticket.usedLockedAccount || investor != wallet;

         
        ticket.equivEurUlps = uint96(newEquivEurUlps);
        ticket.rewardNmkUlps = newRewardNmkUlps;
        ticket.equityTokenInt = newEquityTokenInt;
        ticket.amountEth = newAmountEth;
        ticket.amountEurUlps = newAmountEurUlps;
        ticket.usedLockedAccount = usedLockedAccount;
    }

    function updateTotalInvestment(
        uint256 equityTokenInt,
        uint256 fixedSlotEquityTokenInt,
        uint256 equivEurUlps,
        uint256 amount,
        bool firstTimeInvestment
    )
        private
    {
         
        uint256 newTotalTokensInt = _totalTokensInt + equityTokenInt;
        assert(newTotalTokensInt < 2**56);
         
        uint56 newTotalFixedSlotsTokensInt = _totalFixedSlotsTokensInt + uint56(fixedSlotEquityTokenInt);
         
        uint32 newTotalInvestors = _totalInvestors + (firstTimeInvestment ? 1 : 0);
         
        uint256 newTotalEquivEurUlps = _totalEquivEurUlps + equivEurUlps;
        assert(newTotalEquivEurUlps < 2**112);
         
        uint112 newTotalEth = _additionalContributionEth;
        uint112 newTotalEurUlps = _additionalContributionEurUlps;
        if (msg.sender == address(EURO_TOKEN)) {
            newTotalEurUlps += uint112(amount);
        } else {
            newTotalEth += uint112(amount);
        }

         
        _totalTokensInt = uint56(newTotalTokensInt);
        _totalFixedSlotsTokensInt = newTotalFixedSlotsTokensInt;
        _totalInvestors = newTotalInvestors;
        _totalEquivEurUlps = uint112(newTotalEquivEurUlps);
        _additionalContributionEth = newTotalEth;
        _additionalContributionEurUlps = newTotalEurUlps;
    }

    function isCapExceeded(bool applyDiscounts, uint256 equityTokenInt, uint256 fixedSlotsEquityTokenInt, uint256 equivEurUlps)
        private
        constant
        returns (bool maxCapExceeded)
    {
         
        maxCapExceeded = _totalTokensInt + equityTokenInt > MAX_AVAILABLE_TOKENS;
        if (applyDiscounts && !maxCapExceeded) {
            maxCapExceeded = _totalTokensInt + equityTokenInt - _totalFixedSlotsTokensInt - fixedSlotsEquityTokenInt > MAX_AVAILABLE_TOKENS_IN_WHITELIST;
        }
         
        if ( !maxCapExceeded && (equivEurUlps + _totalEquivEurUlps > MAX_INVESTMENT_AMOUNT_EUR_ULPS )) {
            maxCapExceeded = true;
        }
    }

    function claimTokensPrivate(address investor)
        private
    {
        InvestmentTicket storage ticket = _tickets[investor];
        if (ticket.claimOrRefundSettled) {
            return;
        }
        if (ticket.equivEurUlps == 0) {
            return;
        }
        ticket.claimOrRefundSettled = true;

        if (ticket.rewardNmkUlps > 0) {
            NEUMARK.distribute(investor, ticket.rewardNmkUlps);
        }
        if (ticket.equityTokenInt > 0) {
            EQUITY_TOKEN.distributeTokens(investor, ticket.equityTokenInt);
        }
        if (ticket.usedLockedAccount) {
            ETHER_LOCK.claimed(investor);
            EURO_LOCK.claimed(investor);
        }
        emit LogTokensClaimed(investor, EQUITY_TOKEN, ticket.equityTokenInt, ticket.rewardNmkUlps);
    }

    function refundTokensPrivate(address investor)
        private
    {
        InvestmentTicket storage ticket = _tickets[investor];
        if (ticket.claimOrRefundSettled) {
            return;
        }
        if (ticket.equivEurUlps == 0) {
            return;
        }
        ticket.claimOrRefundSettled = true;
        refundSingleToken(investor, ticket.amountEth, ticket.usedLockedAccount, ETHER_LOCK, ETHER_TOKEN);
        refundSingleToken(investor, ticket.amountEurUlps, ticket.usedLockedAccount, EURO_LOCK, EURO_TOKEN);

        emit LogFundsRefunded(investor, ETHER_TOKEN, ticket.amountEth);
        emit LogFundsRefunded(investor, EURO_TOKEN, ticket.amountEurUlps);
    }

    function refundSingleToken(
        address investor,
        uint256 amount,
        bool usedLockedAccount,
        LockedAccount lockedAccount,
        IERC223Token token
    )
        private
    {
        if (amount == 0) {
            return;
        }
        uint256 a = amount;
         
        if (usedLockedAccount) {
            (uint256 balance,) = lockedAccount.pendingCommitments(this, investor);
            assert(balance <= a);
            if (balance > 0) {
                assert(token.approve(address(lockedAccount), balance));
                lockedAccount.refunded(investor);
                a -= balance;
            }
        }
        if (a > 0) {
            assert(token.transfer(investor, a, ""));
        }
    }
}