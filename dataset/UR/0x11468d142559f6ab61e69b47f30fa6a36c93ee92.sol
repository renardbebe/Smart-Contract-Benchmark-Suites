 

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

 

contract ReentryProtected
{
   
  bool __reMutex;

   
   
   
   
   
   
  modifier preventReentry() {
    require(!__reMutex);
    __reMutex = true;
    _;
    delete __reMutex;
    return;
  }

   
   
   
   
  modifier noReentry() {
    require(!__reMutex);
    _;
  }
}

 


 
contract ERC20Interface
{
   

   

   
   
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value);

   
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value);

   

   

   
  function totalSupply() public constant returns (uint256);

   
   
  function balanceOf(address _addr) public constant returns (uint256);

   
   
   
  function allowance(address _owner, address _spender) public constant
  returns (uint256);

   
   
   
  function transfer(address _to, uint256 _amount) public returns (bool);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _amount)
  public returns (bool);

   
   
   
   
  function approve(address _spender, uint256 _amount) public returns (bool);
}

contract ERC20Token is ReentryProtected, ERC20Interface
{

  using SafeMath for uint256;

   
   
  uint256 totSupply;

 
   
  mapping (address => uint256) balance;

   
  mapping (address => mapping (address => uint256)) allowed;

   

  function ERC20Token()
  {
     
     
    
    totSupply = 0;
      balance[msg.sender] = totSupply;
  }

   
  function totalSupply()
  public
  constant
  returns (uint256)
  {
    return totSupply;
  }


   
  function balanceOf(address _addr)
  public
  constant
  returns (uint256)
  {
    return balance[_addr];
  }

   
  function allowance(address _owner, address _spender)
  public
  constant
  returns (uint256 remaining_)
  {
    return allowed[_owner][_spender];
  }


   
   
  function transfer(address _to, uint256 _value)
  public
  noReentry
  returns (bool)
  {
    return xfer(msg.sender, _to, _value);
  }

   
   
  function transferFrom(address _from, address _to, uint256 _value)
  public
  noReentry
  returns (bool)
  {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] -= _value;
    return xfer(_from, _to, _value);
  }

   
  function xfer(address _from, address _to, uint256 _value)
  internal
  returns (bool)
  {
    require(_value > 0 && _value <= balance[_from]);
    balance[_from] -= _value;
    balance[_to] += _value;
    Transfer(_from, _to, _value);
    return true;
  }

   
   
  function approve(address _spender, uint256 _value)
  public
  noReentry
  returns (bool)
  {
    require(balance[msg.sender] != 0);
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
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


 

 contract MintableBurnableToken is ERC20Token, Ownable {
  using SafeMath for uint256;
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed burner, uint256 indexed value);
   

   

   
     
     
     

  
     function burn(uint256 _value) onlyOwner returns (bool) {
      require(_value > 0);

      address burner = msg.sender;
      balance[burner] = balance[burner].sub(_value);
      totSupply = totSupply.sub(_value);
      Burn(burner, _value);
    }


   
   function mint(address _to, uint256 _amount) onlyOwner returns (bool) {
    totSupply = totSupply.add(_amount);
    balance[_to] = balance[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }
}
 
 contract CombiCoin_v2 is MintableBurnableToken {

  string public constant name = "CombiCoin";
  string public constant symbol = "COMBI";
  uint256 public constant decimals = 10;
}