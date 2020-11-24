 

pragma solidity ^0.4.11;

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
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
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
    if (halted) throw;
    _;
  }
  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) throw;
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
   
  function isPresalePurchase(address purchaser) public constant returns (bool) {
    return false;
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
 
 
contract FractionalERC20 is ERC20 {
  uint public decimals;
}
 
contract Crowdsale is Haltable {
   
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;
  using SafeMathLib for uint;
   
  FractionalERC20 public token;
   
  PricingStrategy public pricingStrategy;
   
  FinalizeAgent public finalizeAgent;
   
  address public multisigWallet;
   
  uint public minimumFundingGoal;
   
  uint public startsAt;
   
  uint public endsAt;
   
  uint public tokensSold = 0;
   
  uint public weiRaised = 0;
   
  uint public presaleWeiRaised = 0;
   
  uint public investorCount = 0;
   
  uint public loadedRefund = 0;
   
  uint public weiRefunded = 0;
   
  bool public finalized;
   
  bool public requireCustomerId;
   
  bool public requiredSignedAddress;
   
  address public signerAddress;
   
  mapping (address => uint256) public investedAmountOf;
   
  mapping (address => uint256) public tokenAmountOf;
   
  mapping (address => bool) public earlyParticipantWhitelist;
   
  uint public ownerTestValue;
   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}
   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);
   
  event Refund(address investor, uint weiAmount);
   
  event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);
   
  event Whitelisted(address addr, bool status);
   
  event EndsAtChanged(uint newEndsAt);
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
    throw;
  }
   
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {
     
    if(getState() == State.PreFunding) {
       
      if(!earlyParticipantWhitelist[receiver]) {
        throw;
      }
    } else if(getState() == State.Funding) {
       
       
    } else {
       
      throw;
    }
    uint weiAmount = msg.value;
     
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());
    if(tokenAmount == 0) {
       
      throw;
    }
    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }
     
    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);
     
    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);
    if(pricingStrategy.isPresalePurchase(receiver)) {
        presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
    }
     
    if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      throw;
    }
    assignTokens(receiver, tokenAmount);
     
    if(!multisigWallet.send(weiAmount)) throw;
     
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }
   
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {
    uint tokenAmount = fullTokens * 10**token.decimals();
    uint weiAmount = weiPrice * fullTokens;  
    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);
    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);
    assignTokens(receiver, tokenAmount);
     
    Invested(receiver, weiAmount, tokenAmount, 0);
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
    loadedRefund = loadedRefund.plus(msg.value);
  }
   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) throw;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.plus(weiValue);
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
 
 
library SafeMathLib {
  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
}
 
contract MintableToken is StandardToken, Ownable {
  using SafeMathLib for uint;
  bool public mintingFinished = false;
   
  mapping (address => bool) public mintAgents;
  event MintingAgentChanged(address addr, bool state  );
   
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = totalSupply.plus(amount);
    balances[receiver] = balances[receiver].plus(amount);
     
     
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
contract GetWhitelist is Ownable {
    using SafeMathLib for uint;
    event NewEntry(address whitelisted);
    event NewBatch();
    event EdittedEntry(address whitelisted, uint tier);
    event WhitelisterChange(address whitelister, bool iswhitelister);
    struct WhitelistInfo {
        uint presaleAmount;
        uint tier1Amount;
        uint tier2Amount;
        uint tier3Amount;
        uint tier4Amount;
        bool isWhitelisted;
    }
    mapping (address => bool) public whitelisters;
    
    mapping (address => WhitelistInfo) public entries;
    uint presaleCap;
    uint tier1Cap;
    uint tier2Cap;
    uint tier3Cap;
    uint tier4Cap;
    modifier onlyWhitelister() {
        require(whitelisters[msg.sender]);
        _;
    }
    function GetWhitelist(uint _presaleCap, uint _tier1Cap, uint _tier2Cap, uint _tier3Cap, uint _tier4Cap) {
        presaleCap = _presaleCap;
        tier1Cap = _tier1Cap;
        tier2Cap = _tier2Cap;
        tier3Cap = _tier3Cap;
        tier4Cap = _tier4Cap;
    }
    function isGetWhiteList() constant returns (bool) {
        return true;
    }
    function acceptBatched(address[] _addresses, bool _isEarly) onlyWhitelister {
         
        uint _presaleCap;
        if (_isEarly) {
            _presaleCap = presaleCap;
        } else {
            _presaleCap = 0;
        }
        for (uint i=0; i<_addresses.length; i++) {
            entries[_addresses[i]] = WhitelistInfo(
                _presaleCap,
                tier1Cap,
                tier2Cap,
                tier3Cap,
                tier4Cap,
                true
            );
        }
        NewBatch();
    }
    function accept(address _address, bool _isEarly) onlyWhitelister {
        require(!entries[_address].isWhitelisted);
        uint _presaleCap;
        if (_isEarly) {
            _presaleCap = presaleCap;
        } else {
            _presaleCap = 0;
        }
        entries[_address] = WhitelistInfo(_presaleCap, tier1Cap, tier2Cap, tier3Cap, tier4Cap, true);
        NewEntry(_address);
    }
    function subtractAmount(address _address, uint _tier, uint _amount) onlyWhitelister {
        require(_amount > 0);
        require(entries[_address].isWhitelisted);
        if (_tier == 0) {
            entries[_address].presaleAmount = entries[_address].presaleAmount.minus(_amount);
            EdittedEntry(_address, 0);
            return;
        }else if (_tier == 1) {
            entries[_address].tier1Amount = entries[_address].tier1Amount.minus(_amount);
            EdittedEntry(_address, 1);
            return;
        }else if (_tier == 2) {
            entries[_address].tier2Amount = entries[_address].tier2Amount.minus(_amount);
            EdittedEntry(_address, 2);
            return;
        }else if (_tier == 3) {
            entries[_address].tier3Amount = entries[_address].tier3Amount.minus(_amount);
            EdittedEntry(_address, 3);
            return;
        }else if (_tier == 4) {
            entries[_address].tier4Amount = entries[_address].tier4Amount.minus(_amount);
            EdittedEntry(_address, 4);
            return;
        }
        revert();
    }
    function setWhitelister(address _whitelister, bool _isWhitelister) onlyOwner {
        whitelisters[_whitelister] = _isWhitelister;
        WhitelisterChange(_whitelister, _isWhitelister);
    }
    function setCaps(uint _presaleCap, uint _tier1Cap, uint _tier2Cap, uint _tier3Cap, uint _tier4Cap) onlyOwner {
        presaleCap = _presaleCap;
        tier1Cap = _tier1Cap;
        tier2Cap = _tier2Cap;
        tier3Cap = _tier3Cap;
        tier4Cap = _tier4Cap;
    }
    function() payable {
        revert();
    }
}
contract GetCrowdsale is MintedTokenCappedCrowdsale {
    uint public lockTime;
    FinalizeAgent presaleFinalizeAgent;
    event PresaleUpdated(uint weiAmount, uint tokenAmount);
    function GetCrowdsale(
        uint _lockTime, FinalizeAgent _presaleFinalizeAgent,
        address _token, PricingStrategy _pricingStrategy, address _multisigWallet,
        uint _start, uint _end, uint _minimumFundingGoal, uint _maximumSellableTokens)
        MintedTokenCappedCrowdsale(_token, _pricingStrategy, _multisigWallet,
            _start, _end, _minimumFundingGoal, _maximumSellableTokens)
    {
        require(_presaleFinalizeAgent.isSane());
        require(_lockTime > 0);
        lockTime = _lockTime;
        presaleFinalizeAgent = _presaleFinalizeAgent;
    }
    function logPresaleResults(uint tokenAmount, uint weiAmount) returns (bool) {
        require(msg.sender == address(presaleFinalizeAgent));
        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);
        presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
        PresaleUpdated(weiAmount, tokenAmount);
        return true;
    }
     
    function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {
        uint tokenAmount = fullTokens * 10**token.decimals();
        uint weiAmount = weiPrice * fullTokens;  
        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);
        presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
        investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);
        assignTokens(receiver, tokenAmount);
         
        Invested(receiver, weiAmount, tokenAmount, 0);
    }
    function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
         
        revert();
    }
     
    function assignTokens(address receiver, uint tokenAmount) private {
        MintableToken mintableToken = MintableToken(token);
        mintableToken.mint(receiver, tokenAmount);
    }
    function finalize() public inState(State.Success) onlyOwner stopInEmergency {
        require(now > endsAt + lockTime);
        super.finalize();
    }
    function() payable {
        invest(msg.sender);
    }
}