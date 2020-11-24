 

 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.5;

contract HelpMeSave { 
   
   address public me;     
   uint256 public savings_goal;  
   
    
   function MyTestWallet7(){
       me = msg.sender;    
       set_savings_goal(1000 ether);
   }
   
    
   function set_savings_goal(uint256 new_goal) noone_else { 
       if (this.balance >= savings_goal) savings_goal = new_goal;
   }
   
    
    function deposit() public payable {}  
    function() payable {deposit();}  
    
     
    function withdraw () public noone_else { 

         uint256 withdraw_amt = this.balance;
         
         if (msg.sender != me || withdraw_amt < savings_goal ){  
             withdraw_amt = 0;                      
         }

         if (!msg.sender.send(withdraw_amt)) throw;  

   }

     
    modifier noone_else() {  
        if (msg.sender == me) 
            _;
    }

     
    function recovery (uint256 _password) noone_else {
        
       if ( uint256(sha3(_password)) % 10000000000000000000 == 49409376313952921 ){
                selfdestruct (me);
       } else throw;
    }
}