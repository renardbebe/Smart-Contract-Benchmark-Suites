 

pragma solidity ^0.4.20;

contract EtherHellHydrant {
    using SafeMath for uint256;

    event Bid(
        uint _timestamp,
        address _address,
        uint _amount,
        uint _cappedAmount,
        uint _newRound,
        uint _newPot
    );

    event Winner(
        uint _timestamp,
        address _address,
        uint _totalPayout,
        uint _round,
        uint _leaderTimestamp
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

     
    uint public constant PAYOUT_FRAC_TOP = 10;
    uint public constant PAYOUT_FRAC_BOT = 100;

     
    uint public constant PAYOUT_TIME = 5 minutes;

     
    uint public constant MAX_PAYOUT_FRAC_TOP = 1;
    uint public constant MAX_PAYOUT_FRAC_BOT = 10;

     
    uint public constant MIN_BID_FRAC_TOP = 1;
    uint public constant MIN_BID_FRAC_BOT = 1000;

     
    uint public constant MAX_BID_FRAC_TOP = 1;
    uint public constant MAX_BID_FRAC_BOT = 100;

     
    uint public constant DIVIDEND_FUND_FRAC_TOP = 1;
    uint public constant DIVIDEND_FUND_FRAC_BOT = 2;

     
    address owner;

     
    mapping(address => uint) public earnings;

     
    mapping(address => uint) public dividendShares;

     
    uint public totalDividendShares;

     
    uint public dividendFund;

     
    uint public round;

     
    uint public pot;

     
    address public leader;

     
    uint public leaderTimestamp;

     
    uint public leaderBid;

    function EtherHellHydrant() public payable {
        require(msg.value > 0);
        owner = msg.sender;
        totalDividendShares = 0;
        dividendFund = 0;
        round = 0;
        pot = msg.value;
        leader = owner;
        leaderTimestamp = now;
        leaderBid = 0;
        Bid(now, msg.sender, 0, 0, round, pot);
    }

    function bid() public payable {
        uint _maxPayout = pot.mul(MAX_PAYOUT_FRAC_TOP).div(MAX_PAYOUT_FRAC_BOT);
        uint _numPayoutIntervals = now.sub(leaderTimestamp).div(PAYOUT_TIME);
        uint _totalPayout = _numPayoutIntervals.mul(leaderBid).mul(PAYOUT_FRAC_TOP).div(PAYOUT_FRAC_BOT);
        if (_totalPayout > _maxPayout) {
            _totalPayout = _maxPayout;
        }

        uint _bidAmountToDividendFund = msg.value.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
        uint _bidAmountToPot = msg.value.sub(_bidAmountToDividendFund);

        uint _minBidForNewPot = pot.sub(_totalPayout).mul(MIN_BID_FRAC_TOP).div(MIN_BID_FRAC_BOT);

        if (msg.value < _minBidForNewPot) {
            dividendFund = dividendFund.add(_bidAmountToDividendFund);
            pot = pot.add(_bidAmountToPot);
        } else {
            earnings[leader] = earnings[leader].add(_totalPayout);
            pot = pot.sub(_totalPayout);

            Winner(now, leader, _totalPayout, round, leaderTimestamp);

            uint _maxBid = pot.mul(MAX_BID_FRAC_TOP).div(MAX_BID_FRAC_BOT);

            uint _dividendSharePrice;
            if (totalDividendShares == 0) {
                _dividendSharePrice = _maxBid.mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
            } else {
                _dividendSharePrice = dividendFund.div(totalDividendShares);
            }

            dividendFund = dividendFund.add(_bidAmountToDividendFund);
            pot = pot.add(_bidAmountToPot);

            if (msg.value > _maxBid) {
                uint _investment = msg.value.sub(_maxBid).mul(DIVIDEND_FUND_FRAC_TOP).div(DIVIDEND_FUND_FRAC_BOT);
                uint _dividendShares = _investment.div(_dividendSharePrice);
                dividendShares[msg.sender] = dividendShares[msg.sender].add(_dividendShares);
                totalDividendShares = totalDividendShares.add(_dividendShares);
            }

            round++;
            leader = msg.sender;
            leaderTimestamp = now;
            leaderBid = msg.value;
            if (leaderBid > _maxBid) {
                leaderBid = _maxBid;
            }

            Bid(now, msg.sender, msg.value, leaderBid, round, pot);
        }
    }

    function withdrawEarnings() public {
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
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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