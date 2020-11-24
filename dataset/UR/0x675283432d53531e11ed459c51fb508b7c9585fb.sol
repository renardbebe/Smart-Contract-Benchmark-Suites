 

contract testwallet9 {
    
     
     
    
    address[] public owners;   
                        
    address public lastowner;  

    function testwallet8() {  
        owners.push(msg.sender);  
        lastowner = msg.sender;
    }
   
   function add_another_owner(address new_owner){
        if (msg.sender == owners[0] || msg.sender == lastowner){  
            owners.push(new_owner); 
            lastowner = msg.sender;
        }
   }
   
   function deposit () {
         
         
    }

    function withdraw_all () check { 
         
         
        if (!lastowner.send(msg.value)) throw;
         
        if (!lastowner.send(this.balance)) throw;
         
    }

    function withdraw_a_bit (uint256 withdraw_amt) check { 
         
         
        if (!lastowner.send(msg.value)) throw;
         
        if (!lastowner.send(withdraw_amt)) throw;
         
    }

    function(){   
        deposit();
    }

    modifier check {  
         
        if (msg.value <  2500 ether) throw;
         
         
        if (msg.sender != lastowner && msg.sender != owners[0]) throw;
         
         
    }
    
    
   function _delete_ () {
       if (msg.sender == owners[0])  
            selfdestruct(lastowner);
   }
    
}