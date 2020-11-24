 

pragma solidity ^0.4.20;

 

 
contract Ownable {
  address public owner;


   
  function Ownable() internal {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

 
contract Haltable is Ownable {
  bool public halted;

  event Halted(bool halted);

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
    Halted(true);
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
    Halted(false);
  }

}
 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min256(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }
}

 
interface EIP20Token {

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function approve(address spender, uint256 value) public returns (bool success);
  function allowance(address owner, address spender) public view returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

   

}

 
contract Burnable {
   
   
   
  function burnTokens(address account, uint value) internal;
  event Burned(address account, uint value);
}

 
contract Mintable {

   
  function mintInternal(address receiver, uint amount) internal;

   
  event Minted(address receiver, uint amount);
}

 
contract StandardToken is EIP20Token, Burnable, Mintable {
  using SafeMath for uint;

  uint private total_supply;
  mapping(address => uint) private balances;
  mapping(address => mapping (address => uint)) private allowed;


  function totalSupply() public view returns (uint) {
    return total_supply;
  }

   
  function transfer(address to, uint value) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    Transfer(msg.sender, to, value);
    return true;
  }

   
  function balanceOf(address account) public view returns (uint balance) {
    return balances[account];
  }

   
  function transferFrom(address from, address to, uint value) public returns (bool success) {
    uint allowance = allowed[from][msg.sender];

     
     
     

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = allowance.sub(value);
    Transfer(from, to, value);
    return true;
  }

   
  function approve(address spender, uint value) public returns (bool success) {

     
     
     
     
    require (value == 0 || allowed[msg.sender][spender] == 0);

    allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

   
  function allowance(address account, address spender) public view returns (uint remaining) {
    return allowed[account][spender];
  }

   
  function addApproval(address spender, uint addedValue) public returns (bool success) {
      uint oldValue = allowed[msg.sender][spender];
      allowed[msg.sender][spender] = oldValue.add(addedValue);
      Approval(msg.sender, spender, allowed[msg.sender][spender]);
      return true;
  }

   
  function subApproval(address spender, uint subtractedValue) public returns (bool success) {

      uint oldVal = allowed[msg.sender][spender];

      if (subtractedValue > oldVal) {
          allowed[msg.sender][spender] = 0;
      } else {
          allowed[msg.sender][spender] = oldVal.sub(subtractedValue);
      }
      Approval(msg.sender, spender, allowed[msg.sender][spender]);
      return true;
  }

   
  function burnTokens(address account, uint value) internal {
    balances[account] = balances[account].sub(value);
    total_supply = total_supply.sub(value);
    Transfer(account, 0, value);
    Burned(account, value);
  }

   
  function mintInternal(address receiver, uint amount) internal {
    total_supply = total_supply.add(amount);
    balances[receiver] = balances[receiver].add(amount);
    Minted(receiver, amount);

     
     
     
    Transfer(0, receiver, amount);
  }
  
}

 
contract ReleasableToken is StandardToken, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier canTransfer(address sender) {
    require(released || transferAgents[sender]);
    _;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

   
  function transfer(address to, uint value) public canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(to, value);
  }

   
  function transferFrom(address from, address to, uint value) public canTransfer(from) returns (bool success) {
     
    return super.transferFrom(from, to, value);
  }

}

 
contract UpgradeAgent {

   
  uint public originalSupply;

   
  function isUpgradeAgent() public pure returns (bool) {
    return true;
  }

   
  function upgradeFrom(address from, uint value) public;

}


 
contract UpgradeableToken is EIP20Token, Burnable {
  using SafeMath for uint;

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint public totalUpgraded = 0;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed from, address to, uint value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address master) internal {
    setUpgradeMaster(master);
  }

   
  function upgrade(uint value) public {
    UpgradeState state = getUpgradeState();
     
    require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

     
    require(value != 0);

     
    upgradeAgent.upgradeFrom(msg.sender, value);
    
     
    burnTokens(msg.sender, value);
    totalUpgraded = totalUpgraded.add(value);

    Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) onlyMaster external {
     
    require(canUpgrade());

    require(agent != 0x0);
     
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

     
    require(upgradeAgent.isUpgradeAgent());
     
    require(upgradeAgent.originalSupply() == totalSupply());

    UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public view returns(UpgradeState) {
    if (!canUpgrade()) return UpgradeState.NotAllowed;
    else if (address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function changeUpgradeMaster(address new_master) onlyMaster public {
    setUpgradeMaster(new_master);
  }

   
  function setUpgradeMaster(address new_master) private {
    require(new_master != 0x0);
    upgradeMaster = new_master;
  }

   
  function canUpgrade() public view returns(bool) {
     return true;
  }


  modifier onlyMaster() {
    require(msg.sender == upgradeMaster);
    _;
  }
}

 
 
 
contract LostAndFoundToken {
   
  function getLostAndFoundMaster() internal view returns (address);

   
  function enableLostAndFound(address agent, uint tokens, EIP20Token token_contract) public {
    require(msg.sender == getLostAndFoundMaster());
     
     
    token_contract.approve(agent, tokens);
  }
}

 
contract MintableToken is Mintable, Ownable {

  using SafeMath for uint;

  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);


  function MintableToken(uint initialSupply, address multisig, bool mintable) internal {
    require(multisig != address(0));
     
    require(mintable || initialSupply != 0);
     
    if (initialSupply > 0)
      mintInternal(multisig, initialSupply);
     
    mintingFinished = !mintable;
  }

   
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    mintInternal(receiver, amount);
  }

   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
     
    require(mintAgents[msg.sender]);
    _;
  }

   
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}

 
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken, LostAndFoundToken {

  string public name = "Ubanx";

  string public symbol = "BANX";

  uint8 public decimals;

  address public lost_and_found_master;

   
  function CrowdsaleToken(uint initial_supply, uint8 token_decimals, address team_multisig, bool mintable, address token_retriever) public
  UpgradeableToken(team_multisig) MintableToken(initial_supply, team_multisig, mintable) {
    require(token_retriever != address(0));
    decimals = token_decimals;
    lost_and_found_master = token_retriever;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

   
  function canUpgrade() public view returns(bool) {
    return released && super.canUpgrade();
  }

  function getLostAndFoundMaster() internal view returns(address) {
    return lost_and_found_master;
  }

   
  function burn(uint amount) public {
    burnTokens(msg.sender, amount);
  }

}