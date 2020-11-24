 

pragma solidity ^0.4.24;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
interface token { function transfer(address, uint) external; }
contract Crowdsale {
  using SafeMath for uint256;

   
   
  address public wallet;
   
  address public addressOfTokenUsedAsReward;

  uint256 public price = 25000;

  token tokenReward;

  


   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  constructor () public {
     
    wallet = 0x6F3D70BAe7Cb77F064B7bD1773D5c1fB38F67cbE;
     
    addressOfTokenUsedAsReward = 0x85C77C93B730Bc4F568aff15F98Cea8Bd7230E1c  ;


    tokenReward = token(addressOfTokenUsedAsReward);
  }

  bool public started = true;


  function stopSale() public {
    require (msg.sender == wallet);
    started = false;
  }


   
  function () payable public {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable public {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    require (weiAmount >= 5**16);

     
    uint256 tokens = (weiAmount/10**10) * price; 

     
    weiRaised = weiRaised.add(weiAmount);
    

    tokenReward.transfer(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = started;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) public {
    require (msg.sender==wallet);
    tokenReward.transfer(wallet,_amount);
  }
}