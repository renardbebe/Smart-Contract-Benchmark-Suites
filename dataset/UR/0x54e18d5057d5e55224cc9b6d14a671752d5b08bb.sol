 

pragma solidity ^0.4.8;

contract WSIPrivateEquityShare {
     
    string public constant name = 'WSI Private Equity Share';
    string public constant symbol = 'WSIPES';
    uint256 public constant totalSupply = 10000;
    uint8 public decimals = 2;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function WSIPrivateEquityShare() {
        balanceOf[msg.sender] = totalSupply;               
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function () {
        throw;      
    }
}