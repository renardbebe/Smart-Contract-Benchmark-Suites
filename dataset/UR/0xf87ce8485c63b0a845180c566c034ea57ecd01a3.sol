 

pragma solidity ^0.4.21;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


contract RealEstateCryptoFund {
  function transfer(address to, uint256 value) public returns (bool);
  function balanceOf(address who) public constant returns (uint256);
}


 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract RECFCO is Ownable {
  
  using SafeMath for uint256;

  RealEstateCryptoFund public token;

  mapping(address=>bool) public participated;
   
   
    
  address public wallet;
  
   
  
   
  uint256 public  salesdeadline;

   
  uint256 public rate;

   
  uint256 public weiRaised;
  
 event sales_deadlineUpdated(uint256 sales_deadline ); 
 event WalletUpdated(address wallet);
 event RateUpdate(uint256 rate);
  

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function RECFCO(address _tokenAddress, address _wallet) public {
    token = RealEstateCryptoFund(_tokenAddress);
    wallet = _wallet;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

 

  

  function buyTokens(address beneficiary) public payable {
    require(now < salesdeadline);
    require(beneficiary != address(0));
    require(msg.value != 0);

    uint256 weiAmount = msg.value;

    uint256 tokens = getTokenAmount( weiAmount);

    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokens);

    emit TokenPurchase(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    participated[beneficiary] = true;

    forwardFunds();
  }

 

function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    uint256 tokenAmount;
    tokenAmount = weiAmount.mul(rate);
    return tokenAmount;
  }

  
  function forwardFunds() internal {
    wallet.transfer(msg.value);
      
  }
 
function setRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    rate = _rate;
    emit RateUpdate(rate);
}

 
function setWallet (address _wallet) onlyOwner public {
wallet=_wallet;
emit WalletUpdated(wallet);
}

 
function setsalesdeadline (uint256 _salesdeadline) onlyOwner public {
salesdeadline=_salesdeadline;
require(now < salesdeadline);
emit sales_deadlineUpdated(salesdeadline);
}
    

}