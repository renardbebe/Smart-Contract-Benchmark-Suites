 

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}






 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}



 
contract StandardToken is ERC20, SafeMath {

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

   
  function upgradeFrom(address _tokenHolder, uint256 _amount) external;
}


 
contract UpgradeableToken is StandardToken {

   
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

      balances[msg.sender] = safeSub(balances[msg.sender], value);

       
      totalSupply = safeSub(totalSupply, value);
      totalUpgraded = safeAdd(totalUpgraded, value);

       
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



 
contract CentrallyIssuedToken is UpgradeableToken {

   
  string public name;
  string public symbol;
  uint public decimals;

   
  bool public released = false;

   
  uint public releaseFinalizationDate;

   
  event UpdatedTokenInformation(string newName, string newSymbol);

  function CentrallyIssuedToken(address _owner, string _name, string _symbol, uint _totalSupply, uint _decimals, uint _releaseFinalizationDate)  UpgradeableToken(_owner) {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;
    decimals = _decimals;

     
    balances[_owner] = _totalSupply;

    releaseFinalizationDate = _releaseFinalizationDate;
  }

   
  function setTokenInformation(string _name, string _symbol) {

    if(msg.sender != upgradeMaster) {
      throw;
    }

    if(bytes(name).length > 0 || bytes(symbol).length > 0) {
       
       
      throw;
    }

    name = _name;
    symbol = _symbol;
    UpdatedTokenInformation(name, symbol);
  }


   
  function transfer(address _to, uint _value) returns (bool success) {

    if(now > releaseFinalizationDate) {
      if(!released) {
        throw;
      }
    }

    return super.transfer(_to, _value);
  }

   
  function releaseTokenTransfer() {
    if(msg.sender != upgradeMaster) {
      throw;
    }

    released = true;
  }
}