 

pragma solidity ^0.4.23;

 
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

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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

contract BablosTokenInterface is ERC20 {
  bool public frozen;
  function burn(uint256 _value) public;
  function setSale(address _sale) public;
  function thaw() external;
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

contract DividendInterface {
  function putProfit() public payable;
  function dividendBalanceOf(address _account) public view returns (uint256);
  function hasDividends() public view returns (bool);
  function claimDividends() public returns (uint256);
  function claimedDividendsOf(address _account) public view returns (uint256);
  function saveUnclaimedDividends(address _account) public;
}

contract BasicDividendToken is StandardToken, Ownable {
  using SafeMath for uint256;

  DividendInterface public dividends;

   
  function setDividends(DividendInterface _dividends) public onlyOwner {
    dividends = _dividends;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    if (dividends != address(0) && dividends.hasDividends()) {
      dividends.saveUnclaimedDividends(msg.sender);
      dividends.saveUnclaimedDividends(_to);
    }

    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    if (dividends != address(0) && dividends.hasDividends()) {
      dividends.saveUnclaimedDividends(_from);
      dividends.saveUnclaimedDividends(_to);
    }

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
}

 
contract UpgradeAgent {

  uint256 public originalSupply;

   
  function isUpgradeAgent() public pure returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;
}

 
contract UpgradeableToken is StandardToken {
  using SafeMath for uint256;

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  constructor (address _upgradeMaster) public {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {
    require(value > 0);
    require(balances[msg.sender] >= value);
    UpgradeState state = getUpgradeState();
    require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);
    
    balances[msg.sender] = balances[msg.sender].sub(value);
     
    totalSupply_ = totalSupply_.sub(value);
    totalUpgraded = totalUpgraded.add(value);

     
    upgradeAgent.upgradeFrom(msg.sender, value);
    emit Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {
    require(agent != address(0));
    require(canUpgrade());
     
    require(msg.sender == upgradeMaster);
     
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

     
    require(upgradeAgent.isUpgradeAgent());
     
    require(upgradeAgent.originalSupply() == totalSupply_);

    emit UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public view returns(UpgradeState) {
    if (!canUpgrade()) {
      return UpgradeState.NotAllowed;
    } else if (upgradeAgent == address(0)) { 
      return UpgradeState.WaitingForAgent; 
    } else if (totalUpgraded == 0) {
      return UpgradeState.ReadyToUpgrade;
    }
    return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
    require(master != address(0));
    require(msg.sender == upgradeMaster);
    upgradeMaster = master;
  }

   
  function canUpgrade() public pure returns(bool) {
    return true;
  }
}

contract BablosToken is BablosTokenInterface, BasicDividendToken, UpgradeableToken, DetailedERC20, BurnableToken, Pausable {
  using SafeMath for uint256;

   
  address public sale;

   
   
  bool public frozen = true;

   
  modifier saleOrUnfrozen() {
    require((frozen == false) || msg.sender == sale || msg.sender == owner);
    _;
  }

   
  modifier onlySale() {
    require(msg.sender == sale);
    _;
  }

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) 
      public 
      UpgradeableToken(msg.sender)
      DetailedERC20(_name, _symbol, _decimals) 
  {
    totalSupply_ = _totalSupply;
    balances[msg.sender] = totalSupply_;
  }

   
  function transfer(address _to, uint256 _value)
      public 
      whenNotPaused 
      saleOrUnfrozen
      returns (bool) 
  {
    super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
      public
      whenNotPaused
      saleOrUnfrozen
      returns (bool) 
  {
    super.transferFrom(_from, _to, _value);
  }

  function setSale(address _sale) public onlyOwner {
    frozen = true;
    sale = _sale;
  }

   
  function thaw() external onlySale {
    frozen = false;
  }
}