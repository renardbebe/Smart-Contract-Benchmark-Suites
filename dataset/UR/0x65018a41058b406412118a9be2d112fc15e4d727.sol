 

pragma solidity ^0.4.17;

 
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
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
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

   
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

 
contract BattleOfTitansToken is StandardToken, Pausable {

  string public constant name = 'BattleOfTitans';                        
  string public constant symbol = 'BTT';                                        
  uint8 public constant decimals = 8;                                           
  
  uint256 public constant INITIAL_SUPPLY = 360000000 * 10**uint256(decimals);
  uint256 public constant launch_date = 1506970800;
  uint256 public constant unfreeze_start_date = 1506970800;
  uint256 public constant unfreeze_periods = 60;
  uint256 public constant unfreeze_period_time = 60;
  uint256 public constant unfreeze_end_date = (unfreeze_start_date + (unfreeze_period_time * unfreeze_periods));

  mapping (address => uint256) public frozenAccount;
  
  event FrozenFunds(address target, uint256 frozen);
  event Burn(address burner, uint256 burned);
  
   
  function BattleOfTitansToken() public {
    totalSupply = INITIAL_SUPPLY;                                
    balances[msg.sender] = INITIAL_SUPPLY;                       
  }

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    freezeCheck(msg.sender, _value);
    
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    freezeCheck(msg.sender, _value);

    return super.transferFrom(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  
  function freezeAccount(address target, uint256 freeze) public onlyOwner {
    require(now < launch_date);
    frozenAccount[target] = freeze;
    FrozenFunds(target, freeze);
  }
  
  function freezeCheck(address _from, uint256 _value) public constant returns (bool) {
    if(now < unfreeze_start_date) {
      require(balances[_from].sub(frozenAccount[_from]) >= _value );
    } else if(now < unfreeze_end_date) {
        
      uint256 tokens_per_pereiod = frozenAccount[_from] / unfreeze_periods;
      uint256 diff = (unfreeze_end_date -  now);
      uint256 left_periods = diff / unfreeze_period_time;
      uint256 freeze_tokens = left_periods * tokens_per_pereiod;
      
      require(balances[_from].sub(freeze_tokens) >= _value);
    }
    return true;
  }
  
   function burn(uint256 _value) public onlyOwner {
    require(_value > 0);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
}