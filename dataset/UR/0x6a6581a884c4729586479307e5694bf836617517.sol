 

 

contract Dao9000 {
    string message;  
    address[] public members;

    function Dao9000 () {
        members.push (msg.sender);  
        message = "Message not yet defined";
    }
    
     
    function getMembers () constant returns (uint256 retVal) {
        return members.length;
    }
    
    function getMessage () constant returns (string retVal) {
        return message;
    }
    
     
    function () {
         
        if (msg.value < 1500000000000000000 && msg.value > 1) {
             
            uint256 randomIndex = (uint256(block.blockhash(block.number-1)) + now) % members.length;
            if (members[randomIndex].send(msg.value)) {
                if (msg.data.length > 0)
                    message = string(msg.data);  
                members.push (msg.sender);  
            } else {
                throw;
            }
        } else {
            throw;
        }
    }
}