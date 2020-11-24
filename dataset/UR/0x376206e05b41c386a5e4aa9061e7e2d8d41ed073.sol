 

pragma solidity ^0.4.4;
 
contract XG4K {	
	mapping (address => uint) public balances;
	function XG4K() {
		balances[tx.origin] = 100000;
	}
	function sendToken(address receiver, uint amount) returns(bool successful){
		if (balances[msg.sender] < amount) return false;
 		balances[msg.sender] -= amount;
 		balances[receiver] += amount;
 		return false;
 	}
} 
contract coinSpawn{
 	mapping(uint => XG4K) deployedContracts;
	uint numContracts;
	function createCoin() returns(address a){
		deployedContracts[numContracts] = new XG4K();
		numContracts++;
		return deployedContracts[numContracts];
	}
}