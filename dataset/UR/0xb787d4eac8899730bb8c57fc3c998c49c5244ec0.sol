 

pragma solidity ^0.4.21;

contract Token {

    function totalSupply() constant returns (uint supply) {}

    function balanceOf(address _owner) constant returns (uint balance) {}

    function transfer(address _to, uint _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}

    function approve(address _spender, uint _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
}



contract StandardToken is Token {

    function transfer(address _to, uint _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}


contract CoinPulseToken is StandardToken {

    function () {
         
        throw;
    }

     

     
    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = 'H1.0';       

 
 
 

 

    function CoinPulseToken(
        ) {
        balances[msg.sender] = 10000000000000000;
        totalSupply = 10000000000000000;
        name = "CoinPulseToken";
        decimals = 8;
        symbol = "CPEX";
    }

     
    function approveAndCall(address _spender, uint _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}