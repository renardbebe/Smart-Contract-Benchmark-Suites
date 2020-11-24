 

pragma solidity ^0.4.18;

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


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is ERC20, Ownable {
  using SafeMath for uint;

   

  string public constant name = "Truedeal Token";
  string public constant symbol = "TDT";

  uint8 public decimals = 18;

  mapping (address => uint256) accounts;  
  mapping (address => mapping (address => uint256)) allowed;  

   
  modifier nonZeroAddress(address _to) {                  
      require(_to != 0x0);
      _;
  }

  modifier nonZeroAmount(uint _amount) {                  
      require(_amount > 0);
      _;
  }

  modifier nonZeroValue() {                               
      require(msg.value > 0);
      _;
  }

   

   
   
   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
      require(accounts[msg.sender] >= _amount);          
      addToBalance(_to, _amount);
      decrementBalance(msg.sender, _amount);
      Transfer(msg.sender, _to, _amount);
      return true;
  }

   
   
   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
      require(allowance(_from, msg.sender) >= _amount);
      decrementBalance(_from, _amount);
      addToBalance(_to, _amount);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
      Transfer(_from, _to, _amount);
      return true;
  }

   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success) {
      require((_value == 0) || (allowance(msg.sender, _spender) == 0));
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
  }

   
   
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
  }

   
   
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
      return accounts[_owner];
  }

  function Token(address _address) public {
    totalSupply = 8000000000 * 1e18;
    addToBalance(_address, totalSupply);
    Transfer(0x0, _address, totalSupply);
  }

   
   
   
  function addToBalance(address _address, uint _amount) internal {
    accounts[_address] = accounts[_address].add(_amount);
  }

   
   
   
  function decrementBalance(address _address, uint _amount) internal {
    accounts[_address] = accounts[_address].sub(_amount);
  }
}