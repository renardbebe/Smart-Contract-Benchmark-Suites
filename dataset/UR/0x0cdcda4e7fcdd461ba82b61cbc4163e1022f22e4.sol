 

pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
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
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   

  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner external {
    require(newOwner != address(0));
     
   emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library Locklist {
  
  struct List {
    mapping(address => bool) registry;
  }
  
  function add(List storage list, address _addr)
    internal
  {
    list.registry[_addr] = true;
  }

  function remove(List storage list, address _addr)
    internal
  {
    list.registry[_addr] = false;
  }

  function check(List storage list, address _addr)
    view
    internal
    returns (bool)
  {
    return list.registry[_addr];
  }
}

contract Locklisted is Ownable  {

  Locklist.List private _list;
  
  modifier onlyLocklisted() {
    require(Locklist.check(_list, msg.sender) == true);
    _;
  }

  event AddressAdded(address _addr);
  event AddressRemoved(address _addr);
  
  function LocklistedAddress()
  public
  {
    Locklist.add(_list, msg.sender);
  }

  function LocklistAddressenable(address _addr) onlyOwner
    public
  {
    Locklist.add(_list, _addr);
    emit AddressAdded(_addr);
  }

  function LocklistAddressdisable(address _addr) onlyOwner
    public
  {
    Locklist.remove(_list, _addr);
   emit AddressRemoved(_addr);
  }
  
  function LocklistAddressisListed(address _addr) public view  returns (bool)  {
      return Locklist.check(_list, _addr);
  }
}

interface IERC20 {
  
  function balanceOf(address _owner) public view returns (uint256);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}






contract StandardToken is IERC20, Locklisted {

  mapping (address => mapping (address => uint256)) internal allowed;
   
  using SafeMath for uint256;
  uint256 public totalSupply;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!LocklistAddressisListed(_to));
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
   emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  } 
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!LocklistAddressisListed(_to));
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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





 

contract MintableToken is Ownable, StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  
  string public constant name = "Vertex Market";
  string public constant symbol = "VTEX";
  uint8 public constant decimals = 5;   
  bool public mintingFinished = false;
  
   
   event Burn(address indexed from, uint256 value);

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(!LocklistAddressisListed(_to));
    totalSupply = totalSupply.add(_amount);
    require(totalSupply <= 30000000000000);
    balances[_to] = balances[_to].add(_amount);
    emit  Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
  function burn(uint256 _value) onlyOwner public {
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
}
  

}




 
contract Vertex_Token is  MintableToken {
    using SafeMath for uint256;

     
    MintableToken  token;

   

    
     
    function totalTokenSupply()  internal returns (uint256) {
        return token.totalSupply();
    }
}