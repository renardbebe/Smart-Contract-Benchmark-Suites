 

pragma solidity ^0.4.16;

 
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
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract BurnableToken is StandardToken {

   
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }

  event Burn(address indexed burner, uint indexed value);

}

contract GIDe is BurnableToken {
    
  string public constant name = "GID Coin";
   
  string public constant symbol = "GIDe";
    
  uint8 public constant decimals = 18;

  uint256 public INITIAL_SUPPLY = 50000000 * 1 ether;

  function GIDe  () {
    totalSupply = INITIAL_SUPPLY;
    balances[0x99c06ecfde7ce418066a3070a5e887655e6e6439] = INITIAL_SUPPLY;
  }
    
}

contract Crowdsale is Ownable {
    
  using SafeMath for uint;
    
  address multisig;

  GIDe public token = new GIDe ();

  uint start;
    
    function Start() constant returns (uint) {
        return start;
    }
  
    function setStart(uint newStart) onlyOwner {
        start = newStart;
    }
    
  uint period;
  
   function Period() constant returns (uint) {
        return period;
    }
  
    function setPeriod(uint newPeriod) onlyOwner {
        period = newPeriod;
    }

  uint rate;
  
    function Rate() constant returns (uint) {
        return rate;
    }
  
    function setRate(uint newRate) onlyOwner {
        rate = newRate * (10**18);
    }

  function Crowdsale() {
    multisig = 0x8fb8541358bf18e113068a68b28f2e972b51d16a;
    rate = 40000000000000000000;
    start = 1525176000;
    period = 80;
  }
  
  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }

 
 
 
  modifier limitation() {
    require(msg.value >= 50000000000000000);
    _;
  }

  function createTokens() limitation saleIsOn payable {
    multisig.transfer(msg.value);
    uint tokens = rate.mul(msg.value).div(1 ether);
    token.transfer(msg.sender, tokens);
  }
 
  function() external payable {
    createTokens();
  }
    
}