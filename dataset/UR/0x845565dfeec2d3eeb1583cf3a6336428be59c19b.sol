 

pragma solidity ^0.4.14;


 
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


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


interface GlobexSci {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}


 
contract GlobexSciICO is Ownable {
  using SafeMath for uint256;

   
  GlobexSci public token = GlobexSci(0x88dBd3f9E6809FC24d27B9403371Af1cC089ba9e);

   
  uint256 public startDate = 1524182400;  
  
   
  uint256 public minimumParticipationAmount = 100000000000000000 wei;  

   
  address wallet;

   
  uint256 rate = 500;

   
  uint256 public weiRaised;

   
  bool public isFinalized = false;

   
  uint256 public cap = 60000000000000000000000 wei;  
 
    uint week1 = 1 * 7 * 1 days;
    uint week2 = 2 * 7 * 1 days;
    uint week3 = 3 * 7 * 1 days;
    uint week4 = 4 * 7 * 1 days;
    uint week5 = 5 * 7 * 1 days;

  event Finalized();

    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


   
  event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);


  
  function GlobexSciICO() {
    wallet = msg.sender;
  }

     
     
     
     
     
     
  function getBonus() constant returns (uint256 price) {
        uint currentDate = now;

        if (currentDate < startDate + week1) {
            return 25;
        }

        if (currentDate > startDate + week1 && currentDate < startDate + week2) {
            return 20;
        }

        if (currentDate > startDate + week2 && currentDate < startDate + week3) {
            return 15;
        }
        if (currentDate > startDate + week3 && currentDate < startDate + week4) {
            return 10;
        }
        if (currentDate > startDate + week4 && currentDate < startDate + week5) {
            return 5;
        }
        return 0; 
    }
  

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

     
    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);
    uint bonus = getBonus();
    tokens = tokens + tokens * bonus / 100;

     
    token.transfer(beneficiary, tokens);

     
    weiRaised = weiRaised.add(weiAmount);

     
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     
    forwardFunds();
  }


   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function finalize() onlyOwner {
    require(!isFinalized);
    uint256 unsoldTokens = token.balanceOf(this);
    token.transfer(wallet, unsoldTokens);
    isFinalized = true;
    Finalized();
  }


   
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = startDate <= now;
    bool nonZeroPurchase = msg.value != 0;
    bool minAmount = msg.value >= minimumParticipationAmount;
    bool withinCap = weiRaised.add(msg.value) <= cap;

    return withinPeriod && nonZeroPurchase && minAmount && !isFinalized && withinCap;
  }

     
  function capReached() public constant returns (bool) {
    return weiRaised >= cap;
  }

   
  function hasEnded() public constant returns (bool) {
    return isFinalized;
  }

}