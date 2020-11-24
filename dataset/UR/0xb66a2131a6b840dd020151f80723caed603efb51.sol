 

pragma solidity ^0.4.24;

 
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

contract Token {

     
    function totalSupply() public view returns (uint256);

     
     
    function balanceOf(address owner) public view returns (uint256);

     
     
     
     
    function transfer(address to, uint256 value) public returns (bool);

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public returns (bool);

     
     
     
     
    function approve(address spender, uint256 value) public returns (bool);

     
     
     
    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract StandardToken is Token {
    using SafeMath for uint256;
    
    mapping (address => uint256) balances;
    
    mapping (address => mapping (address => uint256)) allowed;
    
    uint256 public totalSupply;
    
     
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender]);
        require(to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
     
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
     
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
    
     
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
      return allowed[owner][spender];
    }
    
     
    function approve(address spender, uint256 value) public returns (bool success) {
        require(spender != address(0));
        
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}

contract NNBToken is StandardToken, Ownable {
    string public constant name = "NNB Token";     
    string public constant symbol = "NNB";            
    uint8 public constant decimals = 18;             
    string public constant version = "H1.0";         
    
    mapping (address => uint256) lockedBalance;
    mapping (address => uint256) releasedBalance;
    mapping (address => TimeLock[]) public allocations;
    
    struct TimeLock {
        uint time;
        uint256 balance;
    }
    
    uint256 public constant BASE_SUPPLY = 10 ** uint256(decimals);
    uint256 public constant INITIAL_SUPPLY = 6 * (10 ** 9) * BASE_SUPPLY;     
    
    uint256 public constant noLockedOperatorSupply = INITIAL_SUPPLY / 100 * 2;   
    
    uint256 public constant lockedOperatorSupply = INITIAL_SUPPLY / 100 * 18;   
    uint256 public constant lockedInvestorSupply = INITIAL_SUPPLY / 100 * 10;   
    uint256 public constant lockedTeamSupply = INITIAL_SUPPLY / 100 * 10;   

    uint256 public constant lockedPrivatorForBaseSupply = INITIAL_SUPPLY / 100 * 11;   
    uint256 public constant lockedPrivatorForEcologyPartOneSupply = INITIAL_SUPPLY / 100 * 8;   
    uint256 public constant lockedPrivatorForEcologyPartTwoSupply = INITIAL_SUPPLY / 100 * 4;   
    
    uint256 public constant lockedPrivatorForFaithSupply = INITIAL_SUPPLY / 1000 * 11;   
    uint256 public constant lockedPrivatorForDevelopSupply = INITIAL_SUPPLY / 1000 * 19;   
    
    uint256 public constant lockedLabSupply = INITIAL_SUPPLY / 100 * 10;   
    
    uint public constant operatorUnlockTimes = 24;   
    uint public constant investorUnlockTimes = 3;    
    uint public constant teamUnlockTimes = 24;       
    uint public constant privatorForBaseUnlockTimes = 6;    
    uint public constant privatorForEcologyUnlockTimes = 9;   
    uint public constant privatorForFaithUnlockTimes = 6;    
    uint public constant privatorForDevelopUnlockTimes = 3;   
    uint public constant labUnlockTimes = 12;        
    
    event Lock(address indexed locker, uint256 value, uint releaseTime);
    event UnLock(address indexed unlocker, uint256 value);
    
    constructor(address operator, address investor, address team, address privatorBase,
                address privatorEcology, address privatorFaith, address privatorDevelop, address lab) public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
        
        initialLockedValues(operator, investor, team, privatorBase, privatorEcology, privatorFaith, privatorDevelop, lab);
    }
    
      
    function initialLockedValues(address operator, address investor, address team, address privatorBase,
                                 address privatorEcology, address privatorFaith, address privatorDevelop, address lab) internal onlyOwner returns (bool success) {
        
         
        uint unlockTime = now + 30 days;
        lockedValuesAndTime(operator, lockedOperatorSupply, operatorUnlockTimes, unlockTime);
        
         
        require(0x0 != investor);
        lockedBalance[investor] = lockedInvestorSupply;
        releasedBalance[investor] = 0;
        
        unlockTime = now;
        allocations[investor].push(TimeLock(unlockTime + 180 days, lockedInvestorSupply.div(10).mul(3)));
        allocations[investor].push(TimeLock(unlockTime + 270 days, lockedInvestorSupply.div(10).mul(3)));
        allocations[investor].push(TimeLock(unlockTime + 360 days, lockedInvestorSupply.div(10).mul(4)));
        
         
        unlockTime = now + 180 days;
        lockedValuesAndTime(team, lockedTeamSupply, teamUnlockTimes, unlockTime);
        
         
        unlockTime = now;
        lockedValuesAndTime(privatorBase, lockedPrivatorForBaseSupply, privatorForBaseUnlockTimes, unlockTime);
        
         
         
         
         
        require(0x0 != privatorEcology);
        releasedBalance[privatorEcology] = 0;
        lockedBalance[privatorEcology] = lockedPrivatorForEcologyPartOneSupply.add(lockedPrivatorForEcologyPartTwoSupply);

        unlockTime = now;
        for (uint i = 0; i < privatorForEcologyUnlockTimes; i++) {
            if (i > 0) {
                unlockTime = unlockTime + 30 days;
            }
            
            uint256 lockedValue = lockedPrivatorForEcologyPartOneSupply.div(privatorForEcologyUnlockTimes);
            if (i == privatorForEcologyUnlockTimes - 1) {   
                lockedValue = lockedPrivatorForEcologyPartOneSupply.div(privatorForEcologyUnlockTimes).add(lockedPrivatorForEcologyPartOneSupply.mod(privatorForEcologyUnlockTimes));
            }
            if (i < 6) {
                uint256 partTwoValue = lockedPrivatorForEcologyPartTwoSupply.div(6);
                if (i == 5) {   
                    partTwoValue = lockedPrivatorForEcologyPartTwoSupply.div(6).add(lockedPrivatorForEcologyPartTwoSupply.mod(6));
                }
                lockedValue = lockedValue.add(partTwoValue);
            }
            
            allocations[privatorEcology].push(TimeLock(unlockTime, lockedValue));
        }
        
         
        unlockTime = now;
        lockedValuesAndTime(privatorFaith, lockedPrivatorForFaithSupply, privatorForFaithUnlockTimes, unlockTime);
        
         
        unlockTime = now;
        lockedValuesAndTime(privatorDevelop, lockedPrivatorForDevelopSupply, privatorForDevelopUnlockTimes, unlockTime);
        
         
        unlockTime = now + 365 days;
        lockedValuesAndTime(lab, lockedLabSupply, labUnlockTimes, unlockTime);
        
        return true;
    }
    
      
    function lockedValuesAndTime(address target, uint256 lockedSupply, uint lockedTimes, uint unlockTime) internal onlyOwner returns (bool success) {
        require(0x0 != target);
        releasedBalance[target] = 0;
        lockedBalance[target] = lockedSupply;
        
        for (uint i = 0; i < lockedTimes; i++) {
            if (i > 0) {
                unlockTime = unlockTime + 30 days;
            }
            uint256 lockedValue = lockedSupply.div(lockedTimes);
            if (i == lockedTimes - 1) {   
                lockedValue = lockedSupply.div(lockedTimes).add(lockedSupply.mod(lockedTimes));
            }
            allocations[target].push(TimeLock(unlockTime, lockedValue));
        }
        
        return true;
    }
    
      
    function unlock(address target) public onlyOwner returns(bool success) {
        require(0x0 != target);
        
        uint256 value = 0;
        for(uint i = 0; i < allocations[target].length; i++) {
            if(now >= allocations[target][i].time) {
                value = value.add(allocations[target][i].balance);
                allocations[target][i].balance = 0;
            }
        }
        lockedBalance[target] = lockedBalance[target].sub(value);
        releasedBalance[target] = releasedBalance[target].add(value);
        
        transfer(target, value);
        emit UnLock(target, value);
        
        return true;
    }
    
      
    function initialOperatorValue(address operator) public onlyOwner {
        transfer(operator, noLockedOperatorSupply);
    }
    
     
    function lockedOf(address owner) public constant returns (uint256 balance) {
        return lockedBalance[owner];
    }
    
      
    function unlockTimeOf(address owner) public constant returns (uint time) {
        for(uint i = 0; i < allocations[owner].length; i++) {
            if(allocations[owner][i].time >= now) {
                return allocations[owner][i].time;
            }
        }
    }
    
      
    function unlockValueOf(address owner) public constant returns (uint256 balance) {
        for(uint i = 0; i < allocations[owner].length; i++) {
            if(allocations[owner][i].time >= now) {
                return allocations[owner][i].balance;
            }
        }
    }
    
     
    function releasedOf(address owner) public constant returns (uint256 balance) {
        return releasedBalance[owner];
    }
    
     
    function batchTransferForSingleValue(address[] dests, uint256 value) public onlyOwner {
        uint256 i = 0;
        uint256 sendValue = value * BASE_SUPPLY;
        while (i < dests.length) {
            transfer(dests[i], sendValue);
            i++;
        }
    }
    
     
    function batchTransferForDifferentValues(address[] dests, uint256[] values) public onlyOwner {
        if(dests.length != values.length) return;
        uint256 i = 0;
        while (i < dests.length) {
            uint256 sendValue = values[i] * BASE_SUPPLY;
            transfer(dests[i], sendValue);
            i++;
        }
    }
    
}