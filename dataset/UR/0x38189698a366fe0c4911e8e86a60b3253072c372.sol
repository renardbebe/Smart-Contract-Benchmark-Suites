 

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
  function getAccountListLenght() public constant returns(uint) { return accountsList.length; }  

   
   
  uint public increaseTimeIfBidBeforeEnd = 24 * 60 * 60;  
  uint public increaseTimeBy = 24 * 60 * 60;
  

  event BidEvent(address indexed bidder, uint value, uint timestamp);  
  event Refund(address indexed bidder, uint value, uint timestamp);

  
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
    } else {
      bid();
    }  
  }

  function bid() public payable {
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
    emit BidEvent(winner, msg.value, now);  
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, "can withdraw only once");
    require(initialPrice == false, "can withdraw only if there were bids");

    finalized = true;
    beneficiary.transfer(price);
  }

  function refund(address addr) private {
    require(addr != winner, "winner cannot refund");
    require(bids[addr] > 0, "refunds only allowed if you sent something");

    uint refundValue = bids[addr];
    bids[addr] = 0;  
    addr.transfer(refundValue);
    
    emit Refund(addr, refundValue, now);
  }

  function refund() public {
    refund(msg.sender);
  }

  function refundOnBehalf(address addr) public onlyOwner() {
    refund(addr);
  }

}

 

 
 

contract AuctionMultiple is Auction {

  uint public constant LIMIT = 2000;  
  uint public constant HEAD = 120000000 * 1e18;  
  uint public constant TAIL = 0;
  uint public lastBidID = 0;  
  uint public howMany;  

  struct Bid {
    uint prev;             
    uint next;             
    uint value;
    address contributor;   
  }    

  mapping (uint => Bid) public bids;  
  mapping (address => uint) public contributors;  
  
  event LogNumber(uint number);
  event LogText(string text);
  event LogAddress(address addr);
  
  constructor(uint _price, string _description, uint _timestampEnd, address _beneficiary, uint _howMany) Auction(_price, _description, _timestampEnd, _beneficiary) public {
    require(_howMany > 1, "This auction is suited to multiple items. With 1 item only - use different code. Or remove this 'require' - you've been warned");
    howMany = _howMany;

    bids[HEAD] = Bid({
        prev: TAIL,
        next: TAIL,
        value: HEAD,
        contributor: address(0)
    });
    bids[TAIL] = Bid({
        prev: HEAD,
        next: HEAD,
        value: TAIL,
        contributor: address(0)
    });    
  }

  function bid() public payable {
    require(now < timestampEnd, "cannot bid after the auction ends");

    uint myBidId = contributors[msg.sender];
    uint insertionBidId;
    
    if (myBidId > 0) {  
        
      Bid storage existingBid = bids[myBidId];
      existingBid.value = existingBid.value + msg.value;
      if (existingBid.value > bids[existingBid.next].value) {  
        insertionBidId = searchInsertionPoint(existingBid.value, existingBid.next);

        bids[existingBid.prev].next = existingBid.next;
        bids[existingBid.next].prev = existingBid.prev;

        existingBid.prev = insertionBidId;
        existingBid.next = bids[insertionBidId].next;

        bids[ bids[insertionBidId].next ].prev = myBidId;
        bids[insertionBidId].next = myBidId;
      } 

    } else {  
      require(msg.value >= price, "Not much sense sending less than the price, likely an error");  
      require(lastBidID < LIMIT, "Due to blockGas limit we limit number of people in the auction to 4000 - round arbitrary number - check test gasLimit folder for more info");

      lastBidID++;

      insertionBidId = searchInsertionPoint(msg.value, TAIL);

      contributors[msg.sender] = lastBidID;
      accountsList.push(msg.sender);

      bids[lastBidID] = Bid({
        prev: insertionBidId,
        next: bids[insertionBidId].next,
        value: msg.value,
        contributor: msg.sender
      });

      bids[ bids[insertionBidId].next ].prev = lastBidID;
      bids[insertionBidId].next = lastBidID;
    }

    emit BidEvent(msg.sender, msg.value, now);
  }

  function refund(address addr) private {
    uint bidId = contributors[addr];
    require(bidId > 0, "the guy with this address does not exist, makes no sense to witdraw");
    uint position = getPosition(addr);
    require(position > howMany, "only the non-winning bids can be withdrawn");

    uint refundValue = bids[ bidId ].value;
    _removeBid(bidId);

    addr.transfer(refundValue);
    emit Refund(addr, refundValue, now);
  }

   
  function _removeBid(uint bidId) internal {
    Bid memory thisBid = bids[ bidId ];
    bids[ thisBid.prev ].next = thisBid.next;
    bids[ thisBid.next ].prev = thisBid.prev;

    delete bids[ bidId ];  
    delete contributors[ msg.sender ];  
     
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, "auction already finalized, can withdraw only once");
    finalized = true;

    uint sumContributions = 0;
    uint counter = 0;
    Bid memory currentBid = bids[HEAD];
    while(counter++ < howMany && currentBid.prev != TAIL) {
      currentBid = bids[ currentBid.prev ];
      sumContributions += currentBid.value;
    }

    beneficiary.transfer(sumContributions);
  }

   
   
   
  function searchInsertionPoint(uint _contribution, uint _startSearch) view public returns (uint) {
    require(_contribution > bids[_startSearch].value, "your contribution and _startSearch does not make sense, it will search in a wrong direction");

    Bid memory lowerBid = bids[_startSearch];
    Bid memory higherBid;

    while(true) {  
      higherBid = bids[lowerBid.next];

      if (_contribution < higherBid.value) {
        return higherBid.prev;
      } else {
        lowerBid = higherBid;
      }
    }
  }

  function getPosition(address addr) view public returns(uint) {
    uint bidId = contributors[addr];
    require(bidId != 0, "cannot ask for a position of a guy who is not on the list");
    uint position = 1;

    Bid memory currentBid = bids[HEAD];

    while (currentBid.prev != bidId) {  
      currentBid = bids[currentBid.prev];
      position++;
    }
    return position;
  }

  function getPosition() view public returns(uint) {  
    return getPosition(msg.sender);
  }

}

 

 

 

 
contract AuctionMultipleGuaranteed is AuctionMultiple {

  uint public howManyGuaranteed;  
  uint public priceGuaranteed;
  address[] public guaranteedContributors;  
  mapping (address => uint) public guaranteedContributions;
  function getGuaranteedContributorsLenght() public constant returns(uint) { return guaranteedContributors.length; }  

  event GuaranteedBid(address indexed bidder, uint value, uint timestamp);
  
  constructor(uint _price, string _description, uint _timestampEnd, address _beneficiary, uint _howMany, uint _howManyGuaranteed, uint _priceGuaranteed) AuctionMultiple(_price, _description, _timestampEnd, _beneficiary, _howMany) public {
    require(_howMany >= _howManyGuaranteed, "The number of guaranteed items should be less or equal than total items. If equal = fixed price sell, kind of OK with me");
    require(_priceGuaranteed > 0, "Guranteed price must be greated than zero");

    howManyGuaranteed = _howManyGuaranteed;
    priceGuaranteed = _priceGuaranteed;
  }

  function bid() public payable {
    require(now < timestampEnd, "cannot bid after the auction ends");
    require(guaranteedContributions[msg.sender] == 0, "already a guranteed contributor, cannot more than once");

    uint myBidId = contributors[msg.sender];
    if (myBidId > 0) {
      uint newTotalValue = bids[myBidId].value + msg.value;
      if (newTotalValue >= priceGuaranteed && howManyGuaranteed > 0) {
        _removeBid(myBidId);
        _guarantedBid(newTotalValue);
      } else {
        super.bid();  
      }
    } else if (msg.value >= priceGuaranteed && howManyGuaranteed > 0) {
      _guarantedBid(msg.value);
    } else {
       super.bid();  
    }
  }

  function _guarantedBid(uint value) private {
    guaranteedContributors.push(msg.sender);
    guaranteedContributions[msg.sender] = value;
    howManyGuaranteed--;
    howMany--;
    emit GuaranteedBid(msg.sender, value, now);
  }

  function finalize() public ended() onlyOwner() {
    require(finalized == false, "auction already finalized, can withdraw only once");
    finalized = true;

    uint sumContributions = 0;
    uint counter = 0;
    Bid memory currentBid = bids[HEAD];
    while(counter++ < howMany && currentBid.prev != TAIL) {
      currentBid = bids[ currentBid.prev ];
      sumContributions += currentBid.value;
    }

     
    for (uint i=0; i<guaranteedContributors.length; i++) {
      sumContributions += guaranteedContributions[ guaranteedContributors[i] ];
    }

    beneficiary.transfer(sumContributions);
  }
}