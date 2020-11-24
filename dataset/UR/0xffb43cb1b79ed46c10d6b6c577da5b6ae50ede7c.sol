 

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

interface token { 
    function transfer(address receiver, uint amount); 
}

contract ECT2Crowdsale {
  
  using SafeMath for uint256;

  address public wallet;
  address addressOfTokenUsedAsReward;
  token tokenReward;
  uint256 public startTime;
  uint256 public endTime;
  uint public fundingGoal;
  uint public minimumFundingGoal;
  uint256 public price;
  uint256 public weiRaised;
  uint256 public stage1Bounty;
  uint256 public stage2Bounty;
  uint256 public stage3Bounty;
  uint256 public stage4Bounty;
 
  mapping(address => uint256) public balanceOf;
  bool fundingGoalReached = false;
  bool crowdsaleClosed = false;
 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FundTransfer(address backer, uint amount, bool isContribution);
  event GoalReached(address recipient, uint totalAmountRaised);
  
  modifier isMinimum() {
         if(msg.value < 1000000000000000) revert ();
        _;
    }
    
  modifier afterDeadline() { 
      if (now <= endTime) revert ();
      _;
  }    

  function ECT2Crowdsale(
  ) {
    wallet = 0x55BeA1A0335A8Ea56572b8E66f17196290Ca6467;
    addressOfTokenUsedAsReward = 0x3a799eD72BceF6fc98AeE750C5ACC352CDBA5f6c;
    price = 100 * 1 finney;
    fundingGoal = 30 * 1 finney;
    minimumFundingGoal = 10 * 1 finney;
    tokenReward = token(addressOfTokenUsedAsReward);
    startTime = 1511352000;  
    stage1Bounty = 1511353200;  
    stage2Bounty = 1511354400;  
    stage3Bounty = 1511355600;  
    stage4Bounty = 1511357400;  
    endTime = 1511359200;  
  }

   
  function () payable isMinimum{
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = (weiAmount) * price;
    
    if(now < stage1Bounty){
      tokens += (tokens * 50) / 100;
    }else if(now < stage2Bounty){
      tokens += (tokens * 40) / 100;
    }else if(now < stage3Bounty){
      tokens += (tokens * 25) / 100;
    }else if(now < stage4Bounty){
      tokens += (tokens * 10) / 100;  
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
    
     
  function withdrawEth() private{
        require(this.balance != 0);
        require(weiRaised >= minimumFundingGoal);

        pendingEthWithdrawal = this.balance;
  }
    uint pendingEthWithdrawal;

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
 
}