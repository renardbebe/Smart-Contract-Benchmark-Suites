 

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

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  StandardToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, StandardToken _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    token = _token;
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
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

    token.transfer(beneficiary, tokens);
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

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}

 

 



 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {
    if (!released) {
      require(transferAgents[_sender]);
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
     
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}

 

contract BRFToken is StandardToken, ReleasableToken {
  string public constant name = "Bitrace Token";
  string public constant symbol = "BRF";
  uint8 public constant decimals = 18;

  function BRFToken() public {
    totalSupply = 1000000000 * (10 ** uint256(decimals));
    balances[msg.sender] = totalSupply;
    setReleaseAgent(msg.sender);
    setTransferAgent(msg.sender, true);
  }
}

 

contract BRFCrowdsale is RefundableCrowdsale {

  uint256[3] public icoStartTimes;
  uint256[3] public icoEndTimes;
  uint256[3] public icoRates;
  uint256[3] public icoCaps;
  uint256 public managementTokenAllocation;
  address public managementWalletAddress;
  uint256 public bountyTokenAllocation;
  address public bountyManagementWalletAddress;
  bool public contractInitialized = false;
  uint256 public constant MINIMUM_PURCHASE = 100;
  mapping(uint256 => uint256) public totalTokensByStage;
  bool public refundingComplete = false;
  uint256 public refundingIndex = 0;
  mapping(address => uint256) public directInvestors;
  mapping(address => uint256) public indirectInvestors;
  address[] private directInvestorsCollection;

  event TokenAllocated(address indexed beneficiary, uint256 tokensAllocated, uint256 amount);

  function BRFCrowdsale(
    uint256[3] _icoStartTimes,
    uint256[3] _icoEndTimes,
    uint256[3] _icoRates,
    uint256[3] _icoCaps,
    address _wallet,
    uint256 _goal,
    uint256 _managementTokenAllocation,
    address _managementWalletAddress,
    uint256 _bountyTokenAllocation,
    address _bountyManagementWalletAddress
    ) public
    Crowdsale(_icoStartTimes[0], _icoEndTimes[2], _icoRates[0], _wallet, new BRFToken())
    RefundableCrowdsale(_goal)
  {
    require((_icoCaps[0] > 0) && (_icoCaps[1] > 0) && (_icoCaps[2] > 0));
    require((_icoRates[0] > 0) && (_icoRates[1] > 0) && (_icoRates[2] > 0));
    require((_icoEndTimes[0] > _icoStartTimes[0]) && (_icoEndTimes[1] > _icoStartTimes[1]) && (_icoEndTimes[2] > _icoStartTimes[2]));
    require((_icoStartTimes[1] >= _icoEndTimes[0]) && (_icoStartTimes[2] >= _icoEndTimes[1]));
    require(_managementWalletAddress != owner && _wallet != _managementWalletAddress);
    require(_bountyManagementWalletAddress != owner && _wallet != _bountyManagementWalletAddress);
    icoStartTimes = _icoStartTimes;
    icoEndTimes = _icoEndTimes;
    icoRates = _icoRates;
    icoCaps = _icoCaps;
    managementTokenAllocation = _managementTokenAllocation;
    managementWalletAddress = _managementWalletAddress;
    bountyTokenAllocation = _bountyTokenAllocation;
    bountyManagementWalletAddress = _bountyManagementWalletAddress;
  }

   
  function () external payable {
    require(contractInitialized);
    buyTokens(msg.sender);
  }

  function initializeContract() public onlyOwner {
    require(!contractInitialized);
    allocateTokens(managementWalletAddress, managementTokenAllocation, 0, 0);
    allocateTokens(bountyManagementWalletAddress, bountyTokenAllocation, 0, 0);
    BRFToken brfToken = BRFToken(token);
    brfToken.setTransferAgent(managementWalletAddress, true);
    brfToken.setTransferAgent(bountyManagementWalletAddress, true);
    contractInitialized = true;
  }

   
  function allocateTokens(address beneficiary, uint256 tokensToAllocate, uint256 stage, uint256 rate) public onlyOwner {
    require(stage <= 5);
    uint256 tokensWithDecimals = toBRFWEI(tokensToAllocate);
    uint256 weiAmount = rate == 0 ? 0 : tokensWithDecimals.div(rate);
    weiRaised = weiRaised.add(weiAmount);
    if (weiAmount > 0) {
      totalTokensByStage[stage] = totalTokensByStage[stage].add(tokensWithDecimals);
      indirectInvestors[beneficiary] = indirectInvestors[beneficiary].add(tokensWithDecimals);
    }
    token.transfer(beneficiary, tokensWithDecimals);
    TokenAllocated(beneficiary, tokensWithDecimals, weiAmount);
  }

  function buyTokens(address beneficiary) public payable {
    require(contractInitialized);
     
    uint256 currTime = now;
    uint256 stageCap = toBRFWEI(getStageCap(currTime));
    rate = getTokenRate(currTime);
    uint256 stage = getStage(currTime);
    uint256 weiAmount = msg.value;
    uint256 tokenToGet = weiAmount.mul(rate);
    if (totalTokensByStage[stage].add(tokenToGet) > stageCap) {
      stage = stage + 1;
      rate = getRateByStage(stage);
      tokenToGet = weiAmount.mul(rate);
    }

    require((tokenToGet >= MINIMUM_PURCHASE));

    if (directInvestors[beneficiary] == 0) {
      directInvestorsCollection.push(beneficiary);
    }
    directInvestors[beneficiary] = directInvestors[beneficiary].add(tokenToGet);
    totalTokensByStage[stage] = totalTokensByStage[stage].add(tokenToGet);
    super.buyTokens(beneficiary);
  }

  function refundInvestors() public onlyOwner {
    require(isFinalized);
    require(!goalReached());
    require(!refundingComplete);
    for (uint256 i = 0; i < 20; i++) {
      if (refundingIndex >= directInvestorsCollection.length) {
        refundingComplete = true;
        break;
      }
      vault.refund(directInvestorsCollection[refundingIndex]);
      refundingIndex = refundingIndex.add(1);
    }
  }

  function advanceEndTime(uint256 newEndTime) public onlyOwner {
    require(!isFinalized);
    require(newEndTime > endTime);
    endTime = newEndTime;
  }

  function getTokenRate(uint256 currTime) public view returns (uint256) {
    return getRateByStage(getStage(currTime));
  }

  function getStageCap(uint256 currTime) public view returns (uint256) {
    return getCapByStage(getStage(currTime));
  }

  function getStage(uint256 currTime) public view returns (uint256) {
    if (currTime < icoEndTimes[0]) {
      return 0;
    } else if ((currTime > icoEndTimes[0]) && (currTime <= icoEndTimes[1])) {
      return 1;
    } else {
      return 2;
    }
  }

  function getCapByStage(uint256 stage) public view returns (uint256) {
    return icoCaps[stage];
  }

  function getRateByStage(uint256 stage) public view returns (uint256) {
    return icoRates[stage];
  }

  function allocateUnsold() internal {
    require(hasEnded());
    BRFToken brfToken = BRFToken(token);
    uint256 leftOverTokens = brfToken.balanceOf(address(this));
    if (leftOverTokens > 0) {
      token.transfer(owner, leftOverTokens);
    }
  }

  function toBRFWEI(uint256 value) internal view returns (uint256) {
    BRFToken brfToken = BRFToken(token);
    return (value * (10 ** uint256(brfToken.decimals())));
  }

  function finalization() internal {
    super.finalization();
    if (goalReached()) {
      allocateUnsold();
      BRFToken brfToken = BRFToken(token);
      brfToken.releaseTokenTransfer();
      brfToken.transferOwnership(owner);
    }
  }

}