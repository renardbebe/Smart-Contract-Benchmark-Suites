 

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
}

contract NECPToken is owned {
     
    string public constant standard = 'Token 0.1';
    string public constant name = "Neureal Early Contributor Points";
    string public constant symbol = "NECP";
    uint256 public constant decimals = 8;
    uint256 public constant MAXIMUM_SUPPLY = 3000000000000;
    
    uint256 public totalSupply;
    bool public frozen = false;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function NECPToken() {
        balanceOf[msg.sender] = MAXIMUM_SUPPLY;               
        totalSupply = MAXIMUM_SUPPLY;                         
    }

     
    function transfer(address _to, uint256 _value) {
        if (frozen) throw;                                    
        if (_to == 0x0) throw;                                
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

    function freezeTransfers() onlyOwner  {
        frozen = true;
    }

     
    function () {
        throw;    
    }
}