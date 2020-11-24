 

pragma solidity 0.4.25;

 
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