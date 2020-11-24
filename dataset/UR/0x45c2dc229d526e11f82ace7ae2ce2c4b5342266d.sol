 

pragma solidity ^0.4.24;

 
 
 
 
 
 

 
contract EnsRegistry {
	function setOwner(bytes32 node, address owner) public;
	function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
	function setResolver(bytes32 node, address resolver) public;
	function owner(bytes32 node) public view returns (address);
}

 
contract EnsResolver {
	function setAddr(bytes32 node, address addr) public;
}

 
contract EnsSubdomainFactory {
	address public owner;
    EnsRegistry public registry = EnsRegistry(0x314159265dD8dbb310642f98f50C066173C1259b);
	EnsResolver public resolver = EnsResolver(0x5FfC014343cd971B7eb70732021E26C35B744cc4);
    bytes32 ethNameHash = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

	event SubdomainCreated(string indexed domain, string indexed subdomain, address indexed creator);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
	}

	 
	modifier onlyOwner() {
	  require(msg.sender == owner);
	  _;
	}

	 
	function newSubdomain(string _topLevelDomain, string _subDomain, address _owner, address _target) public {
	     
	    bytes32 topLevelNamehash = keccak256(abi.encodePacked(ethNameHash, keccak256(abi.encodePacked(_topLevelDomain))));
	     
        require(registry.owner(topLevelNamehash) == address(this), "this contract should own top level domain");
	     
	    bytes32 subDomainLabelhash = keccak256(abi.encodePacked(_subDomain));
	     
	    bytes32 subDomainNamehash = keccak256(abi.encodePacked(topLevelNamehash, subDomainLabelhash));
         
        require(registry.owner(subDomainNamehash) == address(0), "sub domain already owned");
		 
		registry.setSubnodeOwner(topLevelNamehash, subDomainLabelhash, address(this));
		 
		registry.setResolver(subDomainNamehash, resolver);
		 
		resolver.setAddr(subDomainNamehash, _target);
		 
		registry.setOwner(subDomainNamehash, _owner);
		
		emit SubdomainCreated(_topLevelDomain, _subDomain, msg.sender);
	}

	 
	function transferDomainOwnership(bytes32 _node, address _owner) public onlyOwner {
		registry.setOwner(_node, _owner);
	}

	 
	function transferContractOwnership(address _owner) public onlyOwner {
	  require(_owner != address(0));
	  owner = _owner;
	  emit OwnershipTransferred(owner, _owner);
	}
}