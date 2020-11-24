 

pragma solidity ^0.4.13;

 
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

 
contract BattleOfTitansToken is StandardToken, Pausable {

  string public constant name = 'BattleOfTitans';                        
  string public constant symbol = 'BoT';                                        
  uint8 public constant decimals = 8;                                           
  uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**uint256(decimals);  

  mapping (address => uint256) public frozenAccount;
  
  event FrozenFunds(address target, uint256 frozen);
  
   
  function BattleOfTitansToken() {
    totalSupply = INITIAL_SUPPLY;                                
    balances[msg.sender] = INITIAL_SUPPLY;                       
  }

   
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    freezeCheck(_to, _value);

    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    freezeCheck(_to, _value);

    return super.transferFrom(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  
  function freezeAccount(address target, uint256 freeze)  onlyOwner  {
        require(block.timestamp < (1505645727 + 3600*10));
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
  }
  
  function freezeCheck(address _to, uint256 _value) {
    if(frozenAccount[_to] > 0) {
       require(block.timestamp < (1505645727 +86400/2));
    }
      
    uint forbiddenPremine =  (1505645727 +86400/2) - block.timestamp + 86400*1;
    if (forbiddenPremine < 0) forbiddenPremine = 0;
       
    require(_to != address(0));  
    require(balances[msg.sender] >= _value + frozenAccount[msg.sender] * forbiddenPremine / (86400*1) );  
    require(balances[_to] + _value > balances[_to]);
  }
}