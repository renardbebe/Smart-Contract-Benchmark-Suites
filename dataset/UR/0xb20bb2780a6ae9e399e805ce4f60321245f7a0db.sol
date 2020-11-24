 

pragma solidity ^0.4.2;

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

contract MyToken is owned {
     
    mapping (address => uint256) public balanceOf;

     
    string public standard = 'Token 0.1';
    string public name = 'TrekMiles';
    string public symbol = 'TMC';
    uint8 public decimals = 0;
    uint256 public totalSupply;

     
    function MyToken() {
        uint256 initialSupply = 10;
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);         
    }

     
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

    function () {
         
        throw;
    }
}