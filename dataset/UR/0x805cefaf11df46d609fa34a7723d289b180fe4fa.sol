 

 
pragma solidity ^0.4.11;

 

 


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool success);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool success);
  function approve(address spender, uint256 value) returns (bool success);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 

contract ErrorHandler {
    bool public isInTestMode = false;
    event evRecord(address msg_sender, uint msg_value, string message);

    function doThrow(string message) internal {
        evRecord(msg.sender, msg.value, message);
        if (!isInTestMode) {
        	throw;
		}
    }
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}


 


 
contract NTRYStandardToken is ERC20, ErrorHandler {
  address public owner;

   
  bool public emergency = false;

  using SafeMath for uint;

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;
  
   
  mapping (address => bool) frozenAccount;

   
  event FrozenFunds(address target, bool frozen);

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }

   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      doThrow("Only Owner!");
    }
    _;
  }

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       doThrow("Short address attack!");
     }
     _;
  }

  modifier stopInEmergency {
    if (emergency){
        doThrow("Emergency state!");
    }
    _;
  }
  
  function transfer(address _to, uint _value) stopInEmergency onlyPayloadSize(2 * 32) returns (bool success) {
     
    if (frozenAccount[msg.sender]) doThrow("Account freezed!");  
                  
    balances[msg.sender] = balances[msg.sender].sub( _value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) stopInEmergency returns (bool success) {
     
    if (frozenAccount[_from]) doThrow("Account freezed!");

    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) stopInEmergency returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) doThrow("Allowance race condition!");

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }


   
  function emergencyStop(bool _stop) onlyOwner {
      emergency = _stop;
  }

   
  function freezeAccount(address target, bool freeze) onlyOwner {
      frozenAccount[target] = freeze;
      FrozenFunds(target, freeze);
  }

  function frozen(address _target) constant returns (bool frozen) {
    return frozenAccount[_target];
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      balances[newOwner] = balances[owner];
      balances[owner] = 0;
      owner = newOwner;
      Transfer(owner, newOwner,balances[newOwner]);
    }
  }

}


 

 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


 


 
contract UpgradeableToken is NTRYStandardToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        doThrow("Called in a bad state!");
      }

       
      if (value == 0) doThrow("Value to upgrade is zero!");

      balances[msg.sender] = balances[msg.sender].sub(value);

       
      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);

       
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
         
        doThrow("Token state is not feasible for upgrading yet!");
      }

      if (agent == 0x0) doThrow("Invalid address!");
       
      if (msg.sender != upgradeMaster) doThrow("Only upgrade master!");
       
      if (getUpgradeState() == UpgradeState.Upgrading) doThrow("Upgrade started already!");

      upgradeAgent = UpgradeAgent(agent);

       
      if(!upgradeAgent.isUpgradeAgent()) doThrow("Bad interface!");
       
      if (upgradeAgent.originalSupply() != totalSupply) doThrow("Total supply source is not equall to target!");

      UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
      if (master == 0x0) doThrow("Invalid address of upgrade master!");
      if (msg.sender != upgradeMaster) doThrow("Only upgrade master!");
      upgradeMaster = master;
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}

 


contract BurnableToken is NTRYStandardToken {

  address public constant BURN_ADDRESS = 0;

   
  event Burned(address burner, uint burnedAmount);

   
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);
    Burned(burner, burnAmount);
  }
}


contract CentrallyIssuedToken is BurnableToken, UpgradeableToken {

  string public name;
  string public symbol;
  uint public decimals;

  function CentrallyIssuedToken() UpgradeableToken(owner) {
    name = "Notary Platform Token";
    symbol = "NTRY";
    decimals = 18;
    owner = 0x1538EF80213cde339A333Ee420a85c21905b1b2D;

    totalSupply = 150000000 * 1 ether;
    
     
    balances[owner] = 150000000 * 1 ether;

     
    unlockedAt =  now + 330 * 1 days;
  }

  uint256 public constant teamAllocations = 15000000 * 1 ether;
  uint256 public unlockedAt;
  mapping (address => uint256) allocations;
  function allocate() public {
      allocations[0xab1cb1740344A9280dC502F3B8545248Dc3045eA] = 2500000 * 1 ether;
      allocations[0x330709A59Ab2D1E1105683F92c1EE8143955a357] = 2500000 * 1 ether;
      allocations[0xAa0887fc6e8896C4A80Ca3368CFd56D203dB39db] = 2500000 * 1 ether;
      allocations[0x1fbA1d22435DD3E7Fa5ba4b449CC550a933E72b3] = 2500000 * 1 ether;
      allocations[0xC9d5E2c7e40373ae576a38cD7e62E223C95aBFD4] = 500000 * 1 ether;
      allocations[0xabc0B64a38DE4b767313268F0db54F4cf8816D9C] = 500000 * 1 ether;
      allocations[0x5d85bCDe5060C5Bd00DBeDF5E07F43CE3Ccade6f] = 250000 * 1 ether;
      allocations[0xecb1b0231CBC0B04015F9e5132C62465C128B578] = 250000 * 1 ether;
      allocations[0xF9b1Cfc7fe3B63bEDc594AD20132CB06c18FD5F2] = 250000 * 1 ether;
      allocations[0xDbb89a87d9f91EA3f0Ab035a67E3A951A05d0130] = 250000 * 1 ether;
      allocations[0xC1530645E21D27AB4b567Bac348721eE3E244Cbd] = 200000 * 1 ether;
      allocations[0xcfb44162030e6CBca88e65DffA21911e97ce8533] = 200000 * 1 ether;
      allocations[0x64f748a5C5e504DbDf61d49282d6202Bc1311c3E] = 200000 * 1 ether;
      allocations[0xFF22FA2B3e5E21817b02a45Ba693B7aC01485a9C] = 200000 * 1 ether;
      allocations[0xC9856112DCb8eE449B83604438611EdCf61408AF] = 200000 * 1 ether;
      allocations[0x689CCfEABD99081D061aE070b1DA5E1f6e4B9fB2] = 2000000 * 1 ether;
  }

  function withDraw() public {
      if(now < unlockedAt){ 
          doThrow("Allocations are freezed!");
      }
      if (allocations[msg.sender] == 0){
          doThrow("No allocation found!");
      }
      balances[owner] -= allocations[msg.sender];
      balances[msg.sender] += allocations[msg.sender];
      Transfer(owner, msg.sender, allocations[msg.sender]);
      allocations[msg.sender] = 0;
      
  }
  
   function () {
         
        throw;
    }
  
}