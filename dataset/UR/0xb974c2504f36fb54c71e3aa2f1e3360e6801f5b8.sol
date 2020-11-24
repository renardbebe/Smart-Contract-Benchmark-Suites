 

pragma solidity ^0.4.24;
 
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
 
contract Ownable {
address private _owner;
event OwnershipTransferred(
address indexed previousOwner,
address indexed newOwner
);
 
constructor() internal {
_owner = msg.sender;
emit OwnershipTransferred(address(0), _owner);
}
 
function owner() public view returns(address) {
return _owner;
}
 
modifier onlyOwner() {
require(isOwner());
_;
}
 
function isOwner() public view returns(bool) {
return msg.sender == _owner;
}
 
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(_owner, address(0));
_owner = address(0);
}
 
function transferOwnership(address newOwner) public onlyOwner {
_transferOwnership(newOwner);
}
 
function _transferOwnership(address newOwner) internal {
require(newOwner != address(0));
emit OwnershipTransferred(_owner, newOwner);
_owner = newOwner;
}
}
 
interface IERC20 {
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
 
contract Uptherium is IERC20, Ownable {

using SafeMath for uint256;
mapping (address => uint256) private _balances;
mapping (address => mapping (address => uint256)) private _allowed;

mapping (address => bool) public allowedAddresses;

uint256 private _totalSupply;
string private _name = "Uptherium";
string private _symbol = "UPZT";
uint8 private _decimals = 18;
bool private _poolsSetted;
bool private _burningAllowed;

event Burn(address indexed owner,
uint256 value
);

modifier checkTransfer() {
require(allowedAddresses[msg.sender] == true);
_;
}
constructor() public {
_poolsSetted = false;
_burningAllowed = false;
allowedAddresses[msg.sender] = true;

}

 
function addAddress(address newAddress) public onlyOwner {
allowedAddresses[newAddress] = true;
}

 
function removeAddress(address oldAddress) public onlyOwner {
allowedAddresses[oldAddress] = false;
}

 
function initialMint(address icoPool, address bountyPool, address teamPool, uint256 icoValue, uint256 bountyValue, uint256 teamValue) public onlyOwner {
require(!_poolsSetted);
_mint(icoPool, icoValue);
_mint(bountyPool, bountyValue);
_mint(teamPool, teamValue);
_poolsSetted = true;
}

 
function name() public view returns(string) {
return _name;
}
 
function symbol() public view returns(string) {
return _symbol;
}
 
function decimals() public view returns(uint8) {
return _decimals;
}
 
function totalSupply() public view returns (uint256) {
return _totalSupply;
}
 
function balanceOf(address owner) public view returns (uint256) {
return _balances[owner];
}
 
function allowance(
address owner,
address spender
)
public
view
returns (uint256)
{
return _allowed[owner][spender];
}
 
function transfer(address to, uint256 value) public checkTransfer returns (bool) {
_transfer(msg.sender, to, value);
return true;
}
 
function approve(address spender, uint256 value) public returns (bool) {
require(spender != address(0));
_allowed[msg.sender][spender] = value;
emit Approval(msg.sender, spender, value);
return true;
}
 
function transferFrom(address from, address to, uint256 value) public checkTransfer returns (bool) {
_allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
_transfer(from, to, value);
return true;
}
 
function increaseAllowance(
address spender,
uint256 addedValue
)
public
returns (bool)
{
require(spender != address(0));
_allowed[msg.sender][spender] = (
_allowed[msg.sender][spender].add(addedValue));
emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
return true;
}
 
function decreaseAllowance(
address spender,
uint256 subtractedValue
)
public
returns (bool)
{
require(spender != address(0));
_allowed[msg.sender][spender] = (
_allowed[msg.sender][spender].sub(subtractedValue));
emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
return true;
}
 
function _transfer(address from, address to, uint256 value) internal {
require(to != address(0));
_balances[from] = _balances[from].sub(value);
_balances[to] = _balances[to].add(value);
emit Transfer(from, to, value);
}
 
function _mint(address account, uint256 value) internal {
require(account != address(0));
_totalSupply = _totalSupply.add(value);
_balances[account] = _balances[account].add(value);
emit Transfer(address(0), account, value);
}

 
function allowBurning() public onlyOwner returns(bool) {
_burningAllowed = true;
return _burningAllowed;
}

 
function burn(uint256 value) public {
require(_burningAllowed);  
require(msg.sender != address(0));
require(_balances[msg.sender] >= value);
_totalSupply = _totalSupply.sub(value);
_balances[msg.sender] = _balances[msg.sender].sub(value);
emit Burn(address(msg.sender), value);
}
}