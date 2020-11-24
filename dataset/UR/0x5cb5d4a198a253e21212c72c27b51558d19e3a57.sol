 

pragma solidity 0.4.15;

 
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

     
     
     

    function AccessControlled(IAccessPolicy policy) internal {
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

         
        LogAccessPolicyChanged(msg.sender, oldPolicy, newPolicy);
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

     
     
     

     
     
     

     
    bytes32 internal constant ROLE_LOCKED_ACCOUNT_ADMIN = 0x4675da546d2d92c5b86c4f726a9e61010dce91cccc2491ce6019e78b09d2572e;

     
    bytes32 internal constant ROLE_WHITELIST_ADMIN = 0xaef456e7c864418e1d2a40d996ca4febf3a7e317fe3af5a7ea4dda59033bbe5c;

     
    bytes32 internal constant ROLE_NEUMARK_ISSUER = 0x921c3afa1f1fff707a785f953a1e197bd28c9c50e300424e015953cbf120c06c;

     
    bytes32 internal constant ROLE_NEUMARK_BURNER = 0x19ce331285f41739cd3362a3ec176edffe014311c0f8075834fdd19d6718e69f;

     
    bytes32 internal constant ROLE_SNAPSHOT_CREATOR = 0x08c1785afc57f933523bc52583a72ce9e19b2241354e04dd86f41f887e3d8174;

     
    bytes32 internal constant ROLE_TRANSFER_ADMIN = 0xb6527e944caca3d151b1f94e49ac5e223142694860743e66164720e034ec9b19;

     
    bytes32 internal constant ROLE_RECLAIMER = 0x0542bbd0c672578966dcc525b30aa16723bb042675554ac5b0362f86b6e97dc5;

     
    bytes32 internal constant ROLE_PLATFORM_OPERATOR_REPRESENTATIVE = 0xb2b321377653f655206f71514ff9f150d0822d062a5abcf220d549e1da7999f0;

     
    bytes32 internal constant ROLE_EURT_DEPOSIT_MANAGER = 0x7c8ecdcba80ce87848d16ad77ef57cc196c208fc95c5638e4a48c681a34d4fe7;
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

contract IBasicToken {

     
     
     

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount);

     
     
     

     
     
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
            reclaimer.transfer(this.balance);
        } else {
            uint256 balance = token.balanceOf(this);
            require(token.transfer(reclaimer, balance));
        }
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

     
     
     

     
     
     
     
     
    function TokenMetadata(
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

contract IERC223Callback {

     
     
     

    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes data
    )
        public;

}

contract IERC223Token is IBasicToken {

     
     
     

     
     
     
     
     


     
     

     
     
     

     
     
     

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool);
}

contract IERC20Allowance {

     
     
     

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount);

     
     
     

     
     
     
     
     
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

contract Math {

     
     
     

     
    function absDiff(uint256 v1, uint256 v2)
        internal
        constant
        returns(uint256)
    {
        return v1 > v2 ? v1 - v2 : v2 - v1;
    }

     
    function divRound(uint256 v, uint256 d)
        internal
        constant
        returns(uint256)
    {
        return add(v, d/2) / d;
    }

     
     
     
     
    function decimalFraction(uint256 amount, uint256 frac)
        internal
        constant
        returns(uint256)
    {
         
        return proportion(amount, frac, 10**18);
    }

     
     
    function proportion(uint256 amount, uint256 part, uint256 total)
        internal
        constant
        returns(uint256)
    {
        return divRound(mul(amount, part), total);
    }

     
     
     

    function mul(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

 
contract BasicToken is IBasicToken, Math {

     
     
     

    mapping(address => uint256) internal _balances;

    uint256 internal _totalSupply;

     
     
     

     
    function transfer(address to, uint256 amount)
        public
        returns (bool)
    {
        transferInternal(msg.sender, to, amount);
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

     
     
     

     
    function transferInternal(address from, address to, uint256 amount)
        internal
    {
        require(to != address(0));

        _balances[from] = sub(_balances[from], amount);
        _balances[to] = add(_balances[to], amount);
        Transfer(from, to, amount);
    }
}

 
contract StandardToken is
    IERC20Token,
    BasicToken,
    IERC677Token
{

     
     
     

    mapping (address => mapping (address => uint256)) private _allowed;

     
     
     

     
     
     

     
    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool)
    {
         
        var allowance = _allowed[from][msg.sender];
        _allowed[from][msg.sender] = sub(allowance, amount);
         
        transferInternal(from, to, amount);
        return true;
    }

     
    function approve(address spender, uint256 amount)
        public
        returns (bool)
    {

         
         
         
         
        require((amount == 0) || (_allowed[msg.sender][spender] == 0));

        _allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

     
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256 remaining)
    {
        return _allowed[owner][spender];
    }

     
     
     

    function approveAndCall(
        address spender,
        uint256 amount,
        bytes extraData
    )
        public
        returns (bool)
    {
        require(approve(spender, amount));

         
        bool success = IERC677Callback(spender).receiveApproval(
            msg.sender,
            amount,
            this,
            extraData
        );
        require(success);

        return true;
    }
}

contract EtherToken is
    IsContract,
    AccessControlled,
    StandardToken,
    TokenMetadata,
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

     
     
     

    function EtherToken(IAccessPolicy accessPolicy)
        AccessControlled(accessPolicy)
        StandardToken()
        TokenMetadata(NAME, DECIMALS, SYMBOL, "")
        Reclaimable()
        public
    {
    }

     
     
     

     
    function deposit()
        payable
        public
    {
        _balances[msg.sender] = add(_balances[msg.sender], msg.value);
        _totalSupply = add(_totalSupply, msg.value);
        LogDeposit(msg.sender, msg.value);
        Transfer(address(0), msg.sender, msg.value);
    }

     
    function withdraw(uint256 amount)
        public
    {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = sub(_balances[msg.sender], amount);
        _totalSupply = sub(_totalSupply, amount);
        msg.sender.transfer(amount);
        LogWithdrawal(msg.sender, amount);
        Transfer(msg.sender, address(0), amount);
    }

     
     
     

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool)
    {
        transferInternal(msg.sender, to, amount);

         
        if (isContract(to)) {
             
            IERC223Callback(to).onTokenTransfer(msg.sender, amount, data);
        }
        return true;
    }

     
     
     

     
     
     
    function reclaim(IBasicToken token)
        public
    {
         
        require(token != RECLAIM_ETHER);
        Reclaimable.reclaim(token);
    }
}

 
 
contract IMigrationTarget {

     
     
     

     
    function currentMigrationSource()
        public
        constant
        returns (address);
}

 
 
contract MigrationTarget is
    IMigrationTarget
{
     
     
     

     
    modifier onlyMigrationSource() {
        require(msg.sender == currentMigrationSource());
        _;
    }
}

 
 
 
contract LockedAccountMigration is
    MigrationTarget
{
     
     
     

     
    function migrateInvestor(
        address investor,
        uint256 balance,
        uint256 neumarksDue,
        uint256 unlockDate
    )
        public
        onlyMigrationSource();
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

     
     
     

    function MigrationSource(
        IAccessPolicy policy,
        bytes32 migrationAdminRole
    )
        AccessControlled(policy)
        internal
    {
        MIGRATION_ADMIN = migrationAdminRole;
    }

     
     
     

     
     
    function migrate()
        onlyMigrationEnabled()
        public;

     
     
    function enableMigration(IMigrationTarget migration)
        public
        onlyMigrationEnabledOnce()
        only(MIGRATION_ADMIN)
    {
         
        require(migration.currentMigrationSource() == address(this));
        _migration = migration;
        LogMigrationEnabled(_migration);
    }

     
    function currentMigrationTarget()
        public
        constant
        returns (IMigrationTarget)
    {
        return _migration;
    }
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

 
contract Agreement is
    AccessControlled,
    AccessRoles
{

     
     
     

     
    struct SignedAgreement {
        address platformOperatorRepresentative;
        uint256 signedBlockTimestamp;
        string agreementUri;
    }

     
     
     

    IEthereumForkArbiter private ETHEREUM_FORK_ARBITER;

     
     
     

     
    SignedAgreement[] private _amendments;

     
    mapping(address => uint256) private _signatories;

     
     
     

    event LogAgreementAccepted(
        address indexed accepter
    );

    event LogAgreementAmended(
        address platformOperatorRepresentative,
        string agreementUri
    );

     
     
     

     
     
    modifier acceptAgreement(address accepter) {
        if(_signatories[accepter] == 0) {
            require(_amendments.length > 0);
            _signatories[accepter] = block.number;
            LogAgreementAccepted(accepter);
        }
        _;
    }

     
     
     

    function Agreement(IAccessPolicy accessPolicy, IEthereumForkArbiter forkArbiter)
        AccessControlled(accessPolicy)
        internal
    {
        require(forkArbiter != IEthereumForkArbiter(0x0));
        ETHEREUM_FORK_ARBITER = forkArbiter;
    }

     
     
     

    function amendAgreement(string agreementUri)
        public
        only(ROLE_PLATFORM_OPERATOR_REPRESENTATIVE)
    {
        SignedAgreement memory amendment = SignedAgreement({
            platformOperatorRepresentative: msg.sender,
            signedBlockTimestamp: block.timestamp,
            agreementUri: agreementUri
        });
        _amendments.push(amendment);
        LogAgreementAmended(msg.sender, agreementUri);
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
            address platformOperatorRepresentative,
            uint256 signedBlockTimestamp,
            string agreementUri,
            uint256 index
        )
    {
        require(_amendments.length > 0);
        uint256 last = _amendments.length - 1;
        SignedAgreement storage amendment = _amendments[last];
        return (
            amendment.platformOperatorRepresentative,
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
            address platformOperatorRepresentative,
            uint256 signedBlockTimestamp,
            string agreementUri,
            uint256 index
        )
    {
        SignedAgreement storage amendment = _amendments[amendmentIndex];
        return (
            amendment.platformOperatorRepresentative,
            amendment.signedBlockTimestamp,
            amendment.agreementUri,
            amendmentIndex
        );
    }

    function agreementSignedAtBlock(address signatory)
        public
        constant
        returns (uint256)
    {
        return _signatories[signatory];
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
        constant
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
        constant
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
        constant
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
        constant
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
        constant
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
        constant
        returns (uint256)
    {
        return NEUMARK_CAP;
    }

    function initialRewardFraction()
        public
        constant
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

     
     
     

     
     
     
     
     
     
    function mCurrentSnapshotId()
        internal
        returns (uint256);
}

 
 
contract DailyAndSnapshotable is
    MSnapshotPolicy,
    ISnapshotable
{
     
     
     

     
    uint256 private MAX_TIMESTAMP = 3938453320844195178974243141571391;

     
     
     

    uint256 private _currentSnapshotId;

     
     
     

     
     
    function DailyAndSnapshotable(uint256 start) internal {
         
        if (start > 0) {
            uint256 dayBase = snapshotAt(block.timestamp);
            require(start >= dayBase);
             
            require(start < dayBase + 2**128);
            _currentSnapshotId = start;
        }
    }

     
     
     

    function snapshotAt(uint256 timestamp)
        public
        constant
        returns (uint256)
    {
        require(timestamp < MAX_TIMESTAMP);

        uint256 dayBase = 2**128 * (timestamp / 1 days);
        return dayBase;
    }

     
     
     

    function createSnapshot()
        public
        returns (uint256)
    {
        uint256 dayBase = 2**128 * (block.timestamp / 1 days);

        if (dayBase > _currentSnapshotId) {
             
            _currentSnapshotId = dayBase;
        } else {
             
            _currentSnapshotId += 1;
        }

         
        LogSnapshotCreated(_currentSnapshotId);
        return _currentSnapshotId;
    }

    function currentSnapshotId()
        public
        constant
        returns (uint256)
    {
        return mCurrentSnapshotId();
    }

     
     
     

     
     
     

    function mCurrentSnapshotId()
        internal
        returns (uint256)
    {
        uint256 dayBase = 2**128 * (block.timestamp / 1 days);

         
        if (dayBase > _currentSnapshotId) {
            _currentSnapshotId = dayBase;
            LogSnapshotCreated(dayBase);
        }

        return _currentSnapshotId;
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

 
 
 
 
 
contract TokenAllowance is
    MTokenTransfer,
    MTokenAllowanceController,
    IERC20Allowance,
    IERC677Token
{

     
     
     

     
    mapping (address => mapping (address => uint256)) private _allowed;

     
     
     

    function TokenAllowance()
        internal
    {
    }

     
     
     

     
     
     

     
     
     
     
     
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256 remaining)
    {
        return _allowed[owner][spender];
    }

     
     
     
     
     
     
    function approve(address spender, uint256 amount)
        public
        returns (bool success)
    {
         
        require(mOnApprove(msg.sender, spender, amount));

         
         
         
         
        require((amount == 0) || (_allowed[msg.sender][spender] == 0));

        _allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool success)
    {
         
        bool amountApproved = _allowed[from][msg.sender] >= amount;
        require(amountApproved);

        _allowed[from][msg.sender] -= amount;
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
         

        uint256 currentSnapshotId = mCurrentSnapshotId();
         
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
    IBasicToken,
    IClonedTokenParent,
    Snapshot
{
     
     
     

     
     
    IClonedTokenParent private PARENT_TOKEN;

     
     
    uint256 private PARENT_SNAPSHOT_ID;

     
     
     

     
     
     
    mapping (address => Values[]) internal _balances;

     
    Values[] internal _totalSupplyValues;

     
     
     

     
     
     
     
     
     
     
     
    function BasicSnapshotToken(
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
        public
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

         
         
        var previousBalanceFrom = balanceOf(from);
        require(previousBalanceFrom >= amount);

         
         
        uint256 newBalanceFrom = previousBalanceFrom - amount;
        setValue(_balances[from], newBalanceFrom);

         
         
        uint256 previousBalanceTo = balanceOf(to);
        uint256 newBalanceTo = previousBalanceTo + amount;
        assert(newBalanceTo >= previousBalanceTo);  
        setValue(_balances[to], newBalanceTo);

         
        Transfer(from, to, amount);
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

     
     
     

     
     
     
    function MintableSnapshotToken(
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

        Transfer(0, owner, amount);
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

        Transfer(owner, 0, amount);
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract StandardSnapshotToken is
    IERC20Token,
    MintableSnapshotToken,
    TokenAllowance,
    IERC223Token,
    IsContract
{
     
     
     

     
     
     
     
     
    function StandardSnapshotToken(
        IClonedTokenParent parentToken,
        uint256 parentSnapshotId
    )
        MintableSnapshotToken(parentToken, parentSnapshotId)
        TokenAllowance()
        internal
    {}

     
     
     

     
     
     

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool)
    {
         
        BasicSnapshotToken.mTransfer(msg.sender, to, amount);

         
        if (isContract(to)) {
            IERC223Callback(to).onTokenTransfer(msg.sender, amount, data);
        }
        return true;
    }
}

contract Neumark is
    AccessControlled,
    AccessRoles,
    Agreement,
    DailyAndSnapshotable,
    StandardSnapshotToken,
    TokenMetadata,
    NeumarkIssuanceCurve,
    Reclaimable
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

     
     
     

    function Neumark(
        IAccessPolicy accessPolicy,
        IEthereumForkArbiter forkArbiter
    )
        AccessControlled(accessPolicy)
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
        LogNeumarksIssued(msg.sender, euroUlps, neumarkUlps);
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
        LogNeumarksBurned(msg.sender, euroUlps, burnNeumarkUlps);
    }
}

contract TimeSource {

     
     
     

    function currentTime() internal constant returns (uint256) {
        return block.timestamp;
    }
}

contract LockedAccount is
    AccessControlled,
    AccessRoles,
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

     
     
     

     
     
     
     
     
     
     
     
     
     
    function LockedAccount(
        IAccessPolicy policy,
        IERC677Token assetToken,
        Neumark neumark,
        address penaltyDisbursalAddress,
        uint256 lockPeriod,
        uint256 penaltyFraction
    )
        AccessControlled(policy)
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
        LogFundsLocked(investor, amount, neumarks);
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
        LockedAccountMigration(_migration).migrateInvestor(
            msg.sender,
            account.balance,
            account.neumarksDue,
            account.unlockDate
        );
        LogInvestorMigrated(msg.sender, account.balance, account.neumarksDue, account.unlockDate);
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
        LogLockStateTransition(_lockState, newState);
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
                        ASSET_TOKEN.approveAndCall(_penaltyDisbursalAddress,penalty, "")
                    );
                } else {
                     
                    assert(ASSET_TOKEN.transfer(_penaltyDisbursalAddress, penalty));
                }
                LogPenaltyDisbursed(_penaltyDisbursalAddress, penalty, ASSET_TOKEN, investor);
                accountInMem.balance -= penalty;
            }
        }
        if (_lockState == LockState.ReleaseAll) {
            accountInMem.neumarksDue = 0;
        }
         
        assert(ASSET_TOKEN.transfer(investor, accountInMem.balance));
        LogFundsUnlocked(investor, accountInMem.balance, accountInMem.neumarksDue);
    }
}