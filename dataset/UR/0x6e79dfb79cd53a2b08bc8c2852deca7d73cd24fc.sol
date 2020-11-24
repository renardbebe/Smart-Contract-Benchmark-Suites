 

pragma solidity 0.4.25;


 
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


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


interface IOrbsValidators {

    event ValidatorApproved(address indexed validator);
    event ValidatorRemoved(address indexed validator);

     
     
    function approve(address validator) external;

     
     
    function remove(address validator) external;

     
     
    function isValidator(address validator) external view returns (bool);

     
     
    function isApproved(address validator) external view returns (bool);

     
    function getValidators() external view returns (address[]);

     
     
    function getValidatorsBytes20() external view returns (bytes20[]);

     
     
    function getApprovalBlockNumber(address validator)
        external
        view
        returns (uint);
}


 
library DateTime {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;

    struct DT {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint public constant SECONDS_IN_DAY = 86400;
    uint public constant SECONDS_IN_YEAR = 31536000;
    uint public constant SECONDS_IN_LEAP_YEAR = 31622400;
    uint public constant DAYS_IN_WEEK = 7;
    uint public constant HOURS_IN_DAY = 24;
    uint public constant MINUTES_IN_HOUR = 60;
    uint public constant SECONDS_IN_HOUR = 3600;
    uint public constant SECONDS_IN_MINUTE = 60;

    uint16 public constant ORIGIN_YEAR = 1970;

     
     
    function isLeapYear(uint16 _year) public pure returns (bool) {
        if (_year % 4 != 0) {
            return false;
        }

        if (_year % 100 != 0) {
            return true;
        }

        if (_year % 400 != 0) {
            return false;
        }

        return true;
    }

     
     
    function leapYearsBefore(uint16 _year) public pure returns (uint16) {
        _year = uint16(_year.sub(1));
        return uint16(_year.div(4).sub(_year.div(100)).add(_year.div(400)));
    }

     
     
     
    function getDaysInMonth(uint16 _year, uint8 _month) public pure returns (uint8) {
        if (_month == 1 || _month == 3 || _month == 5 || _month == 7 || _month == 8 || _month == 10 || _month == 12) {
            return 31;
        }

        if (_month == 4 || _month == 6 || _month == 9 || _month == 11) {
            return 30;
        }

        if (isLeapYear(_year)) {
            return 29;
        }

        return 28;
    }

     
     
    function getYear(uint256 _timestamp) public pure returns (uint16 year) {
        uint256 secondsAccountedFor;
        uint16 numLeapYears;

         
        year = uint16(ORIGIN_YEAR.add(_timestamp.div(SECONDS_IN_YEAR)));
        numLeapYears = uint16(leapYearsBefore(year).sub(leapYearsBefore(ORIGIN_YEAR)));

        secondsAccountedFor = secondsAccountedFor.add(SECONDS_IN_LEAP_YEAR.mul(numLeapYears));
        secondsAccountedFor = secondsAccountedFor.add(SECONDS_IN_YEAR.mul((year.sub(ORIGIN_YEAR).sub(numLeapYears))));

        while (secondsAccountedFor > _timestamp) {
            if (isLeapYear(uint16(year.sub(1)))) {
                secondsAccountedFor = secondsAccountedFor.sub(SECONDS_IN_LEAP_YEAR);
            } else {
                secondsAccountedFor = secondsAccountedFor.sub(SECONDS_IN_YEAR);
            }

            year = uint16(year.sub(1));
        }
    }

     
     
    function getMonth(uint256 _timestamp) public pure returns (uint8) {
        return parseTimestamp(_timestamp).month;
    }

     
     
    function getDay(uint256 _timestamp) public pure returns (uint8) {
        return parseTimestamp(_timestamp).day;
    }

     
     
    function getHour(uint256 _timestamp) public pure returns (uint8) {
        return uint8((_timestamp.div(SECONDS_IN_HOUR)) % HOURS_IN_DAY);
    }

     
     
    function getMinute(uint256 _timestamp) public pure returns (uint8) {
        return uint8((_timestamp.div(SECONDS_IN_MINUTE)) % MINUTES_IN_HOUR);
    }

     
     
    function getSecond(uint256 _timestamp) public pure returns (uint8) {
        return uint8(_timestamp % SECONDS_IN_MINUTE);
    }

     
     
    function getWeekday(uint256 _timestamp) public pure returns (uint8) {
        return uint8((_timestamp.div(SECONDS_IN_DAY).add(4)) % DAYS_IN_WEEK);
    }

     
     
     
    function getBeginningOfMonth(uint16 _year, uint8 _month) public pure returns (uint256) {
        return toTimestamp(_year, _month, 1);
    }

     
     
     
    function getNextMonth(uint16 _year, uint8 _month) public pure returns (uint16 year, uint8 month) {
        if (_month == 12) {
            year = uint16(_year.add(1));
            month = 1;
        } else {
            year = _year;
            month = uint8(_month.add(1));
        }
    }

     
     
     
    function toTimestamp(uint16 _year, uint8 _month) public pure returns (uint) {
        return toTimestampFull(_year, _month, 0, 0, 0, 0);
    }

     
     
     
     
    function toTimestamp(uint16 _year, uint8 _month, uint8 _day) public pure returns (uint) {
        return toTimestampFull(_year, _month, _day, 0, 0, 0);
    }

     
     
     
     
     
     
     
    function toTimestampFull(uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minutes,
        uint8 _seconds) public pure returns (uint) {
        uint16 i;
        uint timestamp;

         
        for (i = ORIGIN_YEAR; i < _year; ++i) {
            if (isLeapYear(i)) {
                timestamp = timestamp.add(SECONDS_IN_LEAP_YEAR);
            } else {
                timestamp = timestamp.add(SECONDS_IN_YEAR);
            }
        }

         
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(_year)) {
            monthDayCounts[1] = 29;
        } else {
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

        for (i = 1; i < _month; ++i) {
            timestamp = timestamp.add(SECONDS_IN_DAY.mul(monthDayCounts[i.sub(1)]));
        }

         
        timestamp = timestamp.add(SECONDS_IN_DAY.mul(_day == 0 ? 0 : _day.sub(1)));

         
        timestamp = timestamp.add(SECONDS_IN_HOUR.mul(_hour));

         
        timestamp = timestamp.add(SECONDS_IN_MINUTE.mul(_minutes));

         
        timestamp = timestamp.add(_seconds);

        return timestamp;
    }

     
     
    function parseTimestamp(uint256 _timestamp) internal pure returns (DT memory dt) {
        uint256 secondsAccountedFor;
        uint256 buf;
        uint8 i;

         
        dt.year = getYear(_timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor = secondsAccountedFor.add(SECONDS_IN_LEAP_YEAR.mul(buf));
        secondsAccountedFor = secondsAccountedFor.add(SECONDS_IN_YEAR.mul((dt.year.sub(ORIGIN_YEAR).sub(buf))));

         
        uint256 secondsInMonth;
        for (i = 1; i <= 12; ++i) {
            secondsInMonth = SECONDS_IN_DAY.mul(getDaysInMonth(dt.year, i));
            if (secondsInMonth.add(secondsAccountedFor) > _timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor = secondsAccountedFor.add(secondsInMonth);
        }

         
        for (i = 1; i <= getDaysInMonth(dt.year, dt.month); ++i) {
            if (SECONDS_IN_DAY.add(secondsAccountedFor) > _timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor = secondsAccountedFor.add(SECONDS_IN_DAY);
        }

         
        dt.hour = getHour(_timestamp);

         
        dt.minute = getMinute(_timestamp);

         
        dt.second = getSecond(_timestamp);

         
        dt.weekday = getWeekday(_timestamp);
    }
}



interface ISubscriptionChecker {
     
     
    function getSubscriptionData(bytes32 _id) external view returns (bytes32 id, string memory profile, uint256 startTime, uint256 tokens);
}


 
contract OrbsSubscriptions is ISubscriptionChecker {
    using SafeMath for uint256;

     
    uint public constant VERSION = 2;

     
    IERC20 public orbs;

     
    IOrbsValidators public validators;

     
    uint public minimalMonthlySubscription;

    struct Subscription {
        bytes32 id;
        string profile;
        uint256 startTime;
        uint256 tokens;
    }

    struct MonthlySubscriptions {
        mapping(bytes32 => Subscription) subscriptions;
        uint256 totalTokens;
    }

     
     
     
    mapping(uint16 => mapping(uint8 => MonthlySubscriptions)) public subscriptions;

    bytes32 constant public EMPTY = bytes32(0);

    event Subscribed(address indexed subscriber, bytes32 indexed id, uint256 value, uint256 startFrom);
    event DistributedFees(address indexed validator, uint256 value);

     
     
     
     
    constructor(IERC20 orbs_, IOrbsValidators validators_, uint256 minimalMonthlySubscription_) public {
        require(address(orbs_) != address(0), "Address must not be 0!");
        require(address(validators_) != address(0), "OrbsValidators must not be 0!");
        require(minimalMonthlySubscription_ != 0, "Minimal subscription value must be greater than 0!");

        orbs = orbs_;
        validators = validators_;
        minimalMonthlySubscription = minimalMonthlySubscription_;
    }

     
     
    function getSubscriptionData(bytes32 _id) public view returns (bytes32 id, string memory profile, uint256 startTime,
        uint256 tokens) {
        require(_id != EMPTY, "ID must not be empty!");

         
        uint16 currentYear;
        uint8 currentMonth;
        (currentYear, currentMonth) = getCurrentTime();

        return getSubscriptionDataByTime(_id, currentYear, currentMonth);
    }

     
     
     
     
    function getSubscriptionDataByTime(bytes32 _id, uint16 _year, uint8 _month) public view returns (bytes32 id,
        string memory profile, uint256 startTime, uint256 tokens) {
        require(_id != EMPTY, "ID must not be empty!");

        MonthlySubscriptions storage monthlySubscription = subscriptions[_year][_month];
        Subscription memory subscription = monthlySubscription.subscriptions[_id];

        id = subscription.id;
        profile = subscription.profile;
        startTime = subscription.startTime;
        tokens = subscription.tokens;
    }

     
    function distributeFees() public {
         
        uint16 currentYear;
        uint8 currentMonth;
        (currentYear, currentMonth) = getCurrentTime();

        distributeFees(currentYear, currentMonth);
    }

     
    function distributeFees(uint16 _year, uint8 _month) public {
        uint16 currentYear;
        uint8 currentMonth;
        (currentYear, currentMonth) = getCurrentTime();

         
        require(DateTime.toTimestamp(currentYear, currentMonth) >= DateTime.toTimestamp(_year, _month),
            "Can't distribute future fees!");

        address[] memory validatorsAddress = validators.getValidators();
        uint validatorCount = validatorsAddress.length;

        MonthlySubscriptions storage monthlySubscription = subscriptions[_year][_month];
        uint256 fee = monthlySubscription.totalTokens.div(validatorCount);
        require(fee > 0, "Fee must be greater than 0!");

        for (uint i = 0; i < validatorCount; ++i) {
            address validator = validatorsAddress[i];
            uint256 validatorFee = fee;

             
            if (i == 0) {
                validatorFee = validatorFee.add(monthlySubscription.totalTokens % validatorCount);
            }

            monthlySubscription.totalTokens = monthlySubscription.totalTokens.sub(validatorFee);

            require(orbs.transfer(validator, validatorFee));
            emit DistributedFees(validator, validatorFee);
        }
    }

     
     
     
     
     
     
    function subscribeForCurrentMonth(bytes32 _id, string memory _profile, uint256 _value) public {
        subscribe(_id, _profile, _value, now);
    }

     
     
     
     
     
     
    function subscribeForNextMonth(bytes32 _id, string memory _profile, uint256 _value) public {
         
        uint16 currentYear;
        uint8 currentMonth;
        (currentYear, currentMonth) = getCurrentTime();

         
        uint16 nextYear;
        uint8 nextMonth;
        (nextYear, nextMonth) = DateTime.getNextMonth(currentYear, currentMonth);

        subscribe(_id, _profile, _value, DateTime.getBeginningOfMonth(nextYear, nextMonth));
    }

     
     
     
     
     
     
     
    function subscribe(bytes32 _id, string memory _profile, uint256 _value, uint256 _startTime) internal {
        require(_id != EMPTY, "ID must not be empty!");
        require(bytes(_profile).length > 0, "Profile must not be empty!");
        require(_value > 0, "Value must be greater than 0!");
        require(_startTime >= now, "Starting time must be in the future");

         
        require(orbs.transferFrom(msg.sender, address(this), _value), "Insufficient allowance!");

        uint16 year;
        uint8 month;
        (year, month) = getTime(_startTime);

         
        MonthlySubscriptions storage monthlySubscription = subscriptions[year][month];
        Subscription storage subscription = monthlySubscription.subscriptions[_id];

         
        if (subscription.id == EMPTY) {
            subscription.id = _id;
            subscription.profile = _profile;
            subscription.startTime = _startTime;
        }

         
        subscription.tokens = subscription.tokens.add(_value);

         
        require(subscription.tokens >= minimalMonthlySubscription, "Subscription value is too low!");

         
        monthlySubscription.totalTokens = monthlySubscription.totalTokens.add(_value);

        emit Subscribed(msg.sender, _id, _value, _startTime);
    }

     
     
     
    function getCurrentTime() private view returns (uint16 year, uint8 month) {
        return getTime(now);
    }

     
     
     
     
    function getTime(uint256 _time) private pure returns (uint16 year, uint8 month) {
        year = DateTime.getYear(_time);
        month = DateTime.getMonth(_time);
    }
}