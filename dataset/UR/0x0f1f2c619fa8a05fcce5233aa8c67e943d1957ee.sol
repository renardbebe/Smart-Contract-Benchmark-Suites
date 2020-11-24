 

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
  uint256 public preIcoStartTime;
  uint256 public preIcoEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
   
  uint256 private preSaleBonus;
  uint256 private preICOBonus;
  uint256 private firstWeekBonus;
  uint256 private secondWeekBonus;
  uint256 private thirdWeekBonus;
  
  
   
  address internal wallet;
  
   
  uint256 public rate;
   
  uint256 internal weiRaised;
   
   
   
   
  
  uint256 weekOneStart;
  uint256 weekOneEnd;
  uint256 weekTwoStart;
  uint256 weekTwoEnd;
  uint256 weekThreeStart;
  uint256 weekThreeEnd;
  uint256 lastWeekStart;
  uint256 lastWeekEnd;
   
  uint256 public totalSupply = 32300000 * 1 ether;
   
  uint256 public publicSupply = 28300000 * 1 ether;
   
  uint256 public reserveSupply = 3000000 * 1 ether;
   
  uint256 public bountySupply = 1000000 * 1 ether;
   
  uint256 public preSaleSupply = 8000000 * 1 ether;
   
  uint256 public preicoSupply = 8000000 * 1 ether;
   
  uint256 public icoSupply = 12300000 * 1 ether;
   
  uint256 public remainingPublicSupply = publicSupply;
   
  uint256 public remainingBountySupply = bountySupply;
   
  uint256 public remainingReserveSupply = reserveSupply;
   
  bool public paused = false;
  bool private checkBurnTokens;
  bool private upgradePreICOSupply;
  bool private upgradeICOSupply;
  bool private grantReserveSupply;
  bool private grantBountySupply;
  
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
     
    token = createTokenContract();
     
    preStartTime = _startTime;  
    
     
     preEndTime = 1522367999;
     
    preIcoStartTime = 1522396800; 
     
    preIcoEndTime = 1523231999; 
     
     ICOstartTime = 1523260800; 
     
    ICOEndTime = _endTime;
     
    rate = _rate;
     
    wallet = _wallet;
     
    preSaleBonus = SafeMath.div(SafeMath.mul(rate,30),100); 
    preICOBonus = SafeMath.div(SafeMath.mul(rate,25),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);
     
    weekOneStart = 1523260800; 
    weekOneEnd = 1524095999; 
    weekTwoStart = 1524124800;
    weekTwoEnd = 1524916799;
    weekThreeStart = 1524988800; 
    weekThreeEnd = 1525823999;
    lastWeekStart = 1525852800; 
    lastWeekEnd = 1526687999;
    checkBurnTokens = false;
    grantReserveSupply = false;
    grantBountySupply = false;
    upgradePreICOSupply = false;
    upgradeICOSupply = false;
  }
   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
   
  function () payable {
    buyTokens(msg.sender);  
  }
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
  }
   
  function unpause() onlyOwner whenPaused public {
    paused = false;
  }
   
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
     
    require(weiAmount >= 0.05 * 1 ether);
    
    uint256 accessTime = now;
    uint256 tokens = 0;
    uint256 supplyTokens = 0;
    uint256 bonusTokens = 0;
   
    if ((accessTime >= preStartTime) && (accessTime < preEndTime)) {
        require(preSaleSupply > 0);
        
        bonusTokens = SafeMath.add(bonusTokens, weiAmount.mul(preSaleBonus));
        supplyTokens = SafeMath.add(supplyTokens, weiAmount.mul(rate));
        tokens = SafeMath.add(bonusTokens, supplyTokens);
        
        require(preSaleSupply >= supplyTokens);
        require(icoSupply >= bonusTokens);
        preSaleSupply = preSaleSupply.sub(supplyTokens);
        icoSupply = icoSupply.sub(bonusTokens);
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    }else if ((accessTime >= preIcoStartTime) && (accessTime < preIcoEndTime)) {
        if (!upgradePreICOSupply) {
          preicoSupply = preicoSupply.add(preSaleSupply);
          upgradePreICOSupply = true;
        }
        require(preicoSupply > 0);
        bonusTokens = SafeMath.add(bonusTokens, weiAmount.mul(preICOBonus));
        supplyTokens = SafeMath.add(supplyTokens, weiAmount.mul(rate));
        tokens = SafeMath.add(bonusTokens, supplyTokens);
        
        require(preicoSupply >= supplyTokens);
        require(icoSupply >= bonusTokens);
        preicoSupply = preicoSupply.sub(supplyTokens);
        icoSupply = icoSupply.sub(bonusTokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) {
        if (!upgradeICOSupply) {
          icoSupply = SafeMath.add(icoSupply,preicoSupply);
          upgradeICOSupply = true;
        }
        require(icoSupply > 0);
        if ( accessTime <= weekOneEnd ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
        } else if (accessTime <= weekTwoEnd) {
            if(accessTime >= weekTwoStart) {
              tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
            }else {
              revert();
            }
        } else if ( accessTime <= weekThreeEnd ) {
            if(accessTime >= weekThreeStart) {
              tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
            }else {
              revert();
            }
        } else if ( accessTime <= lastWeekEnd ) {
            if(accessTime >= lastWeekStart) {
              tokens = 0;
            }else {
              revert();
            }
        }
        
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        icoSupply = icoSupply.sub(tokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    } else {
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
   
  function burnToken() onlyOwner whenNotPaused public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    checkBurnTokens = true;
    token.burnTokens(remainingPublicSupply);
    totalSupply = SafeMath.sub(totalSupply, remainingPublicSupply);
    remainingPublicSupply = 0;
    preSaleSupply = 0;
    preicoSupply = 0;
    icoSupply = 0;
    return true;
  }
   
  function bountyFunds() onlyOwner whenNotPaused public { 
    require(!grantBountySupply);
    grantBountySupply = true;
    token.mint(0x4311E7B5a249B8D2CC7CcD98Dc7bE45d8ce94e39, remainingBountySupply);
    
    remainingBountySupply = 0;
  }  
   
    function grantReserveToken() onlyOwner whenNotPaused public {
    require(!grantReserveSupply);
    grantReserveSupply = true;
    token.mint(0x4C355A270bC49A18791905c1016603906461977a, remainingReserveSupply);
    
    remainingReserveSupply = 0;
    
  }
 
  function transferToken(address beneficiary, uint256 tokens) onlyOwner whenNotPaused public {
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
 
contract GoldiamToken is MintableToken {
  string public constant name = "Goldiam";
  string public constant symbol = "GOL";
  uint256 public constant decimals = 18;
  uint256 public constant _totalSupply = 32300000 * 1 ether;
  
 
  function GoldiamToken() {
    totalSupply = _totalSupply;
  }
}
contract GoldiamICO is Crowdsale, CappedCrowdsale, RefundableCrowdsale {
    uint256 _startTime = 1521532800;
    uint256 _endTime = 1526687999; 
    uint256 _rate = 1300;
    uint256 _goal = 2000 * 1 ether;
    uint256 _cap = 17000 * 1 ether;
    address _wallet  = 0x2fdDc70C97b11496d3183F014166BC0849C119d6;   
     
    function GoldiamICO() 
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime,_endTime,_rate,_wallet) {
        
    }
     
    function createTokenContract() internal returns (MintableToken) {
        return new GoldiamToken();
    }
}