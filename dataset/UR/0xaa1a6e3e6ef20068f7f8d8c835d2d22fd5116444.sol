 

contract AmIOnTheFork {
    function forked() constant returns(bool);
}

contract ReplaySafeSplit {
     
    AmIOnTheFork amIOnTheFork = AmIOnTheFork(0x2bd2326c993dfaef84f696526064ff22eba5b362);

     
    function split(address targetFork, address targetNoFork) returns(bool) {
        if (amIOnTheFork.forked() && targetFork.send(msg.value)) {
            return true;
        } else if (!amIOnTheFork.forked() && targetNoFork.send(msg.value)) {
            return true;
        }
        throw;  
    }

     
    function() {
        throw;
    }
}