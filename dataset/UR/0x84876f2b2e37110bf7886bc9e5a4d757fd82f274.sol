 

pragma solidity ^0.4.13;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  string message;

   
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

 
contract Ownable is BasicToken {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
    totalSupply = 10000000000*10**2;
    balances[owner] = balances[owner].add(totalSupply);
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

contract BinaCoin is BasicToken, Ownable {
    
    uint256 order;
    
    string public constant name = "BinaCoin";
    
    string public constant symbol = "BCO";
    
    uint32 public constant decimals = 2;
    
    function transferToken(address _from, address _to, uint256 _value, uint256 _order) onlyOwner public returns (bool) {
    
        order = _order;
        
        require(_from != address(0));
    	require(_to != address(0));
    	require(_value <= balances[_from]);
    
    	balances[_from] = balances[_from].sub(_value);
    	balances[_to] = balances[_to].add(_value);
    
    	Transfer(_from, _to, _value);
    	return true;
    }
    
}