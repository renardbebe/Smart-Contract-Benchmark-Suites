 

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
   
  address public addressOfTokenUsedAsReward;

  uint256 public price = 350;

  token tokenReward;

  mapping (address => uint) public contributions;
  


   
   
   
   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {
     
    wallet = 0xd0af9888cFb401083ad5944c6a046C831e7d8b20; 
     
     
    addressOfTokenUsedAsReward = 0xa7A05Cf8d6D8e4e73dB47fE4de4Cbd5b63D15cfA;


    tokenReward = token(addressOfTokenUsedAsReward);
  }

  bool public started = false;

  function startSale(){
    if (msg.sender != wallet) throw;
    started = true;
  }

  function stopSale(){
    if(msg.sender != wallet) throw;
    started = false;
  }

  function setPrice(uint256 _price){
    if(msg.sender != wallet) throw;
    price = _price;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = (weiAmount) * price; 

     
    weiRaised = weiRaised.add(weiAmount);
    
    if(contributions[msg.sender].add(weiAmount)>10*10**18) throw;
    contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

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
    bool withinPeriod = started;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) {
    if(msg.sender!=wallet) throw;
    tokenReward.transfer(wallet,_amount);
  }
}