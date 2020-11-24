 

pragma solidity ^0.4.18;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
contract Contract {
    bytes32 public Name;

     
     
    constructor(bytes32 _contractName) public {
        Name = _contractName;
    }

    function() public payable { }
    
    function sendFunds(address receiver, uint amount) public {
        receiver.transfer(amount);
    }    
}

 
 
 
contract DeaultERC20 is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    constructor() public {
        symbol = "DFLT";
        name = "Default";
        decimals = 18;
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function () public payable {
        revert();
    }
}

 
 
 
contract IGCoin is DeaultERC20 {
    using SafeMath for uint;

    address public reserveAddress;  
    uint256 public ask;
    uint256 public bid;
    uint16 public constant reserveRate = 10;
    bool public initialSaleComplete;
    uint256 constant private ICOAmount = 2e0*1e16;  
    uint256 constant private ICOask = 1e0*1e16;  
    uint256 constant private ICObid = 0;  
    uint256 constant private InitialSupply = 1e0 * 1e16;  
 
    uint256 constant private R = 125000;   
    uint256 constant private P = 10;  
    uint256 constant private lnR = R;  
    uint256 constant private S = 1e8;  
    uint256 constant private RS = 800;  
    uint256 constant private lnS = 18;  
    uint256 constant private lnRS = 391764552740441533402669241351723684867125000; 
    uint256 private refund = 0;
    uint256 constant SU = 1e15; 
    
     
    uint256 private constant ONE = 1;
    uint8 private constant MAX_PRECISION = 127;
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x1ffffffffffffffffffffffffffffffff;
    uint256 private constant FIXED_3 = 0x07fffffffffffffffffffffffffffffff; 
    uint256 private constant LN2_MANTISSA = 0x2c5c85fdf473de6af278ece600fcbda;
    uint8   private constant LN2_EXPONENT = 122;
    
     
    uint256[128] private maxExpArray;    
    
    
    
    
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 120;

     
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

     
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;  
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;  


    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen); 

     
     
     
    constructor() public {
        symbol = "IG17";
        name = "theTestToken002";
        decimals = 18;
        initialSaleComplete = false;
        _totalSupply = InitialSupply;   
        balances[owner] = _totalSupply;   
        emit Transfer(address(0), owner, _totalSupply);

        reserveAddress = new Contract("Reserve");   
        quoteAsk();
        quoteBid();        

        
        
        
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;       
    }
    

     
     
     
    function deposit(uint256 _value) private {
        reserveAddress.transfer(_value);
        balances[reserveAddress] += _value;
    }
  
     
     
     
    function withdraw(uint256 _value) private pure {
         
         _value = _value;
    }
    
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        
         
        require(_value > 0);

         
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    
         
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
     
     
     
     
    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }    
 
     
     
     
    function quoteAsk() private returns (uint256) {
        if(initialSaleComplete)
        {
            ask = fracExp(1e16, R, (_totalSupply/1e16)+1, P);
        }
        else
        {
            ask = ICOask;
        }
        
        return ask;
    }
    
     
     
     
    function quoteBid() private returns (uint256) {
        if(initialSaleComplete)
        {
            bid = fracExp(1e16, R, (_totalSupply/1e16)-1, P);
        }
        else
        {
            bid = ICObid;
        }

        return bid;
    }

     
     
    function buy() public payable returns (uint256 amount){

        if(initialSaleComplete)
        {
            uint256 b = 0;
            uint256 p = 0;
            uint8 ps = 0;

            (p, ps) = power(1000008,1000000,(uint32)(1+_totalSupply/SU),1);  
            p=(S*p)>>ps;
            
             
            b = (ln_fixed3_lnr_18(RS*msg.value/SU + p,1)-1e18*lnRS-1e18*FIXED_3)/FIXED_3;  

            refund = msg.value - (msg.value/SU)*SU;
            amount = b*SU/1e18-_totalSupply;
             
             
             
             

            reserveAddress.transfer((msg.value/SU)*SU);      
            balances[reserveAddress] += msg.value-refund;    
            mintToken(msg.sender, amount);                   
            msg.sender.transfer(refund);                     
            quoteAsk();
            quoteBid();
        }
        else
        {
             
             
            ask = ICOask;                                    
            amount = 1e16*msg.value / ask;                   
            refund = msg.value - (amount*ask/1e16);          

             
            reserveAddress.transfer(msg.value - refund);     
            msg.sender.transfer(refund);                     
            balances[reserveAddress] += msg.value-refund;    
            mintToken(msg.sender, amount);                   

            if(_totalSupply >= ICOAmount)
            {
                initialSaleComplete = true;
            }             
        }
        
        
        return amount;                                     
    }

     
     
     
    function sell(uint256 amount) public returns (uint256 revenue){
        uint256 a = 0;
        
        require(initialSaleComplete);
        require(balances[msg.sender] >= amount);         
        
        a = _totalSupply - amount;

        uint256 p = 0;
        uint8 ps = 0;

        (p, ps) = power(1000008,1000000,(uint32)(1e5+1e5*_totalSupply/SU),1e5);  
        p=(S*p)>>ps;

        uint256 p2 = 0;
        uint8 ps2 = 0;

        (p2, ps2) = power(1000008,1000000,(uint32)(1e5+1e5*a/SU),1e5);  
        p2=(S*p2)>>ps2;

            

        revenue = (SU*p-SU*p2)*R/S;
        
        
         
         
        
        _totalSupply -= amount;                  
        require(balances[reserveAddress] >= revenue);
        balances[reserveAddress] -= revenue;              
        balances[msg.sender] -= amount;                  
        Contract reserve = Contract(reserveAddress);
        reserve.sendFunds(msg.sender, revenue);
        
        emit Transfer(msg.sender, reserveAddress, amount);                

        quoteAsk();
        quoteBid();  

        return revenue;                                  
    }    
    
     
     
     
    function mintToken(address target, uint256 mintedAmount) public {
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        
        emit Transfer(address(0), this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }    
    

     
     
     
     
     
     
     
     
     
     
    function fracExp(uint256 _k, uint256 _q, uint256 _n, uint256 _p) internal pure returns (uint256) {
      uint256 s = 0;
      uint256 N = 1;
      uint256 B = 1;
      for (uint256 i = 0; i < _p; ++i){
        s += _k * N / B / (_q**i);
        N  = N * (_n-i);
        B  = B * (i+1);
      }
      return s;
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function ln_fixed3_lnr_18(uint256 _numerator, uint256 _denominator) internal pure returns (uint256) {
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

        return (((res * LN2_MANTISSA) >> LN2_EXPONENT)*lnR*1e18);
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
    
     
     
     
     
    function round(uint256 _n, uint256 _m) internal pure returns (uint256) {
        uint256 res = 0;
        
        uint256 p =_n/_m;
        res = _n-(_m*p);
        
        if(res >= 1)
        {
            res = p+1;
        }
        else
        {
            res = p;
        }

        return res;
    }      
  
  
     
     
     

     
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8) {
        assert(_baseN < MAX_NUM);

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
        
        if (maxExpArray[hi] >= _x){
             
            return hi;
        }
        if (maxExpArray[lo] >= _x){
             
            return lo;
        }
            
        

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