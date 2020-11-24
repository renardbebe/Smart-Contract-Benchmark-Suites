 

pragma solidity ^0.4.18;

 

 
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

 

 
contract BRDCrowdsaleAuthorizer is Ownable {
   
  mapping (address => bool) internal authorizedAccounts;
   
  mapping (address => bool) internal authorizers;

   
  event Authorized(address indexed _to);

   
   
  function addAuthorizer(address _newAuthorizer) onlyOwnerOrAuthorizer public {
     
    authorizers[_newAuthorizer] = true;
  }

   
   
  function removeAuthorizer(address _bannedAuthorizer) onlyOwnerOrAuthorizer public {
     
    require(authorizers[_bannedAuthorizer]);
     
    delete authorizers[_bannedAuthorizer];
  }

   
  function authorizeAccount(address _newAccount) onlyOwnerOrAuthorizer public {
    if (!authorizedAccounts[_newAccount]) {
       
      authorizedAccounts[_newAccount] = true;
       
      Authorized(_newAccount);
    }
  }

   
  function isAuthorizer(address _account) constant public returns (bool _isAuthorizer) {
    return msg.sender == owner || authorizers[_account] == true;
  }

   
  function isAuthorized(address _account) constant public returns (bool _authorized) {
    return authorizedAccounts[_account] == true;
  }

   
  modifier onlyOwnerOrAuthorizer() {
    require(msg.sender == owner || authorizers[msg.sender]);
    _;
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

 

 
contract BRDLockup is Ownable {
  using SafeMath for uint256;

   
  struct Allocation {
    address beneficiary;       
    uint256 allocation;        
    uint256 remainingBalance;  
    uint256 currentInterval;   
    uint256 currentReward;     
  }

   
  Allocation[] public allocations;

   
  uint256 public unlockDate;

   
  uint256 public currentInterval;

   
  uint256 public intervalDuration;

   
  uint256 public numIntervals;

  event Lock(address indexed _to, uint256 _amount);

  event Unlock(address indexed _to, uint256 _amount);

   
   
  function BRDLockup(uint256 _crowdsaleEndDate, uint256 _numIntervals, uint256 _intervalDuration)  public {
    unlockDate = _crowdsaleEndDate;
    numIntervals = _numIntervals;
    intervalDuration = _intervalDuration;
    currentInterval = 0;
  }

   
  function processInterval() onlyOwner public returns (bool _shouldProcessRewards) {
     
    bool _correctInterval = now >= unlockDate && now.sub(unlockDate) > currentInterval.mul(intervalDuration);
    bool _validInterval = currentInterval < numIntervals;
    if (!_correctInterval || !_validInterval)
      return false;

     
    currentInterval = currentInterval.add(1);

     
    uint _allocationsIndex = allocations.length;

     
    for (uint _i = 0; _i < _allocationsIndex; _i++) {
       
      uint256 _amountToReward;

       
      if (currentInterval == numIntervals) {
        _amountToReward = allocations[_i].remainingBalance;
      } else {
         
        _amountToReward = allocations[_i].allocation.div(numIntervals);
      }
       
      allocations[_i].currentReward = _amountToReward;
    }

    return true;
  }

   
  function numAllocations() constant public returns (uint) {
    return allocations.length;
  }

   
  function allocationAmount(uint _index) constant public returns (uint256) {
    return allocations[_index].allocation;
  }

   
  function unlock(uint _index) onlyOwner public returns (bool _shouldReward, address _beneficiary, uint256 _rewardAmount) {
     
    if (allocations[_index].currentInterval < currentInterval) {
       
      allocations[_index].currentInterval = currentInterval;
       
      allocations[_index].remainingBalance = allocations[_index].remainingBalance.sub(allocations[_index].currentReward);
       
      Unlock(allocations[_index].beneficiary, allocations[_index].currentReward);
       
      _shouldReward = true;
    } else {
       
      _shouldReward = false;
    }

     
    _rewardAmount = allocations[_index].currentReward;
    _beneficiary = allocations[_index].beneficiary;
  }

   
  function pushAllocation(address _beneficiary, uint256 _numTokens) onlyOwner public {
    require(now < unlockDate);
    allocations.push(
      Allocation(
        _beneficiary,
        _numTokens,
        _numTokens,
        0,
        0
      )
    );
    Lock(_beneficiary, _numTokens);
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
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

contract BRDToken is MintableToken {
  using SafeMath for uint256;

  string public name = "Bread Token";
  string public symbol = "BRD";
  uint256 public decimals = 18;

   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(mintingFinished || msg.sender == owner);
    return super.transferFrom(_from, _to, _value);
  }

   
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(mintingFinished || msg.sender == owner);
    return super.transfer(_to, _value);
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

 

contract BRDCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public cap;

   
  uint256 public minContribution;

   
  uint256 public maxContribution;

   
  uint256 public ownerRate;

   
  uint256 public bonusRate;

   
  BRDCrowdsaleAuthorizer public authorizer;

   
  BRDLockup public lockup;

   
  function BRDCrowdsale(
    uint256 _cap,          
    uint256 _minWei,       
    uint256 _maxWei,       
    uint256 _startTime,    
    uint256 _endTime,      
    uint256 _rate,         
    uint256 _ownerRate,    
    uint256 _bonusRate,    
    address _wallet)       
    Crowdsale(_startTime, _endTime, _rate, _wallet)
   public
  {
    require(_cap > 0);
    cap = _cap;
    minContribution = _minWei;
    maxContribution = _maxWei;
    ownerRate = _ownerRate;
    bonusRate = _bonusRate;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool _capReached = weiRaised >= cap;
    return super.hasEnded() || _capReached;
  }

   
  function hasStarted() public constant returns (bool) {
    return now > startTime;
  }

   
   
  function buyTokens(address _beneficiary) public payable {
     
    super.buyTokens(_beneficiary);
     
    uint256 _ownerTokens = msg.value.mul(ownerRate);
     
    token.mint(wallet, _ownerTokens);
  }

   
  function allocateTokens(address _beneficiary, uint256 _amount) onlyOwner public {
    require(!isFinalized);

     
    uint256 _weiAmount = _amount.div(rate);
    weiRaised = weiRaised.add(_weiAmount);

     
    token.mint(_beneficiary, _amount);
    
    TokenPurchase(msg.sender, _beneficiary, _weiAmount, _amount);
  }

   
   
   
   
  function lockupTokens(address _beneficiary, uint256 _amount) onlyOwner public {
    require(!isFinalized);

     
    uint256 _ownerTokens = ownerRate.mul(_amount).div(rate);
     
    token.mint(wallet, _ownerTokens);

     
    uint256 _lockupTokens = bonusRate.mul(_amount).div(100);
     
    lockup.pushAllocation(_beneficiary, _lockupTokens);
     
    token.mint(this, _lockupTokens);

     
    uint256 _remainder = _amount.sub(_lockupTokens);
    token.mint(_beneficiary, _remainder);
  }

   
   
   
  function unlockTokens() onlyOwner public returns (bool _didIssueRewards) {
     
     
    if (!lockup.processInterval())
      return false;

     
    uint _numAllocations = lockup.numAllocations();

     
    for (uint _i = 0; _i < _numAllocations; _i++) {
       
      var (_shouldReward, _to, _amount) = lockup.unlock(_i);
       
      if (_shouldReward) {
        token.transfer(_to, _amount);
      }
    }

    return true;
  }

   
  function setAuthorizer(BRDCrowdsaleAuthorizer _authorizer) onlyOwner public {
    require(!hasStarted());
    authorizer = _authorizer;
  }

   
  function setLockup(BRDLockup _lockup) onlyOwner public {
    require(!hasStarted());
    lockup = _lockup;
  }

   
  function setToken(BRDToken _token) onlyOwner public {
    require(!hasStarted());
    token = _token;
  }

   
  function setMaxContribution(uint256 _newMaxContribution) onlyOwner public {
    maxContribution = _newMaxContribution;
  }

   
  function setEndTime(uint256 _newEndTime) onlyOwner public {
    endTime = _newEndTime;
  }

   
  function createTokenContract() internal returns (MintableToken) {
     
     
    return BRDToken(address(0));
  }

   
   
  function finalization() internal {
     
    token.finishMinting();

     
    unlockTokens();

    super.finalization();
  }

   
   
   
   
   
  function validPurchase() internal constant returns (bool) {
    bool _withinCap = weiRaised.add(msg.value) <= cap;
    bool _isAuthorized = authorizer.isAuthorized(msg.sender);
    bool _isMin = msg.value >= minContribution;
    uint256 _alreadyContributed = token.balanceOf(msg.sender).div(rate);
    bool _withinMax = msg.value.add(_alreadyContributed) <= maxContribution;
    return super.validPurchase() && _withinCap && _isAuthorized && _isMin && _withinMax;
  }
}