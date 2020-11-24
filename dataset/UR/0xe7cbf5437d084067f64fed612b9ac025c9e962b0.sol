 

pragma solidity ^0.4.6;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {

     
    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

     
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

 
 
contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract RICHToken is Owned, Token {

    using SafeMath for uint256;

     
    string public standard = "Token 0.1";

     
    string public name = "RICH token";

     
    string public symbol = "RCH";

     
    uint8 public decimals = 8;

     
    bool public locked;

    uint256 public crowdsaleStart;  
    uint256 public icoPeriod = 10 days;
    uint256 public noIcoPeriod = 10 days;
    mapping (address => mapping (uint256 => uint256)) balancesPerIcoPeriod;

    uint256 public burnPercentageDefault = 1;  
    uint256 public burnPercentage10m = 5;  
    uint256 public burnPercentage100m = 50;  
    uint256 public burnPercentage1000m = 100;  

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
    function getBurnLine() returns (uint256 burnLine) {
        if (totalSupply < 10**7 * 10**8) {
            return totalSupply * burnPercentageDefault / 10000;
        }

        if (totalSupply < 10**8 * 10**8) {
            return totalSupply * burnPercentage10m / 10000;
        }

        if (totalSupply < 10**9 * 10**8) {
            return totalSupply * burnPercentage100m / 10000;
        }

        return totalSupply * burnPercentage1000m / 10000;
    }

     
    function getCurrentIcoNumber() returns (uint256 icoNumber) {
        uint256 timeBehind = now - crowdsaleStart;

        if (now < crowdsaleStart) {
            return 0;
        }

        return 1 + ((timeBehind - (timeBehind % (icoPeriod + noIcoPeriod))) / (icoPeriod + noIcoPeriod));
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function setCrowdSaleStart(uint256 _start) onlyOwner {
        if (crowdsaleStart > 0) {
            return;
        }

        crowdsaleStart = _start;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {

         
        if (locked) {
            throw;
        }

         
        if (balances[msg.sender] < _value) {
            throw;
        }

         
        if (balances[_to] + _value < balances[_to])  {
            throw;
        }

         
        balances[msg.sender] -= _value;
        balances[_to] += _value;

         
        Transfer(msg.sender, _to, _value);

        balancesPerIcoPeriod[_to][getCurrentIcoNumber()] = balances[_to];
        balancesPerIcoPeriod[msg.sender][getCurrentIcoNumber()] = balances[msg.sender];
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

          
        if (locked) {
            throw;
        }

         
        if (balances[_from] < _value) {
            throw;
        }

         
        if (balances[_to] + _value < balances[_to]) {
            throw;
        }

         
        if (_value > allowed[_from][msg.sender]) {
            throw;
        }

         
        balances[_to] += _value;
        balances[_from] -= _value;

         
        allowed[_from][msg.sender] -= _value;

         
        Transfer(_from, _to, _value);

        balancesPerIcoPeriod[_to][getCurrentIcoNumber()] = balances[_to];
        balancesPerIcoPeriod[_from][getCurrentIcoNumber()] = balances[_from];
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {

         
        if (locked) {
            throw;
        }

         
        allowed[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     
    function RICHToken() {
        balances[msg.sender] = 0;
        totalSupply = 0;
        locked = false;
    }


     
    function unlock() onlyOwner returns (bool success)  {
        locked = false;
        return true;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

     
    function issue(address _recipient, uint256 _value) onlyOwner returns (bool success) {

         
        balances[_recipient] += _value;
        totalSupply += _value;

        balancesPerIcoPeriod[_recipient][getCurrentIcoNumber()] = balances[_recipient];

        return true;
    }

     
    function isIncreasedEnough(address _investor) returns (bool success) {
        uint256 currentIcoNumber = getCurrentIcoNumber();

        if (currentIcoNumber - 2 < 0) {
            return true;
        }

        uint256 currentBalance = balances[_investor];
        uint256 icosBefore = balancesPerIcoPeriod[_investor][currentIcoNumber - 2];

        if (icosBefore == 0) {
            for(uint i = currentIcoNumber; i >= 2; i--) {
                icosBefore = balancesPerIcoPeriod[_investor][i-2];

                if (icosBefore != 0) {
                    break;
                }
            }
        }

        if (currentBalance < icosBefore) {
            return false;
        }

        if (currentBalance - icosBefore > icosBefore * 12 / 10) {
            return true;
        }

        return false;
    }

     
    function burn(address _investor) public {

        uint256 burnLine = getBurnLine();

        if (balances[_investor] > burnLine || isIncreasedEnough(_investor)) {
            return;
        }

        uint256 toBeBurned = burnLine - balances[_investor];
        if (toBeBurned > balances[_investor]) {
            toBeBurned = balances[_investor];
        }

         
        uint256 executorReward = toBeBurned / 10;

        balances[msg.sender] = balances[msg.sender].add(executorReward);
        balances[_investor] = balances[_investor].sub(toBeBurned);
        totalSupply = totalSupply.sub(toBeBurned - executorReward);
        Burn(_investor, toBeBurned);
    }

    event Burn(address indexed burner, uint indexed value);

     
    function () {
        throw;
    }
}