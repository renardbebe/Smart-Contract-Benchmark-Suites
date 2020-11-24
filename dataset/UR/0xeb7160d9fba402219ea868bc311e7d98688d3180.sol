 

pragma solidity ^0.4.13;




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




contract TokenShield{




 




address public owner;
bytes8[merkleWidth] private ns;  
bytes8[merkleWidth] private ds;  
uint constant merkleWidth = 256;
uint constant merkleDepth = 9;
uint constant lastRow = merkleDepth-1;
bytes8[merkleWidth] private zs;  
uint private zCount;  
uint private nCount;  
bytes8[] private roots;  
uint public currentRootIndex;  
 
Verifier mv;  
Verifier tv;  
Verifier jv;  
Verifier sv;  
 
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




constructor(address mintVerifier, address transferVerifier, address joinVerifier, address splitVerifier) public {
 
owner = msg.sender;
mv = Verifier(mintVerifier);
tv = Verifier(transferVerifier);
jv = Verifier(joinVerifier);
sv = Verifier(splitVerifier);
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
return address(tv);
}




function getJoinVerifier() public view returns(address){
return address(jv);
}




function getSplitVerifier() public view returns(address){
return address(sv);
}




 
function mint() public {
 
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
bytes8 d = mv.getInputBits(0, msg.sender);  
bytes8 z = mv.getInputBits(64, msg.sender);
for (uint i=0; i<zCount; i++) {  
require(ds[i]!= d);
}
zs[zCount] = z;  
ds[zCount++] = d;  
bytes8 root = merkle(0,0);  
currentRootIndex = roots.push(root)-1;  
}




 
function transfer() public {
bool result = tv.verifyTx(
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
bytes8 n = tv.getInputBits(0, msg.sender);
bytes8 z = tv.getInputBits(128, msg.sender);
for (uint i=0; i<nCount; i++) {  
require(ns[i]!=n);
}
ns[nCount++] = n;  
zs[zCount++] = z;  
bytes8 root = merkle(0,0);  
currentRootIndex = roots.push(root)-1;  
}




 
function join() public {
 
bool result = jv.verifyTx(
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
bytes8 na1 = jv.getInputBits(0, msg.sender);
bytes8 na2 = jv.getInputBits(64, msg.sender);
bytes8 zb = jv.getInputBits(192, msg.sender);
bytes8 db = jv.getInputBits(256, msg.sender);
for (uint i=0; i<nCount; i++) {  
require(ns[i]!=na1 && ns[i]!=na2);
}
for (uint j=0; j<zCount; j++) {  
require(ds[j]!= db);
}
ns[nCount++] = na1;  
ns[nCount++] = na2;  
zs[zCount] = zb;  
ds[zCount++] = db;  
bytes8 root = merkle(0,0);  
currentRootIndex = roots.push(root)-1;  
}




 
function split() public {
 
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
bytes8 na = sv.getInputBits(0, msg.sender);
bytes8 zb1 = sv.getInputBits(128, msg.sender);
bytes8 zb2 = sv.getInputBits(192, msg.sender);
bytes8 db1 = sv.getInputBits(256, msg.sender);  
bytes8 db2 = sv.getInputBits(320, msg.sender);  
for (uint i=0; i<nCount; i++) {  
require(ns[i]!=na);
}
ns[nCount++] = na;  
zs[zCount] = zb1;  
ds[zCount++] = db1;  
zs[zCount] = zb2;  
ds[zCount++] = db2;  
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