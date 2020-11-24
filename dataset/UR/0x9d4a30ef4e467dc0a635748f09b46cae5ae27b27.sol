 

pragma solidity ^0.4.17;

 
contract DINRegistry {

    struct Record {
        address owner;
        address resolver;   
        uint256 updated;    
    }

     
    mapping (uint256 => Record) records;

     
    uint256 public genesis;

     
    uint256 public index;

    modifier only_owner(uint256 DIN) {
        require(records[DIN].owner == msg.sender);
        _;
    }

     
    event NewOwner(uint256 indexed DIN, address indexed owner);

     
    event NewResolver(uint256 indexed DIN, address indexed resolver);

     
    event NewRegistration(uint256 indexed DIN, address indexed owner);

     
    function DINRegistry(uint256 _genesis) public {
        genesis = _genesis;
        index = _genesis;

         
        records[_genesis].owner = msg.sender;
        records[_genesis].updated = block.timestamp;
        NewRegistration(_genesis, msg.sender);
    }

     
    function owner(uint256 _DIN) public view returns (address) {
        return records[_DIN].owner;
    }

     
    function setOwner(uint256 _DIN, address _owner) public only_owner(_DIN) {
        records[_DIN].owner = _owner;
        records[_DIN].updated = block.timestamp;
        NewOwner(_DIN, _owner);
    }

     
    function resolver(uint256 _DIN) public view returns (address) {
        return records[_DIN].resolver;
    }

     
    function setResolver(uint256 _DIN, address _resolver) public only_owner(_DIN) {
        records[_DIN].resolver = _resolver;
        records[_DIN].updated = block.timestamp;
        NewResolver(_DIN, _resolver);
    }

     
    function updated(uint256 _DIN) public view returns (uint256 _timestamp) {
        return records[_DIN].updated;
    }

     
    function selfRegisterDIN() public returns (uint256 _DIN) {
        return registerDIN(msg.sender);
    }

     
    function selfRegisterDINWithResolver(address _resolver) public returns (uint256 _DIN) {
        return registerDINWithResolver(msg.sender, _resolver);
    }

     
    function registerDIN(address _owner) public returns (uint256 _DIN) {
        index++;
        records[index].owner = _owner;
        records[index].updated = block.timestamp;
        NewRegistration(index, _owner);
        return index;
    }

     
    function registerDINWithResolver(address _owner, address _resolver) public returns (uint256 _DIN) {
        index++;
        records[index].owner = _owner;
        records[index].resolver = _resolver;
        records[index].updated = block.timestamp;
        NewRegistration(index, _owner);
        NewResolver(index, _resolver);
        return index;
    }

}

 
contract DINRegistryUtils {

    DINRegistry registry;

     
    function DINRegistryUtils(DINRegistry _registry) public {
        registry = _registry;
    }

     
    function selfRegisterDINs(uint256 amount) public {
        registerDINs(msg.sender, amount);
    }

     
    function selfRegisterDINsWithResolver(address resolver, uint256 amount) public {
        registerDINsWithResolver(msg.sender, resolver, amount);
    }

     
    function registerDINs(address owner, uint256 amount) public {
        for (uint i = 0; i < amount; i++) {
            registry.registerDIN(owner);
        }
    }

     
    function registerDINsWithResolver(address owner, address resolver, uint256 amount) public {
        for (uint i = 0; i < amount; i++) {
            registry.registerDINWithResolver(owner, resolver);
        }
    }

}