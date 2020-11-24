 

pragma solidity ^0.4.16;

 
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

contract MintableToken is StandardToken, Ownable {
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(0X0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract ChangeCoin is MintableToken {
  string public name = "Change COIN";
  string public symbol = "CAG";
  uint256 public decimals = 18;

  bool public tradingStarted = false;

   
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

   
  function startTrading() onlyOwner {
    tradingStarted = true;
  }


   
  function transfer(address _to, uint _value) hasStartedTrading returns (bool){
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading returns (bool){
    return super.transferFrom(_from, _to, _value);
  }
}

contract ChangeCoinPresale is Ownable {
  using SafeMath for uint256;

   
  ChangeCoin public token;

   
  uint256 public startTimestamp;
  uint256 public endTimestamp;

   
  address public hardwareWallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  uint256 public minContribution;

   
  uint256 public hardcap;

   
  uint256 public numberOfPurchasers = 0;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event PreSaleClosed();

  function ChangeCoinPresale() {
    startTimestamp = 1504945800;
    endTimestamp = 1505397600;
    rate = 500;
    hardwareWallet = 0x71B1Ee0848c4F68df05429490fc4237089692e1e;
    token = new ChangeCoin();
    minContribution = 9.9 ether;
    hardcap = 50000 ether;

    require(startTimestamp >= now);
    require(endTimestamp >= startTimestamp);
  }

   
  function bonusAmmount(uint256 tokens) internal returns(uint256) {
     
    if (numberOfPurchasers < 501) {
      return tokens * 3 / 10;
    } else {
      return tokens /4;
    }
  }

   
  modifier validPurchase {
    require(now >= startTimestamp);
    require(now <= endTimestamp);
    require(msg.value >= minContribution);
    require(weiRaised.add(msg.value) <= hardcap);
    _;
  }

   
  function hasEnded() public constant returns (bool) {
    bool timeLimitReached = now > endTimestamp;
    bool capReached = weiRaised >= hardcap;
    return timeLimitReached || capReached;
  }

   
  function buyTokens(address beneficiary) payable validPurchase {
    require(beneficiary != 0x0);

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);
    tokens = tokens + bonusAmmount(tokens);

     
    weiRaised = weiRaised.add(weiAmount);
    numberOfPurchasers = numberOfPurchasers + 1;

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    hardwareWallet.transfer(msg.value);
  }

   
  function finishPresale() public onlyOwner {
    require(hasEnded());
    token.transferOwnership(owner);
    PreSaleClosed();
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

}