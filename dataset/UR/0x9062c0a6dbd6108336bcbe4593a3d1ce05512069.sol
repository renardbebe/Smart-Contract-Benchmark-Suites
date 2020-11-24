 

pragma solidity ^0.4.10;

contract AbstractENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function ttl(bytes32 node) constant returns(uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);
}

contract Resolver {
    function setName(bytes32 node, string name) public;
}

 
contract DefaultReverseResolver is Resolver {
     
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    AbstractENS public ens;
    mapping(bytes32=>string) public name;
    
     
    function DefaultReverseResolver(AbstractENS ensAddr) {
        ens = ensAddr;

         
        var registrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
        if(address(registrar) != 0) {
            registrar.claim(msg.sender);
        }
    }

     
    modifier owner_only(bytes32 node) {
        require(msg.sender == ens.owner(node));
        _;
    }

     
    function setName(bytes32 node, string _name) public owner_only(node) {
        name[node] = _name;
    }
}

contract ReverseRegistrar {
     
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    AbstractENS public ens;
    Resolver public defaultResolver;

     
    function ReverseRegistrar(AbstractENS ensAddr, Resolver resolverAddr) {
        ens = ensAddr;
        defaultResolver = resolverAddr;

         
        var oldRegistrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
        if(address(oldRegistrar) != 0) {
            oldRegistrar.claim(msg.sender);
        }
    }
    
     
    function claim(address owner) returns (bytes32 node) {
        return claimWithResolver(owner, 0);
    }

     
    function claimWithResolver(address owner, address resolver) returns (bytes32 node) {
        var label = sha3HexAddress(msg.sender);
        node = sha3(ADDR_REVERSE_NODE, label);
        var currentOwner = ens.owner(node);

         
        if(resolver != 0 && resolver != ens.resolver(node)) {
             
            if(currentOwner != address(this)) {
                ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, this);
                currentOwner = address(this);
            }
            ens.setResolver(node, resolver);
        }

         
        if(currentOwner != owner) {
            ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, owner);
        }

        return node;
    }

     
    function setName(string name) returns (bytes32 node) {
        node = claimWithResolver(this, defaultResolver);
        defaultResolver.setName(node, name);
        return node;
    }

     
    function node(address addr) constant returns (bytes32 ret) {
        return sha3(ADDR_REVERSE_NODE, sha3HexAddress(addr));
    }

     
    function sha3HexAddress(address addr) private returns (bytes32 ret) {
        addr; ret;  
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000
            let i := 40
        loop:
            i := sub(i, 1)
            mstore8(i, byte(and(addr, 0xf), lookup))
            addr := div(addr, 0x10)
            i := sub(i, 1)
            mstore8(i, byte(and(addr, 0xf), lookup))
            addr := div(addr, 0x10)
            jumpi(loop, i)
            ret := sha3(0, 40)
        }
    }
}