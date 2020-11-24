 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Project424_2 {
  using SafeMath for uint256;

  address constant MARKETING_ADDRESS = 0xcc1B012Dc66f51E6cE77122711A8F730eF5a97fa;
  address constant TEAM_ADDRESS = 0x155a3c1Ab0Ac924cB3079804f3784d4d13cF3a45;
  address constant REFUND_ADDRESS = 0x732445bfB4F9541ba4A295d31Fb830B2ffdA80F8;

  uint256 constant ONE_HUNDREDS_PERCENTS = 10000;       
  uint256 constant INCOME_MAX_PERCENT = 5000;           
  uint256 constant MARKETING_FEE = 1000;                
  uint256 constant WITHDRAWAL_PERCENT = 1500;           
  uint256 constant TEAM_FEE = 300;                      
  uint256 constant REFUND_FEE = 200;                    
  uint256 constant INCOME_PERCENT = 150;                
  uint256 constant BALANCE_WITHDRAWAL_PERCENT = 10;     
  uint256 constant BALANCE_INCOME_PERCENT = 1;          

  uint256 constant DAY = 86400;                         

  uint256 constant SPECIAL_NUMBER = 4240 szabo;         
  
  event AddInvestor(address indexed investor, uint256 amount);

  struct User {
    uint256 firstTime;
    uint256 deposit;
  }
  mapping(address => User) public users;

  function () payable external {
    User storage user = users[msg.sender];

     
    if ( msg.value != 0 && user.firstTime == 0 ) {
      user.firstTime = now;
      user.deposit = msg.value;
      AddInvestor(msg.sender, msg.value);
      
      MARKETING_ADDRESS.send(msg.value.mul(MARKETING_FEE).div(ONE_HUNDREDS_PERCENTS));
      TEAM_ADDRESS.send(msg.value.mul(TEAM_FEE).div(ONE_HUNDREDS_PERCENTS));
      REFUND_ADDRESS.send(msg.value.mul(REFUND_FEE).div(ONE_HUNDREDS_PERCENTS));

    } else if ( msg.value == SPECIAL_NUMBER && user.firstTime != 0 ) {  
      uint256 withdrawalSum = userWithdrawalSum(msg.sender).add(SPECIAL_NUMBER);

       
      if (withdrawalSum >= address(this).balance) {
        withdrawalSum = address(this).balance;
      }

       
      user.firstTime = 0;
      user.deposit = 0;

      msg.sender.send(withdrawalSum);
    } else {
      revert();
    }
  }

  function userWithdrawalSum(address wallet) public view returns(uint256) {
    User storage user = users[wallet];
    uint256 daysDuration = getDays(wallet);
    uint256 withdrawal = user.deposit;


    (uint256 getBalanceWithdrawalPercent, uint256 getBalanceIncomePercent) = getBalancePercents();
    uint currentDeposit = user.deposit;
    
    if (daysDuration == 0) {
      return withdrawal.sub(withdrawal.mul(WITHDRAWAL_PERCENT.add(getBalanceWithdrawalPercent)).div(ONE_HUNDREDS_PERCENTS));
    }

    for (uint256 i = 0; i < daysDuration; i++) {
      currentDeposit = currentDeposit.add(currentDeposit.mul(INCOME_PERCENT.add(getBalanceIncomePercent)).div(ONE_HUNDREDS_PERCENTS));

      if (currentDeposit >= user.deposit.add(user.deposit.mul(INCOME_MAX_PERCENT).div(ONE_HUNDREDS_PERCENTS))) {
        withdrawal = user.deposit.add(user.deposit.mul(INCOME_MAX_PERCENT).div(ONE_HUNDREDS_PERCENTS));

        break;
      } else {
        withdrawal = currentDeposit.sub(currentDeposit.mul(WITHDRAWAL_PERCENT.add(getBalanceWithdrawalPercent)).div(ONE_HUNDREDS_PERCENTS));
      }
    }
    
    return withdrawal;
  }
  
  function getDays(address wallet) public view returns(uint256) {
    User storage user = users[wallet];
    if (user.firstTime == 0) {
        return 0;
    } else {
        return (now.sub(user.firstTime)).div(DAY);
    }
  }

  function getBalancePercents() public view returns(uint256 withdrawalRate, uint256 incomeRate) {
    if (address(this).balance >= 100 ether) {
      if (address(this).balance >= 5000 ether) {
        withdrawalRate = 500;
        incomeRate = 50;
      } else {
        uint256 steps = (address(this).balance).div(100 ether);
        uint256 withdrawalUtility = 0;
        uint256 incomeUtility = 0;

        for (uint i = 0; i < steps; i++) {
          withdrawalUtility = withdrawalUtility.add(BALANCE_WITHDRAWAL_PERCENT);
          incomeUtility = incomeUtility.add(BALANCE_INCOME_PERCENT);
        }
        
        withdrawalRate = withdrawalUtility;
        incomeRate = incomeUtility;
      }
    } else {
      withdrawalRate = 0;
      incomeRate = 0;
    }
  }
}