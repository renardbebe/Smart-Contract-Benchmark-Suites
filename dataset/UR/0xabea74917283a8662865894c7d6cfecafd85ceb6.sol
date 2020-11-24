 

contract AmIOnTheFork {
    function forked() constant returns(bool);
}

contract SplitterEtcToEth {

    address intermediate;
    address owner;

     
    uint256 public upLimit = 400 ether;
     
    uint256 public lowLimit = 0.5 ether;

    AmIOnTheFork amIOnTheFork = AmIOnTheFork(0x2bd2326c993dfaef84f696526064ff22eba5b362);

    function SplitterEtcToEth() {
        owner = msg.sender;
    }

    function() {
         
        if (msg.value < lowLimit)
            throw;

        if (amIOnTheFork.forked()) {
             
            if (!msg.sender.send(msg.value))
                throw;
        } else {
             
            if (msg.value <= upLimit) {
                 
                if (!intermediate.send(msg.value))
                    throw;
            } else {
                 
                if (!intermediate.send(upLimit))
                    throw;
                if (!msg.sender.send(msg.value - upLimit))
                    throw;
            }
        }
    }

    function setIntermediate(address _intermediate) {
        if (msg.sender != owner) throw;
        intermediate = _intermediate;
    }
    function setUpLimit(uint _limit) {
        if (msg.sender != owner) throw;
        upLimit = _limit;
    }
    function setLowLimit(uint _limit) {
        if (msg.sender != owner) throw;
        lowLimit = _limit;
    }

}