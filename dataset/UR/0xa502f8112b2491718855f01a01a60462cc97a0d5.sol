 

contract UfoPonzi {

    struct Participant {
        address etherAddress;
        uint amount;
    }

    Participant[] public participants;

    uint public payoutIdx = 0;
    uint public collectedFees;
    uint public balance = 0;

    address public owner;

     
    modifier onlyowner { if (msg.sender == owner) _ }

     
    function UfoPonzi() {
        owner = msg.sender;
        balance += msg.value;
    }

     
    function() {
        enter();
    }
    
    function enter() {
        if (msg.value < 1 ether) {
            msg.sender.send(msg.value);
            return;
        }

         
        uint idx = participants.length;
        participants.length += 1;
        participants[idx].etherAddress = msg.sender;
        participants[idx].amount = msg.value;
        
         
        if (idx != 0) {
            collectedFees += msg.value / 10;
            balance += msg.value;
        } 
        else {
             
             
            collectedFees += msg.value;
        }

   
        if (balance > participants[payoutIdx].amount / 10 + participants[payoutIdx].amount) {
            uint transactionAmount = (participants[payoutIdx].amount - participants[payoutIdx].amount / 10) / 10 + (participants[payoutIdx].amount - participants[payoutIdx].amount / 10);
            participants[payoutIdx].etherAddress.send(transactionAmount);

            balance -= participants[payoutIdx].amount / 10 + participants[payoutIdx].amount;
            payoutIdx += 1;
        }
    }

    function collectFees() onlyowner {
        if (collectedFees == 0) return;

        owner.send(collectedFees);
        collectedFees = 0;
    }

    function setOwner(address _owner) onlyowner {
        owner = _owner;
    }
}