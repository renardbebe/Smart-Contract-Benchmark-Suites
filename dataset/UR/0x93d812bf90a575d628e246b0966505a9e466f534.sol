 

pragma solidity ^0.4.11;

 
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

  function deposit(address buyer) onlyOwner payable {
    require(state == State.Active);
    deposited[buyer] = deposited[buyer].add(msg.value);
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

  function refund(address buyer) {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[buyer];
    deposited[buyer] = 0;
    buyer.transfer(depositedValue);
    Refunded(buyer, depositedValue);
  }
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
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

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

 
contract CirclesTokenOffering is Ownable {
  using SafeMath for uint256;

   
  mapping (address => uint256) allocations;

   
  bool public isFinalized = false;

   
  uint256 public cap;

   
  uint256 public goal;

   
  RefundVault public vault;

   
  StandardToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  address public safe;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  event TokenRedeem(address indexed beneficiary, uint256 amount);

   
  event Finalized();

  function CirclesTokenOffering(address _token, uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, address _wallet) {

    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_cap > 0);
    require(_wallet != 0x0);
    require(_goal > 0);

    vault = new RefundVault(_wallet);
    goal = _goal;
    token = StandardToken(_token);
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    cap = _cap;
    goal = _goal;
    wallet = _wallet;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

     
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

     
    allocations[beneficiary] = tokens;

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function claimTokens() {
    require(isFinalized);
    require(goalReached());

     
    uint256 amount = token.balanceOf(this);
    require(amount > 0);

     
    uint256 tokens = allocations[msg.sender];
    allocations[msg.sender] = 0;
    require(token.transfer(msg.sender, tokens));

    TokenRedeem(msg.sender, tokens);
  }

   
  function sendTokens(address beneficiary) onlyOwner {
    require(isFinalized);
    require(goalReached());

     
    uint256 amount = token.balanceOf(this);
    require(amount > 0);

     
    uint256 tokens = allocations[beneficiary];
    allocations[beneficiary] = 0;
    require(token.transfer(beneficiary, tokens));

    TokenRedeem(beneficiary, tokens);
  }

   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    bool passedEndTime = now > endTime;
    return passedEndTime || capReached;
  }

   
  function claimRefund() {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  function goalReached() public constant returns (bool) {
   return weiRaised >= goal;
  }

     
   
   
  function finalize() onlyOwner {
    require(!isFinalized);
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    Finalized();

    isFinalized = true;
  }

  function unsoldCleanUp() onlyOwner { 
    uint256 amount = token.balanceOf(this);
    if(amount > 0) {
      require(token.transfer(msg.sender, amount));
    } 

  }

}