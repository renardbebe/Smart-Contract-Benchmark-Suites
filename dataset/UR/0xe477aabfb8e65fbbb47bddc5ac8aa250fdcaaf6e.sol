 

pragma solidity ^0.5.11;

 
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

 
interface token { function transfer(address receiver, uint amount) external ; }
contract Crowdsale {
  using SafeMath for uint256;


   
  address payable public wallet;
   
  address public addressOfTokenUsedAsReward;

  uint256 public price = 2000;

  token tokenReward;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  constructor () public {
     
    wallet = 0x9F1D5D27c7FD3EaB394b65B6c06e4Ef22F333210;
    
     
    addressOfTokenUsedAsReward =  0x2Da95f7e0093CE7DC9D9BA5f47b655108754B342;

    tokenReward = token(addressOfTokenUsedAsReward);
  }

  bool public started = true;

  function startSale() public {
    require (msg.sender == wallet);
    started = true;
  }

  function stopSale() public {
    require(msg.sender == wallet);
    started = false;
  }

  function setPrice(uint256 _price) public {
    require(msg.sender == wallet);
    price = _price;
  }
  function changeWallet(address payable _wallet) public {
  	require (msg.sender == wallet);
  	wallet = _wallet;
  }


   
  function () external payable  {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address payable beneficiary) payable public {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;


     
    uint256 tokens = (weiAmount) * price; 
     

     
    weiRaised = weiRaised.add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
     wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = started;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) public {
    require (msg.sender == wallet);
    tokenReward.transfer(wallet,_amount);
  }
}