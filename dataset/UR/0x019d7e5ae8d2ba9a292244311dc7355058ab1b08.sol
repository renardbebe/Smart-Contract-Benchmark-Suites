 

pragma solidity ^0.4.9;

contract ProofOfIdleness {
    address public organizer;
    
     
    uint public countRemaining = 0;
    
     
    mapping (address => uint) public lastPing;
    
     
    event Eliminated(address a);
    event Pinged(address a, uint time);

     
     
    function ProofOfIdleness() {
        organizer = msg.sender;
    }
    
    
     
    function idle() {
      if (lastPing[msg.sender] == 0)
        throw;
        
      lastPing[msg.sender] = now;
      Pinged(msg.sender, now);
    }
    
    
     
    function join() payable { 
        if (lastPing[msg.sender] > 0 || msg.value != 1 ether)
            throw;
        
        lastPing[msg.sender] = now; 
        countRemaining = countRemaining + 1;
        Pinged(msg.sender, now);
        
        if (!organizer.send(0.01 ether)) {
          throw;
        }
    }
    
    
     
     
    function eliminate(address a) {
      if (lastPing[a] == 0 || now <= lastPing[a] + 27 hours)
        throw;
        
      lastPing[a] = 0;
      countRemaining = countRemaining - 1;
      Eliminated(a);
    }
    
    
     
     
    function claimReward() {
      if (lastPing[msg.sender] == 0 || countRemaining != 1)
        throw;
        
      if (!msg.sender.send(this.balance))
        throw;
    }
}