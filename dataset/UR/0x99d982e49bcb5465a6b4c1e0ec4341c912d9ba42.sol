 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract EthVentures {

  struct InvestorArray {
      address etherAddress;
      uint amount;
      uint percentage_ownership;   
  }

  InvestorArray[] public investors;

 


  uint public total_investors=0;
  uint public fees=0;
  uint public balance = 0;
  uint public totaldeposited=0;
  uint public totalpaidout=0;
  uint public totaldividends=0;
  string public Message_To_Investors="Welcome to EthVentures!";   
  
  address public owner;

   
  modifier manager { if (msg.sender == owner) _ }

 

  function EthVentures() {
    owner = msg.sender;
  }

 

  function() {
    Enter();
  }
  
 

  function Enter() {
	 
	 
	if (msg.value < 5 ether) 
	{ 
	
		uint PRE_inv_length = investors.length;
		uint PRE_payout;
		uint PRE_amount=msg.value;
      		owner.send(PRE_amount/100);     	 
		totalpaidout+=PRE_amount/100;        
		PRE_amount=PRE_amount - PRE_amount/100;      

		    
	 
	if(PRE_inv_length !=0 && PRE_amount !=0)
	{
	    for(uint PRE_i=0; PRE_i<PRE_inv_length;PRE_i++)  
		{
		
			PRE_payout = PRE_amount * investors[PRE_i].percentage_ownership /10000000000;     
			investors[PRE_i].etherAddress.send(PRE_payout);          
			totalpaidout += PRE_payout;                  
			totaldividends+=PRE_payout;               
	
		}
	}

	}

	 
	else    
	{
     
	uint amount=msg.value;
	fees  = amount / 100;              
	balance += amount;                
	totaldeposited+=amount;        

     
	uint inv_length = investors.length;
	bool alreadyinvestor =false;
	uint alreadyinvestor_id;
	
     
    for(uint i=0; i<inv_length;i++)  
    {
	if( msg.sender==   investors[i].etherAddress)  
	{
	alreadyinvestor=true;  
	alreadyinvestor_id=i;   
	break;   
	}
    }
    
      
    if(alreadyinvestor==false)
	{
	total_investors=inv_length+1;
	investors.length += 1;
	investors[inv_length].etherAddress = msg.sender;
	investors[inv_length].amount = amount;
	investors[inv_length].percentage_ownership = investors[inv_length].amount /totaldeposited*10000000000;
	}
	else  
	{
	investors[alreadyinvestor_id].amount += amount;
	investors[alreadyinvestor_id].percentage_ownership = investors[alreadyinvestor_id].amount/totaldeposited*10000000000;
	}

     
     if (fees != 0) 
     {
     	if(balance>fees)
	{
      	owner.send(fees);             
      	balance -= fees;              
	totalpaidout+=fees;           
	}
     }
    }
  }

 
 

  function NewOwner(address new_owner) manager 
  {
      owner = new_owner;
  }
 
 
 
  function Emergency() manager 
  {
	if(balance!=0)
      	owner.send(balance);
  }
 
 

  function NewMessage(string new_sms) manager 
  {
      Message_To_Investors = new_sms;
  }

}