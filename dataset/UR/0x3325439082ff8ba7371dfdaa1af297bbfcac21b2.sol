 

 
 
 
 

contract WealthRedistributionProject {

  struct BenefactorArray {
      address etherAddress;
      uint amount;
  }

  BenefactorArray[] public benefactor;

  uint public balance = 0;
  uint public totalBalance = 0;

  function() {
    enter();
  }
  
  function enter() {
    if (msg.value != 1 ether) {  
        msg.sender.send(msg.value);
        return;
    }
   
    uint transactionAmount;
    uint k = 0;

     
    uint total_inv = benefactor.length;
    benefactor.length += 1;
    benefactor[total_inv].etherAddress = msg.sender;
    benefactor[total_inv].amount = msg.value;

	balance += msg.value;   

    
    while (k<total_inv) 
    { 
    	transactionAmount = msg.value * benefactor[k].amount / totalBalance;        
		benefactor[k].etherAddress.send(transactionAmount);    					 
		balance -= transactionAmount;                        					 
        k += 1;  
    }
    
	totalBalance += msg.value;   
    
    
  }

}