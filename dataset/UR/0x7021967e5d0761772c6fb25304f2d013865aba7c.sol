 

pragma solidity ^0.4.21;

 

 
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

contract EpigenCareCrowdsale is Ownable {
  using SafeMath for uint256;

  StandardToken public token;

  uint256 public startTime;
  uint256 public endTime;
  address public wallet;
  address public tokenPool;
  uint256 public rate;
  uint256 public weiRaised;
  uint256 public weiPending;
  uint256 public tokensPending;
  uint256 public minimumInvestment;

  mapping (address => Transaction) transactions;
  mapping (address => bool) approvedAddresses;
  mapping (address => bool) verifiers;

  struct Transaction { uint weiAmount; uint tokenAmount; }

  event TokenPurchaseRequest(address indexed purchaser, address indexed beneficiary, uint256 value);

  function EpigenCareCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _tokenPool, address _token) Ownable() {
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
    require(_tokenPool != 0x0);

    token = StandardToken(_token);
    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
    tokenPool = _tokenPool;

    verifiers[msg.sender] = true;
    rate = _rate;
    minimumInvestment = 0.5 ether;
  }

  function () payable {
    requestTokens(msg.sender);
  }

  function requestTokens(address beneficiary) sufficientApproval(msg.value) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    require(msg.value >= minimumInvestment);

    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(rate);

    if(approvedAddresses[beneficiary]) {
      weiRaised = weiRaised.add(weiAmount);

      token.transferFrom(tokenPool, beneficiary, tokens);
      wallet.transfer(weiAmount);
    } else {
      Transaction transaction = transactions[beneficiary];
      transaction.weiAmount = transaction.weiAmount.add(weiAmount);
      transaction.tokenAmount = transaction.tokenAmount.add(tokens);

      weiPending = weiPending.add(weiAmount);
      tokensPending = tokensPending.add(tokens);
      TokenPurchaseRequest(msg.sender, beneficiary, weiAmount);
    }
  }

  function validateTransaction(address purchaser) onlyVerifiers(msg.sender) {
    Transaction transaction = transactions[purchaser];

    weiRaised = weiRaised.add(transaction.weiAmount);
    weiPending = weiPending.sub(transaction.weiAmount);
    tokensPending = tokensPending.sub(transaction.tokenAmount);
    approvedAddresses[purchaser] = true;

    token.transferFrom(tokenPool, purchaser, transaction.tokenAmount);
    wallet.transfer(transaction.weiAmount);
    transaction.weiAmount = 0;
    transaction.tokenAmount = 0;
  }

  function pendingTransaction(address user) returns (uint value){
    return transactions[user].weiAmount;
  }

  function revokeRequest() {
    Transaction transaction = transactions[msg.sender];
    weiPending = weiPending.sub(transaction.weiAmount);
    tokensPending = tokensPending.sub(transaction.tokenAmount);
    msg.sender.transfer(transaction.weiAmount);
    transaction.weiAmount = 0;
    transaction.tokenAmount = 0;
  }

  modifier sufficientApproval(uint value) {
    uint tokensNeeded = tokensPending.add(value.mul(rate));
    uint tokensAvailable = token.allowance(tokenPool, this);
    require(tokensAvailable >= tokensNeeded);
    _;
  }

  function rejectRequest(address user, uint fee) onlyVerifiers(msg.sender) {
    Transaction transaction = transactions[user];
    weiPending = weiPending.sub(transaction.weiAmount);
    tokensPending = tokensPending.sub(transaction.tokenAmount);
    if(fee > 0) {
      transaction.weiAmount = transaction.weiAmount.sub(fee);
      wallet.transfer(fee);
    }

    user.transfer(transaction.weiAmount);
    transaction.weiAmount = 0;
    transaction.tokenAmount = 0;
  }

  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = (now >= startTime && now <= endTime);
    bool nonZeroPurchase = msg.value != 0;
    return (withinPeriod && nonZeroPurchase);
  }

  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  function updateMinimumInvestment(uint _minimumInvestment) onlyOwner {
    minimumInvestment = _minimumInvestment;
  }

  function updateRate(uint _rate) onlyOwner {
    rate = _rate;
  }

  function setVerifier(address verifier, bool value) onlyOwner {
    verifiers[verifier] = value;
  }

  function isValidated(address user) returns (bool) {
    return approvedAddresses[user];
  }

  modifier onlyVerifiers(address sender) {
    require(verifiers[sender]);
    _;
  }
}