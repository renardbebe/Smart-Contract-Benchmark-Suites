 

pragma solidity ^0.4.18;

 
library Referral {

     
    struct Node {
         
        address referrer;
         
        mapping (address => uint) invitees;
         
        address[] inviteeIndex;
         
        uint shares;
         
        bool exists;
    }

     
    struct Tree {
         
        mapping (address => Referral.Node) nodes;
         
        address[] treeIndex;
    }

     
    function getReferrer (
        Tree storage self,
        address _invitee
    )
        public
        constant
        returns (address _referrer)
    {
        _referrer = self.nodes[_invitee].referrer;
    }

     
    function getTreeSize (
        Tree storage self
    )
        public
        constant
        returns (uint _size)
    {
        _size = self.treeIndex.length;
    }

     
    function addInvitee (
        Tree storage self,
        address _referrer,
        address _invitee,
        uint _shares
    )
        internal
    {
        Node memory inviteeNode;
        inviteeNode.referrer = _referrer;
        inviteeNode.shares = _shares;
        inviteeNode.exists = true;
        self.nodes[_invitee] = inviteeNode;
        self.treeIndex.push(_invitee);

        if (self.nodes[_referrer].exists == true) {
            self.nodes[_referrer].invitees[_invitee] = _shares;
            self.nodes[_referrer].inviteeIndex.push(_invitee);
        }
    }
}

pragma solidity ^0.4.18;

 
library TieredPayoff {
    using SafeMath for uint;

     
    function payoff(
        Referral.Tree storage self,
        address _referrer
    )
        public
        view
        returns (uint)
    {
        Referral.Node node = self.nodes[_referrer];

        if(!node.exists) {
            return 0;
        }

        uint reward = 0;
        uint shares = 0;
        uint degree = node.inviteeIndex.length;
        uint tierPercentage = getBonusPercentage(node.inviteeIndex.length);

         
        if(degree == 0) {
            return 0;
        }

        assert(tierPercentage > 0);

        if(degree == 1) {
            shares = node.invitees[node.inviteeIndex[0]];
            reward = reward.add(shares.mul(tierPercentage).div(100));
            return reward;
        }


         
         
         
        if(degree >= 2 && degree <= 27) {
            for (uint i = 0; i < (degree - 1); i++) {
                shares = node.invitees[node.inviteeIndex[i]];
                reward = reward.add(shares.mul(1).div(100));
            }
        }

         
        shares = node.invitees[node.inviteeIndex[degree - 1]];
        reward = reward.add(shares.mul(tierPercentage).div(100));

        return reward;
    }

     
    function getBonusPercentage(
        uint _referrals
    )
        public
        pure
        returns (uint)
    {
        if (_referrals == 0) {
            return 0;
        }
        if (_referrals >= 27) {
            return 33;
        }
        return _referrals + 6;
    }
}


contract DateTimeAPI {
         
        function isLeapYear(uint16 year) constant returns (bool);
        function getYear(uint timestamp) constant returns (uint16);
        function getMonth(uint timestamp) constant returns (uint8);
        function getDay(uint timestamp) constant returns (uint8);
        function getHour(uint timestamp) constant returns (uint8);
        function getMinute(uint timestamp) constant returns (uint8);
        function getSecond(uint timestamp) constant returns (uint8);
        function getWeekday(uint timestamp) constant returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) constant returns (uint timestamp);
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) constant returns (uint timestamp);
}

pragma solidity ^0.4.16;

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

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt) {
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


pragma solidity ^0.4.18;

 
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

pragma solidity ^0.4.18;
library PresaleBonuses {
    using SafeMath for uint;

    function presaleBonusApplicator(uint _purchased, address _dateTimeLib)
        internal view returns (uint reward)
    {
        DateTimeAPI dateTime = DateTimeAPI(_dateTimeLib);
        uint hour = dateTime.getHour(block.timestamp);
        uint day = dateTime.getDay(block.timestamp);

         
        if (day == 2 && hour >= 16 && hour < 20) {
            return applyPercentage(_purchased, 70);
        }

         
        if ((day == 2 && hour >= 20) || (day == 3 && hour < 5)) {
            return applyPercentage(_purchased, 50);
        }

         
        if ((day == 3 && hour >= 5) || (day == 4 && hour < 5)) {
            return applyPercentage(_purchased, 45);
        } 

         
        if (day < 22) {
            uint numDays = day - 3;
            if (hour < 5) {
                numDays--;
            }

            return applyPercentage(_purchased, (45 - numDays));
        }

         
        if (day == 22 && hour < 5) {
            return applyPercentage(_purchased, 27);
        }

         
        if ((day == 22 && hour >= 5) || (day == 23 && hour < 5)) {
            return applyPercentage(_purchased, 25);
        }

         
        if ((day == 23 && hour >= 5) || (day == 24 && hour < 5)) {
            return applyPercentage(_purchased, 20);
        }

         
        if ((day == 24 && hour >= 5) || (day == 25 && hour < 5)) {
            return applyPercentage(_purchased, 15);
        }

         
        revert();
    }

     
    function applyPercentage(uint _base, uint _percentage)
        internal pure returns (uint num)
    {
        num = _base.mul(_percentage).div(100);
    }
    
}

pragma solidity ^0.4.11;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable()
        public
    {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(
        address newOwner
    )
        onlyOwner
        public
    {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

pragma solidity ^0.4.8;
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

pragma solidity ^0.4.8;
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

pragma solidity ^0.4.8;
contract HumanStandardToken is StandardToken {

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    function HumanStandardToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}

pragma solidity ^0.4.17;
 
contract Share is HumanStandardToken, Ownable {
    using SafeMath for uint;

    string public constant TOKEN_NAME = "Vyral Token";

    string public constant TOKEN_SYMBOL = "SHARE";

    uint8 public constant TOKEN_DECIMALS = 18;

    uint public constant TOTAL_SUPPLY = 777777777 * (10 ** uint(TOKEN_DECIMALS));

    mapping (address => uint256) lockedBalances;

    mapping (address => bool) public transferrers;

     
    function Share() HumanStandardToken(TOTAL_SUPPLY, TOKEN_NAME, TOKEN_DECIMALS, TOKEN_SYMBOL)
        public
    {
        transferrers[msg.sender] = true;
    }

     
     
     

     
    bool isTransferable = false;

     
    bool isBonusLocked = true;

     
    modifier canBeTransferred {
        require(transferrers[msg.sender] || isTransferable);
        _;
    }

    function transferReward(
        address _to,
        uint _value
    )
        canBeTransferred
        public
        returns (bool)
    {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        lockedBalances[_to] = lockedBalances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transfer(
        address _to,
        uint _value
    )
        canBeTransferred
        public
        returns (bool)
    {
        require(balances[msg.sender] >= _value);

         
        if(isBonusLocked) {
            require(balances[msg.sender].sub(lockedBalances[msg.sender]) >= _value);
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    )
        canBeTransferred
        public
        returns (bool)
    {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

         
        if(isBonusLocked) {
            require(balances[_from].sub(lockedBalances[_from]) >= _value);
        }

        allowed[_from][msg.sender] = allowed[_from][_to].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function lockedBalanceOf(
        address _owner
    )
        constant
        returns (uint)
    {
        return lockedBalances[_owner];
    }

     
     
     

    function enableTransfers()
        onlyOwner
        external
        returns (bool)
    {
        isTransferable = true;

        return isTransferable;
    }

    function addTransferrer(
        address _transferrer
    )
        public
        onlyOwner
    {
        transferrers[_transferrer] = true;
    }


     
    function releaseBonus()
        public
        onlyOwner
    {
        isBonusLocked = false;
    }

}

pragma solidity ^0.4.18;

 
contract Campaign is Ownable {
    using SafeMath for uint;
    using Referral for Referral.Tree;
    using TieredPayoff for Referral.Tree;

     
    Referral.Tree vyralTree;

     
    Share public token;

     
    uint public budget;

     
    uint public cost;

     

    modifier onlyNonZeroAddress(address _a) {
        require(_a != 0);
        _;
    }

    modifier onlyNonSelfReferral(address _referrer, address _invitee) {
        require(_referrer != _invitee);
        _;
    }

    modifier onlyOnReferral(address _invitee) {
        require(getReferrer(_invitee) != 0x0);
        _;
    }

    modifier onlyIfFundsAvailable() {
        require(getAvailableBalance() >= 0);
        _;
    }


     

     
    event LogCampaignCreated(address campaign);

     
    event LogRewardAllocated(address referrer, uint inviteeShares, uint referralReward);


     
    function Campaign(
        address _token,
        uint256 _budgetAmount
    )
        public
    {
        token = Share(_token);
        budget = _budgetAmount;
    }

     
    function join(
        address _referrer,
        address _invitee,
        uint _shares
    )
        public
        onlyOwner
        onlyNonZeroAddress(_invitee)
        onlyNonSelfReferral(_referrer, _invitee)
        onlyIfFundsAvailable()
        returns(uint reward)
    {
        Referral.Node memory referrerNode = vyralTree.nodes[_referrer];

         
        if(referrerNode.exists == false) {
            vyralTree.addInvitee(owner, _referrer, 0);
        }

         
        vyralTree.addInvitee(_referrer, _invitee, _shares);

         
        reward = vyralTree.payoff(_referrer);

         
        LogRewardAllocated(_referrer, _shares, reward);
    }

     
    function sendReward(address _who, uint _amount)
        onlyOwner  
        external returns (bool)
    {
        if(getAvailableBalance() >= _amount) {
            token.transferReward(_who, _amount);
            cost = cost.add(_amount);
            return true;
        } else {
            return false;
        }
    }

     
    function getReferrer(
        address _invitee
    )
        public
        constant
        returns (address _referrer)
    {
        _referrer = vyralTree.getReferrer(_invitee);
    }

     
    function getTreeSize()
        public
        constant
        returns (uint _size)
    {
        _size = vyralTree.getTreeSize();
    }

     
    function getBudget()
        public
        constant
        returns (address _token, uint _amount)
    {
        _token = token;
        _amount = budget;
    }

     
    function getAvailableBalance()
        public
        constant
        returns (uint _balance)
    {
        _balance = (budget - cost);
    }

     
    function() public {
        revert();
    }
}

pragma solidity ^0.4.17;
contract Vesting is Ownable {
    using SafeMath for uint;

    Token public vestingToken;           

    struct VestingSchedule {
        uint startTimestamp;             
        uint cliffTimestamp;             
        uint lockPeriod;                 
        uint endTimestamp;               
        uint totalAmount;                
        uint amountWithdrawn;            
        address depositor;               
        bool isConfirmed;                
    }

     
    mapping (address => VestingSchedule) vestingSchedules;

     
     
    function Vesting(address _token) public {
        vestingToken = Token(_token);
    }

    function registerVestingSchedule(address _newAddress,
                                    address _depositor,
                                    uint _startTimestamp,
                                    uint _cliffTimestamp,
                                    uint _lockPeriod,
                                    uint _endTimestamp,
                                    uint _totalAmount)
        public onlyOwner
    {
         
         
        require( _depositor != 0x0 );
        require( vestingSchedules[_newAddress].depositor == 0x0 );

         
        require( _cliffTimestamp >= _startTimestamp );
        require( _endTimestamp > _cliffTimestamp );

         
        require( _lockPeriod != 0 ); 
        require( _endTimestamp.sub(_startTimestamp) > _lockPeriod );

         
        vestingSchedules[_newAddress] = VestingSchedule({
            startTimestamp: _startTimestamp,
            cliffTimestamp: _cliffTimestamp,
            lockPeriod: _lockPeriod,
            endTimestamp: _endTimestamp,
            totalAmount: _totalAmount,
            amountWithdrawn: 0,
            depositor: _depositor,
            isConfirmed: false
        });

         
        VestingScheduleRegistered(
            _newAddress,
            _depositor,
            _startTimestamp,
            _lockPeriod,
            _cliffTimestamp,
            _endTimestamp,
            _totalAmount
        );
    }

    function confirmVestingSchedule(uint _startTimestamp,
                                    uint _cliffTimestamp,
                                    uint _lockPeriod,
                                    uint _endTimestamp,
                                    uint _totalAmount)
        public
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];

         
        require( vestingSchedule.depositor != 0x0 );
        require( vestingSchedule.isConfirmed == false );

         
        require( vestingSchedule.startTimestamp == _startTimestamp );
        require( vestingSchedule.cliffTimestamp == _cliffTimestamp );
        require( vestingSchedule.lockPeriod == _lockPeriod );
        require( vestingSchedule.endTimestamp == _endTimestamp );
        require( vestingSchedule.totalAmount == _totalAmount );

         
        vestingSchedule.isConfirmed = true;
        require(vestingToken.transferFrom(vestingSchedule.depositor, address(this), _totalAmount));

         
        VestingScheduleConfirmed(
            msg.sender,
            vestingSchedule.depositor,
            vestingSchedule.startTimestamp,
            vestingSchedule.cliffTimestamp,
            vestingSchedule.lockPeriod,
            vestingSchedule.endTimestamp,
            vestingSchedule.totalAmount
        );
    }

    function withdrawVestedTokens()
        public 
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];

         
        require( vestingSchedule.isConfirmed == true );
        require( vestingSchedule.cliffTimestamp <= now );

        uint totalAmountVested = calculateTotalAmountVested(vestingSchedule);
        uint amountWithdrawable = totalAmountVested.sub(vestingSchedule.amountWithdrawn);
        vestingSchedule.amountWithdrawn = totalAmountVested;

        if (amountWithdrawable > 0) {
            canWithdraw(vestingSchedule, amountWithdrawable);
            require( vestingToken.transfer(msg.sender, amountWithdrawable) );
            Withdraw(msg.sender, amountWithdrawable);
        }
    }

    function calculateTotalAmountVested(VestingSchedule _vestingSchedule)
        internal view returns (uint _amountVested)
    {
         
        if (now >= _vestingSchedule.endTimestamp) {
            return _vestingSchedule.totalAmount;
        }

         
        uint durationSinceStart = now.sub(_vestingSchedule.startTimestamp);
        uint totalVestingTime = SafeMath.sub(_vestingSchedule.endTimestamp, _vestingSchedule.startTimestamp);
        uint vestedAmount = SafeMath.div(
            SafeMath.mul(durationSinceStart, _vestingSchedule.totalAmount),
            totalVestingTime
        );

        return vestedAmount;
    }

     
    function canWithdraw(VestingSchedule _vestingSchedule, uint _amountWithdrawable)
        internal view
    {
        uint lockPeriods = (_vestingSchedule.endTimestamp.sub(_vestingSchedule.startTimestamp))
                                                         .div(_vestingSchedule.lockPeriod);

        if (now < _vestingSchedule.endTimestamp) {
            require( _amountWithdrawable >= _vestingSchedule.totalAmount.div(lockPeriods) );
        }
    }

     

    function revokeSchedule(address _addressToRevoke, address _addressToRefund)
        public onlyOwner
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[_addressToRevoke];

        require( vestingSchedule.isConfirmed == true );
        require( _addressToRefund != 0x0 );

        uint amountWithdrawable;
        uint amountRefundable;

        if (now < vestingSchedule.cliffTimestamp) {
             
            amountRefundable = vestingSchedule.totalAmount;

            delete vestingSchedules[_addressToRevoke];
            require( vestingToken.transfer(_addressToRefund, amountRefundable) );
        } else {
             
            uint totalAmountVested = calculateTotalAmountVested(vestingSchedule);
            amountWithdrawable = totalAmountVested.sub(vestingSchedule.amountWithdrawn);
            amountRefundable = totalAmountVested.sub(vestingSchedule.amountWithdrawn);

            delete vestingSchedules[_addressToRevoke];
            require( vestingToken.transfer(_addressToRevoke, amountWithdrawable) );
            require( vestingToken.transfer(_addressToRefund, amountRefundable) );
        }

        VestingRevoked(_addressToRevoke, amountWithdrawable, amountRefundable);
    }

     
    function changeVestingAddress(address _oldAddress, address _newAddress)
        public onlyOwner
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[_oldAddress];

        require( vestingSchedule.isConfirmed == true );
        require( _newAddress != 0x0 );
        require( vestingSchedules[_newAddress].depositor == 0x0 );

        VestingSchedule memory newVestingSchedule = vestingSchedule;
        delete vestingSchedules[_oldAddress];
        vestingSchedules[_newAddress] = newVestingSchedule;

        VestingAddressChanged(_oldAddress, _newAddress);
    }

    event VestingScheduleRegistered(
        address registeredAddress,
        address depositor,
        uint startTimestamp,
        uint cliffTimestamp,
        uint lockPeriod,
        uint endTimestamp,
        uint totalAmount
    );
    event VestingScheduleConfirmed(
        address registeredAddress,
        address depositor,
        uint startTimestamp,
        uint cliffTimestamp,
        uint lockPeriod,
        uint endTimestamp,
        uint totalAmount
    );
    event Withdraw(address registeredAddress, uint amountWithdrawn);
    event VestingRevoked(address revokedAddress, uint amountWithdrawn, uint amountRefunded);
    event VestingAddressChanged(address oldAddress, address newAddress);
}


 
 
 
 
 
 

pragma solidity ^0.4.18;
contract VyralSale is Ownable {
    using SafeMath for uint;

    uint public constant MIN_CONTRIBUTION = 1 ether;

    enum Phase {
        Deployed,        
        Initialized,     
        Presale,         
        Freeze,          
        Ready,           
        Crowdsale,       
        Finalized,       
        Decomissioned    
    }

    Phase public phase;

     

    uint public presaleStartTimestamp;

    uint public presaleEndTimestamp;

    uint public presaleRate;

    uint public presaleCap;

    bool public presaleCapReached;

    uint public soldPresale;

     

    uint public saleStartTimestamp;

    uint public saleEndTimestamp;

    uint public saleRate;

    uint public saleCap;

    bool public saleCapReached;

    uint public soldSale;

     
    address public wallet;

    address public vestingWallet;

    Share public shareToken;

    Campaign public campaign;

    DateTime public dateTime;

    bool public vestingRegistered;

     
    uint public constant TOTAL_SUPPLY = 777777777 * (10 ** uint(18));

    uint public constant TEAM = TOTAL_SUPPLY.div(7);

    uint public constant PARTNERS = TOTAL_SUPPLY.div(7);

    uint public constant VYRAL_REWARDS = TOTAL_SUPPLY.div(7).mul(2);

    uint public constant SALE_ALLOCATION = TOTAL_SUPPLY.div(7).mul(3);

     

    modifier inPhase(Phase _phase) {
        require(phase == _phase);
        _;
    }

    modifier canBuy(Phase _phase) {
        require(phase == Phase.Presale || phase == Phase.Crowdsale);

        if (_phase == Phase.Presale) {
            require(block.timestamp >= presaleStartTimestamp);
        }
        if (_phase == Phase.Crowdsale) {
            require(block.timestamp >= saleStartTimestamp);
        }
        _;
    }

    modifier stopInEmergency {
        require(!HALT);
        _;
    }

     

     
    function VyralSale(
        address _share,
        address _datetime
    )
        public
    {
        phase = Phase.Deployed;

        shareToken = Share(_share);
        dateTime = DateTime(_datetime);
    }

    function initPresale(
        address _wallet,
        uint _presaleStartTimestamp,
        uint _presaleEndTimestamp,
        uint _presaleCap,
        uint _presaleRate
    )
        inPhase(Phase.Deployed)
        onlyOwner
        external returns (bool)
    {
        require(_wallet != 0x0);
        require(_presaleStartTimestamp >= block.timestamp);
        require(_presaleEndTimestamp > _presaleStartTimestamp);
        require(_presaleCap < SALE_ALLOCATION.div(_presaleRate));

         
        require(address(campaign) != 0x0);

        wallet = _wallet;
        presaleStartTimestamp = _presaleStartTimestamp;
        presaleEndTimestamp = _presaleEndTimestamp;
        presaleCap = _presaleCap;
        presaleRate = _presaleRate;

        shareToken.transfer(address(campaign), VYRAL_REWARDS);

        phase = Phase.Initialized;
        return true;
    }

     

    function startPresale()
        inPhase(Phase.Initialized)
        onlyOwner
        external returns (bool)
    {
        phase = Phase.Presale;
        return true;
    }

    function endPresale()
        inPhase(Phase.Presale)
        onlyOwner
        external returns (bool)
    {
        phase = Phase.Freeze;
        return true;
    }

    function initSale(
        uint _saleStartTimestamp,
        uint _saleEndTimestamp,
        uint _saleRate
    )
        inPhase(Phase.Freeze)
        onlyOwner
        external returns (bool)
    {
        require(_saleStartTimestamp >= block.timestamp);
        require(_saleEndTimestamp > _saleStartTimestamp);

        saleStartTimestamp = _saleStartTimestamp;
        saleEndTimestamp = _saleEndTimestamp;
        saleRate = _saleRate;
        saleCap = (SALE_ALLOCATION.div(_saleRate)).sub(presaleCap);
        phase = Phase.Ready;
        return true;
    }

    function startSale()
        inPhase(Phase.Ready)
        onlyOwner
        external returns (bool)
    {
        phase = Phase.Crowdsale;
        return true;
    }

    function finalizeSale()
        inPhase(Phase.Crowdsale)
        onlyOwner
        external returns (bool)
    {
        phase = Phase.Finalized;
        return true;
    }

    function decomission()
        onlyOwner
        external returns (bool)
    {
        phase = Phase.Decomissioned;
        return true;
    }

     

    function()
        stopInEmergency
        public payable
    {
        if (phase == Phase.Presale) {
            buyPresale(0x0);
        } else if (phase == Phase.Crowdsale) {
            buySale(0x0);
        } else {
            revert();
        }
    }

    function buyPresale(address _referrer)
        inPhase(Phase.Presale)
        canBuy(Phase.Presale)
        stopInEmergency
        public payable
    {
        require(msg.value >= MIN_CONTRIBUTION);
        require(!presaleCapReached);

        uint contribution = msg.value;
        uint purchased = contribution.mul(presaleRate);
        uint totalSold = soldPresale.add(contribution);

        uint excess;

         
        if (totalSold >= presaleCap) {
            excess = totalSold.sub(presaleCap);
            if (excess > 0) {
                purchased = purchased.sub(excess.mul(presaleRate));
                contribution = contribution.sub(excess);
                msg.sender.transfer(excess);
            }
            presaleCapReached = true;
        }

        soldPresale = totalSold;
        wallet.transfer(contribution);
        shareToken.transfer(msg.sender, purchased);

         
        uint reward = PresaleBonuses.presaleBonusApplicator(purchased, address(dateTime));
        campaign.sendReward(msg.sender, reward);

        if (_referrer != address(0x0)) {
            uint referralReward = campaign.join(_referrer, msg.sender, purchased);
            campaign.sendReward(_referrer, referralReward);
            LogReferral(_referrer, msg.sender, referralReward);
        }

        LogContribution(phase, msg.sender, contribution);
    }

    function buySale(address _referrer)
        inPhase(Phase.Crowdsale)
        canBuy(Phase.Crowdsale)
        stopInEmergency
        public payable
    {
        require(msg.value >= MIN_CONTRIBUTION);
        require(!saleCapReached);

        uint contribution = msg.value;
        uint purchased = contribution.mul(saleRate);
        uint totalSold = soldSale.add(contribution);

        uint excess;

         
        if (totalSold >= saleCap) {
            excess = totalSold.sub(saleCap);
            if (excess > 0) {
                purchased = purchased.sub(excess.mul(saleRate));
                contribution = contribution.sub(excess);
                msg.sender.transfer(excess);
            }
            saleCapReached = true;
        }

        soldSale = totalSold;
        wallet.transfer(contribution);
        shareToken.transfer(msg.sender, purchased);

        if (_referrer != address(0x0)) {
            uint referralReward = campaign.join(_referrer, msg.sender, purchased);
            campaign.sendReward(_referrer, referralReward);
            LogReferral(_referrer, msg.sender, referralReward);
        }

        LogContribution(phase, msg.sender, contribution);
    }

     

    function setPresaleParams(
        uint _presaleStartTimestamp,
        uint _presaleEndTimestamp,
        uint _presaleRate,
        uint _presaleCap
    )
        onlyOwner
        inPhase(Phase.Initialized)
        external returns (bool)
    {
        require(_presaleStartTimestamp >= block.timestamp);
        require(_presaleEndTimestamp > _presaleStartTimestamp);
        require(_presaleCap < SALE_ALLOCATION.div(_presaleRate));

        presaleStartTimestamp = _presaleStartTimestamp;
        presaleEndTimestamp = _presaleEndTimestamp;
        presaleRate = _presaleRate;
        presaleCap = _presaleCap;
    }

    function setCrowdsaleParams(
        uint _saleStartTimestamp,
        uint _saleEndTimestamp,
        uint _saleRate
    )
        onlyOwner
        inPhase(Phase.Ready)
        external returns (bool)
    {
        require(_saleStartTimestamp >= block.timestamp);
        require(_saleEndTimestamp > _saleStartTimestamp);

        saleStartTimestamp = _saleStartTimestamp;
        saleEndTimestamp = _saleEndTimestamp;
        saleRate = _saleRate;
        saleCap = (SALE_ALLOCATION.div(_saleRate)).sub(presaleCap);
    }

    function rewardBeneficiary(
        address _beneficiary,
        uint _tokens
    )
        onlyOwner
        external returns (bool)
    {
        return campaign.sendReward(_beneficiary, _tokens);
    }

    function distributeTimelockedTokens(
        address _beneficiary,
        uint _tokens
    )
        onlyOwner
        external returns (bool)
    {
        return shareToken.transfer(_beneficiary, _tokens);
    }

    function replaceDecomissioned(address _newAddress)
        onlyOwner
        inPhase(Phase.Decomissioned)
        external returns (bool)
    {
        uint allTokens = shareToken.balanceOf(address(this));
        shareToken.transfer(_newAddress, allTokens);
        campaign.transferOwnership(_newAddress);

        return true;
    }

    function setCampaign(
        address _newCampaign
    )
        onlyOwner
        external returns (bool)
    {
        require(address(campaign) != _newCampaign && _newCampaign != 0x0);
        campaign = Campaign(_newCampaign);

        return true;
    }

    function setVesting(
        address _newVesting
    )
        onlyOwner
        external returns (bool)
    {
        require(address(vestingWallet) != _newVesting && _newVesting != 0x0);
        vestingWallet = Vesting(_newVesting);
        shareToken.approve(address(vestingWallet), TEAM.add(PARTNERS));

        return true;
    }

     
    bool public HALT = false;

    function toggleHALT(bool _on)
        onlyOwner
        external returns (bool)
    {
        HALT = _on;
        return HALT;
    }

     
    event LogContribution(Phase phase, address buyer, uint contribution);

    event LogReferral(address referrer, address invitee, uint referralReward);
}