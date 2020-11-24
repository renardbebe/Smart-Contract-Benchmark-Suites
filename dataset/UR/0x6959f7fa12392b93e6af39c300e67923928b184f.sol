 

pragma solidity ^0.4.11;

contract SimpleAuction {
     
     
     
    address public beneficiary;
    uint public auctionStart;
    uint public biddingTime;

     
    address public highestBidder;
    uint public highestBid;

     
    mapping(address => uint) pendingReturns;

     
    bool ended;

     
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

     
     
     
     

     
     
     
    function SimpleAuction() {
        beneficiary = 0xc2752751E6B91736d5a2e8E31336DC7C7220e8FC;
        auctionStart = now;
        biddingTime = 600;
    }

     
     
     
     
    function bid() payable {
         
         
         
         
         

         
         
        require(now <= (auctionStart + biddingTime));

         
         
        require(msg.value > highestBid);

        if (highestBidder != 0) {
             
             
             
             
             
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, msg.value);
    }

     
    function withdraw() returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
             
             
             
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                 
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
     
    function auctionEndTime() constant returns (uint256) {
        return auctionStart + biddingTime;
    }
    
     
     
    function auctionEnd() {
         
         
         
         
         
         
         
         
         
         
         
         

         
        require(now >= (auctionStart + biddingTime));  
        require(!ended);  

         
        ended = true;
        AuctionEnded(highestBidder, highestBid);

         
        beneficiary.transfer(highestBid);
    }
}