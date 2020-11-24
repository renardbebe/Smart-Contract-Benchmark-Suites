 

pragma solidity ^0.4.13;

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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
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

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract MenloSaleBase is Ownable {
  using SafeMath for uint256;

   
  mapping (address => bool) public whitelist;

   
  address public whitelister;

   
  bool public isFinalized;

   
  uint256 public cap;

   
  MenloToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  modifier onlyWhitelister() {
    require(msg.sender == whitelister, "Sender should be whitelister");
    _;
  }

   
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

   
  event TokenRedeem(address indexed purchaser, uint256 amount);

   
  event Finalized();

  event TokensRefund(uint256 amount);

   
  event Refund(address indexed purchaser, uint256 amount);

  constructor(
      MenloToken _token,
      uint256 _startTime,
      uint256 _endTime,
      uint256 _cap,
      address _wallet
  ) public {
    require(_startTime >= getBlockTimestamp(), "Start time should be in the future");
    require(_endTime >= _startTime, "End time should be after start time");
    require(_wallet != address(0), "Wallet address should be non-zero");
    require(_token != address(0), "Token address should be non-zero");
    require(_cap > 0, "Cap should be greater than zero");

    token = _token;

    startTime = _startTime;
    endTime = _endTime;
    cap = _cap;
    wallet = _wallet;
  }

   
  function () public payable {
    buyTokens();
  }

   
  function calculateBonusRate() public view returns (uint256);
  function buyTokensHook(uint256 _tokens) internal;

  function buyTokens() public payable returns (uint256) {
    require(whitelist[msg.sender], "Expected msg.sender to be whitelisted");
    checkFinalize();
    require(!isFinalized, "Should not be finalized when purchasing");
    require(getBlockTimestamp() >= startTime && getBlockTimestamp() <= endTime, "Should be during sale");
    require(msg.value != 0, "Value should not be zero");
    require(token.balanceOf(this) > 0, "This contract must have tokens");

    uint256 _weiAmount = msg.value;

    uint256 _remainingToFund = cap.sub(weiRaised);
    if (_weiAmount > _remainingToFund) {
      _weiAmount = _remainingToFund;
    }

    uint256 _totalTokens = _weiAmount.mul(calculateBonusRate());
    if (_totalTokens > token.balanceOf(this)) {
       
      _weiAmount = token.balanceOf(this).div(calculateBonusRate());
    }

    token.unpause();
    weiRaised = weiRaised.add(_weiAmount);

    forwardFunds(_weiAmount);
    uint256 _weiToReturn = msg.value.sub(_weiAmount);
    if (_weiToReturn > 0) {
      msg.sender.transfer(_weiToReturn);
      emit Refund(msg.sender, _weiToReturn);
    }

    uint256 _tokens = ethToTokens(_weiAmount);
    emit TokenPurchase(msg.sender, _weiAmount, _tokens);
    buyTokensHook(_tokens);
    token.pause();

    checkFinalize();

    return _tokens;
  }

   
  function refund() external onlyOwner returns (bool) {
    require(hasEnded(), "Sale should have ended when refunding");
    uint256 _tokens = token.balanceOf(address(this));

    if (_tokens == 0) {
      return false;
    }

    require(token.transfer(owner, _tokens), "Expected token transfer to succeed");

    emit TokensRefund(_tokens);

    return true;
  }

   
   
   
  function whitelistAddresses(address[] _addresses, bool _status) public onlyWhitelister {
    for (uint256 i = 0; i < _addresses.length; i++) {
      address _investorAddress = _addresses[i];
      if (whitelist[_investorAddress] != _status) {
        whitelist[_investorAddress] = _status;
      }
    }
  }

  function setWhitelister(address _whitelister) public onlyOwner {
    whitelister = _whitelister;
  }

  function checkFinalize() public {
    if (hasEnded()) {
      finalize();
    }
  }

  function emergencyFinalize() public onlyOwner {
    finalize();
  }

  function withdraw() public onlyOwner {
    owner.transfer(address(this).balance);
  }

  function hasEnded() public constant returns (bool) {
    if (isFinalized) {
      return true;
    }
    bool _capReached = weiRaised >= cap;
    bool _passedEndTime = getBlockTimestamp() > endTime;
    return _passedEndTime || _capReached;
  }

   
   
   
  function finalize() internal {
    require(!isFinalized, "Should not be finalized when finalizing");
    emit Finalized();
    isFinalized = true;
    token.transferOwnership(owner);
  }

   
   
  function forwardFunds(uint256 _amount) internal {
    wallet.transfer(_amount);
  }

  function ethToTokens(uint256 _ethAmount) internal view returns (uint256) {
    return _ethAmount.mul(calculateBonusRate());
  }

  function getBlockTimestamp() internal view returns (uint256) {
    return block.timestamp;
  }
}

contract MenloToken is PausableToken, BurnableToken, CanReclaimToken {

   
  string public constant name = 'Menlo One';
  string public constant symbol = 'ONE';

  uint8 public constant decimals = 18;
  uint256 private constant token_factor = 10**uint256(decimals);

   
  uint256 public constant INITIAL_SUPPLY    = 1000000000 * token_factor;

  uint256 public constant PUBLICSALE_SUPPLY = 354000000 * token_factor;
  uint256 public constant GROWTH_SUPPLY     = 246000000 * token_factor;
  uint256 public constant TEAM_SUPPLY       = 200000000 * token_factor;
  uint256 public constant ADVISOR_SUPPLY    = 100000000 * token_factor;
  uint256 public constant PARTNER_SUPPLY    = 100000000 * token_factor;

   
  bytes4 internal constant ONE_RECEIVED = 0x150b7a03;

  address public crowdsale;
  address public teamTimelock;
  address public advisorTimelock;

  modifier notInitialized(address saleAddress) {
    require(address(saleAddress) == address(0), "Expected address to be null");
    _;
  }

  constructor(address _growth, address _teamTimelock, address _advisorTimelock, address _partner) public {
    assert(INITIAL_SUPPLY > 0);
    assert((PUBLICSALE_SUPPLY + GROWTH_SUPPLY + TEAM_SUPPLY + ADVISOR_SUPPLY + PARTNER_SUPPLY) == INITIAL_SUPPLY);

    uint256 _poolTotal = GROWTH_SUPPLY + TEAM_SUPPLY + ADVISOR_SUPPLY + PARTNER_SUPPLY;
    uint256 _availableForSales = INITIAL_SUPPLY - _poolTotal;

    assert(_availableForSales == PUBLICSALE_SUPPLY);

    teamTimelock = _teamTimelock;
    advisorTimelock = _advisorTimelock;

    mint(msg.sender, _availableForSales);
    mint(_growth, GROWTH_SUPPLY);
    mint(_teamTimelock, TEAM_SUPPLY);
    mint(_advisorTimelock, ADVISOR_SUPPLY);
    mint(_partner, PARTNER_SUPPLY);

    assert(totalSupply_ == INITIAL_SUPPLY);
    pause();
  }

  function initializeCrowdsale(address _crowdsale) public onlyOwner notInitialized(crowdsale) {
    unpause();
    transfer(_crowdsale, balances[msg.sender]);   
    crowdsale = _crowdsale;
    pause();
    transferOwnership(_crowdsale);
  }

  function mint(address _to, uint256 _amount) internal {
    balances[_to] = _amount;
    totalSupply_ = totalSupply_.add(_amount);
    emit Transfer(address(0), _to, _amount);
  }

   
  function transferAndCall(address _to, uint256 _value, uint256 _action, bytes _data) public returns (bool) {
    if (transfer(_to, _value)) {
      require (MenloTokenReceiver(_to).onTokenReceived(msg.sender, _value, _action, _data) == ONE_RECEIVED, "Target contract onTokenReceived failed");
      return true;
    }

    return false;
  }
}

contract MenloTokenReceiver {

     
    MenloToken token;

    constructor(MenloToken _tokenContract) public {
        token = _tokenContract;
    }

     
    bytes4 internal constant ONE_RECEIVED = 0x150b7a03;

     
    modifier onlyTokenContract() {
        require(msg.sender == address(token));
        _;
    }

     
    function onTokenReceived(
        address _from,
        uint256 _value,
        uint256 _action,
        bytes _data
    ) public   returns(bytes4);
}

contract MenloTokenSale is MenloSaleBase {

   
  uint256 public HOUR1;
  uint256 public WEEK1;
  uint256 public WEEK2;
  uint256 public WEEK3;
  uint256 public WEEK4;

  constructor(
    MenloToken _token,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _cap,
    address _wallet
  ) MenloSaleBase(
    _token,
    _startTime,
    _endTime,
    _cap,
    _wallet
  ) public {
    HOUR1 = startTime + 1 hours;
    WEEK1 = startTime + 1 weeks;
    WEEK2 = startTime + 2 weeks;
    WEEK3 = startTime + 3 weeks;
  }

   
   
   
   
   
  function calculateBonusRate() public view returns (uint256) {
    uint256 _bonusRate = 12000;

    uint256 _currentTime = getBlockTimestamp();
    if (_currentTime > startTime && _currentTime <= HOUR1) {
      _bonusRate =  15600;
    } else if (_currentTime <= WEEK1) {
      _bonusRate =  13800;  
    } else if (_currentTime <= WEEK2) {
      _bonusRate =  13200;  
    } else if (_currentTime <= WEEK3) {
      _bonusRate =  12600;  
    }
    return _bonusRate;
  }

  function buyTokensHook(uint256 _tokens) internal {
    token.transfer(msg.sender, _tokens);
    emit TokenRedeem(msg.sender, _tokens);
  }
}