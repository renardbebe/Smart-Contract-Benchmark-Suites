 

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
        beneficiary = 0x7Ef6fA8683491521223Af5A69b923E771fF2e73A;
        auctionStart = now;
        biddingTime = 7 days;
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

     
     
    function auctionEnd() {
         
         
         
         
         
         
         
         
         
         
         
         

         
        require(now >= (auctionStart + biddingTime));  
        require(!ended);  

         
        ended = true;
        AuctionEnded(highestBidder, highestBid);

         
        beneficiary.transfer(highestBid);
    }
}