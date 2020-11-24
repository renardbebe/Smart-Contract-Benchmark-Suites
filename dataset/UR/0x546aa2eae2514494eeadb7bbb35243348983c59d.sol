 

pragma solidity 0.4.24;
 
interface AbstractENS {
    function owner(bytes32 _node) public constant returns (address);
    function resolver(bytes32 _node) public constant returns (address);
    function ttl(bytes32 _node) public constant returns (uint64);
    function setOwner(bytes32 _node, address _owner) public;
    function setSubnodeOwner(bytes32 _node, bytes32 label, address _owner) public;
    function setResolver(bytes32 _node, address _resolver) public;
    function setTTL(bytes32 _node, uint64 _ttl) public;

     
    event NewOwner(bytes32 indexed _node, bytes32 indexed _label, address _owner);

     
    event Transfer(bytes32 indexed _node, address _owner);

     
    event NewResolver(bytes32 indexed _node, address _resolver);

     
    event NewTTL(bytes32 indexed _node, uint64 _ttl);
}
 
interface IPublicResolver {
    function supportsInterface(bytes4 interfaceID) constant returns (bool);
    function addr(bytes32 node) constant returns (address ret);
    function setAddr(bytes32 node, address addr);
    function hash(bytes32 node) constant returns (bytes32 ret);
    function setHash(bytes32 node, bytes32 hash);
}
 
interface IFIFSResolvingRegistrar {
    function register(bytes32 _subnode, address _owner) external;
    function registerWithResolver(bytes32 _subnode, address _owner, IPublicResolver _resolver) public;
}
 
 
contract FIFSResolvingRegistrar is IFIFSResolvingRegistrar {
    bytes32 public rootNode;
    AbstractENS internal ens;
    IPublicResolver internal defaultResolver;

    bytes4 private constant ADDR_INTERFACE_ID = 0x3b3b57de;

    event ClaimSubdomain(bytes32 indexed subnode, address indexed owner, address indexed resolver);

     
    constructor(AbstractENS _ensAddr, IPublicResolver _defaultResolver, bytes32 _node)
        public
    {
        ens = _ensAddr;
        defaultResolver = _defaultResolver;
        rootNode = _node;
    }

     
    function register(bytes32 _subnode, address _owner) external {
        registerWithResolver(_subnode, _owner, defaultResolver);
    }

     
    function registerWithResolver(bytes32 _subnode, address _owner, IPublicResolver _resolver) public {
        bytes32 node = keccak256(rootNode, _subnode);
        address currentOwner = ens.owner(node);
        require(currentOwner == address(0));

        ens.setSubnodeOwner(rootNode, _subnode, address(this));
        ens.setResolver(node, _resolver);
        if (_resolver.supportsInterface(ADDR_INTERFACE_ID)) {
            _resolver.setAddr(node, _owner);
        }

         
        ens.setOwner(node, _owner);

        emit ClaimSubdomain(_subnode, _owner, address(_resolver));
    }
}