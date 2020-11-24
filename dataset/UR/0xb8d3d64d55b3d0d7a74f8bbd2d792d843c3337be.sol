 

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

contract ProvidencePresale {
  using SafeMath for uint256;

   
   
  address public wallet;
   
  address addressOfTokenUsedAsReward;

  token tokenReward;



   
  uint256 public startTime;
  uint256 public endTime;
   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function ProvidencePresale() {
     
    wallet = 0x2F81D169A4A773e614eC6958817Ed76381089615;
     
    addressOfTokenUsedAsReward = 0x50584a9bDfAb54B82e620b8a14cC082B07886841;
    tokenReward = token(addressOfTokenUsedAsReward);
    startTime = now;  
    endTime = startTime + 14*24*60 * 1 minutes;   
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   

  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    if(weiAmount < 1 * 10**18) throw;

     
    uint256 tokens = (weiAmount) * 810;

     
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