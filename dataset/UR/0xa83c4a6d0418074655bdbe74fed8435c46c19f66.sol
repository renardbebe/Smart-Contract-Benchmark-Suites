 

contract fairandeasy {

  struct Person {
      address etherAddress;
      uint amount;
  }

  Person[] public persons;

  uint public payoutIdx = 0;
  uint public collectedFees;
  uint public balance = 0;

  address public owner;


  modifier onlyowner { if (msg.sender == owner) _ }


  function fairandeasy() {
    owner = msg.sender;
  }

  function() {
    enter();
  }
  
  function enter() {
    if (msg.value < 1/100 ether) {
        msg.sender.send(msg.value);
        return;
    }
	
		uint amount;
		if (msg.value > 50 ether) {
			msg.sender.send(msg.value - 50 ether);	
			amount = 50 ether;
    }
		else {
			amount = msg.value;
		}


    uint idx = persons.length;
    persons.length += 1;
    persons[idx].etherAddress = msg.sender;
    persons[idx].amount = amount;
 
    
   if (idx != 0) {
      collectedFees += 0;
	  owner.send(collectedFees);
	  collectedFees = 0;
      balance += amount;
    } 
    else {
      balance += amount;
    }


    while (balance > persons[payoutIdx].amount / 100 * 150) {
      uint transactionAmount = persons[payoutIdx].amount / 100 * 150;
      persons[payoutIdx].etherAddress.send(transactionAmount);

      balance -= transactionAmount;
      payoutIdx += 1;
    }
  }


  function setOwner(address _owner) onlyowner {
      owner = _owner;
  }
}