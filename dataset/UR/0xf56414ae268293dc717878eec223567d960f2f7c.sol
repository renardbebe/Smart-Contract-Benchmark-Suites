 

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


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner public{
    require(paused == false);
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public{
    paused = false;
    Unpause();
  }

}


 
contract Mortal is Ownable {
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}


 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


contract BaseToken is Ownable, Pausable, Mortal{

  using SafeMath for uint256;

   
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowances;
  mapping (address => bool) public frozenAccount;
  uint256 public totalSupply;

   
  string public name;
  uint8 public decimals;
  string public symbol;
  string public version;

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   
  event FrozenFunds(address target, bool frozen);

   
  function totalSupply() public constant returns (uint _totalSupply) {
      return totalSupply;
  }

  function balanceOf(address _address) public view returns (uint256 balance) {
    return balances[_address];
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }

   
  function freezeAccount(address target, bool freeze) onlyOwner public{
    frozenAccount[target] = freeze;
    FrozenFunds(target, freeze);
    }

   
  function isFrozen(address _address) public view returns (bool frozen) {
      return frozenAccount[_address];
  }

   
  function transfer(address _to, uint256 _value) whenNotPaused public returns (bool success)  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
     
     
    require(!frozenAccount[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
   
   
   
   
   
   
   
   

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowances[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _owner, address _to, uint256 _value) whenNotPaused public returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[_owner]);
    require(_value <= allowances[_owner][msg.sender]);
    require(!frozenAccount[_owner]);

    balances[_owner] = balances[_owner].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowances[_owner][msg.sender] = allowances[_owner][msg.sender].sub(_value);
    Transfer(_owner, _to, _value);
    return true;
  }

}


 
contract UpgradeableToken is BaseToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeAgentEnabledToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
         
        revert();
      }

       
      if (value == 0) revert();

      balances[msg.sender] = balances[msg.sender].sub(value);

       
      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);

       
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
         
        revert();
      }

      if (agent == 0x0) revert();
       
      if (msg.sender != upgradeMaster) revert();
       
      if (getUpgradeState() == UpgradeState.Upgrading) revert();

      upgradeAgent = UpgradeAgent(agent);

       
      if(!upgradeAgent.isUpgradeAgent()) revert();
       
      if (upgradeAgent.originalSupply() != totalSupply) revert();

      UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
      if (master == 0x0) revert();
      if (msg.sender != upgradeMaster) revert();
      upgradeMaster = master;
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


 
contract YBKToken is UpgradeableToken {

  string public name;
  string public symbol;
  uint public decimals;
  string public version;

   
    
   function YBKToken(string _name, string _symbol, uint _initialSupply, uint _decimals, string _version) public {

     owner = msg.sender;

      
     upgradeMaster = owner;

     name = _name;
     decimals = _decimals;
     symbol = _symbol;
     version = _version;

     totalSupply = _initialSupply;
     balances[msg.sender] = totalSupply;

   }

}