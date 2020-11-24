 

pragma solidity ^0.4.18;



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

pragma solidity ^0.4.0;

 
contract PublicResolver {
    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
    }

    AbstractENS ens;
    mapping(bytes32=>Record) records;

    modifier only_owner(bytes32 node) {
        if (ens.owner(node) != msg.sender) throw;
        _;
    }

     
    function PublicResolver(AbstractENS ensAddr) public {
        ens = ensAddr;
    }

     
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
               interfaceID == CONTENT_INTERFACE_ID ||
               interfaceID == NAME_INTERFACE_ID ||
               interfaceID == ABI_INTERFACE_ID ||
               interfaceID == PUBKEY_INTERFACE_ID ||
               interfaceID == TEXT_INTERFACE_ID ||
               interfaceID == INTERFACE_META_ID;
    }

     
    function addr(bytes32 node) public constant returns (address ret) {
        ret = records[node].addr;
    }

     
    function setAddr(bytes32 node, address addr) only_owner(node) public {
        records[node].addr = addr;
        AddrChanged(node, addr);
    }

     
    function content(bytes32 node) public constant returns (bytes32 ret) {
        ret = records[node].content;
    }

     
    function setContent(bytes32 node, bytes32 hash) only_owner(node) public {
        records[node].content = hash;
        ContentChanged(node, hash);
    }

     
    function name(bytes32 node) public constant returns (string ret) {
        ret = records[node].name;
    }

     
    function setName(bytes32 node, string name) only_owner(node) public {
        records[node].name = name;
        NameChanged(node, name);
    }

     
    function ABI(bytes32 node, uint256 contentTypes) public constant returns (uint256 contentType, bytes data) {
        var record = records[node];
        for(contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

     
    function setABI(bytes32 node, uint256 contentType, bytes data) only_owner(node) public {
         
        if (((contentType - 1) & contentType) != 0) throw;

        records[node].abis[contentType] = data;
        ABIChanged(node, contentType);
    }

     
    function pubkey(bytes32 node) public constant returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

     
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) only_owner(node) public {
        records[node].pubkey = PublicKey(x, y);
        PubkeyChanged(node, x, y);
    }

     
    function text(bytes32 node, string key) public constant returns (string ret) {
        ret = records[node].text[key];
    }

     
    function setText(bytes32 node, string key, string value) only_owner(node) public {
        records[node].text[key] = value;
        TextChanged(node, key, key);
    }
}


 

pragma solidity ^0.4.24;


contract ENSConstants {
    bytes32 constant public ENS_ROOT = bytes32(0);
    bytes32 constant public ETH_TLD_LABEL = keccak256("eth");
    bytes32 constant public ETH_TLD_NODE = keccak256(abi.encodePacked(ENS_ROOT, ETH_TLD_LABEL));
    bytes32 constant public PUBLIC_RESOLVER_LABEL = keccak256("resolver");
    bytes32 constant public PUBLIC_RESOLVER_NODE = keccak256(abi.encodePacked(ETH_TLD_NODE, PUBLIC_RESOLVER_LABEL));
}


contract dwebregistry is ENSConstants {
    
    AbstractENS public ens;
    bytes32 public rootNode;
    
    event NewDWeb(bytes32 indexed node, bytes32 indexed label, string hash);

    function initialize(AbstractENS _ens, bytes32 _rootNode) public {

         
        require(_ens.owner(_rootNode) == address(this));
        require(ens == address(0));
        require(rootNode == 0);

        ens = _ens;
        rootNode = _rootNode;
    }
    
    function createDWeb(bytes32 _label, string hash) external returns (bytes32 node) {
        return _createDWeb(_label, msg.sender, hash);
    }

    function _createDWeb(bytes32 _label, address _owner, string hash) internal returns (bytes32 node) {
        node = getNodeForLabel(_label);
    
        require(ens.owner(rootNode) == address(this));
        require(ens.owner(node) == address(0));  
        
        ens.setSubnodeOwner(rootNode, _label, address(this));
        
        address publicResolver = getAddr(PUBLIC_RESOLVER_NODE);
        ens.setResolver(node, publicResolver);

        PublicResolver(publicResolver).setText(node,'dnslink', hash);
        PublicResolver(publicResolver).setContent(node, bytes(hash)[32]);
    
        ens.setSubnodeOwner(rootNode, _label, _owner);

        emit NewDWeb(node, _label, hash);

        return node;
    }
    
    function getAddr(bytes32 node) internal view returns (address) {
        address resolver = ens.resolver(node);
        return PublicResolver(resolver).addr(node);
    }
    
    function getNodeForLabel(bytes32 _label) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(rootNode, _label));
    }

}