 

pragma solidity 0.4.24;


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

library Percent {
  using SafeMath for uint256;
   
  function perc
  (
    uint256 initialValue,
    uint256 percent
  ) 
    internal 
    pure 
    returns(uint256 result) 
  { 
    return initialValue.div(100).mul(percent);
  }
}

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
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

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}


 
contract TokenVesting is Ownable {
  using SafeMath for uint256;

   
  event Released(uint256 amount);

   
  event Revoked();

   
  address public beneficiary;

   
  uint256 public start;

   
  uint256 public duration = 23667695;
  uint256 public firstStage = 7889229;
  uint256 public secondStage = 15778458;
  

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor(
    address _beneficiary,
    uint256 _start,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    beneficiary = _beneficiary;
    revocable = _revocable;
    start = _start;
  }

   
  function release(ERC20 token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.transfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20 token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.transfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20 token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20 token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } 

    if(block.timestamp >= start.add(firstStage) && block.timestamp <= start.add(secondStage)){
      return totalBalance.div(3);
    }

    if(block.timestamp >= start.add(secondStage) && block.timestamp <= start.add(duration)){
      return totalBalance.div(3).mul(2);
    }

    return 0;
  }
}


 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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


contract TokenDestructible is Ownable {

  constructor() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }
}


contract Token is PausableToken, TokenDestructible {
    
  uint256 public decimals;
  string public name;
  string public symbol;
  uint256 releasedAmount = 0;

  constructor(uint256 _totalSupply, uint256 _decimals, string _name, string _symbol) public {
    require(_totalSupply > 0);
    require(_decimals > 0);

    totalSupply_ = _totalSupply;
    decimals = _decimals;
    name = _name;
    symbol = _symbol;

    balances[msg.sender] = _totalSupply;

     
    emit Transfer(address(0), msg.sender, _totalSupply);
  }
}

 
contract Allocation is Whitelist {
  using SafeMath for uint256;
  using Percent for uint256;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  event Finalized();

   
  event TimeVestingCreation
  (
    address beneficiary,
    uint256 start,
    uint256 duration,
    bool revocable
  );

  struct PartInfo {
    uint256 percent;
    bool lockup;
    uint256 amount;
  }

  mapping (address => bool) public owners;
  mapping (address => uint256) public contributors;            
  mapping (address => TokenVesting) public vesting;
  mapping (uint256 => PartInfo) public pieChart;
  mapping (address => bool) public isInvestor;
  
  address[] public investors;

   
  uint256 private SMALLEST_SUM;  
  uint256 private SMALLER_SUM;   
  uint256 private MEDIUM_SUM;    
  uint256 private BIGGER_SUM;    
  uint256 private BIGGEST_SUM;   

   
  uint256 public duration = 23667695;

   
  bool public isFinalized = false;

   
  uint256 public weiRaised = 0;

   
  Token public token;
   
  address public wallet;
  uint256 public rate;  
  uint256 public softCap;
  uint256 public hardCap;

   
  constructor(
    uint256 _rate, 
    address _wallet, 
    Token _token,
    uint256 _softCap,
    uint256 _hardCap,
    uint256 _smallestSum,
    uint256 _smallerSum,
    uint256 _mediumSum,
    uint256 _biggerSum,
    uint256 _biggestSum
  ) 
    public 
  {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    require(_hardCap > 0);
    require(_softCap > 0);
    require(_hardCap > _softCap);

    rate = _rate;
    wallet = _wallet;
    token = _token;
    hardCap = _hardCap;
    softCap = _softCap;

    SMALLEST_SUM = _smallestSum;
    SMALLER_SUM = _smallerSum;
    MEDIUM_SUM = _mediumSum;
    BIGGER_SUM = _biggerSum;
    BIGGEST_SUM = _biggestSum;

    owners[msg.sender] = true;

     
    pieChart[1] = PartInfo(10, true, token.totalSupply().mul(10).div(100));
    pieChart[2] = PartInfo(15, true, token.totalSupply().mul(15).div(100));
    pieChart[3] = PartInfo(5, true, token.totalSupply().mul(5).div(100));
    pieChart[4] = PartInfo(5, false, token.totalSupply().mul(5).div(100));
    pieChart[5] = PartInfo(8, false, token.totalSupply().mul(8).div(100));
    pieChart[6] = PartInfo(17, false, token.totalSupply().mul(17).div(100));
    pieChart[7] = PartInfo(10, false, token.totalSupply().mul(10).div(100));
    pieChart[8] = PartInfo(30, false, token.totalSupply().mul(30).div(100));
  }

   
   
   
   
  function() 
    external 
    payable 
  {
    buyTokens(msg.sender);
  }

   
  modifier respectContribution() {
    require(
      msg.value >= SMALLEST_SUM,
      "Minimum contribution is $50,000"
    );
    _;
  }


   
  modifier onlyWhileOpen {
    require(!isFinalized, "Sale is closed");
    _;
  }

   
  modifier onlyOwner {
    require(isOwner(msg.sender) == true, "User is not in Owners");
    _;
  }


   
  function addOwner(address _owner) public onlyOwner {
    require(owners[_owner] == false);
    owners[_owner] = true;
  }

   
  function deleteOwner(address _owner) public onlyOwner {
    require(owners[_owner] == true);
    owners[_owner] = false;
  }

   
  function isOwner(address _address) public view returns(bool res) {
    return owners[_address];
  }
  
   
  function allocateTokens(address[] _investors) public onlyOwner {
    require(_investors.length <= 50);
    
    for (uint i = 0; i < _investors.length; i++) {
      allocateTokensInternal(_investors[i]);
    }
  }

   
  function allocateTokensForContributor(address _contributor) public onlyOwner {
    allocateTokensInternal(_contributor);
  }

   
  function allocateTokensInternal(address _contributor) internal {
    uint256 weiAmount = contributors[_contributor];

    if (weiAmount > 0) {
      uint256 tokens = _getTokenAmount(weiAmount);
      uint256 bonusTokens = _getBonusTokens(weiAmount);

      pieChart[8].amount = pieChart[8].amount.sub(tokens);
      pieChart[1].amount = pieChart[1].amount.sub(bonusTokens);

      contributors[_contributor] = 0;

      token.transfer(_contributor, tokens);
      createTimeBasedVesting(_contributor, bonusTokens);
    }
  }
  
   
  function sendFunds(address _to, uint256 _type, uint256 _amount) public onlyOwner {
    require(
      pieChart[_type].amount >= _amount &&
      _type >= 1 &&
      _type <= 8
    );

    if (pieChart[_type].lockup == true) {
      createTimeBasedVesting(_to, _amount);
    } else {
      token.transfer(_to, _amount);
    }
    
    pieChart[_type].amount -= _amount;
  }

   
  function buyTokens(address _beneficiary) public payable {
    uint256 weiAmount = msg.value;

    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

     
    contributors[_beneficiary] += weiAmount;

    if(!isInvestor[_beneficiary]){
      investors.push(_beneficiary);
      isInvestor[_beneficiary] = true;
    }
    
    _forwardFunds();

    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
  }


   
   
   
   
  function _preValidatePurchase
  (
    address _beneficiary,
    uint256 _weiAmount
  )
    onlyIfWhitelisted(_beneficiary)
    respectContribution
    onlyWhileOpen
    view
    internal
  {
    require(weiRaised.add(_weiAmount) <= hardCap);
    require(_beneficiary != address(0));
  }

   
  function createTimeBasedVesting
  (
    address _beneficiary,
    uint256 _tokens
  )
    internal
  {
    uint256 _start = block.timestamp;

    TokenVesting tokenVesting;

    if (vesting[_beneficiary] == address(0)) {
      tokenVesting = new TokenVesting(_beneficiary, _start, false);
      vesting[_beneficiary] = tokenVesting;
    } else {
      tokenVesting = vesting[_beneficiary];
    }

    token.transfer(address(tokenVesting), _tokens);

    emit TimeVestingCreation(_beneficiary, _start, duration, false);
  }


   
  function hasClosed() public view returns (bool) {
    return isFinalized;
  }

   
  function releaseVestedTokens() public {
    address beneficiary = msg.sender;
    require(vesting[beneficiary] != address(0));

    TokenVesting tokenVesting = vesting[beneficiary];
    tokenVesting.release(token);
  }

   
  function _getBonusTokens
  (
    uint256 _weiAmount
  )
    internal
    view
    returns (uint256 purchasedAmount)
  {
    purchasedAmount = _weiAmount;

    if (_weiAmount >= SMALLEST_SUM && _weiAmount < SMALLER_SUM) {
      purchasedAmount = _weiAmount.perc(5);
    }

    if (_weiAmount >= SMALLER_SUM && _weiAmount < MEDIUM_SUM) {
      purchasedAmount = _weiAmount.perc(10);
    }

    if (_weiAmount >= MEDIUM_SUM && _weiAmount < BIGGER_SUM) {
      purchasedAmount = _weiAmount.perc(15);
    }

    if (_weiAmount >= BIGGER_SUM && _weiAmount < BIGGEST_SUM) {
      purchasedAmount = _weiAmount.perc(20);
    }

    if (_weiAmount >= BIGGEST_SUM) {
      purchasedAmount = _weiAmount.perc(30);
    }

    return purchasedAmount.mul(rate);
  }

  function _getTokenAmount
  (
    uint256 _weiAmount
  )
    internal
    view
    returns (uint256 purchasedAmount)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }


   
  function finalize() public onlyOwner {
    require(!hasClosed());
    finalization();
    isFinalized = true;
    emit Finalized();
  } 


   
  function finalization() pure internal {}

}