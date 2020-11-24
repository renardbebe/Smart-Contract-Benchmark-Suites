 

library Math {
   
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

   
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
   
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }
  
   
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }
   
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
       
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult);  
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult);  
    }
  }
   
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;   

      int256 xe = msb - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0;  
          require (re < 128);  
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0;  
          require (xe < 128);  
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }

}

contract Coin {
    
    string public constant name = "Untitled";
    string public constant symbol = "XYZ";
    uint8 public constant decimals = 18;

    mapping(address => uint256) public balanceOf;
    
    uint256 totalSupply = 21*10**6*10**uint(decimals);

    function transfer(address _to, uint _amount) internal {
        require(_amount <= balanceOf[msg.sender]);
        balanceOf[_to] += _amount;
        balanceOf[msg.sender] -= _amount;
    }
}

contract MoneySupplyTax is Coin {
    
	int128 taxrate = Math.div(2**64, 31556926*2**64);
    mapping(address => uint) taxDeclared;
    
    constructor() public {
        taxDeclared[address(this)] = block.timestamp;
    }
    
	function collectTax(int128 undeclared) internal {
		balanceOf[address(this)] += totalSupply - Math.mulu(undeclared, totalSupply);
	}
	function enforceTax(address _account) internal {
        int128 undeclared = Math.pow((2**64-taxrate), block.timestamp - taxDeclared[_account]);
		balanceOf[_account] = Math.mulu(undeclared, balanceOf[_account]);
		if(_account == address(this)) collectTax(undeclared);
		taxDeclared[_account] = block.timestamp;
	}
    function payment(address _to, uint _amount) public {
        enforceTax(msg.sender);
        enforceTax(_to);
        transfer(_to, _amount);
    }
    function taxFaucet() public {
        enforceTax(address(this));
        enforceTax(msg.sender);
        balanceOf[msg.sender] += balanceOf[address(this)];
        balanceOf[address(this)] = 0;
    }
}