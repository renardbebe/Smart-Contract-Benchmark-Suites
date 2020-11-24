 

pragma solidity ^0.4.2;

contract Titaneum {
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function Titaneum() {
    
        balanceOf[msg.sender] = 99000000;               
        totalSupply = 99000000;                         
        name = "Titaneum";                                    
        symbol = "TTNM";                                
        decimals = 0;                             
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }
}