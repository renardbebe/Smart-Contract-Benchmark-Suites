 

pragma solidity ^0.4.24;

 
contract EnsRegistry {
	function setOwner(bytes32 node, address owner) public;
	function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
	function setResolver(bytes32 node, address resolver) public;
	function owner(bytes32 node) public view returns (address);
	function resolver(bytes32 node) public view returns (address);
}

 
contract EnsResolver {
	function setAddr(bytes32 node, address addr) public;
	function addr(bytes32 node) public view returns (address);
}

 
contract SubdomainRegistrar {
	address public owner;
	bool public locked;
    bytes32 emptyNamehash = 0x00;

	mapping (string => EnsRegistry) registries;
	mapping (string => EnsResolver) resolvers;

	event SubdomainCreated(address indexed creator, address indexed owner, string subdomain, string domain, string topdomain);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event RegistryUpdated(address indexed previousRegistry, address indexed newRegistry);
	event ResolverUpdated(address indexed previousResolver, address indexed newResolver);
	event DomainTransfersLocked();
	event DomainTransfersUnlocked();

	constructor(string tld, EnsRegistry _registry, EnsResolver _resolver) public {
		owner = msg.sender;
		registries[tld] = _registry;
		resolvers[tld] = _resolver;
		locked = false;

	}

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier supportedTLD(string tld) {
		require(registries[tld] != address(0) && resolvers[tld] != address(0));
		_;
	}

	 
	function newSubdomain(string _subdomain, string _domain, string _topdomain, address _owner, address _target) public supportedTLD(_topdomain) {
		 
		bytes32 topdomainNamehash = keccak256(abi.encodePacked(emptyNamehash, keccak256(abi.encodePacked(_topdomain))));
		 
		bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
		 
		require(registries[_topdomain].owner(domainNamehash) == address(this), "this contract should own the domain");
		 
		bytes32 subdomainLabelhash = keccak256(abi.encodePacked(_subdomain));
		 
		bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, subdomainLabelhash));
		 
		require(registries[_topdomain].owner(subdomainNamehash) == address(0) ||
			registries[_topdomain].owner(subdomainNamehash) == msg.sender, "sub domain already owned");
		 
		registries[_topdomain].setSubnodeOwner(domainNamehash, subdomainLabelhash, address(this));
		 
		registries[_topdomain].setResolver(subdomainNamehash, resolvers[_topdomain]);
		 
		resolvers[_topdomain].setAddr(subdomainNamehash, _target);
		 
		registries[_topdomain].setOwner(subdomainNamehash, _owner);

		emit SubdomainCreated(msg.sender, _owner, _subdomain, _domain, _topdomain);
	}

	 
	function domainOwner(string _domain, string _topdomain) public view returns (address) {
		bytes32 topdomainNamehash = keccak256(abi.encodePacked(emptyNamehash, keccak256(abi.encodePacked(_topdomain))));
		bytes32 namehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
		return registries[_topdomain].owner(namehash);
	}

	 
	function subdomainOwner(string _subdomain, string _domain, string _topdomain) public view returns (address) {
		bytes32 topdomainNamehash = keccak256(abi.encodePacked(emptyNamehash, keccak256(abi.encodePacked(_topdomain))));
		bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
		bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(_subdomain))));
		return registries[_topdomain].owner(subdomainNamehash);
	}

     
    function subdomainTarget(string _subdomain, string _domain, string _topdomain) public view returns (address) {
        bytes32 topdomainNamehash = keccak256(abi.encodePacked(emptyNamehash, keccak256(abi.encodePacked(_topdomain))));
        bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
        bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(_subdomain))));
        address currentResolver = registries[_topdomain].resolver(subdomainNamehash);
        return EnsResolver(currentResolver).addr(subdomainNamehash);
    }

	 
	function transferDomainOwnership(string tld, bytes32 _node, address _owner) public supportedTLD(tld) onlyOwner {
		require(!locked);
		registries[tld].setOwner(_node, _owner);
	}

	 
	function lockDomainOwnershipTransfers() public onlyOwner {
		require(!locked);
		locked = true;
		emit DomainTransfersLocked();
	}

	function unlockDomainOwnershipTransfer() public onlyOwner {
		require(locked);
		locked = false;
		emit DomainTransfersUnlocked();
	}

	 
	function updateRegistry(string tld, EnsRegistry _registry) public onlyOwner {
		require(registries[tld] != _registry, "new registry should be different from old");
		emit RegistryUpdated(registries[tld], _registry);
		registries[tld] = _registry;
	}

	 
	function updateResolver(string tld, EnsResolver _resolver) public onlyOwner {
		require(resolvers[tld] != _resolver, "new resolver should be different from old");
		emit ResolverUpdated(resolvers[tld], _resolver);
		resolvers[tld] = _resolver;
	}

	 
	function transferContractOwnership(address _owner) public onlyOwner {
		require(_owner != address(0), "cannot transfer to address(0)");
		emit OwnershipTransferred(owner, _owner);
		owner = _owner;
	}
}