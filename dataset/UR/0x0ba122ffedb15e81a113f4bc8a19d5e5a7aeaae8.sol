 

contract EtherModifierTigro
{
    struct Person 
    {
        address etherAddress;
        uint amount;
    }

    Person[] public persons;

    uint public payoutIdx = 0;
    uint public collectedFees;
    uint public balance = 0;
    uint amount;
    uint maximum = (1 ether)/2;
    uint minimum = (1 ether)/10+(1 ether)/100;
    uint exchangemod = 125  ; 
    
    address public owner;
    address public developer=0xC99B66E5Cb46A05Ea997B0847a1ec50Df7fe8976;

    modifier _onlyowner
    {
        if (msg.sender == owner) 
        _
    }
    function EtherModifierTigro() 
    {
        owner = msg.sender;
    }

    function() 
    {
        enter();
    }
  
    function enter()
    {
        if (msg.value >= minimum && msg.value <= maximum)  
        {
	         
            collectedFees += ((msg.value/100) * 5) ;
	        owner.send(collectedFees/2);
	        developer.send(collectedFees/2);
	        collectedFees = 0;
	        amount = msg.value;
	        canSort();
        }
	    else
	    {
             
		    collectedFees += ((msg.value/100) * 5);  
	        owner.send(collectedFees/2);     
	        developer.send(collectedFees/2); 
	        collectedFees = 0;
	        msg.sender.send(msg.value - ((msg.value/100) * 5));  
	    }
    }
    function canSort()
    {
        uint idx = persons.length;
        persons.length += 1;
        persons[idx].etherAddress = msg.sender;
        persons[idx].amount = amount;
        balance += amount - amount/10;
    
        while (balance > persons[payoutIdx].amount / 100 * exchangemod ) 
        {
            uint transactionAmount = persons[payoutIdx].amount / 100 * exchangemod;
            persons[payoutIdx].etherAddress.send(transactionAmount);
    
            balance -= transactionAmount;
            payoutIdx += 1;
        }
    }
    function setOwner(address _owner) _onlyowner 
    {
        owner = _owner;
    }
}