 

pragma solidity ^0.4.19;

 
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

   
  event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length != size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
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

   
  function addApproval(address _spender, uint _addedValue)
  onlyPayloadSize(2 * 32)
  returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      allowed[msg.sender][_spender] = safeAdd(oldValue, _addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

   
  function subApproval(address _spender, uint _subtractedValue)
  onlyPayloadSize(2 * 32)
  returns (bool success) {

      uint oldVal = allowed[msg.sender][_spender];

      if (_subtractedValue > oldVal) {
          allowed[msg.sender][_spender] = 0;
      } else {
          allowed[msg.sender][_spender] = safeSub(oldVal, _subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

}



contract BurnableToken is StandardToken {

  address public constant BURN_ADDRESS = 0;

   
  event Burned(address burner, uint burnedAmount);

   
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = safeSub(balances[burner], burnAmount);
    totalSupply = safeSub(totalSupply, burnAmount);
    Burned(burner, burnAmount);
  }
}





 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


 
contract UpgradeableToken is StandardToken {

   
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
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


contract SunriseToken is BurnableToken, UpgradeableToken {

  string public name;
  string public symbol;
  uint public decimals;
  address public owner;

  mapping(address => uint) previligedBalances;

  function SunriseToken(address _owner, string _name, string _symbol, uint _totalSupply, uint _decimals)  UpgradeableToken(_owner) {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;
    decimals = _decimals;

     
    balances[_owner] = _totalSupply;

     
    owner = _owner;
  }

   
  function transferPrivileged(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
    if (msg.sender != owner) throw;
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    previligedBalances[_to] = safeAdd(previligedBalances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function getPrivilegedBalance(address _owner) constant returns (uint balance) {
    return previligedBalances[_owner];
  }

   
  function transferFromPrivileged(address _from, address _to, uint _value) returns (bool success) {
    if (msg.sender != owner) throw;

    uint availablePrevilegedBalance = previligedBalances[_from];

    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    previligedBalances[_from] = safeSub(availablePrevilegedBalance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
}

contract SunriseTokenSale {
    address public beneficiary;
    uint public startline;
    uint public deadline;
    uint public price;
    uint public amountRaised;
    uint public totalTokensSold;
    uint public threshold;

    mapping(address => uint) public actualGotETH;
    mapping(address => uint) public actualGotTokens;
    SunriseToken public tokenReward;

    modifier onlyOwner() {
        if(msg.sender != beneficiary) throw;
        _;
    }

    function SunriseTokenSale(
        uint start,
        uint end,
        uint costOfEachToken,
        SunriseToken addressOfTokenUsedAsReward
    ) {
        beneficiary = msg.sender;
        startline = start;
        deadline = end;
        price = costOfEachToken ;
        tokenReward = SunriseToken(addressOfTokenUsedAsReward);
        totalTokensSold = 0;
    }

    function () payable {
        if (now <= startline) throw;
        if (now >= deadline) throw;

        uint amount = msg.value ;
        if (amount < price) throw;

        amountRaised += amount;

        uint tokensToSend = (amount * 10000) / (price * 10000) * 1 ether;

        totalTokensSold += tokensToSend;

        actualGotETH[msg.sender] += amount;
        actualGotTokens[msg.sender] += tokensToSend;

        beneficiary.transfer(amount);
        tokenReward.transfer(msg.sender, tokensToSend);
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            beneficiary = newOwner;
        }
    }

    function WithdrawETH(uint amount) onlyOwner {
        beneficiary.transfer(amount);
    }

    function WithdrawAllETH() onlyOwner {
        beneficiary.transfer(amountRaised);
    }

    function WithdrawTokens(uint amount) onlyOwner {
        tokenReward.transfer(beneficiary, amount);
    }

    function ChangeCost(uint costOfEachToken) onlyOwner {
        price = costOfEachToken;
    }

    function ChangeStart(uint start) onlyOwner {
        startline = start;
    }

    function ChangeEnd(uint end) onlyOwner {
        deadline = end;
    }
}