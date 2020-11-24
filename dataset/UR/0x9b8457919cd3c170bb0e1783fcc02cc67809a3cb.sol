 

pragma solidity ^0.4.11;

 
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


contract StandardToken{
    
    using SafeMath for uint256;
    
     
    mapping (address => uint256) balances;
    
    mapping (address => mapping(address => uint256)) approved;
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    uint256 public totalSupply;
    
     
    function totalSupply() constant returns (uint totalSupply){
        return totalSupply;
    }
    
     
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }
    
     
    function transfer(address _to, uint256 _value) returns (bool success){
        
        require(_to != address(0));
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
        
    }
    
     
    function approve(address _spender, uint _value) returns (bool success){
        
        require((_value == 0) || (approved[msg.sender][_spender] == 0));

        approved[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
        
    }
    
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        
        return approved[_owner][_spender];
        
    }
    
     
    function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    approved[msg.sender][_spender] = approved[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, approved[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
    uint oldValue = approved[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      approved[msg.sender][_spender] = 0;
    } else {
      approved[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, approved[msg.sender][_spender]);
    return true;
  }
     
    function transferFrom(address _from, address _to, uint _value) returns (bool success){
        
        require(_to != address(0));
        
         var _allowance = approved[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        approved[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
        
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


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
 
contract ProsperMintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 


contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

   
  function upgradeFrom(address _tokenHolder, uint256 _amount) external;
}



 
contract UpgradeableToken is ProsperMintableToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  event NewUpgradeMaster(address upgradeMaster);

   
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
    NewUpgradeMaster(upgradeMaster);
  }

   
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
         
        throw;
      }

       
      if (value == 0) throw;

      balances[msg.sender] = balances[msg.sender].sub(value);

       
      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);

       
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
         
        throw;
      }

      if (agent == 0x0) throw;
       
      if (msg.sender != upgradeMaster) throw;
       
      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);

       
      if(!upgradeAgent.isUpgradeAgent()) throw;
       
      if (upgradeAgent.originalSupply() != totalSupply) throw;

      UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
      NewUpgradeMaster(upgradeMaster);
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}

contract ProsperPresaleToken is UpgradeableToken {
    
    
    string public name;
    string public symbol;
    uint8 public decimals;

  
    function ProsperPresaleToken(address _owner, string _name, string _symbol, uint256 _initSupply, uint8 _decimals) UpgradeableToken(_owner) {
        
        name = _name;
        symbol = _symbol;
        totalSupply = _initSupply;
        decimals = _decimals;
        
        balances[_owner] = _initSupply;
        
    }
    
}