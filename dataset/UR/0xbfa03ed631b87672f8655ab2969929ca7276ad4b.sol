 

pragma solidity ^0.4.11;
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
library DateTime {
         
        struct MyDateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }
        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;
        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;
        uint16 constant ORIGIN_YEAR = 1970;
        function isLeapYear(uint16 year) constant returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }
        function leapYearsBefore(uint year) constant returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }
        function getDaysInMonth(uint8 month, uint16 year) constant returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }
        function parseTimestamp(uint timestamp) internal returns (MyDateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;
                 
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);
                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);
                 
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }
                 
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }
                 
                dt.hour = 0; 
                 
                dt.minute = 0; 
                 
                dt.second = 0; 
                 
                dt.weekday = 0; 
        }
        function getYear(uint timestamp) constant returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;
                 
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);
                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }
        function getMonth(uint timestamp) constant returns (uint8) {
                return parseTimestamp(timestamp).month;
        }
        function getDay(uint timestamp) constant returns (uint8) {
                return parseTimestamp(timestamp).day;
        }
        function getHour(uint timestamp) constant returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }
        function getMinute(uint timestamp) constant returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }
        function getSecond(uint timestamp) constant returns (uint8) {
                return uint8(timestamp % 60);
        }
        function toTimestamp(uint16 year, uint8 month, uint8 day) constant returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) constant returns (uint timestamp) {
                uint16 i;
                 
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }
                 
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;
                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }
                 
                timestamp += DAY_IN_SECONDS * (day - 1);
                 
                timestamp += HOUR_IN_SECONDS * (hour);
                 
                timestamp += MINUTE_IN_SECONDS * (minute);
                 
                timestamp += second;
                return timestamp;
        }
}
 
contract Ownable {
  address public owner;
   
  function Ownable() {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}
 
contract Claimable is Ownable {
  address public pendingOwner;
   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }
   
  function claimOwnership() onlyPendingOwner {
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}
contract Operational is Claimable {
    address public operator;
    function Operational(address _operator) {
      operator = _operator;
    }
    modifier onlyOperator() {
      require(msg.sender == operator);
      _;
    }
    function transferOperator(address newOperator) onlyOwner {
      require(newOperator != address(0));
      operator = newOperator;
    }
}
 
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
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
     
     
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
   
  function approve(address _spender, uint256 _value) returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
 
contract ReentrancyGuard {
   
  bool private rentrancy_lock = false;
   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }
}
 
contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);
     
    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        return true;
    }
}
contract BonusToken is BurnableToken, Operational {
    using SafeMath for uint;
    using DateTime for uint256;
    uint256 public createTime;
    uint256 standardDecimals = 100000000;
    uint256 minMakeBonusAmount = standardDecimals.mul(10);
    function BonusToken(
                     address operator
                     ) Operational(operator) {}
    function makeBonus(address[] _to, uint256[] _bonus) onlyOperator returns(bool) {
        for(uint i = 0; i < _to.length; i++){
            require(transfer(_to[i], _bonus[i]));
        }
        return true;
    }
}
contract KuaiMintableToken is BonusToken {
    uint256 public standardDailyLimit;  
    uint256 public dailyLimitLeft = standardDecimals.mul(1000000);  
    uint256 public lastMintTime = 0;
    event Mint(address indexed operator, uint256 value, uint256 mintTime);
    event SetDailyLimit(address indexed operator, uint256 time);
    function KuaiMintableToken(
                    address operator,
                    uint256 _dailyLimit
                ) BonusToken(operator) {
        totalSupply = 0;
        createTime = now;
        lastMintTime = createTime;
        standardDailyLimit = standardDecimals.mul(_dailyLimit);
    }
     
    function mint(uint256 mintAmount) onlyOperator returns(uint256 _actualRelease) {
        require(!judgeIsReachDailyLimit(mintAmount, timestamp));
        uint256 timestamp = now;
        balances[owner] = balances[owner].add(mintAmount);
        totalSupply = totalSupply.add(mintAmount);
        Mint(msg.sender, mintAmount, timestamp);
        return mintAmount;
    }
    function judgeIsReachDailyLimit(uint256 mintAmount, uint256 timestamp) internal returns(bool _exist) {
        bool reached = false;
        if (dailyLimitLeft > 0) {
            if ((timestamp.parseTimestamp().year == lastMintTime.parseTimestamp().year)
                && (timestamp.parseTimestamp().month == lastMintTime.parseTimestamp().month)
                && (timestamp.parseTimestamp().day == lastMintTime.parseTimestamp().day)) {
                if (dailyLimitLeft < mintAmount) {
                    reached = true;
                } else {
                    dailyLimitLeft = dailyLimitLeft.sub(mintAmount);
                    lastMintTime = timestamp;
                }
            } else {
                dailyLimitLeft = standardDailyLimit;
                lastMintTime = timestamp;
                if (dailyLimitLeft < mintAmount) {
                    reached = true;
                } else {
                    dailyLimitLeft = dailyLimitLeft.sub(mintAmount);
                }
            }
        }
        return reached;
    }
     
    function setDailyLimit(uint256 _dailyLimit) onlyOwner returns(bool){
        standardDailyLimit = _dailyLimit;
        SetDailyLimit(msg.sender, now);
        return true;
    }
}
contract KuaiToken is KuaiMintableToken {
    string public standard = '2017122806';
    string public name = 'KuaiToken';
    string public symbol = 'KT';
    uint8 public decimals = 8;
    function KuaiToken(
                    address operator,
                    uint256 dailyLimit
                     ) KuaiMintableToken(operator, dailyLimit) {}
}