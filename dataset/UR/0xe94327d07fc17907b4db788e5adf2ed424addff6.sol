 

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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}


contract Initializable {
  bool public initialized = false;

  modifier afterInitialized {
    require(initialized);
    _;
  }

  modifier beforeInitialized {
    require(!initialized);
    _;
  }

  function endInitialization() internal beforeInitialized returns (bool) {
    initialized = true;
    return true;
  }
}


 
contract RepToken is Initializable, PausableToken {
  ERC20Basic public legacyRepContract;
  uint256 public targetSupply;

  string public constant name = "Reputation";
  string public constant symbol = "REP";
  uint256 public constant decimals = 18;

  event Migrated(address indexed holder, uint256 amount);

   
  function RepToken(address _legacyRepContract, uint256 _amountUsedToFreeze, address _accountToSendFrozenRepTo) {
    require(_legacyRepContract != 0);
    legacyRepContract = ERC20Basic(_legacyRepContract);
    targetSupply = legacyRepContract.totalSupply();
    balances[_accountToSendFrozenRepTo] = _amountUsedToFreeze;
    totalSupply = _amountUsedToFreeze;
    pause();
  }

   
  function migrateBalances(address[] _holders) onlyOwner beforeInitialized returns (bool) {
    for (uint256 i = 0; i < _holders.length; i++) {
      migrateBalance(_holders[i]);
    }
    return true;
  }

   
  function migrateBalance(address _holder) onlyOwner beforeInitialized returns (bool) {
    if (balances[_holder] > 0) {
      return false;  
    }

    uint256 amount = legacyRepContract.balanceOf(_holder);
    if (amount == 0) {
      return false;  
    }

    balances[_holder] = amount;
    totalSupply = totalSupply.add(amount);
    Migrated(_holder, amount);

    if (targetSupply == totalSupply) {
      endInitialization();
    }
    return true;
  }

   
  function unpause() onlyOwner whenPaused afterInitialized returns (bool) {
    super.unpause();
    return true;
  }
}