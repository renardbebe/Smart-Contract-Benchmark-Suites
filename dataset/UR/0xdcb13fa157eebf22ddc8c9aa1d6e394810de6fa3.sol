 

contract PiggyBank {

  struct InvestorArray {
      address etherAddress;
      uint amount;
  }

  InvestorArray[] public investors;

  uint public k = 0;
  uint public fees;
  uint public balance = 0;
  address public owner;

   
  modifier onlyowner { if (msg.sender == owner) _ }

   
  function PiggyBank() {
    owner = msg.sender;
  }

   
  function() {
    enter();
  }
  
  function enter() {
    if (msg.value < 50 finney) {
        msg.sender.send(msg.value);
        return;
    }
	
    uint amount=msg.value;


     
    uint total_inv = investors.length;
    investors.length += 1;
    investors[total_inv].etherAddress = msg.sender;
    investors[total_inv].amount = amount;
    
     
 
      fees += amount / 33;              
      balance += amount;                


     if (fees != 0) 
     {
     	if(balance>fees)
	{
      	owner.send(fees);
      	balance -= fees;                  
	}
     }
 

    
    uint transactionAmount;
	
    while (balance > investors[k].amount * 3/100 && k<total_inv)   
    { 
     
     if(k%25==0 &&  balance > investors[k].amount * 9/100)
     {
      transactionAmount = investors[k].amount * 9/100;  
      investors[k].etherAddress.send(transactionAmount);
      balance -= investors[k].amount * 9/100;                       
      }
     else
     {
      transactionAmount = investors[k].amount *3/100;  
      investors[k].etherAddress.send(transactionAmount);
      balance -= investors[k].amount *3/100;                          
      }
      
      k += 1;
    }
    
     
  }



  function setOwner(address new_owner) onlyowner {
      owner = new_owner;
  }
}