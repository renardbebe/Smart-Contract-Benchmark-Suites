 

pragma solidity ^0.4.18;

library SafeMath { 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

  function pow(uint256 a, uint256 b) internal pure returns (uint256){  
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}

 

contract YourCustomTokenJABACO{  
  using SafeMath for uint;
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);


   
  string public constant symbol = "JABAS";
  string public constant name = "JABATOKENS";
  uint8 public constant decimals = 4;
  uint256 _totalSupply = 10000000000;
 

   
  address public owner;

   
  mapping(address => uint256) balances;

   
  mapping(address => mapping (address => uint256)) allowed;

  function totalSupply() public view returns (uint256) {  
    return _totalSupply;
  }

  function balanceOf(address _address) public view returns (uint256 balance) { 
    return balances[_address];
  }
  
   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(msg.sender,_to,_amount);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(_from,_to,_amount);
    return true;
  }
   
  function approve(address _spender, uint256 _amount)public returns (bool success) { 
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function YourCustomTokenJABACO() public {
    owner = msg.sender;
    balances[msg.sender] = _totalSupply;
    Transfer(this,msg.sender,_totalSupply);
  } 
}