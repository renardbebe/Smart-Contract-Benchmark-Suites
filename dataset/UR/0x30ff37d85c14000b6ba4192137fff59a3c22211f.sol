 

pragma solidity ^0.4.20;

interface ENS {

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
}


 
contract SvEnsRegistry is ENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping (bytes32 => Record) records;

     
    modifier only_owner(bytes32 node) {
        require(records[node].owner == msg.sender);
        _;
    }

     
    function SvEnsRegistry() public {
        records[0x0].owner = msg.sender;
    }

     
    function setOwner(bytes32 node, address owner) external only_owner(node) {
        emit Transfer(node, owner);
        records[node].owner = owner;
    }

     
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external only_owner(node) returns (bytes32) {
        bytes32 subnode = keccak256(node, label);
        emit NewOwner(node, label, owner);
        records[subnode].owner = owner;
        return subnode;
    }

     
    function setResolver(bytes32 node, address resolver) external only_owner(node) {
        emit NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

     
    function setTTL(bytes32 node, uint64 ttl) external only_owner(node) {
        emit NewTTL(node, ttl);
        records[node].ttl = ttl;
    }

     
    function owner(bytes32 node) external view returns (address) {
        return records[node].owner;
    }

     
    function resolver(bytes32 node) external view returns (address) {
        return records[node].resolver;
    }

     
    function ttl(bytes32 node) external view returns (uint64) {
        return records[node].ttl;
    }

}