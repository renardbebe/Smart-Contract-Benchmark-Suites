 

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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract SBTTokenAbstract {
  function unlock() public;
}

 
contract StarbitCrowdsale {
  using SafeMath for uint256;

   
  address constant public SBT = 0x503F9794d6A6bB0Df8FBb19a2b3e2Aeab35339Ad;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public starbitWallet = 0xb94F5256B4B87bb7366fA85963Ae041a31F2CcFE;
  address public setWallet = 0xdca6c0569bb618f8dd91e259681e26363dbc16d4;
   
  uint256 public rate = 6000;

   
  uint256 public weiRaised;
  uint256 public weiSold;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());
    require(msg.value>=100000000000000000 && msg.value<=200000000000000000000);
     
    uint256 sbtAmounts = calculateObtainedSBT(msg.value);

     
    weiRaised = weiRaised.add(msg.value);
    weiSold = weiSold.add(sbtAmounts);
    require(ERC20Basic(SBT).transfer(beneficiary, sbtAmounts));
    emit TokenPurchase(msg.sender, beneficiary, msg.value, sbtAmounts);
    
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    starbitWallet.transfer(msg.value);
  }

  function calculateObtainedSBT(uint256 amountEtherInWei) public view returns (uint256) {
    checkRate();
    return amountEtherInWei.mul(rate);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    return withinPeriod;
  }

   
  function hasEnded() public view returns (bool) {
    bool isEnd = now > endTime || weiRaised >= 20000000000000000000000000;
    return isEnd;
  }

   
  function releaseSbtToken() public returns (bool) {
    require (msg.sender == setWallet);
    require (hasEnded() && startTime != 0);
    uint256 remainedSbt = ERC20Basic(SBT).balanceOf(this);
    require(ERC20Basic(SBT).transfer(starbitWallet, remainedSbt));    
    SBTTokenAbstract(SBT).unlock();
  }

   
  function start() public returns (bool) {
    require (msg.sender == setWallet);
    startTime = 1533052800;
    endTime = 1535731199;
  }

  function changeStarbitWallet(address _starbitWallet) public returns (bool) {
    require (msg.sender == setWallet);
    starbitWallet = _starbitWallet;
  }
   function checkRate() public returns (bool) {
    if (now>=startTime && now<1533657600){
        rate = 6000;
    }else if (now >= 1533657600 && now < 1534867200) {
        rate = 5500;
    }else if (now >= 1534867200) {
        rate = 5000;
    }
  }
}