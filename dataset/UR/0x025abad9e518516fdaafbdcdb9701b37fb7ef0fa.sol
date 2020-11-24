 

pragma solidity ^0.4.11;

 


 
contract owned {
    address public owner;  

    function owned() {
        owner = msg.sender;  
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;  
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {  
        owner = newOwner;
    }
}


contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

 

contract StandardMintableToken is owned{ 
     
    string public standard = 'Token 0.1';
    string public name;                      
    string public symbol;                    
    uint8 public decimals;                   
    uint256 public totalSupply;              
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
     
    mapping (address => bool) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event FrozenFunds(address target, bool frozen);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function StandardMintableToken(
        string tokenName,                
        uint8 decimalUnits,              
        string tokenSymbol,              
        uint256 initialSupply             
        ) {

        balanceOf[msg.sender] = initialSupply;                    
        totalSupply = initialSupply;                              
        name = tokenName;                                         
        symbol = tokenSymbol;                                     
        decimals = decimalUnits;                                  
    }

     
    function transfer(address _to, uint256 _value) returns (bool success){
        if (_value == 0) return false; 				              
        if (balanceOf[msg.sender] < _value) return false;     
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (frozenAccount[msg.sender]) throw;                 
        if (frozenAccount[_to]) throw;                        
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;             
        Approval(msg.sender, _spender, _value);               
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                         
        if (frozenAccount[_to]) throw;                           
        if (balanceOf[_from] < _value) return false;          	 
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;     
        if (_value > allowance[_from][msg.sender]) throw;        
        balanceOf[_from] -= _value;                              
        balanceOf[_to] += _value;                                
        allowance[_from][msg.sender] -= _value;                  
        Transfer(_from, _to, _value);                            
        return true;
    }
    
     
    
    function freezeAccount(address target, bool freeze ) onlyOwner {    
        frozenAccount[target] = freeze;                        
        FrozenFunds(target, freeze);                           
    }
    

     
    
    function burn(uint256 _value) returns (bool success) {
        if (frozenAccount[msg.sender]) throw;                  
        if (_value == 0) return false; 				           
        if (balanceOf[msg.sender] < _value) return false;      
        balanceOf[msg.sender] -= _value;                       
        totalSupply -= _value;                                 
        Transfer(msg.sender,0, _value);	                       
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success) {
        if (frozenAccount[msg.sender]) throw;                 
        if (frozenAccount[_from]) throw;                      
        if (_value == 0) return false; 			              
        if (balanceOf[_from] < _value) return false;          
        if (_value > allowance[_from][msg.sender]) throw;     
        balanceOf[_from] -= _value;                           
        totalSupply -= _value;                                
        allowance[_from][msg.sender] -= _value;				  
        Transfer(_from, 0, _value);                           
        return true;
    }
    
     
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        if (balanceOf[target] + mintedAmount < balanceOf[target]) throw;  
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, target, mintedAmount);

    }
    
}