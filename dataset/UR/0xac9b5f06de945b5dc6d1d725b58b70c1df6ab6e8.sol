 

pragma solidity ^0.4.23;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
}
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BitNew is StandardToken, Ownable {
  string public constant name = "BitNew Token (Released)";  
  string public constant symbol = "BN";  
  uint8 public constant decimals = 8;  
  
  uint256 constant MAX_SUPPLY = 2 * 10000 * 10000 * (10 ** uint256(decimals));

   
  mapping (address => uint256) public freezeOf;

   
  event Burn(address indexed from, uint256 value);
  
   
  event Freeze(address indexed from, uint256 value);
  
   
  event Unfreeze(address indexed from, uint256 value);

   
  constructor() public {
    totalSupply_ = MAX_SUPPLY;
    balances[msg.sender] = MAX_SUPPLY;
    emit Transfer(0x0, msg.sender, MAX_SUPPLY);
  }
  
   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner].add(freezeOf[_owner]);
  } 

  function burn(uint256 _value) public returns (bool success) {
    require(_value <= balances[msg.sender]);             
    require(_value > 0); 
    balances[msg.sender] = balances[msg.sender].sub(_value);                      
    totalSupply_ = totalSupply_.sub(_value);                                 
    emit Burn(msg.sender, _value);
    return true;
  }
  
  function freeze(address target, uint256 _value) onlyOwner public returns (bool success) {
    require(_value <= balances[target]);             
    require(_value > 0); 
    balances[target] = balances[target].sub(_value);                       
    freezeOf[target] = freezeOf[target].add(_value);                       
    emit Freeze(target, _value);
    return true;
  }
  
  function unfreeze(address target, uint256 _value) onlyOwner public returns (bool success) {
    require(_value <= freezeOf[target]);             
    require(_value > 0); 
    freezeOf[target] = freezeOf[target].sub(_value);                       
    balances[target] = balances[target].add(_value);
    emit Unfreeze(target, _value);
    return true;
  }
  
   
  function withdrawEther() onlyOwner public {
    msg.sender.transfer(this.balance);           
  }
  
   
  function () payable public{
    owner.transfer(this.balance);
  }
}