 

contract HackerSpaceBarneysToken {
     
    mapping (address => uint256) public balanceOf;

     
    function HackerSpaceBarneysToken() {
        balanceOf[msg.sender] = 1000000;               
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
    }
}