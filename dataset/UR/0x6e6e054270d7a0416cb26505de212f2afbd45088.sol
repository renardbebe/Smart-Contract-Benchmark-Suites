 

pragma solidity ^0.4.11;

 
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

contract token {
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  constructor() public{
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

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  token myToken;
  
   
  address public wallet;
  
   
  uint256 public rate = 750000 ; 

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);


  constructor(address tokenContractAddress, address _walletAddress) public{
    wallet = _walletAddress;
    myToken = token(tokenContractAddress);
  }

   
  function () payable public{
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(msg.value >= 10000000000000000); 
    require(msg.value <= 1000000000000000000); 

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    myToken.transfer(beneficiary, tokens);

    emit TokenPurchase(beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function updateRate(uint256 new_rate) onlyOwner public{
    rate = new_rate;
  }


   
   
  function forwardFunds() onlyOwner internal {
    wallet.transfer(msg.value);
  }

  function transferBackTo(uint256 tokens, address beneficiary) onlyOwner public returns (bool){
    myToken.transfer(beneficiary, tokens);
    return true;
  }

}