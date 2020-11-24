 

pragma solidity ^0.5.2;

 
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

 
contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract Pauser is Ownable {

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    mapping (address => bool) private pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return pausers[account];
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function renouncePauser(address account) public {
        require(msg.sender == account || isOwner());
        _removePauser(account);
    }

    function _addPauser(address account) internal {
        pausers[account] = true;
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        pausers[account] = false;
        emit PauserRemoved(account);
    }
}

 
contract Pausable  is Pauser {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

library BokkyDateTime {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

     
     
     
     
     
     
     
     
     
     
     
     
     
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
     
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 
interface IERC20 {

    function decimals() external view returns (uint8);

     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         
        
         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

 
contract PostAuditSubscriptions is Pausable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using BokkyDateTime for *;

     
    address public subOracle;

     
     
    uint256 public idCount;

     
    address public monarch;

     
    uint256 public adminFee;

     
    uint256 public gasAmt;
    uint256 public gasPriceCap;

     
     
    mapping (address => mapping (uint256 => Subscription)) public subscriptions;

     
    mapping (uint256 => Template) public templates;

     
    mapping (address => mapping (address => uint256)) public balances;

     
    mapping (address => uint256) public approvedTokens;

     
    mapping (address => uint256) public tokenPrices;

     
    event Creation(uint256 indexed id, address indexed recipient, address token, uint256 price, uint256 interval,
                   uint8 target, bool setLen, uint48 payments, address creator, bool payNow, bool payInFiat);

     
    event Deposit(address indexed user, address indexed token, uint256 balance);

     
    event Withdrawal(address indexed user, address indexed token, uint256 balance);

     
    event NewBals(address[4] users, uint256[4] balances, address token);

     
    event NotDue(address indexed user, uint256 indexed id);

     
    event Paid(address indexed user, uint256 indexed id, uint48 nextDue, uint256 datetime, bool setLen, uint48 paymentsLeft);

     
    event Failed(address indexed user, uint256 indexed id, uint256 datetime);

     
    event Subscribed(address indexed user, uint256 indexed id, uint256 datetime, uint48 nextDue);

     
    event Unsubscribed(address indexed user, uint256 indexed id, uint256 datetime);

     
    struct Template {
        uint256 price;
        address recipient;
        uint48 interval;
        uint8 target;
        address token;
        bool setLen;
        uint48 payments;
        address creator;
        bool payNow;
        bool payInFiat;
    }

     
    struct Subscription {
        uint48 startTime;
        uint48 lastPaid;
        uint48 nextDue;
        uint48 paymentsLeft;
        bool startPaid;
    }

 

     
    constructor(address _subOracle, address _monarch)
      public
    {
        subOracle = _subOracle;
        approveToken(address(0), true);
        approveToken(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359, true);
        tokenPrices[address(0)] = 1 ether;
        setMonarch(_monarch);
        setAdminFee(100);

         
        setGasFees(85000, 40000000000);
    }

 

     
    function deposit(address _token, uint256 _amount)
      public
      payable
      whenNotPaused
    {
        require(approvedTokens[_token] > 0, "You may only deposit approved tokens.");
        require(_amount > 0, "You must deposit a non-zero amount.");

        if (_token != address(0)) {

            IERC20 token = IERC20(_token);
            SafeERC20.safeTransferFrom(token, msg.sender, address(this), _amount);

        } else {

            _amount = msg.value;
            require(_amount > 0, "No Ether was included in the transaction.");

        }

        uint256 newBal = balances[msg.sender][_token].add(_amount);
        balances[msg.sender][_token] = newBal;

        emit Deposit(msg.sender, _token, newBal);
    }

     
    function withdraw(address _token, uint256 _amount)
      external
    {
        require(_amount > 0, "You must withdraw a non-zero amount.");

         
        uint256 newBal = balances[msg.sender][_token].sub(_amount);
        balances[msg.sender][_token] = newBal;

        if (_token != address(0)) {

            IERC20 token = IERC20(_token);
            SafeERC20.safeTransfer(token, msg.sender, _amount);

        } else {

            msg.sender.transfer(_amount);

        }

        emit Withdrawal(msg.sender, _token, newBal);
    }

 

     
    function subscribe(uint256 _id)
      public
      whenNotPaused
    {
         
        require(_id != 0 && _id <= idCount, "Subscription does not exist.");

         
        require(subscriptions[msg.sender][_id].lastPaid == 0, "User is already subscribed.");

        Template memory template = templates[_id];

         
        uint48 lastPaid;
        uint48 nextDue;

        if (template.target > 0) {

            lastPaid = uint48(now);

             
            uint256 pstNow = BokkyDateTime.subHours(now, 8);

             
            uint256 year = BokkyDateTime.getYear(pstNow);
            uint256 month = BokkyDateTime.getMonth(pstNow);
            uint256 day = BokkyDateTime.getDay(pstNow);

             
            if (day < template.target) nextDue = uint48(BokkyDateTime.timestampFromDate(year, month, template.target));
            else nextDue = uint48(BokkyDateTime.timestampFromDate(BokkyDateTime.getYear(BokkyDateTime.addMonths(pstNow, 1)), (month % 12) + 1, template.target));

        } else {

            lastPaid = uint48(now);
            nextDue = uint48(now + template.interval);

        }

        subscriptions[msg.sender][_id] = Subscription(uint48(now), lastPaid, nextDue, template.payments, false);
        emit Subscribed(msg.sender, _id, now, nextDue);

        if (template.payNow) require(payment(msg.sender, _id), "Payment failed.");
    }

     
    function unsubscribe(uint256 _id)
      public
    {
        _unsubscribe(msg.sender, _id);
    }

     
    function unsubscribeUser(address _user, uint256 _id)
      public
    {
        require(msg.sender == templates[_id].creator, "Only the template creator may unsubscribe a user.");
        _unsubscribe(_user, _id);
    }

     
    function _unsubscribe(address _user, uint256 _id)
      internal
    {
        delete subscriptions[_user][_id];
        emit Unsubscribed(_user, _id, now);
    }

     
    function depositAndSubscribe(address _token, uint256 _amount, uint256 _id)
      public
      payable
      whenNotPaused
    {
        deposit(_token, _amount);
        subscribe(_id);
    }

 

     
    function payment(address _user, uint256 _id)
      public
      whenNotPaused
    returns (bool)
    {
        Subscription memory sub = subscriptions[_user][_id];
        Template memory template = templates[_id];

         
        if (template.payInFiat) template.price = tokenToFiat(template.token, template.price);

         
        if (!checkDue(_user, _id, template, sub)) return false;

         
        updateBals(_user, template);

         
        sub = updateDue(_user, _id, template, sub);

        emit Paid(_user, _id, sub.nextDue, now, template.setLen, sub.paymentsLeft);

        return true;
    }

     
    function tokenToFiat(address _token, uint256 _usdAmount)
      public
      view
    returns (uint256 tokenAmount)
    {
         
        uint256 daiPerEth = tokenPrices[0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359];
        uint256 tokenPerEth = tokenPrices[_token];

         
        tokenAmount = (_usdAmount.mul(1 ether)).div(((daiPerEth.mul(1 ether)).div((tokenPerEth))));

         
        uint256 decimals = 10 ** approvedTokens[_token];
        tokenAmount = tokenAmount.mul(decimals).div(1 ether);
    }

     
    function checkDue(address _user, uint256 _id, Template memory _template, Subscription memory _sub)
      internal
    returns (bool due)
    {
         
        uint256 balance = balances[_user][_template.token];

         
        if (balance < _template.price) {

            emit Failed(_user, _id, now);
            return false;

        }

         
        if (_sub.lastPaid == 0) {

            emit NotDue(_user, _id);
            return false;

        }

         
        if (_template.payNow && !_sub.startPaid) return true;

         
        if (_sub.nextDue >= now) {

            emit NotDue(_user, _id);
            return false;

        }

        return true;
    }

     
    function updateBals(address _user, Template memory _template)
      internal
    {
        address token = _template.token;
        uint256 price = _template.price;
        uint256 monarchFee = price / adminFee;

        uint256 gasPrice = tx.gasprice;
        if (gasPrice > gasPriceCap) gasPrice = gasPriceCap;

         
        uint256 gasFee;
        if (token != address(0)) gasFee = (tokenPrices[token].mul(gasAmt).mul(gasPrice)).div(1 ether);
        else gasFee = gasAmt.mul(gasPrice);

         
        uint256 userBal = balances[_user][token].sub(price);
        balances[_user][token] = userBal;

         
        uint256 recipBal = balances[_template.recipient][token].add(price.sub(gasFee.add(monarchFee)));
        balances[_template.recipient][token] = recipBal;

         
        uint256 paydBal = balances[msg.sender][token].add(gasFee);
        balances[msg.sender][token] = paydBal;

         
        uint256 monarchBal = balances[monarch][token].add(monarchFee);
        balances[monarch][token] = monarchBal;

        emit NewBals([_user, _template.recipient, msg.sender, monarch], [userBal, recipBal, paydBal, monarchBal], token);
    }

     
    function updateDue(address _user, uint256 _id, Template memory _template, Subscription memory _sub)
      internal
    returns (Subscription memory)
    {
         
        bool payNow = _template.payNow && !_sub.startPaid;

         
        if (!payNow && _template.interval > 0) {

            _sub.lastPaid = _sub.nextDue;
            _sub.nextDue = _sub.lastPaid + _template.interval;

        } else if (!payNow) {

            _sub.lastPaid = _sub.nextDue;
            _sub.nextDue = uint48(BokkyDateTime.addMonths(_sub.lastPaid, 1));

        }

         
        if (_template.setLen) _sub.paymentsLeft = _sub.paymentsLeft - 1;

         
        if (payNow) _sub.startPaid = true;

        if (_template.setLen && _sub.paymentsLeft == 0) _unsubscribe(_user, _id);
        else subscriptions[_user][_id] = _sub;

        return _sub;
    }

     
    function bulkPayments(address[] calldata _users, uint256[] calldata _ids)
      external
      whenNotPaused
    {
        require(_users.length == _ids.length, "The submitted arrays are of uneven length.");

        for (uint256 i = 0; i < _users.length; i++) {

            payment(_users[i], _ids[i]);

        }
    }

 

     
    function createTemplate(address payable _recipient, address _token, uint256 _price, uint48 _interval,
                            uint8 _target, bool _setLen, uint48 _payments, bool _payNow, bool _payInFiat)
      public
      whenNotPaused
    returns (uint256 id)
    {
         
        require((_interval >= 86400 && _target == 0) || (_interval == 0 && _target > 0), "You must choose >= 1 day interval or target.");

         
        require(_interval <= 3153600000, "You may not have an interval of over 100 years.");

         
        if (_target > 0) require(_target <= 28, "Target must be a valid day.");

         
        require(approvedTokens[_token] > 0, "The desired token is not on the approved tokens list.");

         
        require(_price >= tokenToFiat(_token, 1 ether), "Your subscription must have a price of at least $1.");

         
        if (_setLen) require(_payments > 0, "A set-length template must have non-zero payments.");
        else require(_payments == 0, "A non-set-length template must have zero payments.");

        Template memory template = Template(_price, _recipient, _interval, _target, _token, _setLen, _payments, msg.sender, _payNow, _payInFiat);

        idCount++;
        id = idCount;
        templates[id] = template;

        emit Creation(id, _recipient, _token, _price, _interval, _target, _setLen, _payments, msg.sender, _payNow, _payInFiat);
    }

     
    function createAndSubscribe(address payable _recipient, address _token, uint256 _price, uint48 _interval,
                                uint8 _target, bool _setLen, uint48 _payments, bool _payNow, bool _payInFiat)
      external
      whenNotPaused
    {
        uint256 id = createTemplate(_recipient, _token, _price, _interval, _target, _setLen, _payments, _payNow, _payInFiat);
        subscribe(id);
    }

     
    function createDepositAndSubscribe(address payable _recipient, address _token, uint256 _price, uint48 _interval, uint8 _target,
                                       bool _setLen, uint48 _payments, bool _payNow, bool _payInFiat, uint256 _amount)
        external
        payable
        whenNotPaused
    {
        uint256 id = createTemplate(_recipient, _token, _price, _interval, _target, _setLen, _payments, _payNow, _payInFiat);
        deposit(_token, _amount);
        subscribe(id);
    }

 

     
    modifier onlyOracle
    {
        require(msg.sender == subOracle, "Only the oracle may call this function.");
        _;
    }

     
    function setPrices(address[] calldata _tokens, uint256[] calldata _prices)
      external
      onlyOracle
    {
        require(_tokens.length == _prices.length, "Submitted arrays are of uneven length.");

        for (uint256 i = 0; i < _tokens.length; i++) {

            require(approvedTokens[_tokens[i]] > 0, "Price may only be set for approved tokens.");
            tokenPrices[_tokens[i]] = _prices[i];

        }
    }

 

     
    function bulkWithdraw(address payable[] calldata _users, address[] calldata _tokens)
      external
      onlyOwner
    {
        require(_users.length == _tokens.length, "Submitted arrays are of uneven length.");

        for (uint256 i = 0; i < _users.length; i++) {

            address payable user = _users[i];
            address token = _tokens[i];

            uint256 balance = balances[user][token];
            if (balance == 0) continue;

            balances[user][token] = 0;

            if (token != address(0)) {

                IERC20 tokenC = IERC20(token);
                SafeERC20.safeTransfer(tokenC, user, balance);

                 

            } else {

                 
                if (!user.send(balance)) {
                    balances[user][token] = balance;
                    continue;
                }

            }

            emit Withdrawal(user, token, balance);
        }

    }

     
    function setMonarch(address _monarch)
      public
      onlyOwner
    {
        monarch = _monarch;
    }

     
    function approveToken(address _token, bool _add)
      public
      onlyPauser
    {
        if (_add) {

            uint256 decimals;
             
             
            decimals = 18;

            approvedTokens[_token] = decimals;

        } else {

            delete approvedTokens[_token];

        }
    }

     
    function setGasFees(uint256 _gasAmt, uint256 _gasPriceCap)
      public
      onlyPauser
    {
         
        require(_gasAmt <= 85000, "Desired gas amount is too high.");

         
        require(_gasPriceCap <= 40000000000, "Desired gas price is too high.");

        gasAmt = _gasAmt;
        gasPriceCap = _gasPriceCap;
    }

     
    function setAdminFee(uint256 _adminFee)
      public
      onlyPauser
    {
         
        require(_adminFee >= 10, "Desired fee is too large.");
        adminFee = _adminFee;
    }

}