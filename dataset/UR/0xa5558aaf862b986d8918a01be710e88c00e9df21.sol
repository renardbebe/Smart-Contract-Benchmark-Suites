 

pragma solidity ^0.4.15;

 
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

 
interface Token {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract PreSale is Ownable {

  using SafeMath for uint256;

  Token token;

  uint256 public constant RATE = 3900;  
  uint256 public constant CAP = 2000;  
  uint256 public constant START = 1528934400;  
  uint256 public constant DAYS = 32;  

  uint256 public constant initialTokens = 7800000 * 10**18;  
  bool public initialized = false;
  uint256 public raisedAmount = 0;

  event BoughtTokens(address indexed to, uint256 value);

  modifier whenSaleIsActive() {
     
    assert(isActive());

    _;
  }

  function PreSale(address _tokenAddr) {
      require(_tokenAddr != 0);
      token = Token(_tokenAddr);
  }

  function initialize() onlyOwner {
      require(initialized == false);  
      require(tokensAvailable() == initialTokens);  
      initialized = true;
  }

  function isActive() constant returns (bool) {
    return (
        initialized == true &&
        now >= START &&  
        now <= START.add(DAYS * 1 days) &&  
        goalReached() == false  
    );
  }

  function goalReached() constant returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }

  function () payable {
    buyTokens();
  }

   
  function buyTokens() payable whenSaleIsActive {
     
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);

    BoughtTokens(msg.sender, tokens);

     
    raisedAmount = raisedAmount.add(msg.value);

     
    token.transfer(msg.sender, tokens);

     
    owner.transfer(msg.value);
  }

   
  function tokensAvailable() constant returns (uint256) {
    return token.balanceOf(this);
  }

   
  function destroy() onlyOwner {
     
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(owner, balance);

     
    selfdestruct(owner);
  }

}