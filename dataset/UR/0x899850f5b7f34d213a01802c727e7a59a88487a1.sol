 

pragma solidity ^0.4.11;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract MessageToken {
     
    string public standard = 'MessageToken 1.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function MessageToken() {
        balanceOf[msg.sender] = 10000;               
        totalSupply = 10000;                         
        name = "Messages";                                    
        symbol = "\u2709";                                
        decimals = 0;                             
    }

     
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                                
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if(_value > 1 || _value < 1) throw;
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
        if (_to == 0x0) throw;                                 
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;      
        balanceOf[_from] -= _value;                            
        balanceOf[_to] += _value;                              
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;             
        balanceOf[msg.sender] -= _value;                       
        totalSupply -= _value;                                 
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 
        if (_value > allowance[_from][msg.sender]) throw;     
        balanceOf[_from] -= _value;                           
        totalSupply -= _value;                                
        Burn(_from, _value);
        return true;
    }
    
    function mintToken(address target, uint256 mintedAmount) {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
    }
}