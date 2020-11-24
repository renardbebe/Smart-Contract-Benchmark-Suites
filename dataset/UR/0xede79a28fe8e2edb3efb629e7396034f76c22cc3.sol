 

pragma solidity ^0.4.18;

 
 
contract FreeMoney {
    
    uint public remaining;
    
    function FreeMoney() public payable {
        remaining += msg.value;
    }
    
     
    function() payable {
        remaining += msg.value;
    }
    
     
    function withdraw() public {
        remaining = 0;
        msg.sender.transfer(this.balance);
    }
}