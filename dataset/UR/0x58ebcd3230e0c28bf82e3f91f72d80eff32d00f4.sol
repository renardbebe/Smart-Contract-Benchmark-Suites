 

pragma solidity ^0.4.13;
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract Math {
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
    require(newOwner != address(0));
    owner = newOwner;
  }
}
 
contract SafeMath {
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
 
contract BasicToken is SafeMath, ERC20Basic {
  mapping(address => uint256) balances;
   
  function transfer(address _to, uint _value) returns (bool){
    balances[msg.sender] = sub(balances[msg.sender],_value);
    balances[_to] = add(balances[_to],_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
     
     
    balances[_to] = add(balances[_to],_value);
    balances[_from] = sub(balances[_from],_value);
    allowed[_from][msg.sender] = sub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;
  }
   
  function approve(address _spender, uint256 _value) returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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
   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = add(totalSupply,_amount);
    balances[_to] = add(balances[_to],_amount);
    Mint(_to, _amount);
    return true;
  }
   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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
   
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }
   
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}
 
contract PausableToken is StandardToken, Pausable {
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }
  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}
 
contract LimitedTransferToken is ERC20 {
   
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }
   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) returns (bool) {
    return super.transfer(_to, _value);
  }
   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    return balanceOf(holder);
  }
}
 
contract VestedToken is Math, StandardToken, LimitedTransferToken {
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
  ) public {
     
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
    grants[_holder][_grantId] = grants[_holder][sub(grants[_holder].length,1)];
    grants[_holder].length -= 1;
    balances[receiver] = add(balances[receiver],nonVested);
    balances[_holder] = sub(balances[_holder],nonVested);
    Transfer(_holder, receiver, nonVested);
  }
   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);
    if (grantIndex == 0) return super.transferableTokens(holder, time);  
     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = add(nonVested, nonVestedTokens(grants[holder][i], time));
    }
     
    uint256 vestedTransferable = sub(balanceOf(holder), nonVested);
     
     
    return min256(vestedTransferable, super.transferableTokens(holder, time));
  }
   
  function tokenGrantsCount(address _holder) constant returns (uint256 index) {
    return grants[_holder].length;
  }
   
  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) constant returns (uint256)
    {
       
      if (time < cliff) return 0;
      if (time >= vesting) return tokens;
       
       
       
       
      uint256 vestedTokens = div(
                                    mul(
                                      tokens,
                                      sub(time, start)
                                      ),
                                    sub(vesting, start)
                                    );
      return vestedTokens;
  }
   
  function tokenGrant(address _holder, uint256 _grantId) constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
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
    return sub(grant.value,vestedTokens(grant, time));
  }
   
  function lastTokenIsTransferableDate(address holder) constant public returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = grants[holder].length;
    for (uint256 i = 0; i < grantIndex; i++) {
      date = max64(grants[holder][i].vesting, date);
    }
  }
}
 
contract BurnableToken is SafeMath, StandardToken {
    event Burn(address indexed burner, uint indexed value);
     
    function burn(uint _value)
        public
    {
        require(_value > 0);
        address burner = msg.sender;
        balances[burner] = sub(balances[burner], _value);
        totalSupply = sub(totalSupply, _value);
        Burn(burner, _value);
    }
}
 
contract PLC is MintableToken, PausableToken, VestedToken, BurnableToken {
  string public name = "PlusCoin";
  string public symbol = "PLC";
  uint256 public decimals = 18;
}
 
contract RefundVault is Ownable, SafeMath{
  enum State { Active, Refunding, Closed }
  mapping (address => uint256) public deposited;
  mapping (address => uint256) public refunded;
  State public state;
  address public devMultisig;
  address[] public reserveWallet;
  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
   
  function RefundVault(address _devMultiSig, address[] _reserveWallet) {
    state = State.Active;
    devMultisig = _devMultiSig;
    reserveWallet = _reserveWallet;
  }
   
  function deposit(address investor) onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = add(deposited[investor], msg.value);
  }
  event Transferred(address _to, uint _value);
   
  function close() onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    uint256 balance = this.balance;
    uint256 devAmount = div(balance, 10);
    devMultisig.transfer(devAmount);
    Transferred(devMultisig, devAmount);
    uint256 reserveAmount = div(mul(balance, 9), 10);
    uint256 reserveAmountForEach = div(reserveAmount, reserveWallet.length);
    for(uint8 i = 0; i < reserveWallet.length; i++){
      reserveWallet[i].transfer(reserveAmountForEach);
      Transferred(reserveWallet[i], reserveAmountForEach);
    }
    Closed();
  }
   
  function enableRefunds() onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }
   
  function refund(address investor) returns (bool) {
    require(state == State.Refunding);
    if (refunded[investor] > 0) {
      return false;
    }
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    refunded[investor] = depositedValue;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
    return true;
  }
}
 
contract KYC is Ownable, SafeMath, Pausable {
   
  mapping (address => bool) public registeredAddress;
   
  mapping (address => bool) public admin;
  event Registered(address indexed _addr);
  event Unregistered(address indexed _addr);
  event NewAdmin(address indexed _addr);
   
  modifier onlyRegistered(address _addr) {
    require(isRegistered(_addr));
    _;
  }
   
  modifier onlyAdmin() {
    require(admin[msg.sender]);
    _;
  }
  function KYC() {
    admin[msg.sender] = true;
  }
   
  function setAdmin(address _addr)
    public
    onlyOwner
  {
    require(_addr != address(0) && admin[_addr] == false);
    admin[_addr] = true;
    NewAdmin(_addr);
  }
   
  function isRegistered(address _addr)
    public
    constant
    returns (bool)
  {
    return registeredAddress[_addr];
  }
   
  function register(address _addr)
    public
    onlyAdmin
    whenNotPaused
  {
    require(_addr != address(0) && registeredAddress[_addr] == false);
    registeredAddress[_addr] = true;
    Registered(_addr);
  }
   
  function registerByList(address[] _addrs)
    public
    onlyAdmin
    whenNotPaused
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0) && registeredAddress[_addrs[i]] == false);
      registeredAddress[_addrs[i]] = true;
      Registered(_addrs[i]);
    }
  }
   
  function unregister(address _addr)
    public
    onlyAdmin
    onlyRegistered(_addr)
  {
    registeredAddress[_addr] = false;
    Unregistered(_addr);
  }
   
  function unregisterByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(isRegistered(_addrs[i]));
      registeredAddress[_addrs[i]] = false;
      Unregistered(_addrs[i]);
    }
  }
}
 
contract PLCCrowdsale is Ownable, SafeMath, Pausable {
   
  KYC public kyc;
   
  PLC public token;
   
  uint64 public startTime;  
  uint64 public endTime;  
  uint64[5] public deadlines;  
  mapping (address => uint256) public presaleRate;
  uint8[5] public rates = [240, 230, 220, 210, 200];
   
  uint256 public weiRaised;
   
  uint256 constant public maxGuaranteedLimit = 5000 ether;
   
  mapping (address => uint256) public presaleGuaranteedLimit;
  mapping (address => bool) public isDeferred;
   
   
  mapping (bool => mapping (address => uint256)) public buyerFunded;
   
  uint256 public deferredTotalTokens;
   
  uint256 constant public maxCallFrequency = 20;
   
  mapping (address => uint256) public lastCallBlock;
  bool public isFinalized = false;
   
  uint256 public maxEtherCap;  
  uint256 public minEtherCap;  
   
  address[] buyerList;
  mapping (address => bool) inBuyerList;
   
  uint256 refundCompleted;
   
  address newTokenOwner = 0x568E2B5e9643D38e6D8146FeE8d80a1350b2F1B9;
   
  RefundVault public vault;
   
  address devMultisig;
   
  address[] reserveWallet;
   
  modifier canBuyInBlock () {
    require(add(lastCallBlock[msg.sender], maxCallFrequency) < block.number);
    lastCallBlock[msg.sender] = block.number;
    _;
  }
   
  modifier onlyAfterStart() {
    require(now >= startTime && now <= endTime);
    _;
  }
   
  modifier onlyBeforeStart() {
    require(now < startTime);
    _;
  }
   
  modifier onlyRegistered(address _addr) {
    require(kyc.isRegistered(_addr));
    _;
  }
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event PresaleTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event DeferredPresaleTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  event Finalized();
   
  event RegisterPresale(address indexed presaleInvestor, uint256 presaleAmount, uint256 _presaleRate, bool _isDeferred);
   
  event UnregisterPresale(address indexed presaleInvestor);
   
  function PLCCrowdsale(
    address _kyc,
    address _token,
    address _refundVault,
    address _devMultisig,
    address[] _reserveWallet,
    uint64[6] _timelines,  
    uint256 _maxEtherCap,
    uint256 _minEtherCap)
  {
     
    for(uint8 i = 0; i < _timelines.length-1; i++){
      require(_timelines[i] < _timelines[i+1]);
    }
    require(_timelines[0] >= now);
     
    require(_kyc != 0x00 && _token != 0x00 && _refundVault != 0x00 && _devMultisig != 0x00);
    for(i = 0; i < _reserveWallet.length; i++){
      require(_reserveWallet[i] != 0x00);
    }
     
    require(_minEtherCap < _maxEtherCap);
    kyc   = KYC(_kyc);
    token = PLC(_token);
    vault = RefundVault(_refundVault);
    devMultisig   = _devMultisig;
    reserveWallet = _reserveWallet;
    startTime    = _timelines[0];
    endTime      = _timelines[5];
    deadlines[0] = _timelines[1];
    deadlines[1] = _timelines[2];
    deadlines[2] = _timelines[3];
    deadlines[3] = _timelines[4];
    deadlines[4] = _timelines[5];
    maxEtherCap  = _maxEtherCap;
    minEtherCap  = _minEtherCap;
  }
   
  function () payable {
    if(isDeferred[msg.sender])
      buyDeferredPresaleTokens(msg.sender);
    else if(now < startTime)
      buyPresaleTokens(msg.sender);
    else
      buyTokens();
  }
   
  function pushBuyerList(address _addr) internal {
    if (!inBuyerList[_addr]) {
      inBuyerList[_addr] = true;
      buyerList.push(_addr);
    }
  }
   
  function registerPresale(address presaleInvestor, uint256 presaleAmount, uint256 _presaleRate, bool _isDeferred)
    onlyBeforeStart
    onlyOwner
  {
    require(presaleInvestor != 0x00);
    require(presaleAmount > 0);
    require(_presaleRate > 0);
    require(presaleGuaranteedLimit[presaleInvestor] == 0);
    presaleGuaranteedLimit[presaleInvestor] = presaleAmount;
    presaleRate[presaleInvestor] = _presaleRate;
    isDeferred[presaleInvestor] = _isDeferred;
    if(_isDeferred) {
      weiRaised = add(weiRaised, presaleAmount);
      uint256 deferredInvestorToken = mul(presaleAmount, _presaleRate);
      uint256 deferredDevToken = div(mul(deferredInvestorToken, 20), 70);
      uint256 deferredReserveToken = div(mul(deferredInvestorToken, 10), 70);
      uint256 totalAmount = add(deferredInvestorToken, add(deferredDevToken, deferredReserveToken));
      token.mint(address(this), totalAmount);
      deferredTotalTokens = add(deferredTotalTokens, totalAmount);
    }
    RegisterPresale(presaleInvestor, presaleAmount, _presaleRate, _isDeferred);
  }
   
  function unregisterPresale(address presaleInvestor)
    onlyBeforeStart
    onlyOwner
  {
    require(presaleInvestor != 0x00);
    require(presaleGuaranteedLimit[presaleInvestor] > 0);
    uint256 _amount = presaleGuaranteedLimit[presaleInvestor];
    uint256 _rate = presaleRate[presaleInvestor];
    bool _isDeferred = isDeferred[presaleInvestor];
    require(buyerFunded[_isDeferred][presaleInvestor] == 0);
    presaleGuaranteedLimit[presaleInvestor] = 0;
    presaleRate[presaleInvestor] = 0;
    isDeferred[presaleInvestor] = false;
    if(_isDeferred) {
      weiRaised = sub(weiRaised, _amount);
      uint256 deferredInvestorToken = mul(_amount, _rate);
      uint256 deferredDevToken = div(mul(deferredInvestorToken, 20), 70);
      uint256 deferredReserveToken = div(mul(deferredInvestorToken, 10), 70);
      uint256 totalAmount = add(deferredInvestorToken, add(deferredDevToken, deferredReserveToken));
      deferredTotalTokens = sub(deferredTotalTokens, totalAmount);
      token.burn(totalAmount);
    }
    UnregisterPresale(presaleInvestor);
  }
   
  function buyDeferredPresaleTokens(address beneficiary)
    payable
    whenNotPaused
  {
    require(beneficiary != 0x00);
    require(isDeferred[beneficiary]);
    uint guaranteedLimit = presaleGuaranteedLimit[beneficiary];
    require(guaranteedLimit > 0);
    uint256 weiAmount = msg.value;
    require(weiAmount != 0);
    uint256 totalAmount = add(buyerFunded[true][beneficiary], weiAmount);
    uint256 toFund;
    if (totalAmount > guaranteedLimit) {
      toFund = sub(guaranteedLimit, buyerFunded[true][beneficiary]);
    } else {
      toFund = weiAmount;
    }
    require(toFund > 0);
    require(weiAmount >= toFund);
    uint256 tokens = mul(toFund, presaleRate[beneficiary]);
    uint256 toReturn = sub(weiAmount, toFund);
    buy(beneficiary, tokens, toFund, toReturn, true);
     
    uint256 devAmount = div(mul(tokens, 20), 70);
    uint256 reserveAmount = div(mul(tokens, 10), 70);
    distributeToken(devAmount, reserveAmount, true);
     
    uint256 devEtherAmount = div(toFund, 10);
    uint256 reserveEtherAmount = div(mul(toFund, 9), 10);
    distributeEther(devEtherAmount, reserveEtherAmount);
    DeferredPresaleTokenPurchase(msg.sender, beneficiary, toFund, tokens);
  }
   
  function buyPresaleTokens(address beneficiary)
    payable
    whenNotPaused
    onlyBeforeStart
  {
     
    require(beneficiary != 0x00);
    require(validPurchase());
    require(!isDeferred[beneficiary]);
    uint guaranteedLimit = presaleGuaranteedLimit[beneficiary];
    require(guaranteedLimit > 0);
     
    uint256 weiAmount = msg.value;
    uint256 totalAmount = add(buyerFunded[false][beneficiary], weiAmount);
    uint256 toFund;
    if (totalAmount > guaranteedLimit) {
      toFund = sub(guaranteedLimit, buyerFunded[false][beneficiary]);
    } else {
      toFund = weiAmount;
    }
    require(toFund > 0);
    require(weiAmount >= toFund);
    uint256 tokens = mul(toFund, presaleRate[beneficiary]);
    uint256 toReturn = sub(weiAmount, toFund);
    buy(beneficiary, tokens, toFund, toReturn, false);
    forwardFunds(toFund);
    PresaleTokenPurchase(msg.sender, beneficiary, toFund, tokens);
  }
   
  function buyTokens()
    payable
    whenNotPaused
    canBuyInBlock
    onlyAfterStart
    onlyRegistered(msg.sender)
  {
     
    require(validPurchase());
    require(buyerFunded[false][msg.sender] < maxGuaranteedLimit);
     
    uint256 weiAmount = msg.value;
    uint256 totalAmount = add(buyerFunded[false][msg.sender], weiAmount);
    uint256 toFund;
    if (totalAmount > maxGuaranteedLimit) {
      toFund = sub(maxGuaranteedLimit, buyerFunded[false][msg.sender]);
    } else {
      toFund = weiAmount;
    }
    if(add(weiRaised,toFund) > maxEtherCap) {
      toFund = sub(maxEtherCap, weiRaised);
    }
    require(toFund > 0);
    require(weiAmount >= toFund);
    uint256 tokens = mul(toFund, getRate());
    uint256 toReturn = sub(weiAmount, toFund);
    buy(msg.sender, tokens, toFund, toReturn, false);
    forwardFunds(toFund);
    TokenPurchase(msg.sender, msg.sender, toFund, tokens);
  }
   
  function getRate() constant returns (uint256 rate) {
    for(uint8 i = 0; i < deadlines.length; i++)
      if(now < deadlines[i])
        return rates[i];
      return rates[rates.length-1]; 
  }
   
  function getBuyerNumber() constant returns (uint256) {
    return buyerList.length;
  }
   
  function forwardFunds(uint256 toFund) internal {
    vault.deposit.value(toFund)(msg.sender);
  }
   
  function validPurchase() internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase && !maxReached();
  }
  function buy(
    address _beneficiary,
    uint256 _tokens,
    uint256 _toFund,
    uint256 _toReturn,
    bool _isDeferred)
    internal
  {
    if (!_isDeferred) {
      pushBuyerList(msg.sender);
      weiRaised = add(weiRaised, _toFund);
    }
    buyerFunded[_isDeferred][_beneficiary] = add(buyerFunded[_isDeferred][_beneficiary], _toFund);
    if (!_isDeferred) {
      token.mint(address(this), _tokens);
    }
     
    token.grantVestedTokens(
      _beneficiary,
      _tokens,
      uint64(endTime),
      uint64(endTime + 1 weeks),
      uint64(endTime + 1 weeks),
      false,
      false);
     
    if (_toReturn > 0) {
      msg.sender.transfer(_toReturn);
    }
  }
   
  function distributeToken(uint256 devAmount, uint256 reserveAmount, bool _isDeferred) internal {
    uint256 eachReserveAmount = div(reserveAmount, reserveWallet.length);
    token.grantVestedTokens(
      devMultisig,
      devAmount,
      uint64(endTime),
      uint64(endTime),
      uint64(endTime + 1 years),
      false,
      false);
    if (_isDeferred) {
      for(uint8 i = 0; i < reserveWallet.length; i++) {
        token.transfer(reserveWallet[i], eachReserveAmount);
      }
    } else {
      for(uint8 j = 0; j < reserveWallet.length; j++) {
        token.mint(reserveWallet[j], eachReserveAmount);
      }
    }
  }
   
  function distributeEther(uint256 devAmount, uint256 reserveAmount) internal {
    uint256 eachReserveAmount = div(reserveAmount, reserveWallet.length);
    devMultisig.transfer(devAmount);
    for(uint8 i = 0; i < reserveWallet.length; i++){
      reserveWallet[i].transfer(eachReserveAmount);
    }
  }
   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
   
  function finalize() {
    require(!isFinalized);
    require(hasEnded() || maxReached());
    finalization();
    Finalized();
    isFinalized = true;
  }
   
  function finalization() internal {
    if (minReached()) {
      vault.close();
      uint256 totalToken = token.totalSupply();
      uint256 tokenSold = sub(totalToken, deferredTotalTokens);
       
      uint256 devAmount = div(mul(tokenSold, 20), 70);
      uint256 reserveAmount = div(mul(tokenSold, 10), 70);
      token.mint(address(this), devAmount);
      distributeToken(devAmount, reserveAmount, false);
    } else {
      vault.enableRefunds();
    }
    token.finishMinting();
    token.transferOwnership(newTokenOwner);
  }
   
  function finalizeWhenForked() onlyOwner whenPaused {
    require(!isFinalized);
    isFinalized = true;
    vault.enableRefunds();
    token.finishMinting();
  }
   
  function refundAll(uint256 numToRefund) onlyOwner {
    require(isFinalized);
    require(!minReached());
    require(numToRefund > 0);
    uint256 limit = refundCompleted + numToRefund;
    if (limit > buyerList.length) {
      limit = buyerList.length;
    }
    for(uint256 i = refundCompleted; i < limit; i++) {
      vault.refund(buyerList[i]);
    }
    refundCompleted = limit;
  }
   
  function claimRefund(address investor) returns (bool) {
    require(isFinalized);
    require(!minReached());
    return vault.refund(investor);
  }
   
  function maxReached() public constant returns (bool) {
    return weiRaised == maxEtherCap;
  }
   
  function minReached() public constant returns (bool) {
    return weiRaised >= minEtherCap;
  }
   
  function burnUnpaidTokens()
    onlyOwner
  {
    require(isFinalized);
    uint256 unpaidTokens = token.balanceOf(address(this));
    token.burn(unpaidTokens);
  }
}