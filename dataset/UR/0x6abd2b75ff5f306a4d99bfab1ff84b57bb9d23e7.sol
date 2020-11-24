 

contract ThisExternalAssembly {
    uint public numcalls;
    uint public numcallsinternal;
    uint public numfails;
    uint public numsuccesses;
    
    address owner;

    event logCall(uint indexed _numcalls, uint indexed _numcallsinternal);
    
    modifier onlyOwner { if (msg.sender != owner) throw; _ }
    modifier onlyThis { if (msg.sender != address(this)) throw; _ }

     
    function ThisExternalAssembly() {
        owner = msg.sender;
    }

    function failSend() external onlyThis returns (bool) {
         
        numcallsinternal++;
        owner.send(42);

         
        if (true) throw;

         
        return true;
    }
    
    function doCall(uint _gas) onlyOwner {
        numcalls++;

        address addr = address(this);
        bytes4 sig = bytes4(sha3("failSend()"));

        bool ret;

         
         
        assembly {
            let x := mload(0x40)  
            mstore(x,sig)

            ret := call(
                _gas,  
                addr,  
                0,     
                x,     
                0x4,   
                x,     
                0x1)   

             
            mstore(0x40,add(x,0x4))  
        }

        if (ret) { numsuccesses++; }
        else { numfails++; }

         
        logCall(numcalls, numcallsinternal);
    }

     
    function selfDestruct() onlyOwner { selfdestruct(owner); }
    
    function() { throw; }
}