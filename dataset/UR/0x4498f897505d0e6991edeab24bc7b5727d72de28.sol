 

pragma solidity ^0.4.24;

 
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
contract RFCICO {
  using SafeMath for uint256;

  
   
  address public wallet;
   
  address public RFC;

  uint256 public price = 303;

  token tokenReward;

   
  

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  constructor() public{
     
    wallet = 0x1c46A08C940D9433297646cBa10Bc492c7D53A82;

     
    RFC = 0xed1CAa23883345098C7939C44Fb201AA622746aD;


    tokenReward = token(RFC);
  }

  bool public started = true;

  function startSale() public{
    if (msg.sender != wallet) revert();
    started = true;
  }

  function stopSale() public{
    if(msg.sender != wallet) revert();
    started = false;
  }

  function setPrice(uint256 _price) public{
    if(msg.sender != wallet) revert();
    price = _price;
  }
  function changeWallet(address _wallet) public{
  	if(msg.sender != wallet) revert();
  	wallet = _wallet;
  }

  function changeTokenReward(address _token) public{
    if(msg.sender!=wallet) revert();
    tokenReward = token(_token);
    RFC = _token;
  }

   
  function () payable public{
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable public{
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;


     
    uint256 tokens = ((weiAmount) * price);
    
    
   
    weiRaised = weiRaised.add(weiAmount);
    
   
    tokenReward.transfer(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
     
    if (!wallet.send(msg.value)) {
      revert();
    }
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = started;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) public{
    if(msg.sender!=wallet) revert();
    tokenReward.transfer(wallet,_amount);
  }
}