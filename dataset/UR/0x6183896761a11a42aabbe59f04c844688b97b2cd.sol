 

pragma solidity ^0.4.13;

 
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

 
contract Pausable is Ownable {
    
  event Pause();
  
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
  
}


 
contract PreSale is Pausable {
    
  event Invest(address, uint);

  using SafeMath for uint;
    
  address public wallet;

  uint public start;

  uint public min;

  uint public hardcap;
  
  uint public invested;
  
  uint public period;

  mapping (address => uint) public balances;

  address[] public investors;

  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }

  modifier isUnderHardcap() {
    require(invested < hardcap);
    _;
  }

  function setMin(uint newMin) onlyOwner {
    min = newMin;
  }

  function setHardcap(uint newHardcap) onlyOwner {
    hardcap = newHardcap;
  }
  
  function totalInvestors() constant returns (uint) {
    return investors.length;
  }
  
  function balanceOf(address investor) constant returns (uint) {
    return balances[investor];
  }
  
  function setStart(uint newStart) onlyOwner {
    start = newStart;
  }
  
  function setPeriod(uint16 newPeriod) onlyOwner {
    period = newPeriod;
  }
  
  function setWallet(address newWallet) onlyOwner {
    require(newWallet != address(0));
    wallet = newWallet;
  }

  function invest() saleIsOn isUnderHardcap whenNotPaused payable {
    require(msg.value >= min);
    wallet.transfer(msg.value);
    if(balances[msg.sender] == 0) {
      investors.push(msg.sender);    
    }
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    invested = invested.add(msg.value);
    Invest(msg.sender, msg.value);
  }

  function() external payable {
    invest();
  }

}