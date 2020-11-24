 

 

pragma solidity ^0.5.0;

contract AbstractENS {
    function owner(bytes32 _node) public view returns(address);
    function resolver(bytes32 _node) public view returns(address);
    function ttl(bytes32 _node) public view returns(uint64);
    function setOwner(bytes32 _node, address _owner) public;
    function setSubnodeOwner(bytes32 _node, bytes32 _label, address _owner) public;
    function setResolver(bytes32 _node, address _resolver) public;
    function setTTL(bytes32 _node, uint64 _ttl) public;

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

 

pragma solidity ^0.5.0;


 
contract PublicResolver {
    AbstractENS ens;
    mapping(bytes32=>address) addresses;
    mapping(bytes32=>bytes32) hashes;

    modifier only_owner(bytes32 _node) {
        require(ens.owner(_node) == msg.sender);
        _;
    }

     
    constructor(AbstractENS _ensAddr) public {
        ens = _ensAddr;
    }

     
    function has(bytes32 _node, bytes32 _kind) public view returns (bool) {
        return (_kind == "addr" && addresses[_node] != address(0)) || (_kind == "hash" && hashes[_node] != 0);
    }

     
    function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
        return _interfaceID == 0x3b3b57de || _interfaceID == 0xd8389dc5;
    }

     
    function addr(bytes32 _node) public view returns (address ret) {
        ret = addresses[_node];
    }

     
    function setAddr(bytes32 _node, address _addr) public only_owner(_node) {
        addresses[_node] = _addr;
    }

     
    function content(bytes32 _node) public view returns (bytes32 ret) {
        ret = hashes[_node];
    }

     
    function setContent(bytes32 _node, bytes32 _hash) public only_owner(_node) {
        hashes[_node] = _hash;
    }
}