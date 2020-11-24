 

pragma solidity ^0.4.14;

contract CicadaToken {
     
    string public standard = 'Cicada 33.01';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
     
        
    function CicadaToken() {

         initialSupply = 3301000000000;
         name ="CICADA";
         decimals = 9;
         symbol = "3301";
        
        balanceOf[msg.sender] = initialSupply;               
        uint256 totalSupply = initialSupply;                 
                                   
    }

     
    
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
      
    }
    
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
    }  
}