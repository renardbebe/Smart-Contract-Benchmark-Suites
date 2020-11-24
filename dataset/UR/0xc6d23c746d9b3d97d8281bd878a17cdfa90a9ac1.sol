 

pragma solidity 0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

contract CustomPOAToken is PausableToken {

  string public name;
  string public symbol;

  uint8 public constant decimals = 18;

  address public owner;
  address public broker;
  address public custodian;

  uint256 public creationBlock;
  uint256 public timeoutBlock;
   
  uint256 public totalPerTokenPayout;
  uint256 public tokenSaleRate;
  uint256 public fundedAmount;
  uint256 public fundingGoal;
  uint256 public initialSupply;
   
  uint256 public constant feeRate = 5;

   
  mapping (address => bool) public whitelisted;
   
  mapping(address => uint256) public claimedPerTokenPayouts;
   
  mapping(address => uint256) public unclaimedPayoutTotals;

  enum Stages {
    Funding,
    Pending,
    Failed,
    Active,
    Terminated
  }

  Stages public stage = Stages.Funding;

  event StageEvent(Stages stage);
  event BuyEvent(address indexed buyer, uint256 amount);
  event PayoutEvent(uint256 amount);
  event ClaimEvent(uint256 payout);
  event TerminatedEvent();
  event WhitelistedEvent(address indexed account, bool isWhitelisted);

  modifier isWhitelisted() {
    require(whitelisted[msg.sender]);
    _;
  }

  modifier onlyCustodian() {
    require(msg.sender == custodian);
    _;
  }

   
  modifier atStage(Stages _stage) {
    require(stage == _stage);
    _;
  }

  modifier atEitherStage(Stages _stage, Stages _orStage) {
    require(stage == _stage || stage == _orStage);
    _;
  }

  modifier checkTimeout() {
    if (stage == Stages.Funding && block.number >= creationBlock.add(timeoutBlock)) {
      uint256 _unsoldBalance = balances[this];
      balances[this] = 0;
      totalSupply = totalSupply.sub(_unsoldBalance);
      Transfer(this, address(0), balances[this]);
      enterStage(Stages.Failed);
    }
    _;
  }
   

   
  function CustomPOAToken
  (
    string _name,
    string _symbol,
    address _broker,
    address _custodian,
    uint256 _timeoutBlock,
    uint256 _totalSupply,
    uint256 _fundingGoal
  )
    public
  {
    require(_fundingGoal > 0);
    require(_totalSupply > _fundingGoal);
    owner = msg.sender;
    name = _name;
    symbol = _symbol;
    broker = _broker;
    custodian = _custodian;
    timeoutBlock = _timeoutBlock;
    creationBlock = block.number;
     
    totalSupply = _totalSupply;
    initialSupply = _totalSupply;
    fundingGoal = _fundingGoal;
    balances[this] = _totalSupply;
    paused = true;
  }

   

   

   
   
   
  function weiToTokens(uint256 _weiAmount)
    public
    view
    returns (uint256)
  {
    return _weiAmount
      .mul(1e18)
      .mul(initialSupply)
      .div(fundingGoal)
      .div(1e18);
  }

   
   
   
  function tokensToWei(uint256 _tokenAmount)
    public
    view
    returns (uint256)
  {
    return _tokenAmount
      .mul(1e18)
      .mul(fundingGoal)
      .div(initialSupply)
      .div(1e18);
  }

   

   
  function unpause()
    public
    onlyOwner
    whenPaused
  {
     
    require(stage == Stages.Active);
    return super.unpause();
  }

   
  function enterStage(Stages _stage)
    private
  {
    stage = _stage;
    StageEvent(_stage);
  }

   

   
  function whitelistAddress(address _address)
    external
    onlyOwner
    atStage(Stages.Funding)
  {
    require(whitelisted[_address] != true);
    whitelisted[_address] = true;
    WhitelistedEvent(_address, true);
  }

   
  function blacklistAddress(address _address)
    external
    onlyOwner
    atStage(Stages.Funding)
  {
    require(whitelisted[_address] != false);
    whitelisted[_address] = false;
    WhitelistedEvent(_address, false);
  }

   
  function whitelisted(address _address)
    public
    view
    returns (bool)
  {
    return whitelisted[_address];
  }

   

   

   
  function calculateFee(uint256 _value)
    public
    view
    returns (uint256)
  {
    return feeRate.mul(_value).div(1000);
  }

   

   

  function buy()
    public
    payable
    checkTimeout
    atStage(Stages.Funding)
    isWhitelisted
    returns (bool)
  {
    uint256 _payAmount;
    uint256 _buyAmount;
     
    if (fundedAmount.add(msg.value) < fundingGoal) {
       
      _payAmount = msg.value;
       
      _buyAmount = weiToTokens(_payAmount);
       
       
       
      require(_buyAmount > 0);
    } else {
       
      enterStage(Stages.Pending);
       
      uint256 _refundAmount = fundedAmount.add(msg.value).sub(fundingGoal);
       
      _payAmount = msg.value.sub(_refundAmount);
       
      _buyAmount = weiToTokens(_payAmount);
       
      uint256 _dust = balances[this].sub(_buyAmount);
       
      balances[this] = balances[this].sub(_dust);
       
      balances[owner] = balances[owner].add(_dust);
      Transfer(this, owner, _dust);
       
      msg.sender.transfer(_refundAmount);
    }
     
    balances[this] = balances[this].sub(_buyAmount);
     
    balances[msg.sender] = balances[msg.sender].add(_buyAmount);
     
    fundedAmount = fundedAmount.add(_payAmount);
     
    Transfer(this, msg.sender, _buyAmount);
    BuyEvent(msg.sender, _buyAmount);
    return true;
  }

  function activate()
    external
    checkTimeout
    onlyCustodian
    payable
    atStage(Stages.Pending)
    returns (bool)
  {
     
    uint256 _fee = calculateFee(fundingGoal);
     
    require(msg.value == _fee);
     
    enterStage(Stages.Active);
     
    unclaimedPayoutTotals[owner] = unclaimedPayoutTotals[owner].add(_fee);
     
     
     
    unclaimedPayoutTotals[custodian] = unclaimedPayoutTotals[custodian]
      .add(this.balance.sub(_fee));
     
    paused = false;
     
    Unpause();
    return true;
  }

   
   
  function terminate()
    external
    onlyCustodian
    atStage(Stages.Active)
    returns (bool)
  {
     
    enterStage(Stages.Terminated);
     
    paused = true;
     
    TerminatedEvent();
  }

   
   
  function kill()
    external
    onlyOwner
  {
     
    paused = true;
     
    enterStage(Stages.Terminated);
     
    owner.transfer(this.balance);
     
    TerminatedEvent();
  }

   

   

   
  function currentPayout(address _address, bool _includeUnclaimed)
    public
    view
    returns (uint256)
  {
     
    uint256 _totalPerTokenUnclaimedConverted = totalPerTokenPayout == 0
      ? 0
      : balances[_address]
      .mul(totalPerTokenPayout.sub(claimedPerTokenPayouts[_address]))
      .div(1e18);

     
    return _includeUnclaimed
      ? _totalPerTokenUnclaimedConverted.add(unclaimedPayoutTotals[_address])
      : _totalPerTokenUnclaimedConverted;

  }

   
   
  function settleUnclaimedPerTokenPayouts(address _from, address _to)
    private
    returns (bool)
  {
     
    unclaimedPayoutTotals[_from] = unclaimedPayoutTotals[_from].add(currentPayout(_from, false));
     
    claimedPerTokenPayouts[_from] = totalPerTokenPayout;
     
    unclaimedPayoutTotals[_to] = unclaimedPayoutTotals[_to].add(currentPayout(_to, false));
     
    claimedPerTokenPayouts[_to] = totalPerTokenPayout;
    return true;
  }

   
   
  function setFailed()
    external
    atStage(Stages.Funding)
    checkTimeout
    returns (bool)
  {
    if (stage == Stages.Funding) {
      revert();
    }
    return true;
  }

   
  function reclaim()
    external
    checkTimeout
    atStage(Stages.Failed)
    returns (bool)
  {
     
    uint256 _tokenBalance = balances[msg.sender];
     
    require(_tokenBalance > 0);
     
    balances[msg.sender] = 0;
     
    totalSupply = totalSupply.sub(_tokenBalance);
    Transfer(msg.sender, address(0), _tokenBalance);
     
    fundedAmount = fundedAmount.sub(tokensToWei(_tokenBalance));
     
    uint256 _reclaimTotal = tokensToWei(_tokenBalance);
     
    msg.sender.transfer(_reclaimTotal);
    return true;
  }

   
  function payout()
    external
    payable
    atEitherStage(Stages.Active, Stages.Terminated)
    onlyCustodian
    returns (bool)
  {
     
    uint256 _fee = calculateFee(msg.value);
     
    require(_fee > 0);
     
    uint256 _payoutAmount = msg.value.sub(_fee);
     
    totalPerTokenPayout = totalPerTokenPayout
      .add(_payoutAmount
        .mul(1e18)
        .div(totalSupply)
      );

     
     
    uint256 _delta = (_payoutAmount.mul(1e18) % totalSupply).div(1e18);
    unclaimedPayoutTotals[owner] = unclaimedPayoutTotals[owner].add(_fee).add(_delta);
     
    PayoutEvent(_payoutAmount);
    return true;
  }

   
  function claim()
    external
    atEitherStage(Stages.Active, Stages.Terminated)
    returns (uint256)
  {
     
    uint256 _payoutAmount = currentPayout(msg.sender, true);
     
    require(_payoutAmount > 0);
     
     
    claimedPerTokenPayouts[msg.sender] = totalPerTokenPayout;
     
    unclaimedPayoutTotals[msg.sender] = 0;
     
    ClaimEvent(_payoutAmount);
     
    msg.sender.transfer(_payoutAmount);
    return _payoutAmount;
  }

   

   

   
  function transfer
  (
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
     
    require(settleUnclaimedPerTokenPayouts(msg.sender, _to));
    return super.transfer(_to, _value);
  }

   
  function transferFrom
  (
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
     
    require(settleUnclaimedPerTokenPayouts(_from, _to));
    return super.transferFrom(_from, _to, _value);
  }

   

   
   
  function()
    public
    payable
  {
    buy();
  }
}