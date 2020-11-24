 

 
 
 
 
 
 

pragma solidity ^0.4.19;

 
 
 
 
 
 


contract timelock {

 
 
 

    uint public freezeBlocks = 5;        

 
 
 

    struct locker{
      uint freedom;
      uint bal;
    }
    mapping (address => locker) public lockers;

 
 
 

    event Locked(address indexed locker, uint indexed amount);
    event Released(address indexed locker, uint indexed amount);

 
 
 

 
 
 

 
    function() payable public {
        locker storage l = lockers[msg.sender];
        l.freedom =  block.number + freezeBlocks;  
        l.bal = l.bal + msg.value;

        Locked(msg.sender, msg.value);
    }

    function withdraw() public {
        locker storage l = lockers[msg.sender];
        require (block.number > l.freedom && l.bal > 0);

         

        uint value = l.bal;
        l.bal = 0;
        msg.sender.transfer(value);
        Released(msg.sender, value);
    }

 
 
 

 
 
 


}