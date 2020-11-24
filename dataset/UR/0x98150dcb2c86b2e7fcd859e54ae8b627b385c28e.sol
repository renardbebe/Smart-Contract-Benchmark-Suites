 

pragma solidity ^0.4.18;

 
 
 


 


contract Splitter {
    address public owner;    
    address public payee = 0xE413239e62f25Cc6746cD393920d123322aCa948;    
    uint    public percent = 10;  
    
     
     
    function Splitter() public {
        owner   = msg.sender;
    }
    
     
     
    function Withdraw() external {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }
    
     
     
    function() external payable {
        owner.transfer(msg.value * percent / 100);
        payee.transfer(msg.value * (100 - percent) / 100);
    }
}