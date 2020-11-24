 

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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

contract EmpireToken is StandardToken, Ownable {

  string public name = 'Empire Token';
  uint8 public decimals = 18;
  string public symbol = 'EMP';
  string public version = '0.1';

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract EmpireCrowdsale is Ownable, Pausable {
  using SafeMath for uint256;

   
  EmpireToken public token;

   
  uint256 public start;
  uint256 public end;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  uint256 public presaleCap;
  uint256 public softCap;
  uint256 public gracePeriodCap;
    
  uint256 public gracePeriodStart;



    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function EmpireCrowdsale(uint256 _start, uint256 _end, address _wallet, uint256 _presaleCap, uint256 _softCap, uint256 _graceCap) payable {
    require(_start >= now);
    require(_end >= _start);
    require(_wallet != 0x0);
    require(_presaleCap > 0);
    require(_softCap > 0);
    require(_graceCap > 0);

    start = _start;
    end = _end;
    wallet = _wallet;
    token = new EmpireToken();
    presaleCap = _presaleCap;    
    softCap = _softCap;          
    gracePeriodCap = _graceCap;  
  }

   
   
  function getRate() constant returns (uint) {
    bool duringPresale = (now < start) && (weiRaised < presaleCap * 1 ether);
    bool gracePeriodSet = gracePeriodStart != 0;
    bool duringGracePeriod = gracePeriodSet && now <= gracePeriodStart + 24 hours;
    uint rate = 1000;
    
    if (duringPresale) rate = 1300;                
    else if (now <= start +  3 days) rate = 1250;  
    else if (now <= start + 10 days) rate = 1150;  
    else if (now <= start + 20 days) rate = 1050;  
    
    if (duringGracePeriod) return rate.sub(rate.div(10));  
    
    return rate;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) whenNotPaused() payable {
    require(beneficiary != 0x0);
    require(msg.value != 0);
    require(now <= end);

     
    if ((weiRaised >= softCap * 1 ether) && gracePeriodStart == 0) 
      gracePeriodStart = block.timestamp;

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(getRate());
    
     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
   
  function finishMinting() onlyOwner returns (bool) {
    return token.finishMinting();
  }


}