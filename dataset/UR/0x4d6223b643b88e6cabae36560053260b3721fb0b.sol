 

pragma solidity ^0.4.13;

 

contract Products {

	uint8 constant STATUS_ADDED = 1;

	uint8 constant STATUS_REGISTERED = 2;

	 
	address public owner;

	 
	mapping (bytes32 => uint8) items;

	 
	function Products() {
		owner = msg.sender;
	}

	 
	function() {
		revert();
	}

	 
	function getPublicForSecretFor(bytes32 secret) constant returns (bytes32 pubkey) {
		pubkey = sha3(secret);
	}

	 
	function addItem(bytes32 pubkey) public returns (bool) {
		if (msg.sender != owner) {
			revert();
		}
		items[pubkey] = STATUS_ADDED;
	}

	 
	function checkItem(bytes32 pubkey) constant returns (uint8 a) {
		a = items[pubkey];
	}

	 
	function updateRequestSeed(bytes32 pubkey, bytes32 secret) returns (bool) {
		if (items[pubkey] != STATUS_ADDED) {
			revert();
		}
		if (!(sha3(secret) == pubkey)) {
			revert();
		}
		items[pubkey] = STATUS_REGISTERED;
	}
}