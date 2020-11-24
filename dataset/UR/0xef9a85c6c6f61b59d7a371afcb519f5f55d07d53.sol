 

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
   
  function Ownable() public {
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
    uint256 _allowance = allowed[_from][msg.sender];
     
     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function burnTokens(uint256 _unsoldTokens) onlyOwner public returns (bool) {
    totalSupply = SafeMath.sub(totalSupply, _unsoldTokens);
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
  address internal wallet;
  uint256 public rate;
  uint256 internal weiRaised;
   
  uint256 public preSaleStartTime;
  uint256 public preSaleEndTime;
  uint256 public preICOStartTime;
  uint256 public preICOEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
   
  uint internal preSaleBonus;
  uint internal preICOBonus;
  uint internal firstWeekBonus;
  uint internal secondWeekBonus;
  uint internal thirdWeekBonus;
  
   
  uint256 internal weekOne;
  uint256 internal weekTwo;
  uint256 internal weekThree;
   
  uint256 public totalSupply = SafeMath.mul(700000000, 1 ether);
  uint256 internal publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),50);
  uint256 internal reserveSupply = SafeMath.mul(SafeMath.div(totalSupply,100),14);
  uint256 internal teamSupply = SafeMath.div(SafeMath.mul(SafeMath.div(totalSupply,100),13),4);
  uint256 internal advisorSupply = SafeMath.div(SafeMath.mul(SafeMath.div(totalSupply,100),3),4);
  uint256 internal bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);
  uint256 internal founderSupply = SafeMath.div(SafeMath.mul(SafeMath.div(totalSupply,100),15),4);
  uint256 internal preSaleSupply = SafeMath.mul(SafeMath.div(totalSupply,100),2);
  uint256 internal preICOSupply = SafeMath.mul(SafeMath.div(totalSupply,100),13);
  uint256 internal icoSupply = SafeMath.mul(SafeMath.div(totalSupply,100),35);
   
  uint256 internal advisorTimeLock;
  uint256 internal founderTeamTimeLock;
   
  bool internal checkUnsoldTokens;
  bool internal upgradePreICOSupply;
  bool internal upgradeICOSupply;
  bool internal grantAdvisorSupply;
  bool internal grantFounderTeamSupply;
   
  uint vestedFounderTeamCheck;
  uint vestedAdvisorCheck;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) internal {
    
    require(_wallet != 0x0);
    token = createTokenContract();
    preSaleStartTime = _startTime;
    preSaleEndTime = 1525352400;
    preICOStartTime = preSaleEndTime;
    preICOEndTime = 1528030800;
    ICOstartTime = preICOEndTime;
    ICOEndTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    preSaleBonus = SafeMath.div(SafeMath.mul(rate,40),100);
    preICOBonus = SafeMath.div(SafeMath.mul(rate,30),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
 
    weekOne = SafeMath.add(ICOstartTime, 7 days);
    weekTwo = SafeMath.add(weekOne, 7 days);
    weekThree = SafeMath.add(weekTwo, 7 days);
    advisorTimeLock = SafeMath.add(ICOEndTime, 180 days);
    founderTeamTimeLock = SafeMath.add(ICOEndTime, 180 days);
    checkUnsoldTokens = false;
    upgradeICOSupply = false;
    upgradePreICOSupply = false;
    grantAdvisorSupply = false;
    grantFounderTeamSupply = false;
    vestedFounderTeamCheck = 0;
    vestedAdvisorCheck = 0;
    
  }
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
   
  function () payable {
    buyTokens(msg.sender);
  }
   
  function preSaleTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        
    require(preSaleSupply > 0);
    tokens = SafeMath.add(tokens, weiAmount.mul(preSaleBonus));
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    require(preSaleSupply >= tokens);
    preSaleSupply = preSaleSupply.sub(tokens);        
    return tokens;
  }
   
  function preICOTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        
    require(preICOSupply > 0);
    if (!upgradePreICOSupply) {
      preICOSupply = SafeMath.add(preICOSupply,preSaleSupply);
      upgradePreICOSupply = true;
    }
    tokens = SafeMath.add(tokens, weiAmount.mul(preICOBonus));
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    
    require(preICOSupply >= tokens);
    
    preICOSupply = preICOSupply.sub(tokens);        
    return tokens;
  }
   
  
  function icoTokens(uint256 weiAmount, uint256 tokens, uint256 accessTime) internal returns (uint256) {
        
    require(icoSupply > 0);
    if (!upgradeICOSupply) {
      icoSupply = SafeMath.add(icoSupply,preICOSupply);
      upgradeICOSupply = true;
    }
    
    if (accessTime <= weekOne) {
      tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
    } else if (accessTime <= weekTwo) {
      tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
    } else if ( accessTime < weekThree ) {
      tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
    }
    
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    icoSupply = icoSupply.sub(tokens);        
    return tokens;
  }
   
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 accessTime = now;
    uint256 tokens = 0;
    uint256 weiAmount = msg.value;
    require((weiAmount >= (100000000000000000)) && (weiAmount <= (25000000000000000000)));
    if ((accessTime >= preSaleStartTime) && (accessTime < preSaleEndTime)) {
      tokens = preSaleTokens(weiAmount, tokens);
    } else if ((accessTime >= preICOStartTime) && (accessTime < preICOEndTime)) {
      tokens = preICOTokens(weiAmount, tokens);
    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) { 
      tokens = icoTokens(weiAmount, tokens, accessTime);
    } else {
      revert();
    }
    
    publicSupply = publicSupply.sub(tokens);
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= preSaleStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
   
  
  function hasEnded() public constant returns (bool) {
    return now > ICOEndTime;
  }
   
  function unsoldToken() onlyOwner public {
    require(hasEnded());
    require(!checkUnsoldTokens);
    
    checkUnsoldTokens = true;
    reserveSupply = SafeMath.add(reserveSupply, publicSupply);
    publicSupply = 0;
  }
   
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }
   
  function getPublicSupply() onlyOwner public returns (uint256) {
    return publicSupply;
  }
}
 
 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
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
 
contract FinalizableCrowdsale is Crowdsale {
  using SafeMath for uint256;
  bool isFinalized = false;
  event Finalized();
   
  function finalize() onlyOwner public {
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
   
  uint256 public goal;
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
 
 
contract ArtToujourToken is MintableToken {
   
  string public constant name = "ARISTON";
  string public constant symbol = "ARTZ";
  uint8 public constant decimals = 18;
  uint256 public constant _totalSupply = 700000000 * 1 ether;
  
 
  function ArtToujourToken() {
    totalSupply = _totalSupply;
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
contract CrowdsaleFunctions is Crowdsale {
  
  function bountyFunds(address[] beneficiary, uint256[] tokens) onlyOwner public {
    for (uint256 i = 0; i < beneficiary.length; i++) {
      tokens[i] = SafeMath.mul(tokens[i],1 ether); 
      require(bountySupply >= tokens[i]);
      bountySupply = SafeMath.sub(bountySupply,tokens[i]);
      token.mint(beneficiary[i], tokens[i]);
    }
  }
   
  function reserveFunds() onlyOwner public { 
    require(reserveSupply > 0);
    token.mint(0x3501C88dCEAC658014d6C4406E0D39e11a7e0340, reserveSupply);
    reserveSupply = 0;
  }
   
  function grantAdvisorToken() onlyOwner public {
    require(!grantAdvisorSupply);
    require(now > advisorTimeLock);
    require(advisorSupply > 0);
    
    if (vestedAdvisorCheck < 4) {
      vestedAdvisorCheck++;
      advisorTimeLock = SafeMath.add(advisorTimeLock, 90 days);
      token.mint(0x819acdf6731B51Dd7E68D5DfB6f602BBD8E62871, advisorSupply);
  
      if (vestedAdvisorCheck == 4) {
        advisorSupply = 0;
      }
    }
  }
   
  function grantFounderTeamToken() onlyOwner public {
    require(!grantFounderTeamSupply);
    require(now > founderTeamTimeLock);
    require(founderSupply > 0);
    
    if (vestedFounderTeamCheck < 4) {
       vestedFounderTeamCheck++;
       founderTeamTimeLock = SafeMath.add(founderTeamTimeLock, 180 days);
       token.mint(0x996f2959cE684B2cA221b9f0Da41899662220953, founderSupply);
       token.mint(0x3c61fD8BDFf22C3Aa309f52793288CfB8A271325, teamSupply);
       if (vestedFounderTeamCheck == 4) {
          grantFounderTeamSupply = true;
          founderSupply = 0;
          teamSupply = 0;
       }
    }
  }
 
  function transferToken(address beneficiary, uint256 tokens) onlyOwner public {
    require(publicSupply > 0);
    tokens = SafeMath.mul(tokens,1 ether);
    require(publicSupply >= tokens);
    publicSupply = SafeMath.sub(publicSupply,tokens);
    token.mint(beneficiary, tokens);
  }
}
contract ArtToujourICO is Crowdsale, CappedCrowdsale, RefundableCrowdsale, CrowdsaleFunctions {
  
     
    function ArtToujourICO(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _goal, uint256 _cap, address _wallet) 
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)   
    Crowdsale(_startTime,_endTime,_rate,_wallet) 
    {
        require(_goal < _cap);
    }
    
     
    function createTokenContract() internal returns (MintableToken) {
        return new ArtToujourToken();
    }
}