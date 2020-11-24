 

pragma solidity ^0.4.11;

 
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
contract Crowdsale {
  using SafeMath for uint256;

   
   
  address public wallet;
   
  address addressOfTokenUsedAsReward;

  token tokenReward;



   
  uint256 public startTime;
  uint256 public endTime;
   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {
    wallet = 0x8353A3263bc246589eE2a83427D9a805EDD79750;
     
    addressOfTokenUsedAsReward = 0x070C9244a54353a0F9c43670b21856Df2CC4e439;


    tokenReward = token(addressOfTokenUsedAsReward);
    startTime = now + 28250 * 1 minutes;
    endTime = startTime + 64*24*60 * 1 minutes;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = (weiAmount / 10000000000) * 300;

    if(now < startTime + 1*7*24*60* 1 minutes){
      tokens += (tokens * 25) / 100;
    }else if(now < startTime + 2*7*24*60* 1 minutes){
      tokens += (tokens * 20) / 100;
    }else if(now < startTime + 3*7*24*60* 1 minutes){
      tokens += (tokens * 15) / 100;
    }else if(now < startTime + 4*7*24*60* 1 minutes){
      tokens += (tokens * 10) / 100;
    }else if(now < startTime + 5*7*24*60* 1 minutes){
      tokens += (tokens * 5) / 100;
    }

     
    weiRaised = weiRaised.add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
     
    if (!wallet.send(msg.value)) {
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
    if(msg.sender!=wallet) throw;
    tokenReward.transfer(wallet,_amount);
  }
}