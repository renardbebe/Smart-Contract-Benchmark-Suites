 

 

pragma solidity ^0.4.11;

contract Token {
 
 
uint256 public totalSupply;

 
 
function balanceOf(address _owner) public constant returns (uint256 balance);

 
 
 
 
function transfer(address _to, uint256 _value) public returns (bool success);

 
 
 
 
 
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

 
 
 
 
function approve(address _spender, uint256 _value) public returns (bool success);

 
 
 
function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {

 
 
 
 
/* }       

function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
uint256 z = x + y;
assert((z >= x) && (z >= y));
return z;
}

function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
assert(x >= y);
uint256 z = x - y;
return z;
}

function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
uint256 z = x * y;
assert((x == 0)||(z/x == y));
return z;
}

}

contract StandardToken is Token {

function transfer(address _to, uint256 _value) public returns (bool success) {
 
 
 
 
if (balances[msg.sender] >= _value && _value > 0) {
balances[msg.sender] -= _value;
balances[_to] += _value;
emit Transfer(msg.sender, _to, _value);
return true;
} else { return false; }
}

function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
 
 
if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
balances[_to] += _value;
balances[_from] -= _value;
allowed[_from][msg.sender] -= _value;
emit Transfer(_from, _to, _value);
return true;
} else { return false; }
}

function balanceOf(address _owner) public constant returns (uint256 balance) {
return balances[_owner];
}

function approve(address _spender, uint256 _value) public returns (bool success) {
allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);
return true;
}

function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
return allowed[_owner][_spender];
}

mapping (address => uint256) balances;
mapping (address => mapping (address => uint256)) allowed;
}

contract FIREDATE is StandardToken, SafeMath {

 
string public constant name = "FIREDATE";
string public constant symbol = "🔥";  
uint256 public constant decimals = 0;  
string public version = "1.0";

 
address public depositAddress;       

 
bool public isFinalized;             
uint256 public targetEth;            
uint256 public fundingStartBlock;    
uint256 public fundingEndBlock;      

 
event CreateFiredate(string _name);
event Contribute(address _sender, uint256 _value);
event FinalizeSale(address _sender);
event RefundContribution(address _sender, uint256 _value);
event ClaimTokens(address _sender, uint256 _value);

 
mapping (address => uint256) contributions;     
uint256 contributed;       

 
function Firedate() public{
isFinalized = false;
totalSupply = 21040868;
targetEth = 888 * 1000000000000000000;  
depositAddress = 0x509613c84672B7cef3c0838243134b5B02Df0365;
fundingStartBlock = 8848888;
fundingEndBlock = 8888888;
 
emit CreateFiredate(name);}

 
function contribute() payable external {
if (block.number < fundingStartBlock) revert();     
if (block.number > fundingEndBlock) revert();       
if (msg.value == 0) revert();                   

 
contributions[msg.sender] += msg.value;
contributed += msg.value;

 
emit Contribute(msg.sender, msg.value);   
}

 
function finalizeFunding() external {
if (isFinalized) revert();                        
if (msg.sender != depositAddress) revert();       
if (block.number <= fundingEndBlock) revert();    
if (contributed < targetEth) revert();              

isFinalized = true;

 
if (!depositAddress.send(targetEth)) revert();

 
emit FinalizeSale(msg.sender);
}

 
function claimTokensAndRefund() external {
if (0 == contributions[msg.sender]) revert();     
if (block.number < fundingEndBlock) revert();     

 
if (contributed < targetEth) {
 
if (!msg.sender.send(contributions[msg.sender])) revert();
emit RefundContribution(msg.sender, contributions[msg.sender]);
} else {
 
balances[msg.sender] = safeMult(totalSupply, contributions[msg.sender]) / contributed;
 
if (!msg.sender.send(contributions[msg.sender] - (safeMult(targetEth, contributions[msg.sender]) / contributed))) revert();
emit ClaimTokens(msg.sender, balances[msg.sender]);
}

contributions[msg.sender] = 0;
}
}