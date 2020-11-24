 

contract Qudostokenone {
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
  
     
    function Qudostokenone() {
         initialSupply = 500000;
         name ="qudostokenone";
        decimals = 3;
         symbol = "QTKO";
        
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
                                   
    }
     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
      
    }
   
    
   
     
    function () {
        throw;      
    }
}