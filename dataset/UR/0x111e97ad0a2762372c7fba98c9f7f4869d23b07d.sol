 

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
        bytes32 emptyNamehash = 0x00;

	event SubdomainCreated(address indexed creator, address indexed owner, string subdomain, string domain, string topdomain);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event RegistryUpdated(address indexed previousRegistry, address indexed newRegistry);
	event ResolverUpdated(address indexed previousResolver, address indexed newResolver);
	event DomainTransfersLocked();

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

	 
	function newSubdomain(string _subdomain, string _domain, string _topdomain, address _owner, address _target) public {
		 
		bytes32 topdomainNamehash = keccak256(abi.encodePacked(emptyNamehash, keccak256(abi.encodePacked(_topdomain))));
		 
		bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
		 
		require(registry.owner(domainNamehash) == address(this), "this contract should own the domain");
		 
		bytes32 subdomainLabelhash = keccak256(abi.encodePacked(_subdomain));
		 
		bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, subdomainLabelhash));
		 
		require(registry.owner(subdomainNamehash) == address(0) ||
			registry.owner(subdomainNamehash) == msg.sender, "sub domain already owned");
		 
		registry.setSubnodeOwner(domainNamehash, subdomainLabelhash, address(this));
		 
		registry.setResolver(subdomainNamehash, resolver);
		 
		resolver.setAddr(subdomainNamehash, _target);
		 
		registry.setOwner(subdomainNamehash, _owner);

		emit SubdomainCreated(msg.sender, _owner, _subdomain, _domain, _topdomain);
	}

	 
	function domainOwner(string _domain, string _topdomain) public view returns(address) {
		bytes32 topdomainNamehash = keccak256(abi.encodePacked(emptyNamehash, keccak256(abi.encodePacked(_topdomain))));
		bytes32 namehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
		return registry.owner(namehash);
	}

	 
	function subdomainOwner(string _subdomain, string _domain, string _topdomain) public view returns(address) {
		bytes32 topdomainNamehash = keccak256(abi.encodePacked(emptyNamehash, keccak256(abi.encodePacked(_topdomain))));
		bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
		bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(_subdomain))));
		return registry.owner(subdomainNamehash);
	}

	 
	function transferDomainOwnership(bytes32 _node, address _owner) public onlyOwner {
		require(!locked);
		registry.setOwner(_node, _owner);
	}

	 
	function lockDomainOwnershipTransfers() public onlyOwner {
		require(!locked);
		locked = true;
		emit DomainTransfersLocked();
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