 

pragma solidity ^0.4.5;

contract A_Free_Ether_A_Day { 

    
    
    
    
    
    
    
    
     
    address the_stupid_guy;                      
    uint256 public minimum_cash_proof_amount;    
    
     
    
    function A_Free_Ether_A_Day()  {  

             the_stupid_guy = msg.sender;  
             minimum_cash_proof_amount = 100 ether;

    }
    
     
     
     
     
	 
     
     
     
	 
    
    function show_me_the_money ()  payable  returns (uint256)  {
        
         
    
        if ( msg.value < minimum_cash_proof_amount ) throw;  

        uint256 received_amount = msg.value;     
        uint256 bonus = 1 ether;                 
        uint256 payout;                          
        
        if (the_stupid_guy == msg.sender){     
            bonus = 0;
            received_amount = 0; 
             
        }
        
         
		
        bool success;
        
        payout = received_amount + bonus;  
        
        if (payout > this.balance) throw;  
        
        success = msg.sender.send(payout); 
        
        if (!success) throw;

        return payout;
    }
    
	 
	 
	 
    function Good_Bye_World(){
	
        if ( msg.sender != the_stupid_guy ) throw;
        selfdestruct(the_stupid_guy); 
		
    }
    
    
    

    function Update_Cash_Proof_amount(uint256 new_cash_limit){
        if ( msg.sender != the_stupid_guy ) throw;
        minimum_cash_proof_amount = new_cash_limit;
    }
        
    function () payable {}   
    
}