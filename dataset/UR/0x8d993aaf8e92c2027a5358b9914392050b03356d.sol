 

pragma solidity ^0.4.13;
 
library Pairing {
struct G1Point {
uint X;
uint Y;
}
 
struct G2Point {
uint[2] X;
uint[2] Y;
}
 
function P1() pure internal returns (G1Point) {
return G1Point(1, 2);
}
 
function P2() pure internal returns (G2Point) {
return G2Point(
[11559732032986387107991004021392285783925812861821192530917403151452391805634,
10857046999023057135944570762232829481370756359578518086990519993285655852781],
[4082367875863433681332203403145435568316851327593401208105741076214120093531,
8495653923123431417604973247489272438418190587263600148770280649306958101930]
);
}
 
function negate(G1Point p) pure internal returns (G1Point) {
 
uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
if (p.X == 0 && p.Y == 0)
return G1Point(0, 0);
return G1Point(p.X, q - (p.Y % q));
}
 
function addition(G1Point p1, G1Point p2) internal returns (G1Point r) {
uint[4] memory input;
input[0] = p1.X;
input[1] = p1.Y;
input[2] = p2.X;
input[3] = p2.Y;
bool success;
assembly {
success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
 
switch success case 0 { invalid() }
}
require(success);
}
 
 
function scalar_mul(G1Point p, uint s) internal returns (G1Point r) {
uint[3] memory input;
input[0] = p.X;
input[1] = p.Y;
input[2] = s;
bool success;
assembly {
success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
 
switch success case 0 { invalid() }
}
require (success);
}
 
 
 
 
function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
require(p1.length == p2.length);
uint elements = p1.length;
uint inputSize = elements * 6;
uint[] memory input = new uint[](inputSize);
for (uint i = 0; i < elements; i++)
{
input[i * 6 + 0] = p1[i].X;
input[i * 6 + 1] = p1[i].Y;
input[i * 6 + 2] = p2[i].X[0];
input[i * 6 + 3] = p2[i].X[1];
input[i * 6 + 4] = p2[i].Y[0];
input[i * 6 + 5] = p2[i].Y[1];
}
uint[1] memory out;
bool success;
assembly {
success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
 
switch success case 0 { invalid() }
}
require(success);
return out[0] != 0;
}
 
function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
G1Point[] memory p1 = new G1Point[](2);
G2Point[] memory p2 = new G2Point[](2);
p1[0] = a1;
p1[1] = b1;
p2[0] = a2;
p2[1] = b2;
return pairing(p1, p2);
}
 
function pairingProd3(
G1Point a1, G2Point a2,
G1Point b1, G2Point b2,
G1Point c1, G2Point c2
) internal returns (bool) {
G1Point[] memory p1 = new G1Point[](3);
G2Point[] memory p2 = new G2Point[](3);
p1[0] = a1;
p1[1] = b1;
p1[2] = c1;
p2[0] = a2;
p2[1] = b2;
p2[2] = c2;
return pairing(p1, p2);
}
 
function pairingProd4(
G1Point a1, G2Point a2,
G1Point b1, G2Point b2,
G1Point c1, G2Point c2,
G1Point d1, G2Point d2
) internal returns (bool) {
G1Point[] memory p1 = new G1Point[](4);
G2Point[] memory p2 = new G2Point[](4);
p1[0] = a1;
p1[1] = b1;
p1[2] = c1;
p1[3] = d1;
p2[0] = a2;
p2[1] = b2;
p2[2] = c2;
p2[3] = d2;
return pairing(p1, p2);
}
}




contract Verifier {
using Pairing for *;
struct VerifyingKey {
Pairing.G2Point A;
Pairing.G1Point B;
Pairing.G2Point C;
Pairing.G2Point gamma;
Pairing.G1Point gammaBeta1;
Pairing.G2Point gammaBeta2;
Pairing.G2Point Z;
Pairing.G1Point[] IC;
}
struct Proof {
Pairing.G1Point A;
Pairing.G1Point A_p;
Pairing.G2Point B;
Pairing.G1Point B_p;
Pairing.G1Point C;
Pairing.G1Point C_p;
Pairing.G1Point K;
Pairing.G1Point H;
}
 
 
 
mapping(address => VerifyingKey) private vks;
mapping(address => uint[]) private vectors;
mapping(address => Pairing.G1Point) private vk_xs;




function setKeyLength(uint l) public {
vks[msg.sender].IC.length = l;
vectors[msg.sender].length = l-1;
}




function loadVerifyingKeyPreamble(
uint[2][2] A,
uint[2] B,
uint[2][2] C,
uint[2][2] gamma,
uint[2] gammaBeta1,
uint[2][2] gammaBeta2,
uint[2][2] Z
) public {
 
vks[msg.sender].A = Pairing.G2Point([A[0][0],A[0][1]],[A[1][0],A[1][1]]);
vks[msg.sender].B = Pairing.G1Point(B[0],B[1]);
vks[msg.sender].C = Pairing.G2Point([C[0][0],C[0][1]],[C[1][0],C[1][1]]);
vks[msg.sender].gamma = Pairing.G2Point([gamma[0][0],gamma[0][1]],[gamma[1][0],gamma[1][1]]);
vks[msg.sender].gammaBeta1 = Pairing.G1Point(gammaBeta1[0],gammaBeta1[1]);
vks[msg.sender].gammaBeta2 = Pairing.G2Point([gammaBeta2[0][0],gammaBeta2[0][1]],[gammaBeta2[1][0],gammaBeta2[1][1]]);
vks[msg.sender].Z = Pairing.G2Point([Z[0][0],Z[0][1]],[Z[1][0],Z[1][1]]);
 
vk_xs[msg.sender] = Pairing.G1Point(0, 0);  




}




function loadVerifyingKey(uint[2][] points, uint start) public{
 
 
for (uint i=0; i<points.length; i++){
vks[msg.sender].IC[i+start] = Pairing.G1Point(points[i][0],points[i][1]);
}
}




function loadInputVector(uint[] inp, uint start) public {
 
 
for (uint i=0; i<inp.length; i++){
vectors[msg.sender][i+start] = inp[i];
}
}
 
function getInputBits(uint start, address addr) public view returns(bytes8 param) {
 
param = 0x0; bytes8 b = bytes8(1);
for (uint i=0; i<64; i++){
if (vectors[addr][i+start] == 1) param = param | (b<<(63-i));
}
return param;
}




function computeVkx(uint start, uint end) public {
 
 
for (uint i = start; i < end; i++)
vk_xs[msg.sender] = Pairing.addition(vk_xs[msg.sender], Pairing.scalar_mul(vks[msg.sender].IC[i + 1], vectors[msg.sender][i]));
}




function getAddress() public returns(address){
return address(this);
}




function verify(Proof proof, address addr) internal returns (uint) {
require(vectors[addr].length + 1 == vks[addr].IC.length);
 
vk_xs[addr] = Pairing.addition(vk_xs[addr], vks[addr].IC[0]);
if (!Pairing.pairingProd2(proof.A, vks[addr].A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
if (!Pairing.pairingProd2(vks[addr].B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
if (!Pairing.pairingProd2(proof.C, vks[addr].C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
if (!Pairing.pairingProd3(
proof.K, vks[addr].gamma,
Pairing.negate(Pairing.addition(vk_xs[addr], Pairing.addition(proof.A, proof.C))), vks[addr].gammaBeta2,
Pairing.negate(vks[addr].gammaBeta1), proof.B
)) return 4;
if (!Pairing.pairingProd3(
Pairing.addition(vk_xs[addr], proof.A), proof.B,
Pairing.negate(proof.H), vks[addr].Z,
Pairing.negate(proof.C), Pairing.P2()
)) return 5;
return 0;
}
 
 
 
event Verified(bytes4 indexed _decodeFlag, bytes32 indexed _verified);




function verifyTx(
uint[2] a,
uint[2] a_p,
uint[2][2] b,
uint[2] b_p,
uint[2] c,
uint[2] c_p,
uint[2] h,
uint[2] k,
address addr
) public returns (bool r) {
Proof memory proof;
proof.A = Pairing.G1Point(a[0], a[1]);
proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
proof.C = Pairing.G1Point(c[0], c[1]);
proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
proof.H = Pairing.G1Point(h[0], h[1]);
proof.K = Pairing.G1Point(k[0], k[1]);
bytes4 decodeFlag = 0xdec0de;  
bytes32 verified;  
if (verify(proof, addr) == 0) {
vk_xs[addr].X =0; vk_xs[addr].Y=0;  
verified = 0x4559204f7073636861696e202d20547820566572696669656421203a29;  
emit Verified(decodeFlag, verified);
return true;
} else {
vk_xs[addr].X =0; vk_xs[addr].Y=0;  
verified = 0x4559204f7073636861696e202d205478204e4f54205665726966696564203a28;  
emit Verified(decodeFlag, verified);
return false;
}
}
}