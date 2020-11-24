 

pragma solidity ^0.4.22;

 
 
 
 
contract Auctionify {
     
     

    address public beneficiary;
    uint public auctionEnd;
    string public auctionTitle;
    string public auctionDescription;
    uint public minimumBid;

     
    address public escrowModerator;
     

     
    address public highestBidder;

     
    mapping(address => uint) public bids;

     
    enum AuctionStates { Started, Ongoing, Ended }
    AuctionStates public auctionState;


     
    modifier auctionNotEnded()
    {
         
         
        require(
            now < auctionEnd,  
            "Auction already ended."
        );
        require(
          auctionState != AuctionStates.Ended,
           "Auction already ended."
          );
        _;
    }

     
    modifier isMinimumBid()
    {
       
      require(
          msg.value >= minimumBid,
          "The value is smaller than minimum bid."
      );
      _;
    }

    modifier isHighestBid()
    {
       
       
      require(
          msg.value > bids[highestBidder],
          "There already is a higher bid."
      );
      _;
    }

    modifier onlyHighestBidderOrEscrow()
    {
       
       
      if ((msg.sender == highestBidder) || (msg.sender == escrowModerator) || (highestBidder == address(0))) {
        _;
      }
      else{
        revert();
      }
    }


     
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event CheaterBidder(address cheater, uint amount);

    constructor(
        string _auctionTitle,
        uint _auctionEnd,
        address _beneficiary,
        string _auctionDesc,
        uint _minimumBid,
        bool _escrowEnabled,
        bool _listed
    ) public {
        auctionTitle = _auctionTitle;
        beneficiary = _beneficiary;
        auctionEnd = _auctionEnd;
        auctionDescription = _auctionDesc;
        auctionState = AuctionStates.Started;
        minimumBid = _minimumBid;
        if (_escrowEnabled) {
           
          escrowModerator = address(0x32cEfb2dC869BBfe636f7547CDa43f561Bf88d5A);  
        }
        if (_listed) {
           
        }
    }

     
    
    
    
    
    function bid() public payable auctionNotEnded isMinimumBid isHighestBid {
         
         
         
        if (highestBidder != address(0)) {
             
            uint lastBid = bids[highestBidder];
            bids[highestBidder] = 0;
            if(!highestBidder.send(lastBid)) {
                 
                emit CheaterBidder(highestBidder, lastBid);
            }
        }

         
        highestBidder = msg.sender;
        bids[msg.sender] = msg.value;

         
        auctionState = AuctionStates.Ongoing;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

     
    
    
    
    function highestBid() public view returns(uint){
      return (bids[highestBidder]);
    }

     
     
     
    
    
    function endAuction() public onlyHighestBidderOrEscrow {

         
        require(now >= auctionEnd, "Auction not yet ended.");
        require(auctionState != AuctionStates.Ended, "Auction has already ended.");

         
        auctionState = AuctionStates.Ended;
        emit AuctionEnded(highestBidder, bids[highestBidder]);

         
        if(!beneficiary.send(bids[highestBidder])) {
             
             
        }
    }

     
    
    
  function cleanUpAfterYourself() public {
    require(auctionState == AuctionStates.Ended, "Auction is not ended.");
      if (escrowModerator != address(0)) {
        selfdestruct(escrowModerator);
      } else {
        selfdestruct(beneficiary);  
      }
  }
}