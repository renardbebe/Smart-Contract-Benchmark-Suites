 

pragma solidity 0.4.24;

 

 
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 

contract MigrationSource {
  function vacate(address _addr) public returns (uint256 o_balance);
}

contract FLYCoin is MigrationSource, ERC20 {
  using SafeMath for uint256;

  string public constant name = "FLYCoin";
  string public constant symbol = "FLY";
  
   
  uint8 public constant decimals = 5;
  
  uint internal totalSupply_ = 3000000000000000;

  address public owner;

  mapping(address => User) public users;
  
  MigrationSource public migrateFrom;
  address public migrateTo;

  struct User {
    uint256 balance;
      
    mapping(address => uint256) authorized;
  }

  modifier only_owner(){
    require(msg.sender == owner);
    _;
  }

  modifier value_less_than_balance(address _user, uint256 _value){
    User storage user = users[_user];
    require(_value <= user.balance);
    _;
  }

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  event OptIn(address indexed owner, uint256 value);
  event Vacate(address indexed owner, uint256 value);

  constructor() public {
    owner = msg.sender;
    User storage user = users[owner];
    user.balance = totalSupply_;
    emit Transfer(0, owner, totalSupply_);
  }

  function totalSupply() public view returns (uint256){
    return totalSupply_;
  }

  function balanceOf(address _addr) public view returns (uint256 balance) {
    return users[_addr].balance;
  }

  function transfer(address _to, uint256 _value) public value_less_than_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[msg.sender];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public value_less_than_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[_from];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    user.authorized[msg.sender] = user.authorized[msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success){
     
     
     
     
    require((_value == 0) || (users[msg.sender].authorized[_spender] == 0));
    users[msg.sender].authorized[_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _user, address _spender) public view returns (uint256){
    return users[_user].authorized[_spender];
  }

  function setOwner(address _addr) public only_owner {
    owner = _addr;
  }

   
   
   
  function setMigrateFrom(address _addr) public only_owner {
    require(migrateFrom == MigrationSource(0));
    migrateFrom = MigrationSource(_addr);
  }

   
   
   
  function setMigrateTo(address _addr) public only_owner {
    migrateTo = _addr;
  }

   
   
   
   
   
   
   
  function optIn() public returns (bool success) {
    require(migrateFrom != MigrationSource(0));
    User storage user = users[msg.sender];
    
    uint256 balance = migrateFrom.vacate(msg.sender);

    emit OptIn(msg.sender, balance);
    
    user.balance = user.balance.add(balance);
    totalSupply_ = totalSupply_.add(balance);

    return true;
  }

   
   
   
   
  function vacate(address _addr) public returns (uint256 o_balance){
    require(msg.sender == migrateTo);
    User storage user = users[_addr];

    require(user.balance > 0);

    o_balance = user.balance;
    totalSupply_ = totalSupply_.sub(user.balance);
    user.balance = 0;

    emit Vacate(_addr, o_balance);
  }

   
}