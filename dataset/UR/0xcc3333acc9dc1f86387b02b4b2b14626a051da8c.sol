 

pragma solidity ^0.4.15;

contract ELTCoinToken {
  function transfer(address to, uint256 value) public returns (bool);
  function balanceOf(address who) public constant returns (uint256);
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

 
contract Crowdsale {
  using SafeMath for uint256;

  uint256 public constant RATE_CHANGE_THRESHOLD = 30000000000000;

   
  ELTCoinToken public token;

   
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public startRate;

   
  uint256 public currentRate;

   
  uint256 public maxRate;

   
  uint256 public minThreshold;

   
  uint256 public weiRaised;

   
  uint256 public tokensSold;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event WeiTransfer(address indexed receiver, uint256 amount);

  function Crowdsale(
    address _contractAddress, uint256 _endTime, uint256 _startRate, uint256 _minThreshold, address _wallet) {
     
    require(_wallet != 0x0);

    token = ELTCoinToken(_contractAddress);
    endTime = _endTime;
    startRate = _startRate;
    currentRate = _startRate;
    maxRate = startRate.mul(10);
    wallet = _wallet;
    minThreshold = _minThreshold;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    require(weiAmount >= minThreshold);

    uint256 weiToAllocate = weiAmount;

    uint256 tokensTotal = 0;

    while (weiToAllocate > 0) {
      currentRate = tokensSold.div(RATE_CHANGE_THRESHOLD).mul(startRate).add(startRate);

      if (currentRate > maxRate) {
        currentRate = maxRate;
      }

       
      weiToAllocate = weiToAllocate.sub(weiToAllocate % currentRate);

      uint256 remainingTokens = RATE_CHANGE_THRESHOLD.sub(tokensSold % RATE_CHANGE_THRESHOLD);

      uint256 tokens = weiToAllocate.div(currentRate) > remainingTokens ? remainingTokens : weiToAllocate.div(currentRate);

      tokensTotal = tokensTotal.add(tokens);
      tokensSold = tokensSold.add(tokens);

      weiToAllocate = weiToAllocate.sub(tokens.mul(currentRate));
    }

    weiRaised = weiRaised.add(weiAmount);

    require(token.transfer(beneficiary, tokensTotal));

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokensTotal);

    forwardFunds(weiAmount);
  }

  function forwardFunds(uint256 amount) internal {
    wallet.transfer(amount);
    WeiTransfer(wallet, amount);
  }

   
  function validPurchase() internal returns (bool) {
    bool withinPeriod = now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
}

 
contract IndividualCappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint public constant GAS_LIMIT_IN_WEI = 50000000000 wei;

   
  uint256 public capPerAddress;

  mapping(address=>uint) public participated;

  function IndividualCappedCrowdsale(uint256 _capPerAddress) {
     
    capPerAddress = _capPerAddress;
  }

   
  function validPurchase() internal returns (bool) {
    require(tx.gasprice <= GAS_LIMIT_IN_WEI);
    participated[msg.sender] = participated[msg.sender].add(msg.value);
    return super.validPurchase() && participated[msg.sender] <= capPerAddress;
  }
}

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }
}

contract ELTCoinCrowdsale is Ownable, CappedCrowdsale, IndividualCappedCrowdsale {
  function ELTCoinCrowdsale(address _coinAddress, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _minThreshold, uint256 _capPerAddress, address _wallet)
    IndividualCappedCrowdsale(_capPerAddress)
    CappedCrowdsale(_cap)
    Crowdsale(_coinAddress, _endTime, _rate, _minThreshold, _wallet)
  {

  }

   
  function drainRemainingToken ()
    public
    onlyOwner
  {
      require(hasEnded());
      token.transfer(owner, token.balanceOf(this));
  }

  function setMaxRate(uint256 _maxRate) public onlyOwner {
    maxRate = _maxRate;
  }
}