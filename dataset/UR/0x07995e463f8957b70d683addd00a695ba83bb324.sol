 

 
 
 

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

contract VouchFor {
    
    event Vouched(address who, bytes32 what);

    function VouchFor(address _certifier) public {
        certifier = Certifier(_certifier);
    }
    
    function vouch(bytes32 _what)
        public
        only_certified
    {
        vouchers[_what].push(msg.sender);
        Vouched(msg.sender, _what);
    }
    
    function vouched(bytes32 _what, uint _index)
        public
        constant
        returns (address)
    {
        return vouchers[_what][_index];
    }
    
    function unvouch(bytes32 _what, uint _index)
        public
    {
        uint count = vouchers[_what].length;
        require (count > 0);
        require (_index < count);
        require (vouchers[_what][_index] == msg.sender);
        if (_index != count - 1) {
            vouchers[_what][_index] = vouchers[_what][count - 1];
        }
        delete vouchers[_what][count - 1];
        vouchers[_what].length = count - 1;
    }
    
    modifier only_certified {
        require (certifier.certified(msg.sender));
        _;
    }
    
    mapping (bytes32 => address[]) public vouchers;
    Certifier public certifier;
}