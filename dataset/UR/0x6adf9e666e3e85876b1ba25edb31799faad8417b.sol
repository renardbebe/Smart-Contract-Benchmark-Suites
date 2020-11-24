 

pragma solidity ^0.4.6;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract Free_Ether_A_Day_Funds_Return {
   address owner;
   address poorguy = 0xb7b8f253f9Df281EFE9E34F07F598f9817D6eb83;
   
   function Free_Ether_A_Day_Funds_Return() {
        owner = msg.sender;
   }
  
   
   
   
  
   function return_funds() payable {

       if (msg.sender != poorguy) throw;
       
       if (msg.value == 100 ether){
             bool success = poorguy.send(210 ether);
             if (!success) throw;
       }
       else throw;
   }
   
   function() payable {}
   
   function kill(){
       if (msg.sender == owner)
           selfdestruct(owner);
   }
}