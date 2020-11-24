 

pragma solidity 0.4.24;
 
 
 
 
 
 
 
 
 
 
   
 
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
  uint256 public price = 42000;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {
     
    wallet = 0x423A3438cF5b954689a85D45B302A5D1F3C763D4;
     
     
    addressOfTokenUsedAsReward = 0xdd007278B667F6bef52fD0a4c23604aA1f96039a;


    tokenReward = token(addressOfTokenUsedAsReward);
  }

  bool started = false;
  
 
    function startSale(uint256 Start,uint256 End,uint256 amount) public
    {
     if (msg.sender != wallet || started) throw;
     require(Start < End);
  require(now < Start);
   
  startTime=Start;
  endTime=End;
  tokenReward.transfer(this,amount);
    }
 function stopSale()  public{
            require(msg.sender == wallet);
            endTime = 0;
        }
  function setPrice(uint256 _price){
    if(msg.sender != wallet) throw;
    price = _price;
  }
 function manualEtherWithdraw() public{
      require(msg.sender == wallet); 
   if (!wallet.send(address(this).balance)) {
     throw;
   }
  }
   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = (weiAmount/
10**10) * price; 

     
     
     
     
     
     
     
     
     
     
     
     
     
     
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