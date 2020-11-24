 

pragma solidity 0.4.17;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address internal owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
















 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}







 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


    
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

   

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(msg.sender, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;

   
  MintableToken internal token;

   
  uint256 private privateStartTime;
  uint256 private privateEndTime;
  uint256 private publicStartTime;
  uint256 private publicEndTime;
  
   
  uint256 private privateICOBonus;
   
  address internal wallet;
   
  uint256 public rate;
   
  uint256 internal weiRaised;  
   
  uint256 private totalSupply = SafeMath.mul(200000000, 1 ether);
   
  uint256 private privateSupply = SafeMath.mul(40000000, 1 ether);
   
  uint256 private publicSupply = SafeMath.mul(70000000, 1 ether);
   
  uint256 private teamAdvisorSupply = SafeMath.mul(SafeMath.div(totalSupply,100),25);
   
  uint256 private reserveSupply = SafeMath.mul(SafeMath.div(totalSupply,100),20);
   
  uint256 public teamTimeLock;
   
  uint256 public reserveTimeLock;

   
  bool public checkBurnTokens;
  bool public grantTeamAdvisorSupply;
  bool public grantReserveSupply;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  event TokenLeft(uint256 tokensLeft);

   
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

     
    token = createTokenContract();

     
    privateStartTime = _startTime;  
    
     
     privateEndTime = 1525219199;  

     
     publicStartTime = 1530403200;   

     
    publicEndTime = _endTime;   

     
    rate = _rate;

     
    wallet = _wallet;

     
    privateICOBonus = SafeMath.div(SafeMath.mul(rate,50),100);

     
    teamTimeLock = SafeMath.add(publicEndTime, 3 minutes);
    reserveTimeLock = SafeMath.add(publicEndTime, 3 minutes);

    checkBurnTokens = false;
    grantTeamAdvisorSupply = false;
    grantReserveSupply = false;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
   
  function () payable {
    buyTokens(msg.sender);    
  }

   
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
     
    require(weiAmount >= 50000000000000000);  
    
    uint256 accessTime = now;
    uint256 tokens = 0;

   
   require(!((accessTime > privateEndTime) && (accessTime < publicStartTime)));

    if ((accessTime >= privateStartTime) && (accessTime < privateEndTime)) {
        require(privateSupply > 0);

        tokens = SafeMath.add(tokens, weiAmount.mul(privateICOBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        
    } else if ((accessTime >= publicStartTime) && (accessTime <= publicEndTime)) {
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
      } 
     
    weiRaised = weiRaised.add(weiAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
     
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= privateStartTime && now <= publicEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
      return now > publicEndTime;
  }

  function burnToken() onlyOwner  public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    totalSupply = SafeMath.sub(totalSupply, publicSupply);
    totalSupply = SafeMath.sub(totalSupply,privateSupply);
    privateSupply = 0;
    publicSupply = 0;
    checkBurnTokens = true;
    return true;
  }

  function grantReserveToken(address beneficiary) onlyOwner  public {
    require((!grantReserveSupply) && (now > reserveTimeLock));
    grantReserveSupply = true;
    token.mint(beneficiary,reserveSupply);
    reserveSupply = 0;  
  }

  function grantTeamAdvisorToken(address beneficiary) onlyOwner public {
    require((!grantTeamAdvisorSupply) && (now > teamTimeLock));
    grantTeamAdvisorSupply = true;
    token.mint(beneficiary,teamAdvisorSupply);
    teamAdvisorSupply = 0;
    
  }

 function privateSaleTransfer(address[] recipients, uint256[] values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(privateSupply >= values[i]);
        privateSupply = SafeMath.sub(privateSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
    TokenLeft(privateSupply);
  }

 function publicSaleTransfer(address[] recipients, uint256[] values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(publicSupply >= values[i]);
        publicSupply = SafeMath.sub(publicSupply,values[i]);
        token.mint(recipients[i], values[i]);     
    }
    TokenLeft(publicSupply);
  } 



  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }


}









 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 internal cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}


 



contract VantageToken is MintableToken {

  string public constant name = "Vantage Token";
  string public constant symbol = "XVT";
  uint8 public constant decimals = 18;
  uint256 public constant _totalSupply = SafeMath.mul(200000000, 1 ether);

  function VantageToken () {
    totalSupply = _totalSupply;
  }
}













 
contract FinalizableCrowdsale is Crowdsale {
  using SafeMath for uint256;

  bool isFinalized = false;

  event Finalized();

   
  function finalizeCrowdsale() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    
    finalization();
    Finalized();
    
    isFinalized = true;
    }
  

   
  function finalization() internal {
  }
}






 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }
  
  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}




 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 internal goal;
  bool private _goalReached = false;
   
   
  RefundVault private vault;

  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) { 
      vault.close();
    } else {
      vault.enableRefunds();
    }
    super.finalization();
  
  }

  function goalReached() public constant returns (bool) {
    if (weiRaised >= goal) {
      _goalReached = true;
      return true;
    } else if (_goalReached) {
      return true;
    } 
    else {
      return false;
    }
  }

  function updateGoalCheck() onlyOwner public {
    _goalReached = true;
  }

  function getVaultAddress() onlyOwner public returns (address) {
    return vault;
  }
}


contract VantageCrowdsale is Crowdsale, CappedCrowdsale, RefundableCrowdsale {
      
    function VantageCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, address _wallet)
    CappedCrowdsale(_cap)
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_goal <= _cap);  
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new VantageToken();
    }

    
  
}