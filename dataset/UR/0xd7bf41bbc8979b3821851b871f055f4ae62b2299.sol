 

 


contract JamCoin { 
     
    string public name;
    string public symbol;
    uint8 public decimals;
    
     
    mapping (address => uint256) public balanceOf;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    function JamCoin() {
         
        balanceOf[msg.sender] = 10000;
        name = "Jam Coin";     
        symbol = "5ea56e7bfd92b168fc18e421da0088bf";
        decimals = 2;
    }

     
    function transfer(address _to, uint256 _value) {
         
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        
         
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
         
        Transfer(msg.sender, _to, _value);
    }
}