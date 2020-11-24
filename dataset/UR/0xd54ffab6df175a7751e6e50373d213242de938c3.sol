 

pragma solidity ^0.5.8;


 

contract Owned {

     
    address public owner;

    event OwnerChanged(address indexed _newOwner);

     
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

     
     
    function isOwner(address _potentialOwner) external view returns (bool) {
        return owner == _potentialOwner;
    }

     
     
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

 

contract Managed is Owned {

     
    mapping (address => bool) public managers;

     
    modifier onlyManager {
        require(managers[msg.sender] == true, "Must be manager");
        _;
    }

    event ManagerAdded(address indexed _manager);
    event ManagerRevoked(address indexed _manager);

     
     
    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Address must not be null");
        if(managers[_manager] == false) {
            managers[_manager] = true;
            emit ManagerAdded(_manager);
        }
    }

     
     
    function revokeManager(address _manager) external onlyOwner {
        require(managers[_manager] == true, "Target must be an existing manager");
        delete managers[_manager];
        emit ManagerRevoked(_manager);
    }
}

 
contract EnsRegistry {

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

     
    event NewOwner(bytes32 indexed _node, bytes32 indexed _label, address _owner);

     
    event Transfer(bytes32 indexed _node, address _owner);

     
    event NewResolver(bytes32 indexed _node, address _resolver);

     
    event NewTTL(bytes32 indexed _node, uint64 _ttl);

     
    modifier only_owner(bytes32 _node) {
        require(records[_node].owner == msg.sender, "ENSTest: this method needs to be called by the owner of the node");
        _;
    }

     
    constructor() public {
        records[bytes32(0)].owner = msg.sender;
    }

     
    function owner(bytes32 _node) public view returns (address) {
        return records[_node].owner;
    }

     
    function resolver(bytes32 _node) public view returns (address) {
        return records[_node].resolver;
    }

     
    function ttl(bytes32 _node) public view returns (uint64) {
        return records[_node].ttl;
    }

     
    function setOwner(bytes32 _node, address _owner) public only_owner(_node) {
        emit Transfer(_node, _owner);
        records[_node].owner = _owner;
    }

     
    function setSubnodeOwner(bytes32 _node, bytes32 _label, address _owner) public only_owner(_node) {
        bytes32 subnode = keccak256(abi.encodePacked(_node, _label));
        emit NewOwner(_node, _label, _owner);
        records[subnode].owner = _owner;
    }

     
    function setResolver(bytes32 _node, address _resolver) public only_owner(_node) {
        emit NewResolver(_node, _resolver);
        records[_node].resolver = _resolver;
    }

     
    function setTTL(bytes32 _node, uint64 _ttl) public only_owner(_node) {
        emit NewTTL(_node, _ttl);
        records[_node].ttl = _ttl;
    }
}

 
contract EnsResolver {
    function setName(bytes32 _node, string calldata _name) external {}
}

 
contract EnsReverseRegistrar {
    
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    EnsRegistry public ens;
    EnsResolver public defaultResolver;

     
    constructor(address ensAddr, address resolverAddr) public {
        ens = EnsRegistry(ensAddr);
        defaultResolver = EnsResolver(resolverAddr);
    }

     
    function claim(address owner) public returns (bytes32) {
        return claimWithResolver(owner, address(0));
    }

     
    function claimWithResolver(address owner, address resolver) public returns (bytes32) {
        bytes32 label = sha3HexAddress(msg.sender);
        bytes32 node = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
        address currentOwner = ens.owner(node);

         
        if(resolver != address(0) && resolver != address(ens.resolver(node))) {
             
            if(currentOwner != address(this)) {
                ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, address(this));
                currentOwner = address(this);
            }
            ens.setResolver(node, resolver);
        }

         
        if(currentOwner != owner) {
            ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, owner);
        }

        return node;
    }

     
    function setName(string memory name) public returns (bytes32 node) {
        node = claimWithResolver(address(this), address(defaultResolver));
        defaultResolver.setName(node, name);
        return node;
    }

     
    function node(address addr) public returns (bytes32 ret) {
        return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
    }

     
    function sha3HexAddress(address addr) private returns (bytes32 ret) {
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000
            let i := 40

            for { } gt(i, 0) { } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }
            ret := keccak256(0, 40)
        }
    }
}


 

contract AuthereumEnsResolver is Managed {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;

    event AddrChanged(bytes32 indexed node, address a);
    event NameChanged(bytes32 indexed node, string name);

    struct Record {
        address addr;
        string name;
    }

    EnsRegistry ens;
    mapping (bytes32 => Record) records;
    address public authereumEnsManager;
    address public timelockContract;

     
     
     
    constructor(EnsRegistry ensAddr, address _timelockContract) public {
        ens = ensAddr;
        timelockContract = _timelockContract;
    }

     

     
     
     
     
    function setAddr(bytes32 node, address addr) public onlyManager {
        records[node].addr = addr;
        emit AddrChanged(node, addr);
    }

     
     
     
     
    function setName(bytes32 node, string memory name) public onlyManager {
        records[node].name = name;
        emit NameChanged(node, name);
    }

     

     
     
     
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

     
     
     
     
    function name(bytes32 node) public view returns (string memory) {
        return records[node].name;
    }

     
     
     
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
        interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID;
    }
}