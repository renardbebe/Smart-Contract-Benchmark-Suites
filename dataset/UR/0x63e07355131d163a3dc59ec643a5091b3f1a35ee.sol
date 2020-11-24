 

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
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function isOwner(address _owner) internal returns (bool){
        if (_owner == owner){
            return true;
        }
        return false;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

 
contract BPToken is SafeMath, Owned, ERC20 {
    string public constant name = "Backpack Travel Token";
    string public constant symbol = "BP";
    uint256 public constant decimals = 18;  

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function BPToken() {
        totalSupply = 2000000000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
    
    event Issue(uint16 role, address indexed to, uint256 value);

     
    enum Roles { Default, Angel, PrivateSale, Partner, Fans, Team, Foundation, Backup }
    mapping (address => uint256) addressHold;
    mapping (address => uint16) addressRole;

    uint perMonthSecond = 2592000;
    
     
    struct LockRule {
        uint baseLockPercent;
        uint startLockTime;
        uint stopLockTime;
        uint linearRelease;
    }
    mapping (uint16 => LockRule) roleRule;

     
    function setRule(uint16 _role, uint _baseLockPercent, uint _startLockTime, uint _stopLockTime,uint _linearRelease) onlyOwner {
        assert(_startLockTime > block.timestamp);
        assert(_stopLockTime > _startLockTime);
        
        roleRule[_role] = LockRule({
            baseLockPercent: _baseLockPercent,
            startLockTime: _startLockTime,
            stopLockTime: _stopLockTime,
            linearRelease: _linearRelease
        });
    }
    
     
    function assign(uint16 role, address to, uint256 amount) onlyOwner returns (bool) {
        assert(role <= uint16(Roles.Backup));
        assert(balances[msg.sender] > amount);
        
         
        if ((addressRole[to] != uint16(Roles.Default)) && (addressRole[to] != role)) throw;

        if (role != uint16(Roles.Default)) {
            addressRole[to] = role;
            addressHold[to] = safeAdd(addressHold[to],amount);
        }

        if (transfer(to,amount)) {
            Issue(role, to, amount);
            return true;
        }

        return false;
    }

    function isRole(address who) internal returns(uint16) {
        uint16 role = addressRole[who];
        if (role != 0) {
            return role;
        }
        return 100;
    }
    
     
    function shouldHadBalance(address who) internal returns (uint){
        uint16 currentRole = isRole(who);
        if (isOwner(who) || (currentRole == 100)) {
            return 0;
        }
        
         
        uint256 baseLockAmount = safeDiv(safeMul(addressHold[who], roleRule[currentRole].baseLockPercent),100);
        
         
        if (roleRule[currentRole].linearRelease == 0) {
            if (block.timestamp < roleRule[currentRole].stopLockTime) {
                return baseLockAmount;
            } else {
                return 0;
            }
        }
         

         
        if (block.timestamp < roleRule[currentRole].startLockTime + perMonthSecond) {
            return baseLockAmount;
        }
         
        uint lockMonth = safeDiv(safeSub(roleRule[currentRole].stopLockTime,roleRule[currentRole].startLockTime),perMonthSecond);
         
        uint256 monthUnlockAmount = safeDiv(baseLockAmount,lockMonth);
         
        uint hadPassMonth = safeDiv(safeSub(block.timestamp,roleRule[currentRole].startLockTime),perMonthSecond);

        return safeSub(baseLockAmount,safeMul(hadPassMonth,monthUnlockAmount));
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
        }
        return false;
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
        }
        else {return false;}
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