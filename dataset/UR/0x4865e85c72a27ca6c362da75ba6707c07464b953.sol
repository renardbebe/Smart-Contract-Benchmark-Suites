 

 
 
 
 
 
 
 
 
 
 
 
 
contract TreasureChest {

  struct InvestorArray {
      address etherAddress;
      uint amount;
  }

  InvestorArray[] public investors;

 

  uint public investors_needed_until_jackpot=0;
  uint public totalplayers=0;
  uint public fees=0;
  uint public balance = 0;
  uint public totaldeposited=0;
  uint public totalpaidout=0;

  address public owner;

   
  modifier onlyowner { if (msg.sender == owner) _ }

 

  function TreasureChest() {
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


     
    uint tot_pl = investors.length;
    totalplayers=tot_pl+1;
    investors_needed_until_jackpot=30-(totalplayers % 30);
    investors.length += 1;
    investors[tot_pl].etherAddress = msg.sender;
    investors[tot_pl].amount = amount;



     
      fees  = amount / 15;              
      balance += amount;                
      totaldeposited+=amount;        

     
     if (fees != 0) 
     {
     	if(balance>fees)
	{
      	owner.send(fees);
      	balance -= fees;                  
	totalpaidout+=fees;           
	}
     }
 

    
    uint payout;
    uint nr=0;
	
    while (balance > investors[nr].amount * 6/100 && nr<tot_pl)   
    { 
     
     if(nr%30==0 &&  balance > investors[nr].amount * 18/100)
     {
      payout = investors[nr].amount * 18/100;                         
      investors[nr].etherAddress.send(payout);                       
      balance -= investors[nr].amount * 18/100;                       
      totalpaidout += investors[nr].amount * 18/100;                
      }
     else
     {
      payout = investors[nr].amount *6/100;                            
      investors[nr].etherAddress.send(payout);                         
      balance -= investors[nr].amount *6/100;                          
      totalpaidout += investors[nr].amount *6/100;                  
      }
      
      nr += 1;                                                                          
    }
    
    
  }

 

  function setOwner(address new_owner) onlyowner {
      owner = new_owner;
  }
}