 

pragma solidity ^0.4.24;

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
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

 

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
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

 

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 

contract SaiexToken is StandardBurnableToken, Ownable {

  string public constant name = "Saiex Token";
  string public constant symbol = "SAIEX";
  uint8 public constant decimals = 18;

  constructor(uint _totalSupply, uint _crowdsaleSupply, uint _fundSupply, address _fundWallet) public {
    totalSupply_ = _totalSupply;

     
    balances[msg.sender] = _crowdsaleSupply;
    emit Transfer(address(0), msg.sender, _crowdsaleSupply);

     
    balances[_fundWallet] = _fundSupply;
    emit Transfer(address(0), _fundWallet, _fundSupply);
  }
}


contract SaiexCrowdsale is TimedCrowdsale, CanReclaimToken {

  constructor(uint256 _openingTime, uint256 _closingTime, uint256 _rate, address _fundWallet, StandardBurnableToken _token, uint[] _timeBonus, uint[] _amountBonus) public
    Crowdsale(_rate, _fundWallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
  {
     
    TimeBonusPricing(_timeBonus);
    AmountBonusPricing(_amountBonus);
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    uint256 currentRate = getCurrentRate(_weiAmount);
    return currentRate.mul(_weiAmount);
  }

   
  function getCurrentRate(uint256 _weiAmount) public view returns (uint256) {
    uint256 currentRate;
    currentRate = rate;

     
    uint256 timeBonusRate;
    timeBonusRate = getCurrentTimeBonusRate();
    currentRate = currentRate.mul(timeBonusRate).div(100);

     
    uint256 amountBonusRate;
    amountBonusRate = getCurrentAmountBonusRate(_weiAmount);
    currentRate = currentRate.mul(amountBonusRate).div(100);

    return currentRate;
  }


  struct Bonus {
     
    uint timeOrAmount;
     
    uint rateMultiplier;
  }

   
  uint public constant MAX_BONUS = 10;
  Bonus[10] public timeBonus;
  Bonus[10] public amountBonus;

   
  uint public timeBonusCount;
  uint public amountBonusCount;

   
  function getCurrentTimeBonusRate() private constant returns (uint) {
    uint i;
    for(i=0; i<timeBonus.length; i++) {
      if(block.timestamp < timeBonus[i].timeOrAmount) {
        return timeBonus[i].rateMultiplier;
      }
    }
    return 100;
  }

   
   
  function getCurrentAmountBonusRate(uint256 _weiAmount) private constant returns (uint) {
    uint i;
    for(i=0; i<amountBonus.length; i++) {
      if(_weiAmount.mul(rate) >= amountBonus[i].timeOrAmount) {
        return amountBonus[i].rateMultiplier;
      }
    }
    return 100;
  }

   
   
  function TimeBonusPricing(uint[] _bonuses) internal {
     
    require(!(_bonuses.length % 2 == 1 || _bonuses.length >= MAX_BONUS*2));
    timeBonusCount = _bonuses.length / 2;
    uint lastTimeOrAmount = 0;

    for(uint i=0; i<_bonuses.length/2; i++) {
      timeBonus[i].timeOrAmount  = _bonuses[i*2];
      timeBonus[i].rateMultiplier = _bonuses[i*2+1];

       
      require(!((lastTimeOrAmount != 0) && (timeBonus[i].rateMultiplier != 100) && (timeBonus[i].timeOrAmount <= lastTimeOrAmount)));
      lastTimeOrAmount = timeBonus[i].timeOrAmount;
    }

     
    require(timeBonus[timeBonusCount-1].rateMultiplier == 100);
  }

   
   
  function AmountBonusPricing(uint[] _bonuses) internal {
     
    require(!(_bonuses.length % 2 == 1 || _bonuses.length >= MAX_BONUS*2));
    amountBonusCount = _bonuses.length / 2;
    uint lastTimeOrAmount = 0;
    for(uint i=0; i<_bonuses.length/2; i++) {
      amountBonus[i].timeOrAmount  = _bonuses[i*2];
      amountBonus[i].rateMultiplier = _bonuses[i*2+1];

       
      require(!((lastTimeOrAmount != 0) && (amountBonus[i].timeOrAmount >= lastTimeOrAmount)));
      lastTimeOrAmount = amountBonus[i].timeOrAmount;
    }

     
    require(amountBonus[amountBonusCount-1].rateMultiplier == 100);
  }

   
   
   
  function changeBonuses(uint[] _timeBonus, uint[] _amountBonus) external {
    require(msg.sender == owner);
    TimeBonusPricing(_timeBonus);
    AmountBonusPricing(_amountBonus);
  }

   
   
   
  function changeOpeningClosingTime(uint256 _openingTime, uint256 _closingTime) external {
    require(msg.sender == owner);
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

	 
   
  function changeRate(uint _rate) external {
    require(msg.sender == owner);
    rate = _rate;
  }
}