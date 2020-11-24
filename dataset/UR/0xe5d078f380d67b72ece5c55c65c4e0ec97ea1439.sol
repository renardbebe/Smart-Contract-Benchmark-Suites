 

pragma solidity >=0.4.22 <0.6.0;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
        function isLeapYear(uint16 year) public pure returns (bool) {
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
        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }
        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
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
        function parseTimestamp(uint timestamp) internal pure returns (MyDateTime memory dt) {
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
        function getYear(uint timestamp) public pure returns (uint16) {
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
        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }
        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }
        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }
        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }
        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }
        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toDay(uint256 timestamp) internal pure returns (uint256) {
                MyDateTime memory d = parseTimestamp(timestamp);
                return uint256(d.year) * 10000 + uint256(d.month) * 100 + uint256(d.day);
        }
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
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

contract Controlled{
    address public owner;
    address public operator;
    mapping (address => bool) public blackList;

    constructor() public {
        owner = msg.sender;
        operator = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner);
        _;
    }

    modifier isNotBlack(address _addr) {
        require(blackList[_addr] == false);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function transferOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0));
        operator = _newOperator;
    }

    function addBlackList(address _blackAddr) public onlyOperator {
        blackList[_blackAddr] = true;
    }
    
    function removeBlackList(address _blackAddr) public onlyOperator {
        delete blackList[_blackAddr];
    }
    
}

contract TokenERC20 is Controlled{
    using SafeMath for uint;
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
     
    event Burn(address indexed burner, uint256 value);
    
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public isNotBlack(msg.sender) returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public isNotBlack(msg.sender) returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public isNotBlack(msg.sender) returns (bool success) {
        require(_value <= balanceOf[msg.sender]);      
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

      
    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_value <= balanceOf[msg.sender]);
         
         
        address burner = msg.sender;
        balanceOf[burner] = balanceOf[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        return true;
    }
}

contract FrozenableToken is TokenERC20{
    using SafeMath for uint;
    using DateTime for uint256;

    uint256 public totalFrozen;

    struct UnfreezeRecord {
        address to;
        uint256 amount;  
        uint256 unfreezeTime;
    }
    mapping (uint256 => UnfreezeRecord) public unfreezeRecords;

    event Unfreeze(address indexed receiver, uint256 value, uint256 unfreezeTime);

    function unfreeze(address _receiver, uint256 _value) public onlyOwner returns (bool) {
        require(_value > 0);
        require(_value <= totalFrozen);
        balanceOf[owner] = balanceOf[owner].add(_value);
        totalFrozen = totalFrozen.sub(_value);
        totalSupply = totalSupply.add(_value);
        uint256 timestamp = block.timestamp;
        uint256 releasedDay = timestamp.toDay();
        _transfer(owner,_receiver,_value);
        unfreezeRecords[releasedDay] = UnfreezeRecord(_receiver, _value, timestamp);
        emit Unfreeze(_receiver, _value, timestamp);
        return true;
    }
}

contract CasinoTkoen is FrozenableToken{
     
    constructor() public {
        name = 'CasinoToken';                         
        symbol = 'CT';                                
        decimals = 18;
        totalFrozen = 100000000 * 10 ** uint256(decimals);
        totalSupply = 0;
        balanceOf[msg.sender] = 0;
    }
}