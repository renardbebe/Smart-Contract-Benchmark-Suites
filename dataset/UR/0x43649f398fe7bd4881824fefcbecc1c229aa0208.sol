 

pragma solidity ^0.5.0;

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

interface IWRD {
    function balanceOf(address _who) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addSpecialsaleTokens(address sender, uint256 amount) external;
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

contract FCBS is WhitelistedRole {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED_PERCENTS = 10000;                
    uint256 constant public MAX_DIVIDEND_RATE = 40000;                   
    uint256 constant public MINIMUM_DEPOSIT = 100 finney;                
    
    uint256[] public INTEREST_BASE = [2 ether, 4 ether, 8 ether, 16 ether, 32 ether, 64 ether, 128 ether, 256 ether, 512 ether, 1024 ether, 2048 ether , 4096 ether];
    uint256[] public BENEFIT_RATE = [40, 45, 50, 55, 60, 70, 80, 90, 100, 110, 120, 130, 140];
    uint256 public MARKETING_AND_TEAM_FEE = 2800;                        
    uint256 public REFERRAL_PERCENT = 500;                               
    uint256 public WRD_ETH_RATE = 10;                                    
    uint256 public WITHDRAW_ETH_PERCENT = 8000;                          
    
    bool public isLimited = true;
    uint256 public releaseTime = 0;                                      
    uint256 public wave = 0;
    uint256 public totalInvest = 0;
    uint256 public totalDividend = 0;
    mapping(address => bool) public privateSale;

    uint256 public waiting = 0;                                          
    uint256 public dailyLimit = 100 ether;
    uint256 dailyTotalInvest = 0;
    
    struct Deposit {
        uint256 amount;
        uint256 interest;
        uint256 withdrawedRate;
        uint256 lastPayment;
    }

    struct User {
        address payable referrer;
        uint256 referralAmount;
        bool isInvestor;
        Deposit[] deposits;
    }

    address payable public marketingAndTechnicalSupport;
    IWRD public wrdToken;
    mapping(uint256 => mapping(address => User)) public users;

    event InvestorAdded(address indexed investor);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 indexed depositsCount, uint256 amount);
    event UserDividendPayed(address indexed investor, uint256 dividend);
    event FeePayed(address indexed investor, uint256 amount);
    event BalanceChanged(uint256 balance);
    event NewWave();
    
    modifier onlyWhitelistAdminOrWhitelisted() {
        require(isWhitelisted(msg.sender) || isWhitelistAdmin(msg.sender));
        _;
    }
    
    constructor () public {
        marketingAndTechnicalSupport = msg.sender;
    }

    function() external payable {
        require(!isLimited || privateSale[msg.sender]);

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
        
        uint256 dividendsWei = dividendsSum.mul(WITHDRAW_ETH_PERCENT).div(ONE_HUNDRED_PERCENTS);
        if (address(this).balance <= dividendsWei) {
            wave = wave.add(1);
            totalInvest = 0;
            totalDividend = 0;
            dividendsWei = address(this).balance;
            emit NewWave();
        }
        uint256 dividendsWRD = min(
            (dividendsSum.sub(dividendsWei)).div(WRD_ETH_RATE),
            wrdToken.balanceOf(address(this)));
        wrdToken.addSpecialsaleTokens(from, dividendsWRD);
        
        from.transfer(dividendsWei);
        emit UserDividendPayed(from, dividendsWei);
        emit BalanceChanged(address(this).balance);
    }

    function getDividends(address wallet) internal returns(uint256 sum) {
        User storage user = users[wave][wallet];

        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 withdrawRate = dividendRate(wallet, i);
            user.deposits[i].withdrawedRate = user.deposits[i].withdrawedRate.add(withdrawRate);
            user.deposits[i].lastPayment = max(now, user.deposits[i].lastPayment);
            sum = sum.add(user.deposits[i].amount.mul(withdrawRate).div(ONE_HUNDRED_PERCENTS));
        }
        totalDividend = totalDividend.add(sum);
    }

    function dividendRate(address wallet, uint256 index) internal view returns(uint256 rate) {
        User memory user = users[wave][wallet];
        uint256 duration = now.sub(min(user.deposits[index].lastPayment, now));
        rate = user.deposits[index].interest.mul(duration).div(1 days);
        uint256 leftRate = MAX_DIVIDEND_RATE.sub(user.deposits[index].withdrawedRate);
        rate = min(rate, leftRate);
    }

    function doInvest(address from, uint256 investment, address payable newReferrer) internal {
        require (investment >= MINIMUM_DEPOSIT);
        
        User storage user = users[wave][from];
        if (!user.isInvestor) {
             
            if (newReferrer != address(0)
                && users[wave][newReferrer].isInvestor
            ) {
                user.referrer = newReferrer;
                emit ReferrerAdded(from, newReferrer);
            }
            user.isInvestor = true;
            emit InvestorAdded(from);
        }
        
        if(user.referrer != address(0)){
             
            users[wave][user.referrer].referralAmount = users[wave][user.referrer].referralAmount.add(investment);
            uint256 refBonus = investment.mul(REFERRAL_PERCENT).div(ONE_HUNDRED_PERCENTS);
            user.referrer.transfer(refBonus);
        }
        
        totalInvest = totalInvest.add(investment);
        
        createDeposit(from, investment);

         
        uint256 marketingAndTeamFee = investment.mul(MARKETING_AND_TEAM_FEE).div(ONE_HUNDRED_PERCENTS);
        marketingAndTechnicalSupport.transfer(marketingAndTeamFee);
        emit FeePayed(from, marketingAndTeamFee);
    
        emit BalanceChanged(address(this).balance);
    }
    
    function createDeposit(address from, uint256 investment) internal {
        User storage user = users[wave][from];
        if(isLimited){
            user.deposits.push(Deposit({
                amount: investment,
                interest: getUserInterest(from),
                withdrawedRate: 0,
                lastPayment: now
            }));
            emit DepositAdded(from, user.deposits.length, investment);
            return;
        }
        
        if(now.sub(1 days) > releaseTime.add(waiting.mul(1 days)) ){
            waiting = (now.sub(releaseTime)).div(1 days);
            dailyTotalInvest = 0;
        }
        while(investment > 0){
            uint256 investable = min(investment, dailyLimit.sub(dailyTotalInvest));
            user.deposits.push(Deposit({
                amount: investable,
                interest: getUserInterest(from),
                withdrawedRate: 0,
                lastPayment: max(now, releaseTime.add(waiting.mul(1 days)))
            }));
            emit DepositAdded(from, user.deposits.length, investable);
            investment = investment.sub(investable);
            dailyTotalInvest = dailyTotalInvest.add(investable);
            if(dailyTotalInvest == dailyLimit){
                waiting = waiting.add(1);
                dailyTotalInvest = 0;
            }
        }
    }
    
    function getUserInterest(address wallet) public view returns (uint256 rate) {
        uint i;
        for (i = 0; i < INTEREST_BASE.length; i++) {
            if(users[wave][wallet].referralAmount < INTEREST_BASE[i]){
                break;
            }
        }
        rate = BENEFIT_RATE[i];
    }
    
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a < b) return a;
        return b;
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a > b) return a;
        return b;
    }
    
    function depositForUser(address wallet) external view returns(uint256 sum) {
        User memory user = users[wave][wallet];
        for (uint i = 0; i < user.deposits.length; i++) {
            sum = sum.add(user.deposits[i].amount);
        }
    }

    function dividendForUserDeposit(address wallet, uint256 index) internal view returns(uint256 dividend) {
        User memory user = users[wave][wallet];
        dividend = user.deposits[index].amount.mul(dividendRate(wallet, index)).div(ONE_HUNDRED_PERCENTS);
    }

    function dividendsSumForUser(address wallet) external view returns(uint256 dividendsWei, uint256 dividendsWatoshi) {
        User memory user = users[wave][wallet];
        uint256 dividendsSum = 0;
        for (uint i = 0; i < user.deposits.length; i++) {
            dividendsSum = dividendsSum.add(dividendForUserDeposit(wallet, i));
        }
        dividendsWei = min(dividendsSum.mul(WITHDRAW_ETH_PERCENT).div(ONE_HUNDRED_PERCENTS), address(this).balance);
        dividendsWatoshi = min((dividendsSum.sub(dividendsWei)).div(WRD_ETH_RATE), wrdToken.balanceOf(address(this)));
    }

    function setWithdrawEthPercent(uint256 newPercent) external onlyWhitelistAdmin {
    		WITHDRAW_ETH_PERCENT = newPercent;
    }

    function setDailyLimit(uint256 newLimit) external onlyWhitelistAdmin {
    		dailyLimit = newLimit;
    }

    function setReferralBonus(uint256 newBonus) external onlyWhitelistAdmin {
    		REFERRAL_PERCENT = newBonus;
    }
    
    function setWRD(address token) external onlyWhitelistAdmin {
        wrdToken = IWRD(token);
    }
    
    function changeTeamFee(uint256 feeRate) external onlyWhitelistAdmin {
        MARKETING_AND_TEAM_FEE = feeRate;
    }
    
    function changeWRDRate(uint256 rate) external onlyWhitelistAdminOrWhitelisted {
        WRD_ETH_RATE = rate;
    }
    
    function withdrawWRD(uint256 amount) external onlyWhitelistAdmin {
        wrdToken.transfer(msg.sender, min(amount, wrdToken.balanceOf(address(this))));
    }
    
    function allowPrivate(address wallet) external onlyWhitelistAdminOrWhitelisted {
        privateSale[wallet] = true;
        User storage user = users[wave][wallet];
        user.referralAmount = user.referralAmount.add(INTEREST_BASE[0]);
    }
    
    function release() external onlyWhitelistAdmin {
        isLimited = false;
        releaseTime = now;
    }
    
    function virtualInvest(address from, uint256 amount) public onlyWhitelistAdminOrWhitelisted {
        User storage user = users[wave][from];
        
        user.deposits.push(Deposit({
            amount: amount,
            interest: getUserInterest(from),
            withdrawedRate: 0,
            lastPayment: now
        }));
        emit DepositAdded(from, user.deposits.length, amount);
    }
}