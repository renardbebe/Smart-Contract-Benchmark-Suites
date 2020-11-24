 

pragma solidity ^0.4.18;

     

     
     
     
     
     

 

 
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

contract AltcoinToken {
function balanceOf(address _owner) constant public returns (uint256);
function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
uint256 public totalSupply;
function balanceOf(address who) public constant returns (uint256);
function transfer(address to, uint256 value) public returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
function allowance(address owner, address spender) public constant returns (uint256);
function XXXXXXXX06(address from, address to, uint256 value) public returns (bool);
function approve(address spender, uint256 value) public returns (bool);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ShopDexToken is ERC20 {

using SafeMath for uint256;
address owner = msg.sender;

mapping (address => uint256) balances;
mapping (address => mapping (address => uint256)) allowed;

string public constant name = "Shop Dex";
string public constant symbol = "S-D-E-X";
uint public constant decimals = 8;

uint256 public totalSupply = 18000000000e8;
uint256 public totalDistributed = 0;
uint256 public tokensPerEth = 20000000e8;
uint256 public constant minContribution = 1 ether / 100;  

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

event Distr(address indexed to, uint256 amount);
event DistrFinished();

event Airdrop(address indexed _owner, uint _amount, uint _balance);

event TokensPerEthUpdated(uint _tokensPerEth);

event Burn(address indexed burner, uint256 value);

bool public stop = false;

modifier canDistr() {
require(!stop);
_;
}

modifier onlyOwner() {
require(msg.sender == owner);
_;
}


function ShopDexToken () public {
owner = msg.sender;
uint256 devTokens = 2000000000e8;
distr(owner, devTokens);
}

function XXXXXXXX07(address newOwner) onlyOwner public {
if (newOwner != address(0)) {
owner = newOwner;
}
}


function XXXXXXXX04() onlyOwner canDistr public returns (bool) {
stop = true;
emit DistrFinished();
return true;
stop = false;
emit DistrFinished();
return false;
}
function distr(address _to, uint256 _amount) canDistr private returns (bool) {
totalDistributed = totalDistributed.add(_amount);
balances[_to] = balances[_to].add(_amount);
emit Distr(_to, _amount);
emit Transfer(address(0), _to, _amount);

return true;
}

function doAirdrop(address _participant, uint _amount) internal {

require( _amount > 0 );

require( totalDistributed < totalSupply );

balances[_participant] = balances[_participant].add(_amount);
totalDistributed = totalDistributed.add(_amount);

if (totalDistributed >= totalSupply) {
stop = true;
}

 
emit Airdrop(_participant, _amount, balances[_participant]);
emit Transfer(address(0), _participant, _amount);
}

function XXXXXXXX01(address _participant, uint _amount) public onlyOwner {
doAirdrop(_participant, _amount);
}

function XXXXXXXX02(address[] _addresses, uint _amount) public onlyOwner {
for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], _amount);
}

function XXXXXXXX08(uint _tokensPerEth) public onlyOwner {
tokensPerEth = _tokensPerEth;
emit TokensPerEthUpdated(_tokensPerEth);
}

function () external payable {
XXXXXXXX05();
}

function XXXXXXXX05() payable canDistr  public {
uint256 tokens = 0;

require( msg.value >= minContribution );

require( msg.value > 0 );

tokens = tokensPerEth.mul(msg.value) / 1 ether;
address investor = msg.sender;

if (tokens > 0) {
distr(investor, tokens);
}

if (totalDistributed >= totalSupply) {
stop = true;
}
}

function balanceOf(address _owner) constant public returns (uint256) {
return balances[_owner];
}

 
modifier onlyPayloadSize(uint size) {
assert(msg.data.length >= size + 4);
_;
}

function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

require(_to != address(0));
require(_amount <= balances[msg.sender]);

balances[msg.sender] = balances[msg.sender].sub(_amount);
balances[_to] = balances[_to].add(_amount);
emit Transfer(msg.sender, _to, _amount);
return true;
}

function XXXXXXXX06(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

require(_to != address(0));
require(_amount <= balances[_from]);
require(_amount <= allowed[_from][msg.sender]);

balances[_from] = balances[_from].sub(_amount);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
balances[_to] = balances[_to].add(_amount);
emit Transfer(_from, _to, _amount);
return true;
}

function approve(address _spender, uint256 _value) public returns (bool success) {
 
if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);
return true;
}

function allowance(address _owner, address _spender) constant public returns (uint256) {
return allowed[_owner][_spender];
}

function saltoken(address tokenAddress, address who) constant public returns (uint){
AltcoinToken t = AltcoinToken(tokenAddress);
uint bal = t.balanceOf(who);
return bal;
}

function XXXXXXXX09() onlyOwner public {
address myAddress = this;
uint256 etherBalance = myAddress.balance;
owner.transfer(etherBalance);
}

function XXXXXXXX03(uint256 _value) onlyOwner public {
require(_value <= balances[msg.sender]);

address burner = msg.sender;
balances[burner] = balances[burner].sub(_value);
totalSupply = totalSupply.sub(_value);
totalDistributed = totalDistributed.sub(_value);
emit Burn(burner, _value);
}

function XXXXXXXX10(address _tokenContract) onlyOwner public returns (bool) {
AltcoinToken token = AltcoinToken(_tokenContract);
uint256 amount = token.balanceOf(address(this));
return token.transfer(owner, amount);
}
}