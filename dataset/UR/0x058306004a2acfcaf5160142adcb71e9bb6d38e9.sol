 

pragma solidity ^0.4.17;

 
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
   
  address public addressOfTokenUsedAsReward;

  token tokenReward;



   
  uint256 public startTime;
  uint256 public endTime;
   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {
    wallet = 0x7F9C7AA8A7F467DD5641BA81B218aADd6883e038;
    addressOfTokenUsedAsReward = 0xD70c22FF998cb7c5c36ae1680d1b49A435Cd7306;


    tokenReward = token(addressOfTokenUsedAsReward);
     
    startTime = now + 50410 * 1 minutes;
    endTime = startTime + 54*24*60 * 1 minutes;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;



     
    uint256 tokens = (weiAmount) * 1000;

    if(now < startTime + 7*24*60* 1 minutes){
      tokens += (tokens * 40) / 100;
    }else if (now < startTime + 27*24*60*1 minutes){
      throw;
    }else if(now < startTime + 34*24*60* 1 minutes){
      tokens += (tokens * 20) / 100;
    }else if(now < startTime + 41*24*60* 1 minutes){
      tokens += (tokens * 15) / 100;
    }else if(now < startTime + 47*24*60* 1 minutes){
      tokens += (tokens * 10) / 100;
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