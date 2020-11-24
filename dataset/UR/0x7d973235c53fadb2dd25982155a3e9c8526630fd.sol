 

contract Daric {
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
     
    function Daric() {

         initialSupply = 110000000000000000000000000;
         name ="Daric Coins";
        decimals = 18;
         symbol = "Daric";
        
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
                                   
    }


      
    function transfer(address _to, uint256 _value) {
         
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

         
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);

         
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }

}