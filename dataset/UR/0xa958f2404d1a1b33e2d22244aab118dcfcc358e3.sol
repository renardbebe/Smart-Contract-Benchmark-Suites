 

pragma solidity ^0.4.24;

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Proxy {
    using SafeMath for uint256;
    uint256 public contribution = 0;
    Lottery lottery;
    
    constructor() public {
        lottery = Lottery(msg.sender);
    }
    function() public payable {
        contribution = contribution.add(msg.value);
        address(lottery).transfer(msg.value);
    }
    function resetContribution() external {
        require(msg.sender == lottery.owner());
        contribution = 0;
    }
}

contract Lottery {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED_PERCENTS = 10000;                
    uint256[] public DAILY_INTEREST = [111, 133, 222, 333, 444];         
    uint256 public MARKETING_AND_TEAM_FEE = 1000;                        
    uint256 public referralPercents = 1000;                              
    uint256 constant public MAX_DIVIDEND_RATE = 25000;                   
    uint256 constant public MINIMUM_DEPOSIT = 100 finney;                
    uint256 public wave = 0;
    uint256 public totalInvest = 0;
    uint256 public totalDividend = 0;
    mapping(address => bool) public isProxy;

    struct Deposit {
        uint256 amount;
        uint256 interest;
        uint256 withdrawedRate;
    }

    struct User {
        address referrer;
        uint256 referralAmount;
        uint256 firstTime;
        uint256 lastPayment;
        Deposit[] deposits;
        uint256 referBonus;
    }

    address public marketingAndTechnicalSupport = 0xFaea7fa229C29526698657e7Ab7063E20581A50c;  
    address public owner = 0x4e3e605b9f7b333e413E1CD9E577f2eba447f876;
    mapping(uint256 => mapping(address => User)) public users;

    event InvestorAdded(address indexed investor);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 indexed depositsCount, uint256 amount);
    event UserDividendPayed(address indexed investor, uint256 dividend);
    event DepositDividendPayed(address indexed investor, uint256 indexed index, uint256 deposit, uint256 totalPayed, uint256 dividend);
    event FeePayed(address indexed investor, uint256 amount);
    event BalanceChanged(uint256 balance);
    event NewWave();
    
    function() public payable {
        require(isProxy[msg.sender]);
        
        if(msg.value == 0) {
             
            withdrawDividends();
            return;
        }

         
        doInvest();
    }
        
    function withdrawDividends() internal {
        uint256 dividendsSum = getDividends(tx.origin);
        require(dividendsSum > 0);
        
        if (address(this).balance <= dividendsSum) {
            wave = wave.add(1);
            totalInvest = 0;
            dividendsSum = address(this).balance;
            emit NewWave();
        }
        tx.origin.transfer(dividendsSum);
        emit UserDividendPayed(tx.origin, dividendsSum);
        emit BalanceChanged(address(this).balance);
    }
    
    function getDividends(address wallet) internal returns(uint256 sum) {
        User storage user = users[wave][wallet];
        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 withdrawRate = dividendRate(tx.origin, i);
            user.deposits[i].withdrawedRate = user.deposits[i].withdrawedRate.add(withdrawRate);
            sum = sum.add(user.deposits[i].amount.mul(withdrawRate).div(ONE_HUNDRED_PERCENTS));
            emit DepositDividendPayed(
                tx.origin,
                i,
                user.deposits[i].amount,
                user.deposits[i].amount.mul(user.deposits[i].withdrawedRate.div(ONE_HUNDRED_PERCENTS)),
                user.deposits[i].amount.mul(withdrawRate.div(ONE_HUNDRED_PERCENTS))
            );
        }
        user.lastPayment = now;
        sum = sum.add(user.referBonus);
        user.referBonus = 0;
        totalDividend = totalDividend.add(sum);
    }

    function dividendRate(address wallet, uint256 index) internal view returns(uint256 rate) {
        User memory user = users[wave][wallet];
        uint256 duration = now.sub(user.lastPayment);
        rate = user.deposits[index].interest.mul(duration).div(1 days);
        uint256 leftRate = MAX_DIVIDEND_RATE.sub(user.deposits[index].withdrawedRate);
        rate = min(rate, leftRate);
    }

    function doInvest() internal {
        uint256 investment = msg.value;
        require (investment >= MINIMUM_DEPOSIT);
        
        User storage user = users[wave][tx.origin];
        if (user.firstTime == 0) {
            user.firstTime = now;
            user.lastPayment = now;
            emit InvestorAdded(tx.origin);
        }

         
        if (user.referrer == address(0) && msg.data.length == 20 && user.firstTime == now) {
            address newReferrer = _bytesToAddress(msg.data);
            if (newReferrer != address(0) && newReferrer != tx.origin && users[wave][newReferrer].firstTime > 0) {
                user.referrer = newReferrer;
                emit ReferrerAdded(tx.origin, newReferrer);
            }
        }
        
         
        if (user.referrer != address(0)) {
            uint256 refAmount = investment.mul(referralPercents).div(ONE_HUNDRED_PERCENTS);
            users[wave][user.referrer].referralAmount = users[wave][user.referrer].referralAmount.add(investment);
            user.referrer.transfer(refAmount);
        }
        
         
        investment = investment.add(getDividends(tx.origin));
        
        totalInvest = totalInvest.add(investment);
        
         
        user.deposits.push(Deposit({
            amount: investment,
            interest: getUserInterest(tx.origin),
            withdrawedRate: 0
        }));
        emit DepositAdded(tx.origin, user.deposits.length, investment);

         
        uint256 marketingAndTeamFee = msg.value.mul(MARKETING_AND_TEAM_FEE).div(ONE_HUNDRED_PERCENTS);
        marketingAndTechnicalSupport.transfer(marketingAndTeamFee);
        emit FeePayed(tx.origin, marketingAndTeamFee);
    
        emit BalanceChanged(address(this).balance);
    }
    
    function getUserInterest(address wallet) public view returns (uint256) {
        User memory user = users[wave][wallet];
        if (user.referralAmount < 1 ether) {
            if(user.referrer == address(0)) return DAILY_INTEREST[0];
            return DAILY_INTEREST[1];
        } else if (user.referralAmount < 10 ether) {
            return DAILY_INTEREST[2];
        } else if (user.referralAmount < 20 ether) {
            return DAILY_INTEREST[3];
        } else {
            return DAILY_INTEREST[4];
        }
    }

    function _bytesToAddress(bytes data) private pure returns(address addr) {
         
        assembly {
            addr := mload(add(data, 20)) 
        }
    }
    
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a < b) return a;
        return b;
    }
    
    function depositForUser(address wallet) external view returns(uint256 sum) {
        User memory user = users[wave][wallet];
        for (uint i = 0; i < user.deposits.length; i++) {
            sum = sum.add(user.deposits[i].amount);
        }
    }
    
    function dividendsSumForUser(address wallet) external view returns(uint256 dividendsSum) {
        User memory user = users[wave][wallet];
        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 withdrawAmount = user.deposits[i].amount.mul(dividendRate(wallet, i)).div(ONE_HUNDRED_PERCENTS);
            dividendsSum = dividendsSum.add(withdrawAmount);
        }
        dividendsSum = dividendsSum.add(user.referBonus);
        dividendsSum = min(dividendsSum, address(this).balance);
    }
    
    function changeInterest(uint256[] interestList) external {
        require(address(msg.sender) == owner);
        DAILY_INTEREST = interestList;
    }
    
    function changeTeamFee(uint256 feeRate) external {
        require(address(msg.sender) == owner);
        MARKETING_AND_TEAM_FEE = feeRate;
    }
    
    function virtualInvest(address from, uint256 amount) public {
        require(address(msg.sender) == owner);
        
        User storage user = users[wave][from];
        if (user.firstTime == 0) {
            user.firstTime = now;
            user.lastPayment = now;
            emit InvestorAdded(from);
        }
        
         
        amount = amount.add(getDividends(from));
        
        user.deposits.push(Deposit({
            amount: amount,
            interest: getUserInterest(from),
            withdrawedRate: 0
        }));
        emit DepositAdded(from, user.deposits.length, amount);
    }
    
    function createProxy() external {
        require(msg.sender == owner);
        Proxy newProxy = new Proxy();
        isProxy[address(newProxy)] = true;
    }
}