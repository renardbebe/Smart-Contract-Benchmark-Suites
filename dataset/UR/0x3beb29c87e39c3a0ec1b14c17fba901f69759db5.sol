 

pragma solidity ^0.4.13;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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
    uint256 c = a + b; assert(c >= a);
    return c;
  }

}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[msg.sender]); 
    
     
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

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
    require (_value <= _allowance);

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

 
contract Ownable is BasicToken {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
    totalSupply = 10000000000*10**3;
    balances[owner] = balances[owner].add(totalSupply);
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

contract Etoken is StandardToken, Ownable {
    
    string public constant name = "Etoken";
    
    string public constant symbol = "ETK";
    
    uint32 public constant decimals = 3;
    
    event DelegatedTransfer(address indexed from, address indexed to, address indexed delegate, uint256 value, uint256 fee);
  
    function delegatedTransfer(address _from, address _to, uint256 _value, uint256 _fee) onlyOwner public returns (bool) {
    
    	uint256 total = _value.add(_fee);
    	require(_from != address(0));
    	require(_to != address(0));
    	require(total <= balances[_from]);
    
    	address delegate = owner;
    
    	balances[_from] = balances[_from].sub(total);
    	balances[_to] = balances[_to].add(_value);
    	balances[delegate] = balances[delegate].add(_fee);
    
    	DelegatedTransfer(_from, _to, delegate, _value, _fee);
    	return true;
    }
    
}