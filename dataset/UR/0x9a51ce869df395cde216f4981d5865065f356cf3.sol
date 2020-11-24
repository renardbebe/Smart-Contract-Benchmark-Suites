 

pragma solidity ^0.4.18;

 
 
 


 

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

  function mod(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a % b;
     
    assert(a == (a / b) * b + c);  
    return c;
  }

}

 
contract Ownable {

  address public owner;
  address public ownerManualMinter; 

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() {
      

    ownerManualMinter = 0xd97c302e9b5ee38ab900d3a07164c2ad43ffc044 ;  
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == ownerManualMinter);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

 
  function transferOwnershipManualMinter(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    ownerManualMinter = newOwner;
  }

}

contract Restrictable is Ownable {
    
    address public restrictedAddress;
    
    event RestrictedAddressChanged(address indexed restrictedAddress);
    
    function Restrictable() {
        restrictedAddress = address(0);
    }
    
     
    function setRestrictedAddress(address _restrictedAddress) onlyOwner public {
      restrictedAddress = _restrictedAddress;
      RestrictedAddressChanged(_restrictedAddress);
      transferOwnership(_restrictedAddress);
    }
    
    modifier notRestricted(address tryTo) {
        if(tryTo == restrictedAddress) {
            revert();
        }
        _;
    }
}

 

contract BasicToken is ERC20Basic, Restrictable {

  using SafeMath for uint256;

  mapping(address => uint256) balances;
  uint256 public constant icoEndDatetime = 1520978217 ; 

   

  function transfer(address _to, uint256 _value) notRestricted(_to) public returns (bool) {
    require(_to != address(0));
    
     
    require(now > icoEndDatetime ); 

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

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) notRestricted(_to) public returns (bool) {
    require(_to != address(0));
    
     
    require(now > icoEndDatetime) ; 


    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     


    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


 
contract MintableToken is StandardToken {

  uint32 public constant decimals = 4;
  uint256 public constant MAX_SUPPLY = 700000000 * (10 ** uint256(decimals));  

  event Mint(address indexed to, uint256 amount);

   

  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    uint256 newTotalSupply = totalSupply.add(_amount);
    require(newTotalSupply <= MAX_SUPPLY);  
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

}

contract LAFINAL3 is MintableToken 
{
  string public constant name = "LAFINAL2";
  string public constant symbol = "LAFINAL2";

 function LAFINAL3() { totalSupply = 0 ; }  
}