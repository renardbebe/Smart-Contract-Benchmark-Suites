 

pragma solidity ^0.4.2;

contract CON0217 {
     
    string public standard = 'Консервативный от 02.2017';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


    address public owner;

    

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function CON0217() {
        if (owner!=0) throw;
        owner = msg.sender;
        balanceOf[msg.sender] = 0;               
        totalSupply = 0;                         
        name = 'CON0217';                                    
        symbol = 'CON';                                
        decimals = 0;                             
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    function mintToken(uint256 mintedAmount) onlyOwner {
        balanceOf[owner] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
    }
     
    function () {
        throw;      
    }
}