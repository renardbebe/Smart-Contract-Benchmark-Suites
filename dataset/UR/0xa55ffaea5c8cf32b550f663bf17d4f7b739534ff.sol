 

pragma solidity ^0.4.18;
 
 
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
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure  returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}
 
 
 
contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();
 
  bool public mintingFinished = false;
 
  address public saleAgent;
  
   modifier canMint() {
   require(!mintingFinished);
    _;
  }
  
   modifier onlySaleAgent() {
   require(msg.sender == saleAgent);
    _;
  }

  function setSaleAgent(address newSaleAgent) public onlyOwner {
   saleAgent = newSaleAgent;
  }

   
  function mint(address _to, uint256 _amount) public onlySaleAgent canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
 
   
  function finishMinting() public onlySaleAgent returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}
 
contract AgroTechFarmToken is MintableToken {
    
    string public constant name = "Agro Tech Farm";
    
    string public constant symbol = "ATF";
    
    uint32 public constant decimals = 18;
}