 

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
    uint256[]   public referralPercents = [500, 300, 200];  

    address public admin = msg.sender;
    uint256 public totalDeposits = 0;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public joinedAt;
    mapping(address => uint256) public updatedAt;
    mapping(address => address) public referrers;

    event InvestorAdded(address investor);
    event ReferrerAdded(address investor, address referrer);
    event DepositAdded(address investor, uint256 deposit, uint256 amount);
    event DividendPayed(address investor, uint256 dividend);
    event ReferrerPayed(address investor, address referrer, uint256 amount);
    event AdminFeePayed(address investor, uint256 amount);
    event TotalDepositsChanged(uint256 totalDeposits);
    event BalanceChanged(uint256 balance);
    
    function() public payable {
         
        uint256 dividends = dividendsForUser(msg.sender);
        if (dividends > 0) {
            if (dividends > address(this).balance) {
                dividends = address(this).balance;
            }
            msg.sender.transfer(dividends);
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
                address referrer = bytesToAddress(msg.data);
                if (referrer != address(0) && deposits[referrer] > 0 && now >= joinedAt[referrer].add(1 days)) {  
                    referrers[msg.sender] = referrer;
                    emit ReferrerAdded(msg.sender, referrer);
                }
            }

             
            referrer = referrers[msg.sender];
            for (uint i = 0; referrer != address(0) && i < referralPercents.length; i++) {
                uint256 refAmount = msg.value.mul(referralPercents[i]).div(ONE_HUNDRED_PERCENTS);
                referrer.send(refAmount);  
                emit ReferrerPayed(msg.sender, referrer, refAmount);
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

    function bytesToAddress(bytes data) internal pure returns(address addr) {
         
        assembly {
            addr := mload(add(data, 20)) 
        }
    }
}