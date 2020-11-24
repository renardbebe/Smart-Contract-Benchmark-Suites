 

pragma solidity ^0.4.11;
 
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
 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  MintableToken private token;
   
  uint256 public preStartTime;
  uint256 public preEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
   
  uint256 private preICOBonus;
  uint256 private firstWeekBonus;
  uint256 private secondWeekBonus;
  uint256 private thirdWeekBonus;
  uint256 private forthWeekBonus;
  
  
   
  address internal wallet;
  
   
  uint256 public rate;
   
  uint256 internal weiRaised;
   
  uint256 weekOne;
  uint256 weekTwo;
  uint256 weekThree;
  uint256 weekForth;
  
   
  uint256 private totalSupply = 300000000 * (10**18);
   
  uint256 private publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),75);
   
  uint256 private rewardsSupply = SafeMath.mul(SafeMath.div(totalSupply,100),15);
   
  uint256 private teamSupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);
   
  uint256 private advisorSupply = SafeMath.mul(SafeMath.div(totalSupply,100),3);
   
  uint256 private bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),2);
   
  uint256 private preicoSupply = SafeMath.mul(SafeMath.div(publicSupply,100),15);
   
  uint256 private icoSupply = SafeMath.mul(SafeMath.div(publicSupply,100),85);
   
  uint256 private remainingPublicSupply = publicSupply;
   
  uint256 private remainingRewardsSupply = rewardsSupply;
   
  uint256 private remainingBountySupply = bountySupply;
   
  uint256 private remainingAdvisorSupply = advisorSupply;
   
  uint256 private remainingTeamSupply = teamSupply;
   
  uint256 private teamTimeLock;
   
  uint256 private advisorTimeLock;
   
  bool private checkBurnTokens;
  bool private upgradeICOSupply;
  bool private grantTeamSupply;
  bool private grantAdvisorSupply;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
     
    token = createTokenContract();
     
    preStartTime = _startTime;
    
     
     preEndTime = 1521637200;
     
     ICOstartTime = 1521982800;
     
    ICOEndTime = _endTime;
     
    rate = _rate;
     
    wallet = _wallet;
     
    preICOBonus = SafeMath.div(SafeMath.mul(rate,30),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    forthWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);
     
    weekOne = SafeMath.add(ICOstartTime, 604800);
    weekTwo = SafeMath.add(weekOne, 604800);
    weekThree = SafeMath.add(weekTwo, 604800);
    weekForth = SafeMath.add(weekThree, 604800);
     
    teamTimeLock = SafeMath.add(ICOEndTime, 31536000);
    advisorTimeLock = SafeMath.add(ICOEndTime, 5356800);
    
    checkBurnTokens = false;
    upgradeICOSupply = false;
    grantAdvisorSupply = false;
    grantTeamSupply = false;
  }
   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
   
  function () payable {
    buyTokens(msg.sender);
    
  }
   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
     
    require(weiAmount >= (0.05 * 1 ether));
    
    uint256 accessTime = now;
    uint256 tokens = 0;
   
    if ((accessTime >= preStartTime) && (accessTime < preEndTime)) {
        require(preicoSupply > 0);
        tokens = SafeMath.add(tokens, weiAmount.mul(preICOBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        
        require(preicoSupply >= tokens);
        
        preicoSupply = preicoSupply.sub(tokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) {
        if (!upgradeICOSupply) {
          icoSupply = SafeMath.add(icoSupply,preicoSupply);
          upgradeICOSupply = true;
        }
        if ( accessTime <= weekOne ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
        } else if (accessTime <= weekTwo) {
          tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
        } else if ( accessTime < weekThree ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
        } else if ( accessTime < weekForth ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(forthWeekBonus));
        }
        
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        icoSupply = icoSupply.sub(tokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    } else if ((accessTime > preEndTime) && (accessTime < ICOstartTime)){
      revert();
    }
     
    weiRaised = weiRaised.add(weiAmount);
     
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
     
    forwardFunds();
  }
   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= preStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
   
  function hasEnded() public constant returns (bool) {
      return now > ICOEndTime;
  }
   
  function burnToken() onlyOwner public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    token.burnTokens(remainingPublicSupply);
    totalSupply = SafeMath.sub(totalSupply, remainingPublicSupply);
    remainingPublicSupply = 0;
    checkBurnTokens = true;
    return true;
  }
   
  function bountyFunds(address beneficiary, uint256 valueToken) onlyOwner public { 
    valueToken = SafeMath.mul(valueToken, 1 ether);
    require(remainingBountySupply >= valueToken);
    remainingBountySupply = SafeMath.sub(remainingBountySupply,valueToken);
    token.mint(beneficiary, valueToken);
  }
   
  function rewardsFunds(address beneficiary, uint256 valueToken) onlyOwner public { 
    valueToken = SafeMath.mul(valueToken, 1 ether);
    require(remainingRewardsSupply >= valueToken);
    remainingRewardsSupply = SafeMath.sub(remainingRewardsSupply,valueToken);
    token.mint(beneficiary, valueToken);
  } 
   
  function grantAdvisorToken() onlyOwner public {
    require(!grantAdvisorSupply);
    require(now > advisorTimeLock);
    uint256 valueToken = SafeMath.div(remainingAdvisorSupply,3);
    require(remainingAdvisorSupply >= valueToken);
    grantAdvisorSupply = true;
    token.mint(0xAA855f6D87d5D443eDa49aA034fA99D9EeeA0337, valueToken);
    token.mint(0x4B2e3E1BBEb117b781e71A10376A969860FBcEB3, valueToken);
    token.mint(0xbb3b3799D1b31189b491C26B1D7c17307fb87F5d, valueToken);
    remainingAdvisorSupply = 0;
  }
   
    function grantTeamToken() onlyOwner public {
    require(!grantTeamSupply);
    require(now > teamTimeLock);
    uint256 valueToken = SafeMath.div(remainingTeamSupply, 5);
    require(remainingTeamSupply >= valueToken);
    grantTeamSupply = true;
    token.mint(0xBEB9e4057f953AaBdF14Dc4018056888C67E40b0, valueToken);
    token.mint(0x70fcd07629eB9b406223168AEB8De06E2564F558, valueToken);
    token.mint(0x0e562f12239C660627bE186de6535c05983579E9, valueToken);
    token.mint(0x42e045f4D119212AC1CF5820488E69AA9164DC70, valueToken);
    token.mint(0x2f53678a33C0fEE8f30fc5cfaC4E5E140397b40D, valueToken);
    remainingTeamSupply = 0;
    
  }
 
  function transferToken(address beneficiary, uint256 tokens) onlyOwner public {
    require(ICOEndTime > now);
    tokens = SafeMath.mul(tokens,1 ether);
    require(remainingPublicSupply >= tokens);
    remainingPublicSupply = SafeMath.sub(remainingPublicSupply,tokens);
    token.mint(beneficiary, tokens);
  }
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }
  function getPublicSupply() onlyOwner public returns (uint256) {
    return remainingPublicSupply;
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
 
contract BenebitToken is MintableToken {
  string public constant name = "BenebitToken";
  string public constant symbol = "BNE";
  uint256 public constant decimals = 18;
  uint256 public constant _totalSupply = 300000000 * 1 ether;
  
 
  function BenebitToken() {
    totalSupply = _totalSupply;
  }
}
contract BenebitICO is Crowdsale, CappedCrowdsale, RefundableCrowdsale {
    uint256 _startTime = 1516626000;
    uint256 _endTime = 1525093200; 
    uint256 _rate = 3000;
    uint256 _goal = 5000 * 1 ether;
    uint256 _cap = 40000 * 1 ether;
    address _wallet  = 0x88BfBd2B464C15b245A9f7a563D207bd8A161054;   
     
    function BenebitICO() 
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime,_endTime,_rate,_wallet) 
    {
        
    }
     
    function createTokenContract() internal returns (MintableToken) {
        return new BenebitToken();
    }
}