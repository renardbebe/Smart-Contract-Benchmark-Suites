 

pragma solidity ^0.4.18;

 

 
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
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

 

 
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

contract HieToken is BasicToken, BurnableToken, CappedToken {
  using SafeMath for uint256;

  string public constant name = 'HIU TOKEN';

  string public constant symbol = 'HIE';

  uint public constant decimals = 18;

  uint256 constant CAP = 2000000000 * (10 ** decimals);

  function HieToken()
    public
    CappedToken(CAP)
  {
  }
}

 

 

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }
  
   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

   
  function withdrawTokens() public {
    require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
  }
}

 

 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
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

   
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

   
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
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

 

 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

   
  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

   
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
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

 

contract HieCrowdsale is Crowdsale, CappedCrowdsale, RefundableCrowdsale, PostDeliveryCrowdsale, Pausable {

  uint256 constant RATE_SALE_1 = 40650;
  uint256 constant RATE_SALE_2 = 27100;
  uint256 constant RATE_SALE_3 = 20325;

  uint256 constant CAP_SALE_1 = 9850 ether;
  uint256 constant CAP_SALE_2 = 7400 ether;
  uint256 constant CAP_SALE_3 = 9850 ether;
  uint256 constant CAP = 27100 ether;

  uint256 constant GOAL = 750 ether;

  uint256 constant INITIAL_ALLOCATE_TOKEN = 1198856250 * (10 ** 18);

  uint256 constant MINIMUM_WEI_AMOUNT_SALE_1 = 200 ether;
  uint256 constant MINIMUM_WEI_AMOUNT_SALE_2 = 1 ether;

  uint256 public startTimeSale1;
  uint256 public endTimeSale1;

  uint256 public startTimeSale2;
  uint256 public endTimeSale2;

  uint256 public startTimeSale3;
  uint256 public endTimeSale3;

  uint256 public totalWeiAmountSale1;
  uint256 public totalWeiAmountSale2;
  uint256 public totalWeiAmountSale3;

  uint256 public initialFundBalance;
  bool public isInitialAllocated = false;

  function HieCrowdsale(
    uint256 _startTime,
    uint256 _endTime,
    uint256[] _startTimeSales,
    uint256[] _endTimeSales,
    HieToken _token,
    address _wallet
  )
    public
    Crowdsale(RATE_SALE_1, _wallet, _token)
    TimedCrowdsale(_startTime, _endTime)
    CappedCrowdsale(CAP)
    RefundableCrowdsale(GOAL)
  {
    require(_startTimeSales.length == 3);
    require(_endTimeSales.length == 3);

    startTimeSale1 = _startTimeSales[0];
    endTimeSale1 = _endTimeSales[0];
    startTimeSale2 = _startTimeSales[1];
    endTimeSale2 = _endTimeSales[1];
    startTimeSale3 = _startTimeSales[2];
    endTimeSale3 = _endTimeSales[2];
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 currentRate = rate;

    if (sale1Accepting()) {
      currentRate = RATE_SALE_1;
    } else if (sale2Accepting()) {
      currentRate = RATE_SALE_2;
    } else {
      currentRate = RATE_SALE_3;
    }

    return _weiAmount.mul(currentRate);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    require(!paused);
    require(saleAccepting());

    if (sale1Accepting()) {
      require(_weiAmount >= MINIMUM_WEI_AMOUNT_SALE_1);
      require(totalWeiAmountSale1.add(_weiAmount) <= CAP_SALE_1);
    } else if (sale2Accepting()) {
      require(_weiAmount >= MINIMUM_WEI_AMOUNT_SALE_2);
      require(totalWeiAmountSale2.add(_weiAmount) <= CAP_SALE_2);
    } else {
      require(totalWeiAmountSale3.add(_weiAmount) <= CAP_SALE_3);
    }

    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    if (sale1Accepting()) {
      totalWeiAmountSale1 = totalWeiAmountSale1.add(_weiAmount);
    } else if (sale2Accepting()) {
      totalWeiAmountSale2 = totalWeiAmountSale2.add(_weiAmount);
    } else {
      totalWeiAmountSale3 = totalWeiAmountSale3.add(_weiAmount);
    }

    super._updatePurchasingState(_beneficiary, _weiAmount);
  }

  function sale1Accepting() internal view returns (bool) {
    return startTimeSale1 <= now && now <= endTimeSale1;
  }

  function sale2Accepting() internal view returns (bool) {
    return startTimeSale2 <= now && now <= endTimeSale2;
  }

  function sale3Accepting() internal view returns (bool) {
    return startTimeSale3 <= now && now <= endTimeSale3;
  }

  function saleAccepting() internal view returns (bool) {
    return sale1Accepting() || sale2Accepting() || sale3Accepting();
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    HieToken(token).mint(this, _tokenAmount);
    super._processPurchase(_beneficiary, _tokenAmount);
  }

  function initialAllocation() public onlyOwner {
    require(!isInitialAllocated);

    HieToken(token).mint(wallet, INITIAL_ALLOCATE_TOKEN);

    isInitialAllocated = true;
  }

  function finalization() internal {
    HieToken(token).transferOwnership(wallet);
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }

  function withdrawTokens() public {
    require(isFinalized);
    require(goalReached());
    super.withdrawTokens();
  }
}