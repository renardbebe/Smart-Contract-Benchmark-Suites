 

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
    EnsRegistry public registry;
	EnsResolver public resolver;
	bool public locked;
    bytes32 ethNameHash = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

	event SubdomainCreated(address indexed creator, address indexed owner, string subdomain, string domain);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event RegistryUpdated(address indexed previousRegistry, address indexed newRegistry);
	event ResolverUpdated(address indexed previousResolver, address indexed newResolver);
	event TopLevelDomainTransfersLocked();

	constructor(EnsRegistry _registry, EnsResolver _resolver) public {
		owner = msg.sender;
		registry = _registry;
		resolver = _resolver;
		locked = false;
	}

	 
	modifier onlyOwner() {
	  require(msg.sender == owner);
	  _;
	}

	 
	function newSubdomain(string _subDomain, string _topLevelDomain, address _owner, address _target) public {
	     
	    bytes32 topLevelNamehash = keccak256(abi.encodePacked(ethNameHash, keccak256(abi.encodePacked(_topLevelDomain))));
	     
        require(registry.owner(topLevelNamehash) == address(this), "this contract should own top level domain");
	     
	    bytes32 subDomainLabelhash = keccak256(abi.encodePacked(_subDomain));
	     
	    bytes32 subDomainNamehash = keccak256(abi.encodePacked(topLevelNamehash, subDomainLabelhash));
         
        require(registry.owner(subDomainNamehash) == address(0) ||
            registry.owner(subDomainNamehash) == msg.sender, "sub domain already owned");
		 
		registry.setSubnodeOwner(topLevelNamehash, subDomainLabelhash, address(this));
		 
		registry.setResolver(subDomainNamehash, resolver);
		 
		resolver.setAddr(subDomainNamehash, _target);
		 
		registry.setOwner(subDomainNamehash, _owner);
		
		emit SubdomainCreated(msg.sender, _owner, _subDomain, _topLevelDomain);
	}

	 
	function topLevelDomainOwner(string _topLevelDomain) public view returns(address) {
		bytes32 namehash = keccak256(abi.encodePacked(ethNameHash, keccak256(abi.encodePacked(_topLevelDomain))));
		return registry.owner(namehash);
	}
	
	 
	function subDomainOwner(string _subDomain, string _topLevelDomain) public view returns(address) {
		bytes32 topLevelNamehash = keccak256(abi.encodePacked(ethNameHash, keccak256(abi.encodePacked(_topLevelDomain))));
		bytes32 subDomainNamehash = keccak256(abi.encodePacked(topLevelNamehash, keccak256(abi.encodePacked(_subDomain))));
		return registry.owner(subDomainNamehash);
	}

	 
	function transferTopLevelDomainOwnership(bytes32 _node, address _owner) public onlyOwner {
		require(!locked);
		registry.setOwner(_node, _owner);
	}

	 
	function lockTopLevelDomainOwnershipTransfers() public onlyOwner {
		require(!locked);
		locked = true;
		emit TopLevelDomainTransfersLocked();
	}

	 
	function updateRegistry(EnsRegistry _registry) public onlyOwner {
		require(registry != _registry, "new registry should be different from old");
		emit RegistryUpdated(registry, _registry);
		registry = _registry;
	}

	 
	function updateResolver(EnsResolver _resolver) public onlyOwner {
		require(resolver != _resolver, "new resolver should be different from old");
		emit ResolverUpdated(resolver, _resolver);
		resolver = _resolver;
	}

	 
	function transferContractOwnership(address _owner) public onlyOwner {
		require(_owner != address(0), "cannot transfer to address(0)");
		emit OwnershipTransferred(owner, _owner);
		owner = _owner;
	}
}