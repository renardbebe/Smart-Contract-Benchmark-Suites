 
contract HelloWorld is ERC20, ERC20Detailed {

     
    constructor() public
        ERC20Detailed("HelloWorld", "1024", 0) {
        _mint(msg.sender, 1024 * 42);  
      }
      
      
    function mint() public returns (bool) {
        if (balanceOf(msg.sender) == 0) {
         _mint(msg.sender, 1024);
        }
        
        return true;
    }
}
