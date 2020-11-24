 

 
 
 
 
 
 
 
 
 
 
 
contract CrystalDoubler {

  struct InvestorArray 
	{
      	address EtherAddress;
      	uint Amount;
  	}

  InvestorArray[] public depositors;

 

  uint public Total_Players=0;
  uint public Balance = 0;
  uint public Total_Deposited=0;
  uint public Total_Paid_Out=0;
string public Message="Welcome Player! Double your ETH Now!";
	
  address public owner;

 

  function CrystalDoubler() {
    owner = msg.sender;
  }

 

  function() {
    enter();
  }
  
 

  function enter() {
    if (msg.value > 500 finney) {

    uint Amount=msg.value;

     
    Total_Players=depositors.length+1;
    depositors.length += 1;
    depositors[depositors.length-1].EtherAddress = msg.sender;
    depositors[depositors.length-1].Amount = Amount;
    Balance += Amount;               		 
    Total_Deposited+=Amount;       		 
    uint payout;
    uint nr=0;

    while (Balance > depositors[nr].Amount * 200/100 && nr<Total_Players)
     {
      payout = depositors[nr].Amount *200/100;                            
      depositors[nr].EtherAddress.send(payout);                         
      Balance -= depositors[nr].Amount *200/100;                          
      Total_Paid_Out += depositors[nr].Amount *200/100;                  
      }
      
  }
}
}