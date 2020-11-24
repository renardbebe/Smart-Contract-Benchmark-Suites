 

contract BEXP {  
       
    mapping (address => uint256) public balanceOf;
      
    string public name = "BitExpress";  
    string public symbol = "BEXP";  
    uint8 public decimals = 8;  
    uint256 public totalSupply = 1000000000 * 10**8;
    address founder = address(0xe2ce6a2539efbdf0a211300aadb70a416d5d2bec);
      
    event Transfer(address indexed from, address indexed to, uint256 value);  
          
       
    function BEXP () public {  
        balanceOf[founder] = totalSupply ;              
        Transfer(0, founder, totalSupply);
    }  
          
    function transfer(address _to, uint256 _value) public returns (bool success){  
           
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);  
  
           
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;  
          
           
        Transfer(msg.sender, _to, _value);
        
        return true;
    }
}