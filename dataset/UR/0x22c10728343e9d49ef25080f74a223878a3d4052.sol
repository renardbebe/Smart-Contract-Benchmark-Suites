 

pragma solidity ^0.4.8;

contract DigitalRupiah {
     
    string public standard = 'ERC20';
    string public name =  'Digital Rupiah';
    string public symbol = 'DRP' ;
    uint8 public decimals = 8 ;
    uint256 public totalSupply = 10000000000000000;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);


     
    function transfer(address _to, uint256 _value) {
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        balanceOf[_from] -= _value;                            
        balanceOf[_to] += _value;                              
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
}