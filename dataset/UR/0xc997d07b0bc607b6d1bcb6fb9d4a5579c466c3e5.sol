 

pragma solidity ^0.4.8;

contract tokenRecipient { 
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); 
    
}

contract FlipToken {
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    string public standard = 'FLIP';
    string public name = "Flip";
    string public symbol = "FLIP";
    uint8 public decimals = 0;
    uint256 public totalSupply = 15000000;

     
    function FlipToken() {
        balanceOf[msg.sender] = totalSupply;
    }

     
     
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                               
        if (balanceOf[msg.sender] < _value) throw;           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        balanceOf[msg.sender] -= _value;                   
        balanceOf[_to] += _value;                           
        Transfer(msg.sender, _to, _value);                   
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
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
}