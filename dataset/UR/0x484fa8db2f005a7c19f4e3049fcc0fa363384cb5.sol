 

pragma solidity ^0.4.25;

 
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


   
  address public wallet;
   
  address public addressOfTokenUsedAsReward;

  uint256 public price = 1650;

  token tokenReward;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  constructor () public {
     
    wallet = 0x237625d599dd5F30E51ccd0F51B5Ee564d31Bd7b;
    
     
    addressOfTokenUsedAsReward =  0x4a74Df6113E3d38d8e184273341Cb6BBb6885152;

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
  function changeWallet(address _wallet) public {
  	require (msg.sender == wallet);
  	wallet = _wallet;
  }


   
  function () payable public {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable public {
    require(beneficiary != 0x0);
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

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = started;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) public {
    require (msg.sender == wallet);
    tokenReward.transfer(wallet,_amount);
  }
}