 
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

 

contract BasicToken is ERC20Basic {
using SafeMath for uint256;
mapping(address => uint256) balances;
uint256 totalSupply_;

 
function totalSupply() public view returns (uint256){
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

 

function balanceOf(address _owner) public view returns (uint256) {
return balances[_owner];
}
}
 
function transferFrom(
address _from,
address _to,
uint256 _value
)
public
returns (bool)
{
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

 
function allowance(
address _owner,
address _spender
)
public
view
returns (uint256)
{
return allowed[_owner][_spender];
}

}

 
contract owned {
address public owner;

constructor() public {
owner = msg.sender;
}

modifier onlyOwner {
require(msg.sender == owner);
_;
}

function transferOwnership(address newOwner) onlyOwner public {
owner = newOwner;
}
}


contract BcdpToken is owned, StandardToken {
string public name = "BCDP";
string public symbol = "BCDP";
uint8 public decimals = 5;

 
constructor() public {
 
totalSupply_ = 100 * 1000 * 10000 * 100000;
balances[msg.sender] = totalSupply_;
}

}
