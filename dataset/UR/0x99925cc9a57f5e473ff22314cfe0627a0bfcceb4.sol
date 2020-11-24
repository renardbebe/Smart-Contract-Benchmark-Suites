 

pragma solidity ^0.4.5;

contract Bank_With_Interest {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    mapping(address => uint256) balances;
    mapping(address => uint256) term_deposit_end_block;  
                                                          
    address public thebank;  
    
    uint256 public minimum_payment;  
    uint256 public deposit_fee;      
    
    uint256 public contract_alive_until_this_block;
    
    bool public any_customer_payments_yet = false;  
                                         
    
    function Bank_With_Interest() {  
        thebank = msg.sender;  
        minimum_payment = 250 ether;
        deposit_fee = 5 ether;
        contract_alive_until_this_block = 3000000;  
                                                    
         
         
        term_deposit_end_block[thebank] = 0; 
         
    }
    
    
     
     
    function deposit() payable {
         
        if (msg.value < minimum_payment) throw;  
         
         
        if (balances[msg.sender] == 0) deposit_fee = 0 ether;  
         
        if ( msg.sender == thebank ){  
            balances[thebank] += msg.value;
        }
        else {  
            any_customer_payments_yet = true;  
            balances[msg.sender] += msg.value - deposit_fee;   
            balances[thebank] += deposit_fee;  
            term_deposit_end_block[msg.sender] = block.number + 30850;  
        }
         
    }
    
     
     
     
     
    function withdraw(uint256 withdraw_amount) {
         
        if (withdraw_amount < 10 ether) throw;  
        if ( withdraw_amount > balances[msg.sender]  ) throw;  
        if (block.number < term_deposit_end_block[msg.sender] ) throw;  
         
         
         
        uint256 interest = 1 ether;   
         
        if (msg.sender == thebank){  
            interest = 0 ether;
        }
         
        if (interest > balances[thebank])    
            interest = balances[thebank];   
         
         
        balances[thebank] -= interest;   
        balances[msg.sender] -= withdraw_amount;
         
        if (!msg.sender.send(withdraw_amount)) throw;   
        if (!msg.sender.send(interest)) throw;          
         
    }
    
     
     
     
    
     
    function set_minimum_payment(uint256 new_limit) {
        if ( msg.sender == thebank ){
            minimum_payment = new_limit;
        }
    }
     
     
    function set_deposit_fee (uint256 new_fee) {
        if ( msg.sender == thebank ){
            deposit_fee = new_fee;
        }
    }
    
     
    function get_available_interest_amount () returns (uint256) {
        return balances[thebank];
    }
     
    function get_term_deposit_end_date () returns (uint256) {
        return term_deposit_end_block[msg.sender];
    }    
     
    function get_balance () returns (uint256) {
        return balances[msg.sender];
    }
     
     
     
     
	 
    function extend_life_of_contract (uint256 newblock){
        if ( msg.sender != thebank || newblock < contract_alive_until_this_block ) throw;
         
        contract_alive_until_this_block = newblock; 
         
        term_deposit_end_block[thebank] = contract_alive_until_this_block;
    }
     
     
    function close_bank(){
        if (contract_alive_until_this_block < block.number || !any_customer_payments_yet)
            selfdestruct(thebank); 
             
             
    }
     
     
     
    function () payable {  
                           
                           
        balances[thebank] += msg.value;
    }
}