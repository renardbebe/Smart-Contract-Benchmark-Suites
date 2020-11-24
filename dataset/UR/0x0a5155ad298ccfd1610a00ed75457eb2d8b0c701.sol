 

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

 

contract Oasis {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED_PERCENTS = 10000;                
    uint256 constant public DAILY_INTEREST = 300;                        
    uint256 constant public MARKETING_FEE = 1500;                        
    uint256 constant public TEAM_FEE = 400;                              
    uint256 constant public CHARITY_FEE = 100;                           
    uint256 constant public MAX_DEPOSIT_TIME = 50 days;                  
    uint256 constant public REFERRER_ACTIVATION_PERIOD = 0;
    uint256 constant public MAX_USER_DEPOSITS_COUNT = 50;
    uint256 constant public REFBACK_PERCENT = 150;                       
    uint256[]   public referralPercents = [150, 200, 100];    

    struct Deposit {
        uint256 time;
        uint256 amount;
    }

    struct User {
        address referrer;
        uint256 firstTime;
        uint256 lastPayment;
        Deposit[] deposits;
    }

    address public marketing = 0xDB6827de6b9Fc722Dc4EFa7e35f3b78c54932494;
    address public team = 0x31CdA77ab136c8b971511473c3D04BBF7EAe8C0f;
    address public charity = 0x36c92a9Da5256EaA5Ccc355415271b7d2682f32E;
    uint256 public totalDeposits;
    bool public running = true;
    mapping(address => User) public users;

    event InvestorAdded(address indexed investor);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 indexed depositsCount, uint256 amount);
    event UserDividendPayed(address indexed investor, uint256 dividend);
    event DepositDividendPayed(address indexed investor, uint256 indexed index, uint256 deposit, uint256 totalPayed, uint256 dividend);
    event ReferrerPayed(address indexed investor, address indexed referrer, uint256 amount, uint256 refAmount, uint256 indexed level);
    event FeePayed(address indexed investor, uint256 amount);
    event TotalDepositsChanged(uint256 totalDeposits);
    event BalanceChanged(uint256 balance);
    
    function() public payable {
        require(running, "Oasis is not running");
        User storage user = users[msg.sender];

         
        uint256[] memory dividends = dividendsForUser(msg.sender);
        uint256 dividendsSum = _dividendsSum(dividends);
        if (dividendsSum > 0) {
            if (dividendsSum >= address(this).balance) {
                dividendsSum = address(this).balance;
                running = false;
            }

            msg.sender.transfer(dividendsSum);
            user.lastPayment = now;
            emit UserDividendPayed(msg.sender, dividendsSum);
            for (uint i = 0; i < dividends.length; i++) {
                emit DepositDividendPayed(
                    msg.sender,
                    i,
                    user.deposits[i].amount,
                    dividendsForAmountAndTime(user.deposits[i].amount, now.sub(user.deposits[i].time)),
                    dividends[i]
                );
            }

             
            for (i = 0; i < user.deposits.length; i++) {
                if (now >= user.deposits[i].time.add(MAX_DEPOSIT_TIME)) {
                    user.deposits[i] = user.deposits[user.deposits.length - 1];
                    user.deposits.length -= 1;
                    i -= 1;
                }
            }
        }

         
        if (msg.value > 0) {
            if (user.firstTime == 0) {
                user.firstTime = now;
                user.lastPayment = now;
                emit InvestorAdded(msg.sender);
            }

             
            user.deposits.push(Deposit({
                time: now,
                amount: msg.value
            }));
            require(user.deposits.length <= MAX_USER_DEPOSITS_COUNT, "Too many deposits per user");
            emit DepositAdded(msg.sender, user.deposits.length, msg.value);

             
            totalDeposits = totalDeposits.add(msg.value);
            emit TotalDepositsChanged(totalDeposits);

             
            if (user.referrer == address(0) && msg.data.length == 20) {
                address referrer = _bytesToAddress(msg.data);
                if (referrer != address(0) && referrer != msg.sender && users[referrer].firstTime > 0 && now >= users[referrer].firstTime.add(REFERRER_ACTIVATION_PERIOD))
                {
                    user.referrer = referrer;
                    msg.sender.transfer(msg.value.mul(REFBACK_PERCENT).div(ONE_HUNDRED_PERCENTS));
                    emit ReferrerAdded(msg.sender, referrer);
                }
            }

             
            referrer = users[msg.sender].referrer;
            for (i = 0; referrer != address(0) && i < referralPercents.length; i++) {
                uint256 refAmount = msg.value.mul(referralPercents[i]).div(ONE_HUNDRED_PERCENTS);
                referrer.send(refAmount);  
                emit ReferrerPayed(msg.sender, referrer, msg.value, refAmount, i);
                referrer = users[referrer].referrer;
            }

             
            uint256 marketingFee = msg.value.mul(MARKETING_FEE).div(ONE_HUNDRED_PERCENTS);
            uint256 teamFee = msg.value.mul(TEAM_FEE).div(ONE_HUNDRED_PERCENTS);
            uint256 charityFee = msg.value.mul(CHARITY_FEE).div(ONE_HUNDRED_PERCENTS);
            marketing.send(marketingFee);  
            team.send(teamFee);  
            charity.send(charityFee);  
            emit FeePayed(msg.sender, marketingFee.add(teamFee));
        }

         
        if (user.deposits.length == 0 && msg.value == 0) {
            user.firstTime = now;
        }
        emit BalanceChanged(address(this).balance);
    }

    function depositsCountForUser(address wallet) public view returns(uint256) {
        return users[wallet].deposits.length;
    }

    function depositForUser(address wallet, uint256 index) public view returns(uint256 time, uint256 amount) {
        time = users[wallet].deposits[index].time;
        amount = users[wallet].deposits[index].amount;
    }

    function dividendsSumForUser(address wallet) public view returns(uint256 dividendsSum) {
        return _dividendsSum(dividendsForUser(wallet));
    }

    function dividendsForUser(address wallet) public view returns(uint256[] dividends) {
        User storage user = users[wallet];
        dividends = new uint256[](user.deposits.length);

        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 howOld = now.sub(user.deposits[i].time);
            uint256 duration = now.sub(user.lastPayment);
            if (howOld > MAX_DEPOSIT_TIME) {
                uint256 overtime = howOld.sub(MAX_DEPOSIT_TIME);
                duration = duration.sub(overtime);
            }

            dividends[i] = dividendsForAmountAndTime(user.deposits[i].amount, duration);
        }
    }

    function dividendsForAmountAndTime(uint256 amount, uint256 duration) public pure returns(uint256) {
        return amount
            .mul(DAILY_INTEREST).div(ONE_HUNDRED_PERCENTS)
            .mul(duration).div(1 days);
    }

    function _bytesToAddress(bytes data) private pure returns(address addr) {
         
        assembly {
            addr := mload(add(data, 20)) 
        }
    }

    function _dividendsSum(uint256[] dividends) private pure returns(uint256 dividendsSum) {
        for (uint i = 0; i < dividends.length; i++) {
            dividendsSum = dividendsSum.add(dividends[i]);
        }
    }
}