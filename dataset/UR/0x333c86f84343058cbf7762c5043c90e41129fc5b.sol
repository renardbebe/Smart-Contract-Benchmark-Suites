 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
    if (_subtractedValue > oldValue) {
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

 

 

  

   

 

 
contract Power {
  string public version = "0.3";

  uint256 private constant ONE = 1;
  uint32 private constant MAX_WEIGHT = 1000000;
  uint8 private constant MIN_PRECISION = 32;
  uint8 private constant MAX_PRECISION = 127;

   
  uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
  uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
  uint256 private constant MAX_NUM = 0x1ffffffffffffffffffffffffffffffff;

   
  uint256 private constant LN2_MANTISSA = 0x2c5c85fdf473de6af278ece600fcbda;
  uint8   private constant LN2_EXPONENT = 122;

   
  uint256[128] private maxExpArray;

  constructor() public {
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
    maxExpArray[ 32] = 0x1c35fedd14ffffffffffffffffffffffff;
    maxExpArray[ 33] = 0x1b0ce43b323fffffffffffffffffffffff;
    maxExpArray[ 34] = 0x19f0028ec1ffffffffffffffffffffffff;
    maxExpArray[ 35] = 0x18ded91f0e7fffffffffffffffffffffff;
    maxExpArray[ 36] = 0x17d8ec7f0417ffffffffffffffffffffff;
    maxExpArray[ 37] = 0x16ddc6556cdbffffffffffffffffffffff;
    maxExpArray[ 38] = 0x15ecf52776a1ffffffffffffffffffffff;
    maxExpArray[ 39] = 0x15060c256cb2ffffffffffffffffffffff;
    maxExpArray[ 40] = 0x1428a2f98d72ffffffffffffffffffffff;
    maxExpArray[ 41] = 0x13545598e5c23fffffffffffffffffffff;
    maxExpArray[ 42] = 0x1288c4161ce1dfffffffffffffffffffff;
    maxExpArray[ 43] = 0x11c592761c666fffffffffffffffffffff;
    maxExpArray[ 44] = 0x110a688680a757ffffffffffffffffffff;
    maxExpArray[ 45] = 0x1056f1b5bedf77ffffffffffffffffffff;
    maxExpArray[ 46] = 0x0faadceceeff8bffffffffffffffffffff;
    maxExpArray[ 47] = 0x0f05dc6b27edadffffffffffffffffffff;
    maxExpArray[ 48] = 0x0e67a5a25da4107fffffffffffffffffff;
    maxExpArray[ 49] = 0x0dcff115b14eedffffffffffffffffffff;
    maxExpArray[ 50] = 0x0d3e7a392431239fffffffffffffffffff;
    maxExpArray[ 51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
    maxExpArray[ 52] = 0x0c2d415c3db974afffffffffffffffffff;
    maxExpArray[ 53] = 0x0bad03e7d883f69bffffffffffffffffff;
    maxExpArray[ 54] = 0x0b320d03b2c343d5ffffffffffffffffff;
    maxExpArray[ 55] = 0x0abc25204e02828dffffffffffffffffff;
    maxExpArray[ 56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
    maxExpArray[ 57] = 0x09deaf736ac1f569ffffffffffffffffff;
    maxExpArray[ 58] = 0x0976bd9952c7aa957fffffffffffffffff;
    maxExpArray[ 59] = 0x09131271922eaa606fffffffffffffffff;
    maxExpArray[ 60] = 0x08b380f3558668c46fffffffffffffffff;
    maxExpArray[ 61] = 0x0857ddf0117efa215bffffffffffffffff;
    maxExpArray[ 62] = 0x07ffffffffffffffffffffffffffffffff;
    maxExpArray[ 63] = 0x07abbf6f6abb9d087fffffffffffffffff;
    maxExpArray[ 64] = 0x075af62cbac95f7dfa7fffffffffffffff;
    maxExpArray[ 65] = 0x070d7fb7452e187ac13fffffffffffffff;
    maxExpArray[ 66] = 0x06c3390ecc8af379295fffffffffffffff;
    maxExpArray[ 67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
    maxExpArray[ 68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
    maxExpArray[ 69] = 0x05f63b1fc104dbd39587ffffffffffffff;
    maxExpArray[ 70] = 0x05b771955b36e12f7235ffffffffffffff;
    maxExpArray[ 71] = 0x057b3d49dda84556d6f6ffffffffffffff;
    maxExpArray[ 72] = 0x054183095b2c8ececf30ffffffffffffff;
    maxExpArray[ 73] = 0x050a28be635ca2b888f77fffffffffffff;
    maxExpArray[ 74] = 0x04d5156639708c9db33c3fffffffffffff;
    maxExpArray[ 75] = 0x04a23105873875bd52dfdfffffffffffff;
    maxExpArray[ 76] = 0x0471649d87199aa990756fffffffffffff;
    maxExpArray[ 77] = 0x04429a21a029d4c1457cfbffffffffffff;
    maxExpArray[ 78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
    maxExpArray[ 79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
    maxExpArray[ 80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
    maxExpArray[ 81] = 0x0399e96897690418f785257fffffffffff;
    maxExpArray[ 82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
    maxExpArray[ 83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
    maxExpArray[ 84] = 0x032cbfd4a7adc790560b3337ffffffffff;
    maxExpArray[ 85] = 0x030b50570f6e5d2acca94613ffffffffff;
    maxExpArray[ 86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
    maxExpArray[ 87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
    maxExpArray[ 88] = 0x02af09481380a0a35cf1ba02ffffffffff;
    maxExpArray[ 89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
    maxExpArray[ 90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
    maxExpArray[ 91] = 0x025daf6654b1eaa55fd64df5efffffffff;
    maxExpArray[ 92] = 0x0244c49c648baa98192dce88b7ffffffff;
    maxExpArray[ 93] = 0x022ce03cd5619a311b2471268bffffffff;
    maxExpArray[ 94] = 0x0215f77c045fbe885654a44a0fffffffff;
    maxExpArray[ 95] = 0x01ffffffffffffffffffffffffffffffff;
    maxExpArray[ 96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
    maxExpArray[ 97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
    maxExpArray[ 98] = 0x01c35fedd14b861eb0443f7f133fffffff;
    maxExpArray[ 99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
    maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
    maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
    maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
    maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
    maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
    maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
    maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
    maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
    maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
    maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
    maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
    maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
    maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
    maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
    maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
    maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
    maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
    maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
    maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
    maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
    maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
    maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
    maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
    maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
    maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
    maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
    maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
    maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
  }


   
  function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal constant returns (uint256, uint8) {
    uint256 lnBaseTimesExp = ln(_baseN, _baseD) * _expN / _expD;
    uint8 precision = findPositionInMaxExpArray(lnBaseTimesExp);
    return (fixedExp(lnBaseTimesExp >> (MAX_PRECISION - precision), precision), precision);
  }

   
  function ln(uint256 _numerator, uint256 _denominator) internal constant returns (uint256) {
    assert(_numerator <= MAX_NUM);

    uint256 res = 0;
    uint256 x = _numerator * FIXED_1 / _denominator;

     
    if (x >= FIXED_2) {
      uint8 count = floorLog2(x / FIXED_1);
      x >>= count;  
      res = count * FIXED_1;
    }

     
    if (x > FIXED_1) {
      for (uint8 i = MAX_PRECISION; i > 0; --i) {
        x = (x * x) / FIXED_1;  
        if (x >= FIXED_2) {
          x >>= 1;  
          res += ONE << (i - 1);
        }
      }
    }

    return (res * LN2_MANTISSA) >> LN2_EXPONENT;
  }

   
  function floorLog2(uint256 _n) internal constant returns (uint8) {
    uint8 res = 0;
    uint256 n = _n;

    if (n < 256) {
       
      while (n > 1) {
        n >>= 1;
        res += 1;
      }
    } else {
       
      for (uint8 s = 128; s > 0; s >>= 1) {
        if (n >= (ONE << s)) {
          n >>= s;
          res |= s;
        }
      }
    }

    return res;
  }

   
  function findPositionInMaxExpArray(uint256 _x) internal constant returns (uint8) {
    uint8 lo = MIN_PRECISION;
    uint8 hi = MAX_PRECISION;

    while (lo + 1 < hi) {
      uint8 mid = (lo + hi) / 2;
      if (maxExpArray[mid] >= _x)
        lo = mid;
      else
        hi = mid;
    }

    if (maxExpArray[hi] >= _x)
        return hi;
    if (maxExpArray[lo] >= _x)
        return lo;

    assert(false);
    return 0;
  }

   
  function fixedExp(uint256 _x, uint8 _precision) internal constant returns (uint256) {
    uint256 xi = _x;
    uint256 res = 0;

    xi = (xi * _x) >> _precision;
    res += xi * 0x03442c4e6074a82f1797f72ac0000000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0116b96f757c380fb287fd0e40000000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0045ae5bdd5f0e03eca1ff4390000000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000defabf91302cd95b9ffda50000000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0002529ca9832b22439efff9b8000000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000054f1cf12bd04e516b6da88000000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000a9e39e257a09ca2d6db51000000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000012e066e7b839fa050c309000000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000001e33d7d926c329a1ad1a800000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000002bee513bdb4a6b19b5f800000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000003a9316fa79b88eccf2a00000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000048177ebe1fa812375200000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000005263fe90242dcbacf00000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000057e22099c030d94100000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000057e22099c030d9410000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000052b6b54569976310000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000004985f67696bf748000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000003dea12ea99e498000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000031880f2214b6e000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000025bcff56eb36000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000001b722e10ab1000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000001317c70077000;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000cba84aafa00;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000082573a0a00;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000005035ad900;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000000000002f881b00;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000001b29340;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000000000efc40;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000007fe0;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000420;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000021;  
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000001;  

    return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision);  
  }
}

 

 
contract BancorFormula is Power {
  using SafeMath for uint256;

  string public version = "0.3";
  uint32 private constant MAX_WEIGHT = 1000000;

   
  function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public constant returns (uint256) {
     
    require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT);

     
    if (_depositAmount == 0)
      return 0;

     
    if (_connectorWeight == MAX_WEIGHT)
      return _supply.mul(_depositAmount).div(_connectorBalance);

    uint256 result;
    uint8 precision;
    uint256 baseN = _depositAmount.add(_connectorBalance);
    (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
    uint256 temp = _supply.mul(result) >> precision;
    return temp - _supply;
  }

   
  function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public constant returns (uint256) {
     
    require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT && _sellAmount <= _supply);

     
    if (_sellAmount == 0)
      return 0;

     
    if (_sellAmount == _supply)
      return _connectorBalance;

     
    if (_connectorWeight == MAX_WEIGHT)
      return _connectorBalance.mul(_sellAmount).div(_supply);

    uint256 result;
    uint8 precision;
    uint256 baseD = _supply - _sellAmount;
    (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
    uint256 temp1 = _connectorBalance.mul(result);
    uint256 temp2 = _connectorBalance << precision;
    return temp1.sub(temp2).div(result);
  }
}

 

 
contract EthBondingCurve is StandardToken, BancorFormula, Ownable {
  uint256 public poolBalance;

   
  uint32 public reserveRatio;

   
  uint256 public gasPrice = 0 wei;  

   
  function() public payable {
    buy();
  }

   
  function buy() validGasPrice onlyOwner public payable returns(bool) {
    require(msg.value > 0);
    uint256 tokensToMint = calculatePurchaseReturn(totalSupply_, poolBalance, reserveRatio, msg.value);
    totalSupply_ = totalSupply_.add(tokensToMint);
    balances[msg.sender] = balances[msg.sender].add(tokensToMint);
    poolBalance = poolBalance.add(msg.value);
    emit LogMint(msg.sender, tokensToMint, msg.value);
    return true;
  }

   
  function sell(uint256 sellAmount) validGasPrice public returns(bool) {
    require(sellAmount > 0 && balances[msg.sender] >= sellAmount);
    uint256 ethAmount = calculateSaleReturn(totalSupply_, poolBalance, reserveRatio, sellAmount);
    msg.sender.transfer(ethAmount);
    poolBalance = poolBalance.sub(ethAmount);
    balances[msg.sender] = balances[msg.sender].sub(sellAmount);
    totalSupply_ = totalSupply_.sub(sellAmount);
    emit LogWithdraw(msg.sender, sellAmount, ethAmount);
    return true;
  }

   
  modifier validGasPrice() {
    assert(tx.gasprice <= gasPrice);
    _;
  }

   
  function setGasPrice(uint256 _gasPrice) onlyOwner public {
    require(_gasPrice > 0);
    gasPrice = _gasPrice;
  }

  event LogMint(address sender, uint256 amountMinted, uint256 totalCost);
  event LogWithdraw(address sender, uint256 amountWithdrawn, uint256 reward);
  event LogBondingCurve(address sender, string logString, uint256 value);
}

 

contract TrojanCoin is EthBondingCurve {
  string public constant name = "Trojan";
  string public constant symbol = "TROJ";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 2000000 * (10 ** 18);
  uint256 public constant INITIAL_PRICE = 5 * (10 ** 13);
  uint32 public constant CURVE_RATIO = 500000;
  uint256 public constant INITAL_BALANCE = CURVE_RATIO * INITIAL_SUPPLY * INITIAL_PRICE / (1000000 * 10 ** 18);

  constructor() public {
    reserveRatio = CURVE_RATIO;
    totalSupply_ = INITIAL_SUPPLY;
    poolBalance = INITAL_BALANCE;
    gasPrice = 26 * (10 ** 9);
  }
}