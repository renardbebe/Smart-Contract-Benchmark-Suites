 

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
   
  address public addressOfTokenUsedAsReward1;
  address public addressOfTokenUsedAsReward2;
  address public addressOfTokenUsedAsReward3;
  address public addressOfTokenUsedAsReward4;
  address public addressOfTokenUsedAsReward5;

  uint256 public price = 7500;

  token tokenReward1;
  token tokenReward2;
  token tokenReward3;
  token tokenReward4;
  token tokenReward5;

   
  


   
   
   
   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {
     
    wallet = 0xE37C4541C34e4A8785DaAA9aEb5005DdD29854ac;
     
     
     
    addressOfTokenUsedAsReward1 = 0xBD17Dfe402f1Afa41Cda169297F8de48d6Dfb613;
     
    addressOfTokenUsedAsReward2 = 0x489DF6493C58642e6a4651dDcd4145eaFBAA1018;
     
    addressOfTokenUsedAsReward3 = 0x404a639086eda1B9C8abA3e34a5f8145B4B04ea5;
     
    addressOfTokenUsedAsReward4 = 0x00755562Dfc1F409ec05d38254158850E4e8362a;
     
    addressOfTokenUsedAsReward5 = 0xE7AE9dc8F5F572e4f80655C4D0Ffe32ec16fF0E3;


    tokenReward1 = token(addressOfTokenUsedAsReward1);
    tokenReward2 = token(addressOfTokenUsedAsReward2);
    tokenReward3 = token(addressOfTokenUsedAsReward3);
    tokenReward4 = token(addressOfTokenUsedAsReward4);
    tokenReward5 = token(addressOfTokenUsedAsReward5);
  }

  bool public started = true;

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
  function changeWallet(address _wallet){
  	if(msg.sender != wallet) throw;
  	wallet = _wallet;
  }

   
   
   
   

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
     

     
    uint256 tokens = (weiAmount/10**10) * price; 
     

     
    weiRaised = weiRaised.add(weiAmount);
    
     
     

    tokenReward1.transfer(beneficiary, tokens);
    tokenReward2.transfer(beneficiary, tokens);
    tokenReward3.transfer(beneficiary, tokens);
    tokenReward4.transfer(beneficiary, tokens);
    tokenReward5.transfer(beneficiary, tokens);
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

  function withdrawTokens1(uint256 _amount) {
    if(msg.sender!=wallet) throw;
    tokenReward1.transfer(wallet,_amount);
  }
  function withdrawTokens2(uint256 _amount) {
    if(msg.sender!=wallet) throw;
    tokenReward2.transfer(wallet,_amount);
  }
  function withdrawTokens3(uint256 _amount) {
    if(msg.sender!=wallet) throw;
    tokenReward3.transfer(wallet,_amount);
  }
  function withdrawTokens4(uint256 _amount) {
    if(msg.sender!=wallet) throw;
    tokenReward4.transfer(wallet,_amount);
  }
  function withdrawTokens5(uint256 _amount) {
    if(msg.sender!=wallet) throw;
    tokenReward5.transfer(wallet,_amount);
  }
}