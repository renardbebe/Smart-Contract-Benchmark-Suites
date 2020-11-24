 

contract Company { 
     
    string public standart = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initilSupply;
    uint256 public totalSupply;
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;
    
   
    function Company() {
         
         
        
         
        initilSupply = 10000000000000000;
        name = "Company";
        decimals = 8;   
        symbol = "COMP";
        
       balanceOf[msg.sender] = initilSupply;
       totalSupply = initilSupply;
    }

     
    function transfer(address _to, uint256 _value) {
      if (balanceOf[msg.sender] < _value) revert();
      if(balanceOf[_to] + _value < balanceOf[_to]) revert();
      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;
    }
}