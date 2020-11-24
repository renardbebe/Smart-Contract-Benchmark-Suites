 

pragma solidity ^0.4.13;

 


contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
     
    require(MintableToken(address(token)).mint(_beneficiary, _tokenAmount));
  }
}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract DailyLimitCrowdsale is TimedCrowdsale, Ownable {

    uint256 public dailyLimit;  
    uint256 public stageLimit;  
    uint256 public minDailyPerUser;
    uint256 public maxDailyPerUser;

     
    mapping(uint256 => mapping(address => uint256)) public userSpending;
     
    mapping(uint256 => uint256) public totalSpending;

    uint256 public stageSpending;
     
    constructor(uint256 _minDailyPerUser, uint256 _maxDailyPerUser, uint256 _dailyLimit, uint256 _stageLimit)
    public {
        minDailyPerUser = _minDailyPerUser;
        maxDailyPerUser = _maxDailyPerUser;
        dailyLimit = _dailyLimit;
        stageLimit = _stageLimit;
        stageSpending = 0;
    }

    function setTime(uint256 _openingTime, uint256 _closingTime)
    onlyOwner
    public {
        require(_closingTime >= _openingTime);
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

     
    function _setDailyLimit(uint256 _value) internal {
        dailyLimit = _value;
    }

    function _setMinDailyPerUser(uint256 _value) internal {
        minDailyPerUser = _value;
    }

    function _setMaxDailyPerUser(uint256 _value) internal {
        maxDailyPerUser = _value;
    }

    function _setStageLimit(uint256 _value) internal {
        stageLimit = _value;
    }


     

    function underLimit(address who, uint256 _value) internal returns (bool) {
        require(stageLimit > 0);
        require(minDailyPerUser > 0);
        require(maxDailyPerUser > 0);
        require(_value >= minDailyPerUser);
        require(_value <= maxDailyPerUser);
        uint256 _key = today();
        require(userSpending[_key][who] + _value >= userSpending[_key][who] && userSpending[_key][who] + _value <= maxDailyPerUser);
        if (dailyLimit > 0) {
            require(totalSpending[_key] + _value >= totalSpending[_key] && totalSpending[_key] + _value <= dailyLimit);
        }
        require(stageSpending + _value >= stageSpending && stageSpending + _value <= stageLimit);
        totalSpending[_key] += _value;
        userSpending[_key][who] += _value;
        stageSpending += _value;
        return true;
    }

     
    function today() private view returns (uint256) {
        return now / 1 days;
    }

    modifier limitedDaily(address who, uint256 _value) {
        require(underLimit(who, _value));
        _;
    }
     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    limitedDaily(_beneficiary, _weiAmount)
    internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        require(LendToken(token).deliver(_beneficiary, _tokenAmount));
    }
}

contract LendContract is MintedCrowdsale, DailyLimitCrowdsale {

     
    enum CrowdsaleStage {
        BT,          
        PS,          
        TS_R1,       
        TS_R2,       
        TS_R3,       
        EX,          
        P2P_EX       
    }

    CrowdsaleStage public stage = CrowdsaleStage.PS;  
     

     
     
    uint256 public maxTokens = 120 * 1e6 * 1e18;  
    uint256 public tokensForReserve = 50 * 1e6 * 1e18;  
    uint256 public tokensForBounty = 1 * 1e6 * 1e18;  
    uint256 public totalTokensForTokenSale = 49 * 1e6 * 1e18;  
    uint256 public totalTokensForSaleDuringPreSale = 20 * 1e6 * 1e18;  
     
     
     
    uint256 public constant PRESALE_RATE = 1070;  
    uint256 public constant ROUND_1_TOKENSALE_RATE = 535;  
    uint256 public constant ROUND_2_TOKENSALE_RATE = 389;  
    uint256 public constant ROUND_3_TOKENSALE_RATE = 306;  

     
     
     

    uint256 public constant PRESALE_MIN_DAILY_PER_USER = 5 * 1e18;  
    uint256 public constant PRESALE_MAX_DAILY_PER_USER = 100 * 1e18;  

    uint256 public constant TOKENSALE_MIN_DAILY_PER_USER = 0.1 * 1e18;  
    uint256 public constant TOKENSALE_MAX_DAILY_PER_USER = 10 * 1e18;  


    uint256 public constant ROUND_1_TOKENSALE_LIMIT_PER_DAY = 1.5 * 1e6 * 1e18;  
    uint256 public constant ROUND_1_TOKENSALE_LIMIT = 15 * 1e6 * 1e18;  

    uint256 public constant ROUND_2_TOKENSALE_LIMIT_PER_DAY = 1.5 * 1e6 * 1e18;  
    uint256 public constant ROUND_2_TOKENSALE_LIMIT = 15 * 1e6 * 1e18;  

    uint256 public constant ROUND_3_TOKENSALE_LIMIT_PER_DAY = 1.9 * 1e6 * 1e18;  
    uint256 public constant ROUND_3_TOKENSALE_LIMIT = 19 * 1e6 * 1e18;  

     
    bool public crowdsaleStarted = true;
    bool public crowdsalePaused = false;
     
    event EthTransferred(string text);
    event EthRefunded(string text);

    function LendContract
    (
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _rate,
        address _wallet,
        uint256 _minDailyPerUser,
        uint256 _maxDailyPerUser,
        uint256 _dailyLimit,
        uint256 _stageLimit,
        MintableToken _token
    )
    public
    DailyLimitCrowdsale(_minDailyPerUser, _maxDailyPerUser, _dailyLimit, _stageLimit)
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime) {

    }
    function setCrowdsaleStage(uint value) public onlyOwner {
        require(value > uint(CrowdsaleStage.BT) && value < uint(CrowdsaleStage.EX));
        CrowdsaleStage _stage;
        if (uint(CrowdsaleStage.PS) == value) {
            _stage = CrowdsaleStage.PS;
            setCurrentRate(PRESALE_RATE);
            setMinDailyPerUser(PRESALE_MIN_DAILY_PER_USER);
            setMaxDailyPerUser(PRESALE_MAX_DAILY_PER_USER);
            setStageLimit(totalTokensForSaleDuringPreSale);
        } else if (uint(CrowdsaleStage.TS_R1) == value) {
            _stage = CrowdsaleStage.TS_R2;
            setCurrentRate(ROUND_1_TOKENSALE_RATE);
             
            setDailyLimit(ROUND_1_TOKENSALE_LIMIT_PER_DAY);
            setMinDailyPerUser(TOKENSALE_MIN_DAILY_PER_USER);
            setMaxDailyPerUser(TOKENSALE_MAX_DAILY_PER_USER);
            setStageLimit(ROUND_1_TOKENSALE_LIMIT);
        } else if (uint(CrowdsaleStage.TS_R2) == value) {
            _stage = CrowdsaleStage.TS_R2;
            setCurrentRate(ROUND_2_TOKENSALE_RATE);
             
            setDailyLimit(ROUND_2_TOKENSALE_LIMIT_PER_DAY);
            setMinDailyPerUser(TOKENSALE_MIN_DAILY_PER_USER);
            setMaxDailyPerUser(TOKENSALE_MAX_DAILY_PER_USER);
            setStageLimit(ROUND_2_TOKENSALE_LIMIT);
        } else if (uint(CrowdsaleStage.TS_R3) == value) {
            _stage = CrowdsaleStage.TS_R3;
            setCurrentRate(ROUND_2_TOKENSALE_RATE);
             
            setDailyLimit(ROUND_2_TOKENSALE_LIMIT_PER_DAY);
            setMinDailyPerUser(TOKENSALE_MIN_DAILY_PER_USER);
            setMaxDailyPerUser(TOKENSALE_MAX_DAILY_PER_USER);
            setStageLimit(ROUND_3_TOKENSALE_LIMIT);
        }
        stage = _stage;
    }

     
    function setCurrentRate(uint256 _rate) private {
        rate = _rate;
    }

    function setRate(uint256 _rate) public onlyOwner {
        setCurrentRate(_rate);
    }

    function setCrowdSale(bool _started) public onlyOwner {
        crowdsaleStarted = _started;
    }
     
    function setDailyLimit(uint256 _value) public onlyOwner {
        _setDailyLimit(_value);
    }
    function setMinDailyPerUser(uint256 _value) public onlyOwner {
        _setMinDailyPerUser(_value);
    }

    function setMaxDailyPerUser(uint256 _value) public onlyOwner {
        _setMaxDailyPerUser(_value);
    }
    function setStageLimit(uint256 _value) public onlyOwner {
        _setStageLimit(_value);
    }
    function pauseCrowdsale() public onlyOwner {
        crowdsalePaused = true;
    }

    function unPauseCrowdsale() public onlyOwner {
        crowdsalePaused = false;
    }
     
     
     

    function finish(address _reserveFund) public onlyOwner {
        if (crowdsaleStarted) {
            uint256 alreadyMinted = token.totalSupply();
            require(alreadyMinted < maxTokens);

            uint256 unsoldTokens = totalTokensForTokenSale - alreadyMinted;
            if (unsoldTokens > 0) {
                tokensForReserve = tokensForReserve + unsoldTokens;
            }
            MintableToken(token).mint(_reserveFund, tokensForReserve);
            crowdsaleStarted = false;
        }
    }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract LendToken is MintableToken {
    string public name = "LENDXCOIN";
    string public symbol = "XCOIN";
    uint8 public decimals = 18;
    address public contractAddress;
    uint256 public fee;

    uint256 public constant FEE_TRANSFER = 5 * 1e15;  

    uint256 public constant INITIAL_SUPPLY = 51 * 1e6 * (10 ** uint256(decimals));  

     
    event ChangedFee(address who, uint256 newFee);

     
    function LendToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        fee = FEE_TRANSFER;
    }

    function setContractAddress(address _contractAddress) external onlyOwner {
        if (_contractAddress != address(0)) {
            contractAddress = _contractAddress;
        }
    }

    function deliver(
        address _beneficiary,
        uint256 _tokenAmount
    )
    public
    returns (bool success)
    {
        require(_tokenAmount > 0);
        require(msg.sender == contractAddress);
        balances[_beneficiary] += _tokenAmount;
        totalSupply_ += _tokenAmount;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (msg.sender == owner) {
            return super.transfer(_to, _value);
        } else {
            require(fee <= balances[msg.sender]);
            balances[owner] = balances[owner].add(fee);
            balances[msg.sender] = balances[msg.sender].sub(fee);
            return super.transfer(_to, _value - fee);
        }
    }

    function setFee(uint256 _fee)
    onlyOwner
    public
    {
        fee = _fee;
        emit ChangedFee(msg.sender, _fee);
    }

}