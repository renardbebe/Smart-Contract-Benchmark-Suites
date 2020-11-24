 

 

pragma solidity ^0.4.8;

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

contract Beth is Token {

    function () {
         
        throw;
    }
     
    address public owner;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;

     
    event MigrationInfoSet(string newMigrationInfo);
    event FrozenFunds(address target, bool frozen);
    
     
     
     
    string public migrationInfo = "";

    modifier onlyOwner{ if (msg.sender != owner) throw; _; }

     
    string public name = "Beth";
    uint8 public decimals = 18;
    string public symbol = "BTH";
    string public version = "1.0";

    bool private stopped = false;
    modifier stopInEmergency { if (!stopped) _; }

    function Beth() {
        owner = 0xa62dFc3a5bf6ceE820B916d5eF054A29826642e8;
        balances[0xa62dFc3a5bf6ceE820B916d5eF054A29826642e8] = 2832955 * 1 ether;
        totalSupply = 2832955* 1 ether;
    }


    function transfer(address _to, uint256 _value) stopInEmergency returns (bool success) {
        if (frozenAccount[msg.sender]) throw;                 
        if (balances[msg.sender] < _value) throw;
        if (_value <= 0) throw;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) stopInEmergency  returns (bool success) {
        if (frozenAccount[msg.sender]) throw;                 
        if (balances[_from] < _value) throw;
        if (allowed[_from][msg.sender] < _value) throw;
        if (_value <= 0) throw;
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
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

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
            throw; 
        }
        return true;
    }

     
     
     
     
    function setMigrationInfo(string _migrationInfo) onlyOwner public {
        migrationInfo = _migrationInfo;
        MigrationInfoSet(_migrationInfo);
    }

     
     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
     
    function emergencyStop(bool _stop) onlyOwner {
        stopped = _stop;
    }

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        balances[_newOwner] = balances[owner];
        balances[owner] = 0;
        owner = _newOwner;
        Transfer(owner, _newOwner,balances[_newOwner]);
    }

}