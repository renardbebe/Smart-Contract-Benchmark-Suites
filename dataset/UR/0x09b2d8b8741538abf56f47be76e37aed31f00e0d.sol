 

pragma solidity ^0.4.13;




interface ERC20Interface {
function totalSupply() external view returns (uint256);




function balanceOf(address who) external view returns (uint256);




function allowance(address owner, address spender)
external view returns (uint256);




function transfer(address to, uint256 value) external returns (bool);




function approve(address spender, uint256 value)
external returns (bool);




function transferFrom(address from, address to, uint256 value)
external returns (bool);




event Transfer(
address indexed from,
address indexed to,
uint256 value
);




event Approval(
address indexed owner,
address indexed spender,
uint256 value
);
}




contract OpsCoin is ERC20Interface {




 




using SafeMath for uint256;




string public symbol;
string public name;
address public owner;
uint256 public totalSupply;








mapping (address => uint256) private balances;
mapping (address => mapping (address => uint256)) private allowed;
mapping (address => mapping (address => uint)) private timeLock;








constructor() {
symbol = "OPS";
name = "EY OpsCoin";
totalSupply = 1000000;
owner = msg.sender;
balances[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}




 
modifier onlyOwner () {
require(msg.sender == owner);
_;
}




 
function close() public onlyOwner {
selfdestruct(owner);
}




 
function balanceOf(address _address) public view returns (uint256) {
return balances[_address];
}




 
function allowance(address _owner, address _spender) public view returns (uint256)
{
return allowed[_owner][_spender];
}




 
function totalSupply() public view returns (uint256) {
return totalSupply;
}








 
function mint(address _account, uint256 _amount) public {
require(_account != 0);
require(_amount > 0);
totalSupply = totalSupply.add(_amount);
balances[_account] = balances[_account].add(_amount);
emit Transfer(address(0), _account, _amount);
}




 
function burn(address _account, uint256 _amount) public {
require(_account != 0);
require(_amount <= balances[_account]);




totalSupply = totalSupply.sub(_amount);
balances[_account] = balances[_account].sub(_amount);
emit Transfer(_account, address(0), _amount);
}




 
function burnFrom(address _account, uint256 _amount) public {
require(_amount <= allowed[_account][msg.sender]);




allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
emit Approval(_account, msg.sender, allowed[_account][msg.sender]);
burn(_account, _amount);
}




 
function transfer(address _to, uint256 _value) public returns (bool) {
require(_value <= balances[msg.sender]);
require(_to != address(0));




balances[msg.sender] = balances[msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
emit Transfer(msg.sender, _to, _value);
return true;
}




 
function approve(address _spender, uint256 _value) public returns (bool) {
require(_spender != address(0));




allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);
return true;
}




 
function approveAt(address _spender, uint256 _value, uint _timeLockTill) public returns (bool) {
require(_spender != address(0));




allowed[msg.sender][_spender] = _value;
timeLock[msg.sender][_spender] = _timeLockTill;
emit Approval(msg.sender, _spender, _value);
return true;
}




 
function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
{
require(_value <= balances[_from]);
require(_value <= allowed[_from][msg.sender]);
require(_to != address(0));




balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
emit Transfer(_from, _to, _value);
return true;
}




 
function transferFromAt(address _from, address _to, uint256 _value) public returns (bool)
{
require(_value <= balances[_from]);
require(_value <= allowed[_from][msg.sender]);
require(_to != address(0));
require(block.timestamp > timeLock[_from][msg.sender]);




balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
emit Transfer(_from, _to, _value);
return true;
}




 
function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool)
{
require(_spender != address(0));




allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
return true;
}




 
function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool)
{
require(_spender != address(0));




allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].sub(_subtractedValue));
emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
return true;
}




}




library SafeMath {




 
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 
 
 
if (a == 0) {
return 0;
}




uint256 c = a * b;
require(c / a == b);




return c;
}




 
function div(uint256 a, uint256 b) internal pure returns (uint256) {
require(b > 0);  
uint256 c = a / b;
 




return c;
}




 
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
require(b <= a);
uint256 c = a - b;




return c;
}




 
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
require(c >= a);




return c;
}




 
function mod(uint256 a, uint256 b) internal pure returns (uint256) {
require(b != 0);
return a % b;
}
}