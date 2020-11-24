 

pragma solidity ^0.4.23;

 
 
 
 

contract Auction {
  
  string public description;
  string public instructions;  
  uint public price;
  bool public initialPrice = true;  
  uint public timestampEnd;
  address public beneficiary;
  bool public finalized = false;

  address public owner;
  address public winner;
  mapping(address => uint) public bids;
  address[] public accountsList;  

   
   
  uint public increaseTimeIfBidBeforeEnd = 24 * 60 * 60;  
  uint public increaseTimeBy = 24 * 60 * 60;
  

  event Bid(address indexed winner, uint indexed price, uint indexed timestamp);
  event Refund(address indexed sender, uint indexed amount, uint indexed timestamp);
  
  modifier onlyOwner { require(owner == msg.sender, "only owner"); _; }
  modifier onlyWinner { require(winner == msg.sender, "only winner"); _; }
  modifier ended { require(now > timestampEnd, "not ended yet"); _; }

  function setDescription(string _description) public onlyOwner() {
    description = _description;
  }

  function setInstructions(string _instructions) public ended() onlyWinner()  {
    instructions = _instructions;
  }

  constructor(uint _price, string _description, uint _timestampEnd, address _beneficiary) public {
    require(_timestampEnd > now, "end of the auction must be in the future");
    owner = msg.sender;
    price = _price;
    description = _description;
    timestampEnd = _timestampEnd;
    beneficiary = _beneficiary;
  }

  function() public payable {

    if (msg.value == 0) {  
      refund();
      return;
    }

    require(now < timestampEnd, "auction has ended");  

    if (bids[msg.sender] > 0) {  
      bids[msg.sender] += msg.value;
    } else {
      bids[msg.sender] = msg.value;
      accountsList.push(msg.sender);  
    }

    if (initialPrice) {
      require(bids[msg.sender] >= price, "bid too low, minimum is the initial price");
    } else {
      require(bids[msg.sender] >= (price * 5 / 4), "bid too low, minimum 25% increment");
    }
    
    if (now > timestampEnd - increaseTimeIfBidBeforeEnd) {
      timestampEnd = now + increaseTimeBy;
    }

    initialPrice = false;
    price = bids[msg.sender];
    winner = msg.sender;
    emit Bid(winner, price, now);
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, "can withdraw only once");
    require(initialPrice == false, "can withdraw only if there were bids");

    finalized = true;
    beneficiary.transfer(price);
  }

  function refundContributors() public ended() onlyOwner() {
    bids[winner] = 0;  
    for (uint i = 0; i < accountsList.length;  i++) {
      if (bids[accountsList[i]] > 0) {
        uint refundValue = bids[accountsList[i]];
        bids[accountsList[i]] = 0;
        accountsList[i].transfer(refundValue); 
      }
    }
  }   

  function refund() public {
    require(msg.sender != winner, "winner cannot refund");
    require(bids[msg.sender] > 0, "refunds only allowed if you sent something");

    uint refundValue = bids[msg.sender];
    bids[msg.sender] = 0;  
    msg.sender.transfer(refundValue);
    
    emit Refund(msg.sender, refundValue, now);
  }

}