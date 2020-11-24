 

 
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

contract owned {
    address owner;
    
    function owned() {
        owner = msg.sender;
    }
    
    modifier owner_only() {
        if(msg.sender != owner) throw;
        _;
    }
    
    function setOwner(address _owner) owner_only {
        owner = _owner;
    }
}

contract Resolver {
    function setAddr(bytes32 node, address addr);
}

contract ReverseRegistrar {
    function claim(address owner) returns (bytes32 node);
}

contract SimpleRegistrar is owned {
     
    bytes32 constant RR_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    event HashRegistered(bytes32 indexed hash, address indexed owner);

    AbstractENS public ens;
    bytes32 public rootNode;
    uint public fee;
     
    Resolver public resolver;
    
    function SimpleRegistrar(AbstractENS _ens, bytes32 _rootNode, uint _fee, Resolver _resolver) {
        ens = _ens;
        rootNode = _rootNode;
        fee = _fee;
        resolver = _resolver;
        
         
        ReverseRegistrar(ens.owner(RR_NODE)).claim(msg.sender);
    }
    
    function withdraw() owner_only {
        if(!msg.sender.send(this.balance)) throw;
    }
    
    function setFee(uint _fee) owner_only {
        fee = _fee;
    }
    
    function setResolver(Resolver _resolver) owner_only {
        resolver = _resolver;
    }
    
    modifier can_register(bytes32 label) {
        if(ens.owner(sha3(rootNode, label)) != 0 || msg.value < fee) throw;
        _;
    }
    
    function register(string name) payable can_register(sha3(name)) {
        var label = sha3(name);
        
         
        ens.setSubnodeOwner(rootNode, label, this);
        
         
        var node = sha3(rootNode, label);
        ens.setResolver(node, resolver);
        resolver.setAddr(node, msg.sender);
        
         
        ens.setOwner(node, msg.sender);
        
        HashRegistered(label, msg.sender);
        
         
        if(msg.value > fee) {
            if(!msg.sender.send(msg.value - fee)) throw;
        }
    }
}