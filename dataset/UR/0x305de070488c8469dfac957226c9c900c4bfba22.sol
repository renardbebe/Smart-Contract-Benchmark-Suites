 

 
pragma solidity 0.4.24;

 
contract Owned {
    address public owner;

    function changeOwner(address _addr) onlyOwner {
        if (_addr == 0x0) throw;
        owner = _addr;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
}

 
contract Mutex is Owned {
    bool locked = false;
    modifier mutexed {
        if (locked) throw;
        locked = true;
        _;
        locked = false;
    }

    function unMutex() onlyOwner {
        locked = false;
    }
}

 
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

contract Token is Owned, Mutex {
     
    using SafeMath for uint256;

    Ledger public ledger;

    uint256 public lockedSupply = 0;

    string public name;
    uint8 public decimals; 
    string public symbol;

    string public version = '0.2'; 
    bool public transfersOn = true;

     
     
     
     
     
     
     
     
    constructor(address _owner, string _tokenName, uint8 _decimals,
                string _symbol, address _ledger) public {
        require(_owner != address(0), "address cannot be null");
        owner = _owner;

        name = _tokenName;
        decimals = _decimals;
        symbol = _symbol;

        ledger = Ledger(_ledger);
    }

     

     
     
     
    event LedgerUpdated(address _from, address _ledger);



     
     
    function changeLedger(address _addr) onlyOwner public {
        require(_addr != address(0), "address cannot be null");
        ledger = Ledger(_addr);
    
        emit LedgerUpdated(msg.sender, _addr);
    }

     

     
     
     
     
    function lock(address _seizeAddr) onlyOwner mutexed public {
        require(_seizeAddr != address(0), "address cannot be null");

        uint256 myBalance = ledger.balanceOf(_seizeAddr);
        lockedSupply = lockedSupply.add(myBalance);
        ledger.setBalance(_seizeAddr, 0);
    }

     
     
     
    event Dilution(address _destAddr, uint256 _amount);

     
     
     
     
     
    function dilute(address _destAddr, uint256 amount) onlyOwner public {
        require(amount <= lockedSupply, "amount greater than lockedSupply");

        lockedSupply = lockedSupply.sub(amount);

        uint256 curBalance = ledger.balanceOf(_destAddr);
        curBalance = curBalance.add(amount);
        ledger.setBalance(_destAddr, curBalance);

        emit Dilution(_destAddr, amount);
    }

     
    function pauseTransfers() onlyOwner public {
        transfersOn = false;
    }

     
    function resumeTransfers() onlyOwner public {
        transfersOn = true;
    }

     

     
     
    function burn(uint256 _amount) public {
        uint256 balance = ledger.balanceOf(msg.sender);
        require(_amount <= balance, "not enough balance");
        ledger.setBalance(msg.sender, balance.sub(_amount));
        emit Transfer(msg.sender, 0, _amount);
    }

     

     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
     
     
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
     
    function totalSupply() public view returns(uint256) {
        return ledger.totalSupply();
    }

     
     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(transfersOn || msg.sender == owner, "transferring disabled");
        require(ledger.tokenTransfer(msg.sender, _to, _value), "transfer failed");

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transfersOn || msg.sender == owner, "transferring disabled");
        require(ledger.tokenTransferFrom(msg.sender, _from, _to, _value), "transferFrom failed");

        emit Transfer(_from, _to, _value);
        uint256 allowed = allowance(_from, msg.sender);
        emit Approval(_from, msg.sender, allowed);
        return true;
    }

     
     
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return ledger.allowance(_owner, _spender); 
    }

     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(ledger.tokenApprove(msg.sender, _spender, _value), "approve failed");
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
    function balanceOf(address _addr) public view returns(uint256) {
        return ledger.balanceOf(_addr);
    }
}

contract Ledger is Owned {
    mapping (address => uint) balances;
    mapping (address => uint) usedToday;

    mapping (address => bool) seenHere;
    address[] public seenHereA;

    mapping (address => mapping (address => uint256)) allowed;
    address token;
    uint public totalSupply = 0;

    function Ledger(address _owner, uint _preMined, uint ONE) {
        if (_owner == 0x0) throw;
        owner = _owner;

        seenHere[_owner] = true;
        seenHereA.push(_owner);

        totalSupply = _preMined *ONE;
        balances[_owner] = totalSupply;
    }

    modifier onlyToken {
        if (msg.sender != token) throw;
        _;
    }

    modifier onlyTokenOrOwner {
        if (msg.sender != token && msg.sender != owner) throw;
        _;
    }


    function tokenTransfer(address _from, address _to, uint amount) onlyToken returns(bool) {
        if (amount > balances[_from]) return false;
        if ((balances[_to] + amount) < balances[_to]) return false;
        if (amount == 0) { return false; }

        balances[_from] -= amount;
        balances[_to] += amount;

        if (seenHere[_to] == false) {
            seenHereA.push(_to);
            seenHere[_to] = true;
        }

        return true;
    }

    function tokenTransferFrom(address _sender, address _from, address _to, uint amount) onlyToken returns(bool) {
        if (allowed[_from][_sender] <= amount) return false;
        if (amount > balanceOf(_from)) return false;
        if (amount == 0) return false;

        if ((balances[_to] + amount) < amount) return false;

        balances[_from] -= amount;
        balances[_to] += amount;
        allowed[_from][_sender] -= amount;

        if (seenHere[_to] == false) {
            seenHereA.push(_to);
            seenHere[_to] = true;
        }

        return true;
    }


    function changeUsed(address _addr, int amount) onlyToken {
        int myToday = int(usedToday[_addr]) + amount;
        usedToday[_addr] = uint(myToday);
    }

    function resetUsedToday(uint8 startI, uint8 numTimes) onlyTokenOrOwner returns(uint8) {
        uint8 numDeleted;
        for (uint i = 0; i < numTimes && i + startI < seenHereA.length; i++) {
            if (usedToday[seenHereA[i+startI]] != 0) { 
                delete usedToday[seenHereA[i+startI]];
                numDeleted++;
            }
        }
        return numDeleted;
    }

    function balanceOf(address _addr) constant returns (uint) {
         
        if (usedToday[_addr] >= balances[_addr]) { return 0;}
        return balances[_addr] - usedToday[_addr];
    }

    event Approval(address, address, uint);

    function tokenApprove(address _from, address _spender, uint256 _value) onlyToken returns (bool) {
        allowed[_from][_spender] = _value;
        Approval(_from, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function changeToken(address _token) onlyOwner {
        token = Token(_token);
    }

    function reduceTotalSupply(uint amount) onlyToken {
        if (amount > totalSupply) throw;

        totalSupply -= amount;
    }

    function setBalance(address _addr, uint amount) onlyTokenOrOwner {
        if (balances[_addr] == amount) { return; }
        if (balances[_addr] < amount) {
             
            uint increase = amount - balances[_addr];
            totalSupply += increase;
        } else {
             
            uint decrease = balances[_addr] - amount;
             
            totalSupply -= decrease;
        }
        balances[_addr] = amount;
    }

}