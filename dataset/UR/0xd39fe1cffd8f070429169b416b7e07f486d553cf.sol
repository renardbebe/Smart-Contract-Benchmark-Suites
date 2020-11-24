 

contract store {

    address owner;

    uint public contentCount = 0;
    
    event content(string datainfo, uint indexed version, address indexed sender, uint indexed datatype, uint timespan, uint payment);
    modifier onlyowner { if (msg.sender == owner) _ } 
    
    function store() public { owner = msg.sender; }
    
     
    function kill() onlyowner { suicide(owner); }

    function flush() onlyowner {
        owner.send(this.balance);
    }

    function add(string datainfo, uint version, uint datatype, uint timespan) {
         
        if(datatype == 1) {
           
          if(timespan <= 1209600) {
            if(msg.value < (4 finney)) return;
           
          } else if(timespan <= 2419200) {
            if(msg.value < (6 finney)) return;
           
          } else {
            timespan = 2419200;
            if(msg.value < (6 finney)) return;
          }
        }

         
        if(msg.value > (6 finney)) throw;

        contentCount++;
        content(datainfo, version, msg.sender, datatype, timespan, msg.value);
    }
}