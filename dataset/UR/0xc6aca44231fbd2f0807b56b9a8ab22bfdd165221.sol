 

pragma solidity ^0.4.24;

 
 
 
 
 

 
contract EnsRegistry {
	function setOwner(bytes32 node, address owner) public;
	function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
	function setResolver(bytes32 node, address resolver) public;
}

 
contract EnsResolver {
	function setAddr(bytes32 node, address addr) public;
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _owner) public onlyOwner {
    require(_owner != address(0));
    owner = _owner;
    emit OwnershipTransferred(owner, _owner);
  }
}

 
contract EnsSubdomainFactory is Ownable {
	EnsRegistry public registry = EnsRegistry(0x314159265dD8dbb310642f98f50C066173C1259b);
	EnsResolver public resolver = EnsResolver(0x5FfC014343cd971B7eb70732021E26C35B744cc4);

	event SubdomainCreated(bytes32 indexed subdomain, address indexed owner);

	constructor() public {
		owner = msg.sender;
	}

	 
	function setDomainOwner(bytes32 _node, address _owner) onlyOwner public {
		registry.setOwner(_node, _owner);
	}

	 
	function newSubdomain(bytes32 _node, bytes32 _subnode, bytes32 _label, address _owner, address _target) public {
		 
		registry.setSubnodeOwner(_node, _label, address(this));
		 
		registry.setResolver(_subnode, resolver);
		 
		resolver.setAddr(_subnode, _target);
		 
		registry.setOwner(_subnode, _owner);
		emit SubdomainCreated(_label, _owner);
	}
}