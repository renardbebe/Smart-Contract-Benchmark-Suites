 

pragma solidity 0.4.24;
pragma experimental "v0.5.0";

 

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

 

 
library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract AccessControlledBase {
     

    mapping (address => bool) public authorized;

     

    event AccessGranted(
        address who
    );

    event AccessRevoked(
        address who
    );

     

    modifier requiresAuthorization() {
        require(
            authorized[msg.sender],
            "AccessControlledBase#requiresAuthorization: Sender not authorized"
        );
        _;
    }
}

 

 
contract StaticAccessControlled is AccessControlledBase, Ownable {
    using SafeMath for uint256;

     

     
    uint256 public GRACE_PERIOD_EXPIRATION;

     

    constructor(
        uint256 gracePeriod
    )
        public
        Ownable()
    {
        GRACE_PERIOD_EXPIRATION = block.timestamp.add(gracePeriod);
    }

     

    function grantAccess(
        address who
    )
        external
        onlyOwner
    {
        require(
            block.timestamp < GRACE_PERIOD_EXPIRATION,
            "StaticAccessControlled#grantAccess: Cannot grant access after grace period"
        );

        emit AccessGranted(who);
        authorized[who] = true;
    }
}

 

 
interface GeneralERC20 {
    function totalSupply(
    )
        external
        view
        returns (uint256);

    function balanceOf(
        address who
    )
        external
        view
        returns (uint256);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function transfer(
        address to,
        uint256 value
    )
        external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external;

    function approve(
        address spender,
        uint256 value
    )
        external;
}

 

 
library TokenInteract {
    function balanceOf(
        address token,
        address owner
    )
        internal
        view
        returns (uint256)
    {
        return GeneralERC20(token).balanceOf(owner);
    }

    function allowance(
        address token,
        address owner,
        address spender
    )
        internal
        view
        returns (uint256)
    {
        return GeneralERC20(token).allowance(owner, spender);
    }

    function approve(
        address token,
        address spender,
        uint256 amount
    )
        internal
    {
        GeneralERC20(token).approve(spender, amount);

        require(
            checkSuccess(),
            "TokenInteract#approve: Approval failed"
        );
    }

    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        address from = address(this);
        if (
            amount == 0
            || from == to
        ) {
            return;
        }

        GeneralERC20(token).transfer(to, amount);

        require(
            checkSuccess(),
            "TokenInteract#transfer: Transfer failed"
        );
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (
            amount == 0
            || from == to
        ) {
            return;
        }

        GeneralERC20(token).transferFrom(from, to, amount);

        require(
            checkSuccess(),
            "TokenInteract#transferFrom: TransferFrom failed"
        );
    }

     

     
    function checkSuccess(
    )
        private
        pure
        returns (bool)
    {
        uint256 returnValue = 0;

         
        assembly {
             
            switch returndatasize

             
            case 0x0 {
                returnValue := 1
            }

             
            case 0x20 {
                 
                returndatacopy(0x0, 0x0, 0x20)

                 
                returnValue := mload(0x0)
            }

             
            default { }
        }

        return returnValue != 0;
    }
}

 

 
contract TokenProxy is StaticAccessControlled {
    using SafeMath for uint256;

     

    constructor(
        uint256 gracePeriod
    )
        public
        StaticAccessControlled(gracePeriod)
    {}

     

     
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 value
    )
        external
        requiresAuthorization
    {
        TokenInteract.transferFrom(
            token,
            from,
            to,
            value
        );
    }

     

     
    function available(
        address who,
        address token
    )
        external
        view
        returns (uint256)
    {
        return Math.min256(
            TokenInteract.allowance(token, who, address(this)),
            TokenInteract.balanceOf(token, who)
        );
    }
}

 

 
contract Vault is StaticAccessControlled
{
    using SafeMath for uint256;

     

    event ExcessTokensWithdrawn(
        address indexed token,
        address indexed to,
        address caller
    );

     

     
    address public TOKEN_PROXY;

     
     
    mapping (bytes32 => mapping (address => uint256)) public balances;

     
    mapping (address => uint256) public totalBalances;

     

    constructor(
        address proxy,
        uint256 gracePeriod
    )
        public
        StaticAccessControlled(gracePeriod)
    {
        TOKEN_PROXY = proxy;
    }

     

     
    function withdrawExcessToken(
        address token,
        address to
    )
        external
        onlyOwner
        returns (uint256)
    {
        uint256 actualBalance = TokenInteract.balanceOf(token, address(this));
        uint256 accountedBalance = totalBalances[token];
        uint256 withdrawableBalance = actualBalance.sub(accountedBalance);

        require(
            withdrawableBalance != 0,
            "Vault#withdrawExcessToken: Withdrawable token amount must be non-zero"
        );

        TokenInteract.transfer(token, to, withdrawableBalance);

        emit ExcessTokensWithdrawn(token, to, msg.sender);

        return withdrawableBalance;
    }

     

     
    function transferToVault(
        bytes32 id,
        address token,
        address from,
        uint256 amount
    )
        external
        requiresAuthorization
    {
         
        TokenProxy(TOKEN_PROXY).transferTokens(
            token,
            from,
            address(this),
            amount
        );

         
        balances[id][token] = balances[id][token].add(amount);
        totalBalances[token] = totalBalances[token].add(amount);

         
        assert(totalBalances[token] >= balances[id][token]);

        validateBalance(token);
    }

     
    function transferFromVault(
        bytes32 id,
        address token,
        address to,
        uint256 amount
    )
        external
        requiresAuthorization
    {
         
        balances[id][token] = balances[id][token].sub(amount);

         
        totalBalances[token] = totalBalances[token].sub(amount);

         
        assert(totalBalances[token] >= balances[id][token]);

         
        TokenInteract.transfer(token, to, amount);  

         
        validateBalance(token);
    }

     

     
    function validateBalance(
        address token
    )
        private
        view
    {
         
         
        assert(TokenInteract.balanceOf(token, address(this)) >= totalBalances[token]);
    }
}

 

 
contract ReentrancyGuard {
    uint256 private _guardCounter = 1;

    modifier nonReentrant() {
        uint256 localCounter = _guardCounter + 1;
        _guardCounter = localCounter;
        _;
        require(
            _guardCounter == localCounter,
            "Reentrancy check failure"
        );
    }
}

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 
library Fraction {
    struct Fraction128 {
        uint128 num;
        uint128 den;
    }
}

 

 
library FractionMath {
    using SafeMath for uint256;
    using SafeMath for uint128;

     
    function add(
        Fraction.Fraction128 memory a,
        Fraction.Fraction128 memory b
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        uint256 left = a.num.mul(b.den);
        uint256 right = b.num.mul(a.den);
        uint256 denominator = a.den.mul(b.den);

         
        if (left + right < left) {
            left = left.div(2);
            right = right.div(2);
            denominator = denominator.div(2);
        }

        return bound(left.add(right), denominator);
    }

     
    function sub1Over(
        Fraction.Fraction128 memory a,
        uint128 d
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        if (a.den % d == 0) {
            return bound(
                a.num.sub(a.den.div(d)),
                a.den
            );
        }
        return bound(
            a.num.mul(d).sub(a.den),
            a.den.mul(d)
        );
    }

     
    function div(
        Fraction.Fraction128 memory a,
        uint128 d
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        if (a.num % d == 0) {
            return bound(
                a.num.div(d),
                a.den
            );
        }
        return bound(
            a.num,
            a.den.mul(d)
        );
    }

     
    function mul(
        Fraction.Fraction128 memory a,
        Fraction.Fraction128 memory b
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        return bound(
            a.num.mul(b.num),
            a.den.mul(b.den)
        );
    }

     
     
    function bound(
        uint256 num,
        uint256 den
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        uint256 max = num > den ? num : den;
        uint256 first128Bits = (max >> 128);
        if (first128Bits != 0) {
            first128Bits += 1;
            num /= first128Bits;
            den /= first128Bits;
        }

        assert(den != 0);  
        assert(den < 2**128);
        assert(num < 2**128);

        return Fraction.Fraction128({
            num: uint128(num),
            den: uint128(den)
        });
    }

     
    function copy(
        Fraction.Fraction128 memory a
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        validate(a);
        return Fraction.Fraction128({ num: a.num, den: a.den });
    }

     

     
    function validate(
        Fraction.Fraction128 memory a
    )
        private
        pure
    {
        assert(a.den != 0);  
    }
}

 

 
library Exponent {
    using SafeMath for uint256;
    using FractionMath for Fraction.Fraction128;

     

     
    uint128 constant public MAX_NUMERATOR = 340282366920938463463374607431768211455;

     
    uint256 constant public MAX_PRECOMPUTE_PRECISION = 32;

     
    uint256 constant public NUM_PRECOMPUTED_INTEGERS = 32;

     

     
    function exp(
        Fraction.Fraction128 memory X,
        uint256 precomputePrecision,
        uint256 maclaurinPrecision
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        require(
            precomputePrecision <= MAX_PRECOMPUTE_PRECISION,
            "Exponent#exp: Precompute precision over maximum"
        );

        Fraction.Fraction128 memory Xcopy = X.copy();
        if (Xcopy.num == 0) {  
            return ONE();
        }

         
        uint256 integerX = uint256(Xcopy.num).div(Xcopy.den);

         
        if (integerX == 0) {
            return expHybrid(Xcopy, precomputePrecision, maclaurinPrecision);
        }

         
        Fraction.Fraction128 memory expOfInt =
            getPrecomputedEToThe(integerX % NUM_PRECOMPUTED_INTEGERS);
        while (integerX >= NUM_PRECOMPUTED_INTEGERS) {
            expOfInt = expOfInt.mul(getPrecomputedEToThe(NUM_PRECOMPUTED_INTEGERS));
            integerX -= NUM_PRECOMPUTED_INTEGERS;
        }

         
        Fraction.Fraction128 memory decimalX = Fraction.Fraction128({
            num: Xcopy.num % Xcopy.den,
            den: Xcopy.den
        });
        return expHybrid(decimalX, precomputePrecision, maclaurinPrecision).mul(expOfInt);
    }

     
    function expHybrid(
        Fraction.Fraction128 memory X,
        uint256 precomputePrecision,
        uint256 maclaurinPrecision
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        assert(precomputePrecision <= MAX_PRECOMPUTE_PRECISION);
        assert(X.num < X.den);
         

        Fraction.Fraction128 memory Xtemp = X.copy();
        if (Xtemp.num == 0) {  
            return ONE();
        }

        Fraction.Fraction128 memory result = ONE();

        uint256 d = 1;  
        for (uint256 i = 1; i <= precomputePrecision; i++) {
            d *= 2;

             
            if (d.mul(Xtemp.num) >= Xtemp.den) {
                Xtemp = Xtemp.sub1Over(uint128(d));
                result = result.mul(getPrecomputedEToTheHalfToThe(i));
            }
        }
        return result.mul(expMaclaurin(Xtemp, maclaurinPrecision));
    }

     
    function expMaclaurin(
        Fraction.Fraction128 memory X,
        uint256 precision
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        Fraction.Fraction128 memory Xcopy = X.copy();
        if (Xcopy.num == 0) {  
            return ONE();
        }

        Fraction.Fraction128 memory result = ONE();
        Fraction.Fraction128 memory Xtemp = ONE();
        for (uint256 i = 1; i <= precision; i++) {
            Xtemp = Xtemp.mul(Xcopy.div(uint128(i)));
            result = result.add(Xtemp);
        }
        return result;
    }

     
    function getPrecomputedEToTheHalfToThe(
        uint256 x
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        assert(x <= MAX_PRECOMPUTE_PRECISION);

        uint128 denominator = [
            125182886983370532117250726298150828301,
            206391688497133195273760705512282642279,
            265012173823417992016237332255925138361,
            300298134811882980317033350418940119802,
            319665700530617779809390163992561606014,
            329812979126047300897653247035862915816,
            335006777809430963166468914297166288162,
            337634268532609249517744113622081347950,
            338955731696479810470146282672867036734,
            339618401537809365075354109784799900812,
            339950222128463181389559457827561204959,
            340116253979683015278260491021941090650,
            340199300311581465057079429423749235412,
            340240831081268226777032180141478221816,
            340261598367316729254995498374473399540,
            340271982485676106947851156443492415142,
            340277174663693808406010255284800906112,
            340279770782412691177936847400746725466,
            340281068849199706686796915841848278311,
            340281717884450116236033378667952410919,
            340282042402539547492367191008339680733,
            340282204661700319870089970029119685699,
            340282285791309720262481214385569134454,
            340282326356121674011576912006427792656,
            340282346638529464274601981200276914173,
            340282356779733812753265346086924801364,
            340282361850336100329388676752133324799,
            340282364385637272451648746721404212564,
            340282365653287865596328444437856608255,
            340282366287113163939555716675618384724,
            340282366604025813553891209601455838559,
            340282366762482138471739420386372790954,
            340282366841710300958333641874363209044
        ][x];
        return Fraction.Fraction128({
            num: MAX_NUMERATOR,
            den: denominator
        });
    }

     
    function getPrecomputedEToThe(
        uint256 x
    )
        internal
        pure
        returns (Fraction.Fraction128 memory)
    {
        assert(x <= NUM_PRECOMPUTED_INTEGERS);

        uint128 denominator = [
            340282366920938463463374607431768211455,
            125182886983370532117250726298150828301,
            46052210507670172419625860892627118820,
            16941661466271327126146327822211253888,
            6232488952727653950957829210887653621,
            2292804553036637136093891217529878878,
            843475657686456657683449904934172134,
            310297353591408453462393329342695980,
            114152017036184782947077973323212575,
            41994180235864621538772677139808695,
            15448795557622704876497742989562086,
            5683294276510101335127414470015662,
            2090767122455392675095471286328463,
            769150240628514374138961856925097,
            282954560699298259527814398449860,
            104093165666968799599694528310221,
            38293735615330848145349245349513,
            14087478058534870382224480725096,
            5182493555688763339001418388912,
            1906532833141383353974257736699,
            701374233231058797338605168652,
            258021160973090761055471434334,
            94920680509187392077350434438,
            34919366901332874995585576427,
            12846117181722897538509298435,
            4725822410035083116489797150,
            1738532907279185132707372378,
            639570514388029575350057932,
            235284843422800231081973821,
            86556456714490055457751527,
            31842340925906738090071268,
            11714142585413118080082437,
            4309392228124372433711936
        ][x];
        return Fraction.Fraction128({
            num: MAX_NUMERATOR,
            den: denominator
        });
    }

     

    function ONE()
        private
        pure
        returns (Fraction.Fraction128 memory)
    {
        return Fraction.Fraction128({ num: 1, den: 1 });
    }
}

 

 
library MathHelpers {
    using SafeMath for uint256;

     
    function getPartialAmount(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256)
    {
        return numerator.mul(target).div(denominator);
    }

     
    function getPartialAmountRoundedUp(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256)
    {
        return divisionRoundedUp(numerator.mul(target), denominator);
    }

     
    function divisionRoundedUp(
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        assert(denominator != 0);  
        if (numerator == 0) {
            return 0;
        }
        return numerator.sub(1).div(denominator).add(1);
    }

     
    function maxUint256(
    )
        internal
        pure
        returns (uint256)
    {
        return 2 ** 256 - 1;
    }

     
    function maxUint32(
    )
        internal
        pure
        returns (uint32)
    {
        return 2 ** 32 - 1;
    }

     
    function getNumBits(
        uint256 n
    )
        internal
        pure
        returns (uint256)
    {
        uint256 first = 0;
        uint256 last = 256;
        while (first < last) {
            uint256 check = (first + last) / 2;
            if ((n >> check) == 0) {
                last = check;
            } else {
                first = check + 1;
            }
        }
        assert(first <= 256);
        return first;
    }
}

 

 
library InterestImpl {
    using SafeMath for uint256;
    using FractionMath for Fraction.Fraction128;

     

    uint256 constant DEFAULT_PRECOMPUTE_PRECISION = 11;

    uint256 constant DEFAULT_MACLAURIN_PRECISION = 5;

    uint256 constant MAXIMUM_EXPONENT = 80;

    uint128 constant E_TO_MAXIUMUM_EXPONENT = 55406223843935100525711733958316613;

     

     
    function getCompoundedInterest(
        uint256 principal,
        uint256 interestRate,
        uint256 secondsOfInterest
    )
        public
        pure
        returns (uint256)
    {
        uint256 numerator = interestRate.mul(secondsOfInterest);
        uint128 denominator = (10**8) * (365 * 1 days);

         
        assert(numerator < 2**128);

         
        Fraction.Fraction128 memory rt = Fraction.Fraction128({
            num: uint128(numerator),
            den: denominator
        });

         
        Fraction.Fraction128 memory eToRT;
        if (numerator.div(denominator) >= MAXIMUM_EXPONENT) {
             
            eToRT = Fraction.Fraction128({
                num: E_TO_MAXIUMUM_EXPONENT,
                den: 1
            });
        } else {
             
            eToRT = Exponent.exp(
                rt,
                DEFAULT_PRECOMPUTE_PRECISION,
                DEFAULT_MACLAURIN_PRECISION
            );
        }

         
        assert(eToRT.num >= eToRT.den);

        return safeMultiplyUint256ByFraction(principal, eToRT);
    }

     

     
    function safeMultiplyUint256ByFraction(
        uint256 n,
        Fraction.Fraction128 memory f
    )
        private
        pure
        returns (uint256)
    {
        uint256 term1 = n.div(2 ** 128);  
        uint256 term2 = n % (2 ** 128);  

         
        if (term1 > 0) {
            term1 = term1.mul(f.num);
            uint256 numBits = MathHelpers.getNumBits(term1);

             
            term1 = MathHelpers.divisionRoundedUp(
                term1 << (uint256(256).sub(numBits)),
                f.den);

             
            if (numBits > 128) {
                term1 = term1 << (numBits.sub(128));
            } else if (numBits < 128) {
                term1 = term1 >> (uint256(128).sub(numBits));
            }
        }

         
        term2 = MathHelpers.getPartialAmountRoundedUp(
            f.num,
            f.den,
            term2
        );

        return term1.add(term2);
    }
}

 

 
library MarginState {
    struct State {
         
        address VAULT;

         
        address TOKEN_PROXY;

         
         
        mapping (bytes32 => uint256) loanFills;

         
         
        mapping (bytes32 => uint256) loanCancels;

         
        mapping (bytes32 => MarginCommon.Position) positions;

         
         
        mapping (bytes32 => bool) closedPositions;

         
         
        mapping (bytes32 => uint256) totalOwedTokenRepaidToLender;
    }
}

 

 
interface LoanOwner {

     

     
    function receiveLoanOwnership(
        address from,
        bytes32 positionId
    )
        external
         
        returns (address);
}

 

 
interface PositionOwner {

     

     
    function receivePositionOwnership(
        address from,
        bytes32 positionId
    )
        external
         
        returns (address);
}

 

 
library TransferInternal {

     

     
    event LoanTransferred(
        bytes32 indexed positionId,
        address indexed from,
        address indexed to
    );

     
    event PositionTransferred(
        bytes32 indexed positionId,
        address indexed from,
        address indexed to
    );

     

     
    function grantLoanOwnership(
        bytes32 positionId,
        address oldOwner,
        address newOwner
    )
        internal
        returns (address)
    {
         
        if (oldOwner != address(0)) {
            emit LoanTransferred(positionId, oldOwner, newOwner);
        }

        if (AddressUtils.isContract(newOwner)) {
            address nextOwner =
                LoanOwner(newOwner).receiveLoanOwnership(oldOwner, positionId);
            if (nextOwner != newOwner) {
                return grantLoanOwnership(positionId, newOwner, nextOwner);
            }
        }

        require(
            newOwner != address(0),
            "TransferInternal#grantLoanOwnership: New owner did not consent to owning loan"
        );

        return newOwner;
    }

     
    function grantPositionOwnership(
        bytes32 positionId,
        address oldOwner,
        address newOwner
    )
        internal
        returns (address)
    {
         
        if (oldOwner != address(0)) {
            emit PositionTransferred(positionId, oldOwner, newOwner);
        }

        if (AddressUtils.isContract(newOwner)) {
            address nextOwner =
                PositionOwner(newOwner).receivePositionOwnership(oldOwner, positionId);
            if (nextOwner != newOwner) {
                return grantPositionOwnership(positionId, newOwner, nextOwner);
            }
        }

        require(
            newOwner != address(0),
            "TransferInternal#grantPositionOwnership: New owner did not consent to owning position"
        );

        return newOwner;
    }
}

 

 
library TimestampHelper {
    function getBlockTimestamp32()
        internal
        view
        returns (uint32)
    {
         
        assert(uint256(uint32(block.timestamp)) == block.timestamp);

        assert(block.timestamp > 0);

        return uint32(block.timestamp);
    }
}

 

 
library MarginCommon {
    using SafeMath for uint256;

     

    struct Position {
        address owedToken;        
        address heldToken;        
        address lender;
        address owner;
        uint256 principal;
        uint256 requiredDeposit;
        uint32  callTimeLimit;    
        uint32  startTimestamp;   
        uint32  callTimestamp;
        uint32  maxDuration;      
        uint32  interestRate;     
        uint32  interestPeriod;   
    }

    struct LoanOffering {
        address   owedToken;
        address   heldToken;
        address   payer;
        address   owner;
        address   taker;
        address   positionOwner;
        address   feeRecipient;
        address   lenderFeeToken;
        address   takerFeeToken;
        LoanRates rates;
        uint256   expirationTimestamp;
        uint32    callTimeLimit;
        uint32    maxDuration;
        uint256   salt;
        bytes32   loanHash;
        bytes     signature;
    }

    struct LoanRates {
        uint256 maxAmount;
        uint256 minAmount;
        uint256 minHeldToken;
        uint256 lenderFee;
        uint256 takerFee;
        uint32  interestRate;
        uint32  interestPeriod;
    }

     

    function storeNewPosition(
        MarginState.State storage state,
        bytes32 positionId,
        Position memory position,
        address loanPayer
    )
        internal
    {
        assert(!positionHasExisted(state, positionId));
        assert(position.owedToken != address(0));
        assert(position.heldToken != address(0));
        assert(position.owedToken != position.heldToken);
        assert(position.owner != address(0));
        assert(position.lender != address(0));
        assert(position.maxDuration != 0);
        assert(position.interestPeriod <= position.maxDuration);
        assert(position.callTimestamp == 0);
        assert(position.requiredDeposit == 0);

        state.positions[positionId].owedToken = position.owedToken;
        state.positions[positionId].heldToken = position.heldToken;
        state.positions[positionId].principal = position.principal;
        state.positions[positionId].callTimeLimit = position.callTimeLimit;
        state.positions[positionId].startTimestamp = TimestampHelper.getBlockTimestamp32();
        state.positions[positionId].maxDuration = position.maxDuration;
        state.positions[positionId].interestRate = position.interestRate;
        state.positions[positionId].interestPeriod = position.interestPeriod;

        state.positions[positionId].owner = TransferInternal.grantPositionOwnership(
            positionId,
            (position.owner != msg.sender) ? msg.sender : address(0),
            position.owner
        );

        state.positions[positionId].lender = TransferInternal.grantLoanOwnership(
            positionId,
            (position.lender != loanPayer) ? loanPayer : address(0),
            position.lender
        );
    }

    function getPositionIdFromNonce(
        uint256 nonce
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(msg.sender, nonce));
    }

    function getUnavailableLoanOfferingAmountImpl(
        MarginState.State storage state,
        bytes32 loanHash
    )
        internal
        view
        returns (uint256)
    {
        return state.loanFills[loanHash].add(state.loanCancels[loanHash]);
    }

    function cleanupPosition(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
    {
        delete state.positions[positionId];
        state.closedPositions[positionId] = true;
    }

    function calculateOwedAmount(
        Position storage position,
        uint256 closeAmount,
        uint256 endTimestamp
    )
        internal
        view
        returns (uint256)
    {
        uint256 timeElapsed = calculateEffectiveTimeElapsed(position, endTimestamp);

        return InterestImpl.getCompoundedInterest(
            closeAmount,
            position.interestRate,
            timeElapsed
        );
    }

     
    function calculateEffectiveTimeElapsed(
        Position storage position,
        uint256 timestamp
    )
        internal
        view
        returns (uint256)
    {
        uint256 elapsed = timestamp.sub(position.startTimestamp);

         
        uint256 period = position.interestPeriod;
        if (period > 1) {
            elapsed = MathHelpers.divisionRoundedUp(elapsed, period).mul(period);
        }

         
        return Math.min256(
            elapsed,
            position.maxDuration
        );
    }

    function calculateLenderAmountForIncreasePosition(
        Position storage position,
        uint256 principalToAdd,
        uint256 endTimestamp
    )
        internal
        view
        returns (uint256)
    {
        uint256 timeElapsed = calculateEffectiveTimeElapsedForNewLender(position, endTimestamp);

        return InterestImpl.getCompoundedInterest(
            principalToAdd,
            position.interestRate,
            timeElapsed
        );
    }

    function getLoanOfferingHash(
        LoanOffering loanOffering
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                loanOffering.owedToken,
                loanOffering.heldToken,
                loanOffering.payer,
                loanOffering.owner,
                loanOffering.taker,
                loanOffering.positionOwner,
                loanOffering.feeRecipient,
                loanOffering.lenderFeeToken,
                loanOffering.takerFeeToken,
                getValuesHash(loanOffering)
            )
        );
    }

    function getPositionBalanceImpl(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
        view
        returns(uint256)
    {
        return Vault(state.VAULT).balances(positionId, state.positions[positionId].heldToken);
    }

    function containsPositionImpl(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
        view
        returns (bool)
    {
        return state.positions[positionId].startTimestamp != 0;
    }

    function positionHasExisted(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
        view
        returns (bool)
    {
        return containsPositionImpl(state, positionId) || state.closedPositions[positionId];
    }

    function getPositionFromStorage(
        MarginState.State storage state,
        bytes32 positionId
    )
        internal
        view
        returns (Position storage)
    {
        Position storage position = state.positions[positionId];

        require(
            position.startTimestamp != 0,
            "MarginCommon#getPositionFromStorage: The position does not exist"
        );

        return position;
    }

     

     
    function calculateEffectiveTimeElapsedForNewLender(
        Position storage position,
        uint256 timestamp
    )
        private
        view
        returns (uint256)
    {
        uint256 elapsed = timestamp.sub(position.startTimestamp);

         
        uint256 period = position.interestPeriod;
        if (period > 1) {
            elapsed = elapsed.div(period).mul(period);
        }

         
        return Math.min256(
            elapsed,
            position.maxDuration
        );
    }

    function getValuesHash(
        LoanOffering loanOffering
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                loanOffering.rates.maxAmount,
                loanOffering.rates.minAmount,
                loanOffering.rates.minHeldToken,
                loanOffering.rates.lenderFee,
                loanOffering.rates.takerFee,
                loanOffering.expirationTimestamp,
                loanOffering.salt,
                loanOffering.callTimeLimit,
                loanOffering.maxDuration,
                loanOffering.rates.interestRate,
                loanOffering.rates.interestPeriod
            )
        );
    }
}

 

 
interface PayoutRecipient {

     

     
    function receiveClosePositionPayout(
        bytes32 positionId,
        uint256 closeAmount,
        address closer,
        address positionOwner,
        address heldToken,
        uint256 payout,
        uint256 totalHeldToken,
        bool    payoutInHeldToken
    )
        external
         
        returns (bool);
}

 

 
interface CloseLoanDelegator {

     

     
    function closeLoanOnBehalfOf(
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 requestedAmount
    )
        external
         
        returns (address, uint256);
}

 

 
interface ClosePositionDelegator {

     

     
    function closeOnBehalfOf(
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 requestedAmount
    )
        external
         
        returns (address, uint256);
}

 

 
library ClosePositionShared {
    using SafeMath for uint256;

     

    struct CloseTx {
        bytes32 positionId;
        uint256 originalPrincipal;
        uint256 closeAmount;
        uint256 owedTokenOwed;
        uint256 startingHeldTokenBalance;
        uint256 availableHeldToken;
        address payoutRecipient;
        address owedToken;
        address heldToken;
        address positionOwner;
        address positionLender;
        address exchangeWrapper;
        bool    payoutInHeldToken;
    }

     

    function closePositionStateUpdate(
        MarginState.State storage state,
        CloseTx memory transaction
    )
        internal
    {
         
        if (transaction.closeAmount == transaction.originalPrincipal) {
            MarginCommon.cleanupPosition(state, transaction.positionId);
        } else {
            assert(
                transaction.originalPrincipal == state.positions[transaction.positionId].principal
            );
            state.positions[transaction.positionId].principal =
                transaction.originalPrincipal.sub(transaction.closeAmount);
        }
    }

    function sendTokensToPayoutRecipient(
        MarginState.State storage state,
        ClosePositionShared.CloseTx memory transaction,
        uint256 buybackCostInHeldToken,
        uint256 receivedOwedToken
    )
        internal
        returns (uint256)
    {
        uint256 payout;

        if (transaction.payoutInHeldToken) {
             
            payout = transaction.availableHeldToken.sub(buybackCostInHeldToken);

            Vault(state.VAULT).transferFromVault(
                transaction.positionId,
                transaction.heldToken,
                transaction.payoutRecipient,
                payout
            );
        } else {
            assert(transaction.exchangeWrapper != address(0));

            payout = receivedOwedToken.sub(transaction.owedTokenOwed);

            TokenProxy(state.TOKEN_PROXY).transferTokens(
                transaction.owedToken,
                transaction.exchangeWrapper,
                transaction.payoutRecipient,
                payout
            );
        }

        if (AddressUtils.isContract(transaction.payoutRecipient)) {
            require(
                PayoutRecipient(transaction.payoutRecipient).receiveClosePositionPayout(
                    transaction.positionId,
                    transaction.closeAmount,
                    msg.sender,
                    transaction.positionOwner,
                    transaction.heldToken,
                    payout,
                    transaction.availableHeldToken,
                    transaction.payoutInHeldToken
                ),
                "ClosePositionShared#sendTokensToPayoutRecipient: Payout recipient does not consent"
            );
        }

         
         
        assert(
            MarginCommon.getPositionBalanceImpl(state, transaction.positionId)
            == transaction.startingHeldTokenBalance.sub(transaction.availableHeldToken)
        );

        return payout;
    }

    function createCloseTx(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 requestedAmount,
        address payoutRecipient,
        address exchangeWrapper,
        bool payoutInHeldToken,
        bool isWithoutCounterparty
    )
        internal
        returns (CloseTx memory)
    {
         
        require(
            payoutRecipient != address(0),
            "ClosePositionShared#createCloseTx: Payout recipient cannot be 0"
        );
        require(
            requestedAmount > 0,
            "ClosePositionShared#createCloseTx: Requested close amount cannot be 0"
        );

        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        uint256 closeAmount = getApprovedAmount(
            position,
            positionId,
            requestedAmount,
            payoutRecipient,
            isWithoutCounterparty
        );

        return parseCloseTx(
            state,
            position,
            positionId,
            closeAmount,
            payoutRecipient,
            exchangeWrapper,
            payoutInHeldToken,
            isWithoutCounterparty
        );
    }

     

    function getApprovedAmount(
        MarginCommon.Position storage position,
        bytes32 positionId,
        uint256 requestedAmount,
        address payoutRecipient,
        bool requireLenderApproval
    )
        private
        returns (uint256)
    {
         
        uint256 allowedAmount = Math.min256(requestedAmount, position.principal);

         
        allowedAmount = closePositionOnBehalfOfRecurse(
            position.owner,
            msg.sender,
            payoutRecipient,
            positionId,
            allowedAmount
        );

         
        if (requireLenderApproval) {
            allowedAmount = closeLoanOnBehalfOfRecurse(
                position.lender,
                msg.sender,
                payoutRecipient,
                positionId,
                allowedAmount
            );
        }

        assert(allowedAmount > 0);
        assert(allowedAmount <= position.principal);
        assert(allowedAmount <= requestedAmount);

        return allowedAmount;
    }

    function closePositionOnBehalfOfRecurse(
        address contractAddr,
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 closeAmount
    )
        private
        returns (uint256)
    {
         
        if (closer == contractAddr) {
            return closeAmount;
        }

        (
            address newContractAddr,
            uint256 newCloseAmount
        ) = ClosePositionDelegator(contractAddr).closeOnBehalfOf(
            closer,
            payoutRecipient,
            positionId,
            closeAmount
        );

        require(
            newCloseAmount <= closeAmount,
            "ClosePositionShared#closePositionRecurse: newCloseAmount is greater than closeAmount"
        );
        require(
            newCloseAmount > 0,
            "ClosePositionShared#closePositionRecurse: newCloseAmount is zero"
        );

        if (newContractAddr != contractAddr) {
            closePositionOnBehalfOfRecurse(
                newContractAddr,
                closer,
                payoutRecipient,
                positionId,
                newCloseAmount
            );
        }

        return newCloseAmount;
    }

    function closeLoanOnBehalfOfRecurse(
        address contractAddr,
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 closeAmount
    )
        private
        returns (uint256)
    {
         
        if (closer == contractAddr) {
            return closeAmount;
        }

        (
            address newContractAddr,
            uint256 newCloseAmount
        ) = CloseLoanDelegator(contractAddr).closeLoanOnBehalfOf(
                closer,
                payoutRecipient,
                positionId,
                closeAmount
            );

        require(
            newCloseAmount <= closeAmount,
            "ClosePositionShared#closeLoanRecurse: newCloseAmount is greater than closeAmount"
        );
        require(
            newCloseAmount > 0,
            "ClosePositionShared#closeLoanRecurse: newCloseAmount is zero"
        );

        if (newContractAddr != contractAddr) {
            closeLoanOnBehalfOfRecurse(
                newContractAddr,
                closer,
                payoutRecipient,
                positionId,
                newCloseAmount
            );
        }

        return newCloseAmount;
    }

     

    function parseCloseTx(
        MarginState.State storage state,
        MarginCommon.Position storage position,
        bytes32 positionId,
        uint256 closeAmount,
        address payoutRecipient,
        address exchangeWrapper,
        bool payoutInHeldToken,
        bool isWithoutCounterparty
    )
        private
        view
        returns (CloseTx memory)
    {
        uint256 startingHeldTokenBalance = MarginCommon.getPositionBalanceImpl(state, positionId);

        uint256 availableHeldToken = MathHelpers.getPartialAmount(
            closeAmount,
            position.principal,
            startingHeldTokenBalance
        );
        uint256 owedTokenOwed = 0;

        if (!isWithoutCounterparty) {
            owedTokenOwed = MarginCommon.calculateOwedAmount(
                position,
                closeAmount,
                block.timestamp
            );
        }

        return CloseTx({
            positionId: positionId,
            originalPrincipal: position.principal,
            closeAmount: closeAmount,
            owedTokenOwed: owedTokenOwed,
            startingHeldTokenBalance: startingHeldTokenBalance,
            availableHeldToken: availableHeldToken,
            payoutRecipient: payoutRecipient,
            owedToken: position.owedToken,
            heldToken: position.heldToken,
            positionOwner: position.owner,
            positionLender: position.lender,
            exchangeWrapper: exchangeWrapper,
            payoutInHeldToken: payoutInHeldToken
        });
    }
}

 

 
interface ExchangeWrapper {

     

     
    function exchange(
        address tradeOriginator,
        address receiver,
        address makerToken,
        address takerToken,
        uint256 requestedFillAmount,
        bytes orderData
    )
        external
        returns (uint256);

     
    function getExchangeCost(
        address makerToken,
        address takerToken,
        uint256 desiredMakerToken,
        bytes orderData
    )
        external
        view
        returns (uint256);
}

 

 
library ClosePositionImpl {
    using SafeMath for uint256;

     

     
    event PositionClosed(
        bytes32 indexed positionId,
        address indexed closer,
        address indexed payoutRecipient,
        uint256 closeAmount,
        uint256 remainingAmount,
        uint256 owedTokenPaidToLender,
        uint256 payoutAmount,
        uint256 buybackCostInHeldToken,
        bool    payoutInHeldToken
    );

     

    function closePositionImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient,
        address exchangeWrapper,
        bool payoutInHeldToken,
        bytes memory orderData
    )
        public
        returns (uint256, uint256, uint256)
    {
        ClosePositionShared.CloseTx memory transaction = ClosePositionShared.createCloseTx(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient,
            exchangeWrapper,
            payoutInHeldToken,
            false
        );

        (
            uint256 buybackCostInHeldToken,
            uint256 receivedOwedToken
        ) = returnOwedTokensToLender(
            state,
            transaction,
            orderData
        );

        uint256 payout = ClosePositionShared.sendTokensToPayoutRecipient(
            state,
            transaction,
            buybackCostInHeldToken,
            receivedOwedToken
        );

        ClosePositionShared.closePositionStateUpdate(state, transaction);

        logEventOnClose(
            transaction,
            buybackCostInHeldToken,
            payout
        );

        return (
            transaction.closeAmount,
            payout,
            transaction.owedTokenOwed
        );
    }

     

    function returnOwedTokensToLender(
        MarginState.State storage state,
        ClosePositionShared.CloseTx memory transaction,
        bytes memory orderData
    )
        private
        returns (uint256, uint256)
    {
        uint256 buybackCostInHeldToken = 0;
        uint256 receivedOwedToken = 0;
        uint256 lenderOwedToken = transaction.owedTokenOwed;

         
         
        if (transaction.exchangeWrapper == address(0)) {
            require(
                transaction.payoutInHeldToken,
                "ClosePositionImpl#returnOwedTokensToLender: Cannot payout in owedToken"
            );

             
            TokenProxy(state.TOKEN_PROXY).transferTokens(
                transaction.owedToken,
                msg.sender,
                transaction.positionLender,
                lenderOwedToken
            );
        } else {
             
            (buybackCostInHeldToken, receivedOwedToken) = buyBackOwedToken(
                state,
                transaction,
                orderData
            );

             
            if (transaction.payoutInHeldToken) {
                assert(receivedOwedToken >= lenderOwedToken);
                lenderOwedToken = receivedOwedToken;
            }

             
            TokenProxy(state.TOKEN_PROXY).transferTokens(
                transaction.owedToken,
                transaction.exchangeWrapper,
                transaction.positionLender,
                lenderOwedToken
            );
        }

        state.totalOwedTokenRepaidToLender[transaction.positionId] =
            state.totalOwedTokenRepaidToLender[transaction.positionId].add(lenderOwedToken);

        return (buybackCostInHeldToken, receivedOwedToken);
    }

    function buyBackOwedToken(
        MarginState.State storage state,
        ClosePositionShared.CloseTx transaction,
        bytes memory orderData
    )
        private
        returns (uint256, uint256)
    {
         
         
        uint256 buybackCostInHeldToken;

        if (transaction.payoutInHeldToken) {
            buybackCostInHeldToken = ExchangeWrapper(transaction.exchangeWrapper)
                .getExchangeCost(
                    transaction.owedToken,
                    transaction.heldToken,
                    transaction.owedTokenOwed,
                    orderData
                );

             
            require(
                buybackCostInHeldToken <= transaction.availableHeldToken,
                "ClosePositionImpl#buyBackOwedToken: Not enough available heldToken"
            );
        } else {
            buybackCostInHeldToken = transaction.availableHeldToken;
        }

         
        Vault(state.VAULT).transferFromVault(
            transaction.positionId,
            transaction.heldToken,
            transaction.exchangeWrapper,
            buybackCostInHeldToken
        );

         
        uint256 receivedOwedToken = ExchangeWrapper(transaction.exchangeWrapper).exchange(
            msg.sender,
            state.TOKEN_PROXY,
            transaction.owedToken,
            transaction.heldToken,
            buybackCostInHeldToken,
            orderData
        );

        require(
            receivedOwedToken >= transaction.owedTokenOwed,
            "ClosePositionImpl#buyBackOwedToken: Did not receive enough owedToken"
        );

        return (buybackCostInHeldToken, receivedOwedToken);
    }

    function logEventOnClose(
        ClosePositionShared.CloseTx transaction,
        uint256 buybackCostInHeldToken,
        uint256 payout
    )
        private
    {
        emit PositionClosed(
            transaction.positionId,
            msg.sender,
            transaction.payoutRecipient,
            transaction.closeAmount,
            transaction.originalPrincipal.sub(transaction.closeAmount),
            transaction.owedTokenOwed,
            payout,
            buybackCostInHeldToken,
            transaction.payoutInHeldToken
        );
    }

}

 

 
library CloseWithoutCounterpartyImpl {
    using SafeMath for uint256;

     

     
    event PositionClosed(
        bytes32 indexed positionId,
        address indexed closer,
        address indexed payoutRecipient,
        uint256 closeAmount,
        uint256 remainingAmount,
        uint256 owedTokenPaidToLender,
        uint256 payoutAmount,
        uint256 buybackCostInHeldToken,
        bool payoutInHeldToken
    );

     

    function closeWithoutCounterpartyImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient
    )
        public
        returns (uint256, uint256)
    {
        ClosePositionShared.CloseTx memory transaction = ClosePositionShared.createCloseTx(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient,
            address(0),
            true,
            true
        );

        uint256 heldTokenPayout = ClosePositionShared.sendTokensToPayoutRecipient(
            state,
            transaction,
            0,  
            0   
        );

        ClosePositionShared.closePositionStateUpdate(state, transaction);

        logEventOnCloseWithoutCounterparty(transaction);

        return (
            transaction.closeAmount,
            heldTokenPayout
        );
    }

     

    function logEventOnCloseWithoutCounterparty(
        ClosePositionShared.CloseTx transaction
    )
        private
    {
        emit PositionClosed(
            transaction.positionId,
            msg.sender,
            transaction.payoutRecipient,
            transaction.closeAmount,
            transaction.originalPrincipal.sub(transaction.closeAmount),
            0,
            transaction.availableHeldToken,
            0,
            true
        );
    }
}

 

 
interface DepositCollateralDelegator {

     

     
    function depositCollateralOnBehalfOf(
        address depositor,
        bytes32 positionId,
        uint256 amount
    )
        external
         
        returns (address);
}

 

 
library DepositCollateralImpl {
    using SafeMath for uint256;

     

     
    event AdditionalCollateralDeposited(
        bytes32 indexed positionId,
        uint256 amount,
        address depositor
    );

     
    event MarginCallCanceled(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 depositAmount
    );

     

    function depositCollateralImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 depositAmount
    )
        public
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            depositAmount > 0,
            "DepositCollateralImpl#depositCollateralImpl: Deposit amount cannot be 0"
        );

         
        depositCollateralOnBehalfOfRecurse(
            position.owner,
            msg.sender,
            positionId,
            depositAmount
        );

        Vault(state.VAULT).transferToVault(
            positionId,
            position.heldToken,
            msg.sender,
            depositAmount
        );

         
        bool marginCallCanceled = false;
        uint256 requiredDeposit = position.requiredDeposit;
        if (position.callTimestamp > 0 && requiredDeposit > 0) {
            if (depositAmount >= requiredDeposit) {
                position.requiredDeposit = 0;
                position.callTimestamp = 0;
                marginCallCanceled = true;
            } else {
                position.requiredDeposit = position.requiredDeposit.sub(depositAmount);
            }
        }

        emit AdditionalCollateralDeposited(
            positionId,
            depositAmount,
            msg.sender
        );

        if (marginCallCanceled) {
            emit MarginCallCanceled(
                positionId,
                position.lender,
                msg.sender,
                depositAmount
            );
        }
    }

     

    function depositCollateralOnBehalfOfRecurse(
        address contractAddr,
        address depositor,
        bytes32 positionId,
        uint256 amount
    )
        private
    {
         
        if (depositor == contractAddr) {
            return;
        }

        address newContractAddr =
            DepositCollateralDelegator(contractAddr).depositCollateralOnBehalfOf(
                depositor,
                positionId,
                amount
            );

         
        if (newContractAddr != contractAddr) {
            depositCollateralOnBehalfOfRecurse(
                newContractAddr,
                depositor,
                positionId,
                amount
            );
        }
    }
}

 

 
interface ForceRecoverCollateralDelegator {

     

     
    function forceRecoverCollateralOnBehalfOf(
        address recoverer,
        bytes32 positionId,
        address recipient
    )
        external
         
        returns (address);
}

 

 

 
library ForceRecoverCollateralImpl {
    using SafeMath for uint256;

     

     
    event CollateralForceRecovered(
        bytes32 indexed positionId,
        address indexed recipient,
        uint256 amount
    );

     

    function forceRecoverCollateralImpl(
        MarginState.State storage state,
        bytes32 positionId,
        address recipient
    )
        public
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

         
         
         
        require(  
            (
                position.callTimestamp > 0
                && block.timestamp >= uint256(position.callTimestamp).add(position.callTimeLimit)
            ) || (
                block.timestamp >= uint256(position.startTimestamp).add(position.maxDuration)
            ),
            "ForceRecoverCollateralImpl#forceRecoverCollateralImpl: Cannot recover yet"
        );

         
        forceRecoverCollateralOnBehalfOfRecurse(
            position.lender,
            msg.sender,
            positionId,
            recipient
        );

         
        uint256 heldTokenRecovered = MarginCommon.getPositionBalanceImpl(state, positionId);
        Vault(state.VAULT).transferFromVault(
            positionId,
            position.heldToken,
            recipient,
            heldTokenRecovered
        );

         
         
         
        MarginCommon.cleanupPosition(
            state,
            positionId
        );

         
        emit CollateralForceRecovered(
            positionId,
            recipient,
            heldTokenRecovered
        );

        return heldTokenRecovered;
    }

     

    function forceRecoverCollateralOnBehalfOfRecurse(
        address contractAddr,
        address recoverer,
        bytes32 positionId,
        address recipient
    )
        private
    {
         
        if (recoverer == contractAddr) {
            return;
        }

        address newContractAddr =
            ForceRecoverCollateralDelegator(contractAddr).forceRecoverCollateralOnBehalfOf(
                recoverer,
                positionId,
                recipient
            );

        if (newContractAddr != contractAddr) {
            forceRecoverCollateralOnBehalfOfRecurse(
                newContractAddr,
                recoverer,
                positionId,
                recipient
            );
        }
    }
}

 

 
library TypedSignature {

     
    uint8 private constant SIGTYPE_INVALID = 0;
    uint8 private constant SIGTYPE_ECRECOVER_DEC = 1;
    uint8 private constant SIGTYPE_ECRECOVER_HEX = 2;
    uint8 private constant SIGTYPE_UNSUPPORTED = 3;

     
    bytes constant private PREPEND_HEX = "\x19Ethereum Signed Message:\n\x20";

     
    bytes constant private PREPEND_DEC = "\x19Ethereum Signed Message:\n32";

     
    function recover(
        bytes32 hash,
        bytes signatureWithType
    )
        internal
        pure
        returns (address)
    {
        require(
            signatureWithType.length == 66,
            "SignatureValidator#validateSignature: invalid signature length"
        );

        uint8 sigType = uint8(signatureWithType[0]);

        require(
            sigType > uint8(SIGTYPE_INVALID),
            "SignatureValidator#validateSignature: invalid signature type"
        );
        require(
            sigType < uint8(SIGTYPE_UNSUPPORTED),
            "SignatureValidator#validateSignature: unsupported signature type"
        );

        uint8 v = uint8(signatureWithType[1]);
        bytes32 r;
        bytes32 s;

         
        assembly {
            r := mload(add(signatureWithType, 34))
            s := mload(add(signatureWithType, 66))
        }

        bytes32 signedHash;
        if (sigType == SIGTYPE_ECRECOVER_DEC) {
            signedHash = keccak256(abi.encodePacked(PREPEND_DEC, hash));
        } else {
            assert(sigType == SIGTYPE_ECRECOVER_HEX);
            signedHash = keccak256(abi.encodePacked(PREPEND_HEX, hash));
        }

        return ecrecover(
            signedHash,
            v,
            r,
            s
        );
    }
}

 

 
interface LoanOfferingVerifier {

     
    function verifyLoanOffering(
        address[9] addresses,
        uint256[7] values256,
        uint32[4] values32,
        bytes32 positionId,
        bytes signature
    )
        external
         
        returns (address);
}

 

 
library BorrowShared {
    using SafeMath for uint256;

     

    struct Tx {
        bytes32 positionId;
        address owner;
        uint256 principal;
        uint256 lenderAmount;
        MarginCommon.LoanOffering loanOffering;
        address exchangeWrapper;
        bool depositInHeldToken;
        uint256 depositAmount;
        uint256 collateralAmount;
        uint256 heldTokenFromSell;
    }

     

     
    function validateTxPreSell(
        MarginState.State storage state,
        Tx memory transaction
    )
        internal
    {
        assert(transaction.lenderAmount >= transaction.principal);

        require(
            transaction.principal > 0,
            "BorrowShared#validateTxPreSell: Positions with 0 principal are not allowed"
        );

         
        if (transaction.loanOffering.taker != address(0)) {
            require(
                msg.sender == transaction.loanOffering.taker,
                "BorrowShared#validateTxPreSell: Invalid loan offering taker"
            );
        }

         
         
        if (transaction.loanOffering.positionOwner != address(0)) {
            require(
                transaction.owner == transaction.loanOffering.positionOwner,
                "BorrowShared#validateTxPreSell: Invalid position owner"
            );
        }

         
        if (AddressUtils.isContract(transaction.loanOffering.payer)) {
            getConsentFromSmartContractLender(transaction);
        } else {
            require(
                transaction.loanOffering.payer == TypedSignature.recover(
                    transaction.loanOffering.loanHash,
                    transaction.loanOffering.signature
                ),
                "BorrowShared#validateTxPreSell: Invalid loan offering signature"
            );
        }

         
        uint256 unavailable = MarginCommon.getUnavailableLoanOfferingAmountImpl(
            state,
            transaction.loanOffering.loanHash
        );
        require(
            transaction.lenderAmount.add(unavailable) <= transaction.loanOffering.rates.maxAmount,
            "BorrowShared#validateTxPreSell: Loan offering does not have enough available"
        );

        require(
            transaction.lenderAmount >= transaction.loanOffering.rates.minAmount,
            "BorrowShared#validateTxPreSell: Lender amount is below loan offering minimum amount"
        );

        require(
            transaction.loanOffering.owedToken != transaction.loanOffering.heldToken,
            "BorrowShared#validateTxPreSell: owedToken cannot be equal to heldToken"
        );

        require(
            transaction.owner != address(0),
            "BorrowShared#validateTxPreSell: Position owner cannot be 0"
        );

        require(
            transaction.loanOffering.owner != address(0),
            "BorrowShared#validateTxPreSell: Loan owner cannot be 0"
        );

        require(
            transaction.loanOffering.expirationTimestamp > block.timestamp,
            "BorrowShared#validateTxPreSell: Loan offering is expired"
        );

        require(
            transaction.loanOffering.maxDuration > 0,
            "BorrowShared#validateTxPreSell: Loan offering has 0 maximum duration"
        );

        require(
            transaction.loanOffering.rates.interestPeriod <= transaction.loanOffering.maxDuration,
            "BorrowShared#validateTxPreSell: Loan offering interestPeriod > maxDuration"
        );

         
         
    }

     
    function doPostSell(
        MarginState.State storage state,
        Tx memory transaction
    )
        internal
    {
        validateTxPostSell(transaction);

         
        transferLoanFees(state, transaction);

         
        state.loanFills[transaction.loanOffering.loanHash] =
            state.loanFills[transaction.loanOffering.loanHash].add(transaction.lenderAmount);
    }

     
    function doSell(
        MarginState.State storage state,
        Tx transaction,
        bytes orderData,
        uint256 maxHeldTokenToBuy
    )
        internal
        returns (uint256)
    {
         
        pullOwedTokensFromLender(state, transaction);

         
         
        uint256 sellAmount = transaction.depositInHeldToken ?
            transaction.lenderAmount :
            transaction.lenderAmount.add(transaction.depositAmount);

         
        uint256 heldTokenFromSell = Math.min256(
            maxHeldTokenToBuy,
            ExchangeWrapper(transaction.exchangeWrapper).exchange(
                msg.sender,
                state.TOKEN_PROXY,
                transaction.loanOffering.heldToken,
                transaction.loanOffering.owedToken,
                sellAmount,
                orderData
            )
        );

         
        Vault(state.VAULT).transferToVault(
            transaction.positionId,
            transaction.loanOffering.heldToken,
            transaction.exchangeWrapper,
            heldTokenFromSell
        );

         
        transaction.collateralAmount = transaction.collateralAmount.add(heldTokenFromSell);

        return heldTokenFromSell;
    }

     
    function doDepositOwedToken(
        MarginState.State storage state,
        Tx transaction
    )
        internal
    {
        TokenProxy(state.TOKEN_PROXY).transferTokens(
            transaction.loanOffering.owedToken,
            msg.sender,
            transaction.exchangeWrapper,
            transaction.depositAmount
        );
    }

     
    function doDepositHeldToken(
        MarginState.State storage state,
        Tx transaction
    )
        internal
    {
        Vault(state.VAULT).transferToVault(
            transaction.positionId,
            transaction.loanOffering.heldToken,
            msg.sender,
            transaction.depositAmount
        );

         
        transaction.collateralAmount = transaction.collateralAmount.add(transaction.depositAmount);
    }

     

    function validateTxPostSell(
        Tx transaction
    )
        private
        pure
    {
        uint256 expectedCollateral = transaction.depositInHeldToken ?
            transaction.heldTokenFromSell.add(transaction.depositAmount) :
            transaction.heldTokenFromSell;
        assert(transaction.collateralAmount == expectedCollateral);

        uint256 loanOfferingMinimumHeldToken = MathHelpers.getPartialAmountRoundedUp(
            transaction.lenderAmount,
            transaction.loanOffering.rates.maxAmount,
            transaction.loanOffering.rates.minHeldToken
        );
        require(
            transaction.collateralAmount >= loanOfferingMinimumHeldToken,
            "BorrowShared#validateTxPostSell: Loan offering minimum held token not met"
        );
    }

    function getConsentFromSmartContractLender(
        Tx transaction
    )
        private
    {
        verifyLoanOfferingRecurse(
            transaction.loanOffering.payer,
            getLoanOfferingAddresses(transaction),
            getLoanOfferingValues256(transaction),
            getLoanOfferingValues32(transaction),
            transaction.positionId,
            transaction.loanOffering.signature
        );
    }

    function verifyLoanOfferingRecurse(
        address contractAddr,
        address[9] addresses,
        uint256[7] values256,
        uint32[4] values32,
        bytes32 positionId,
        bytes signature
    )
        private
    {
        address newContractAddr = LoanOfferingVerifier(contractAddr).verifyLoanOffering(
            addresses,
            values256,
            values32,
            positionId,
            signature
        );

        if (newContractAddr != contractAddr) {
            verifyLoanOfferingRecurse(
                newContractAddr,
                addresses,
                values256,
                values32,
                positionId,
                signature
            );
        }
    }

    function pullOwedTokensFromLender(
        MarginState.State storage state,
        Tx transaction
    )
        private
    {
         
        TokenProxy(state.TOKEN_PROXY).transferTokens(
            transaction.loanOffering.owedToken,
            transaction.loanOffering.payer,
            transaction.exchangeWrapper,
            transaction.lenderAmount
        );
    }

    function transferLoanFees(
        MarginState.State storage state,
        Tx transaction
    )
        private
    {
         
        if (transaction.loanOffering.feeRecipient == address(0)) {
            return;
        }

        TokenProxy proxy = TokenProxy(state.TOKEN_PROXY);

        uint256 lenderFee = MathHelpers.getPartialAmount(
            transaction.lenderAmount,
            transaction.loanOffering.rates.maxAmount,
            transaction.loanOffering.rates.lenderFee
        );
        uint256 takerFee = MathHelpers.getPartialAmount(
            transaction.lenderAmount,
            transaction.loanOffering.rates.maxAmount,
            transaction.loanOffering.rates.takerFee
        );

        if (lenderFee > 0) {
            proxy.transferTokens(
                transaction.loanOffering.lenderFeeToken,
                transaction.loanOffering.payer,
                transaction.loanOffering.feeRecipient,
                lenderFee
            );
        }

        if (takerFee > 0) {
            proxy.transferTokens(
                transaction.loanOffering.takerFeeToken,
                msg.sender,
                transaction.loanOffering.feeRecipient,
                takerFee
            );
        }
    }

    function getLoanOfferingAddresses(
        Tx transaction
    )
        private
        pure
        returns (address[9])
    {
        return [
            transaction.loanOffering.owedToken,
            transaction.loanOffering.heldToken,
            transaction.loanOffering.payer,
            transaction.loanOffering.owner,
            transaction.loanOffering.taker,
            transaction.loanOffering.positionOwner,
            transaction.loanOffering.feeRecipient,
            transaction.loanOffering.lenderFeeToken,
            transaction.loanOffering.takerFeeToken
        ];
    }

    function getLoanOfferingValues256(
        Tx transaction
    )
        private
        pure
        returns (uint256[7])
    {
        return [
            transaction.loanOffering.rates.maxAmount,
            transaction.loanOffering.rates.minAmount,
            transaction.loanOffering.rates.minHeldToken,
            transaction.loanOffering.rates.lenderFee,
            transaction.loanOffering.rates.takerFee,
            transaction.loanOffering.expirationTimestamp,
            transaction.loanOffering.salt
        ];
    }

    function getLoanOfferingValues32(
        Tx transaction
    )
        private
        pure
        returns (uint32[4])
    {
        return [
            transaction.loanOffering.callTimeLimit,
            transaction.loanOffering.maxDuration,
            transaction.loanOffering.rates.interestRate,
            transaction.loanOffering.rates.interestPeriod
        ];
    }
}

 

 
interface IncreaseLoanDelegator {

     

     
    function increaseLoanOnBehalfOf(
        address payer,
        bytes32 positionId,
        uint256 principalAdded,
        uint256 lentAmount
    )
        external
         
        returns (address);
}

 

 
interface IncreasePositionDelegator {

     

     
    function increasePositionOnBehalfOf(
        address trader,
        bytes32 positionId,
        uint256 principalAdded
    )
        external
         
        returns (address);
}

 

 
library IncreasePositionImpl {
    using SafeMath for uint256;

     

     
    event PositionIncreased(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        address positionOwner,
        address loanOwner,
        bytes32 loanHash,
        address loanFeeRecipient,
        uint256 amountBorrowed,
        uint256 principalAdded,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        bool    depositInHeldToken
    );

     

    function increasePositionImpl(
        MarginState.State storage state,
        bytes32 positionId,
        address[7] addresses,
        uint256[8] values256,
        uint32[2] values32,
        bool depositInHeldToken,
        bytes signature,
        bytes orderData
    )
        public
        returns (uint256)
    {
         
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        BorrowShared.Tx memory transaction = parseIncreasePositionTx(
            position,
            positionId,
            addresses,
            values256,
            values32,
            depositInHeldToken,
            signature
        );

        validateIncrease(state, transaction, position);

        doBorrowAndSell(state, transaction, orderData);

        updateState(
            position,
            transaction.positionId,
            transaction.principal,
            transaction.lenderAmount,
            transaction.loanOffering.payer
        );

         
        recordPositionIncreased(transaction, position);

        return transaction.lenderAmount;
    }

    function increaseWithoutCounterpartyImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 principalToAdd
    )
        public
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

         
        require(
            principalToAdd > 0,
            "IncreasePositionImpl#increaseWithoutCounterpartyImpl: Cannot add 0 principal"
        );

         
        require(
            block.timestamp < uint256(position.startTimestamp).add(position.maxDuration),
            "IncreasePositionImpl#increaseWithoutCounterpartyImpl: Cannot increase after maxDuration"
        );

        uint256 heldTokenAmount = getCollateralNeededForAddedPrincipal(
            state,
            position,
            positionId,
            principalToAdd
        );

        Vault(state.VAULT).transferToVault(
            positionId,
            position.heldToken,
            msg.sender,
            heldTokenAmount
        );

        updateState(
            position,
            positionId,
            principalToAdd,
            0,  
            msg.sender
        );

        emit PositionIncreased(
            positionId,
            msg.sender,
            msg.sender,
            position.owner,
            position.lender,
            "",
            address(0),
            0,
            principalToAdd,
            0,
            heldTokenAmount,
            true
        );

        return heldTokenAmount;
    }

     

    function doBorrowAndSell(
        MarginState.State storage state,
        BorrowShared.Tx memory transaction,
        bytes orderData
    )
        private
    {
         
        uint256 collateralToAdd = getCollateralNeededForAddedPrincipal(
            state,
            state.positions[transaction.positionId],
            transaction.positionId,
            transaction.principal
        );

         
        BorrowShared.validateTxPreSell(state, transaction);

         
        uint256 maxHeldTokenFromSell = MathHelpers.maxUint256();
        if (!transaction.depositInHeldToken) {
            transaction.depositAmount =
                getOwedTokenDeposit(transaction, collateralToAdd, orderData);
            BorrowShared.doDepositOwedToken(state, transaction);
            maxHeldTokenFromSell = collateralToAdd;
        }

         
        transaction.heldTokenFromSell = BorrowShared.doSell(
            state,
            transaction,
            orderData,
            maxHeldTokenFromSell
        );

         
        if (transaction.depositInHeldToken) {
            require(
                transaction.heldTokenFromSell <= collateralToAdd,
                "IncreasePositionImpl#doBorrowAndSell: DEX order gives too much heldToken"
            );
            transaction.depositAmount = collateralToAdd.sub(transaction.heldTokenFromSell);
            BorrowShared.doDepositHeldToken(state, transaction);
        }

         
        assert(transaction.collateralAmount == collateralToAdd);

         
        BorrowShared.doPostSell(state, transaction);
    }

    function getOwedTokenDeposit(
        BorrowShared.Tx transaction,
        uint256 collateralToAdd,
        bytes orderData
    )
        private
        view
        returns (uint256)
    {
        uint256 totalOwedToken = ExchangeWrapper(transaction.exchangeWrapper).getExchangeCost(
            transaction.loanOffering.heldToken,
            transaction.loanOffering.owedToken,
            collateralToAdd,
            orderData
        );

        require(
            transaction.lenderAmount <= totalOwedToken,
            "IncreasePositionImpl#getOwedTokenDeposit: Lender amount is more than required"
        );

        return totalOwedToken.sub(transaction.lenderAmount);
    }

    function validateIncrease(
        MarginState.State storage state,
        BorrowShared.Tx transaction,
        MarginCommon.Position storage position
    )
        private
        view
    {
        assert(MarginCommon.containsPositionImpl(state, transaction.positionId));

        require(
            position.callTimeLimit <= transaction.loanOffering.callTimeLimit,
            "IncreasePositionImpl#validateIncrease: Loan callTimeLimit is less than the position"
        );

         
        uint256 positionEndTimestamp = uint256(position.startTimestamp).add(position.maxDuration);
        uint256 offeringEndTimestamp = block.timestamp.add(transaction.loanOffering.maxDuration);
        require(
            positionEndTimestamp <= offeringEndTimestamp,
            "IncreasePositionImpl#validateIncrease: Loan end timestamp is less than the position"
        );

        require(
            block.timestamp < positionEndTimestamp,
            "IncreasePositionImpl#validateIncrease: Position has passed its maximum duration"
        );
    }

    function getCollateralNeededForAddedPrincipal(
        MarginState.State storage state,
        MarginCommon.Position storage position,
        bytes32 positionId,
        uint256 principalToAdd
    )
        private
        view
        returns (uint256)
    {
        uint256 heldTokenBalance = MarginCommon.getPositionBalanceImpl(state, positionId);

        return MathHelpers.getPartialAmountRoundedUp(
            principalToAdd,
            position.principal,
            heldTokenBalance
        );
    }

    function updateState(
        MarginCommon.Position storage position,
        bytes32 positionId,
        uint256 principalAdded,
        uint256 owedTokenLent,
        address loanPayer
    )
        private
    {
        position.principal = position.principal.add(principalAdded);

        address owner = position.owner;
        address lender = position.lender;

         
        increasePositionOnBehalfOfRecurse(
            owner,
            msg.sender,
            positionId,
            principalAdded
        );

         
        increaseLoanOnBehalfOfRecurse(
            lender,
            loanPayer,
            positionId,
            principalAdded,
            owedTokenLent
        );
    }

    function increasePositionOnBehalfOfRecurse(
        address contractAddr,
        address trader,
        bytes32 positionId,
        uint256 principalAdded
    )
        private
    {
         
        if (trader == contractAddr && !AddressUtils.isContract(contractAddr)) {
            return;
        }

        address newContractAddr =
            IncreasePositionDelegator(contractAddr).increasePositionOnBehalfOf(
                trader,
                positionId,
                principalAdded
            );

        if (newContractAddr != contractAddr) {
            increasePositionOnBehalfOfRecurse(
                newContractAddr,
                trader,
                positionId,
                principalAdded
            );
        }
    }

    function increaseLoanOnBehalfOfRecurse(
        address contractAddr,
        address payer,
        bytes32 positionId,
        uint256 principalAdded,
        uint256 amountLent
    )
        private
    {
         
        if (payer == contractAddr && !AddressUtils.isContract(contractAddr)) {
            return;
        }

        address newContractAddr =
            IncreaseLoanDelegator(contractAddr).increaseLoanOnBehalfOf(
                payer,
                positionId,
                principalAdded,
                amountLent
            );

        if (newContractAddr != contractAddr) {
            increaseLoanOnBehalfOfRecurse(
                newContractAddr,
                payer,
                positionId,
                principalAdded,
                amountLent
            );
        }
    }

    function recordPositionIncreased(
        BorrowShared.Tx transaction,
        MarginCommon.Position storage position
    )
        private
    {
        emit PositionIncreased(
            transaction.positionId,
            msg.sender,
            transaction.loanOffering.payer,
            position.owner,
            position.lender,
            transaction.loanOffering.loanHash,
            transaction.loanOffering.feeRecipient,
            transaction.lenderAmount,
            transaction.principal,
            transaction.heldTokenFromSell,
            transaction.depositAmount,
            transaction.depositInHeldToken
        );
    }

     

    function parseIncreasePositionTx(
        MarginCommon.Position storage position,
        bytes32 positionId,
        address[7] addresses,
        uint256[8] values256,
        uint32[2] values32,
        bool depositInHeldToken,
        bytes signature
    )
        private
        view
        returns (BorrowShared.Tx memory)
    {
        uint256 principal = values256[7];

        uint256 lenderAmount = MarginCommon.calculateLenderAmountForIncreasePosition(
            position,
            principal,
            block.timestamp
        );
        assert(lenderAmount >= principal);

        BorrowShared.Tx memory transaction = BorrowShared.Tx({
            positionId: positionId,
            owner: position.owner,
            principal: principal,
            lenderAmount: lenderAmount,
            loanOffering: parseLoanOfferingFromIncreasePositionTx(
                position,
                addresses,
                values256,
                values32,
                signature
            ),
            exchangeWrapper: addresses[6],
            depositInHeldToken: depositInHeldToken,
            depositAmount: 0,  
            collateralAmount: 0,  
            heldTokenFromSell: 0  
        });

        return transaction;
    }

    function parseLoanOfferingFromIncreasePositionTx(
        MarginCommon.Position storage position,
        address[7] addresses,
        uint256[8] values256,
        uint32[2] values32,
        bytes signature
    )
        private
        view
        returns (MarginCommon.LoanOffering memory)
    {
        MarginCommon.LoanOffering memory loanOffering = MarginCommon.LoanOffering({
            owedToken: position.owedToken,
            heldToken: position.heldToken,
            payer: addresses[0],
            owner: position.lender,
            taker: addresses[1],
            positionOwner: addresses[2],
            feeRecipient: addresses[3],
            lenderFeeToken: addresses[4],
            takerFeeToken: addresses[5],
            rates: parseLoanOfferingRatesFromIncreasePositionTx(position, values256),
            expirationTimestamp: values256[5],
            callTimeLimit: values32[0],
            maxDuration: values32[1],
            salt: values256[6],
            loanHash: 0,
            signature: signature
        });

        loanOffering.loanHash = MarginCommon.getLoanOfferingHash(loanOffering);

        return loanOffering;
    }

    function parseLoanOfferingRatesFromIncreasePositionTx(
        MarginCommon.Position storage position,
        uint256[8] values256
    )
        private
        view
        returns (MarginCommon.LoanRates memory)
    {
        MarginCommon.LoanRates memory rates = MarginCommon.LoanRates({
            maxAmount: values256[0],
            minAmount: values256[1],
            minHeldToken: values256[2],
            lenderFee: values256[3],
            takerFee: values256[4],
            interestRate: position.interestRate,
            interestPeriod: position.interestPeriod
        });

        return rates;
    }
}

 

 
contract MarginStorage {

    MarginState.State state;

}

 

 
contract LoanGetters is MarginStorage {

     

     
    function getLoanUnavailableAmount(
        bytes32 loanHash
    )
        external
        view
        returns (uint256)
    {
        return MarginCommon.getUnavailableLoanOfferingAmountImpl(state, loanHash);
    }

     
    function getLoanFilledAmount(
        bytes32 loanHash
    )
        external
        view
        returns (uint256)
    {
        return state.loanFills[loanHash];
    }

     
    function getLoanCanceledAmount(
        bytes32 loanHash
    )
        external
        view
        returns (uint256)
    {
        return state.loanCancels[loanHash];
    }
}

 

 
interface CancelMarginCallDelegator {

     

     
    function cancelMarginCallOnBehalfOf(
        address canceler,
        bytes32 positionId
    )
        external
         
        returns (address);
}

 

 
interface MarginCallDelegator {

     

     
    function marginCallOnBehalfOf(
        address caller,
        bytes32 positionId,
        uint256 depositAmount
    )
        external
         
        returns (address);
}

 

 
library LoanImpl {
    using SafeMath for uint256;

     

     
    event MarginCallInitiated(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 requiredDeposit
    );

     
    event MarginCallCanceled(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 depositAmount
    );

     
    event LoanOfferingCanceled(
        bytes32 indexed loanHash,
        address indexed payer,
        address indexed feeRecipient,
        uint256 cancelAmount
    );

     

    function marginCallImpl(
        MarginState.State storage state,
        bytes32 positionId,
        uint256 requiredDeposit
    )
        public
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            position.callTimestamp == 0,
            "LoanImpl#marginCallImpl: The position has already been margin-called"
        );

         
        marginCallOnBehalfOfRecurse(
            position.lender,
            msg.sender,
            positionId,
            requiredDeposit
        );

        position.callTimestamp = TimestampHelper.getBlockTimestamp32();
        position.requiredDeposit = requiredDeposit;

        emit MarginCallInitiated(
            positionId,
            position.lender,
            position.owner,
            requiredDeposit
        );
    }

    function cancelMarginCallImpl(
        MarginState.State storage state,
        bytes32 positionId
    )
        public
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            position.callTimestamp > 0,
            "LoanImpl#cancelMarginCallImpl: Position has not been margin-called"
        );

         
        cancelMarginCallOnBehalfOfRecurse(
            position.lender,
            msg.sender,
            positionId
        );

        state.positions[positionId].callTimestamp = 0;
        state.positions[positionId].requiredDeposit = 0;

        emit MarginCallCanceled(
            positionId,
            position.lender,
            position.owner,
            0
        );
    }

    function cancelLoanOfferingImpl(
        MarginState.State storage state,
        address[9] addresses,
        uint256[7] values256,
        uint32[4]  values32,
        uint256    cancelAmount
    )
        public
        returns (uint256)
    {
        MarginCommon.LoanOffering memory loanOffering = parseLoanOffering(
            addresses,
            values256,
            values32
        );

        require(
            msg.sender == loanOffering.payer,
            "LoanImpl#cancelLoanOfferingImpl: Only loan offering payer can cancel"
        );
        require(
            loanOffering.expirationTimestamp > block.timestamp,
            "LoanImpl#cancelLoanOfferingImpl: Loan offering has already expired"
        );

        uint256 remainingAmount = loanOffering.rates.maxAmount.sub(
            MarginCommon.getUnavailableLoanOfferingAmountImpl(state, loanOffering.loanHash)
        );
        uint256 amountToCancel = Math.min256(remainingAmount, cancelAmount);

         
        if (amountToCancel == 0) {
            return 0;
        }

        state.loanCancels[loanOffering.loanHash] =
            state.loanCancels[loanOffering.loanHash].add(amountToCancel);

        emit LoanOfferingCanceled(
            loanOffering.loanHash,
            loanOffering.payer,
            loanOffering.feeRecipient,
            amountToCancel
        );

        return amountToCancel;
    }

     

    function marginCallOnBehalfOfRecurse(
        address contractAddr,
        address who,
        bytes32 positionId,
        uint256 requiredDeposit
    )
        private
    {
         
        if (who == contractAddr) {
            return;
        }

        address newContractAddr =
            MarginCallDelegator(contractAddr).marginCallOnBehalfOf(
                msg.sender,
                positionId,
                requiredDeposit
            );

        if (newContractAddr != contractAddr) {
            marginCallOnBehalfOfRecurse(
                newContractAddr,
                who,
                positionId,
                requiredDeposit
            );
        }
    }

    function cancelMarginCallOnBehalfOfRecurse(
        address contractAddr,
        address who,
        bytes32 positionId
    )
        private
    {
         
        if (who == contractAddr) {
            return;
        }

        address newContractAddr =
            CancelMarginCallDelegator(contractAddr).cancelMarginCallOnBehalfOf(
                msg.sender,
                positionId
            );

        if (newContractAddr != contractAddr) {
            cancelMarginCallOnBehalfOfRecurse(
                newContractAddr,
                who,
                positionId
            );
        }
    }

     

    function parseLoanOffering(
        address[9] addresses,
        uint256[7] values256,
        uint32[4]  values32
    )
        private
        view
        returns (MarginCommon.LoanOffering memory)
    {
        MarginCommon.LoanOffering memory loanOffering = MarginCommon.LoanOffering({
            owedToken: addresses[0],
            heldToken: addresses[1],
            payer: addresses[2],
            owner: addresses[3],
            taker: addresses[4],
            positionOwner: addresses[5],
            feeRecipient: addresses[6],
            lenderFeeToken: addresses[7],
            takerFeeToken: addresses[8],
            rates: parseLoanOfferRates(values256, values32),
            expirationTimestamp: values256[5],
            callTimeLimit: values32[0],
            maxDuration: values32[1],
            salt: values256[6],
            loanHash: 0,
            signature: new bytes(0)
        });

        loanOffering.loanHash = MarginCommon.getLoanOfferingHash(loanOffering);

        return loanOffering;
    }

    function parseLoanOfferRates(
        uint256[7] values256,
        uint32[4] values32
    )
        private
        pure
        returns (MarginCommon.LoanRates memory)
    {
        MarginCommon.LoanRates memory rates = MarginCommon.LoanRates({
            maxAmount: values256[0],
            minAmount: values256[1],
            minHeldToken: values256[2],
            interestRate: values32[2],
            lenderFee: values256[3],
            takerFee: values256[4],
            interestPeriod: values32[3]
        });

        return rates;
    }
}

 

 
contract MarginAdmin is Ownable {
     

     
    uint8 private constant OPERATION_STATE_OPERATIONAL = 0;

     
     
    uint8 private constant OPERATION_STATE_CLOSE_AND_CANCEL_LOAN_ONLY = 1;

     
     
    uint8 private constant OPERATION_STATE_CLOSE_ONLY = 2;

     
    uint8 private constant OPERATION_STATE_CLOSE_DIRECTLY_ONLY = 3;

     
    uint8 private constant OPERATION_STATE_INVALID = 4;

     

     
    event OperationStateChanged(
        uint8 from,
        uint8 to
    );

     

    uint8 public operationState;

     

    constructor()
        public
        Ownable()
    {
        operationState = OPERATION_STATE_OPERATIONAL;
    }

     

    modifier onlyWhileOperational() {
        require(
            operationState == OPERATION_STATE_OPERATIONAL,
            "MarginAdmin#onlyWhileOperational: Can only call while operational"
        );
        _;
    }

    modifier cancelLoanOfferingStateControl() {
        require(
            operationState == OPERATION_STATE_OPERATIONAL
            || operationState == OPERATION_STATE_CLOSE_AND_CANCEL_LOAN_ONLY,
            "MarginAdmin#cancelLoanOfferingStateControl: Invalid operation state"
        );
        _;
    }

    modifier closePositionStateControl() {
        require(
            operationState == OPERATION_STATE_OPERATIONAL
            || operationState == OPERATION_STATE_CLOSE_AND_CANCEL_LOAN_ONLY
            || operationState == OPERATION_STATE_CLOSE_ONLY,
            "MarginAdmin#closePositionStateControl: Invalid operation state"
        );
        _;
    }

    modifier closePositionDirectlyStateControl() {
        _;
    }

     

    function setOperationState(
        uint8 newState
    )
        external
        onlyOwner
    {
        require(
            newState < OPERATION_STATE_INVALID,
            "MarginAdmin#setOperationState: newState is not a valid operation state"
        );

        if (newState != operationState) {
            emit OperationStateChanged(
                operationState,
                newState
            );
            operationState = newState;
        }
    }
}

 

 
contract MarginEvents {
     

     
    event PositionOpened(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        bytes32 loanHash,
        address owedToken,
        address heldToken,
        address loanFeeRecipient,
        uint256 principal,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        uint256 interestRate,
        uint32  callTimeLimit,
        uint32  maxDuration,
        bool    depositInHeldToken
    );

     
    event PositionIncreased(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        address positionOwner,
        address loanOwner,
        bytes32 loanHash,
        address loanFeeRecipient,
        uint256 amountBorrowed,
        uint256 principalAdded,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        bool    depositInHeldToken
    );

     
    event PositionClosed(
        bytes32 indexed positionId,
        address indexed closer,
        address indexed payoutRecipient,
        uint256 closeAmount,
        uint256 remainingAmount,
        uint256 owedTokenPaidToLender,
        uint256 payoutAmount,
        uint256 buybackCostInHeldToken,
        bool payoutInHeldToken
    );

     
    event CollateralForceRecovered(
        bytes32 indexed positionId,
        address indexed recipient,
        uint256 amount
    );

     
    event MarginCallInitiated(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 requiredDeposit
    );

     
    event MarginCallCanceled(
        bytes32 indexed positionId,
        address indexed lender,
        address indexed owner,
        uint256 depositAmount
    );

     
    event LoanOfferingCanceled(
        bytes32 indexed loanHash,
        address indexed payer,
        address indexed feeRecipient,
        uint256 cancelAmount
    );

     
    event AdditionalCollateralDeposited(
        bytes32 indexed positionId,
        uint256 amount,
        address depositor
    );

     
    event LoanTransferred(
        bytes32 indexed positionId,
        address indexed from,
        address indexed to
    );

     
    event PositionTransferred(
        bytes32 indexed positionId,
        address indexed from,
        address indexed to
    );
}

 

 
library OpenPositionImpl {
    using SafeMath for uint256;

     

     
    event PositionOpened(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        bytes32 loanHash,
        address owedToken,
        address heldToken,
        address loanFeeRecipient,
        uint256 principal,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        uint256 interestRate,
        uint32  callTimeLimit,
        uint32  maxDuration,
        bool    depositInHeldToken
    );

     

    function openPositionImpl(
        MarginState.State storage state,
        address[11] addresses,
        uint256[10] values256,
        uint32[4] values32,
        bool depositInHeldToken,
        bytes signature,
        bytes orderData
    )
        public
        returns (bytes32)
    {
        BorrowShared.Tx memory transaction = parseOpenTx(
            addresses,
            values256,
            values32,
            depositInHeldToken,
            signature
        );

        require(
            !MarginCommon.positionHasExisted(state, transaction.positionId),
            "OpenPositionImpl#openPositionImpl: positionId already exists"
        );

        doBorrowAndSell(state, transaction, orderData);

         
        recordPositionOpened(
            transaction
        );

        doStoreNewPosition(
            state,
            transaction
        );

        return transaction.positionId;
    }

     

    function doBorrowAndSell(
        MarginState.State storage state,
        BorrowShared.Tx memory transaction,
        bytes orderData
    )
        private
    {
        BorrowShared.validateTxPreSell(state, transaction);

        if (transaction.depositInHeldToken) {
            BorrowShared.doDepositHeldToken(state, transaction);
        } else {
            BorrowShared.doDepositOwedToken(state, transaction);
        }

        transaction.heldTokenFromSell = BorrowShared.doSell(
            state,
            transaction,
            orderData,
            MathHelpers.maxUint256()
        );

        BorrowShared.doPostSell(state, transaction);
    }

    function doStoreNewPosition(
        MarginState.State storage state,
        BorrowShared.Tx memory transaction
    )
        private
    {
        MarginCommon.storeNewPosition(
            state,
            transaction.positionId,
            MarginCommon.Position({
                owedToken: transaction.loanOffering.owedToken,
                heldToken: transaction.loanOffering.heldToken,
                lender: transaction.loanOffering.owner,
                owner: transaction.owner,
                principal: transaction.principal,
                requiredDeposit: 0,
                callTimeLimit: transaction.loanOffering.callTimeLimit,
                startTimestamp: 0,
                callTimestamp: 0,
                maxDuration: transaction.loanOffering.maxDuration,
                interestRate: transaction.loanOffering.rates.interestRate,
                interestPeriod: transaction.loanOffering.rates.interestPeriod
            }),
            transaction.loanOffering.payer
        );
    }

    function recordPositionOpened(
        BorrowShared.Tx transaction
    )
        private
    {
        emit PositionOpened(
            transaction.positionId,
            msg.sender,
            transaction.loanOffering.payer,
            transaction.loanOffering.loanHash,
            transaction.loanOffering.owedToken,
            transaction.loanOffering.heldToken,
            transaction.loanOffering.feeRecipient,
            transaction.principal,
            transaction.heldTokenFromSell,
            transaction.depositAmount,
            transaction.loanOffering.rates.interestRate,
            transaction.loanOffering.callTimeLimit,
            transaction.loanOffering.maxDuration,
            transaction.depositInHeldToken
        );
    }

     

    function parseOpenTx(
        address[11] addresses,
        uint256[10] values256,
        uint32[4] values32,
        bool depositInHeldToken,
        bytes signature
    )
        private
        view
        returns (BorrowShared.Tx memory)
    {
        BorrowShared.Tx memory transaction = BorrowShared.Tx({
            positionId: MarginCommon.getPositionIdFromNonce(values256[9]),
            owner: addresses[0],
            principal: values256[7],
            lenderAmount: values256[7],
            loanOffering: parseLoanOffering(
                addresses,
                values256,
                values32,
                signature
            ),
            exchangeWrapper: addresses[10],
            depositInHeldToken: depositInHeldToken,
            depositAmount: values256[8],
            collateralAmount: 0,  
            heldTokenFromSell: 0  
        });

        return transaction;
    }

    function parseLoanOffering(
        address[11] addresses,
        uint256[10] values256,
        uint32[4]   values32,
        bytes       signature
    )
        private
        view
        returns (MarginCommon.LoanOffering memory)
    {
        MarginCommon.LoanOffering memory loanOffering = MarginCommon.LoanOffering({
            owedToken: addresses[1],
            heldToken: addresses[2],
            payer: addresses[3],
            owner: addresses[4],
            taker: addresses[5],
            positionOwner: addresses[6],
            feeRecipient: addresses[7],
            lenderFeeToken: addresses[8],
            takerFeeToken: addresses[9],
            rates: parseLoanOfferRates(values256, values32),
            expirationTimestamp: values256[5],
            callTimeLimit: values32[0],
            maxDuration: values32[1],
            salt: values256[6],
            loanHash: 0,
            signature: signature
        });

        loanOffering.loanHash = MarginCommon.getLoanOfferingHash(loanOffering);

        return loanOffering;
    }

    function parseLoanOfferRates(
        uint256[10] values256,
        uint32[4] values32
    )
        private
        pure
        returns (MarginCommon.LoanRates memory)
    {
        MarginCommon.LoanRates memory rates = MarginCommon.LoanRates({
            maxAmount: values256[0],
            minAmount: values256[1],
            minHeldToken: values256[2],
            lenderFee: values256[3],
            takerFee: values256[4],
            interestRate: values32[2],
            interestPeriod: values32[3]
        });

        return rates;
    }
}

 

 
library OpenWithoutCounterpartyImpl {

     

    struct Tx {
        bytes32 positionId;
        address positionOwner;
        address owedToken;
        address heldToken;
        address loanOwner;
        uint256 principal;
        uint256 deposit;
        uint32 callTimeLimit;
        uint32 maxDuration;
        uint32 interestRate;
        uint32 interestPeriod;
    }

     

     
    event PositionOpened(
        bytes32 indexed positionId,
        address indexed trader,
        address indexed lender,
        bytes32 loanHash,
        address owedToken,
        address heldToken,
        address loanFeeRecipient,
        uint256 principal,
        uint256 heldTokenFromSell,
        uint256 depositAmount,
        uint256 interestRate,
        uint32  callTimeLimit,
        uint32  maxDuration,
        bool    depositInHeldToken
    );

     

    function openWithoutCounterpartyImpl(
        MarginState.State storage state,
        address[4] addresses,
        uint256[3] values256,
        uint32[4]  values32
    )
        public
        returns (bytes32)
    {
        Tx memory openTx = parseTx(
            addresses,
            values256,
            values32
        );

        validate(
            state,
            openTx
        );

        Vault(state.VAULT).transferToVault(
            openTx.positionId,
            openTx.heldToken,
            msg.sender,
            openTx.deposit
        );

        recordPositionOpened(
            openTx
        );

        doStoreNewPosition(
            state,
            openTx
        );

        return openTx.positionId;
    }

     

    function doStoreNewPosition(
        MarginState.State storage state,
        Tx memory openTx
    )
        private
    {
        MarginCommon.storeNewPosition(
            state,
            openTx.positionId,
            MarginCommon.Position({
                owedToken: openTx.owedToken,
                heldToken: openTx.heldToken,
                lender: openTx.loanOwner,
                owner: openTx.positionOwner,
                principal: openTx.principal,
                requiredDeposit: 0,
                callTimeLimit: openTx.callTimeLimit,
                startTimestamp: 0,
                callTimestamp: 0,
                maxDuration: openTx.maxDuration,
                interestRate: openTx.interestRate,
                interestPeriod: openTx.interestPeriod
            }),
            msg.sender
        );
    }

    function validate(
        MarginState.State storage state,
        Tx memory openTx
    )
        private
        view
    {
        require(
            !MarginCommon.positionHasExisted(state, openTx.positionId),
            "openWithoutCounterpartyImpl#validate: positionId already exists"
        );

        require(
            openTx.principal > 0,
            "openWithoutCounterpartyImpl#validate: principal cannot be 0"
        );

        require(
            openTx.owedToken != address(0),
            "openWithoutCounterpartyImpl#validate: owedToken cannot be 0"
        );

        require(
            openTx.owedToken != openTx.heldToken,
            "openWithoutCounterpartyImpl#validate: owedToken cannot be equal to heldToken"
        );

        require(
            openTx.positionOwner != address(0),
            "openWithoutCounterpartyImpl#validate: positionOwner cannot be 0"
        );

        require(
            openTx.loanOwner != address(0),
            "openWithoutCounterpartyImpl#validate: loanOwner cannot be 0"
        );

        require(
            openTx.maxDuration > 0,
            "openWithoutCounterpartyImpl#validate: maxDuration cannot be 0"
        );

        require(
            openTx.interestPeriod <= openTx.maxDuration,
            "openWithoutCounterpartyImpl#validate: interestPeriod must be <= maxDuration"
        );
    }

    function recordPositionOpened(
        Tx memory openTx
    )
        private
    {
        emit PositionOpened(
            openTx.positionId,
            msg.sender,
            msg.sender,
            bytes32(0),
            openTx.owedToken,
            openTx.heldToken,
            address(0),
            openTx.principal,
            0,
            openTx.deposit,
            openTx.interestRate,
            openTx.callTimeLimit,
            openTx.maxDuration,
            true
        );
    }

     

    function parseTx(
        address[4] addresses,
        uint256[3] values256,
        uint32[4]  values32
    )
        private
        view
        returns (Tx memory)
    {
        Tx memory openTx = Tx({
            positionId: MarginCommon.getPositionIdFromNonce(values256[2]),
            positionOwner: addresses[0],
            owedToken: addresses[1],
            heldToken: addresses[2],
            loanOwner: addresses[3],
            principal: values256[0],
            deposit: values256[1],
            callTimeLimit: values32[0],
            maxDuration: values32[1],
            interestRate: values32[2],
            interestPeriod: values32[3]
        });

        return openTx;
    }
}

 

 
contract PositionGetters is MarginStorage {
    using SafeMath for uint256;

     

     
    function containsPosition(
        bytes32 positionId
    )
        external
        view
        returns (bool)
    {
        return MarginCommon.containsPositionImpl(state, positionId);
    }

     
    function isPositionCalled(
        bytes32 positionId
    )
        external
        view
        returns (bool)
    {
        return (state.positions[positionId].callTimestamp > 0);
    }

     
    function isPositionClosed(
        bytes32 positionId
    )
        external
        view
        returns (bool)
    {
        return state.closedPositions[positionId];
    }

     
    function getTotalOwedTokenRepaidToLender(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return state.totalOwedTokenRepaidToLender[positionId];
    }

     
    function getPositionBalance(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return MarginCommon.getPositionBalanceImpl(state, positionId);
    }

     
    function getTimeUntilInterestIncrease(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        uint256 effectiveTimeElapsed = MarginCommon.calculateEffectiveTimeElapsed(
            position,
            block.timestamp
        );

        uint256 absoluteTimeElapsed = block.timestamp.sub(position.startTimestamp);
        if (absoluteTimeElapsed > effectiveTimeElapsed) {  
            return 0;
        } else {
             
             
            return effectiveTimeElapsed.add(1).sub(absoluteTimeElapsed);
        }
    }

     
    function getPositionOwedAmount(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        return MarginCommon.calculateOwedAmount(
            position,
            position.principal,
            block.timestamp
        );
    }

     
    function getPositionOwedAmountAtTime(
        bytes32 positionId,
        uint256 principalToClose,
        uint32  timestamp
    )
        external
        view
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            timestamp >= position.startTimestamp,
            "PositionGetters#getPositionOwedAmountAtTime: Requested time before position started"
        );

        return MarginCommon.calculateOwedAmount(
            position,
            principalToClose,
            timestamp
        );
    }

     
    function getLenderAmountForIncreasePositionAtTime(
        bytes32 positionId,
        uint256 principalToAdd,
        uint32  timestamp
    )
        external
        view
        returns (uint256)
    {
        MarginCommon.Position storage position =
            MarginCommon.getPositionFromStorage(state, positionId);

        require(
            timestamp >= position.startTimestamp,
            "PositionGetters#getLenderAmountForIncreasePositionAtTime: timestamp < position start"
        );

        return MarginCommon.calculateLenderAmountForIncreasePosition(
            position,
            principalToAdd,
            timestamp
        );
    }

     

     
    function getPosition(
        bytes32 positionId
    )
        external
        view
        returns (
            address[4],
            uint256[2],
            uint32[6]
        )
    {
        MarginCommon.Position storage position = state.positions[positionId];

        return (
            [
                position.owedToken,
                position.heldToken,
                position.lender,
                position.owner
            ],
            [
                position.principal,
                position.requiredDeposit
            ],
            [
                position.callTimeLimit,
                position.startTimestamp,
                position.callTimestamp,
                position.maxDuration,
                position.interestRate,
                position.interestPeriod
            ]
        );
    }

     

    function getPositionLender(
        bytes32 positionId
    )
        external
        view
        returns (address)
    {
        return state.positions[positionId].lender;
    }

    function getPositionOwner(
        bytes32 positionId
    )
        external
        view
        returns (address)
    {
        return state.positions[positionId].owner;
    }

    function getPositionHeldToken(
        bytes32 positionId
    )
        external
        view
        returns (address)
    {
        return state.positions[positionId].heldToken;
    }

    function getPositionOwedToken(
        bytes32 positionId
    )
        external
        view
        returns (address)
    {
        return state.positions[positionId].owedToken;
    }

    function getPositionPrincipal(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return state.positions[positionId].principal;
    }

    function getPositionInterestRate(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return state.positions[positionId].interestRate;
    }

    function getPositionRequiredDeposit(
        bytes32 positionId
    )
        external
        view
        returns (uint256)
    {
        return state.positions[positionId].requiredDeposit;
    }

    function getPositionStartTimestamp(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].startTimestamp;
    }

    function getPositionCallTimestamp(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].callTimestamp;
    }

    function getPositionCallTimeLimit(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].callTimeLimit;
    }

    function getPositionMaxDuration(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].maxDuration;
    }

    function getPositioninterestPeriod(
        bytes32 positionId
    )
        external
        view
        returns (uint32)
    {
        return state.positions[positionId].interestPeriod;
    }
}

 

 
library TransferImpl {

     

    function transferLoanImpl(
        MarginState.State storage state,
        bytes32 positionId,
        address newLender
    )
        public
    {
        require(
            MarginCommon.containsPositionImpl(state, positionId),
            "TransferImpl#transferLoanImpl: Position does not exist"
        );

        address originalLender = state.positions[positionId].lender;

        require(
            msg.sender == originalLender,
            "TransferImpl#transferLoanImpl: Only lender can transfer ownership"
        );
        require(
            newLender != originalLender,
            "TransferImpl#transferLoanImpl: Cannot transfer ownership to self"
        );

         
         
        address finalLender = TransferInternal.grantLoanOwnership(
            positionId,
            originalLender,
            newLender);

        require(
            finalLender != originalLender,
            "TransferImpl#transferLoanImpl: Cannot ultimately transfer ownership to self"
        );

         
        state.positions[positionId].lender = finalLender;
    }

    function transferPositionImpl(
        MarginState.State storage state,
        bytes32 positionId,
        address newOwner
    )
        public
    {
        require(
            MarginCommon.containsPositionImpl(state, positionId),
            "TransferImpl#transferPositionImpl: Position does not exist"
        );

        address originalOwner = state.positions[positionId].owner;

        require(
            msg.sender == originalOwner,
            "TransferImpl#transferPositionImpl: Only position owner can transfer ownership"
        );
        require(
            newOwner != originalOwner,
            "TransferImpl#transferPositionImpl: Cannot transfer ownership to self"
        );

         
         
        address finalOwner = TransferInternal.grantPositionOwnership(
            positionId,
            originalOwner,
            newOwner);

        require(
            finalOwner != originalOwner,
            "TransferImpl#transferPositionImpl: Cannot ultimately transfer ownership to self"
        );

         
        state.positions[positionId].owner = finalOwner;
    }
}

 

 
contract Margin is
    ReentrancyGuard,
    MarginStorage,
    MarginEvents,
    MarginAdmin,
    LoanGetters,
    PositionGetters
{

    using SafeMath for uint256;

     

    constructor(
        address vault,
        address proxy
    )
        public
        MarginAdmin()
    {
        state = MarginState.State({
            VAULT: vault,
            TOKEN_PROXY: proxy
        });
    }

     

     
    function openPosition(
        address[11] addresses,
        uint256[10] values256,
        uint32[4]   values32,
        bool        depositInHeldToken,
        bytes       signature,
        bytes       order
    )
        external
        onlyWhileOperational
        nonReentrant
        returns (bytes32)
    {
        return OpenPositionImpl.openPositionImpl(
            state,
            addresses,
            values256,
            values32,
            depositInHeldToken,
            signature,
            order
        );
    }

     
    function openWithoutCounterparty(
        address[4] addresses,
        uint256[3] values256,
        uint32[4]  values32
    )
        external
        onlyWhileOperational
        nonReentrant
        returns (bytes32)
    {
        return OpenWithoutCounterpartyImpl.openWithoutCounterpartyImpl(
            state,
            addresses,
            values256,
            values32
        );
    }

     
    function increasePosition(
        bytes32    positionId,
        address[7] addresses,
        uint256[8] values256,
        uint32[2]  values32,
        bool       depositInHeldToken,
        bytes      signature,
        bytes      order
    )
        external
        onlyWhileOperational
        nonReentrant
        returns (uint256)
    {
        return IncreasePositionImpl.increasePositionImpl(
            state,
            positionId,
            addresses,
            values256,
            values32,
            depositInHeldToken,
            signature,
            order
        );
    }

     
    function increaseWithoutCounterparty(
        bytes32 positionId,
        uint256 principalToAdd
    )
        external
        onlyWhileOperational
        nonReentrant
        returns (uint256)
    {
        return IncreasePositionImpl.increaseWithoutCounterpartyImpl(
            state,
            positionId,
            principalToAdd
        );
    }

     
    function closePosition(
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient,
        address exchangeWrapper,
        bool    payoutInHeldToken,
        bytes   order
    )
        external
        closePositionStateControl
        nonReentrant
        returns (uint256, uint256, uint256)
    {
        return ClosePositionImpl.closePositionImpl(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient,
            exchangeWrapper,
            payoutInHeldToken,
            order
        );
    }

     
    function closePositionDirectly(
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient
    )
        external
        closePositionDirectlyStateControl
        nonReentrant
        returns (uint256, uint256, uint256)
    {
        return ClosePositionImpl.closePositionImpl(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient,
            address(0),
            true,
            new bytes(0)
        );
    }

     
    function closeWithoutCounterparty(
        bytes32 positionId,
        uint256 requestedCloseAmount,
        address payoutRecipient
    )
        external
        closePositionStateControl
        nonReentrant
        returns (uint256, uint256)
    {
        return CloseWithoutCounterpartyImpl.closeWithoutCounterpartyImpl(
            state,
            positionId,
            requestedCloseAmount,
            payoutRecipient
        );
    }

     
    function marginCall(
        bytes32 positionId,
        uint256 requiredDeposit
    )
        external
        nonReentrant
    {
        LoanImpl.marginCallImpl(
            state,
            positionId,
            requiredDeposit
        );
    }

     
    function cancelMarginCall(
        bytes32 positionId
    )
        external
        onlyWhileOperational
        nonReentrant
    {
        LoanImpl.cancelMarginCallImpl(state, positionId);
    }

     
    function forceRecoverCollateral(
        bytes32 positionId,
        address recipient
    )
        external
        nonReentrant
        returns (uint256)
    {
        return ForceRecoverCollateralImpl.forceRecoverCollateralImpl(
            state,
            positionId,
            recipient
        );
    }

     
    function depositCollateral(
        bytes32 positionId,
        uint256 depositAmount
    )
        external
        onlyWhileOperational
        nonReentrant
    {
        DepositCollateralImpl.depositCollateralImpl(
            state,
            positionId,
            depositAmount
        );
    }

     
    function cancelLoanOffering(
        address[9] addresses,
        uint256[7]  values256,
        uint32[4]   values32,
        uint256     cancelAmount
    )
        external
        cancelLoanOfferingStateControl
        nonReentrant
        returns (uint256)
    {
        return LoanImpl.cancelLoanOfferingImpl(
            state,
            addresses,
            values256,
            values32,
            cancelAmount
        );
    }

     
    function transferLoan(
        bytes32 positionId,
        address who
    )
        external
        nonReentrant
    {
        TransferImpl.transferLoanImpl(
            state,
            positionId,
            who);
    }

     
    function transferPosition(
        bytes32 positionId,
        address who
    )
        external
        nonReentrant
    {
        TransferImpl.transferPositionImpl(
            state,
            positionId,
            who);
    }

     

     
    function getVaultAddress()
        external
        view
        returns (address)
    {
        return state.VAULT;
    }

     
    function getTokenProxyAddress()
        external
        view
        returns (address)
    {
        return state.TOKEN_PROXY;
    }
}

 

 
contract OnlyMargin {

     

     
    address public DYDX_MARGIN;

     

    constructor(
        address margin
    )
        public
    {
        DYDX_MARGIN = margin;
    }

     

    modifier onlyMargin()
    {
        require(
            msg.sender == DYDX_MARGIN,
            "OnlyMargin#onlyMargin: Only Margin can call"
        );

        _;
    }
}

 

 
interface PositionCustodian {

     
    function getPositionDeedHolder(
        bytes32 positionId
    )
        external
        view
        returns (address);
}

 

 
library MarginHelper {
    function getPosition(
        address DYDX_MARGIN,
        bytes32 positionId
    )
        internal
        view
        returns (MarginCommon.Position memory)
    {
        (
            address[4] memory addresses,
            uint256[2] memory values256,
            uint32[6]  memory values32
        ) = Margin(DYDX_MARGIN).getPosition(positionId);

        return MarginCommon.Position({
            owedToken: addresses[0],
            heldToken: addresses[1],
            lender: addresses[2],
            owner: addresses[3],
            principal: values256[0],
            requiredDeposit: values256[1],
            callTimeLimit: values32[0],
            startTimestamp: values32[1],
            callTimestamp: values32[2],
            maxDuration: values32[3],
            interestRate: values32[4],
            interestPeriod: values32[5]
        });
    }
}

 

 
contract ERC20Position is
    ReentrancyGuard,
    StandardToken,
    OnlyMargin,
    PositionOwner,
    IncreasePositionDelegator,
    ClosePositionDelegator,
    PositionCustodian
{
    using SafeMath for uint256;

     

    enum State {
        UNINITIALIZED,
        OPEN,
        CLOSED
    }

     

     
    event Initialized(
        bytes32 positionId,
        uint256 initialSupply
    );

     
    event ClosedByTrustedParty(
        address closer,
        uint256 tokenAmount,
        address payoutRecipient
    );

     
    event CompletelyClosed();

     
    event Withdraw(
        address indexed redeemer,
        uint256 tokensRedeemed,
        uint256 heldTokenPayout
    );

     
    event Close(
        address indexed redeemer,
        uint256 closeAmount
    );

     

     
    address public INITIAL_TOKEN_HOLDER;

     
    bytes32 public POSITION_ID;

     
    mapping (address => bool) public TRUSTED_RECIPIENTS;

     
    mapping (address => bool) public TRUSTED_WITHDRAWERS;

     
    State public state;

     
    address public heldToken;

     
    bool public closedUsingTrustedRecipient;

     

    modifier onlyPosition(bytes32 positionId) {
        require(
            POSITION_ID == positionId,
            "ERC20Position#onlyPosition: Incorrect position"
        );
        _;
    }

    modifier onlyState(State specificState) {
        require(
            state == specificState,
            "ERC20Position#onlyState: Incorrect State"
        );
        _;
    }

     

    constructor(
        bytes32 positionId,
        address margin,
        address initialTokenHolder,
        address[] trustedRecipients,
        address[] trustedWithdrawers
    )
        public
        OnlyMargin(margin)
    {
        POSITION_ID = positionId;
        state = State.UNINITIALIZED;
        INITIAL_TOKEN_HOLDER = initialTokenHolder;
        closedUsingTrustedRecipient = false;

        uint256 i;
        for (i = 0; i < trustedRecipients.length; i++) {
            TRUSTED_RECIPIENTS[trustedRecipients[i]] = true;
        }
        for (i = 0; i < trustedWithdrawers.length; i++) {
            TRUSTED_WITHDRAWERS[trustedWithdrawers[i]] = true;
        }
    }

     

     
    function receivePositionOwnership(
        address  ,
        bytes32 positionId
    )
        external
        onlyMargin
        nonReentrant
        onlyState(State.UNINITIALIZED)
        onlyPosition(positionId)
        returns (address)
    {
        MarginCommon.Position memory position = MarginHelper.getPosition(DYDX_MARGIN, POSITION_ID);
        assert(position.principal > 0);

         
        state = State.OPEN;
        heldToken = position.heldToken;

        uint256 tokenAmount = getTokenAmountOnAdd(position.principal);

        emit Initialized(POSITION_ID, tokenAmount);

        mint(INITIAL_TOKEN_HOLDER, tokenAmount);

        return address(this);  
    }

     
    function increasePositionOnBehalfOf(
        address trader,
        bytes32 positionId,
        uint256 principalAdded
    )
        external
        onlyMargin
        nonReentrant
        onlyState(State.OPEN)
        onlyPosition(positionId)
        returns (address)
    {
        require(
            !Margin(DYDX_MARGIN).isPositionCalled(POSITION_ID),
            "ERC20Position#increasePositionOnBehalfOf: Position is margin-called"
        );
        require(
            !closedUsingTrustedRecipient,
            "ERC20Position#increasePositionOnBehalfOf: Position closed using trusted recipient"
        );

        uint256 tokenAmount = getTokenAmountOnAdd(principalAdded);

        mint(trader, tokenAmount);

        return address(this);
    }

     
    function closeOnBehalfOf(
        address closer,
        address payoutRecipient,
        bytes32 positionId,
        uint256 requestedAmount
    )
        external
        onlyMargin
        nonReentrant
        onlyState(State.OPEN)
        onlyPosition(positionId)
        returns (address, uint256)
    {
        uint256 positionPrincipal = Margin(DYDX_MARGIN).getPositionPrincipal(positionId);

        assert(requestedAmount <= positionPrincipal);

        uint256 allowedAmount;
        if (TRUSTED_RECIPIENTS[payoutRecipient]) {
            allowedAmount = closeUsingTrustedRecipient(
                closer,
                payoutRecipient,
                requestedAmount
            );
        } else {
            allowedAmount = close(
                closer,
                requestedAmount,
                positionPrincipal
            );
        }

        assert(allowedAmount > 0);
        assert(allowedAmount <= requestedAmount);

        if (allowedAmount == positionPrincipal) {
            state = State.CLOSED;
            emit CompletelyClosed();
        }

        return (address(this), allowedAmount);
    }

     

     
    function withdraw(
        address onBehalfOf
    )
        external
        nonReentrant
        returns (uint256)
    {
        setStateClosedIfClosed();
        require(
            state == State.CLOSED,
            "ERC20Position#withdraw: Position has not yet been closed"
        );

        if (msg.sender != onBehalfOf) {
            require(
                TRUSTED_WITHDRAWERS[msg.sender],
                "ERC20Position#withdraw: Only trusted withdrawers can withdraw on behalf of others"
            );
        }

        return withdrawImpl(msg.sender, onBehalfOf);
    }

     

     
    function decimals()
        external
        view
        returns (uint8);

     
    function symbol()
        external
        view
        returns (string);

     
    function getPositionDeedHolder(
        bytes32 positionId
    )
        external
        view
        onlyPosition(positionId)
        returns (address)
    {
         
        return address(this);
    }

     

     
    function closeUsingTrustedRecipient(
        address closer,
        address payoutRecipient,
        uint256 requestedAmount
    )
        internal
        returns (uint256)
    {
        assert(requestedAmount > 0);

         
        if (!closedUsingTrustedRecipient) {
            closedUsingTrustedRecipient = true;
        }

        emit ClosedByTrustedParty(closer, requestedAmount, payoutRecipient);

        return requestedAmount;
    }

     

    function withdrawImpl(
        address receiver,
        address onBehalfOf
    )
        private
        returns (uint256)
    {
        uint256 value = balanceOf(onBehalfOf);

        if (value == 0) {
            return 0;
        }

        uint256 heldTokenBalance = TokenInteract.balanceOf(heldToken, address(this));

         
        uint256 heldTokenPayout = MathHelpers.getPartialAmount(
            value,
            totalSupply_,
            heldTokenBalance
        );

         
        burn(onBehalfOf, value);
        emit Withdraw(onBehalfOf, value, heldTokenPayout);

         
        TokenInteract.transfer(heldToken, receiver, heldTokenPayout);

        return heldTokenPayout;
    }

    function setStateClosedIfClosed(
    )
        private
    {
         
        if (state == State.OPEN && Margin(DYDX_MARGIN).isPositionClosed(POSITION_ID)) {
            state = State.CLOSED;
            emit CompletelyClosed();
        }
    }

    function close(
        address closer,
        uint256 requestedAmount,
        uint256 positionPrincipal
    )
        private
        returns (uint256)
    {
        uint256 balance = balances[closer];

        (
            uint256 tokenAmount,
            uint256 allowedCloseAmount
        ) = getCloseAmounts(
            requestedAmount,
            balance,
            positionPrincipal
        );

        require(
            tokenAmount > 0 && allowedCloseAmount > 0,
            "ERC20Position#close: Cannot close 0 amount"
        );

        assert(allowedCloseAmount <= requestedAmount);

        burn(closer, tokenAmount);

        emit Close(closer, tokenAmount);

        return allowedCloseAmount;
    }

    function burn(
        address from,
        uint256 amount
    )
        private
    {
        assert(from != address(0));
        totalSupply_ = totalSupply_.sub(amount);
        balances[from] = balances[from].sub(amount);
        emit Transfer(from, address(0), amount);
    }

    function mint(
        address to,
        uint256 amount
    )
        private
    {
        assert(to != address(0));
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(address(0), to, amount);
    }

     

    function getTokenAmountOnAdd(
        uint256 principalAdded
    )
        internal
        view
        returns (uint256);

    function getCloseAmounts(
        uint256 requestedCloseAmount,
        uint256 balance,
        uint256 positionPrincipal
    )
        private
        view
        returns (
            uint256  ,
            uint256  
        );
}

 

 
contract ERC20PositionWithdrawerV2
{
    using TokenInteract for address;

     

    address public WETH;

     

    constructor(
        address weth
    )
        public
    {
        WETH = weth;
    }

     

     
    function ()
        external
        payable
    {
        require(  
            msg.sender == WETH,
            "PayableMarginMinter#fallback: Cannot recieve ETH directly unless unwrapping WETH"
        );
    }

     
    function withdraw(
        address erc20Position,
        address returnedToken,
        address exchangeWrapper,
        bytes orderData
    )
        external
        returns (uint256, uint256)
    {
         
        uint256 tokensWithdrawn = ERC20Position(erc20Position).withdraw(msg.sender);
        if (tokensWithdrawn == 0) {
            return (0, 0);
        }

         
        address withdrawnToken = ERC20Position(erc20Position).heldToken();
        withdrawnToken.transfer(exchangeWrapper, tokensWithdrawn);
        uint256 tokensReturned = ExchangeWrapper(exchangeWrapper).exchange(
            msg.sender,
            address(this),
            returnedToken,
            withdrawnToken,
            tokensWithdrawn,
            orderData
        );

         
        if (returnedToken == WETH) {
             
            returnedToken.transferFrom(exchangeWrapper, address(this), tokensReturned);
            WETH9(returnedToken).withdraw(tokensReturned);
            msg.sender.transfer(tokensReturned);
        } else {
             
            returnedToken.transferFrom(exchangeWrapper, msg.sender, tokensReturned);
        }

        return (tokensWithdrawn, tokensReturned);
    }

     
    function withdrawAsEth(
        address erc20Position
    )
        external
        returns (uint256)
    {
         
        address token = ERC20Position(erc20Position).heldToken();
        require(
            token == WETH,
            "ERC20PositionWithdrawer#withdrawAsEth: Withdrawn token must be WETH"
        );

         
        uint256 amount = ERC20Position(erc20Position).withdraw(msg.sender);
        WETH9(token).withdraw(amount);
        msg.sender.transfer(amount);

        return amount;
    }
}