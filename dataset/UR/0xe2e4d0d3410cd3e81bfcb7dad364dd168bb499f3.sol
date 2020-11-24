 

 

 

contract goods {

    address public owner;
     
    uint16 public status;
     
    uint16 public count;
     
    uint public price;

    uint16 public availableCount;
    uint16 public pendingCount;

    event log_event(string message);
    event content(string datainfo, uint indexed version, uint indexed datatype, address indexed sender, uint count, uint payment);
    modifier onlyowner { if (msg.sender == owner) _ } 
    
    function goods(uint16 _count, uint _price) {
        owner = msg.sender;
         
        status = 1;
        count = _count;
        price = _price;

        availableCount = count;
        pendingCount = 0;
    }
    
    function kill() onlyowner { suicide(owner); }

    function flush() onlyowner {
        owner.send(this.balance);
    }

    function log(string message) private {
        log_event(message);
    }

    function buy(string datainfo, uint _version, uint16 _count) {
        if(status != 1) { log("status != 1"); throw; }
        if(msg.value < (price * _count)) { log("msg.value < (price * _count)"); throw; }
        if(_count > availableCount) { log("_count > availableCount"); throw; }

        pendingCount += _count;

         
        content(datainfo, _version, 1, msg.sender, _count, msg.value);
    }

    function accept(string datainfo, uint _version, uint16 _count) onlyowner {
        if(_count > availableCount) { log("_count > availableCount"); return; }
        if(_count > pendingCount) { log("_count > pendingCount"); return; }
        
        pendingCount -= _count;
        availableCount -= _count;

         
        content(datainfo, _version, 2, msg.sender, _count, 0);
    }

    function reject(string datainfo, uint _version, uint16 _count, address recipient, uint amount) onlyowner {
        if(_count > pendingCount) { log("_count > pendingCount"); return; }

        pendingCount -= _count;
         
        recipient.send(amount);

         
        content(datainfo, _version, 3, msg.sender, _count, amount);
    }

    function cancel(string datainfo, uint _version) onlyowner {
         
        status = 2;

         
        content(datainfo, _version, 4, msg.sender, availableCount, 0);
    }
}