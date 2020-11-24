 

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

 
contract ERC20 {

     
    function totalSupply() public view returns (uint256 supply);

     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract DevCoin is ERC20 {
  using SafeMath for uint256;

   
  string public constant symbol = "DEV";

  string public constant version = '1.0';

  string public constant name = "DevCoin";

  uint256 public constant decimals = 18;

  uint256 constant TOTAL_SUPPLY = 100 * (10 ** 6) * 10 ** decimals;  

   
  address public owner;

   
  mapping(address => uint256) internal balances;

   
   
   
  mapping(address => mapping(address => uint256)) internal allowed;

   
  function DevCoin() public {
    owner = msg.sender;
    balances[owner] = TOTAL_SUPPLY;
  }

   
  function totalSupply() public view returns (uint256 supply) {
    supply = TOTAL_SUPPLY;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(_amount <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

     
    Transfer(msg.sender, _to, _amount);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
     
    require(_to != address(0));
    require(_amount <= balances[_from]);
    require(_amount <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);

     
    Transfer(_from, _to, _amount);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool success) {
     
    allowed[msg.sender][_spender] = _value;
     
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}