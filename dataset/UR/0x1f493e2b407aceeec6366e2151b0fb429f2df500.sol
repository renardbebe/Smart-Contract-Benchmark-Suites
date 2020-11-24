 

pragma solidity ^0.4.4;

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}
contract TIC is StandardToken { 

    string public name;                  
    uint8 public decimals;              
    string public symbol;                 
    string public version = '1.0'; 
    uint256 public Rate;     
    uint256 public totalEthInWei;      
    address public fundsWallet;         
    address public CandyBox;
    address public TeamBox;


    function TIC(
        ) {
        CandyBox = 0x94eE12284824C91dB533d4745cD02098d7284460;
        TeamBox = 0xfaDB28B22b1b5579f877c78098948529175F81Eb;
        totalSupply = 6000000000000000000000000000;                   
        balances[msg.sender] = 5091000000000000000000000000;             
        balances[CandyBox] = 9000000000000000000000000;  
        balances[TeamBox] = 900000000000000000000000000;
        name = "TIC";                                        
        decimals = 18;                                  
        symbol = "TIC";                                            
        Rate = 50000;                                      
        fundsWallet = msg.sender;                                   
    }
    
    function setCurrentRate(uint256 _rate) public {
        if(msg.sender != fundsWallet) { throw; }
        Rate = _rate;
    }    

    function setCurrentVersion(string _ver) public {
        if(msg.sender != fundsWallet) { throw; }
        version = _ver;
    }  

    function() payable{
 
        totalEthInWei = totalEthInWei + msg.value;
  
        uint256 amount = msg.value * Rate;

        require(balances[fundsWallet] >= amount);


        balances[fundsWallet] = balances[fundsWallet] - amount;

        balances[msg.sender] = balances[msg.sender] + amount;


        Transfer(fundsWallet, msg.sender, amount); 

 
        fundsWallet.transfer(msg.value);                               
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}