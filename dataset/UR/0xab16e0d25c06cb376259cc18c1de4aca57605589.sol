 

pragma solidity ^0.4.16;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract FuckToken {
     
    string public standard = 'FUCK 1.1';
    string public name = 'FinallyUsableCryptoKarma';
    string public symbol = 'FUCK';
    uint8 public decimals = 4;
    uint256 public totalSupply = 708567744953;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function FuckToken() {
        balanceOf[msg.sender] = totalSupply;                     
    }

     
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                                
        if (balanceOf[msg.sender] < _value) revert();            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        balanceOf[msg.sender] -= _value;                         
        balanceOf[_to] += _value;                                
        Transfer(msg.sender, _to, _value);                       
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) revert();
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
        if (_to == 0x0) revert();                                 
        if (balanceOf[_from] < _value) revert();                  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        if (_value > allowance[_from][msg.sender]) revert();      
        balanceOf[_from] -= _value;                               
        balanceOf[_to] += _value;                                 
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

	 
    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert();             
        balanceOf[msg.sender] -= _value;                          
        totalSupply -= _value;                                    
        Burn(msg.sender, _value);
        return true;
    }

	 
    function burnFrom(address _from, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) revert();                 
        if (_value > allowance[_from][msg.sender]) revert();     
        balanceOf[_from] -= _value;                              
        totalSupply -= _value;                                   
        Burn(_from, _value);
        return true;
    }
}