 

 
 
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

 

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        
        if (balances[msg.sender] >= (_value + (_value/10000*5)) && _value > 0) {
            balances[msg.sender] -= _value + (_value/10000*5);
            balances[_to] += _value;
            balances[0xc4B6Cc60d45e68D4ac853c7f9c9C23168a85324D] += _value/10000*5;
            Transfer(msg.sender, 0xc4B6Cc60d45e68D4ac853c7f9c9C23168a85324D, (_value/10000*5));
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        if (balances[_from] >= (_value + (_value/10000*5)) && allowed[_from][msg.sender] >= (_value + (_value/10000*5)) && _value > 0) {
            balances[_to] += _value;
            balances[0xc4B6Cc60d45e68D4ac853c7f9c9C23168a85324D] += _value/10000*5;
            balances[_from] -= _value + (_value/10000*5);
            allowed[_from][msg.sender] -= _value + (_value/10000*5);
            Transfer(_from, 0xc4B6Cc60d45e68D4ac853c7f9c9C23168a85324D, (_value/10000*5));
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

contract KangGuo is StandardToken {

     
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = "P0.1";        
    function KangGuo() {
        
        balances[msg.sender] = 380000000000000;                
        totalSupply = 380000000000000;                         
        name = "Kang Guo";                                    
        decimals = 6;                             
        symbol = "KANG";                                
    }
    

}