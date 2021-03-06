 

 



 
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

   
  uint public largeCapDelay = 24 * 60 * 60;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public investorCount = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized;

   
  bool public requireCustomerId = false;

   
  bool public requiredSignedAddress = false;

   
  address public signerAddress;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  mapping (address => uint256) public smallCapLimitOf;

   
  mapping (address => uint256) public largeCapLimitOf;

   
  mapping (address => bool) public earlyParticipantWhitelist;

   
  mapping (address => bool) public isWhitelistAgent;

   
  uint public ownerTestValue;

   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

   
  event Refund(address investor, uint weiAmount);

   
  event InvestmentPolicyChanged(bool requireCustomerId, bool requiredSignedAddress, address signerAddress);

   
  event WhitelistedEarlyParticipant(address addr, bool status);
  event WhitelistedSmallCap(address addr, uint256 limit);
  event WhitelistedLargeCap(address addr, uint256 limit);

   
  event EndsAtChanged(uint endsAt);
  event StartsAtChanged(uint startsAt);
  event LargeCapStartTimeChanged(uint startsAt);

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

     
    isWhitelistAgent[owner] = true;
    isWhitelistAgent[multisigWallet] = true;

     
    minimumFundingGoal = _minimumFundingGoal;
  }

   
  function() payable {
    invest(msg.sender);
  }

   
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

     
    State state = getState();
    if (state == State.Funding) {
       
    } else if (state == State.PreFunding) {
       
      if (!earlyParticipantWhitelist[receiver]) {
        throw;
      }
    } else {
       
      throw;
    }

    uint weiAmount = msg.value;
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());

    if (tokenAmount == 0) {
       
      throw;
    }

    if (investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokenAmount);

     
    uint256 personalWeiLimit = smallCapLimitOf[receiver];
    if (block.timestamp > startsAt + largeCapDelay) {
      personalWeiLimit = safeAdd(personalWeiLimit, largeCapLimitOf[receiver]);
    }
    if (investedAmountOf[receiver] > personalWeiLimit) {
      throw;
    }

     
    weiRaised = safeAdd(weiRaised, weiAmount);
    tokensSold = safeAdd(tokensSold, tokenAmount);

     
    if (isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      throw;
    }

    assignTokens(receiver, tokenAmount);

     
    if (!multisigWallet.send(weiAmount)) throw;

     
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }

   
  function preallocate(address receiver, uint tokenAmount, uint weiAmount) public onlyOwner {
    if (getState() != State.PreFunding) { throw; }

     
    if (weiAmount == 0) {
      tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokenAmount);
      assignTokens(receiver, tokenAmount);
    } else {

       
      if (investedAmountOf[receiver] == 0) {
        investorCount++;
      }

      weiRaised = safeAdd(weiRaised, weiAmount);
      tokensSold = safeAdd(tokensSold, tokenAmount);
      investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
      tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokenAmount);

      assignTokens(receiver, tokenAmount);

      Invested(receiver, weiAmount, tokenAmount, 0);
    }
  }

   
  function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
     bytes32 hash = sha256(addr);
     if (ecrecover(hash, v, r, s) != signerAddress) throw;
     if(customerId == 0) throw;   
     investInternal(addr, customerId);
  }

   
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    if(requiredSignedAddress) throw;  
    if(customerId == 0) throw;   
    investInternal(addr, customerId);
  }

   
  function invest(address addr) public payable {
    if(requireCustomerId) throw;  
    if(requiredSignedAddress) throw;  
    investInternal(addr, 0);
  }

   
  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
    investWithSignedAddress(msg.sender, customerId, v, r, s);
  }

   
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

   
  function buy() public payable {
    invest(msg.sender);
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

   
  function setRequireCustomerId(bool value) onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
    requiredSignedAddress = value;
    signerAddress = _signerAddress;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setEarlyParticipantWhitelist(address addr, bool status) onlyOwner {
    earlyParticipantWhitelist[addr] = status;
    WhitelistedEarlyParticipant(addr, status);
  }

   
  function setSmallCapWhitelistParticipant(address addr, uint256 weiLimit) {
    if (isWhitelistAgent[msg.sender]) {
      smallCapLimitOf[addr] = weiLimit;
      WhitelistedSmallCap(addr, weiLimit);
    }
  }
  function setSmallCapWhitelistParticipants(address[] addrs, uint256 weiLimit) {
    if (isWhitelistAgent[msg.sender]) {
      for (uint i = 0; i < addrs.length; i++) {
        var addr = addrs[i];
        smallCapLimitOf[addr] = weiLimit;
        WhitelistedSmallCap(addr, weiLimit);
      }
    }
  }
  function setSmallCapWhitelistParticipants(address[] addrs, uint256[] weiLimits) {
    if (addrs.length != weiLimits.length) {
      throw;
    }
    if (isWhitelistAgent[msg.sender]) {
      for (uint i = 0; i < addrs.length; i++) {
        var addr = addrs[i];
        var weiLimit = weiLimits[i];
        smallCapLimitOf[addr] = weiLimit;
        WhitelistedSmallCap(addr, weiLimit);
      }
    }
  }

  function setLargeCapWhitelistParticipant(address addr, uint256 weiLimit) {
    if (isWhitelistAgent[msg.sender]) {
      largeCapLimitOf[addr] = weiLimit;
      WhitelistedLargeCap(addr, weiLimit);
    }
  }
  function setLargeCapWhitelistParticipants(address[] addrs, uint256 weiLimit) {
    if (isWhitelistAgent[msg.sender]) {
      for (uint i = 0; i < addrs.length; i++) {
        var addr = addrs[i];
        largeCapLimitOf[addr] = weiLimit;
        WhitelistedLargeCap(addr, weiLimit);
      }
    }
  }
  function setLargeCapWhitelistParticipants(address[] addrs, uint256[] weiLimits) {
    if (addrs.length != weiLimits.length) {
      throw;
    }
    if (isWhitelistAgent[msg.sender]) {
      for (uint i = 0; i < addrs.length; i++) {
        var addr = addrs[i];
        var weiLimit = weiLimits[i];
        largeCapLimitOf[addr] = weiLimit;
        WhitelistedLargeCap(addr, weiLimit);
      }
    }
  }

  function setWhitelistAgent(address addr, bool status) onlyOwner {
    isWhitelistAgent[addr] = status;
  }

   
  function setStartsAt(uint time) onlyOwner {

     
    if (time < now) { throw; }

     
    if (time > endsAt) { throw; }

     
    if (startsAt < now) { throw; }

    startsAt = time;
    StartsAtChanged(endsAt);
  }

  function setLargeCapDelay(uint secs) onlyOwner {
    if (secs < 0) { throw; }

     
    if (startsAt + secs > endsAt) { throw; }

     
    if (startsAt + largeCapDelay < now) { throw; }

    largeCapDelay = secs;
    LargeCapStartTimeChanged(startsAt + largeCapDelay);
  }

   
  function setEndsAt(uint time) onlyOwner {

    if (now > time) {
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



 
contract MintableToken is StandardToken, Ownable {

  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);

   
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


 
contract MintedTokenCappedCrowdsale is Crowdsale {

   
  uint public maximumSellableTokens;

  function MintedTokenCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _maximumSellableTokens) Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) {
    maximumSellableTokens = _maximumSellableTokens;
  }

   
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
    return tokensSoldTotal > maximumSellableTokens;
  }

  function isCrowdsaleFull() public constant returns (bool) {
    return tokensSold >= maximumSellableTokens;
  }

   
  function assignTokens(address receiver, uint tokenAmount) private {
    MintableToken mintableToken = MintableToken(token);
    mintableToken.mint(receiver, tokenAmount);
  }
}