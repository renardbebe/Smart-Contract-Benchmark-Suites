 

 
contract self_store {

    address owner;

    uint16 public contentCount = 0;
    
    event content(string datainfo);
    modifier onlyowner { if (msg.sender == owner) _ }
    
    function self_store() public { owner = msg.sender; }
    
     
    function kill() onlyowner { suicide(owner); }

    function flush() onlyowner {
        owner.send(this.balance);
    }

    function add(string datainfo) onlyowner {
        contentCount++;
        content(datainfo);
    }
}