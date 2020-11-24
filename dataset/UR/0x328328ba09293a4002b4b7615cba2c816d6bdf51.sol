 

 

pragma solidity ^0.5.0;

interface RegistrarInterface {

    event Registration(string name, address owner, address addr);

    function register(string calldata name, address owner, bytes calldata signature) external;
    function hash(string calldata name, address owner) external pure returns (bytes32);
}

 

pragma solidity ^0.5.0;

library SignatureValidator {

     
     
     
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65);

        uint8 v = uint8(signature[64]);
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
        }

        return ecrecover(hash, v, r, s);
    }
}

 

pragma solidity >=0.4.24;

interface ENS {

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}

 

pragma solidity >=0.4.25;


 
contract PublicResolver {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 constant CONTENTHASH_INTERFACE_ID = 0xbc1c58d1;

    event AddrChanged(bytes32 indexed node, address a);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
        bytes contenthash;
    }

    ENS ens;

    mapping (bytes32 => Record) records;

    modifier onlyOwner(bytes32 node) {
        require(ens.owner(node) == msg.sender);
        _;
    }

     
    constructor(ENS ensAddr) public {
        ens = ensAddr;
    }

     
    function setAddr(bytes32 node, address addr) external onlyOwner(node) {
        records[node].addr = addr;
        emit AddrChanged(node, addr);
    }

     
    function setContenthash(bytes32 node, bytes calldata hash) external onlyOwner(node) {
        records[node].contenthash = hash;
        emit ContenthashChanged(node, hash);
    }

     
    function setName(bytes32 node, string calldata name) external onlyOwner(node) {
        records[node].name = name;
        emit NameChanged(node, name);
    }

     
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external onlyOwner(node) {
         
        require(((contentType - 1) & contentType) == 0);

        records[node].abis[contentType] = data;
        emit ABIChanged(node, contentType);
    }

     
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external onlyOwner(node) {
        records[node].pubkey = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

     
    function setText(bytes32 node, string calldata key, string calldata value) external onlyOwner(node) {
        records[node].text[key] = value;
        emit TextChanged(node, key, key);
    }

     
    function text(bytes32 node, string calldata key) external view returns (string memory) {
        return records[node].text[key];
    }

     
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

     
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory) {
        Record storage record = records[node];

        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                return (contentType, record.abis[contentType]);
            }
        }

        bytes memory empty;
        return (0, empty);
    }

     
    function name(bytes32 node) external view returns (string memory) {
        return records[node].name;
    }

     
    function addr(bytes32 node) external view returns (address) {
        return records[node].addr;
    }

     
    function contenthash(bytes32 node) external view returns (bytes memory) {
        return records[node].contenthash;
    }

     
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID ||
        interfaceID == ABI_INTERFACE_ID ||
        interfaceID == PUBKEY_INTERFACE_ID ||
        interfaceID == TEXT_INTERFACE_ID ||
        interfaceID == CONTENTHASH_INTERFACE_ID ||
        interfaceID == INTERFACE_META_ID;
    }
}

 

pragma solidity ^0.5.0;





contract Registrar is RegistrarInterface {

    ENS public ens;
    bytes32 public node;
    PublicResolver public resolver;

    constructor(ENS _ens, bytes32 _node, PublicResolver _resolver) public {
        ens = _ens;
        node = _node;
        resolver = _resolver;
    }

    function register(string calldata name, address owner, bytes calldata signature) external {
        address token = SignatureValidator.recover(_hash(name, owner), signature);

        bytes32 label = keccak256(bytes(name));
        bytes32 subnode = keccak256(abi.encodePacked(node, label));

         
        ens.setSubnodeOwner(node, label, address(this));

         
        ens.setResolver(subnode, address(resolver));

         
        resolver.setAddr(subnode, owner);

         
        ens.setOwner(subnode, owner);

        emit Registration(name, owner, token);
    }

    function hash(string calldata name, address owner) external pure returns (bytes32) {
        return _hash(name, owner);
    }

    function _hash(string memory name, address owner) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, owner));
    }
}