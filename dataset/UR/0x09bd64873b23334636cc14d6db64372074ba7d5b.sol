 

pragma solidity ^0.4.19;

 

contract ERC20i {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20i {
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
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SeaToken is ERC20i {
    
  using SafeMath for uint256;
  mapping(address => uint256) balances;
      modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
 
 function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
 
contract StandardToken is ERC20, SeaToken {
 
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
    owner = 0x66C2E6dd4B83CA376EFA05809Ae8e0C26911f46B;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}
    
contract MESSIAH is StandardToken, Ownable {
  string public constant name = "MESSIAH";
  string public constant symbol = "MESSIAH";
  uint public constant decimals = 3;
   string public price = 'Invaluable';
   string public issuer = '<a class="__cf_email__" data-cfemail="d4aca7a3b1b1a494b3b9b5bdb8fab7bbb9" href="/cdn-cgi/l/email-protection">[email protected]</a>';
  uint256 public initialSupply;
    
  function MESSIAH () { 
     totalSupply = 100000000 * 10 ** decimals;
      balances[owner] = totalSupply;
      initialSupply = totalSupply; 
        Transfer(2017, this, totalSupply);
        Transfer(this, owner, totalSupply);
  }
}


 