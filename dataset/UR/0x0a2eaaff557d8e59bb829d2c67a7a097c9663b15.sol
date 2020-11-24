 

pragma solidity ^0.4.4;
 
contract Token {
    
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
    
    }
 
     
    function totalSupply() constant returns (uint256 supply) {}
 
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}
 
     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}
 
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
 
     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}
    
     
    function burn(uint256 _value) returns (bool success) {}
 
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
    
}
 
 
 
contract StandardToken is Token {
 
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
 
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
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
    
    function burn(uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) throw;             
		if (_value <= 0) throw; 
        balances[msg.sender] = Token.safeSub(balances[msg.sender], _value);                       
        totalSupply = Token.safeSub(totalSupply,_value);                                 
        Burn(msg.sender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}
 
 
 
contract OodlebitToken is StandardToken {
 
    function () {
         
        throw;
    }
 
     
 
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H1.0';        
 
 
 
 
 
 
 
    function OodlebitToken(
        ) {
        balances[msg.sender] = 200000000000000000000000000;                
        totalSupply = 200000000000000000000000000;                         
        name = "OODL";                                    
        decimals = 18;                             
        symbol = "OODL";                                
        
         
         
         
    }
 
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
 
         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}