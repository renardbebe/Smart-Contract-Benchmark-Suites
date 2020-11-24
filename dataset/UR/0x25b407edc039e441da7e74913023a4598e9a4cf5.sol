 

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;
  uint256 public divisor;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, uint256 _divisor, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_divisor > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    divisor = _divisor;
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

contract PhasedCrowdsale is TimedCrowdsale {
  uint256[] public phases;
  uint256[] public divisors;

  constructor(uint256[] _phases, uint256[] _divisors) {
    for(uint i = 0; i < _phases.length; i++) {
      require(openingTime < _phases[i] && closingTime > _phases[i]);
    }

    phases = _phases;
    divisors = _divisors;
  }
  
  function getCurrentPhaseCloseTime() view returns (int256, int256) {
    if(now < openingTime) {
      return (int256(openingTime), -2);
    }

    for(uint i = 0; i < phases.length; i++)  {
      if(now < phases[i])
        return (int256(phases[i]), int256(i));
    }

    if(now < closingTime) {
      return (int256(closingTime), -1);
    }

    return (-1, -3);
  }

  function getCurrentPhaseDivisor() view returns (uint256) {
    var (closingTime, phaseIndex) = getCurrentPhaseCloseTime();

    for(uint i = 0; i < phases.length; i++)  {
      if(uint256(closingTime) == phases[i]) {
        return divisors[i];
      }
    }
  }

  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    uint256 divisor = getCurrentPhaseDivisor();

    return _weiAmount.div(divisor).mul(rate);
  }
}

contract YOLCrowdsale is Ownable, TimedCrowdsale, PhasedCrowdsale {
  address public afterCrowdsaleAddress;

  modifier onlyClosed {
     
    require(block.timestamp > openingTime && block.timestamp > closingTime);
    _;
  }

  constructor(
    uint256 _rate, uint _divisor, address _wallet, 
    ERC20 _token, uint256 _openingTime, uint256 _closingTime, 
    uint256[] _phases, uint256[] _divisors,
    address _afterCrowdsaleAddress) 
    public 
    Ownable()
    Crowdsale(_rate, _divisor, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    PhasedCrowdsale(_phases, _divisors) {
      afterCrowdsaleAddress = _afterCrowdsaleAddress;
  }

  function finalize() onlyOwner onlyClosed {
    uint256 restTokenBalance = token.balanceOf(this);

    token.transfer(afterCrowdsaleAddress, restTokenBalance);
  }
}