 

pragma solidity ^0.4.20;


 
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);

    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }

}

 
contract Owned {
    address[] public pools;
    address public owner;

    function Owned() {
        owner = msg.sender;
        pools.push(msg.sender);
    }

    modifier onlyPool {
        require(isPool(msg.sender));
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
     
    function addPool(address newPool) onlyOwner {
        assert (newPool != 0);
        if (isPool(newPool)) throw;
        pools.push(newPool);
    }
    
     
    function removePool(address pool) onlyOwner{
        assert (pool != 0);
        if (!isPool(pool)) throw;
        
        for (uint i=0; i<pools.length - 1; i++) {
            if (pools[i] == pool) {
                pools[i] = pools[pools.length - 1];
                break;
            }
        }
        pools.length -= 1;
    }

    function isPool(address pool) internal returns (bool ok){
        for (uint i=0; i<pools.length; i++) {
            if (pools[i] == pool)
                return true;
        }
        return false;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        removePool(owner);
        addPool(newOwner);
        owner = newOwner;
    }
}

 
contract BPToken is SafeMath, Owned, ERC20 {
    string public constant name = "Backpack Token";
    string public constant symbol = "BP";
    uint256 public constant decimals = 18;  

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function BPToken() {
        totalSupply = 2000000000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

     
    mapping (address => address) addressPool;

     
    mapping (address => uint256) addressAmount;

     
    uint perMonthSecond = 2592000;
    
     
    function shouldHadBalance(address who) constant returns (uint256){
        if (isPool(who)) return 0;

        address apAddress = getAssetPoolAddress(who);
        uint256 baseAmount  = getBaseAmount(who);

         
        if( (apAddress == address(0)) || (baseAmount == 0) ) return 0;

         
        AssetPool ap = AssetPool(apAddress);

        uint startLockTime = ap.getStartLockTime();
        uint stopLockTime = ap.getStopLockTime();

        if (block.timestamp > stopLockTime) {
            return 0;
        }

        if (ap.getBaseLockPercent() == 0) {
            return 0;
        }

         
        uint256 baseLockAmount = safeDiv(safeMul(baseAmount, ap.getBaseLockPercent()),100);
        if (block.timestamp < startLockTime) {
            return baseLockAmount;
        }
        
         
        if (ap.getLinearRelease() == 0) {
            if (block.timestamp < stopLockTime) {
                return baseLockAmount;
            } else {
                return 0;
            }
        }
         

         
        if (block.timestamp < startLockTime + perMonthSecond) {
            return baseLockAmount;
        }
         
        uint lockMonth = safeDiv(safeSub(stopLockTime,startLockTime),perMonthSecond);
        if (lockMonth <= 0) {
            if (block.timestamp >= stopLockTime) {
                return 0;
            } else {
                return baseLockAmount;
            }
        }

         
        uint256 monthUnlockAmount = safeDiv(baseLockAmount,lockMonth);

         
        uint hadPassMonth = safeDiv(safeSub(block.timestamp,startLockTime),perMonthSecond);

        return safeSub(baseLockAmount,safeMul(hadPassMonth,monthUnlockAmount));
    }

    function getAssetPoolAddress(address who) internal returns(address){
        return addressPool[who];
    }

    function getBaseAmount(address who) internal returns(uint256){
        return addressAmount[who];
    }

    function getBalance() constant returns(uint){
        return balances[msg.sender];
    }

    function setPoolAndAmount(address who, uint256 amount) onlyPool returns (bool) {
        assert(balances[msg.sender] >= amount);

        if (owner == who) {
            return true;
        }
        
        address apAddress = getAssetPoolAddress(who);
        uint256 baseAmount = getBaseAmount(who);

        assert((apAddress == msg.sender) || (baseAmount == 0));

        addressPool[who] = msg.sender;
        addressAmount[who] += amount;

        return true;
    }

     
    function balanceOf(address who) constant returns (uint) {
        return balances[who];
    }

     
     
     
     
     
     
     
    function transfer(address to, uint256 value) returns (bool) {
        if (safeSub(balances[msg.sender],value) < shouldHadBalance(msg.sender)) throw;

        uint256 senderBalance = balances[msg.sender];
        if (senderBalance >= value && value > 0) {
            senderBalance = safeSub(senderBalance, value);
            balances[msg.sender] = senderBalance;
            balances[to] = safeAdd(balances[to], value);
            Transfer(msg.sender, to, value);
            return true;
        } else {
            throw;
        }
    }

     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) returns (bool) {
         
         
        if (balances[from] >= value &&
        allowed[from][msg.sender] >= value &&
        safeAdd(balances[to], value) > balances[to])
        {
            balances[to] = safeAdd(balances[to], value);
            balances[from] = safeSub(balances[from], value);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
            Transfer(from, to, value);
            return true;
        } else {
            throw;
        }
    }

     
     
     
     
    function approve(address spender, uint256 value) returns (bool) {
        if (safeSub(balances[msg.sender],value) < shouldHadBalance(msg.sender)) throw;
        
         
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
    function allowance(address owner, address spender) constant returns (uint) {
        uint allow = allowed[owner][spender];
        return allow;
    }
}



contract ownedPool {
    address public owner;

    function ownedPool() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

 
contract AssetPool is ownedPool {
    uint  baseLockPercent;
    uint  startLockTime;
    uint  stopLockTime;
    uint  linearRelease;
    address public bpTokenAddress;

    BPToken bp;

    function AssetPool(address _bpTokenAddress, uint _baseLockPercent, uint _startLockTime, uint _stopLockTime, uint _linearRelease) {
        assert(_stopLockTime > _startLockTime);
        
        baseLockPercent = _baseLockPercent;
        startLockTime = _startLockTime;
        stopLockTime = _stopLockTime;
        linearRelease = _linearRelease;

        bpTokenAddress = _bpTokenAddress;
        bp = BPToken(bpTokenAddress);

        owner = msg.sender;
    }
    
     
    function setRule(uint _baseLockPercent, uint _startLockTime, uint _stopLockTime, uint _linearRelease) onlyOwner {
        assert(_stopLockTime > _startLockTime);
       
        baseLockPercent = _baseLockPercent;
        startLockTime = _startLockTime;
        stopLockTime = _stopLockTime;
        linearRelease = _linearRelease;
    }

     
     
     
     
     
    
     
    function assign(address to, uint256 amount) onlyOwner returns (bool) {
        if (bp.setPoolAndAmount(to,amount)) {
            if (bp.transfer(to,amount)) {
                return true;
            }
        }
        return false;
    }

     
    function getPoolBalance() constant returns (uint) {
        return bp.getBalance();
    }
    
    function getStartLockTime() constant returns (uint) {
        return startLockTime;
    }
    
    function getStopLockTime() constant returns (uint) {
        return stopLockTime;
    }
    
    function getBaseLockPercent() constant returns (uint) {
        return baseLockPercent;
    }
    
    function getLinearRelease() constant returns (uint) {
        return linearRelease;
    }
}