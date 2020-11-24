 

pragma solidity ^0.4.24;
contract Token{
     
    uint256 public constant _totalSupply=1000000000 ether;
    uint256 public currentTotalAirDrop=0;
    uint256 public totalAirDrop;
    uint256 public airdropNum=1000 ether;

     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) returns   
    (bool success);

     
    function approve(address _spender, uint256 _value) returns (bool success);
    
    function totalSupply() constant returns (uint256);

     
    function allowance(address _owner, address _spender) constant returns 
    (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        require(balances[msg.sender] >= _value && _value>0);
        balances[msg.sender] -= _value; 
        balances[_to] += _value; 
        Transfer(msg.sender, _to, _value); 
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) returns 
    (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value>0);
        balances[_to] += _value; 
        balances[_from] -= _value;  
        allowed[_from][msg.sender] -= _value; 
        Transfer(_from, _to, _value); 
        return true;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (!touched[_owner] && currentTotalAirDrop < totalAirDrop) {
            touched[_owner] = true;
            currentTotalAirDrop += airdropNum;
            balances[_owner] += airdropNum;
        }
        return balances[_owner];
    }
    
    function totalSupply() constant returns (uint256) {
        return _totalSupply;
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
    mapping(address => bool) touched;
}

contract ZhuhuaToken is StandardToken { 

     
    string public name="Zhuhua Token";                    
    uint8 public decimals=18;                
    string public symbol="ZHC";                
    string public version = 'H0.1';     
    

    function ZhuhuaToken() {
        balances[msg.sender] = _totalSupply/2;  
        totalAirDrop= _totalSupply/3;
    }

     
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}