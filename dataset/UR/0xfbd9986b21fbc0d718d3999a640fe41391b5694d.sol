 

 
contract TheDaoHardForkOracle {
     
    function forked() constant returns (bool);
}

 
 
contract ReversibleDemo {
     
    uint public numcalls;
    uint public numcallsinternal;
    uint public numfails;
    uint public numsuccesses;

    address owner;

     
    address constant withdrawdaoaddr = 0xbf4ed7b27f1d666546e30d74d50d173d20bca754;
    TheDaoHardForkOracle oracle = TheDaoHardForkOracle(0xe8e506306ddb78ee38c9b0d86c257bd97c2536b3);

    event logCall(uint indexed _numcalls,
                  uint indexed _numfails,
                  uint indexed _numsuccesses);

    modifier onlyOwner { if (msg.sender != owner) throw; _ }
    modifier onlyThis { if (msg.sender != address(this)) throw; _ }

     
    function ReversibleDemo() { owner = msg.sender; }

     
     
    function sendIfNotForked() external onlyThis returns (bool) {
        numcallsinternal++;

         
         
         
        if (withdrawdaoaddr.balance < 3000000 ether) {
             
            owner.send(42);
        }

         
        if (oracle.forked()) throw;

         
        return true;
    }

     
    function doCall(uint _gas) onlyOwner {
        numcalls++;

        if (!this.sendIfNotForked.gas(_gas)()) {
            numfails++;
        }
        else {
            numsuccesses++;
        }
        logCall(numcalls, numfails, numsuccesses);
    }

    function selfDestruct() onlyOwner {
        selfdestruct(owner);
    }

     
    function() {}
}