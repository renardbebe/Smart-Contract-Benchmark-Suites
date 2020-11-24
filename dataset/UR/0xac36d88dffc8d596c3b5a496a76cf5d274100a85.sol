 

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

   

  token tokenReward;

   
  mapping(address => bool) public whitelist;


   
  uint256 public startTime;
  uint256 public endTime;
   
  uint256 public weiRaised;
  uint256 public tokensSold;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {
     
    startTime = now + 80715 * 1 minutes;
    endTime = startTime + 31*24*60*1 minutes;

     
    wallet = 0xe65b6eEAfE34adb2e19e8b2AE9c517688771548E;
     
     
    addressOfTokenUsedAsReward = 0xA024E8057EEC474a9b2356833707Dd0579E26eF3;


    tokenReward = token(addressOfTokenUsedAsReward);
  }

   

   
   
   
   

   
   
   
   

   
   
   
   

  function changeWallet(address _wallet){
  	require(msg.sender == wallet);
  	wallet = _wallet;
  }

   
   
   
   
   

  function whitelistAddresses(address[] _addrs){
    require(msg.sender==wallet);
    for(uint i = 0; i < _addrs.length; ++i)
      whitelist[_addrs[i]] = true;
  }

  function removeAddressesFromWhitelist(address[] _addrs){
    require(msg.sender==wallet);
    for(uint i = 0;i < _addrs.length;++i)
      whitelist[_addrs[i]] = false;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    require(whitelist[beneficiary]);

    uint256 weiAmount = msg.value;

     
     

     
    uint256 tokens = (weiAmount) * 5000; 
     

     

     
    if(now < startTime + 9*24*60* 1 minutes){
      tokens += (tokens * 40) / 100; 
      if(tokensSold>14000000*10**18) throw;
    }else if(now < startTime + 16*24*60* 1 minutes){
      throw;
    }else if(now < startTime + 23*24*60* 1 minutes){
      tokens += (tokens * 20) / 100;
    }else if(now < startTime + 25*24*60* 1 minutes){
      throw;
    }

     
    weiRaised = weiRaised.add(weiAmount);
    
     
     

    tokenReward.transfer(beneficiary, tokens);
    tokensSold = tokensSold.add(tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) {
    require(msg.sender==wallet);
    tokenReward.transfer(wallet,_amount);
  }
}