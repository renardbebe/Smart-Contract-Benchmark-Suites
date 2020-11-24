 

pragma solidity ^0.4.8;
contract Token{
     
    uint256 public totalSupply;

     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) returns   
    (bool success);

     
    function approve(address _spender, uint256 _value) returns (bool success);

     
    function allowance(address _owner, address _spender) constant returns 
    (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value; 
        balances[_to] += _value; 
        Transfer(msg.sender, _to, _value); 
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns 
    (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value; 
        balances[_from] -= _value;  
        allowed[_from][msg.sender] -= _value; 
        Transfer(_from, _to, _value); 
        return true;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success)   
    {
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

contract VerifyingIdentityToken is StandardToken {
    string public constant name = "Verifying Identity Token";
    string public constant symbol = "VIT";
    uint8 public constant decimals = 18;

    uint256 public constant ONE_TOKENS = (10 ** uint256(decimals));
    uint256 public constant MILLION_TOKENS = (10**6) * ONE_TOKENS;
    uint256 public constant TOTAL_TOKENS = 1800 * MILLION_TOKENS;

    function VerifyingIdentityToken ()    
    {
        balances[msg.sender] = TOTAL_TOKENS;  
        totalSupply = TOTAL_TOKENS;          
    }   
}