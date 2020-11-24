 

pragma solidity ^0.4.18;

contract PayPerView {
     
    string public standard = 'PayPerView 1.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
     
    function PayPerView () public {

         initialSupply = 120000000000000000;
         name ="Pay Per View";
         decimals = 8;
         symbol = "PPV";
        
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
                                   
    }

     
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) revert();            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
    }


     
    function () public {
        revert();      
    }
}