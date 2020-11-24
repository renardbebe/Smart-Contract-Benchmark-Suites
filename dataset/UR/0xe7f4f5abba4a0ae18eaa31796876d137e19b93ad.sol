 

contract ChainSensitive {
     
    uint256 public afterForkBlockNumber;
    uint256 public afterForkRescueContractBalance;

     
     
     
    function whichChainIsThis() internal returns (uint8) {
        if (block.number >= 1920000) {
            if (afterForkBlockNumber == 0) {  
                afterForkBlockNumber = block.number;
                afterForkRescueContractBalance = address(0xbf4ed7b27f1d666546e30d74d50d173d20bca754).balance;
            }
            if (afterForkRescueContractBalance < 1000000 ether) {
                return 1;  
            } else {
                return 2;  
            }
        } else {
            return 0;  
        }
    }

    function() {
        secureSend(msg.sender);
        whichChainIsThis();   
    }

    function secureSend(address to) internal {
        if (!to.send(msg.value))
            throw;
    }

    function isThisPreforkVersion() returns (bool) {
        secureSend(msg.sender);
        return whichChainIsThis() == 0;
    }
    
    function isThisPuritanicalVersion() returns (bool) {
        secureSend(msg.sender);
        return whichChainIsThis() == 1;
    }

    function isThisHardforkedVersion() returns (bool) {
        secureSend(msg.sender);
        return whichChainIsThis() == 2;
    }

    function transferIfPuritanical(address to) {
        if (whichChainIsThis() == 1) {
            secureSend(to);
        } else {
            secureSend(msg.sender);
        }
    }

    function transferIfHardForked(address to) {
        if (whichChainIsThis() == 2) {
            secureSend(to);
        } else {
            secureSend(msg.sender);
        }
    }
}