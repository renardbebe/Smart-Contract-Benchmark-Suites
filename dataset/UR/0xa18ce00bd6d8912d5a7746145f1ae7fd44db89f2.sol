 

pragma solidity 0.5.8;

interface DateTimeAPI {
    function getYear(uint timestamp) external pure returns (uint16);

    function getMonth(uint timestamp) external pure returns (uint8);

    function getDay(uint timestamp) external pure returns (uint8);

    function getHour(uint timestamp) external pure returns (uint8);

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) external pure returns (uint);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Called by unknown account");
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract DateTime {
     
    struct _DateTime {
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

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
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

         
        dt.hour = getHour(timestamp);

         
        dt.minute = getMinute(timestamp);

         
        dt.second = getSecond(timestamp);

         
        dt.weekday = getWeekday(timestamp);
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

    function getWeekday(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
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

contract EJackpot is Ownable {
    event CaseOpened(
        uint amount,
        uint prize,
        address indexed user,
        uint indexed timestamp
    );

    struct ReferralStat {
        uint profit;
        uint count;
    }

    struct Probability {
        uint from;
        uint to;
    }

    uint public usersCount = 0;
    uint public openedCases = 0;
    uint public totalWins = 0;
    Probability[1 ] public probabilities;
    mapping(uint => uint[11]) public betsPrizes;
    mapping(uint => bool) public cases;
    uint[1 ] public casesArr = [
    5 * 10 ** 16 
    ];
    mapping(uint => uint) public caseWins;
    mapping(uint => uint) public caseOpenings;
    mapping(address => bool) private users;
    mapping(address => uint) private userCasesCount;
    mapping(address => address payable) private referrals;
    mapping(address => mapping(address => bool)) private usedReferrals;
    mapping(address => ReferralStat) public referralStats;
    uint private constant multiplier = 1 ether / 10000;
    DateTimeAPI private dateTimeAPI;

     
    constructor(address _dateTimeAPI) public Ownable() {
        dateTimeAPI = DateTimeAPI(_dateTimeAPI);
        for (uint i = 0; i < 1 ; i++) cases[casesArr[i]] = true;
        probabilities[0] = Probability(1, 100 );
 
 
 
 
 
 
 
 
 
 

        betsPrizes[5 * 10 ** 16] = [65, 100, 130, 170, 230, 333, 500, 666, 1350, 2000, 2500];
 
 
 
 
 
 
 
 
    }

     
    function showCoefs() external view returns (uint[1 ] memory result){
        uint d = 10000;

        for (uint casesIndex = 0; casesIndex < casesArr.length; casesIndex++) {
            uint sum = 0;
            uint casesVal = casesArr[casesIndex];

            for (uint i = 0; i < probabilities.length; i++) {
                sum += multiplier * betsPrizes[casesVal][i] * (probabilities[i].to - probabilities[i].from + 1);
            }

            result[casesIndex] = ((d * sum) / (casesVal * 100));
        }
    }

     
    function play(address payable referrer) external payable notContract(msg.sender, false) notContract(referrer, true) {
        if (msg.sender == owner) return;
        uint maxPrize = betsPrizes[msg.value][betsPrizes[msg.value].length - 1] * multiplier;
        require(cases[msg.value] && address(this).balance >= maxPrize, "Contract balance is not enough");
        openedCases++;
        userCasesCount[msg.sender]++;
        if (!users[msg.sender]) {
            users[msg.sender] = true;
            usersCount++;
        }
        uint prize = determinePrize();
        caseWins[msg.value] += prize;
        caseOpenings[msg.value]++;
        totalWins += prize;
        increaseDailyStat(prize);
        msg.sender.transfer(prize);

        if (referrer == address(0x0) && referrals[msg.sender] == address(0x0)) return;

        int casinoProfit = int(msg.value) - int(prize);
        if (referrer != address(0x0)) {
            if (referrals[msg.sender] != address(0x0) && referrer != referrals[msg.sender]) referralStats[referrals[msg.sender]].count -= 1;
            referrals[msg.sender] = referrer;
        }
        if (!usedReferrals[referrals[msg.sender]][msg.sender]) {
            referralStats[referrals[msg.sender]].count++;
            usedReferrals[referrals[msg.sender]][msg.sender] = true;
        }
        if (casinoProfit <= 0) return;
        uint referrerProfit = uint(casinoProfit * 10 / 100);
        referralStats[referrals[msg.sender]].profit += referrerProfit;
        referrals[msg.sender].transfer(referrerProfit);
    }

     
    function determinePrize() private returns (uint) {
        uint8 chance = random();
        uint[11] memory prizes = betsPrizes[msg.value];
        uint prize = 0;
        for (uint i = 0; i < 1 ; i++) {
            if (chance >= probabilities[i].from && chance <= probabilities[i].to) {
                prize = prizes[i] * multiplier;
                break;
            }
        }

        return prize;
    }

     
    function increaseDailyStat(uint prize) private {
        uint16 year = dateTimeAPI.getYear(now);
        uint8 month = dateTimeAPI.getMonth(now);
        uint8 day = dateTimeAPI.getDay(now);
        uint8 hour = dateTimeAPI.getHour(now);
        uint timestamp = dateTimeAPI.toTimestamp(year, month, day, hour);

        emit CaseOpened(msg.value, prize, msg.sender, timestamp);
    }

     
    function withdraw(uint amount) external onlyOwner {
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }

    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, userCasesCount[msg.sender]))) % 100) + 1;
    }

    modifier notContract(address addr, bool referrer) {
        if (addr != address(0x0)) {
            uint size;
            assembly {size := extcodesize(addr)}
            require(size <= 0, "Called by contract");
            if (!referrer) require(tx.origin == addr, "Called by contract");
        }
        _;
    }
}