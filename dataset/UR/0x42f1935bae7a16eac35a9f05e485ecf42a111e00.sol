 

pragma solidity ^0.4.20;

contract Penny {

     
    address public owner;
    
     
    address public latestBidder;
    address public latestWinner;
    
     
    uint public endTime;
    uint public addTime;
    
     
    event Bid(address bidder, uint ending, uint adding, uint balance);

     
    function Penny() public {
        owner           = msg.sender;
        latestBidder    = msg.sender;
        latestWinner    = msg.sender;
        addTime         = (2 hours);
        endTime         = 0;
    }

     
    function bid() payable public{
        
         
        require(msg.value == 5000000000000000);

         
        if(endTime == 0){
            endTime = (now + addTime);
        }
        
         
        if(endTime != 0 && endTime > now){
            addTime -= (10 seconds);
            endTime = (now + addTime);
            latestBidder = msg.sender;
            Bid(latestBidder, endTime, addTime, this.balance);
        }
        
         
        if(addTime == 0 || endTime <= now){
            latestWinner = latestBidder;
            
             
            addTime = (2 hours);
            endTime = (now + addTime);
            latestBidder = msg.sender;
            Bid(latestBidder, endTime, addTime, ((this.balance/20)*17)+5000000000000000);
            
             
            owner.transfer((this.balance/20)*1);
            latestWinner.transfer(((this.balance-5000000000000000)/10)*8);
        }
    }
    
     
    function() public payable {}
}