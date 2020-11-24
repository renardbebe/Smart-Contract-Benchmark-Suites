 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract TokenRecover is Ownable {

   
  function recoverERC20(
    address _tokenAddress,
    uint256 _tokens
  )
  public
  onlyOwner
  returns (bool success)
  {
    return ERC20Basic(_tokenAddress).transfer(owner, _tokens);
  }
}

 

 
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
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
     
    require(MintableToken(address(token)).mint(_beneficiary, _tokenAmount));
  }
}

 

 
contract TokenCappedCrowdsale is Crowdsale {

  using SafeMath for uint256;

  uint256 public tokenCap;

   
  uint256 public soldTokens;

   
  constructor(uint256 _tokenCap) public {
    require(_tokenCap > 0);
    tokenCap = _tokenCap;
  }

   
  function tokenCapReached() public view returns (bool) {
    return soldTokens >= tokenCap;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
  internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(soldTokens.add(_getTokenAmount(_weiAmount)) <= tokenCap);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
  internal
  {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    soldTokens = soldTokens.add(_getTokenAmount(_weiAmount));
  }
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract Contributions is RBAC, Ownable {

  using SafeMath for uint256;

  string public constant ROLE_OPERATOR = "operator";

  modifier onlyOperator () {
    checkRole(msg.sender, ROLE_OPERATOR);
    _;
  }

  uint256 public totalSoldTokens;
  uint256 public totalWeiRaised;
  mapping(address => uint256) public tokenBalances;
  mapping(address => uint256) public weiContributions;
  address[] public addresses;

  constructor() public {}

   
  function addBalance(
    address _address,
    uint256 _weiAmount,
    uint256 _tokenAmount
  )
  public
  onlyOperator
  {
    if (weiContributions[_address] == 0) {
      addresses.push(_address);
    }
    weiContributions[_address] = weiContributions[_address].add(_weiAmount);
    totalWeiRaised = totalWeiRaised.add(_weiAmount);

    tokenBalances[_address] = tokenBalances[_address].add(_tokenAmount);
    totalSoldTokens = totalSoldTokens.add(_tokenAmount);
  }

   
  function addOperator(address _operator) public onlyOwner {
    addRole(_operator, ROLE_OPERATOR);
  }

   
  function removeOperator(address _operator) public onlyOwner {
    removeRole(_operator, ROLE_OPERATOR);
  }

   
  function getContributorsLength() public view returns (uint) {
    return addresses.length;
  }
}

 

 
contract DefaultCrowdsale is TimedCrowdsale, MintedCrowdsale, TokenCappedCrowdsale, TokenRecover {  

  Contributions public contributions;

  uint256 public minimumContribution;
  uint256 public maximumContribution;
  uint256 public transactionCount;

  constructor(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    uint256 _tokenCap,
    uint256 _minimumContribution,
    uint256 _maximumContribution,
    address _token,
    address _contributions
  )
  Crowdsale(_rate, _wallet, ERC20(_token))
  TimedCrowdsale(_startTime, _endTime)
  TokenCappedCrowdsale(_tokenCap)
  public
  {
    require(_maximumContribution >= _minimumContribution);
    require(_contributions != address(0));

    minimumContribution = _minimumContribution;
    maximumContribution = _maximumContribution;
    contributions = Contributions(_contributions);
  }

   
  function started() public view returns(bool) {
     
    return block.timestamp >= openingTime;
  }

   
  function ended() public view returns(bool) {
    return hasClosed() || tokenCapReached();
  }

   
  function updateRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    rate = _rate;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
  internal
  {
    require(_weiAmount >= minimumContribution);
    require(
      contributions.weiContributions(_beneficiary).add(_weiAmount) <= maximumContribution
    );
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
  internal
  {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions.addBalance(
      _beneficiary,
      _weiAmount,
      _getTokenAmount(_weiAmount)
    );

    transactionCount = transactionCount + 1;
  }
}

 

 
contract IncreasingBonusCrowdsale is DefaultCrowdsale {

  uint256[] public bonusRanges;
  uint256[] public bonusValues;

  constructor(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    uint256 _tokenCap,
    uint256 _minimumContribution,
    uint256 _maximumContribution,
    address _token,
    address _contributions
  )
  DefaultCrowdsale(
    _startTime,
    _endTime,
    _rate,
    _wallet,
    _tokenCap,
    _minimumContribution,
    _maximumContribution,
    _token,
    _contributions
  )
  public
  {}

  function setBonusRates(
    uint256[] _bonusRanges,
    uint256[] _bonusValues
  )
  public
  onlyOwner
  {
    require(bonusRanges.length == 0 && bonusValues.length == 0);
    require(_bonusRanges.length == _bonusValues.length);

    for (uint256 i = 0; i < (_bonusValues.length - 1); i++) {
      require(_bonusValues[i] > _bonusValues[i + 1]);
      require(_bonusRanges[i] > _bonusRanges[i + 1]);
    }

    bonusRanges = _bonusRanges;
    bonusValues = _bonusValues;
  }

   
  function _getTokenAmount(uint256 _weiAmount)
  internal view returns (uint256)
  {
    uint256 tokens = _weiAmount.mul(rate);

    uint256 bonusPercent = 0;

    for (uint256 i = 0; i < bonusValues.length; i++) {
      if (_weiAmount >= bonusRanges[i]) {
        bonusPercent = bonusValues[i];
        break;
      }
    }

    uint256 bonusAmount = tokens.mul(bonusPercent).div(100);

    return tokens.add(bonusAmount);
  }
}

 

 
contract ForkRC is IncreasingBonusCrowdsale {

  constructor(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    uint256 _tokenCap,
    uint256 _minimumContribution,
    uint256 _maximumContribution,
    address _token,
    address _contributions
  )
  IncreasingBonusCrowdsale(
    _startTime,
    _endTime,
    _rate,
    _wallet,
    _tokenCap,
    _minimumContribution,
    _maximumContribution,
    _token,
    _contributions
  )
  public
  {}
}

 

 
contract CrowdGenerator is TokenRecover {

  using SafeMath for uint256;

  uint256[] public bonusRanges;
  uint256[] public bonusValues;

  uint256 public endTime;
  uint256 public rate;
  address public wallet;
  uint256 public tokenCap;
  address public token;
  address public contributions;
  uint256 public minimumContribution;
  uint256 public maximumContribution;

  address[] public crowdsaleList;

  event CrowdsaleStarted(
    address indexed crowdsale
  );

  constructor(
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    uint256 _tokenCap,
    uint256 _minimumContribution,
    address _token,
    address _contributions,
    uint256[] _bonusRanges,
    uint256[] _bonusValues
  ) public {
     
    require(_endTime >= block.timestamp);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_tokenCap > 0);
    require(_token != address(0));
    require(_contributions != address(0));
    require(_bonusRanges.length == _bonusValues.length);

    for (uint256 i = 0; i < (_bonusValues.length - 1); i++) {
      require(_bonusValues[i] > _bonusValues[i + 1]);
      require(_bonusRanges[i] > _bonusRanges[i + 1]);
    }

    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    tokenCap = _tokenCap;
    minimumContribution = _minimumContribution;
    maximumContribution = tokenCap.div(rate);
    token = _token;
    contributions = _contributions;
    bonusRanges = _bonusRanges;
    bonusValues = _bonusValues;
  }

  function startCrowdsales(uint256 _number) public onlyOwner {
    for (uint256 i = 0; i < _number; i++) {
      ForkRC crowd = new ForkRC(
        block.timestamp,  
        endTime,
        rate,
        wallet,
        tokenCap,
        minimumContribution,
        maximumContribution,
        token,
        contributions
      );

      crowd.setBonusRates(bonusRanges, bonusValues);
      crowd.transferOwnership(msg.sender);
      crowdsaleList.push(address(crowd));
      emit CrowdsaleStarted(address(crowd));
    }
  }

  function getCrowdsalesLength() public view returns (uint) {
    return crowdsaleList.length;
  }
}