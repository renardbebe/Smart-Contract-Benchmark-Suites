 

pragma solidity ^0.4.23;

 
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

 
contract Ownable {
 address owner_;  

 event OwnershipRenounced(address indexed previousOwner);  
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);  

  
 constructor() public {
  owner_ = msg.sender;  
 }

  
 function owner() public view returns (address) {
  return owner_;
 }

  
 modifier onlyOwner() {
  require(msg.sender == owner_);
  _;
 }

  
 function transferOwnership(address newOwner) public onlyOwner {
  require(newOwner != address(0));
  emit OwnershipTransferred(owner_, newOwner);
  owner_ = newOwner;
 }
}

 
contract ERC20 is Ownable {

 using SafeMath for uint256;  

 string name_;  
 string symbol_;  
 uint8 decimals_;  
 uint256 totalSupply_;  

 mapping(address => uint256) balances;  
 mapping(address => mapping(address => uint256)) internal allowed;  

 event Transfer(address indexed from, address indexed to, uint256 value);  
 event Approval(address indexed owner, address indexed spender, uint256 value);  
 event OwnershipRenounced(address indexed previousOwner);  
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);  

  
 constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
  name_ = _name;
  symbol_ = _symbol;
  decimals_ = _decimals;
  totalSupply_ = _totalSupply.mul(10 ** uint256(decimals_));  
  balances[owner_] = totalSupply_;  
 }

  
 function name() public view returns (string) {
  return name_;
 }

  
 function symbol() public view returns (string) {
  return symbol_;
 }

  
 function decimals() public view returns (uint8) {
  return decimals_;
 }

  
 function totalSupply() public view returns (uint256) {
  return totalSupply_;
 }

  
 modifier onlyOwner() {
  require(msg.sender == owner_);
  _;
 }

  
 function transfer(address _to, uint256 _value) public {
  require(_to != address(0));
  require(_value <= balances[msg.sender]);

  balances[msg.sender] = balances[msg.sender].sub(_value);
  balances[_to] = balances[_to].add(_value);
  emit Transfer(msg.sender, _to, _value);
 }

  
 function balanceOf(address _account) public view returns (uint256) {
  return balances[_account];
 }

  
 function approve(address _spender, uint256 _value) public returns (bool) {
  allowed[msg.sender][_spender] = _value;
  emit Approval(msg.sender, _spender, _value);
  return true;
 }

  
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

  
 function allowance(address _owner, address _spender) public view returns (uint256) {
  return allowed[_owner][_spender];
 }

  
 function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
  allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
  emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
  return true;
 }

  
 function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
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