 

pragma solidity ^0.4.23;

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

function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
assert(b <= a);
return a - b;
}

}

contract StandardToken is Token, SafeMath {

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

contract TSETERIF is StandardToken {

 
string public constant name = "TSETERIF";
string public constant symbol = "LIPS";
uint256 public constant decimals = 0;
string public version = "1.0";

 
address public ethFundDeposit;       
address public tokenFundDeposit;      

 
bool public isFinalized;        
uint256 public fundingStartBlock;
uint256 public fundingEndBlock;
uint256 public crowdsaleSupply = 0;          
uint256 public tokenExchangeRate = 1000000;    
uint256 public constant tokenCreationCap =  88 * (10 ** 6) * 10 ** 18;
uint256 public tokenCrowdsaleCap =  80 * (10 ** 6) * 10 ** 18;
 
event CreateTSETERIF(address indexed _to, uint256 _value);

 
constructor() public
{
    isFinalized = false;                    
    ethFundDeposit = 0xbD4eF565DC5aD1835B005deBe75AbB815A757fDB;
    tokenFundDeposit = 0xbD4eF565DC5aD1835B005deBe75AbB815A757fDB;
    tokenExchangeRate = 1000000;
    fundingStartBlock = block.number;
    fundingEndBlock = fundingStartBlock + 24;
    totalSupply = tokenCreationCap;
    balances[tokenFundDeposit] = tokenCreationCap;     
    emit CreateTSETERIF(tokenFundDeposit, tokenCreationCap);
}

function () payable public {
assert(!isFinalized);
require(block.number >= fundingStartBlock);
require(block.number < fundingEndBlock);
require(msg.value > 0);

uint256 tokens = safeMult(msg.value, tokenExchangeRate);
crowdsaleSupply = safeAdd(crowdsaleSupply, tokens);

 
require(tokenCrowdsaleCap >= crowdsaleSupply);

balances[msg.sender] = safeAdd(balances[msg.sender], tokens);      
balances[tokenFundDeposit] = safeSub(balances[tokenFundDeposit], tokens);  
emit CreateTSETERIF(msg.sender, tokens);
}
 
function createTokens() payable external {
require(!isFinalized);
require(block.number >= fundingStartBlock);
require(block.number < fundingEndBlock);
require(msg.value > 0);

uint256 tokens = safeMult(msg.value, tokenExchangeRate);     
crowdsaleSupply = safeAdd(crowdsaleSupply, tokens);

 
require(tokenCrowdsaleCap >= crowdsaleSupply);

balances[msg.sender] = safeAdd(balances[msg.sender], tokens);      
balances[tokenFundDeposit] = safeSub(balances[tokenFundDeposit], tokens);  
emit CreateTSETERIF(msg.sender, tokens);       
}

 
function updateParams(
uint256 _tokenExchangeRate,
uint256 _tokenCrowdsaleCap,
uint256 _fundingStartBlock,
uint256 _fundingEndBlock) external
{
assert(block.number < fundingStartBlock);
assert(!isFinalized);

 
tokenExchangeRate = _tokenExchangeRate;
tokenCrowdsaleCap = _tokenCrowdsaleCap;
fundingStartBlock = _fundingStartBlock;
fundingEndBlock = _fundingEndBlock;
}
 
function finalize(uint _amount) external {
    assert(!isFinalized);

     
    isFinalized = true;
    require(address(this).balance > _amount);
    ethFundDeposit.transfer(_amount);
}
}