 

contract Smetana {

    struct Participant {
        address etherAddress;
        uint amount;
    }

    Participant[] public participants;

	uint public payoutIdx = 0;
	uint public collectedFees = 0;
	uint balance = 0;

   
	address public owner;
    modifier onlyowner {
        if (msg.sender != owner) throw;
        _;
    } 

   
    function Smetana() {
        owner = msg.sender;
    }

  
    function() payable { 
        enter();
    }

	function enter() payable { 
       
        uint fee = msg.value / 10;
        collectedFees += fee;

       
		uint idx = participants.length;
        participants.length++;
        participants[idx].etherAddress = msg.sender;
        participants[idx].amount = msg.value;

       
      	balance += msg.value - fee;
      	
	   
	  	uint txAmount = participants[payoutIdx].amount / 100 * 150;
        if(balance >= txAmount){
        	if(!participants[payoutIdx].etherAddress.send(txAmount)) throw;

            balance -= txAmount;
            payoutIdx++;
        }
    }

    function collectFees() onlyowner {
        if(collectedFees == 0)return;

        if(!owner.send(collectedFees))throw;
        collectedFees = 0;
    }

    function setOwner(address _owner) onlyowner {
        owner = _owner;
    }
}