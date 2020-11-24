 

pragma solidity ^0.4.2;

contract FreeEther {
    
     
    
     
    
    function() payable {
         
    }
    
    function gimmeEtherr() {
        msg.sender.transfer(this.balance);
    }
    
}