 

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

 

contract Efirica {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED_PERCENTS = 10000;
    uint256 constant public LOWEST_DIVIDEND_PERCENTS = 50;             
    uint256 constant public HIGHEST_DIVIDEND_PERCENTS = 500;           
    uint256 constant public REFERRAL_ACTIVATION_TIME = 1 days;
    uint256[]   public referralPercents = [500, 300, 200];  

    bool public running = true;
    address public admin = msg.sender;
    uint256 public totalDeposits = 0;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public withdrawals;
    mapping(address => uint256) public joinedAt;
    mapping(address => uint256) public updatedAt;
    mapping(address => address) public referrers;
    mapping(address => uint256) public refCount;
    mapping(address => uint256) public refEarned;

    event InvestorAdded(address indexed investor);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 deposit, uint256 amount);
    event DividendPayed(address indexed investor, uint256 dividend);
    event ReferrerPayed(address indexed investor, uint256 indexed level, address referrer, uint256 amount);
    event AdminFeePayed(address indexed investor, uint256 amount);
    event TotalDepositsChanged(uint256 totalDeposits);
    event BalanceChanged(uint256 balance);
    
    function() public payable {
        require(running, "Project is not running");

         
        uint256 dividends = dividendsForUser(msg.sender);
        if (dividends > 0) {
            if (dividends >= address(this).balance) {
                dividends = address(this).balance;
                running = false;
            }
            msg.sender.transfer(dividends);
            withdrawals[msg.sender] = withdrawals[msg.sender].add(dividends);
            updatedAt[msg.sender] = now;
            emit DividendPayed(msg.sender, dividends);
        }

         
        if (msg.value > 0) {
            if (deposits[msg.sender] == 0) {
                joinedAt[msg.sender] = now;
                emit InvestorAdded(msg.sender);
            }
            updatedAt[msg.sender] = now;
            deposits[msg.sender] = deposits[msg.sender].add(msg.value);
            emit DepositAdded(msg.sender, deposits[msg.sender], msg.value);

            totalDeposits = totalDeposits.add(msg.value);
            emit TotalDepositsChanged(totalDeposits);

             
            if (referrers[msg.sender] == address(0) && msg.data.length == 20) {
                address referrer = _bytesToAddress(msg.data);
                if (referrer != address(0) && deposits[referrer] > 0 && now >= joinedAt[referrer].add(REFERRAL_ACTIVATION_TIME)) {
                    referrers[msg.sender] = referrer;
                    refCount[referrer] += 1;
                    emit ReferrerAdded(msg.sender, referrer);
                }
            }

             
            referrer = referrers[msg.sender];
            for (uint i = 0; referrer != address(0) && i < referralPercents.length; i++) {
                uint256 refAmount = msg.value.mul(referralPercents[i]).div(ONE_HUNDRED_PERCENTS);
                referrer.send(refAmount);  
                refEarned[referrer] = refEarned[referrer].add(refAmount);
                emit ReferrerPayed(msg.sender, i, referrer, refAmount);
                referrer = referrers[referrer];
            }

             
            uint256 adminFee = msg.value.div(100);
            admin.send(adminFee);  
            emit AdminFeePayed(msg.sender, adminFee);
        }

        emit BalanceChanged(address(this).balance);
    }

    function dividendsForUser(address user) public view returns(uint256) {
        return dividendsForPercents(user, percentsForUser(user));
    }

    function dividendsForPercents(address user, uint256 percents) public view returns(uint256) {
        return deposits[user]
            .mul(percents).div(ONE_HUNDRED_PERCENTS)
            .mul(now.sub(updatedAt[user])).div(1 days);  
    }

    function percentsForUser(address user) public view returns(uint256) {
        uint256 percents = generalPercents();

         
        if (referrers[user] != address(0)) {
            percents = percents.mul(110).div(100);
        }

        return percents;
    }

    function generalPercents() public view returns(uint256) {
        uint256 health = healthPercents();
        if (health >= ONE_HUNDRED_PERCENTS.mul(80).div(100)) {  
            return HIGHEST_DIVIDEND_PERCENTS;
        }

         
        uint256 percents = LOWEST_DIVIDEND_PERCENTS.add(
            HIGHEST_DIVIDEND_PERCENTS.sub(LOWEST_DIVIDEND_PERCENTS)
                .mul(healthPercents().mul(45).div(ONE_HUNDRED_PERCENTS.mul(80).div(100))).div(45)
        );

        return percents;
    }

    function healthPercents() public view returns(uint256) {
        if (totalDeposits == 0) {
            return ONE_HUNDRED_PERCENTS;
        }

        return address(this).balance
            .mul(ONE_HUNDRED_PERCENTS).div(totalDeposits);
    }

    function _bytesToAddress(bytes data) internal pure returns(address addr) {
         
        assembly {
            addr := mload(add(data, 0x14)) 
        }
    }
}