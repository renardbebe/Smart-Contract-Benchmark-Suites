 

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


 

contract StandardToken is owned{ 
     
    string public standard = 'Token 0.1';
    string public name;                      
    string public symbol;                    
    uint8 public decimals;                   
    address public the120address;            
    address public the365address;            
    uint public deadline120;                 
    uint public deadline365;                 
    uint256 public totalSupply;              
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
     
    mapping (address => bool) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event FrozenFunds(address target, bool frozen);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function StandardToken(

        string tokenName,   
        uint8 decimalUnits,
        string tokenSymbol,
        
        uint256 distro1,             
        uint256 distro120,           
        uint256 distro365,           
        address address120,          
        address address365,          
        uint durationInMinutes120,   
        uint durationInMinutes365    
        
        ) {
        balanceOf[msg.sender] = distro1;                          
        balanceOf[address120] = distro120;                        
        balanceOf[address365] = distro365;                        
        freezeAccount(address120, true);                          
        freezeAccount(address365, true);                          
        totalSupply = distro1+distro120+distro365;                
        deadline120 = now + durationInMinutes120 * 1 minutes;     
        deadline365 = now + durationInMinutes365 * 1 minutes;     
        the120address = address120;                               
        the365address = address365;                               
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
        if ((target == the120address) && (now < deadline120)) throw;     
        if ((target == the365address) && (now < deadline365)) throw;     
        frozenAccount[target] = freeze;                                  
        FrozenFunds(target, freeze);                                     
    }
    
     
    function burn(uint256 _value) returns (bool success)  {
		if (frozenAccount[msg.sender]) throw;                   
        if (_value == 0) return false;			                
        if (balanceOf[msg.sender] < _value) return false;       
        balanceOf[msg.sender] -= _value;                        
        totalSupply -= _value;                                  
        Transfer(msg.sender,0, _value);                         
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success)  {
        if (frozenAccount[msg.sender]) throw;                   
        if (frozenAccount[_from]) throw;                        
        if (_value == 0) return false;			                
        if (balanceOf[_from] < _value) return false;            
        if (_value > allowance[_from][msg.sender]) throw;       
        balanceOf[_from] -= _value;                             
        allowance[_from][msg.sender] -= _value;                 
        totalSupply -= _value;                                  
        Transfer(_from, 0, _value);
        return true;
    }

}