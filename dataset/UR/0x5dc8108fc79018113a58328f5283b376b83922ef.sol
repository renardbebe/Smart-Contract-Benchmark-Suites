 

contract AmIOnTheFork {
    function forked() constant returns(bool);
}

contract LedgerSplitSingle {
     
    AmIOnTheFork amIOnTheFork = AmIOnTheFork(0x2bd2326c993dfaef84f696526064ff22eba5b362);

     
    function split(bool forked, address target) returns(bool) {
        if (amIOnTheFork.forked() && forked && target.send(msg.value)) {
            return true;
        } 
        else
        if (!amIOnTheFork.forked() && !forked && target.send(msg.value)) {
            return true;
        } 
        throw;  
    }

     
    function() {
        throw;
    }
}