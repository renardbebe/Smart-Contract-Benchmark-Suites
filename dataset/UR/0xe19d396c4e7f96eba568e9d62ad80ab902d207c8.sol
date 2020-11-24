 

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