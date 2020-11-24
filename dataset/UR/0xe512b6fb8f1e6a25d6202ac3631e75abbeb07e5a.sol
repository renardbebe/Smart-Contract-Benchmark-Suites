 

pragma solidity ^0.4.19;

 

 
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract EthbetToken is StandardToken {

  string public constant name = "Ethbet";
  string public constant symbol = "EBET";
  uint8 public constant decimals = 2;  

  uint256 public constant INITIAL_SUPPLY = 1000000000;  

   
  function EthbetToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}


 

 

 
library SafeMath2 {

   
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

contract Ethbet {
  using SafeMath2 for uint256;

   

  event Deposit(address indexed user, uint amount, uint balance);

  event Withdraw(address indexed user, uint amount, uint balance);

  event LockedBalance(address indexed user, uint amount);

  event UnlockedBalance(address indexed user, uint amount);

  event ExecutedBet(address indexed winner, address indexed loser, uint amount);

  event RelayAddressChanged(address relay);


   
  address public relay;

  EthbetToken public token;

  mapping(address => uint256) balances;

  mapping(address => uint256) lockedBalances;

   

  modifier isRelay() {
    require(msg.sender == relay);
    _;
  }

   

   
  function Ethbet(address _relay, address _tokenAddress) public {
     
    require(_relay != address(0));

    relay = _relay;
    token = EthbetToken(_tokenAddress);
  }

   
  function setRelay(address _relay) public isRelay {
     
    require(_relay != address(0));

    relay = _relay;

    RelayAddressChanged(_relay);
  }

   
  function deposit(uint _amount) public {
    require(_amount > 0);

     
     
    require(token.transferFrom(msg.sender, this, _amount));

     
    balances[msg.sender] = balances[msg.sender].add(_amount);

    Deposit(msg.sender, _amount, balances[msg.sender]);
  }

   
  function withdraw(uint _amount) public {
    require(_amount > 0);
    require(balances[msg.sender] >= _amount);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);

     
    require(token.transfer(msg.sender, _amount));

    Withdraw(msg.sender, _amount, balances[msg.sender]);
  }


   
  function lockBalance(address _userAddress, uint _amount) public isRelay {
    require(_amount > 0);
    require(balances[_userAddress] >= _amount);

     
    balances[_userAddress] = balances[_userAddress].sub(_amount);

     
    lockedBalances[_userAddress] = lockedBalances[_userAddress].add(_amount);

    LockedBalance(_userAddress, _amount);
  }

   
  function unlockBalance(address _userAddress, uint _amount) public isRelay {
    require(_amount > 0);
    require(lockedBalances[_userAddress] >= _amount);

     
    lockedBalances[_userAddress] = lockedBalances[_userAddress].sub(_amount);

     
    balances[_userAddress] = balances[_userAddress].add(_amount);

    UnlockedBalance(_userAddress, _amount);
  }

   
  function balanceOf(address _userAddress) constant public returns (uint) {
    return balances[_userAddress];
  }

   
  function lockedBalanceOf(address _userAddress) constant public returns (uint) {
    return lockedBalances[_userAddress];
  }

   
  function executeBet(address _maker, address _caller, bool _makerWon, uint _amount) isRelay public {
     
    require(lockedBalances[_caller] >= _amount);

     
    require(lockedBalances[_maker] >= _amount);

     
    unlockBalance(_caller, _amount);

     
    unlockBalance(_maker, _amount);

    var winner = _makerWon ? _maker : _caller;
    var loser = _makerWon ? _caller : _maker;

     
    balances[winner] = balances[winner].add(_amount);
     
    balances[loser] = balances[loser].sub(_amount);

     
    ExecutedBet(winner, loser, _amount);
  }

}