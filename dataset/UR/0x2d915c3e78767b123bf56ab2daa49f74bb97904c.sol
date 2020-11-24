 

pragma solidity ^0.4.8;

contract ENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function ttl(bytes32 node) constant returns(uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

contract ReverseRegistrar {
    function setName(string name) returns (bytes32 node);
    function claimWithResolver(address owner, address resolver) returns (bytes32 node);
}

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract ShibbolethToken is StandardToken {
    ENS ens;    

    string public name;
    string public symbol;
    address public issuer;

    function version() constant returns(string) { return "S0.1"; }
    function decimals() constant returns(uint8) { return 0; }
    function name(bytes32 node) constant returns(string) { return name; }
    
    modifier issuer_only {
        require(msg.sender == issuer);
        _;
    }
    
    function ShibbolethToken(ENS _ens, string _name, string _symbol, address _issuer) {
        ens = _ens;
        name = _name;
        symbol = _symbol;
        issuer = _issuer;
        
        var rr = ReverseRegistrar(ens.owner(0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2));
        rr.claimWithResolver(this, this);
    }
    
    function issue(uint _value) issuer_only {
        require(totalSupply + _value >= _value);
        balances[issuer] += _value;
        totalSupply += _value;
        Transfer(0, issuer, _value);
    }
    
    function burn(uint _value) issuer_only {
        require(_value <= balances[issuer]);
        balances[issuer] -= _value;
        totalSupply -= _value;
        Transfer(issuer, 0, _value);
    }
    
    function setIssuer(address _issuer) issuer_only {
        issuer = _issuer;
    }
}

library StringUtils {
    function strcpy(string dest, uint off, string src) private {
        var len = bytes(src).length;
        assembly {
            dest := add(add(dest, off), 32)
            src := add(src, 32)
        }
        
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(add(dest, off), mload(src))
                dest := add(dest, 32)
                src := add(src, 32)
            }
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    
    function concat(string a, string b) internal returns(string ret) {
        ret = new string(bytes(a).length + bytes(b).length);
        strcpy(ret, 0, a);
        strcpy(ret, bytes(a).length, b);
    }
}

contract ShibbolethTokenFactory {
    using StringUtils for *;
    
    ENS ens;
     
    bytes32 constant rootNode = 0x2952863bce80be8e995bbf003c7a1901dd801bb90c09327da9d029d0496c7010;
    bytes32 reverseNode;
    mapping(bytes32=>address) tokens;
    
    event NewToken(string indexed symbol, string _symbol, string name, address addr);
    
    function ShibbolethTokenFactory(ENS _ens) {
        ens = _ens;
        var rr = ReverseRegistrar(ens.owner(0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2));
        reverseNode = rr.claimWithResolver(this, this);
    }
    
    function create(string symbol) returns(address) {
        var name = symbol.concat(".myshibbol.eth");
        var subnode = sha3(rootNode, sha3(symbol));
        require(ens.owner(subnode) == 0);

        var token = create(symbol, name);

        ens.setSubnodeOwner(rootNode, sha3(symbol), this);
        ens.setResolver(subnode, this);
        tokens[subnode] = token;

        return token;
    }
    
    function create(string symbol, string name) returns(address) {
        var token = new ShibbolethToken(ens, name, symbol, msg.sender);
        NewToken(symbol, symbol, name, token);
        return token;
    }

     
    function supportsInterface(bytes4 interfaceId) returns(bool) {
        return (interfaceId == 0x01ffc9a7 ||  
                interfaceId == 0x3b3b57de ||  
                interfaceId == 0x691f3431 ||  
                interfaceId == 0x2203ab56);   
    }
    
    function addr(bytes32 node) constant returns (address) {
        if(node == rootNode) {
            return this;
        }
        return tokens[node];
    }
    
    function ABI(bytes32 node) constant returns (uint256, bytes) {
        if(node == rootNode || node == reverseNode) {
            return (1, '[{"constant":false,"inputs":[{"name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"ABI","outputs":[{"name":"","type":"uint256"},{"name":"","type":"bytes"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"symbol","type":"string"},{"name":"name","type":"string"}],"name":"create","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"addr","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"symbol","type":"string"}],"name":"create","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"inputs":[{"name":"_ens","type":"address"}],"payable":false,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"symbol","type":"string"},{"indexed":false,"name":"_symbol","type":"string"},{"indexed":false,"name":"name","type":"string"},{"indexed":false,"name":"addr","type":"address"}],"name":"NewToken","type":"event"}]');
        }
        return (1, '[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"issuer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"addr","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_value","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_issuer","type":"address"}],"name":"setIssuer","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"node","type":"bytes32"}],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_value","type":"uint256"}],"name":"issue","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"inputs":[{"name":"_ens","type":"address"},{"name":"_name","type":"string"},{"name":"_symbol","type":"string"},{"name":"_issuer","type":"address"}],"payable":false,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"}]');
    }

     
    function name(bytes32 node) constant returns (string) { 
        if(node == reverseNode) {
            return 'myshibbol.eth';
        }
        return '';
    }
}