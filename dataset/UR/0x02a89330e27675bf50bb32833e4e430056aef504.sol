 

pragma solidity ^0.4.18;

 
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

contract SmartBondsSale {
  using SafeMath for uint256;

   
   
  address public badgerWallet;
  address public investmentFundWallet;
  address public buyoutWallet;
   
  address addressOfTokenUsedAsReward;

  token tokenReward;



   
  uint256 public startTime;
  uint256 public endTime;
   
  uint256 public weiRaised;
  
  uint256 public badgerAmount;
  uint256 public investAmount;
  uint256 public buyoutAmount;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function SmartBondsSale() {
     
    badgerWallet = 0x5cB7a6547A9408e3C9B09FB5c640d4fB767b8070; 
    investmentFundWallet = 0x8F2d31E3c259F65222D0748e416A79e51589Ce3b;
    buyoutWallet = 0x336b903eF5e3c911df7f8172EcAaAA651B80CA1D;
   
     
    addressOfTokenUsedAsReward = 0x38dCb83980183f089FC7D147c5bF82E5C9b8F237;
    tokenReward = token(addressOfTokenUsedAsReward);
    
     
    startTime = 1533583718;  
    endTime = startTime + 182 * 1 days;  
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

     
    uint256 weiAmount = msg.value;
    if(weiAmount < 2.5 * 10**18) throw; 
    if(weiAmount > 25 * 10**18) throw;
    
     
    badgerAmount = (5 * weiAmount)/100;
    buyoutAmount = (25 * weiAmount)/100;
    investAmount = (70 * weiAmount)/100;

     
    uint256 tokenPrice = 25000000000000000;
     
    uint256 tokens = (weiAmount *10**18) / tokenPrice;

     
    weiRaised = weiRaised.add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
     
    if (!badgerWallet.send(badgerAmount)) {
      throw;
    }
    if (!investmentFundWallet.send(investAmount)){
        throw;
    }
    if (!buyoutWallet.send(buyoutAmount)){
        throw;
    }
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  function withdrawTokens(uint256 _amount) {
    if(msg.sender!=badgerWallet) throw;
    tokenReward.transfer(badgerWallet,_amount);
  }
}