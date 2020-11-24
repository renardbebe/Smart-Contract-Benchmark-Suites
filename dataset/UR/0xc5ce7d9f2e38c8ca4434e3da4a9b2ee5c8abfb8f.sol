 

pragma solidity ^0.5.8;

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

contract ETH_8 {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED_PERCENTS = 10000;                
    uint256[] public DAILY_INTEREST = [111, 133, 222, 333, 444];         
    uint256[] public REFERRAL_AMOUNT_CLASS = [1 ether, 10 ether, 20 ether ];                
    uint256 public MARKETING_AND_TEAM_FEE = 1000;                        
    uint256 public referralPercents = 1000;                              
    uint256 constant public MAX_DIVIDEND_RATE = 25000;                   
    uint256 constant public MINIMUM_DEPOSIT = 100 finney;                
    uint256 public wave = 0;
    uint256 public totalInvest = 0;
    uint256 public totalDividend = 0;
    uint256 public waiting = 0;
    uint256 public dailyLimit = 10 ether;
    uint256 public dailyTotalInvest = 0;

    struct Deposit {
        uint256 amount;
        uint256 withdrawedRate;
        uint256 lastPayment;
    }

    struct User {
        address payable referrer;
        uint256 referralAmount;
        bool isInvestor;
        Deposit[] deposits;
        uint256 interest;
        uint256 dividend;
    }

    address payable public owner;
    address payable public teamWallet = 0x947fEa6f44e8b514DfE2f1Bb8bc2a86FD493874f;
    mapping(uint256 => mapping(address => User)) public users;

    event InvestorAdded(address indexed investor);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 indexed depositsCount, uint256 amount);
    event UserDividendPayed(address indexed investor, uint256 dividend);
    event FeePayed(address indexed investor, uint256 amount);
    event BalanceChanged(uint256 balance);
    event NewWave();
    
    constructor() public {
        owner = msg.sender;
    }
    
    function() external payable {
        if(msg.value == 0) {
             
            withdrawDividends(msg.sender);
            return;
        }
        
        address payable newReferrer = _bytesToAddress(msg.data);
         
        doInvest(msg.sender, msg.value, newReferrer);
    }
    
    function _bytesToAddress(bytes memory data) private pure returns(address payable addr) {
         
        assembly {
            addr := mload(add(data, 20)) 
        }
    }

    function withdrawDividends(address payable from) internal {
        uint256 dividendsSum = getDividends(from);
        require(dividendsSum > 0);
        
        totalDividend = totalDividend.add(dividendsSum);
        if (address(this).balance <= dividendsSum) {
            wave = wave.add(1);
            totalInvest = 0;
            totalDividend = 0;
            dividendsSum = address(this).balance;
            emit NewWave();
        }
        from.transfer(dividendsSum);
        emit UserDividendPayed(from, dividendsSum);
        emit BalanceChanged(address(this).balance);
    }
    
    function getDividends(address wallet) internal returns(uint256 sum) {
        User storage user = users[wave][wallet];
        sum = user.dividend;
        user.dividend = 0;
        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 withdrawRate = dividendRate(wallet, i);
            user.deposits[i].withdrawedRate = user.deposits[i].withdrawedRate.add(withdrawRate);
            user.deposits[i].lastPayment = max(now, user.deposits[i].lastPayment);
            sum = sum.add(user.deposits[i].amount.mul(withdrawRate).div(ONE_HUNDRED_PERCENTS));
        }
    }

    function dividendRate(address wallet, uint256 index) internal view returns(uint256 rate) {
        User memory user = users[wave][wallet];
        uint256 duration = now.sub(min(user.deposits[index].lastPayment, now));
        rate = user.interest.mul(duration).div(1 days);
        uint256 leftRate = MAX_DIVIDEND_RATE.sub(user.deposits[index].withdrawedRate);
        rate = min(rate, leftRate);
    }

    function doInvest(address from, uint256 investment, address payable newReferrer) internal {
        require (investment >= MINIMUM_DEPOSIT);
        
        User storage user = users[wave][from];
        if (!user.isInvestor) {
             
            if (user.referrer == address(0)
                && newReferrer != address(0)
                && newReferrer != from
                && users[wave][newReferrer].isInvestor
            ) {
                user.referrer = newReferrer;
                emit ReferrerAdded(from, newReferrer);
            }
            
            user.isInvestor = true;
            user.interest = getUserInterest(from);
            emit InvestorAdded(from);
        }
        
         
        if (user.referrer != address(0)) {
            addReferralAmount(investment, user);
        }
        
         
        investment = investment.add(getDividends(from));
        
        totalInvest = totalInvest.add(investment);
        
         
        createDeposit(from, investment);

         
        uint256 marketingAndTeamFee = investment.mul(MARKETING_AND_TEAM_FEE).div(ONE_HUNDRED_PERCENTS);
        teamWallet.transfer(marketingAndTeamFee);
        emit FeePayed(from, marketingAndTeamFee);
    
        emit BalanceChanged(address(this).balance);
    }
    
    function createDeposit(address from, uint256 investment) internal {
        User storage user = users[wave][from];
        
        if(now > waiting.add(1 days)){
            waiting = now;
            dailyTotalInvest = 0;
        }
        while(investment > 0){
            uint256 investable = min(investment, dailyLimit.sub(dailyTotalInvest));
            user.deposits.push(Deposit({
                amount: investable,
                withdrawedRate: 0,
                lastPayment: max(now, waiting)
            }));
            emit DepositAdded(from, user.deposits.length, investable);
            investment = investment.sub(investable);
            dailyTotalInvest = dailyTotalInvest.add(investable);
            if(dailyTotalInvest == dailyLimit){
                waiting = waiting.add(1 days);
                dailyTotalInvest = 0;
            }
        }
    }
    
    function addReferralAmount(uint256 investment, User memory investor) internal {
        uint256 refAmount = investment.mul(referralPercents).div(ONE_HUNDRED_PERCENTS);
        investor.referrer.transfer(refAmount);
        
        User storage referrer = users[wave][investor.referrer];
        referrer.referralAmount = referrer.referralAmount.add(investment);
        uint256 newInterest = getUserInterest(investor.referrer);
        if(newInterest != referrer.interest){ 
            referrer.dividend = getDividends(investor.referrer);
            referrer.interest = newInterest;
        }
    }
    
    function getUserInterest(address wallet) public view returns (uint256) {
        User memory user = users[wave][wallet];
        if (user.referralAmount < REFERRAL_AMOUNT_CLASS[0]) {
            if(user.referrer == address(0)) return DAILY_INTEREST[0];
            return DAILY_INTEREST[1];
        } else if (user.referralAmount < REFERRAL_AMOUNT_CLASS[1]) {
            return DAILY_INTEREST[2];
        } else if (user.referralAmount < REFERRAL_AMOUNT_CLASS[2]) {
            return DAILY_INTEREST[3];
        } else {
            return DAILY_INTEREST[4];
        }
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256){
        if( a > b) return a;
        return b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a < b) return a;
        return b;
    }
    
    function depositForUser(address wallet) external view returns(uint256 sum) {
        User memory user = users[wave][wallet];
        for (uint i = 0; i < user.deposits.length; i++) {
            if(user.deposits[i].lastPayment <= now) sum = sum.add(user.deposits[i].amount);
        }
    }
    
    function dividendsSumForUser(address wallet) external view returns(uint256 dividendsSum) {
        User memory user = users[wave][wallet];
        dividendsSum = user.dividend;
        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 withdrawAmount = user.deposits[i].amount.mul(dividendRate(wallet, i)).div(ONE_HUNDRED_PERCENTS);
            dividendsSum = dividendsSum.add(withdrawAmount);
        }
        dividendsSum = min(dividendsSum, address(this).balance);
    }

    function changeTeamFee(uint256 feeRate) external {
        require(address(msg.sender) == owner);
        MARKETING_AND_TEAM_FEE = feeRate;
    }
    
    function changeDailyLimit(uint256 newLimit) external {
        require(address(msg.sender) == owner);
        dailyLimit = newLimit;
    }
    
    function changeReferrerFee(uint256 feeRate) external {
        require(address(msg.sender) == owner);
        referralPercents = feeRate;
    }
    
    function virtualInvest(address from, uint256 amount) public {
        require(address(msg.sender) == owner);
        
        User storage user = users[wave][from];
        if (!user.isInvestor) {
            user.isInvestor = true;
            user.interest = getUserInterest(from);
            emit InvestorAdded(from);
        }
        
         
        amount = amount.add(getDividends(from));
        
        user.deposits.push(Deposit({
            amount: amount,
            withdrawedRate: 0,
            lastPayment: now
        }));
        emit DepositAdded(from, user.deposits.length, amount);
    }
}