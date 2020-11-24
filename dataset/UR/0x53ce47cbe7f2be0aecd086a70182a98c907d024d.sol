 

pragma solidity ^0.4.13;

contract Token {
   
   
  uint256 public totalSupply;

   
   
  function balanceOf(address _owner) constant returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) returns (bool success) {
     
     
     
     
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
     
     
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
}

contract EasyMineToken is StandardToken {

  string public constant name = "easyMINE Token";
  string public constant symbol = "EMT";
  uint8 public constant decimals = 18;

  function EasyMineToken(address _icoAddress,
                         address _preIcoAddress,
                         address _easyMineWalletAddress,
                         address _bountyWalletAddress) {
    require(_icoAddress != 0x0);
    require(_preIcoAddress != 0x0);
    require(_easyMineWalletAddress != 0x0);
    require(_bountyWalletAddress != 0x0);

    totalSupply = 33000000 * 10**18;                      

    uint256 icoTokens = 27000000 * 10**18;                

    uint256 preIcoTokens = 2000000 * 10**18;              

    uint256 easyMineTokens = 3000000 * 10**18;            
                                                          
                                                          
                                                          

    uint256 bountyTokens = 1000000 * 10**18;              

    assert(icoTokens + preIcoTokens + easyMineTokens + bountyTokens == totalSupply);

    balances[_icoAddress] = icoTokens;
    Transfer(0, _icoAddress, icoTokens);

    balances[_preIcoAddress] = preIcoTokens;
    Transfer(0, _preIcoAddress, preIcoTokens);

    balances[_easyMineWalletAddress] = easyMineTokens;
    Transfer(0, _easyMineWalletAddress, easyMineTokens);

    balances[_bountyWalletAddress] = bountyTokens;
    Transfer(0, _bountyWalletAddress, bountyTokens);
  }

  function burn(uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      totalSupply -= _value;
      Transfer(msg.sender, 0x0, _value);
      return true;
    } else {
      return false;
    }
  }
}

contract EasyMineTokenWallet {

  uint256 constant public VESTING_PERIOD = 180 days;
  uint256 constant public DAILY_FUNDS_RELEASE = 15000 * 10**18;  

  address public owner;
  address public withdrawalAddress;
  Token public easyMineToken;
  uint256 public startTime;
  uint256 public totalWithdrawn;

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  function EasyMineTokenWallet() {
    owner = msg.sender;
  }

  function setup(address _easyMineToken, address _withdrawalAddress)
    public
    isOwner
  {
    require(_easyMineToken != 0x0);
    require(_withdrawalAddress != 0x0);

    easyMineToken = Token(_easyMineToken);
    withdrawalAddress = _withdrawalAddress;
    startTime = now;
  }

  function withdraw(uint256 requestedAmount)
    public
    isOwner
    returns (uint256 amount)
  {
    uint256 limit = maxPossibleWithdrawal();
    uint256 withdrawalAmount = requestedAmount;
    if (requestedAmount > limit) {
      withdrawalAmount = limit;
    }

    if (withdrawalAmount > 0) {
      if (!easyMineToken.transfer(withdrawalAddress, withdrawalAmount)) {
        revert();
      }
      totalWithdrawn += withdrawalAmount;
    }

    return withdrawalAmount;
  }

  function maxPossibleWithdrawal()
    public
    constant
    returns (uint256)
  {
    if (now < startTime + VESTING_PERIOD) {
      return 0;
    } else {
      uint256 daysPassed = (now - (startTime + VESTING_PERIOD)) / 86400;
      uint256 res = DAILY_FUNDS_RELEASE * daysPassed - totalWithdrawn;
      if (res < 0) {
        return 0;
      } else {
        return res;
      }
    }
  }

}

contract EasyMineIco {

  event TokensSold(address indexed buyer, uint256 amount);
  event TokensReserved(uint256 amount);
  event IcoFinished(uint256 burned);

  struct PriceThreshold {
    uint256 tokenCount;
    uint256 price;
    uint256 tokensSold;
  }

   
  uint256 public maxDuration;

   
  uint256 public minStartDelay;

   
  address public owner;

   
  address public sys;

   
  address public reservationAddress;

   
  address public wallet;

   
  EasyMineToken public easyMineToken;

   
  uint256 public startBlock;

   
  uint256 public endBlock;

   
  PriceThreshold[3] public priceThresholds;

   
  Stages public stage;

  enum Stages {
    Deployed,
    SetUp,
    StartScheduled,
    Started,
    Ended
  }

  modifier atStage(Stages _stage) {
    require(stage == _stage);
    _;
  }

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier isSys() {
    require(msg.sender == sys);
    _;
  }

  modifier isValidPayload() {
    require(msg.data.length == 0 || msg.data.length == 4);
    _;
  }

  modifier timedTransitions() {
    if (stage == Stages.StartScheduled && block.number >= startBlock) {
      stage = Stages.Started;
    }
    if (stage == Stages.Started && block.number >= endBlock) {
      finalize();
    }
    _;
  }

  function EasyMineIco(address _wallet)
    public {
    require(_wallet != 0x0);

    owner = msg.sender;
    wallet = _wallet;
    stage = Stages.Deployed;
  }

   
  function()
    public
    payable
    timedTransitions {
    if (stage == Stages.Started) {
      buyTokens();
    } else {
      revert();
    }
  }

  function setup(address _easyMineToken, address _sys, address _reservationAddress, uint256 _minStartDelay, uint256 _maxDuration)
    public
    isOwner
    atStage(Stages.Deployed)
  {
    require(_easyMineToken != 0x0);
    require(_sys != 0x0);
    require(_reservationAddress != 0x0);
    require(_minStartDelay > 0);
    require(_maxDuration > 0);

    priceThresholds[0] = PriceThreshold(2000000  * 10**18, 0.00070 * 10**18, 0);
    priceThresholds[1] = PriceThreshold(2000000  * 10**18, 0.00075 * 10**18, 0);
    priceThresholds[2] = PriceThreshold(23000000 * 10**18, 0.00080 * 10**18, 0);

    easyMineToken = EasyMineToken(_easyMineToken);
    sys = _sys;
    reservationAddress = _reservationAddress;
    minStartDelay = _minStartDelay;
    maxDuration = _maxDuration;

     
    assert(easyMineToken.balanceOf(this) == maxTokensSold());

    stage = Stages.SetUp;
  }

  function maxTokensSold()
    public
    constant
    returns (uint256) {
    uint256 total = 0;
    for (uint8 i = 0; i < priceThresholds.length; i++) {
      total += priceThresholds[i].tokenCount;
    }
    return total;
  }

  function totalTokensSold()
    public
    constant
    returns (uint256) {
    uint256 total = 0;
    for (uint8 i = 0; i < priceThresholds.length; i++) {
      total += priceThresholds[i].tokensSold;
    }
    return total;
  }

   
  function scheduleStart(uint256 _startBlock)
    public
    isOwner
    atStage(Stages.SetUp)
  {
     
    require(_startBlock > block.number + minStartDelay);

    startBlock = _startBlock;
    endBlock = startBlock + maxDuration;
    stage = Stages.StartScheduled;
  }

  function updateStage()
    public
    timedTransitions
    returns (Stages)
  {
    return stage;
  }

  function buyTokens()
    public
    payable
    isValidPayload
    timedTransitions
    atStage(Stages.Started)
  {
    require(msg.value > 0);

    uint256 amountRemaining = msg.value;
    uint256 tokensToReceive = 0;

    for (uint8 i = 0; i < priceThresholds.length; i++) {
      uint256 tokensAvailable = priceThresholds[i].tokenCount - priceThresholds[i].tokensSold;
      uint256 maxTokensByAmount = amountRemaining * 10**18 / priceThresholds[i].price;

      uint256 tokens;
      if (maxTokensByAmount > tokensAvailable) {
        tokens = tokensAvailable;
        amountRemaining -= (priceThresholds[i].price * tokens) / 10**18;
      } else {
        tokens = maxTokensByAmount;
        amountRemaining = 0;
      }
      priceThresholds[i].tokensSold += tokens;
      tokensToReceive += tokens;
    }

    assert(tokensToReceive > 0);

    if (amountRemaining != 0) {
      assert(msg.sender.send(amountRemaining));
    }

    assert(wallet.send(msg.value - amountRemaining));
    assert(easyMineToken.transfer(msg.sender, tokensToReceive));

    if (totalTokensSold() == maxTokensSold()) {
      finalize();
    }

    TokensSold(msg.sender, tokensToReceive);
  }

  function reserveTokens(uint256 tokenCount)
    public
    isSys
    timedTransitions
    atStage(Stages.Started)
  {
    require(tokenCount > 0);

    uint256 tokensRemaining = tokenCount;

    for (uint8 i = 0; i < priceThresholds.length; i++) {
      uint256 tokensAvailable = priceThresholds[i].tokenCount - priceThresholds[i].tokensSold;

      uint256 tokens;
      if (tokensRemaining > tokensAvailable) {
        tokens = tokensAvailable;
      } else {
        tokens = tokensRemaining;
      }
      priceThresholds[i].tokensSold += tokens;
      tokensRemaining -= tokens;
    }

    uint256 tokensReserved = tokenCount - tokensRemaining;

    assert(easyMineToken.transfer(reservationAddress, tokensReserved));

    if (totalTokensSold() == maxTokensSold()) {
      finalize();
    }

    TokensReserved(tokensReserved);
  }

   
  function cleanup()
    public
    isOwner
    timedTransitions
    atStage(Stages.Ended)
  {
    assert(owner.send(this.balance));
  }

  function finalize()
    private
  {
    stage = Stages.Ended;

     
    uint256 balance = easyMineToken.balanceOf(this);
    easyMineToken.burn(balance);
    IcoFinished(balance);
  }

}