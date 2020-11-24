 

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;




 
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

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;




 
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

 

pragma solidity ^0.4.24;



 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

pragma solidity ^0.4.24;



 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

pragma solidity ^0.4.18;

 





contract ClubToken is StandardToken, DetailedERC20, MintableToken, BurnableToken {

    address public cloversController;
    address public clubTokenController;

    modifier hasMintPermission() {
      require(
          msg.sender == clubTokenController ||
          msg.sender == cloversController ||
          msg.sender == owner
      );
      _;
    }

     
    constructor(string _name, string _symbol, uint8 _decimals) public
        DetailedERC20(_name, _symbol, _decimals)
    {}

    function () public payable {}

    function updateClubTokenControllerAddress(address _clubTokenController) public onlyOwner {
        require(_clubTokenController != 0);
        clubTokenController = _clubTokenController;
    }

    function updateCloversControllerAddress(address _cloversController) public onlyOwner {
        require(_cloversController != 0);
        cloversController = _cloversController;
    }


       
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
        if (msg.sender != cloversController && msg.sender != clubTokenController) {
            require(_value <= allowed[_from][msg.sender]);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
      }

     
    function burn(uint256 _value) public {
        _value;
        revert();
    }

     
    function burn(address _burner, uint256 _value) public hasMintPermission {
      _burn(_burner, _value);
    }

     
    function moveEth(address _to, uint256 _amount) public hasMintPermission {
        require(this.balance >= _amount);
        _to.transfer(_amount);
    }
     
    function moveToken(address _to, uint256 _amount, address _token) public hasMintPermission returns (bool) {
        require(_amount <= StandardToken(_token).balanceOf(this));
        return StandardToken(_token).transfer(_to, _amount);
    }
     
    function approveToken(address _to, uint256 _amount, address _token) public hasMintPermission returns (bool) {
        return StandardToken(_token).approve(_to, _amount);
    }
}

 

pragma solidity ^0.4.24;

 
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256);
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256);
}

 

pragma solidity ^0.4.24;

 
contract Utils {
     
    constructor() public {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 

pragma solidity ^0.4.24;



contract BancorFormula is IBancorFormula, Utils {
    string public version = '0.3';

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

     
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

     
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

     
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

     
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

     
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256) {
         
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT);

         
        if (_depositAmount == 0)
            return 0;

         
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_supply, _depositAmount) / _connectorBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = safeAdd(_depositAmount, _connectorBalance);
        (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
        uint256 temp = safeMul(_supply, result) >> precision;
        return temp - _supply;
    }

     
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256) {
         
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT && _sellAmount <= _supply);

         
        if (_sellAmount == 0)
            return 0;

         
        if (_sellAmount == _supply)
            return _connectorBalance;

         
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_connectorBalance, _sellAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
        uint256 temp1 = safeMul(_connectorBalance, result);
        uint256 temp2 = _connectorBalance << precision;
        return (temp1 - temp2) / result;
    }

     
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256) {
         
        require(_fromConnectorBalance > 0 && _fromConnectorWeight > 0 && _fromConnectorWeight <= MAX_WEIGHT && _toConnectorBalance > 0 && _toConnectorWeight > 0 && _toConnectorWeight <= MAX_WEIGHT);

         
        if (_fromConnectorWeight == _toConnectorWeight)
            return safeMul(_toConnectorBalance, _amount) / safeAdd(_fromConnectorBalance, _amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = safeAdd(_fromConnectorBalance, _amount);
        (result, precision) = power(baseN, _fromConnectorBalance, _fromConnectorWeight, _toConnectorWeight);
        uint256 temp1 = safeMul(_toConnectorBalance, result);
        uint256 temp2 = _toConnectorBalance << precision;
        return (temp1 - temp2) / result;
    }

     
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        }
        else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        }
        else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

     
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

         
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

        if (_n < 256) {
             
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
             
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

     
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
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

        require(false);
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

 

pragma solidity ^0.4.24;


 
contract Admin {
  mapping (address => bool) public admins;


  event AdminshipRenounced(address indexed previousAdmin);
  event AdminshipTransferred(
    address indexed previousAdmin,
    address indexed newAdmin
  );


   
  constructor() public {
    admins[msg.sender] = true;
  }

   
  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }

  function isAdmin(address _admin) public view returns(bool) {
    return admins[_admin];
  }

   
  function renounceAdminship(address _previousAdmin) public onlyAdmin {
    emit AdminshipRenounced(_previousAdmin);
    admins[_previousAdmin] = false;
  }

   
  function transferAdminship(address _newAdmin) public onlyAdmin {
    _transferAdminship(_newAdmin);
  }

   
  function _transferAdminship(address _newAdmin) internal {
    require(_newAdmin != address(0));
    emit AdminshipTransferred(msg.sender, _newAdmin);
    admins[_newAdmin] = true;
  }
}

 

pragma solidity ^0.4.18;

 





contract ClubTokenController is BancorFormula, Admin, Ownable {
    event Buy(address buyer, uint256 tokens, uint256 value, uint256 poolBalance, uint256 tokenSupply);
    event Sell(address seller, uint256 tokens, uint256 value, uint256 poolBalance, uint256 tokenSupply);

    bool public paused;
    address public clubToken;
    address public simpleCloversMarket;
    address public curationMarket;
    address public support;

     
    uint256 public virtualSupply;
    uint256 public virtualBalance;
    uint32 public reserveRatio;  

    constructor(address _clubToken) public {
        clubToken = _clubToken;
        paused = true;
    }

    function () public payable {
        buy(msg.sender);
    }

    modifier notPaused() {
        require(!paused || owner == msg.sender || admins[tx.origin], "Contract must not be paused");
        _;
    }

    function poolBalance() public constant returns(uint256) {
        return clubToken.balance;
    }

     
    function getBuy(uint256 buyValue) public constant returns(uint256) {
        return calculatePurchaseReturn(
            safeAdd(ClubToken(clubToken).totalSupply(), virtualSupply),
            safeAdd(poolBalance(), virtualBalance),
            reserveRatio,
            buyValue);
    }


     

    function getSell(uint256 sellAmount) public constant returns(uint256) {
        return calculateSaleReturn(
            safeAdd(ClubToken(clubToken).totalSupply(), virtualSupply),
            safeAdd(poolBalance(), virtualBalance),
            reserveRatio,
            sellAmount);
    }

    function updatePaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

     
    function updateReserveRatio(uint32 _reserveRatio) public onlyOwner returns(bool){
        reserveRatio = _reserveRatio;
        return true;
    }

     
    function updateVirtualSupply(uint256 _virtualSupply) public onlyOwner returns(bool){
        virtualSupply = _virtualSupply;
        return true;
    }

     
    function updateVirtualBalance(uint256 _virtualBalance) public onlyOwner returns(bool){
        virtualBalance = _virtualBalance;
        return true;
    }
     
     

     
    function updateSimpleCloversMarket(address _simpleCloversMarket) public onlyOwner returns(bool){
        simpleCloversMarket = _simpleCloversMarket;
        return true;
    }

     
    function updateCurationMarket(address _curationMarket) public onlyOwner returns(bool){
        curationMarket = _curationMarket;
        return true;
    }

     
    function updateSupport(address _support) public onlyOwner returns(bool){
        support = _support;
        return true;
    }

     
    function donate() public payable {
        require(msg.value > 0);
         
        clubToken.transfer(msg.value);
    }

    function burn(address from, uint256 amount) public {
        require(msg.sender == simpleCloversMarket);
        ClubToken(clubToken).burn(from, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        require(msg.sender == simpleCloversMarket || msg.sender == curationMarket || msg.sender == support);
        ClubToken(clubToken).transferFrom(from, to, amount);
    }

     
    function buy(address buyer) public payable notPaused returns(bool) {
        require(msg.value > 0);
        uint256 tokens = getBuy(msg.value);
        require(tokens > 0);
        require(ClubToken(clubToken).mint(buyer, tokens));
         
        clubToken.transfer(msg.value);
        emit Buy(buyer, tokens, msg.value, poolBalance(), ClubToken(clubToken).totalSupply());
    }


     
    function sell(uint256 sellAmount) public notPaused returns(bool) {
        require(sellAmount > 0);
        require(ClubToken(clubToken).balanceOf(msg.sender) >= sellAmount);
        uint256 saleReturn = getSell(sellAmount);
        require(saleReturn > 0);
        require(saleReturn <= poolBalance());
        require(saleReturn <= clubToken.balance);
        ClubToken(clubToken).burn(msg.sender, sellAmount);
         
        ClubToken(clubToken).moveEth(msg.sender, saleReturn);
        emit Sell(msg.sender, sellAmount, saleReturn, poolBalance(), ClubToken(clubToken).totalSupply());
    }


 }