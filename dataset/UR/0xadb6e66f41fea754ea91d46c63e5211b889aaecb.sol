 

pragma solidity ^0.4.13;

  
  
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

 
 
 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);       
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }
}



  
  
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);
  function mint(address receiver, uint amount);
  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

  
  
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    require(assertion);  
  }
}


 
 
contract SolarDaoToken is SafeMath, ERC20, Ownable {
 string public name = "Solar DAO Token";
 string public symbol = "SDAO";
 uint public decimals = 4;

  
 address public crowdsaleAgent;
  
 bool public released = false;
  
 mapping (address => mapping (address => uint)) allowed;
  
 mapping(address => uint) balances;

  
 modifier canTransfer() {
   if(!released) {
       require(msg.sender == crowdsaleAgent);
   }
   _;
 }

  
  
 modifier inReleaseState(bool _released) {
   require(_released == released);
   _;
 }

  
 modifier onlyCrowdsaleAgent() {
   require(msg.sender == crowdsaleAgent);
   _;
 }

  
  
 modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    _;
 }

  
 modifier canMint() {
    require(!released);
    _;
  }

  
 function SolarDaoToken() {
   owner = msg.sender;
 }

  
 function() payable {
   revert();
 }

  
  
  
 function mint(address receiver, uint amount) onlyCrowdsaleAgent canMint public {
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);
    Transfer(0, receiver, amount);
 }

  
  
 function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner inReleaseState(false) public {
   crowdsaleAgent = _crowdsaleAgent;
 }
  
 function releaseTokenTransfer() public onlyCrowdsaleAgent {
   released = true;
 }
  
  
  
  
 function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
   balances[msg.sender] = safeSub(balances[msg.sender], _value);
   balances[_to] = safeAdd(balances[_to], _value);

   Transfer(msg.sender, _to, _value);
   return true;
 }

  
  
  
  
  
 function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
   var _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
 }
  
  
  
 function balanceOf(address _owner) constant returns (uint balance) {
   return balances[_owner];
 }

  
  
  
  
 function approve(address _spender, uint _value) returns (bool success) {
    
    
    
    
   require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

   allowed[msg.sender][_spender] = _value;
   Approval(msg.sender, _spender, _value);
   return true;
 }

  
  
  
  
 function allowance(address _owner, address _spender) constant returns (uint remaining) {
   return allowed[_owner][_spender];
 }
}


 
 
contract SolarDaoTokenCrowdsale is Haltable, SafeMath {

   
  uint public constant PRE_FUNDING_GOAL = 4e6 * PRICE;

   
  uint public constant ICO_GOAL = 8e7 * PRICE;

   
  uint public constant MIN_ICO_GOAL = 1e7;

   
  uint public constant TEAM_BONUS_PERCENT = 25;

   
  uint constant public PRICE = 100;

   
  uint constant public PRE_ICO_DURATION = 5 weeks;

   
  SolarDaoToken public token;

   
  address public multisigWallet;

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public preInvestStart;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public investorCount = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized;

   
  uint public exchangeRate;

   
  uint public exchangeRateTimestamp;

   
  address public exchangeRateAgent;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  struct Milestone {
       
      uint start;
       
      uint end;
       
      uint bonus;
  }

  Milestone[] public milestones;

   
   
   
   
   
   
   
   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount);
   
  event Refund(address investor, uint weiAmount);
   
  event EndsAtChanged(uint endsAt);
   
  event ExchangeRateChanged(uint oldValue, uint newValue);

   
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

  modifier onlyExchangeRateAgent() {
    require(msg.sender == exchangeRateAgent);
    _;
  }

   
   
   
   
   
   
  function Crowdsale(address _token, address _multisigWallet, uint _preInvestStart, uint _start, uint _end) {
    require(_multisigWallet != 0);
    require(_preInvestStart != 0);
    require(_start != 0);
    require(_end != 0);
    require(_start < _end);
    require(_end > _preInvestStart + PRE_ICO_DURATION);

    owner = msg.sender;
    token = SolarDaoToken(_token);

    multisigWallet = _multisigWallet;
    startsAt = _start;
    endsAt = _end;
    preInvestStart = _preInvestStart;

    var preIcoBonuses = [uint(100), 80, 70, 60, 50];
    for (uint i = 0; i < preIcoBonuses.length; i++) {
      milestones.push(Milestone(preInvestStart + i * 1 weeks, preInvestStart + (i + 1) * 1 weeks, preIcoBonuses[i]));
    }
    milestones.push(Milestone(startsAt, startsAt + 4 days, 25));
    milestones.push(Milestone(startsAt + 4 days, startsAt + 1 weeks, 20));
    delete preIcoBonuses;

    var icoBonuses = [uint(15), 10, 5];
    for (i = 1; i <= icoBonuses.length; i++) {
      milestones.push(Milestone(startsAt + i * 1 weeks, startsAt + (i + 1) * 1 weeks, icoBonuses[i - 1]));
    }
    delete icoBonuses;
  }

  function() payable {
    buy();
  }

   
   
  function getCurrentMilestone() private constant returns (Milestone) {
      for (uint i = 0; i < milestones.length; i++) {
        if (milestones[i].start <= now && milestones[i].end > now) {
          return milestones[i];
        }
      }
  }

    
    
  function investInternal(address receiver) stopInEmergency private {
    var state = getState();
    require(state == State.Funding || state == State.PreFunding);

    uint weiAmount = msg.value;
    uint tokensAmount = calculateTokens(weiAmount);
    assert (tokensAmount > 0);

    if(state == State.PreFunding) {
        tokensAmount += safeDiv(safeMul(tokensAmount, getCurrentMilestone().bonus), 100);
    }

    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokensAmount);
     
    weiRaised = safeAdd(weiRaised, weiAmount);
    tokensSold = safeAdd(tokensSold, tokensAmount);

     
     

    assignTokens(receiver, tokensAmount);
    var teamBonusTokens = safeDiv(safeMul(tokensAmount, TEAM_BONUS_PERCENT), 100 - TEAM_BONUS_PERCENT);
    assignTokens(multisigWallet, teamBonusTokens);

    multisigWallet.transfer(weiAmount);
     
    Invested(receiver, weiAmount, tokensAmount);
  }

   
   
  function invest(address receiver) public payable {
    investInternal(receiver);
  }

   
  function buy() public payable {
    invest(msg.sender);
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    require(!finalized);

    finalized = true;
    finalizeCrowdsale();
  }

   
  function finalizeCrowdsale() internal {
     
    token.releaseTokenTransfer();
  }

    
    
    
  function setExchangeRate(uint value, uint time) onlyExchangeRateAgent {
    require(value > 0);
    require(time > 0);
    require(exchangeRateTimestamp == 0 || getDifference(int(time), int(now)) <= 1 minutes);
    require(exchangeRate == 0 || (getDifference(int(value), int(exchangeRate)) * 100 / exchangeRate <= 30));

    ExchangeRateChanged(exchangeRate, value);
    exchangeRate = value;
    exchangeRateTimestamp = time;
  }

   
   
 function setExchangeRateAgent(address newAgent) onlyOwner {
   if (newAgent != address(0)) {
     exchangeRateAgent = newAgent;
   }
 }

  function getDifference(int one, int two) private constant returns (uint) {
    var diff = one - two;
    if (diff < 0)
      diff = -diff;
    return uint(diff);
  }

   
   
  function setEndsAt(uint time) onlyOwner {
    require(time >= now);
    endsAt = time;
    EndsAtChanged(endsAt);
  }

   
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value > 0);
    loadedRefund = safeAdd(loadedRefund, msg.value);
  }

   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0)
      return;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = safeAdd(weiRefunded, weiValue);
    Refund(msg.sender, weiValue);
    msg.sender.transfer(weiValue);
  }

   
   
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiToUsdCents(weiRaised) >= MIN_ICO_GOAL;
  }

   
   
  function isCrowdsaleFull() public constant returns (bool) {
    return weiToUsdCents(weiRaised) >= ICO_GOAL;
  }

   
   
  function getState() public constant returns (State) {
    if (finalized)
      return State.Finalized;
    if (address(token) == 0 || address(multisigWallet) == 0 || now < preInvestStart)
      return State.Preparing;
    if (preInvestStart <= now && now < startsAt && !isMaximumPreFundingGoalReached())
      return State.PreFunding;
    if (now <= endsAt && !isCrowdsaleFull())
      return State.Funding;
    if (isMinimumGoalReached())
      return State.Success;
    if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
      return State.Refunding;
    return State.Failure;
  }

   
   
   
  function calculateTokens(uint weiAmount) internal returns (uint tokenAmount) {
    var multiplier = 10 ** token.decimals();

    uint usdAmount = weiToUsdCents(weiAmount);
    assert (usdAmount >= PRICE);

    return safeMul(usdAmount, safeDiv(multiplier, PRICE));
  }

    
    
    
    
    
    
   function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
     return false;
   }

    
    
   function isMaximumPreFundingGoalReached() public constant returns (bool reached) {
     return weiToUsdCents(weiRaised) >= PRE_FUNDING_GOAL;
   }

    
    
    
   function weiToUsdCents(uint weiValue) private returns (uint) {
     return safeDiv(safeMul(weiValue, exchangeRate), 1e18);
   }

    
    
    
   function assignTokens(address receiver, uint tokenAmount) private {
     token.mint(receiver, tokenAmount);
   }
}