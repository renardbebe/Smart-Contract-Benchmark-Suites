 

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

 
 
 
 
 
 
contract IContractId {
     
     
    function contractId() public pure returns (bytes32 id, uint256 version);
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

contract IGasExchange {

     
     
     

     
     
    event LogGasExchange(
        address indexed gasRecipient,
        uint256 amountEurUlps,
        uint256 exchangeFeeFrac,
        uint256 amountWei,
        uint256 rate
    );

    event LogSetExchangeRate(
        address indexed numeratorToken,
        address indexed denominatorToken,
        uint256 rate
    );

    event LogReceivedEther(
        address sender,
        uint256 amount,
        uint256 balance
    );

     
     
     

     
     
     
     
     
    function gasExchange(address gasRecipient, uint256 amountEurUlps, uint256 exchangeFeeFraction)
        public;

     
    function gasExchangeMultiple(address[] gasRecipients, uint256[] amountsEurUlps, uint256 exchangeFeeFraction)
        public;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function setExchangeRate(IERC223Token numeratorToken, IERC223Token denominatorToken, uint256 rateFraction)
        public;

     
     
    function setExchangeRates(IERC223Token[] numeratorTokens, IERC223Token[] denominatorTokens, uint256[] rateFractions)
        public;
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

 
 
contract SimpleExchange is
    ITokenExchangeRateOracle,
    IGasExchange,
    IContractId,
    Reclaimable,
    Math
{
     
     
     

    struct TokenRate {
         
        uint128 rateFraction;
         
        uint128 timestamp;
    }

     
     
     

     
    IERC223Token private ETHER_TOKEN;
     
    IERC223Token private EURO_TOKEN;

     
     
     

     
    mapping (address => mapping (address => TokenRate)) private _rates;

     
     
     

    constructor(
        IAccessPolicy accessPolicy,
        IERC223Token euroToken,
        IERC223Token etherToken
    )
        AccessControlled(accessPolicy)
        Reclaimable()
        public
    {
        EURO_TOKEN = euroToken;
        ETHER_TOKEN = etherToken;
    }

     
     
     

     
     
     

    function gasExchange(address gasRecipient, uint256 amountEurUlps, uint256 exchangeFeeFraction)
        public
        only(ROLE_GAS_EXCHANGE)
    {
         
        assert(exchangeFeeFraction < 10**18);
        (uint256 rate, uint256 rateTimestamp) = getExchangeRatePrivate(EURO_TOKEN, ETHER_TOKEN);
         
        require(block.timestamp - rateTimestamp < 1 hours, "NF_SEX_OLD_RATE");
        gasExchangePrivate(gasRecipient, amountEurUlps, exchangeFeeFraction, rate);
    }

    function gasExchangeMultiple(
        address[] gasRecipients,
        uint256[] amountsEurUlps,
        uint256 exchangeFeeFraction
    )
        public
        only(ROLE_GAS_EXCHANGE)
    {
         
        assert(exchangeFeeFraction < 10**18);
        require(gasRecipients.length == amountsEurUlps.length);
        (uint256 rate, uint256 rateTimestamp) = getExchangeRatePrivate(EURO_TOKEN, ETHER_TOKEN);
         
        require(block.timestamp - rateTimestamp < 1 hours, "NF_SEX_OLD_RATE");
        uint256 idx;
        while(idx < gasRecipients.length) {
            gasExchangePrivate(gasRecipients[idx], amountsEurUlps[idx], exchangeFeeFraction, rate);
            idx += 1;
        }
    }

     
     
    function setExchangeRate(IERC223Token numeratorToken, IERC223Token denominatorToken, uint256 rateFraction)
        public
        only(ROLE_TOKEN_RATE_ORACLE)
    {
        setExchangeRatePrivate(numeratorToken, denominatorToken, rateFraction);
    }

    function setExchangeRates(IERC223Token[] numeratorTokens, IERC223Token[] denominatorTokens, uint256[] rateFractions)
        public
        only(ROLE_TOKEN_RATE_ORACLE)
    {
        require(numeratorTokens.length == denominatorTokens.length);
        require(numeratorTokens.length == rateFractions.length);
        for(uint256 idx = 0; idx < numeratorTokens.length; idx++) {
            setExchangeRatePrivate(numeratorTokens[idx], denominatorTokens[idx], rateFractions[idx]);
        }
    }

     
     
     

    function getExchangeRate(address numeratorToken, address denominatorToken)
        public
        constant
        returns (uint256 rateFraction, uint256 timestamp)
    {
        return getExchangeRatePrivate(numeratorToken, denominatorToken);
    }

    function getExchangeRates(address[] numeratorTokens, address[] denominatorTokens)
        public
        constant
        returns (uint256[] rateFractions, uint256[] timestamps)
    {
        require(numeratorTokens.length == denominatorTokens.length);
        uint256 idx;
        rateFractions = new uint256[](numeratorTokens.length);
        timestamps = new uint256[](denominatorTokens.length);
        while(idx < numeratorTokens.length) {
            (uint256 rate, uint256 timestamp) = getExchangeRatePrivate(numeratorTokens[idx], denominatorTokens[idx]);
            rateFractions[idx] = rate;
            timestamps[idx] = timestamp;
            idx += 1;
        }
    }

     
     
     

    function contractId() public pure returns (bytes32 id, uint256 version) {
        return (0x434a1a753d1d39381c462f37c155e520ae6f86ad79289abca9cde354a0cebd68, 0);
    }

     
     
     

    function () external payable {
        emit LogReceivedEther(msg.sender, msg.value, address(this).balance);
    }

     
     
     

    function gasExchangePrivate(
        address gasRecipient,
        uint256 amountEurUlps,
        uint256 exchangeFeeFraction,
        uint256 rate
    )
        private
    {
         
        uint256 amountEthWei = decimalFraction(amountEurUlps - decimalFraction(amountEurUlps, exchangeFeeFraction), rate);
         
        assert(EURO_TOKEN.transferFrom(gasRecipient, this, amountEurUlps));
         
        gasRecipient.transfer(amountEthWei);

        emit LogGasExchange(gasRecipient, amountEurUlps, exchangeFeeFraction, amountEthWei, rate);
    }

    function getExchangeRatePrivate(address numeratorToken, address denominatorToken)
        private
        constant
        returns (uint256 rateFraction, uint256 timestamp)
    {
        TokenRate storage requested_rate = _rates[numeratorToken][denominatorToken];
        TokenRate storage inversed_requested_rate = _rates[denominatorToken][numeratorToken];
        if (requested_rate.timestamp > 0) {
            return (requested_rate.rateFraction, requested_rate.timestamp);
        }
        else if (inversed_requested_rate.timestamp > 0) {
            uint256 invRateFraction = proportion(10**18, 10**18, inversed_requested_rate.rateFraction);
            return (invRateFraction, inversed_requested_rate.timestamp);
        }
         
    }

    function setExchangeRatePrivate(
        IERC223Token numeratorToken,
        IERC223Token denominatorToken,
        uint256 rateFraction
    )
        private
    {
        require(numeratorToken != denominatorToken, "NF_SEX_SAME_N_D");
        assert(rateFraction > 0);
        assert(rateFraction < 2**128);
        uint256 invRateFraction = proportion(10**18, 10**18, rateFraction);

         
         
        require(denominatorToken.decimals() == numeratorToken.decimals(), "NF_SEX_DECIMALS");
         

        if (_rates[denominatorToken][numeratorToken].timestamp > 0) {
            _rates[denominatorToken][numeratorToken] = TokenRate({
                rateFraction: uint128(invRateFraction),
                timestamp: uint128(block.timestamp)
            });
        }
        else {
            _rates[numeratorToken][denominatorToken] = TokenRate({
                rateFraction: uint128(rateFraction),
                timestamp: uint128(block.timestamp)
            });
        }

        emit LogSetExchangeRate(numeratorToken, denominatorToken, rateFraction);
        emit LogSetExchangeRate(denominatorToken, numeratorToken, invRateFraction);
    }
}