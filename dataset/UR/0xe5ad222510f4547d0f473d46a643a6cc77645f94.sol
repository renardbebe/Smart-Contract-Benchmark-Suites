 

pragma solidity ^0.4.24;

 

 
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

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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

   
  constructor(address _wallet) public {
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
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

 

contract IpoVault is RefundVault {
  using SafeMath for uint256;

  address platformWallet;
  uint platformFee;
  constructor(address _wallet, address _platformWallet, uint _platformFee) public  RefundVault(_wallet) {
    platformWallet = _platformWallet;
    platformFee = _platformFee;
  }

  function close() onlyOwner public {
    require(state == State.Active);
    uint platformReward = address(this).balance.mul(platformFee).div(100);
    platformWallet.transfer(platformReward);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
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
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

 

contract BaseToken is MintableToken, PausableToken {

  string public name;  
  string public symbol;  
  uint8 public constant decimals = 0;  
  uint public cap;

  mapping(address => uint256) dividendBalanceOf;
  uint256 public dividendPerToken;
  mapping(address => uint256) dividendCreditedTo;

  constructor(uint _cap, string _name, string _symbol) public {
    cap = _cap * (10 ** uint256(decimals));
    name = _name;
    symbol = _symbol;
    pause();
  }

  function increaseTokenCap(uint _additionalTokensAmount) onlyOwner public {
    cap = cap.add(_additionalTokensAmount);
  }

  function capReached() public view returns (bool) {
    return totalSupply_ >= cap;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    return super.mint(_to, _amount);
  }

  function isTokenHolder(address _address) public constant returns (bool) {
    return balanceOf(_address) > 0;
  }

  function updateDividends(address account) internal {
    uint256 owed = dividendPerToken.sub(dividendCreditedTo[account]);
    dividendBalanceOf[account] = dividendBalanceOf[account].add(balanceOf(account).mul(owed));
    dividendCreditedTo[account] = dividendPerToken;
  }

  function depositDividends() public payable onlyOwner {
    dividendPerToken = dividendPerToken.add(msg.value.div(totalSupply_));
  }

  function claimDividends() public {
    require(isTokenHolder(msg.sender));
    updateDividends(msg.sender);
    uint256 amount = dividendBalanceOf[msg.sender];
    dividendBalanceOf[msg.sender] = 0;
    msg.sender.transfer(amount);
  }
}

 

contract BaseIPO is Ownable {
  using SafeMath for uint256;

  address wallet;

  bool public success = false;
  bool public isFinalized = false;

  enum Result {InProgress, Success, Failure}
  Result public result = Result.InProgress;

  enum State {Closed, IPO}
  State public state = State.Closed;

  uint public endTime;

  uint public tokenPrice;
  IpoVault public vault;
  BaseToken public token;

  event EventAdditionalSaleStarted(address ipoAddress, uint startTime);
  event EventRefundSuccess(address ipoAddress, address beneficiary);
  event EventBuyTokens(address ipoAddress, uint tokens, address beneficiary, uint weiAmount, uint tokenPrice);
  event EventCreateIpoSuccess(address ipoContractAddress, address contractOwner, address tokenAddress);
  event EventIpoFinalized(address ipoAddress, Result result);

  constructor (
    address _owner,
    address _wallet,
    address _platformWallet,
    uint _tokenGoal,
    uint _tokenPrice,
    string _tokenName,
    string _tokenSymbol,
    uint _ipoPeriodInDays,
    uint _platformFee
  ) public {
    require(_ipoPeriodInDays > 0);
    require(_tokenPrice > 0);
    require(_tokenGoal > 0);
    require(_wallet != address(0));
    transferOwnership(_owner);
    wallet = _wallet;
    vault = new IpoVault(_wallet, _platformWallet, _platformFee);
    token = new BaseToken(_tokenGoal, _tokenName, _tokenSymbol);
    tokenPrice = _tokenPrice;
    endTime = now.add(_ipoPeriodInDays.mul(1 days));
    state = State.IPO;
    emit EventCreateIpoSuccess(address(this), _owner, token);
  }

  function getTokenAmount(uint weiAmount) internal view returns (uint) {
    return weiAmount.div(tokenPrice);
  }

  function isIpoPeriodOver() public view returns (bool) {
    return now >= endTime;
  }

  function buyTokens(address _beneficiary) public payable {
    uint weiAmount = msg.value;
    require(_beneficiary != address(0));
    require(weiAmount > 0);
    require(!token.capReached());
    require(!isIpoPeriodOver());
    require(state == State.IPO);
    uint tokens = getTokenAmount(weiAmount);
    token.mint(_beneficiary, tokens);
    vault.deposit.value(msg.value)(msg.sender);
    if (token.capReached()) {
      finalizeIPO();
    }
    emit EventBuyTokens(address(this), tokens, msg.sender, weiAmount, tokenPrice);
  }

  function finalizeIPO() internal {
    if (token.capReached()) {
      result = Result.Success;
      vault.close();
      token.unpause();
    } else {
      result = Result.Failure;
      vault.enableRefunds();
    }
    state = State.Closed;
    isFinalized = true;
    emit EventIpoFinalized(address(this), result);
  }

  function claimRefund() public {
    require(token.isTokenHolder(msg.sender));
    if (isIpoPeriodOver() && !isFinalized) {
      finalizeIPO();
    }
    require(isFinalized);
    require(!token.capReached());
    vault.refund(msg.sender);
    emit EventRefundSuccess(address(this), msg.sender);
  }

  function payDividends() payable external onlyOwner {
    require(result == Result.Success);
    token.depositDividends.value(msg.value)();
  }

  function() external payable {
    buyTokens(msg.sender);
  }
}

 

contract IpoCreator {
  address public platformAddress = 0xB23167b1941A4fe6C4864f97281099425B07A5c0;
  uint public ipoPeriodInDays = 30;
  uint public platformFee = 5;

  function createIpo(address _wallet, uint _tokenGoal, uint _tokenPrice, string _tokenName, string _tokenSymbol) public {
    new BaseIPO(msg.sender, _wallet, platformAddress, _tokenGoal, _tokenPrice, _tokenName, _tokenSymbol, ipoPeriodInDays, platformFee);
  }
}