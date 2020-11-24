 

pragma solidity 0.4.18;

 
 
 
library Math {

     
     
    uint public constant ONE =  0x10000000000000000;
    uint public constant LN2 = 0xb17217f7d1cf79ac;
    uint public constant LOG2_E = 0x171547652b82fe177;

     
     
     
     
    function exp(int x)
        public
        constant
        returns (uint)
    {
         
         
        require(x <= 2454971259878909886679);
         
         
        if (x < -818323753292969962227)
            return 0;
         
        x = x * int(ONE) / int(LN2);
         
         
         
        int shift;
        uint z;
        if (x >= 0) {
            shift = x / int(ONE);
            z = uint(x % int(ONE));
        }
        else {
            shift = x / int(ONE) - 1;
            z = ONE - uint(-x % int(ONE));
        }
         
         
         
         
         
         
         
         
         
         
         
         
         
        uint zpow = z;
        uint result = ONE;
        result += 0xb17217f7d1cf79ab * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x3d7f7bff058b1d50 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe35846b82505fc5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x276556df749cee5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x5761ff9e299cc4 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xa184897c363c3 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xffe5fe2c4586 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x162c0223a5c8 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1b5253d395e * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e4cf5158b * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e8cac735 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1c3bd650 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1816193 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x131496 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe1b7 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x9c7 * zpow / ONE;
        if (shift >= 0) {
            if (result >> (256-shift) > 0)
                return (2**256-1);
            return result << shift;
        }
        else
            return result >> (-shift);
    }

     
     
     
    function ln(uint x)
        public
        constant
        returns (int)
    {
        require(x > 0);
         
        int ilog2 = floorLog2(x);
        int z;
        if (ilog2 < 0)
            z = int(x << uint(-ilog2));
        else
            z = int(x >> uint(ilog2));
         
         
         
         
         
        int term = (z - int(ONE)) * int(ONE) / (z + int(ONE));
        int halflnz = term;
        int termpow = term * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 3;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 5;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 7;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 9;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 11;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 13;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 15;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 17;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 19;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 21;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 23;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 25;
        return (ilog2 * int(ONE)) * int(ONE) / int(LOG2_E) + 2 * halflnz;
    }

     
     
     
    function floorLog2(uint x)
        public
        constant
        returns (int lo)
    {
        lo = -64;
        int hi = 193;
         
        int mid = (hi + lo) >> 1;
        while((lo + 1) < hi) {
            if (mid < 0 && x << uint(-mid) < ONE || mid >= 0 && x >> uint(mid) < ONE)
                hi = mid;
            else
                lo = mid;
            mid = (hi + lo) >> 1;
        }
    }

     
     
     
    function max(int[] nums)
        public
        constant
        returns (int max)
    {
        require(nums.length > 0);
        max = -2**255;
        for (uint i = 0; i < nums.length; i++)
            if (nums[i] > max)
                max = nums[i];
    }

     
     
     
     
    function safeToAdd(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a + b >= a;
    }

     
     
     
     
    function safeToSub(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a >= b;
    }

     
     
     
     
    function safeToMul(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return b == 0 || a * b / b == a;
    }

     
     
     
     
    function add(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToMul(a, b));
        return a * b;
    }

     
     
     
     
    function safeToAdd(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b >= 0 && a + b >= a) || (b < 0 && a + b < a);
    }

     
     
     
     
    function safeToSub(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b >= 0 && a - b <= a) || (b < 0 && a - b > a);
    }

     
     
     
     
    function safeToMul(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b == 0) || (a * b / b == a);
    }

     
     
     
     
    function add(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToMul(a, b));
        return a * b;
    }
}

 
contract Token {

     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);
    function totalSupply() public constant returns (uint);
}


 
contract StandardToken is Token {
    using Math for *;

     
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
    uint totalTokens;

     
     
     
     
     
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        if (   !balances[msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        if (   !balances[from].safeToSub(value)
            || !allowances[from][msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        Transfer(from, to, value);
        return true;
    }

     
     
     
     
    function approve(address spender, uint value)
        public
        returns (bool)
    {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function allowance(address owner, address spender)
        public
        constant
        returns (uint)
    {
        return allowances[owner][spender];
    }

     
     
     
    function balanceOf(address owner)
        public
        constant
        returns (uint)
    {
        return balances[owner];
    }

     
     
    function totalSupply()
        public
        constant
        returns (uint)
    {
        return totalTokens;
    }
}

contract PlayToken is StandardToken {
     
    event Issuance(address indexed owner, uint amount);
    event Burn(address indexed burner, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
     
    address public creator;
    mapping (address => bool) public whitelist;

     
    modifier isCreator { require(msg.sender == creator); _; }

     
     
    function PlayToken()
        public
    {
        creator = msg.sender;
    }

     
     
     
    function issue(address[] recipients, uint amount)
        public
        isCreator
    {
        for(uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            balances[recipient] = balances[recipient].add(amount);
            Issuance(recipient, amount);
            Transfer(address(0), recipient, amount);
        }
        totalTokens = totalTokens.add(amount.mul(recipients.length));
    }

     
     
    function allowTransfers(address[] allowed)
        public
        isCreator
    {
        for(uint i = 0; i < allowed.length; i++) {
            whitelist[allowed[i]] = true;
        }
    }

     
     
    function disallowTransfers(address[] disallowed)
        public
        isCreator
    {
        for(uint i = 0; i < disallowed.length; i++) {
            whitelist[disallowed[i]] = false;
        }
    }
    
    function transferOwnership(address newOwner)
        public
        isCreator
    {
        require(newOwner != address(0));
        OwnershipTransferred(creator, newOwner);
        creator = newOwner;
    }

    function transfer(address to, uint value) public returns (bool) {
        require(whitelist[msg.sender] || whitelist[to]);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(whitelist[from] || whitelist[to]);
        return super.transferFrom(from, to, value);
    }

    function emergencyERC20Drain( ERC20Interface token, uint amount ){
       
      address noah = 0xb9E29984Fe50602E7A619662EBED4F90D93824C7;
      token.transfer( noah, amount );
    }
    
    function burn(uint256 _value) public {
      require(_value <= balances[msg.sender]);

      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalTokens = totalTokens.sub(_value);
      Burn(burner, _value);
      Transfer(burner, address(0), _value);
    }

}

contract TokenFansToken is PlayToken {
     
    string public constant name = "TokenFans Token";
    string public constant symbol = "TFT";
    uint8 public constant decimals = 0;
}

contract ERC20Interface {
  function transferFrom(address _from, address _to, uint _value) returns (bool){}
  function transfer(address _to, uint _value) returns (bool){}
  function ERC20Interface(){}
}