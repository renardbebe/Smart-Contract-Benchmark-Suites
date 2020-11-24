 

pragma solidity ^0.4.13;

pragma solidity ^0.4.13;

  
  
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

pragma solidity ^0.4.13;

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

pragma solidity ^0.4.13;

pragma solidity ^0.4.13;

 


  
  
contract Killable is Ownable {
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}

pragma solidity ^0.4.13;

pragma solidity ^0.4.13;

 

pragma solidity ^0.4.13;

  
  
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

pragma solidity ^0.4.13;

 


 
 
contract ZiberToken is SafeMath, ERC20, Ownable {
 string public name = "Ziber Token";
 string public symbol = "ZBR";
 uint public decimals = 8;
 uint public constant FROZEN_TOKENS = 1e7;
 uint public constant FREEZE_PERIOD = 1 years;
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

  
 function ZiberToken() {
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
    
    
    
    
   require(_value == 0 && allowed[msg.sender][_spender] == 0);

   allowed[msg.sender][_spender] = _value;
   Approval(msg.sender, _spender, _value);
   return true;
 }

  
  
  
  
 function allowance(address _owner, address _spender) constant returns (uint remaining) {
   return allowed[_owner][_spender];
 }
}


 
 
contract ZiberCrowdsale is Haltable, Killable, SafeMath {

   
  uint public constant TOTAL_ICO_TOKENS = 1e8;

   
  uint public constant MIN_ICO_GOAL = 5e3 ether;

   
  uint public constant MAX_ICO_GOAL = 5e4 ether;

   
  uint public maxGoalReachedAt = 0;

   
  uint public constant ICO_DURATION = 10 days;

   
  uint public constant AFTER_MAX_GOAL_DURATION = 24 hours;

   
  ZiberToken public token;

   
  uint public startsAt;

   
  uint public weiRaised = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  struct Investment {
       
      address source;
       
      uint weiValue;
  }

  Investment[] public investments;

   
   
   
   
   
   
   
   
  enum State {Unknown, Preparing, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount);
   
  event Refund(address investor, uint weiAmount);

   
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

   
   
   
  function Crowdsale(address _token, uint _start) {
    require(_token != 0);
    require(_start != 0);

    owner = msg.sender;
    token = ZiberToken(_token);
    startsAt = _start;
  }

   
  function() payable {
    buy();
  }

    
    
  function investInternal(address receiver) stopInEmergency private {
    var state = getState();
    require(state == State.Funding);
    require(msg.value > 0);

     
    var weiAmount = msg.value;
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
    investments.push(Investment(receiver, weiAmount));

     
    weiRaised = safeAdd(weiRaised, weiAmount);
     
    if(maxGoalReachedAt == 0 && weiRaised >= MAX_ICO_GOAL)
      maxGoalReachedAt = now;
     
    Invested(receiver, weiAmount);
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

   
  function withdraw() public onlyOwner {
     
    owner.transfer(this.balance);
  }

   
  function finalizeCrowdsale() internal {
     
    uint divisor;
    for (uint i = 0; i < investments.length; i++)
       divisor = safeAdd(divisor, investments[i].weiValue);

    var multiplier = 10 ** token.decimals();
     
    uint unitPrice = safeDiv(safeMul(TOTAL_ICO_TOKENS, multiplier), divisor);

     
    for (i = 0; i < investments.length; i++) {
        var tokenAmount = safeMul(unitPrice, investments[i].weiValue);
        tokenAmountOf[investments[i].source] += tokenAmount;
        assignTokens(investments[i].source, tokenAmount);
    }
    assignTokens(owner, 2e7);
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
    return weiRaised >= MAX_ICO_GOAL && now > maxGoalReachedAt + AFTER_MAX_GOAL_DURATION;
  }

   
   
  function getState() public constant returns (State) {
    if (finalized)
      return State.Finalized;
    if (address(token) == 0)
      return State.Preparing;
    if (now >= startsAt && now < startsAt + ICO_DURATION && !isCrowdsaleFull())
      return State.Funding;
    if (isCrowdsaleFull())
      return State.Success;
    if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
      return State.Refunding;
    return State.Failure;
  }

    
    
    
   function assignTokens(address receiver, uint tokenAmount) private {
     token.mint(receiver, tokenAmount);
   }
}