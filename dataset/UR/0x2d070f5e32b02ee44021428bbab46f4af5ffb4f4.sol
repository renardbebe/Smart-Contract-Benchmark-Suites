 

pragma solidity ^0.4.20;

interface SvEns {
     
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


 
contract SvEnsCompatibleRegistrar {
    SvEns public ens;
    bytes32 public rootNode;
    mapping (bytes32 => bool) knownNodes;
    mapping (address => bool) admins;
    address public owner;


    modifier req(bool c) {
        require(c);
        _;
    }


     
    function SvEnsCompatibleRegistrar(SvEns ensAddr, bytes32 node) public {
        ens = ensAddr;
        rootNode = node;
        admins[msg.sender] = true;
        owner = msg.sender;
    }

    function addAdmin(address newAdmin) req(admins[msg.sender]) external {
        admins[newAdmin] = true;
    }

    function remAdmin(address oldAdmin) req(admins[msg.sender]) external {
        require(oldAdmin != msg.sender && oldAdmin != owner);
        admins[oldAdmin] = false;
    }

    function chOwner(address newOwner, bool remPrevOwnerAsAdmin) req(msg.sender == owner) external {
        if (remPrevOwnerAsAdmin) {
            admins[owner] = false;
        }
        owner = newOwner;
        admins[newOwner] = true;
    }

     
    function register(bytes32 subnode, address _owner) req(admins[msg.sender]) external {
        _setSubnodeOwner(subnode, _owner);
    }

     
    function registerName(string subnodeStr, address _owner) req(admins[msg.sender]) external {
         
        bytes32 subnode = keccak256(subnodeStr);
        _setSubnodeOwner(subnode, _owner);
    }

     
    function _setSubnodeOwner(bytes32 subnode, address _owner) internal {
        require(!knownNodes[subnode]);
        knownNodes[subnode] = true;
        ens.setSubnodeOwner(rootNode, subnode, _owner);
    }
}