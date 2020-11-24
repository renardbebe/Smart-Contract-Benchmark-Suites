 

pragma solidity ^0.4.16;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract token { function transfer(address receiver, uint amount){  } }
contract WaterCrowdsale {
  using SafeMath for uint256;

   
   
  address public wallet;
   
  address addressOfTokenUsedAsReward;

  token tokenReward;



   
  uint256 public startTimeInMinutes;
  uint256 public endTimeinMinutes;
  uint public fundingGoal;
  uint public minimumFundingGoal;
  uint256 public price;
   
  uint256 public weiRaised;
  uint256 public firstWeekBonusInWeek;
  uint256 public secondWeekBonusInWeek;
  uint256 public thirdWeekBonusInWeek;
 
  
  mapping(address => uint256) public balanceOf;
  bool fundingGoalReached = false;
  bool crowdsaleClosed = false;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FundTransfer(address backer, uint amount, bool isContribution);
  event GoalReached(address recipient, uint totalAmountRaised);
  
  modifier isMinimum() {
         if(msg.value < 500000000000000000) throw;
        _;
    }
    
  modifier afterDeadline() { 
      if (now <= endTimeinMinutes) throw;
      _;
  }    

  function WaterCrowdsale(uint256 _startTimeInMinutes, 
  uint256 _endTimeInMinutes, 
  address _beneficiary, 
  address _addressTokenUsedAsReward,
  uint256 _tokenConvertioninEther,
  uint256 _fundingGoalInEther,
  uint256 _minimumFundingGoalInEther,
  uint256 _firstWeekBonusInWeek,
  uint256 _secondWeekBonusInWeek,
  uint256 _thirdWeekBonusInWeek ) {
    wallet = _beneficiary;
     
    addressOfTokenUsedAsReward = _addressTokenUsedAsReward;
    price = _tokenConvertioninEther;
    fundingGoal = _fundingGoalInEther * 1 ether;
    minimumFundingGoal = _minimumFundingGoalInEther * 1 ether;
    tokenReward = token(addressOfTokenUsedAsReward);
     
    startTimeInMinutes = now + _startTimeInMinutes * 1 minutes;
    firstWeekBonusInWeek = startTimeInMinutes + _firstWeekBonusInWeek*7*24*60* 1 minutes;
    secondWeekBonusInWeek = startTimeInMinutes + _secondWeekBonusInWeek*7*24*60* 1 minutes;
    thirdWeekBonusInWeek = startTimeInMinutes + _thirdWeekBonusInWeek*7*24*60* 1 minutes;

    endTimeinMinutes = startTimeInMinutes + _endTimeInMinutes * 1 minutes;
    
     
  }

   
  function () payable isMinimum{
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = (weiAmount) * price;
    
    if(now < firstWeekBonusInWeek){
      tokens += (tokens * 20) / 100;
    }else if(now < secondWeekBonusInWeek){
      tokens += (tokens * 10) / 100;
    }else if(now < thirdWeekBonusInWeek){
      tokens += (tokens * 5) / 100;
    }
     
    balanceOf[msg.sender] += weiAmount;
    weiRaised = weiRaised.add(weiAmount);
    tokenReward.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
  
  
   
  function safeWithdrawal() afterDeadline {
        if (weiRaised < fundingGoal && weiRaised < minimumFundingGoal) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                     
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if ((weiRaised >= fundingGoal || weiRaised >= minimumFundingGoal) && wallet == msg.sender) {
            if (wallet.send(weiRaised)) {
                FundTransfer(wallet, weiRaised, false);
                GoalReached(wallet, weiRaised);
            } else {
                 
                fundingGoalReached = false;
            }
        }
    }


   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTimeInMinutes && now <= endTimeinMinutes;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTimeinMinutes;
  }
 
}