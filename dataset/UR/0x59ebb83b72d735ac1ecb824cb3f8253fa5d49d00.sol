 

pragma solidity ^0.4.8;
contract Token{
     
    uint256 public totalSupply;   
    uint256 public teamlock;   
    uint256 public foundationlock; 
    uint256 public mininglock; 
    uint256 public releaseTime; 
    uint256 public starttime; 
     
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

contract HumanStandardToken is StandardToken { 

     
    string public name;                  
    uint8 public decimals;               
    string public symbol;                
   
    string public version = 'H0.1';     

    function HumanStandardToken() {
         
       
        totalSupply          =1000000000;   
        balances[msg.sender] =300000000;    
        teamlock             =150000000;    
        foundationlock       =100000000;    
        mininglock           =450000000;    
        name = 'DPSChain token';            
        decimals = 0;                       
        symbol = 'DPST';                    
        releaseTime=365*3*24*60*60;         
        starttime=block.timestamp;
       
    }
    
      
    function unlocktoken(address _team, address _foundation, address _mining) returns 
    (bool success) {
         
        require(block.timestamp >= starttime+releaseTime);
        require(teamlock > 0);
        require(foundationlock > 0);
        require(mininglock > 0);
        
         balances[_team] +=teamlock;   
         teamlock-=150000000;
         Transfer(this, _team, teamlock); 
         
        balances[_foundation] +=foundationlock; 
        foundationlock-=100000000;
        Transfer(this, _foundation, foundationlock); 
        
        
        balances[_mining] +=mininglock; 
         mininglock-=450000000;
        Transfer(this, _mining, mininglock); 
        
        return true;
    }
    
   

     
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
         
         
         
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}