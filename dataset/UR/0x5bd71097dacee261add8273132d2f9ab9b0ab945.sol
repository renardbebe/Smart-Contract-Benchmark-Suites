 

pragma solidity ^0.4.0;

contract AbstractENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function ttl(bytes32 node) constant returns(uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);
}

 
contract TokenResolver {
    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes32 constant ROOT_NODE = 0x637f12e7cd6bed65eeceee34d35868279778fc56c3e5e951f46b801fb78a2d26;
    bytes TOKEN_JSON_ABI = '[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"name","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"totalSupply","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"decimals","type":"uint8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"symbol","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"}]';
    
    event AddrChanged(bytes32 indexed node, address a);

    AbstractENS ens = AbstractENS(0x314159265dD8dbb310642f98f50C066173C1259b);
    mapping(bytes32=>address) addresses;
    address owner;

    modifier only_node_owner(bytes32 node) {
        require(ens.owner(node) == msg.sender || owner == msg.sender);
        _;
    }
    
    modifier only_owner() {
        require(owner == msg.sender);
        _;
    }
    
    function setOwner(address newOwner) only_owner {
        owner = newOwner;
    }

    function newToken(string name, address addr) only_owner {
        var label = sha3(name);
        var node = sha3(ROOT_NODE, name);
        
        ens.setSubnodeOwner(ROOT_NODE, label, this);
        ens.setResolver(node, this);
        addresses[node] = addr;
        AddrChanged(node, addr);
    }
    
    function setSubnodeOwner(bytes22 label, address newOwner) only_owner {
        ens.setSubnodeOwner(ROOT_NODE, label, newOwner);
    }

    function TokenResolver() {
        owner = msg.sender;
    }

     
    function supportsInterface(bytes4 interfaceID) constant returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
               interfaceID == ABI_INTERFACE_ID ||
               interfaceID == INTERFACE_META_ID;
    }

     
    function addr(bytes32 node) constant returns (address ret) {
        ret = addresses[node];
    }

     
    function setAddr(bytes32 node, address addr) only_node_owner(node) {
        addresses[node] = addr;
        AddrChanged(node, addr);
    }

     
    function ABI(bytes32 node, uint256 contentTypes) constant returns (uint256 contentType, bytes data) {
        node;
        if(contentTypes & 1 == 1) {
             
            contentType = 1;
            data = TOKEN_JSON_ABI;
            return;
        }
        contentType = 0;
    }
}