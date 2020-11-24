 

pragma solidity ^0.4.11;

 
contract SafeMath {
     
    function SafeMath() {
    }

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 

contract BancorFormula is SafeMath {

    uint256 constant ONE = 1;
    uint256 constant TWO = 2;
    uint256 constant MAX_FIXED_EXP_32 = 0x386bfdba29;
    string public version = '0.2';

    function BancorFormula() {
    }

     
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _depositAmount) public constant returns (uint256) {
         
        require(_supply != 0 && _reserveBalance != 0 && _reserveRatio > 0 && _reserveRatio <= 100);

         
        if (_depositAmount == 0)
            return 0;

        uint256 baseN = safeAdd(_depositAmount, _reserveBalance);
        uint256 temp;

         
        if (_reserveRatio == 100) {
            temp = safeMul(_supply, baseN) / _reserveBalance;
            return safeSub(temp, _supply); 
        }

        uint8 precision = calculateBestPrecision(baseN, _reserveBalance, _reserveRatio, 100);
        uint256 resN = power(baseN, _reserveBalance, _reserveRatio, 100, precision);
        temp = safeMul(_supply, resN) >> precision;
        return safeSub(temp, _supply);
     }

     
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _sellAmount) public constant returns (uint256) {
         
        require(_supply != 0 && _reserveBalance != 0 && _reserveRatio > 0 && _reserveRatio <= 100 && _sellAmount <= _supply);

         
        if (_sellAmount == 0)
            return 0;

        uint256 baseD = safeSub(_supply, _sellAmount);
        uint256 temp1;
        uint256 temp2;

         
        if (_reserveRatio == 100) {
            temp1 = safeMul(_reserveBalance, _supply);
            temp2 = safeMul(_reserveBalance, baseD);
            return safeSub(temp1, temp2) / _supply;
        }

         
        if (_sellAmount == _supply)
            return _reserveBalance;

        uint8 precision = calculateBestPrecision(_supply, baseD, 100, _reserveRatio);
        uint256 resN = power(_supply, baseD, 100, _reserveRatio, precision);
        temp1 = safeMul(_reserveBalance, resN);
        temp2 = safeMul(_reserveBalance, ONE << precision);
        return safeSub(temp1, temp2) / resN;
    }

     
    function calculateBestPrecision(uint256 _baseN, uint256 _baseD, uint256 _expN, uint256 _expD) constant returns (uint8) {
        uint8 precision;
        uint256 maxExp = MAX_FIXED_EXP_32;
        uint256 maxVal = lnUpperBound32(_baseN,_baseD) * _expN;
        for (precision = 0; precision < 32; precision += 2) {
            if (maxExp < (maxVal << precision) / _expD)
                break;
            maxExp = (maxExp * 0xeb5ec5975959c565) >> (64-2);
        }
        if (precision == 0)
            return 32;
        return precision+32-2;
    }

      
    function power(uint256 _baseN, uint256 _baseD, uint256 _expN, uint256 _expD, uint8 _precision) constant returns (uint256) {
        uint256 logbase = ln(_baseN, _baseD, _precision);
         
         
         
        return fixedExp(safeMul(logbase, _expN) / _expD, _precision);
    }
    
     
    function ln(uint256 _numerator, uint256 _denominator, uint8 _precision) public constant returns (uint256) {
         
        assert(_denominator <= _numerator);

         
        assert(_denominator != 0 && _numerator != 0);

         
        uint256 MAX_VAL = ONE << (256 - _precision);
        assert(_numerator < MAX_VAL);
        assert(_denominator < MAX_VAL);

        return fixedLoge( (_numerator << _precision) / _denominator, _precision);
    }

     
    function lnUpperBound32(uint256 _baseN, uint256 _baseD) constant returns (uint256) {
        assert(_baseN > _baseD);

        uint256 scaledBaseN = _baseN * 100000;
        if (scaledBaseN <= _baseD *  271828)  
            return uint256(1) << 32;
        if (scaledBaseN <= _baseD *  738905)  
            return uint256(2) << 32;
        if (scaledBaseN <= _baseD * 2008553)  
            return uint256(3) << 32;

        return (floorLog2((_baseN - 1) / _baseD) + 1) * 0xb17217f8;
    }

     
    function fixedLoge(uint256 _x, uint8 _precision) constant returns (uint256) {
         
        assert(_x >= ONE << _precision);

        uint256 flog2 = fixedLog2(_x, _precision);
        return (flog2 * 0xb17217f7d1cf78) >> 56;
    }

     
    function fixedLog2(uint256 _x, uint8 _precision) constant returns (uint256) {
        uint256 fixedOne = ONE << _precision;
        uint256 fixedTwo = TWO << _precision;

         
        assert( _x >= fixedOne);

        uint256 hi = 0;
        while (_x >= fixedTwo) {
            _x >>= 1;
            hi += fixedOne;
        }

        for (uint8 i = 0; i < _precision; ++i) {
            _x = (_x * _x) / fixedOne;
            if (_x >= fixedTwo) {
                _x >>= 1;
                hi += ONE << (_precision - 1 - i);
            }
        }

        return hi;
    }

     
    function floorLog2(uint256 _n) constant returns (uint256) {
        uint8 t = 0;
        for (uint8 s = 128; s > 0; s >>= 1) {
            if (_n >= (ONE << s)) {
                _n >>= s;
                t |= s;
            }
        }

        return t;
    }

     
    function fixedExp(uint256 _x, uint8 _precision) constant returns (uint256) {
        uint256 maxExp = MAX_FIXED_EXP_32;
        for (uint8 p = 32; p < _precision; p += 2)
            maxExp = (maxExp * 0xeb5ec5975959c565) >> (64-2);
        
        assert(_x <= maxExp);
        return fixedExpUnsafe(_x, _precision);
    }

     
    function fixedExpUnsafe(uint256 _x, uint8 _precision) constant returns (uint256) {
        uint256 xi = _x;
        uint256 res = uint256(0xde1bc4d19efcac82445da75b00000000) << _precision;

        res += xi * 0xde1bc4d19efcac82445da75b00000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x6f0de268cf7e5641222ed3ad80000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x2504a0cd9a7f7215b60f9be480000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x9412833669fdc856d83e6f920000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x1d9d4d714865f4de2b3fafea0000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x4ef8ce836bba8cfb1dff2a70000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xb481d807d1aa66d04490610000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x16903b00fa354cda08920c2000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x281cdaac677b334ab9e732000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x402e2aad725eb8778fd85000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x5d5a6c9f31fe2396a2af000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x7c7890d442a82f73839400000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x9931ed54034526b58e400000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xaf147cf24ce150cf7e00000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xbac08546b867cdaa200000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xbac08546b867cdaa20000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xafc441338061b2820000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x9c3cabbc0056d790000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x839168328705c30000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x694120286c049c000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x50319e98b3d2c000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x3a52a1e36b82000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x289286e0fce000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x1b0c59eb53400;
        xi = (xi * _x) >> _precision;
        res += xi * 0x114f95b55400;
        xi = (xi * _x) >> _precision;
        res += xi * 0xaa7210d200;
        xi = (xi * _x) >> _precision;
        res += xi * 0x650139600;
        xi = (xi * _x) >> _precision;
        res += xi * 0x39b78e80;
        xi = (xi * _x) >> _precision;
        res += xi * 0x1fd8080;
        xi = (xi * _x) >> _precision;
        res += xi * 0x10fbc0;
        xi = (xi * _x) >> _precision;
        res += xi * 0x8c40;
        xi = (xi * _x) >> _precision;
        res += xi * 0x462;
        xi = (xi * _x) >> _precision;
        res += xi * 0x22;

        return res / 0xde1bc4d19efcac82445da75b00000000;
    }
}


contract BasicERC20Token {
     
    string public standard = 'Token 0.1';
    string public name = 'Ivan\'s Trackable Token';
    string public symbol = 'ITT';
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event BalanceCheck(uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     

    function deposit() payable returns (bool success) {
        if (msg.value == 0) return false;
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        return true;
    }

    function withdraw(uint256 amount) returns (bool success) {
        if (balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        if (!msg.sender.send(amount)) {
            balances[msg.sender] += amount;
            totalSupply += amount;
            return false;
        }
        return true;
    }

}


contract DummyBancorToken is BasicERC20Token, BancorFormula {

    string public standard = 'Token 0.1';
    string public name = 'Dummy Constant Reserve Rate Token';
    string public symbol = 'DBT';
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;

    uint8 public ratio = 10;  

    address public owner = 0x0;

    event Deposit(address indexed sender);
    event Withdraw(uint256 amount);

     
    function setUp(uint256 _initialSupply) payable {
        if (owner != 0) return;
        owner = msg.sender;
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function tearDown() {
        if (msg.sender != owner) return;
        selfdestruct(owner);
    }

    function reserveBalance() constant returns (uint256) {
        return this.balance;
    }

     
    function deposit() payable returns (bool success) {
        if (msg.value == 0) return false;
        uint256 tokensPurchased = calculatePurchaseReturn(totalSupply, reserveBalance(), ratio, msg.value);
        balances[msg.sender] += tokensPurchased;
        totalSupply += tokensPurchased;
        Deposit(msg.sender);
        return true;
    }

    function withdraw(uint256 amount) returns (bool success) {
        if (balances[msg.sender] < amount) return false;
        uint256 ethAmount = calculateSaleReturn(totalSupply, reserveBalance(), ratio, amount);
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        if (!msg.sender.send(ethAmount)) {
            balances[msg.sender] += amount;
            totalSupply += amount;
            return false;
        }
        Withdraw(amount);
        return true;
    }

}