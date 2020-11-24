 

 

pragma solidity ^0.5.2;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.2;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 

pragma solidity ^0.5.2;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 

pragma solidity ^0.5.2;


  
contract Power {
  string public version = "0.3";

  uint256 private constant ONE = 1;
  uint32 private constant MAX_WEIGHT = 1000000;
  uint8 private constant MIN_PRECISION = 32;
  uint8 private constant MAX_PRECISION = 127;

   
  uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
  uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
  uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

   
  uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
  uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

   
  uint256 private constant OPT_LOG_MAX_VAL =
  0x15bf0a8b1457695355fb8ac404e7a79e3;
  uint256 private constant OPT_EXP_MAX_VAL =
  0x800000000000000000000000000000000;

   
  uint256[128] private maxExpArray;
  constructor() public {
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
    maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
    maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
    maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
    maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
    maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
    maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
    maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
    maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
    maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
    maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
    maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
    maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
    maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
    maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
    maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
    maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
    maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
    maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
    maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
    maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
    maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
    maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
    maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
    maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
    maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
    maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
    maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
    maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
    maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
    maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
    maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
    maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
    maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
    maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
    maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
    maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
    maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
    maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
    maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
    maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
    maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
    maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
    maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
    maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
    maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
    maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
    maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
    maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
    maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
    maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
    maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
    maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
    maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
    maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
    maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
    maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
    maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
    maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
    maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
    maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
    maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
    maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
    maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
    maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
    maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
    maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
    maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
    maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
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

   
  function power(
    uint256 _baseN,
    uint256 _baseD,
    uint32 _expN,
    uint32 _expD
  ) internal view returns (uint256, uint8)
  {
    require(_baseN < MAX_NUM, "baseN exceeds max value.");
    require(_baseN >= _baseD, "Bases < 1 are not supported.");

    uint256 baseLog;
    uint256 base = _baseN * FIXED_1 / _baseD;
    if (base < OPT_LOG_MAX_VAL) {
      baseLog = optimalLog(base);
    } else {
      baseLog = generalLog(base);
    }

    uint256 baseLogTimesExp = baseLog * _expN / _expD;
    if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
      return (optimalExp(baseLogTimesExp), MAX_PRECISION);
    } else {
      uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
      return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
    }
  }

   
  function generalLog(uint256 _x) internal pure returns (uint256) {
    uint256 res = 0;
    uint256 x = _x;

     
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

    return res * LN2_NUMERATOR / LN2_DENOMINATOR;
  }

   
  function floorLog2(uint256 _n) internal pure returns (uint8) {
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

   
  function findPositionInMaxExpArray(uint256 _x)
  internal view returns (uint8)
  {
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

   
   
   function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
       uint256 xi = _x;
       uint256 res = 0;

       xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000;  
       xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000;  
       xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000;  
       xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000;  
       xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000;  
       xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000;  
       xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000;  
       xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000;  
       xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000;  
       xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000;  
       xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000;  
       xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000;  
       xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000;  
       xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000;  
       xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000;  
       xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000;  
       xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00;  
       xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00;  
       xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900;  
       xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340;  
       xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021;  
       xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001;  

       return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision);  
   }

    
   function optimalLog(uint256 x) internal pure returns (uint256) {
       uint256 res = 0;

       uint256 y;
       uint256 z;
       uint256 w;

       if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;}
       if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;}
       if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;}
       if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;}
       if (x >= 0x84102b00893f64c705e841d5d4064bd3) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;}
       if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;}
       if (x >= 0x810100ab00222d861931c15e39b44e99) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;}
       if (x >= 0x808040155aabbbe9451521693554f733) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;}

       z = y = x - FIXED_1;
       w = y * y / FIXED_1;
       res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1;
       res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1;
       res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1;
       res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1;
       res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1;
       res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1;
       res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1;
       res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;

       return res;
   }

    
   function optimalExp(uint256 x) internal pure returns (uint256) {
       uint256 res = 0;

       uint256 y;
       uint256 z;

       z = y = x % 0x10000000000000000000000000000000;
       z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000;  
       z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000;  
       z = z * y / FIXED_1; res += z * 0x0168244fdac78000;  
       z = z * y / FIXED_1; res += z * 0x004807432bc18000;  
       z = z * y / FIXED_1; res += z * 0x000c0135dca04000;  
       z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000;  
       z = z * y / FIXED_1; res += z * 0x000036e0f639b800;  
       z = z * y / FIXED_1; res += z * 0x00000618fee9f800;  
       z = z * y / FIXED_1; res += z * 0x0000009c197dcc00;  
       z = z * y / FIXED_1; res += z * 0x0000000e30dce400;  
       z = z * y / FIXED_1; res += z * 0x000000012ebd1300;  
       z = z * y / FIXED_1; res += z * 0x0000000017499f00;  
       z = z * y / FIXED_1; res += z * 0x0000000001a9d480;  
       z = z * y / FIXED_1; res += z * 0x00000000001c6380;  
       z = z * y / FIXED_1; res += z * 0x000000000001c638;  
       z = z * y / FIXED_1; res += z * 0x0000000000001ab8;  
       z = z * y / FIXED_1; res += z * 0x000000000000017c;  
       z = z * y / FIXED_1; res += z * 0x0000000000000014;  
       z = z * y / FIXED_1; res += z * 0x0000000000000001;  
       res = res / 0x21c3677c82b40000 + y + FIXED_1;  

       if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776;
       if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4;
       if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f;
       if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9;
       if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea;
       if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d;
       if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11;

       return res;
   }
    
}

 

pragma solidity ^0.5.2;



 
contract BancorBondingCurve is Power {
   using SafeMath for uint256;
   uint32 private constant MAX_RESERVE_RATIO = 1000000;

    
  function calculatePurchaseReturn(
    uint256 _supply,
    uint256 _reserveBalance,
    uint32 _reserveRatio,
    uint256 _depositAmount) public view returns (uint256)
  {
     
    require(_supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO);
      
    if (_depositAmount == 0) {
      return 0;
    }
      
    if (_reserveRatio == MAX_RESERVE_RATIO) {
      return _supply.mul(_depositAmount).div(_reserveBalance);
    }
     uint256 result;
    uint8 precision;
    uint256 baseN = _depositAmount.add(_reserveBalance);
    (result, precision) = power(
      baseN, _reserveBalance, _reserveRatio, MAX_RESERVE_RATIO
    );
    uint256 newTokenSupply = _supply.mul(result) >> precision;
    return newTokenSupply - _supply;
  }
    
  function calculateSaleReturn(
    uint256 _supply,
    uint256 _reserveBalance,
    uint32 _reserveRatio,
    uint256 _sellAmount) public view returns (uint256)
  {
     
    require(_supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO && _sellAmount <= _supply);
      
    if (_sellAmount == 0) {
      return 0;
    }
      
    if (_sellAmount == _supply) {
      return _reserveBalance;
    }
      
    if (_reserveRatio == MAX_RESERVE_RATIO) {
      return _reserveBalance.mul(_sellAmount).div(_supply);
    }
     uint256 result;
    uint8 precision;
    uint256 baseD = _supply - _sellAmount;
    (result, precision) = power(
      _supply, baseD, MAX_RESERVE_RATIO, _reserveRatio
    );
    uint256 oldBalance = _reserveBalance.mul(result);
    uint256 newBalance = _reserveBalance << precision;
    return oldBalance.sub(newBalance).div(result);
  }
}

 

pragma solidity ^0.5.2;





contract ContinuousToken is BancorBondingCurve, Ownable, ERC20 {
    
    using SafeMath for uint256;

    uint256 public scale = 10**18;
    uint256 public reserveBalance = 10*scale;
    uint256 public reserveRatio = 500000;

    constructor() public {
        _mint(msg.sender, 1*scale);
    }

    function mint(address reciever, uint value) internal {
        require(value > 0, "Must send ether to buy tokens.");
        _continuousMint(reciever, value);
    }

    function burn(uint256 _amount) public {
        uint256 returnAmount = _continuousBurn(_amount);
        msg.sender.transfer(returnAmount);
    }

    function calculateContinuousMintReturn(uint256 _amount)
        public view returns (uint256 mintAmount)
    {
        return calculatePurchaseReturn(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
    }

    function calculateContinuousBurnReturn(uint256 _amount)
        public view returns (uint256 burnAmount)
    {
        return calculateSaleReturn(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
    }

    function _continuousMint(address reciever, uint value)
        internal returns (uint256)
    {
        require(value > 0, "Deposit must be non-zero.");

        uint256 amount = calculateContinuousMintReturn(value);
        _mint(reciever, amount);
        reserveBalance = reserveBalance.add(value);
        return amount;
    }

    function _continuousBurn(uint256 _amount)
        internal returns (uint256)
    {
        require(_amount > 0, "Amount must be non-zero.");
        require(balanceOf(msg.sender) >= _amount, "Insufficient tokens to burn.");

        uint256 reimburseAmount = calculateContinuousBurnReturn(_amount);
        reserveBalance = reserveBalance.sub(reimburseAmount);
        _burn(msg.sender, _amount);
        return reimburseAmount;
    }
}

 

pragma solidity ^0.5.2;

 



 


contract SpaceMiners is Ownable, ContinuousToken {

  using SafeMath for uint;

  uint public PRICE_TO_MINE = 20 finney;
  uint public PLANET_CAPACITY = 6;
  uint public NUM_WINNERS = 3;
  uint constant OWNER_FEE_PERCENT = 5;
  address[] miners = new address[](PLANET_CAPACITY);
  uint public planetPopulation = 0;
  uint ownerHoldings = 1;

  string public constant name = "Kerium Crystals";
  string public constant symbol = "KMC";
  uint8 public constant decimals = 18;

  function setGameSettings(uint priceToMine, uint planetCapacity, uint numWinners) public payable onlyOwner {
    PRICE_TO_MINE = priceToMine;
    PLANET_CAPACITY = planetCapacity;
    NUM_WINNERS = numWinners;
  }

  function getNumUsersMinersOnPlanet(address miner) public view returns (uint) {
    uint count = 0;
    for (uint i = 0; i < planetPopulation; i++) {
      if (miners[i] == miner) {
        count++;
      }
    }
    return count;
  }

  function sendSingleMinerToPlanet(address miner) internal {
    miners[planetPopulation] = miner;
    planetPopulation = planetPopulation.add(1);
    if (planetPopulation == PLANET_CAPACITY) {
      rewardMiners();
      planetPopulation = 0;
    }
  }

  function sendMinersToPlanet(uint numMiners) public payable {
    require(msg.value >= numMiners * PRICE_TO_MINE, "Not enough paid");
    require(planetPopulation < PLANET_CAPACITY, "Planet is full");
    mint(msg.sender, numMiners);
    for (uint i = 0; i < numMiners; i++) {
      sendSingleMinerToPlanet(msg.sender);
    }
  }

  function percentOfValue(uint percent, uint value) pure internal returns (uint) {
    return (value.mul(percent)).div(100);
  }

  function getRandom(uint cap) view internal returns (uint) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % cap;
  }

  function rewardMiners() internal {
     
    uint roundEarnings = PRICE_TO_MINE * PLANET_CAPACITY;
    uint ownerFee = percentOfValue(OWNER_FEE_PERCENT, roundEarnings);
    ownerHoldings = ownerHoldings.add(ownerFee);
    roundEarnings = roundEarnings.sub(ownerFee);
    uint rewardAmount = roundEarnings.div(NUM_WINNERS);
    uint rnd = getRandom(PLANET_CAPACITY);
    for (uint i = rnd; i < rnd + NUM_WINNERS; i++) {
      if (i >= PLANET_CAPACITY) {
        mint(miners[i - PLANET_CAPACITY], rewardAmount);
      } else {
        mint(miners[i], rewardAmount);
      }
    }
  }

  function cashOutOwnerFee() public payable onlyOwner {
    require(ownerHoldings > 1);
    msg.sender.transfer(ownerHoldings - 1);
    ownerHoldings = 1;
  }

  function() external payable {
    address payable payableAddress = address(uint160(owner()));
    payableAddress.transfer(msg.value);
  }

}