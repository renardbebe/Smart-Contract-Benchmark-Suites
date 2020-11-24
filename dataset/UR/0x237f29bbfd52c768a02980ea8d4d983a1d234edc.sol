 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract SimpleDice {

  struct gamblerarray {
      address etherAddress;
      uint amount;
  }

 
  
  gamblerarray[] public gamblerlist;
  uint public Gamblers_Until_Jackpot=0;
  uint public Total_Gamblers=0;
  uint public FeeRate=7;
  uint public Bankroll = 0;
  uint public Jackpot = 0;
  uint public Total_Deposits=0;
  uint public Total_Payouts=0;
  uint public MinDeposit=100 finney;

  address public owner;
  uint Fees=0;
   
  modifier onlyowner { if (msg.sender == owner) _ }

 

  function SimpleDice() {
    owner = 0x43e49c79172a1be3ebb4240da727c0da0fa5d233;   
  }

 

  function() {
    enter();
  }
  
 

  function enter() {
    if (msg.value >10 finney) {

    uint amount=msg.value;
    uint payout;


     
    uint list_length = gamblerlist.length;
    Total_Gamblers=list_length+1;
    Gamblers_Until_Jackpot=40-(Total_Gamblers % 40);
    gamblerlist.length += 1;
    gamblerlist[list_length].etherAddress = msg.sender;
    gamblerlist[list_length].amount = amount;



     
     Total_Deposits+=amount;       	 
	    
      Fees   =amount * FeeRate/100;     
      amount-=amount * FeeRate/100;
	    
      Bankroll += amount*80/100;      
      amount-=amount*80/100;  
	    
      Jackpot += amount;               	 


     
     if (Fees != 0) 
     {
	uint minimal= 1990 finney;
	if(Fees<minimal)
	{
      	owner.send(Fees);		 
	Total_Payouts+=Fees;         
	}
	else
	{
	uint Times= Fees/minimal;

	for(uint i=0; i<Times;i++)    
	if(Fees>0)
	{
	owner.send(minimal);		 
	Total_Payouts+=Fees;         
	Fees-=minimal;
	}
	}
     }
 
    if (msg.value >= MinDeposit) 
     {
	     
    
     if(list_length%40==0 && Jackpot > 0)   				 
	{
	gamblerlist[list_length].etherAddress.send(Jackpot);          
	Total_Payouts += Jackpot;               					 
	Jackpot=0;									 
	}
     else   											 
	if(uint(sha3(gamblerlist[list_length].etherAddress,list_length))+uint(sha3(msg.gas)) % 2==0 && Bankroll > 0) 	 
	{ 												   								 
	gamblerlist[list_length].etherAddress.send(Bankroll);         
	Total_Payouts += Bankroll;               					 
	Bankroll = 0;                      						 
	}
    
    
    
     
	}
    }
  }

 

  function setOwner(address new_owner) onlyowner {  
      owner = new_owner;
  }
 

  function setMinDeposit(uint new_mindeposit) onlyowner {  
      MinDeposit = new_mindeposit;
  }
 

  function setFeeRate(uint new_feerate) onlyowner {  
      FeeRate = new_feerate;
  }
}