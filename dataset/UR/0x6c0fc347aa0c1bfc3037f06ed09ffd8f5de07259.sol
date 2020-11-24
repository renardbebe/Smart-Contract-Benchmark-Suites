 

pragma solidity ^0.4.4;

 
contract Owned {
     
    address public owner;

     
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}

 
contract Destroyable {
    address public hammer;

     
    function setHammer(address _hammer) onlyHammer
    { hammer = _hammer; }

     
    function destroy() onlyHammer
    { suicide(msg.sender); }

     
    modifier onlyHammer { if (msg.sender != hammer) throw; _; }
}

 
contract Object is Owned, Destroyable {
    function Object() {
        owner  = msg.sender;
        hammer = msg.sender;
    }
}

 
 
contract ERC20 
{
 
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256);

 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Token is Object, ERC20 {
     
    string public name;
    string public symbol;

     
    uint public totalSupply;

     
    uint8 public decimals;
    
     
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
 
     
    function balanceOf(address _owner) constant returns (uint256)
    { return balances[_owner]; }
 
     
    function allowance(address _owner, address _spender) constant returns (uint256)
    { return allowances[_owner][_spender]; }

     
    function Token(string _name, string _symbol, uint8 _decimals, uint _count) {
        name        = _name;
        symbol      = _symbol;
        decimals    = _decimals;
        totalSupply = _count;
        balances[msg.sender] = _count;
    }
 
     
    function transfer(address _to, uint _value) returns (bool) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to]        += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var avail = allowances[_from][msg.sender]
                  > balances[_from] ? balances[_from]
                                    : allowances[_from][msg.sender];
        if (avail >= _value) {
            allowances[_from][msg.sender] -= _value;
            balances[_from] -= _value;
            balances[_to]   += _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {
        allowances[msg.sender][_spender] += _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function unapprove(address _spender)
    { allowances[msg.sender][_spender] = 0; }
}

library CreatorToken {
    function create(string _name, string _symbol, uint8 _decimals, uint256 _count) returns (Token)
    { return new Token(_name, _symbol, _decimals, _count); }

    function version() constant returns (string)
    { return "v0.6.0 (1b4435b8)"; }

    function abi() constant returns (string)
    { return '[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hammer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"destroy","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_hammer","type":"address"}],"name":"setHammer","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"}],"name":"unapprove","outputs":[],"payable":false,"type":"function"},{"inputs":[{"name":"_name","type":"string"},{"name":"_symbol","type":"string"},{"name":"_decimals","type":"uint8"},{"name":"_count","type":"uint256"}],"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"}]'; }
}

 
contract Builder is Object {
     
    event Builded(address indexed client, address indexed instance);
 
     
    mapping(address => address[]) public getContractsOf;
 
     
    function getLastContract() constant returns (address) {
        var sender_contracts = getContractsOf[msg.sender];
        return sender_contracts[sender_contracts.length - 1];
    }

     
    address public beneficiary;

     
    function setBeneficiary(address _beneficiary) onlyOwner
    { beneficiary = _beneficiary; }

     
    uint public buildingCostWei;

     
    function setCost(uint _buildingCostWei) onlyOwner
    { buildingCostWei = _buildingCostWei; }

     
    string public securityCheckURI;

     
    function setSecurityCheck(string _uri) onlyOwner
    { securityCheckURI = _uri; }
}

 
 
 
contract BuilderToken is Builder {
     
    function create(string _name, string _symbol, uint8 _decimals, uint256 _count, address _client) payable returns (address) {
        if (buildingCostWei > 0 && beneficiary != 0) {
             
            if (msg.value < buildingCostWei) throw;
             
            if (!beneficiary.send(buildingCostWei)) throw;
             
            if (msg.value > buildingCostWei) {
                if (!msg.sender.send(msg.value - buildingCostWei)) throw;
            }
        } else {
             
            if (msg.value > 0) {
                if (!msg.sender.send(msg.value)) throw;
            }
        }

        if (_client == 0)
            _client = msg.sender;
 
        var inst = CreatorToken.create(_name, _symbol, _decimals, _count);
        getContractsOf[_client].push(inst);
        Builded(_client, inst);
        inst.transfer(_client, _count);
        inst.setOwner(_client);
        inst.setHammer(_client);
        return inst;
    }
}