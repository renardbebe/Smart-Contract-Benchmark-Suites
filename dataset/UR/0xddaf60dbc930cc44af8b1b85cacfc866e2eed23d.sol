 

 
 
 

pragma solidity ^0.4.16;

 
contract Owned {
	modifier only_owner { if (msg.sender != owner) return; _; }

	event NewOwner(address indexed old, address indexed current);

	function setOwner(address _new) public only_owner { NewOwner(owner, _new); owner = _new; }

	address public owner = msg.sender;
}

 
contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address) public constant returns (bool);
	function get(address, string) public constant returns (bytes32);
	function getAddress(address, string) public constant returns (address);
	function getUint(address, string) public constant returns (uint);
}

 
contract MultiCertifier is Owned, Certifier {
	modifier only_delegate { require (msg.sender == owner || delegates[msg.sender]); _; }
	modifier only_certifier_of(address who) { require (msg.sender == owner || msg.sender == certs[who].certifier); _; }
	modifier only_certified(address who) { require (certs[who].active); _; }
	modifier only_uncertified(address who) { require (!certs[who].active); _; }

	event Confirmed(address indexed who, address indexed by);
	event Revoked(address indexed who, address indexed by);

	struct Certification {
		address certifier;
		bool active;
	}

	function certify(address _who)
		public
		only_delegate
		only_uncertified(_who)
	{
		certs[_who].active = true;
		certs[_who].certifier = msg.sender;
		Confirmed(_who, msg.sender);
	}

	function revoke(address _who)
		public
		only_certifier_of(_who)
		only_certified(_who)
	{
		certs[_who].active = false;
		Revoked(_who, msg.sender);
	}

	function certified(address _who) public constant returns (bool) { return certs[_who].active; }
	function getCertifier(address _who) public constant returns (address) { return certs[_who].certifier; }
	function addDelegate(address _new) public only_owner { delegates[_new] = true; }
	function removeDelegate(address _old) public only_owner { delete delegates[_old]; }

	mapping (address => Certification) certs;
	mapping (address => bool) delegates;

	 
	function get(address, string) public constant returns (bytes32) {}
	function getAddress(address, string) public constant returns (address) {}
	function getUint(address, string) public constant returns (uint) {}
}