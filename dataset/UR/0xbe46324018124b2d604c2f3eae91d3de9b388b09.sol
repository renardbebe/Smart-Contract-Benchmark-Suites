 

contract RobinHoodPonzi {

 
 
 
 
 
 
 
 
 
 




  struct Participant {
      address etherAddress;
      uint payin;
      uint payout;	
  }

  Participant[] private participants;

  uint private payoutIdx = 0;
  uint private collectedFees;
  uint private balance = 0;
  uint private fee = 1;  
  uint private factor = 200; 

  address private owner;

   
  modifier onlyowner { if (msg.sender == owner) _ }

   
  function RobinHoodPonzi() {
    owner = msg.sender;
  }

   
  function() {
    enter();
  }
  

  function enter() private {
    if (msg.value < 1 finney) {
        msg.sender.send(msg.value);
        return;
    }
		uint amount;
		if (msg.value > 1000 ether) {
			msg.sender.send(msg.value - 1000 ether);	
			amount = 1000 ether;
    }
		else {
			amount = msg.value;
		}

  	 

    uint idx = participants.length;
    participants.length += 1;
    participants[idx].etherAddress = msg.sender;
    participants[idx].payin = amount;

	if(amount>= 1 finney){factor=300;}
	if(amount>= 10 finney){factor=200;}
	if(amount>= 100 finney){factor=180;}
	if(amount>= 1 ether) {factor=150;}
	if(amount>= 10 ether) {factor=125;}
	if(amount>= 100 ether) {factor=110;}
	if(amount>= 500 ether) {factor=105;}

    participants[idx].payout = amount *factor/100;	
	
 
    
     
    
     collectedFees += amount *fee/100;
     balance += amount - amount *fee/100;
     



 
    while (balance > participants[payoutIdx].payout) 
	{
	      uint transactionAmount = participants[payoutIdx].payout;
	      participants[payoutIdx].etherAddress.send(transactionAmount);
	      balance -= transactionAmount;
	      payoutIdx += 1;
	}

 	if (collectedFees >1 ether) 
	{
	
      		owner.send(collectedFees);
      		collectedFees = 0;
	}
  }

  
  
 
  
  

  
  
  


	function Infos() constant returns (address Owner, uint BalanceInFinney, uint Participants, uint PayOutIndex,uint NextPayout, string info) 
	{
		Owner=owner;
        	BalanceInFinney = balance / 1 finney;
        	PayOutIndex=payoutIdx;
		Participants=participants.length;
		NextPayout =participants[payoutIdx].payout / 1 finney;
		info = 'All amounts in Finney (1 Ether = 1000 Finney)';
    	}

	function participantDetails(uint nr) constant returns (address Address, uint PayinInFinney, uint PayoutInFinney, string PaidOut)
    	{
		
		PaidOut='N.A.';
		Address=0;
		PayinInFinney=0;
		PayoutInFinney=0;
        	if (nr < participants.length) {
            	Address = participants[nr].etherAddress;

            	PayinInFinney = participants[nr].payin / 1 finney;
		PayoutInFinney= participants[nr].payout / 1 finney;
		PaidOut='no';
		if (nr<payoutIdx){PaidOut='yes';}		

       }
    }
}