 

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




contract Verifier{
function verifyTx(
uint[2],
uint[2],
uint[2][2],
uint[2],
uint[2],
uint[2],
uint[2],
uint[2],
address
) public pure returns (bool){}




 
function getInputBits(uint, address) public view returns(bytes8){}
}




contract OpsCoinShield{




 




address public owner;
bytes8[merkleWidth] ns;  
uint constant merkleWidth = 256;
uint constant merkleDepth = 9;
uint constant lastRow = merkleDepth-1;
uint private balance = 0;
bytes8[merkleWidth] private zs;  
uint private zCount;  
uint private nCount;  
bytes8[] private roots;  
uint private currentRootIndex;  
 
Verifier private mv;  
Verifier private sv;  
OpsCoin private ops;  
struct Proof {  
uint[2] a;
uint[2] a_p;
uint[2][2] b;
uint[2] b_p;
uint[2] c;
uint[2] c_p;
uint[2] h;
uint[2] k;
}
 
mapping(address => Proof) private proofs;




constructor(address mintVerifier, address transferVerifier, address opsCoin) public {
 
owner = msg.sender;
mv = Verifier(mintVerifier);
sv = Verifier(transferVerifier);
ops = OpsCoin(opsCoin);
}




 
modifier onlyOwner () {
require(msg.sender == owner);
_;
}




 
function close() public onlyOwner {
selfdestruct(owner);
}








function getMintVerifier() public view returns(address){
return address(mv);
}




function getTransferVerifier() public view returns(address){
return address(sv);
}




function getOpsCoin() public view returns(address){
return address(ops);
}




 
function mint(uint amount) public {
 




bool result = mv.verifyTx(
proofs[msg.sender].a,
proofs[msg.sender].a_p,
proofs[msg.sender].b,
proofs[msg.sender].b_p,
proofs[msg.sender].c,
proofs[msg.sender].c_p,
proofs[msg.sender].h,
proofs[msg.sender].k,
msg.sender);




require(result);  
 
ops.transferFrom(msg.sender, address(this), amount);
 
bytes8 z = mv.getInputBits(64, msg.sender); 
zs[zCount++] = z;  
require(uint(mv.getInputBits(0, msg.sender))==amount);  
bytes8 root = merkle(0,0);  
currentRootIndex = roots.push(root)-1;  
}




 
function transfer() public {
 
bool result = sv.verifyTx(
proofs[msg.sender].a,
proofs[msg.sender].a_p,
proofs[msg.sender].b,
proofs[msg.sender].b_p,
proofs[msg.sender].c,
proofs[msg.sender].c_p,
proofs[msg.sender].h,
proofs[msg.sender].k,
msg.sender);
require(result);  




bytes8 nc = sv.getInputBits(0, msg.sender);
bytes8 nd = sv.getInputBits(64, msg.sender);
bytes8 ze = sv.getInputBits(128, msg.sender);
bytes8 zf = sv.getInputBits(192, msg.sender);
for (uint i=0; i<nCount; i++) {  
require(ns[i]!=nc && ns[i]!=nd);
}
ns[nCount++] = nc;  
ns[nCount++] = nd;  
zs[zCount++] = ze;  
zs[zCount++] = zf;  
bytes8 root = merkle(0,0);  
currentRootIndex = roots.push(root)-1;  
}




function burn(address payTo) public {
 
bool result = mv.verifyTx(
proofs[msg.sender].a,
proofs[msg.sender].a_p,
proofs[msg.sender].b,
proofs[msg.sender].b_p,
proofs[msg.sender].c,
proofs[msg.sender].c_p,
proofs[msg.sender].h,
proofs[msg.sender].k,
msg.sender);




require(result);  
 
bytes8 C = mv.getInputBits(0, msg.sender); 
uint256 value = uint256(C);  
ops.transfer(payTo, value);  
bytes8 Nc = mv.getInputBits(64, msg.sender);  
ns[nCount++] = Nc;  
bytes8 root = merkle(0,0);  
currentRootIndex = roots.push(root)-1;  
}




 
function setProofParams(
uint[2] a,
uint[2] a_p,
uint[2][2] b,
uint[2] b_p,
uint[2] c,
uint[2] c_p,
uint[2] h,
uint[2] k)
public {
 
proofs[msg.sender].a[0] = a[0];
proofs[msg.sender].a[1] = a[1];
proofs[msg.sender].a_p[0] = a_p[0];
proofs[msg.sender].a_p[1] = a_p[1];
proofs[msg.sender].b[0][0] = b[0][0];
proofs[msg.sender].b[0][1] = b[0][1];
proofs[msg.sender].b[1][0] = b[1][0];
proofs[msg.sender].b[1][1] = b[1][1];
proofs[msg.sender].b_p[0] = b_p[0];
proofs[msg.sender].b_p[1] = b_p[1];
proofs[msg.sender].c[0] = c[0];
proofs[msg.sender].c[1] = c[1];
proofs[msg.sender].c_p[0] = c_p[0];
proofs[msg.sender].c_p[1] = c_p[1];
proofs[msg.sender].h[0] = h[0];
proofs[msg.sender].h[1] = h[1];
proofs[msg.sender].k[0] = k[0];
proofs[msg.sender].k[1] = k[1];
}




function getTokens() public view returns(bytes8[merkleWidth], uint root) {
 
 
return (zs,currentRootIndex);
}




 
function getRoot(uint rootIndex) view public returns(bytes8) {
return roots[rootIndex];
}




function computeMerkle() public view returns (bytes8){ 
return merkle(0,0);
}




function merkle(uint r, uint t) public view returns (bytes8) {
 
 
 
if (r==lastRow) {
return zs[t];
} else {
return bytes8(sha256(merkle(r+1,2*t)^merkle(r+1,2*t+1))<<192);
}
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