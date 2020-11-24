 

 

pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a < b ? a : b;
  }

}

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  
  event Pause(bool indexed state);

  bool private paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function Paused() external constant returns(bool){ return paused; }

   
  function tweakState() external onlyOwner {
    paused = !paused;
    Pause(paused);
  }

}

contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

contract CE7 is Pausable, ReentrancyGuard {

  using SafeMath for *;

  string constant public name = "ACT Curation Engine";
  string constant public symbol = "CE7";
  uint8 constant public decimals = 4;
  uint256 private supply = 10e6 * 1e4;  
  string constant public version = "v1.0.0";

  mapping(address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function CE7() public {
    owner = msg.sender;
    balances[msg.sender] = supply;
  }


   

   
  function transfer(address _to, uint256 _value) external whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) external constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) external whenNotPaused returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) external whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) external whenNotPaused returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function totalSupply() public constant returns (uint256) {
    return supply;
  }

   
  uint256 public totalMigrated;
  bool private upgrading = false;
  MigrationAgent private agent;
  event Migrate(address indexed _from, address indexed _to, uint256 _value);
  event Upgrading(bool status);

  function migrationAgent() external constant returns(address) { return agent; }
  function upgradingEnabled()  external constant returns(bool) { return upgrading; }

      
  function migrate(uint256 _value) external nonReentrant isUpgrading {
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    require(agent.isMigrationAgent());

    balances[msg.sender] = balances[msg.sender].sub(_value);
    supply = supply.sub(_value);
    totalMigrated = totalMigrated.add(_value);
    
    if (!agent.migrateFrom(msg.sender, _value)) {
      revert();
    }
    Migrate(msg.sender, agent, _value);
  }

   
  function setMigrationAgent(address _agent) external isUpgrading onlyOwner {
    require(_agent != 0x00);
    agent = MigrationAgent(_agent);
    if (!agent.isMigrationAgent()) {
      revert();
    }
    
    if (agent.originalSupply() != supply) {
      revert();
    }
  }

   
  function tweakUpgrading() external onlyOwner {
      upgrading = !upgrading;
      Upgrading(upgrading);
  }


   
  function isTokenContract() external pure returns (bool) {
    return true;
  }

  modifier isUpgrading() { 
    require(upgrading); 
    _; 
  }


   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length == size + 4);
     _;
  }

  function () external {
     
    revert();
  }
  
}

 
contract MigrationAgent {

  uint256 public originalSupply;
  
  function migrateFrom(address _from, uint256 _value) external returns(bool);
  
   
  function isMigrationAgent() external pure returns (bool) {
    return true;
  }
}