 

contract ResetPonzi {
    
    struct Person {
      address addr;
    }
    
    struct NiceGuy {
      address addr2;
    }
    
    Person[] public persons;
    NiceGuy[] public niceGuys;
    
    uint public payoutIdx = 0;
    uint public currentNiceGuyIdx = 0;
    uint public investor = 0;
    
    address public currentNiceGuy;
    address public beta;
    
    function ResetPonzi() {
        currentNiceGuy = msg.sender;
    }
    
    
    function() {
        
        if (msg.value != 9 ether) {
            throw;
        }
        
        if (investor < 8) {
            uint idx = persons.length;
            persons.length += 1;
            persons[idx].addr = msg.sender;
        }
        
        if (investor > 7) {
            uint ngidx = niceGuys.length;
            niceGuys.length += 1;
            niceGuys[ngidx].addr2 = msg.sender;
            if (investor > 8 ) {
                currentNiceGuy = niceGuys[currentNiceGuyIdx].addr2;
                currentNiceGuyIdx += 1;
            }
        }
        
        if (investor < 9) {
            investor += 1;
        }
        else {
            investor = 0;
        }
        
        currentNiceGuy.send(1 ether);
        
        while (this.balance >= 10 ether) {
            persons[payoutIdx].addr.send(10 ether);
            payoutIdx += 1;
        }
    }
}