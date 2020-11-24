 

pragma solidity ^0.4.23;

 
 
 
 
 
 
 
 
 
 
 
 
 

 
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

  uint256 public price = 1000;
  uint256 public bonusPercent = 20;
  uint256 public referralBonusPercent = 5;

  token tokenReward;

   
   
  mapping (address => uint) public bonuses;
  mapping (address => uint) public bonusUnlockTime;


   
   
   
   
  uint256 public weiRaised;
  uint256 public tokensSold;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {

     
    wallet = 0x965A2a21C60252C09E5e2872b8d3088424c4f58A;
     
     
    addressOfTokenUsedAsReward = 0xF86C2C4c7Dd79Ba0480eBbEbd096F51311Cfb952;


    tokenReward = token(addressOfTokenUsedAsReward);
  }

  bool public started = true;

  function startSale() {
    require(msg.sender == wallet);
    started = true;
  }

  function stopSale() {
    require(msg.sender == wallet);
    started = false;
  }

  function setPrice(uint256 _price) {
    require(msg.sender == wallet);
    price = _price;
  }

  function changeWallet(address _wallet) {
    require(msg.sender == wallet);
    wallet = _wallet;
  }

  function changeTokenReward(address _token) {
    require(msg.sender==wallet);
    tokenReward = token(_token);
    addressOfTokenUsedAsReward = _token;
  }

  function setBonusPercent(uint256 _bonusPercent) {
    require(msg.sender == wallet);
    bonusPercent = _bonusPercent;
  }

  function getBonus() {
    address sender = msg.sender;
    require(bonuses[sender] > 0);
    require(bonusUnlockTime[sender]!=0 && 
      now > bonusUnlockTime[sender]);
    tokenReward.transfer(sender, bonuses[sender]);
    bonuses[sender] = 0;
  }

  function setReferralBonusPercent(uint256 _referralBonusPercent) {
    require(msg.sender == wallet);
    referralBonusPercent = _referralBonusPercent;
  }


   
   
   
   
   

   
   
   
   
   

   
  function () payable {
    buyTokens(msg.sender, 0x0);
  }

   
  function buyTokens(address beneficiary, address referrer) payable {
    require(beneficiary != 0x0);
    require(validPurchase());
     

    uint256 weiAmount = msg.value;

     
     

     
    uint256 tokens = weiAmount.mul(price);
    uint256 bonusTokens = tokens.mul(bonusPercent)/100;
    uint256 referralBonusTokens = tokens.mul(referralBonusPercent)/100;
     


     
    weiRaised = weiRaised.add(weiAmount);
    
     
     

    tokenReward.transfer(beneficiary, tokens);
    tokensSold = tokensSold.add(tokens);
    bonuses[beneficiary] = bonuses[beneficiary].add(bonusTokens);
    bonusUnlockTime[beneficiary] = now.add(6*30 days);
    tokensSold = tokensSold.add(bonusTokens);
    if (referrer != 0x0) {
      bonuses[referrer] = bonuses[referrer].add(referralBonusTokens);
      bonusUnlockTime[referrer] = now.add(6*30 days);
      tokensSold = tokensSold.add(referralBonusTokens);      
    }

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
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

  function withdrawTokens(uint256 _amount) {
    require(msg.sender==wallet);
    tokenReward.transfer(wallet,_amount);
  }
}