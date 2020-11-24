 

pragma solidity 0.4.25;

 
 
contract ERC223LegacyCallbackCompat {

     
     
     

    function onTokenTransfer(address wallet, uint256 amount, bytes data)
        public
    {
        tokenFallback(wallet, amount, data);
    }

    function tokenFallback(address wallet, uint256 amount, bytes data)
        public;

}

 
 
 
contract KnownContracts {

     
     
     

     
    bytes32 internal constant FEE_DISBURSAL_CONTROLLER = 0xfc72936b568fd5fc632b76e8feac0b717b4db1fce26a1b3b623b7fb6149bd8ae;

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

     
    bytes4 internal constant KNOWN_INTERFACE_PAYMENT_TOKEN = 0xb2a0042a;
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

     
    bytes32 internal constant ROLE_DISBURSER = 0xd7ea6093d11d866c9e8449f8bffd9da1387c530ee40ad54f0641425bb0ca33b7;

     
    bytes32 internal constant ROLE_DISBURSAL_MANAGER = 0x677f87f7b7ef7c97e42a7e6c85c295cf020c9f11eea1e49f6bf847d7aeae1475;

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

 
 
 
contract IERC223Callback {

     
     
     

    function tokenFallback(address from, uint256 amount, bytes data)
        public;

}

contract IERC223Token is IERC20Token, ITokenMetadata {

     
     
     

     
     
     
     
     


     
     

     
     
     

     
     
     

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool);
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

 
contract PlatformTerms is Math, IContractId {

     
     
     

     
    uint256 public constant PLATFORM_FEE_FRACTION = 3 * 10**16;
     
    uint256 public constant TOKEN_PARTICIPATION_FEE_FRACTION = 2 * 10**16;
     
     
     
    uint256 public constant PLATFORM_NEUMARK_SHARE = 2;  
     
    bool public constant IS_ICBM_INVESTOR_WHITELISTED = true;

     
    uint256 public constant MIN_TICKET_EUR_ULPS = 100 * 10**18;
     
     
     

     
    uint256 public constant DATE_TO_WHITELIST_MIN_DURATION = 7 days;
     
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
        return (0x95482babc4e32de6c4dc3910ee7ae62c8e427efde6bc4e9ce0d6d93e24c39323, 1);
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

 
 
contract IERC223LegacyCallback {

     
     
     

    function onTokenTransfer(address from, uint256 amount, bytes data)
        public;

}

 
 
contract IFeeDisbursal is IERC223Callback {
     
    function claim() public;

    function recycle() public;
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

 
contract FeeDisbursal is
    IERC223Callback,
    IERC677Callback,
    IERC223LegacyCallback,
    ERC223LegacyCallbackCompat,
    Serialization,
    Math,
    KnownContracts,
    KnownInterfaces,
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

     
     
     
    uint256 constant UINT256_MAX = 2**256 - 1;


     
     
     
    Universe private UNIVERSE;

     
    address private ICBM_ETHER_TOKEN;

     
     
     

     
    IFeeDisbursalController private _feeDisbursalController;
     
    mapping (address => mapping(address => Disbursal[])) private _disbursals;
     
     
    mapping (address => mapping(address => mapping(address => uint256))) _disbursalProgress;


     
     
     
    constructor(Universe universe, IFeeDisbursalController controller)
        public
    {
        require(universe != address(0x0));
        (bytes32 controllerContractId, ) = controller.contractId();
        require(controllerContractId == FEE_DISBURSAL_CONTROLLER);
        UNIVERSE = universe;
        ICBM_ETHER_TOKEN = universe.getSingleton(KNOWN_INTERFACE_ICBM_ETHER_TOKEN);
        _feeDisbursalController = controller;
    }

     
     
     

     
     
     
     
    function getDisbursal(address token, address proRataToken, uint256 index)
        public
        constant
    returns (
        uint256 snapshotId,
        uint256 amount,
        uint256 recycleableAfterTimestamp,
        uint256 disburseTimestamp,
        address disburser
    )
    {
        Disbursal storage disbursal = _disbursals[token][proRataToken][index];
        snapshotId = disbursal.snapshotId;
        amount = disbursal.amount;
        recycleableAfterTimestamp = disbursal.recycleableAfterTimestamp;
        disburseTimestamp = disbursal.disbursalTimestamp;
        disburser = disbursal.disburser;
    }

     
     
     
     
    function getNonClaimableDisbursals(address token, address proRataToken)
        public
        constant
    returns (uint256[3][] memory disbursals)
    {
        uint256 len = _disbursals[token][proRataToken].length;
        if (len == 0) {
            return;
        }
         
        uint256 snapshotId = ITokenSnapshots(proRataToken).currentSnapshotId();
        uint256 ii = len;
        while(_disbursals[token][proRataToken][ii-1].snapshotId == snapshotId && --ii > 0) {}
        disbursals = new uint256[3][](len-ii);
        for(uint256 jj = 0; jj < len - ii; jj += 1) {
            disbursals[jj][0] = snapshotId;
            disbursals[jj][1] = _disbursals[token][proRataToken][ii+jj].amount;
            disbursals[jj][2] = ii+jj;
        }
    }

     
     
     
    function getDisbursalCount(address token, address proRataToken)
        public
        constant
        returns (uint256)
    {
        return _disbursals[token][proRataToken].length;
    }

     
     
     
     
    function accept(address token, ITokenSnapshots proRataToken, uint256 until)
        public
    {
         
        require(_feeDisbursalController.onAccept(token, proRataToken, msg.sender), "NF_ACCEPT_REJECTED");
        (uint256 claimedAmount, , uint256 nextIndex) = claimPrivate(token, proRataToken, msg.sender, until);

         
        if (claimedAmount > 0) {
            IERC223Token ierc223Token = IERC223Token(token);
            assert(ierc223Token.transfer(msg.sender, claimedAmount, ""));
        }
         
        emit LogDisbursalAccepted(msg.sender, token, proRataToken, claimedAmount, nextIndex);
    }

     
     
     
    function acceptMultipleByToken(address[] tokens, ITokenSnapshots proRataToken)
        public
    {
        uint256[2][] memory claimed = new uint256[2][](tokens.length);
         
        uint256 i;
        for (i = 0; i < tokens.length; i += 1) {
             
            require(_feeDisbursalController.onAccept(tokens[i], proRataToken, msg.sender), "NF_ACCEPT_REJECTED");
            (claimed[i][0], ,claimed[i][1]) = claimPrivate(tokens[i], proRataToken, msg.sender, UINT256_MAX);
        }
         
        for (i = 0; i < tokens.length; i += 1) {
            if (claimed[i][0] > 0) {
                 
                IERC223Token ierc223Token = IERC223Token(tokens[i]);
                assert(ierc223Token.transfer(msg.sender, claimed[i][0], ""));
            }
             
            emit LogDisbursalAccepted(msg.sender, tokens[i], proRataToken, claimed[i][0], claimed[i][1]);
        }
    }

     
     
     
     
    function acceptMultipleByProRataToken(address token, ITokenSnapshots[] proRataTokens)
        public
    {
        uint256 i;
        uint256 fullAmount;
        for (i = 0; i < proRataTokens.length; i += 1) {
            require(_feeDisbursalController.onAccept(token, proRataTokens[i], msg.sender), "NF_ACCEPT_REJECTED");
            (uint256 amount, , uint256 nextIndex) = claimPrivate(token, proRataTokens[i], msg.sender, UINT256_MAX);
            fullAmount += amount;
             
            emit LogDisbursalAccepted(msg.sender, token, proRataTokens[i], amount, nextIndex);
        }
        if (fullAmount > 0) {
             
            IERC223Token ierc223Token = IERC223Token(token);
            assert(ierc223Token.transfer(msg.sender, fullAmount, ""));
        }
    }

     
     
     
     
    function reject(address token, ITokenSnapshots proRataToken, uint256 until)
        public
    {
         
        require(_feeDisbursalController.onReject(token, address(0), msg.sender), "NF_REJECT_REJECTED");
        (uint256 claimedAmount, , uint256 nextIndex) = claimPrivate(token, proRataToken, msg.sender, until);
         
        if (claimedAmount > 0) {
            PlatformTerms terms = PlatformTerms(UNIVERSE.platformTerms());
            disburse(token, this, claimedAmount, proRataToken, terms.DEFAULT_DISBURSAL_RECYCLE_AFTER_DURATION());
        }
         
        emit LogDisbursalRejected(msg.sender, token, proRataToken, claimedAmount, nextIndex);
    }

     
     
     
     
     
     
    function claimable(address token, ITokenSnapshots proRataToken, address claimer, uint256 until)
        public
        constant
    returns (uint256 claimableAmount, uint256 totalAmount, uint256 recycleableAfterTimestamp, uint256 firstIndex)
    {
        firstIndex = _disbursalProgress[token][proRataToken][claimer];
        if (firstIndex < _disbursals[token][proRataToken].length) {
            recycleableAfterTimestamp = _disbursals[token][proRataToken][firstIndex].recycleableAfterTimestamp;
        }
         
        (claimableAmount, totalAmount,) = claimablePrivate(token, proRataToken, claimer, until, false);
    }

     
     
     
     
     
     
    function claimableMutipleByToken(address[] tokens, ITokenSnapshots proRataToken, address claimer)
        public
        constant
    returns (uint256[4][] claimables)
    {
        claimables = new uint256[4][](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            claimables[i][3] = _disbursalProgress[tokens[i]][proRataToken][claimer];
            if (claimables[i][3] < _disbursals[tokens[i]][proRataToken].length) {
                claimables[i][2] = _disbursals[tokens[i]][proRataToken][claimables[i][3]].recycleableAfterTimestamp;
            }
            (claimables[i][0], claimables[i][1], ) = claimablePrivate(tokens[i], proRataToken, claimer, UINT256_MAX, false);
        }
    }

     
     
     
     
     
    function claimableMutipleByProRataToken(address token, ITokenSnapshots[] proRataTokens, address claimer)
        public
        constant
    returns (uint256[4][] claimables)
    {
        claimables = new uint256[4][](proRataTokens.length);
        for (uint256 i = 0; i < proRataTokens.length; i += 1) {
            claimables[i][3] = _disbursalProgress[token][proRataTokens[i]][claimer];
            if (claimables[i][3] < _disbursals[token][proRataTokens[i]].length) {
                claimables[i][2] = _disbursals[token][proRataTokens[i]][claimables[i][3]].recycleableAfterTimestamp;
            }
            (claimables[i][0], claimables[i][1], ) = claimablePrivate(token, proRataTokens[i], claimer, UINT256_MAX, false);
        }
    }

     
     
     
     
     
    function recycle(address token, ITokenSnapshots proRataToken, address[] investors, uint256 until)
        public
    {
        require(_feeDisbursalController.onRecycle(token, proRataToken, investors, until), "");
         
         
        uint256 totalClaimableAmount = 0;
        for (uint256 i = 0; i < investors.length; i += 1) {
            (uint256 claimableAmount, ,uint256 nextIndex) = claimablePrivate(token, ITokenSnapshots(proRataToken), investors[i], until, true);
            totalClaimableAmount += claimableAmount;
            _disbursalProgress[token][proRataToken][investors[i]] = nextIndex;
        }

         
        if (totalClaimableAmount > 0) {
             
            PlatformTerms terms = PlatformTerms(UNIVERSE.platformTerms());
            disburse(token, this, totalClaimableAmount, proRataToken, terms.DEFAULT_DISBURSAL_RECYCLE_AFTER_DURATION());
        }

         
        emit LogFundsRecycled(proRataToken, token, totalClaimableAmount, msg.sender);
    }

     
     
     
     
     
    function recycleable(address token, ITokenSnapshots proRataToken, address[] investors, uint256 until)
        public
        constant
    returns (uint256)
    {
         
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < investors.length; i += 1) {
            (uint256 claimableAmount,,) = claimablePrivate(token, proRataToken, investors[i], until, true);
            totalAmount += claimableAmount;
        }
        return totalAmount;
    }

     
    function feeDisbursalController()
        public
        constant
        returns (IFeeDisbursalController)
    {
        return _feeDisbursalController;
    }

     
    function changeFeeDisbursalController(IFeeDisbursalController newController)
        public
    {
        require(_feeDisbursalController.onChangeFeeDisbursalController(msg.sender, newController), "NF_CHANGING_CONTROLLER_REJECTED");
        address oldController = address(_feeDisbursalController);
        _feeDisbursalController = newController;
        emit LogChangeFeeDisbursalController(oldController, address(newController), msg.sender);
    }

     

    function tokenFallback(address wallet, uint256 amount, bytes data)
        public
    {
        tokenFallbackPrivate(msg.sender, wallet, amount, data);
    }

     
    function receiveApproval(address from, uint256 amount, address tokenAddress, bytes data)
        public
        returns (bool success)
    {
         
        require(msg.sender == tokenAddress);
         
        IERC20Token token = IERC20Token(tokenAddress);
         
        require(token.transferFrom(from, address(this), amount));

         
         
        if (tokenAddress == ICBM_ETHER_TOKEN) {
             
            IWithdrawableToken(tokenAddress).withdraw(amount);
            token = IERC20Token(UNIVERSE.etherToken());
            EtherToken(token).deposit.value(amount)();
        }
        if(tokenAddress == UNIVERSE.getSingleton(KNOWN_INTERFACE_ICBM_EURO_TOKEN)) {
            IWithdrawableToken(tokenAddress).withdraw(amount);
            token = IERC20Token(UNIVERSE.euroToken());
             
            EuroToken(token).deposit(this, amount, 0x0);
        }
        tokenFallbackPrivate(address(token), from, amount, data);
        return true;
    }

     
     
     

    function contractId()
        public
        pure
        returns (bytes32 id, uint256 version)
    {
        return (0x2e1a7e4ac88445368dddb31fe43d29638868837724e9be8ffd156f21a971a4d7, 0);
    }

     
     
     
    function ()
        public
        payable
    {
        require(msg.sender == ICBM_ETHER_TOKEN);
    }


     
     
     

    function tokenFallbackPrivate(address token, address wallet, uint256 amount, bytes data)
        private
    {
        ITokenSnapshots proRataToken;
        PlatformTerms terms = PlatformTerms(UNIVERSE.platformTerms());
        uint256 recycleAfterDuration = terms.DEFAULT_DISBURSAL_RECYCLE_AFTER_DURATION();
        if (data.length == 20) {
            proRataToken = ITokenSnapshots(decodeAddress(data));
        }
        else if (data.length == 52) {
            address proRataTokenAddress;
            (proRataTokenAddress, recycleAfterDuration) = decodeAddressUInt256(data);
            proRataToken = ITokenSnapshots(proRataTokenAddress);
        } else {
             
            proRataToken = UNIVERSE.neumark();
        }
        disburse(token, wallet, amount, proRataToken, recycleAfterDuration);
    }

     
     
     
     
     
    function disburse(address token, address disburser, uint256 amount, ITokenSnapshots proRataToken, uint256 recycleAfterDuration)
        private
    {
        require(
            _feeDisbursalController.onDisburse(token, disburser, amount, address(proRataToken), recycleAfterDuration), "NF_DISBURSAL_REJECTED");

        uint256 snapshotId = proRataToken.currentSnapshotId();
        uint256 proRataTokenTotalSupply = proRataToken.totalSupplyAt(snapshotId);
         
        if (token == address(proRataToken)) {
            proRataTokenTotalSupply -= proRataToken.balanceOfAt(address(this), snapshotId);
        }
        require(proRataTokenTotalSupply > 0, "NF_NO_DISBURSE_EMPTY_TOKEN");
        uint256 recycleAfter = add(block.timestamp, recycleAfterDuration);
        assert(recycleAfter<2**128);

        Disbursal[] storage disbursals = _disbursals[token][proRataToken];
         
        bool merged = false;
        for ( uint256 i = disbursals.length - 1; i != UINT256_MAX; i-- ) {
             
             
            Disbursal storage disbursal = disbursals[i];
            if ( disbursal.snapshotId < snapshotId) {
                break;
            }
             
             
            if ( disbursal.disburser == disburser ) {
                merged = true;
                disbursal.amount += amount;
                disbursal.recycleableAfterTimestamp = uint128(recycleAfter);
                disbursal.disbursalTimestamp = uint128(block.timestamp);
                break;
            }
        }

         
        if (!merged) {
            disbursals.push(Disbursal({
                recycleableAfterTimestamp: uint128(recycleAfter),
                disbursalTimestamp: uint128(block.timestamp),
                amount: amount,
                snapshotId: snapshotId,
                disburser: disburser
            }));
        }
        emit LogDisbursalCreated(proRataToken, token, amount, recycleAfterDuration, disburser, merged ? i : disbursals.length - 1);
    }


     
     
     
     
    function claimPrivate(address token, ITokenSnapshots proRataToken, address claimer, uint256 until)
        private
    returns (uint256 claimedAmount, uint256 totalAmount, uint256 nextIndex)
    {
        (claimedAmount, totalAmount, nextIndex) = claimablePrivate(token, proRataToken, claimer, until, false);

         
        _disbursalProgress[token][proRataToken][claimer] = nextIndex;
    }

     
     
     
     
     
     
    function claimablePrivate(address token, ITokenSnapshots proRataToken, address claimer, uint256 until, bool onlyRecycleable)
        private
        constant
        returns (uint256 claimableAmount, uint256 totalAmount, uint256 nextIndex)
    {
        nextIndex = min(until, _disbursals[token][proRataToken].length);
        uint256 currentIndex = _disbursalProgress[token][proRataToken][claimer];
        uint256 currentSnapshotId = proRataToken.currentSnapshotId();
        for (; currentIndex < nextIndex; currentIndex += 1) {
            Disbursal storage disbursal = _disbursals[token][proRataToken][currentIndex];
            uint256 snapshotId = disbursal.snapshotId;
             
            if ( snapshotId == currentSnapshotId )
                break;
             
             
             
            if ( onlyRecycleable && disbursal.recycleableAfterTimestamp > block.timestamp )
                break;
             
            totalAmount += disbursal.amount;
             
            claimableAmount += calculateClaimableAmount(claimer, disbursal.amount, token, proRataToken, snapshotId);
        }
        return (claimableAmount, totalAmount, currentIndex);
    }

    function calculateClaimableAmount(address claimer, uint256 disbursalAmount, address token, ITokenSnapshots proRataToken, uint256 snapshotId)
        private
        constant
        returns (uint256)
    {
        uint256 proRataClaimerBalance = proRataToken.balanceOfAt(claimer, snapshotId);
         
        if (proRataClaimerBalance == 0) {
            return 0;
        }
         
        uint256 proRataTokenTotalSupply = proRataToken.totalSupplyAt(snapshotId);
         
        if (token == address(proRataToken)) {
            proRataTokenTotalSupply -= proRataToken.balanceOfAt(address(this), snapshotId);
        }
         
         
         
         
         
        return mul(disbursalAmount, proRataClaimerBalance) / proRataTokenTotalSupply;
    }
}