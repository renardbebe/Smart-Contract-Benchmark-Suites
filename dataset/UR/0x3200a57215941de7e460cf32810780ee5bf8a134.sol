 

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



 
contract PayFairToken is SafeMath, ERC20, Ownable {
 string public name = "PayFair Token";
 string public symbol = "PFR";
 uint public constant decimals = 8;
 uint public constant FROZEN_TOKENS = 11e6;
 uint public constant FREEZE_PERIOD = 1 years;
 uint public constant MULTIPLIER = 10 ** decimals;
 uint public crowdSaleOverTimestamp;

  
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

 modifier checkFrozenAmount(address source, uint amount) {
   if (source == owner && now < crowdSaleOverTimestamp + FREEZE_PERIOD) {
     var frozenTokens = 10 ** decimals * FROZEN_TOKENS;
     require(safeSub(balances[owner], amount) > frozenTokens);
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

  
 function PayFairToken() {
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
   crowdSaleOverTimestamp = now;
   released = true;
 }

  
  
 function convertToDecimal(uint amount) public constant returns (uint) {
   return safeMul(amount, MULTIPLIER);
 }

  
  
  
  
 function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer checkFrozenAmount(msg.sender, _value) returns (bool success) {
   balances[msg.sender] = safeSub(balances[msg.sender], _value);
   balances[_to] = safeAdd(balances[_to], _value);

   Transfer(msg.sender, _to, _value);
   return true;
 }

  
  
  
  
  
 function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer checkFrozenAmount(_from, _value) returns (bool success) {
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

  
contract Killable is Ownable {
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}

 
contract PayFairTokenCrowdsale is Haltable, Killable, SafeMath {

   
  uint public constant TOTAL_ICO_TOKENS = 56e6;

   
  uint public constant PRE_ICO_MAX_TOKENS = 33e6;

   
  uint public constant MIN_ICO_GOAL = 1 ether;

   
  uint public constant ICO_DURATION = 30 days;

   
  PayFairToken public token;

   
  address public multisigWallet;

   
  uint public startsAt;

   
  uint public weiRaised = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  uint public preIcoTokensDistributed = 0;

   
  bool public finalized;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  struct Milestone {
       
      uint start;
       
      uint end;
       
      uint bonus;
  }

   
  struct Investment {
       
      address source;

       
      uint weight;

       
      uint weiValue;
  }

  Milestone[] public milestones;
  Investment[] public investments;

   
   
   
   
   
   
   
   
  enum State {Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount);
   
  event Refund(address investor, uint weiAmount);

   
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

   
   
   
   
  function PayFairTokenCrowdsale(address _token, address _multisigWallet, uint _start) {
    require(_multisigWallet != 0);
    require(_start != 0);

    token = PayFairToken(_token);

    multisigWallet = _multisigWallet;
    startsAt = _start;

    milestones.push(Milestone(startsAt, startsAt + 1 days, 20));
    milestones.push(Milestone(startsAt + 1 days, startsAt + 5 days, 15));
    milestones.push(Milestone(startsAt + 5 days, startsAt + 10 days, 10));
    milestones.push(Milestone(startsAt + 10 days, startsAt + 20 days, 5));
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
    require(state == State.Funding);
    require(msg.value > 0);

     
    var weiAmount = msg.value;
    investments.push(Investment(receiver, weiAmount, getCurrentMilestone().bonus + 100));
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);

     
    weiRaised = safeAdd(weiRaised, weiAmount);
     
    multisigWallet.transfer(weiAmount);
     
    Invested(receiver, weiAmount);
  }

   
   
  function invest(address receiver) public payable {
    investInternal(receiver);
  }

  function sendPreIcoTokens(address receiver, uint amount) public inState(State.PreFunding) onlyOwner {
    require(receiver != 0);
    require(amount > 0);
    require(safeAdd(preIcoTokensDistributed, amount) <= token.convertToDecimal(PRE_ICO_MAX_TOKENS));

    preIcoTokensDistributed = safeAdd(preIcoTokensDistributed, amount);
    assignTokens(receiver, amount);
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
     
    uint divisor;
    for (uint i = 0; i < investments.length; i++)
       divisor = safeAdd(divisor, safeMul(investments[i].weiValue, investments[i].weight));

    uint localMultiplier = 10 ** 12;
     
    uint unitPrice = safeDiv(safeMul(token.convertToDecimal(TOTAL_ICO_TOKENS), localMultiplier), divisor);

     
    for (i = 0; i < investments.length; i++) {
        var tokenAmount = safeDiv(safeMul(unitPrice, safeMul(investments[i].weiValue, investments[i].weight)), localMultiplier);
        tokenAmountOf[investments[i].source] += tokenAmount;
        assignTokens(investments[i].source, tokenAmount);
    }

    token.releaseTokenTransfer();
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
    return weiRaised >= MIN_ICO_GOAL;
  }

   
   
  function isCrowdsaleFull() public constant returns (bool) {
    return isMinimumGoalReached() && now > startsAt + ICO_DURATION;
  }

   
   
  function getState() public constant returns (State) {
    if (finalized)
      return State.Finalized;
    if (address(token) == 0 || address(multisigWallet) == 0)
      return State.Preparing;
    if (preIcoTokensDistributed < token.convertToDecimal(PRE_ICO_MAX_TOKENS))
        return State.PreFunding;
    if (now >= startsAt && now < startsAt + ICO_DURATION && !isCrowdsaleFull())
      return State.Funding;
    if (isMinimumGoalReached())
      return State.Success;
    if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
      return State.Refunding;
    return State.Failure;
  }

  
    
    
    
   function assignTokens(address receiver, uint tokenAmount) private {
     token.mint(receiver, tokenAmount);
   }
}