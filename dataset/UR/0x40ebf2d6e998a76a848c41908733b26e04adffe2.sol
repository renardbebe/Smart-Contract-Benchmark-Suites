 

contract AmIOnTheFork {
    function forked() constant returns(bool);
}

contract ReplaySafeSend {
     
    AmIOnTheFork amIOnTheFork = AmIOnTheFork(0x2bd2326c993dfaef84f696526064ff22eba5b362);

    function safeSend(address etcAddress) returns(bool) {
        if (!amIOnTheFork.forked() && etcAddress.send(msg.value)) {
            return true;
        }
        throw;  
    }

     
    function() {
        throw;
    }
}