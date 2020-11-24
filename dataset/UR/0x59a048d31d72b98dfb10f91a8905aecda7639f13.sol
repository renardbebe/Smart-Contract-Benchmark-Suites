 

pragma solidity ^0.4.6;

 
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
    if (!assertion) {
      throw;
    }
  }
}

 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
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
    if (halted) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

 
contract PricingStrategy {

   
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }

   
  function isSane(address crowdsale) public constant returns (bool) {
    return true;
  }

   
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}

 
contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

   
  function isSane() public constant returns (bool);

   
  function finalizeCrowdsale();

}

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract FractionalERC20 is ERC20 {

  uint public decimals;

}


 
contract Crowdsale is Haltable, SafeMath {

   
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

   
  FractionalERC20 public token;

   
  PricingStrategy public pricingStrategy;

   
  FinalizeAgent public finalizeAgent;

   
  address public multisigWallet;

   
  uint public minimumFundingGoal;

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public investorCount = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  mapping (address => bool) public earlyParticipantWhitelist;

   
  uint public ownerTestValue;

   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount);

   
  event Refund(address investor, uint weiAmount);

   
  event Whitelisted(address addr, bool status);

   
  event EndsAtChanged(uint endsAt);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) {

    owner = msg.sender;

    token = FractionalERC20(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if(multisigWallet == 0) {
        throw;
    }

    if(_start == 0) {
        throw;
    }

    startsAt = _start;

    if(_end == 0) {
        throw;
    }

    endsAt = _end;

     
    if(startsAt >= endsAt) {
        throw;
    }

     
    minimumFundingGoal = _minimumFundingGoal;
  }

   
  function() payable {
    investInternal(msg.sender);
  }

   
  function investInternal(address receiver) stopInEmergency private {

     
    if(getState() == State.PreFunding) {
       
      if(!earlyParticipantWhitelist[receiver]) {
        throw;
      }
    } else if(getState() == State.Funding) {
       
       
    } else {
       
      throw;
    }

    uint weiAmount = msg.value;
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());

    if(tokenAmount == 0) {
       
      throw;
    }

    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokenAmount);

     
    weiRaised = safeAdd(weiRaised, weiAmount);
    tokensSold = safeAdd(tokensSold, tokenAmount);

     
    if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      throw;
    }

    assignTokens(receiver, tokenAmount);

     
    if(!multisigWallet.send(weiAmount)) throw;

     
    Invested(receiver, weiAmount, tokenAmount);
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

     
    if(finalized) {
      throw;
    }

     
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

   
  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    finalizeAgent = addr;

     
    if(!finalizeAgent.isFinalizeAgent()) {
      throw;
    }
  }

   
  function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

   
  function setEndsAt(uint time) onlyOwner {

    if(now > time) {
      throw;  
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }

   
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;

     
    if(!pricingStrategy.isPricingStrategy()) {
      throw;
    }
  }

   
  function setMultisig(address addr) public onlyOwner {

     
    if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
      throw;
    }

    multisigWallet = addr;
  }

   
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) throw;
    loadedRefund = safeAdd(loadedRefund, msg.value);
  }

   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) throw;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = safeAdd(weiRefunded, weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) throw;
  }

   
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

   
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

   
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

   
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

   
  function setOwnerTestValue(uint val) onlyOwner {
    ownerTestValue = val;
  }

   
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

   
   
   

   
  modifier inState(State state) {
    if(getState() != state) throw;
    _;
  }


   
   
   

   
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);

   
  function isCrowdsaleFull() public constant returns (bool);

   
  function assignTokens(address receiver, uint tokenAmount) private;
}

 
contract WWAMPricingStrategy is PricingStrategy, Ownable, SafeMath {

  uint round1BeginsAt;
  uint round2BeginsAt;
  uint finalRoundBeginsAt;
  uint baseRate = 5000000000000;  
  
  enum CurrentRound { Round1, Round2, Final }
  
  function WWAMPricingStrategy(uint _round1BeginsAt, uint _round2BeginsAt, uint _finalRoundBeginsAt) {
	round1BeginsAt = _round1BeginsAt;
	round2BeginsAt = _round2BeginsAt;
	finalRoundBeginsAt = _finalRoundBeginsAt;
  }
  
  function getCurrentRound() public returns (CurrentRound){
	  if (now < round2BeginsAt)
		  return CurrentRound.Round1;
	  else if (now < finalRoundBeginsAt)
		  return CurrentRound.Round2;
	  return CurrentRound.Final;
  }
  
  function tokensToWei(uint tokens) public constant returns (uint) {
	return safeMul(tokens, baseRate);
  }
  
   
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
	 
	if (value < 10 finney) 
		return 0;
	 
	if (getCurrentRound() == CurrentRound.Round1)
		return safeMul(safeDiv(safeDiv(value, baseRate), 100), 115);
	 
	else if (getCurrentRound() == CurrentRound.Round2)
		return safeMul(safeDiv(safeDiv(value, baseRate), 100), 110);
	 
	return value / baseRate;
  }

}


 
contract StandardToken is ERC20, SafeMath {

   
  event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

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

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract WWAMBountyToken is StandardToken, Ownable {

   
  mapping (address => bool) public bountyAgents;
  
  event BountyAgentChanged(address addr, bool state  );
  
   
  function revokeTokens(address receiver, uint tokenAmount) onlyBountyAgent {
      if (balances[receiver] >= tokenAmount) {
	    totalSupply = safeSub(totalSupply, tokenAmount);
	    balances[receiver] = safeSub(balances[receiver], tokenAmount);
      }
  }
  
    
  function setBountyAgent(address addr, bool state) onlyOwner public {
    bountyAgents[addr] = state;
    BountyAgentChanged(addr, state);
  }
  
  modifier onlyBountyAgent() {
     
    if(!bountyAgents[msg.sender]) {
        throw;
    }
    _;
  }
  
}

 
contract MintableToken is StandardToken, Ownable {


  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );

   
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);

     
     
    Transfer(0, receiver, amount);
  }

   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
     
    if(!mintAgents[msg.sender]) {
        throw;
    }
    _;
  }

   
  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }
}


contract WWAMCrowdsale is Crowdsale {
  
   
  uint investmentCapInWei = 500000000000000000000000;  
  
   
  uint public bountyTokens = 0;
  
   
  mapping (address => uint256) public bountyRewards;
	
  function WWAMCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end)
    Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, 500000000000000000000) {  
  }

    
  function assignBountyTokens(address receiver, uint tokenAmount) onlyOwner {
	  uint bountyWeiAmount = WWAMPricingStrategy(pricingStrategy).tokensToWei(tokenAmount);
	  uint totalBountyWeiAmount = WWAMPricingStrategy(pricingStrategy).tokensToWei(bountyTokens);
	  
	   
	  if (safeAdd(bountyWeiAmount, totalBountyWeiAmount) >= (investmentCapInWei / 100))
		  throw;
	  
	  bountyRewards[receiver] = safeAdd(bountyRewards[receiver], tokenAmount);
	  bountyTokens = safeAdd(bountyTokens, tokenAmount);
	  
	  assignTokens(receiver, tokenAmount);
  }
  
   
  function revokeBountyTokens(address receiver, uint tokenAmount) onlyOwner {
	   
	  if (bountyRewards[receiver] < tokenAmount)
		  throw;
	  bountyTokens = safeSub(bountyTokens, tokenAmount);
	  bountyRewards[receiver] = safeSub(bountyRewards[receiver], tokenAmount);
	  
	  WWAMBountyToken bountyToken = WWAMBountyToken(token);
	  bountyToken.revokeTokens(receiver, tokenAmount);
  }
  
   
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool) {
    return weiRaisedTotal > investmentCapInWei;
  }

   
  function isCrowdsaleFull() public constant returns (bool) {
    return weiRaised >= investmentCapInWei;
  }

   
  function assignTokens(address receiver, uint tokenAmount) private {
    MintableToken mintableToken = MintableToken(token);
    mintableToken.mint(receiver, tokenAmount);
  }

}