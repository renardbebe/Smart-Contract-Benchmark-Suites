 

pragma solidity ^0.4.13;


contract Emoji {
     
    string public name;
    string public standard = 'Token 0.1';
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

   

     
    function Emoji () {
        totalSupply = 600600600600600600600600600;                         
        name = "Emoji";                                    
        symbol = ":)";                                
        decimals = 3;                             
        balanceOf[msg.sender] = totalSupply;               
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] > _value);                 
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                             
        Transfer(_from, _to, _value);
    }

     
     
     
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_value < allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

}