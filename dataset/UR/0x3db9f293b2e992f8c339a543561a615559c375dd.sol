 

pragma solidity ^0.4.19;

 

 
 

 

 
 

contract Countdown {
    uint public deadline = now;
    uint private constant waittime = 12 hours;
    
    address private owner = msg.sender;
    address public winner;
    
    function () public payable {
        
    }
    
    function click() public payable {
        require(msg.value >= 0.0001 ether);
        deadline = now + waittime;
        winner = msg.sender;
    }
    
    function withdraw() public {
        require(now > deadline);
        require(msg.sender == winner);
        
        deadline = now + waittime;

         
         
        if(this.balance < 0.0005 ether)
            msg.sender.transfer(this.balance);
        else
            msg.sender.transfer(this.balance /  10);

         
        if(this.balance > 0.0005 ether)
            owner.transfer(0.0005 ether);
    }
}