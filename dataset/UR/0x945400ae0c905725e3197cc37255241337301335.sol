 

pragma solidity ^0.4.16;

 
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

contract Crowdsale is Ownable {

  using SafeMath for uint256;

  Token token;

  uint256 public constant RATE = 312;  
  uint256 public constant START = 1505433600;  
  uint256 public DAYS = 20;  

  uint256 public constant initialTokens = 15600000 * 10**18;  
  bool public initialized = false;

  uint256 public raisedAmount = 0;

  event BoughtTokens(address indexed to, uint256 value);

  modifier whenSaleIsActive() {
     
    assert(isActive());

    _;
  }

  function Crowdsale(address _tokenAddr) {
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
        now <= START.add(DAYS * 1 days)  
    );
  }

  function () payable {
    buyTokens();
  }

   
  function buyTokens() payable whenSaleIsActive {

     
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);
    uint256 bonus = 0;

    require(tokens >= 1);

     
    if (now <= START.add(5 days)) {
      bonus = tokens.mul(20).div(100);
    } else if (now <= START.add(8 days)) {
      bonus = tokens.mul(10).div(100);
    } else if (now <= START.add(18 days)) {
      bonus = tokens.mul(5).div(100);
    }
    
    tokens = tokens.add(bonus);

    BoughtTokens(msg.sender, tokens);

     
    token.transfer(msg.sender, tokens);

     
    owner.transfer(msg.value);
  }

   
  function tokensAvailable() constant returns (uint256) {
    return token.balanceOf(this);
  }

   
  function destroy() onlyOwner {
     
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);

     
    selfdestruct(owner);
  }

}