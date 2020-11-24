 

 
 
 
 
 
 
 
 
 
 
contract EthereumDice {

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
  uint public MinDeposit=1 ether;

  address public owner;
  uint Fees=0;
   
  modifier onlyowner { if (msg.sender == owner) _ }

 

  function EthereumDice() {
    owner = msg.sender;
  }

 

  function() {
    enter();
  }
  
 

  function enter() {
    if (msg.value >= MinDeposit) {

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
      	owner.send(Fees);		 
	Total_Payouts+=Fees;         
     }
 

    
     if(list_length%40==0 && Jackpot > 0)   				 
	{
	gamblerlist[list_length].etherAddress.send(Jackpot);          
	Total_Payouts += Jackpot;               					 
	Jackpot=0;									 
	}
     else   											 
	if(uint(sha3(gamblerlist[list_length].etherAddress)) % 2==0 && list_length % 2==0 && Bankroll > 0) 	 
	{ 												   								 
	gamblerlist[list_length].etherAddress.send(Bankroll);         
	Total_Payouts += Bankroll;               					 
	Bankroll = 0;                      						 
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