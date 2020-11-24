 

pragma solidity ^0.4.11;

 
contract DINRegistry {

    struct Record {
        address owner;
        address resolver;   
        uint256 updated;    
    }

     
    mapping (uint256 => Record) records;

     
    address public registrar;

     
    uint256 public genesis;

    modifier only_registrar {
        require(registrar == msg.sender);
        _;
    }

    modifier only_owner(uint256 DIN) {
        require(records[DIN].owner == msg.sender);
        _;
    }

     
    event NewOwner(uint256 indexed DIN, address indexed owner);

     
    event NewResolver(uint256 indexed DIN, address indexed resolver);

     
    event NewRegistration(uint256 indexed DIN, address indexed owner);

     
    event NewRegistrar(address indexed registrar);

     
    function DINRegistry(uint256 _genesis) {
        genesis = _genesis;

         
        records[genesis].owner = msg.sender;
        records[genesis].updated = block.timestamp;
        NewRegistration(genesis, msg.sender);
    }

     
    function owner(uint256 DIN) constant returns (address) {
        return records[DIN].owner;
    }

     
    function setOwner(uint256 DIN, address owner) only_owner(DIN) {
        records[DIN].owner = owner;
        records[DIN].updated = block.timestamp;
        NewOwner(DIN, owner);
    }

     
    function resolver(uint256 DIN) constant returns (address) {
        return records[DIN].resolver;
    }

     
    function setResolver(uint256 DIN, address resolver) only_owner(DIN) {
        records[DIN].resolver = resolver;
        records[DIN].updated = block.timestamp;
        NewResolver(DIN, resolver);
    }

     
    function updated(uint256 DIN) constant returns (uint256) {
        return records[DIN].updated;
    } 

     
    function register(uint256 DIN, address owner) only_registrar {
        records[DIN].owner = owner;
        records[DIN].updated = block.timestamp;
        NewRegistration(DIN, owner);
    }

     
    function setRegistrar(address _registrar) only_owner(genesis) {
        registrar = _registrar;
        NewRegistrar(_registrar);
    }

}

 
contract DINRegistrar {

     
    DINRegistry registry;

     
    uint256 public index;

     
    uint256 public MAX_QUANTITY = 10;

     
    function DINRegistrar(DINRegistry _registry, uint256 _genesis) {
        registry = _registry;

         
        index = _genesis;
    }

     
    function registerDIN() returns (uint256 DIN) {
        index++;
        registry.register(index, msg.sender);
        return index;
    }

     
    function registerDINs(uint256 quantity) {
        require(quantity <= MAX_QUANTITY);

        for (uint i = 0; i < quantity; i++) {
            registerDIN();
        }
    }

}