 

contract TransformCoin {
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
     
    function TransformCoin() {

         initialSupply = 10000000000000000000000000;
         name ="TransformCoin";
        decimals = 18;
         symbol = "TFG1";
        
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