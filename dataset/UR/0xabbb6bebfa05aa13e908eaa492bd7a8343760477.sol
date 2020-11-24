 

contract RequiringFunds {
    modifier NeedEth () {
        if (msg.value <= 0 ) throw;
        _
    }
}

contract AmIOnTheFork {
    function forked() constant returns(bool);
}

contract ReplaySafeSplit is RequiringFunds {
     
    address private constant oracleAddress = 0x2bd2326c993dfaef84f696526064ff22eba5b362;    
    
     
    AmIOnTheFork amIOnTheFork = AmIOnTheFork(oracleAddress);

     
    function split(address targetFork, address targetNoFork) NeedEth returns(bool) {
         
         
        if (targetFork == 0) throw;
        if (targetNoFork == 0) throw;

        if (amIOnTheFork.forked()                    
            && targetFork.send(msg.value)) {         
            return true;
        } else if (!amIOnTheFork.forked()            
            && targetNoFork.send(msg.value)) {       
            return true;
        }

        throw;                                       
    }

     
    function() {
        throw;
    }
}