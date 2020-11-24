 

pragma solidity ^0.4.18;

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract ContractReceiver {
  function tokenFallback(address from, uint value) public;
}

 
contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}



 
contract StandardToken is ERC20, SafeMath {

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length != size + 4) {
       revert();
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);

    if (isContract(_to)) {
      ContractReceiver rx = ContractReceiver(_to);
      rx.tokenFallback(msg.sender, _value);
    }

    return true;
  }

   
  function isContract( address _addr ) view private returns (bool) {
    uint length;
    _addr = _addr;
    assembly { length := extcodesize(_addr) }
    return (length > 0);
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

   
  function addApproval(address _spender, uint _addedValue)
  onlyPayloadSize(2 * 32)
  public returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      allowed[msg.sender][_spender] = safeAdd(oldValue, _addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

   
  function subApproval(address _spender, uint _subtractedValue)
  onlyPayloadSize(2 * 32)
  public returns (bool success) {

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

   
  function burn(uint burnAmount) public {
    address burner = msg.sender;
    balances[burner] = safeSub(balances[burner], burnAmount);
    totalSupply = safeSub(totalSupply, burnAmount);
    Burned(burner, burnAmount);
  }
}





 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public pure returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


 
contract UpgradeableToken is StandardToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {
    Unknown, 
    NotAllowed, 
    WaitingForAgent, 
    ReadyToUpgrade, 
    Upgrading
  }

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address _upgradeMaster) public {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
         
        revert();
      }

       
      if (value == 0) revert();

      balances[msg.sender] = safeSub(balances[msg.sender], value);

       
      totalSupply = safeSub(totalSupply, value);
      totalUpgraded = safeAdd(totalUpgraded, value);

       
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

   
  function canUpgrade() public pure returns(bool) {
     return true;
  }

}


contract SQDFiniteToken is BurnableToken, UpgradeableToken {

  string public name;
  string public symbol;
  uint8 public decimals;
  address public owner;

  mapping(address => uint) public previligedBalances;

  modifier onlyOwner() {
    if(msg.sender != owner) revert();
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function SQDFiniteToken(address _owner, string _name, string _symbol, uint _totalSupply, uint8 _decimals) UpgradeableToken(_owner) public {
    uint calculatedSupply = _totalSupply * 10 ** uint(_decimals);
    name = _name;
    symbol = _symbol;
    totalSupply = calculatedSupply;
    decimals = _decimals;

     
    balances[_owner] = calculatedSupply;

     
    owner = _owner;
  }

   
  function transferPrivileged(address _to, uint _value) onlyOwner public returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    previligedBalances[_to] = safeAdd(previligedBalances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function getPrivilegedBalance(address _owner) public constant returns (uint balance) {
    return previligedBalances[_owner];
  }

   
  function transferFromPrivileged(address _from, address _to, uint _value) onlyOwner public returns (bool success) {
    uint availablePrevilegedBalance = previligedBalances[_from];

    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    previligedBalances[_from] = safeSub(availablePrevilegedBalance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
}

contract InitialSaleSQD {
    address public beneficiary;
    uint public preICOSaleStart;
    uint public ICOSaleStart;
    uint public ICOSaleEnd;

    uint public preICOPrice;  
    uint public ICOPrice;  
    
    uint public amountRaised;
    uint public incomingTokensTransactions;

    SQDFiniteToken public tokenReward;

    event TokenFallback( address indexed from,
                         uint256 value);

    modifier onlyOwner() {
        if(msg.sender != beneficiary) revert();
        _;
    }

    function InitialSaleSQD(
        uint _preICOStart,
        uint _ICOStart,
        uint _ICOEnd,
        uint _preICOPrice,
        uint _ICOPrice,
        SQDFiniteToken addressOfTokenUsedAsReward
    ) public {
        beneficiary = msg.sender;
        preICOSaleStart = _preICOStart;
        ICOSaleStart = _ICOStart;
        ICOSaleEnd = _ICOEnd;
        preICOPrice = _preICOPrice;
        ICOPrice = _ICOPrice;
        tokenReward = SQDFiniteToken(addressOfTokenUsedAsReward);
    }

    function () payable public {
        if (now < preICOSaleStart) revert();
        if (now >= ICOSaleEnd) revert();

        uint price = preICOPrice;
        if (now >= ICOSaleStart) {
            price = ICOPrice;
        }

        uint amount = msg.value;
        if (amount < price) revert();

        amountRaised += amount;

        uint payoutPerPrice = 10 ** uint(tokenReward.decimals() - 8);
        uint units = amount / price;
        uint tokensToSend = units * payoutPerPrice;

        tokenReward.transfer(msg.sender, tokensToSend);
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            beneficiary = newOwner;
        }
    }

    function WithdrawETH(uint amount) onlyOwner public {
        beneficiary.transfer(amount);
    }

    function WithdrawAllETH() onlyOwner public {
        beneficiary.transfer(amountRaised);
    }

    function WithdrawTokens(uint amount) onlyOwner public {
        tokenReward.transfer(beneficiary, amount);
    }

    function ChangeCost(uint _preICOPrice, uint _ICOPrice) onlyOwner public {
        preICOPrice = _preICOPrice;
        ICOPrice = _ICOPrice;
    }

    function ChangePreICOStart(uint _start) onlyOwner public {
        preICOSaleStart = _start;
    }

    function ChangeICOStart(uint _start) onlyOwner public {
        ICOSaleStart = _start;
    }

    function ChangeICOEnd(uint _end) onlyOwner public {
        ICOSaleEnd = _end;
    }

     
     
    function tokenFallback(address from, uint value) public {
        incomingTokensTransactions += 1;
        TokenFallback(from, value);
    }
}