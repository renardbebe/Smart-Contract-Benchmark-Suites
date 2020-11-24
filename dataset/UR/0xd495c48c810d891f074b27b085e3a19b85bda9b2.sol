 

pragma solidity ^0.4.13;

contract Owned {
	modifier only_owner {
		if (msg.sender != owner)
			return;
		_; 
	}

	event NewOwner(address indexed old, address indexed current);

	function setOwner(address _new) only_owner { NewOwner(owner, _new); owner = _new; }

	address public owner = msg.sender;
}

library Math {
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract LegalLazyScheduler is Ownable {
    uint64 public lastUpdate;
    uint64 public intervalDuration;
    bool schedulerEnabled = false;
    function() internal callback;

    event LogRegisteredInterval(uint64 date, uint64 duration);
    event LogProcessedInterval(uint64 date, uint64 intervals);    
     
    modifier intervalTrigger() {
        uint64 currentTime = uint64(now);
        uint64 requiredIntervals = (currentTime - lastUpdate) / intervalDuration;
        if( schedulerEnabled && (requiredIntervals > 0)) {
            LogProcessedInterval(lastUpdate, requiredIntervals);
            while (requiredIntervals-- > 0) {
                callback();
            }
            lastUpdate = currentTime;
        }
        _;
    }
    
    function LegalLazyScheduler() {
        lastUpdate = uint64(now);
    }

    function enableScheduler() onlyOwner public {
        schedulerEnabled = true;
    }

    function registerIntervalCall(uint64 _intervalDuration, function() internal _callback) internal {
        lastUpdate = uint64(now);
        intervalDuration = _intervalDuration;
        callback = _callback;
        LogRegisteredInterval(lastUpdate, intervalDuration);        
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

  function close() onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner {
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

contract LegalTGE is Ownable, Pausable {
   
  using SafeMath for uint256;
   
  enum States{PreparePreContribution, PreContribution, PrepareContribution, Contribution, Auditing, Finalized, Refunding}

  enum VerificationLevel { None, SMSVerified, KYCVerified }

  
  event LogStateChange(States _states);


   
  event LogKYCConfirmation(address sender);

   
  event LogTokenAssigned(address sender, address newToken);

   
  event LogTimedTransition(uint _now, States _newState);
  
   
  event LogPreparePreContribution(address sender, uint conversionRate, uint startDate, uint endDate);

   
  event LogContribution(address contributor, uint256 weiAmount, uint256 tokenAmount, VerificationLevel verificationLevel, States _state);

   
  event LogFinalized(address sender);

   
  event LogRegularityConfirmation(address sender, bool _regularity, bytes32 _comment);
  
   
  event LogRefundsEnabled(address sender);

   
  event LogPrepareContribution(address sender, uint conversionRate, uint startDate, uint endDate);

    
  RefundVault public vault;

   
  States public state;

    
  LegalToken public token;
  
    
  ProofOfSMS public proofOfSMS;

   
  address public multisigWallet;

   
  uint256 public tokenCap;

   
  mapping (address => uint) public weiPerContributor;

   
  uint256 public minWeiPerContributor;

   
  uint256 public maxWeiSMSVerified;

   
  uint256 public maxWeiUnverified;

    
  uint public preSaleConversionRate;

   
  uint public preSaleStartDate;

   
  uint public preSaleEndDate;

    
  uint public saleConversionRate;

   
  uint public saleStartDate;

   
  uint public saleEndDate;

   
  uint public smsVerifiedBonusBps;

   
  uint public kycVerifiedBonusBps;

   
  uint public maxTeamBonusBps;

   
  address public foundationBoard;

   
  address public kycConfirmer;

   
  address public auditor;

   
  address public instContWallet;

   
  bool public regulationsFulfilled;

   
  bytes32 public auditorComment;

   
  uint256 public tokensSold = 0;

   
  uint public instContAllocatedTokens;

   
  uint256 public weiRaised = 0;

   
  uint256 public preSaleWeiRaised = 0;

   
  uint256 public weiRefunded = 0;

   
  uint public teamBonusAllocatedTokens;

   
  uint public numberOfContributors = 0;

   
  mapping (address => bool) public kycRegisteredContributors;

  struct TeamBonus {
    address toAddress;
    uint64 tokenBps;
    uint64 cliffDate;
    uint64 vestingDate;
  }

   
  TeamBonus[] public teamBonuses;

   

 function LegalTGE (address _foundationBoard, address _multisigWallet, address _instContWallet, uint256 _instContAllocatedTokens, uint256 _tokenCap, uint256 _smsVerifiedBonusBps, uint256 _kycVerifiedBonusBps, uint256 _maxTeamBonusBps, address _auditor, address _kycConfirmer, ProofOfSMS _proofOfSMS, RefundVault _vault) {
      
     
     
     
    require(_foundationBoard != 0x0);
    
     
    require(_multisigWallet != 0x0);

     
    require(_instContWallet != 0x0);

     
    require(_auditor != 0x0);
    
     
    require(_tokenCap > 0); 

     
     

    multisigWallet = _multisigWallet;
    instContWallet = _instContWallet;
    instContAllocatedTokens = _instContAllocatedTokens;
    tokenCap = _tokenCap;
    smsVerifiedBonusBps = _smsVerifiedBonusBps;
    kycVerifiedBonusBps = _kycVerifiedBonusBps;
    maxTeamBonusBps = _maxTeamBonusBps;
    auditor = _auditor;
    foundationBoard = _foundationBoard;
    kycConfirmer = _kycConfirmer;
    proofOfSMS = _proofOfSMS;

     
     
     
    state = States.PreparePreContribution;
    vault = _vault;
  }

   

  function setMaxWeiForVerificationLevels(uint _minWeiPerContributor, uint _maxWeiUnverified, uint  _maxWeiSMSVerified) public onlyOwner inState(States.PreparePreContribution) {
    require(_minWeiPerContributor >= 0);
    require(_maxWeiUnverified > _minWeiPerContributor);
    require(_maxWeiSMSVerified > _minWeiPerContributor);

     
    minWeiPerContributor = _minWeiPerContributor;

     
    maxWeiUnverified = _maxWeiUnverified;

     
    maxWeiSMSVerified = _maxWeiSMSVerified;
  }

  function setLegalToken(LegalToken _legalToken) public onlyOwner inState(States.PreparePreContribution) {
    token = _legalToken;
    if ( instContAllocatedTokens > 0 ) {
       
      token.mint(instContWallet, instContAllocatedTokens);
      tokensSold += instContAllocatedTokens;
    }    
    LogTokenAssigned(msg.sender, _legalToken);
  }

  function validatePreContribution(uint _preSaleConversionRate, uint _preSaleStartDate, uint _preSaleEndDate) constant internal {
     
    require(_preSaleConversionRate >= 0);

     
    require(_preSaleStartDate >= now);

     
    require(_preSaleEndDate >= _preSaleStartDate);
  }

  function validateContribution(uint _saleConversionRate, uint _saleStartDate, uint _saleEndDate) constant internal {
     
    require(_saleConversionRate >= 0);

     
    require(_saleStartDate >= now);

     
    require(_saleEndDate >= _saleStartDate);
  }

  function isNowBefore(uint _date) constant internal returns (bool) {
    return ( now < _date );
  }

  function evalTransitionState() public returns (States) {
     
    if ( hasState(States.Finalized))
      return States.Finalized;
    if ( hasState(States.Refunding))
      return States.Refunding;
    if ( isCapReached()) 
      return States.Auditing;
    if ( isNowBefore(preSaleStartDate))
      return States.PreparePreContribution; 
    if ( isNowBefore(preSaleEndDate))
      return States.PreContribution;
    if ( isNowBefore(saleStartDate))  
      return States.PrepareContribution;
    if ( isNowBefore(saleEndDate))    
      return States.Contribution;
    return States.Auditing;
  }

  modifier stateTransitions() {
    States evaluatedState = evalTransitionState();
    setState(evaluatedState);
    _;
  }

  function hasState(States _state) constant private returns (bool) {
    return (state == _state);
  }

  function setState(States _state) private {
  	if ( _state != state ) {
      state = _state;
	  LogStateChange(state);
	  }
  }

  modifier inState(States  _state) {
    require(hasState(_state));
    _;
  }

  function updateState() public stateTransitions {
  }  
  
   
  modifier inPreOrContributionState() {
    require(hasState(States.PreContribution) || (hasState(States.Contribution)));
    _;
  }
  modifier inPrePrepareOrPreContributionState() {
    require(hasState(States.PreparePreContribution) || (hasState(States.PreContribution)));
    _;
  }

  modifier inPrepareState() {
     
    require(hasState(States.PreparePreContribution) || (hasState(States.PrepareContribution)));
    _;
  }
   
  modifier teamBonusLimit(uint64 _tokenBps) {
    uint teamBonusBps = 0; 
    for ( uint i = 0; i < teamBonuses.length; i++ ) {
      teamBonusBps = teamBonusBps.add(teamBonuses[i].tokenBps);
    }
    require(maxTeamBonusBps >= teamBonusBps);
    _;
  }

   
  function allocateTeamBonus(address _toAddress, uint64 _tokenBps, uint64 _cliffDate, uint64 _vestingDate) public onlyOwner teamBonusLimit(_tokenBps) inState(States.PreparePreContribution) {
    teamBonuses.push(TeamBonus(_toAddress, _tokenBps, _cliffDate, _vestingDate));
  }

   
  function preparePreContribution(uint _preSaleConversionRate, uint _preSaleStartDate, uint _preSaleEndDate) public onlyOwner inState(States.PreparePreContribution) {
    validatePreContribution(_preSaleConversionRate, _preSaleStartDate, _preSaleEndDate);    
    preSaleConversionRate = _preSaleConversionRate;
    preSaleStartDate = _preSaleStartDate;
    preSaleEndDate = _preSaleEndDate;
    LogPreparePreContribution(msg.sender, preSaleConversionRate, preSaleStartDate, preSaleEndDate);
  }

   
  function prepareContribution(uint _saleConversionRate, uint _saleStartDate, uint _saleEndDate) public onlyOwner inPrepareState {
    validateContribution(_saleConversionRate, _saleStartDate, _saleEndDate);
    saleConversionRate = _saleConversionRate;
    saleStartDate = _saleStartDate;
    saleEndDate = _saleEndDate;

    LogPrepareContribution(msg.sender, saleConversionRate, saleStartDate, saleEndDate);
  }

   
  function () payable public {
    contribute();  
  }
  function getWeiPerContributor(address _contributor) public constant returns (uint) {
  	return weiPerContributor[_contributor];
  }

  function contribute() whenNotPaused stateTransitions inPreOrContributionState public payable {
    require(msg.sender != 0x0);
    require(msg.value >= minWeiPerContributor);

    VerificationLevel verificationLevel = getVerificationLevel();
    
     
    require(hasState(States.Contribution) || verificationLevel > VerificationLevel.None);

     
    weiPerContributor[msg.sender] = weiPerContributor[msg.sender].add(msg.value);

     

    if ( verificationLevel == VerificationLevel.SMSVerified ) {
       
      require(weiPerContributor[msg.sender] <= maxWeiSMSVerified);
    }

    if ( verificationLevel == VerificationLevel.None ) {
       
      require(weiPerContributor[msg.sender] <= maxWeiUnverified);
    }

    if (hasState(States.PreContribution)) {
      preSaleWeiRaised = preSaleWeiRaised.add(msg.value);
    }

    weiRaised = weiRaised.add(msg.value);

     
    uint256 tokenAmount = calculateTokenAmount(msg.value, verificationLevel);

    tokensSold = tokensSold.add(tokenAmount);

    if ( token.balanceOf(msg.sender) == 0 ) {
       numberOfContributors++;
    }

    if ( isCapReached()) {
      updateState();
    }

    token.mint(msg.sender, tokenAmount);

    forwardFunds();

    LogContribution(msg.sender, msg.value, tokenAmount, verificationLevel, state);    
  }

 
  function calculateTokenAmount(uint256 _weiAmount, VerificationLevel _verificationLevel) public constant returns (uint256) {
    uint256 conversionRate = saleConversionRate;
    if ( state == States.PreContribution) {
      conversionRate = preSaleConversionRate;
    }
    uint256 tokenAmount = _weiAmount.mul(conversionRate);
    
     
    uint256 bonusTokenAmount = 0;

    if ( _verificationLevel == VerificationLevel.SMSVerified ) {
       
      bonusTokenAmount = tokenAmount.mul(smsVerifiedBonusBps).div(10000);
    } else if ( _verificationLevel == VerificationLevel.KYCVerified ) {
       
      bonusTokenAmount = tokenAmount.mul(kycVerifiedBonusBps).div(10000);
    }
    return tokenAmount.add(bonusTokenAmount);
  }

  function getVerificationLevel() constant public returns (VerificationLevel) {
    if (kycRegisteredContributors[msg.sender]) {
      return VerificationLevel.KYCVerified;
    } else if (proofOfSMS.certified(msg.sender)) {
      return VerificationLevel.SMSVerified;
    }
    return VerificationLevel.None;
  }

  modifier onlyKycConfirmer() {
    require(msg.sender == kycConfirmer);
    _;
  }

  function confirmKYC(address addressId) onlyKycConfirmer inPrePrepareOrPreContributionState() public returns (bool) {
    LogKYCConfirmation(msg.sender);
    return kycRegisteredContributors[addressId] = true;
  }

 
 
 
  function isCapReached() constant internal returns (bool) {
    if (tokensSold >= tokenCap) {
      return true;
    }
    return false;
  }

 
 
 
   
  modifier onlyFoundationBoard() {
    require(msg.sender == foundationBoard);
    _;
  }

   
  modifier onlyAuditor() {
    require(msg.sender == auditor);
    _;
  }
  
   
  modifier auditorConfirmed() {
    require(auditorComment != 0x0);
    _;
  }

  
 function confirmLawfulness(bool _regulationsFulfilled, bytes32 _auditorComment) public onlyAuditor stateTransitions inState ( States.Auditing ) {
    regulationsFulfilled = _regulationsFulfilled;
    auditorComment = _auditorComment;
    LogRegularityConfirmation(msg.sender, _regulationsFulfilled, _auditorComment);
  }

   
  function finalize() public onlyFoundationBoard stateTransitions inState ( States.Auditing ) auditorConfirmed {
    setState(States.Finalized);
     
    token.releaseTokenTransfer();
    
     
    allocateTeamBonusTokens();

     
    vault.close();

     
    token.finishMinting();

     
    token.enableScheduler();

     
    token.transferOwnership(owner);

    LogFinalized(msg.sender);
  }

  function enableRefunds() public onlyFoundationBoard stateTransitions inState ( States.Auditing ) auditorConfirmed {
    setState(States.Refunding);

    LogRefundsEnabled(msg.sender);

     
    vault.enableRefunds(); 
  }
  

 
 
 
  
   
  function allocateTeamBonusTokens() private {

    for (uint i = 0; i < teamBonuses.length; i++) {
       
      uint _teamBonusTokens = (tokensSold.mul(teamBonuses[i].tokenBps)).div(10000);

       
      token.mint(this, _teamBonusTokens);
      token.grantVestedTokens(teamBonuses[i].toAddress, _teamBonusTokens, uint64(now), teamBonuses[i].cliffDate, teamBonuses[i].vestingDate, false, false);
      teamBonusAllocatedTokens = teamBonusAllocatedTokens.add(_teamBonusTokens);
    }
  }

   
   
   
   

   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public stateTransitions inState ( States.Refunding ) {
     
    weiRefunded = weiRefunded.add(vault.deposited(msg.sender));
    vault.refund(msg.sender);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint256 _value) {
    require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }

   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
    return balanceOf(holder);
  }
}

contract VestedToken is StandardToken, LimitedTransferToken, Ownable {

  uint256 MAX_GRANTS_PER_ADDRESS = 20;

  struct TokenGrant {
    address granter;      
    uint256 value;        
    uint64 cliff;
    uint64 vesting;
    uint64 start;         
    bool revokable;
    bool burnsOnRevoke;   
  }  

  mapping (address => TokenGrant[]) public grants;

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

   
  function grantVestedTokens(
    address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke
  ) onlyOwner public {

     
    require(_cliff >= _start && _vesting >= _cliff);

    require(tokenGrantsCount(_to) < MAX_GRANTS_PER_ADDRESS);    

    uint256 count = grants[_to].push(
                TokenGrant(
                  _revokable ? msg.sender : 0,  
                  _value,
                  _cliff,
                  _vesting,
                  _start,
                  _revokable,
                  _burnsOnRevoke
                )
              );

    transfer(_to, _value);

    NewTokenGrant(msg.sender, _to, _value, count - 1);
  }

   
  function revokeTokenGrant(address _holder, uint256 _grantId) public {
    TokenGrant storage grant = grants[_holder][_grantId];

    require(grant.revokable);
    require(grant.granter == msg.sender);  

    address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;

    uint256 nonVested = nonVestedTokens(grant, uint64(now));

     
    delete grants[_holder][_grantId];
    grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
    grants[_holder].length -= 1;

    balances[receiver] = balances[receiver].add(nonVested);
    balances[_holder] = balances[_holder].sub(nonVested);

    Transfer(_holder, receiver, nonVested);
  }


   
  function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);

    if (grantIndex == 0) 
      return super.transferableTokens(holder, time);  

     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time));
    }

     
    uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

     
     
    return Math.min256(vestedTransferable, super.transferableTokens(holder, time));
  }

   
  function tokenGrantsCount(address _holder) public constant returns (uint256 index) {
    return grants[_holder].length;
  }

   
  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) public constant returns (uint256)
    {
       
      if (time < cliff) return 0;
      if (time >= vesting) return tokens;

       
       
       

       
      uint256 vestedTokens = SafeMath.div(
                                    SafeMath.mul(
                                      tokens,
                                      SafeMath.sub(time, start)
                                      ),
                                    SafeMath.sub(vesting, start)
                                    );

      return vestedTokens;
  }

   
  function tokenGrant(address _holder, uint256 _grantId) public constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
    TokenGrant storage grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;
    revokable = grant.revokable;
    burnsOnRevoke = grant.burnsOnRevoke;

    vested = vestedTokens(grant, uint64(now));
  }

   
  function vestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return calculateVestedTokens(
      grant.value,
      uint256(time),
      uint256(grant.start),
      uint256(grant.cliff),
      uint256(grant.vesting)
    );
  }

   
  function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return grant.value.sub(vestedTokens(grant, time));
  }

   
  function lastTokenIsTransferableDate(address holder) public constant returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = grants[holder].length;
    for (uint256 i = 0; i < grantIndex; i++) {
      date = Math.max64(grants[holder][i].vesting, date);
    }
  }
}

contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address _who) constant returns (bool);
	 
	 
	 
}

contract SimpleCertifier is Owned, Certifier {

	modifier only_delegate {
		assert(msg.sender == delegate);
		_; 
	}
	modifier only_certified(address _who) {
		if (!certs[_who].active)
			return;
		_; 
	}

	struct Certification {
		bool active;
		mapping (string => bytes32) meta;
	}

	function certify(address _who) only_delegate {
		certs[_who].active = true;
		Confirmed(_who);
	}
	function revoke(address _who) only_delegate only_certified(_who) {
		certs[_who].active = false;
		Revoked(_who);
	}
	function certified(address _who) constant returns (bool) { return certs[_who].active; }
	 
	 
	 
	function setDelegate(address _new) only_owner { delegate = _new; }

	mapping (address => Certification) certs;
	 
	address public delegate = msg.sender;
}

contract ProofOfSMS is SimpleCertifier {

	modifier when_fee_paid {
		if (msg.value < fee)  {
		RequiredFeeNotMet(fee, msg.value);
			return;
		}
		_; 
	}
	event RequiredFeeNotMet(uint required, uint provided);
	event Requested(address indexed who);
	event Puzzled(address who, bytes32 puzzle);

	event LogAddress(address test);

	function request() payable when_fee_paid {
		if (certs[msg.sender].active) {
			return;
		}
		Requested(msg.sender);
	}

	function puzzle (address _who, bytes32 _puzzle) only_delegate {
		puzzles[_who] = _puzzle;
		Puzzled(_who, _puzzle);
	}

	function confirm(bytes32 _code) returns (bool) {
		LogAddress(msg.sender);
		if (puzzles[msg.sender] != sha3(_code))
			return;

		delete puzzles[msg.sender];
		certs[msg.sender].active = true;
		Confirmed(msg.sender);
		return true;
	}

	function setFee(uint _new) only_owner {
		fee = _new;
	}

	function drain() only_owner {
		require(msg.sender.send(this.balance));
	}

	function certified(address _who) constant returns (bool) {
		return certs[_who].active;
	}

	mapping (address => bytes32) puzzles;

	uint public fee = 30 finney;
}

contract LegalToken is LegalLazyScheduler, MintableToken, VestedToken {
     
    bytes32 public name;

     
    bytes32 public symbol;

     
    uint public decimals = 18;

     
    uint32 public inflationCompBPS;

     
    bool public released = false;

     
    address public rewardWallet;

     
    event UpdatedTokenInformation(bytes32 newName, bytes32 newSymbol);

     
    function LegalToken(address _rewardWallet, uint32 _inflationCompBPS, uint32 _inflationCompInterval) onlyOwner public {
        setTokenInformation("Legal Token", "LGL");
        totalSupply = 0;        
        rewardWallet = _rewardWallet;
        inflationCompBPS = _inflationCompBPS;
        registerIntervalCall(_inflationCompInterval, mintInflationPeriod);
    }    

     
    function setTokenInformation(bytes32 _name, bytes32 _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
        UpdatedTokenInformation(name, symbol);
    }

     
    function mintInflationPeriod() private {
        uint256 tokensToMint = totalSupply.mul(inflationCompBPS).div(10000);
        totalSupply = totalSupply.add(tokensToMint);
        balances[rewardWallet] = balances[rewardWallet].add(tokensToMint);
        Mint(rewardWallet, tokensToMint);
        Transfer(0x0, rewardWallet, tokensToMint);
    }     
    
    function setRewardWallet(address _rewardWallet) public onlyOwner {
        rewardWallet = _rewardWallet;
    }

     
    modifier tokenReleased(address _sender) {
        require(released);
        _;
    }

     
    function releaseTokenTransfer() public onlyOwner {
        released = true;
    }

     
    function transfer(address _to, uint _value) public tokenReleased(msg.sender) intervalTrigger returns (bool success) {
         
         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public tokenReleased(_from) intervalTrigger returns (bool success) {
         
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public tokenReleased(msg.sender) intervalTrigger returns (bool) {
         
        return super.approve(_spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
         
        return super.allowance(_owner, _spender);
    }

    function increaseApproval (address _spender, uint _addedValue) public tokenReleased(msg.sender) intervalTrigger returns (bool success) {
         
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public tokenReleased(msg.sender) intervalTrigger returns (bool success) {
         
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}