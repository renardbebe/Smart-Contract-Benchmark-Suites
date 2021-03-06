 

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

}


contract Potentl is StandardToken, Ownable {

  using SafeMath for uint256;

  uint256 public initialSupply = 37000000e9;
  uint256 public totalSupply = initialSupply;
  uint256 public buyPrice = 300 finney;
  string public symbol = "PTL";
  string public name = "Potentl";
  uint8 public decimals = 9;

  address public owner;

  function Potentl() {
    owner = msg.sender;
    balances[this] = SafeMath.mul(totalSupply.div(37),18);
    balances[owner] = SafeMath.mul(totalSupply.div(37),19); 
  }

  function () payable {
        uint amount = msg.value.div(buyPrice);
        if (balances[this] < amount){
            revert();
        }
        balances[msg.sender] = balances[msg.sender].add(amount);
        balances[this] = balances[this].sub(amount);
        Transfer(this, msg.sender, amount);
    }

    function setPriceInWei(uint256 newBuyPrice) onlyOwner {
        buyPrice = newBuyPrice.mul(10e9);
    }

    function pullTokens() onlyOwner {
        uint amount = balances[this];
        balances[msg.sender] = balances[msg.sender].add(balances[this]);
        balances[this] = 0;
        Transfer(this, msg.sender, amount);
    }
    
    function sendEtherToOwner() onlyOwner {                       
        owner.transfer(this.balance);
    }

    function changeOwner(address _owner) onlyOwner {
        owner = _owner;
    }
}