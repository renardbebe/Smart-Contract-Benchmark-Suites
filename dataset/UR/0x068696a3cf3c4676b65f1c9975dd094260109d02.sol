 

pragma solidity ^0.4.13;

 

contract DadaCollectible {

   
  address owner;


   
  bool isExecutionAllowed = false;

   
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  struct Offer {
      bool isForSale;
      uint drawingId;
      uint printIndex;
      address seller; 
      uint minValue;           
      address onlySellTo;      
      uint lastSellValue;
  }

  struct Bid {
      bool hasBid;
      uint drawingId;
      uint printIndex;
      address bidder;
      uint value;
  }

  struct Collectible{
    uint drawingId;
    string checkSum;  
    uint totalSupply;
    uint nextPrintIndexToAssign;
    bool allPrintsAssigned;
    uint initialPrice;
    uint initialPrintIndex;
    string collectionName;
    uint authorUId;  
    string scarcity;  
  }    

   
   
  mapping (uint => address) public DrawingPrintToAddress;
  
   
   
   
   
  mapping (uint => Offer) public OfferedForSale;

   
  mapping (uint => Bid) public Bids;


   
  mapping (uint => Collectible) public drawingIdToCollectibles;

  mapping (address => uint) public pendingWithdrawals;

  mapping (address => uint256) public balances;

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  } 

   
  event Assigned(address indexed to, uint256 collectibleIndex, uint256 printIndex);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event CollectibleTransfer(address indexed from, address indexed to, uint256 collectibleIndex, uint256 printIndex);
  event CollectibleOffered(uint indexed collectibleIndex, uint indexed printIndex, uint minValue, address indexed toAddress, uint lastSellValue);
  event CollectibleBidEntered(uint indexed collectibleIndex, uint indexed printIndex, uint value, address indexed fromAddress);
  event CollectibleBidWithdrawn(uint indexed collectibleIndex, uint indexed printIndex, uint value, address indexed fromAddress);
  event CollectibleBought(uint indexed collectibleIndex, uint printIndex, uint value, address indexed fromAddress, address indexed toAddress);
  event CollectibleNoLongerForSale(uint indexed collectibleIndex, uint indexed printIndex);

   
  function DadaCollectible () { 
     
     
     
    owner = msg.sender;

     
    totalSupply = 16600;
     
    balances[owner] = totalSupply;

     
    name = "DADA Collectible";
     
    symbol = "Ɖ";
     
    decimals = 0;
  }

   
  
   
  function buyCollectible(uint drawingId, uint printIndex) payable {
    require(isExecutionAllowed);
     
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) &&  (printIndex >= collectible.initialPrintIndex));
    Offer storage offer = OfferedForSale[printIndex];
    require(offer.drawingId != 0);
    require(offer.isForSale);  
    require(offer.onlySellTo == 0x0 || offer.onlySellTo == msg.sender);   
    require(msg.value >= offer.minValue);  
    require(offer.seller == DrawingPrintToAddress[printIndex]);  
    require(DrawingPrintToAddress[printIndex] != msg.sender);

    address seller = offer.seller;
    address buyer = msg.sender;

    DrawingPrintToAddress[printIndex] = buyer;  

     
    balances[seller]--;
     
    balances[buyer]++;

     
    Transfer(seller, buyer, 1);

     
     
     
     
     
     
    if(offer.lastSellValue < msg.value && (msg.value - offer.lastSellValue) >= 100 ){  
      uint profit = msg.value - offer.lastSellValue;
       
      pendingWithdrawals[seller] += offer.lastSellValue + (profit*60/100); 
       
       
       
       
       
      pendingWithdrawals[owner] += (profit*40/100);
    }else{
       
       
      pendingWithdrawals[seller] += msg.value;
    }
    makeCollectibleUnavailableToSale(buyer, drawingId, printIndex, msg.value);

     
    CollectibleBought(drawingId, printIndex, msg.value, seller, buyer);

     
     
    Bid storage bid = Bids[printIndex];
    if (bid.bidder == buyer) {
       
      pendingWithdrawals[buyer] += bid.value;
      Bids[printIndex] = Bid(false, collectible.drawingId, printIndex, 0x0, 0);
    }
  }

  function alt_buyCollectible(uint drawingId, uint printIndex) payable {
    require(isExecutionAllowed);
     
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) &&  (printIndex >= collectible.initialPrintIndex));
    Offer storage offer = OfferedForSale[printIndex];
    require(offer.drawingId == 0);
    
    require(msg.value >= collectible.initialPrice);  
    require(DrawingPrintToAddress[printIndex] == 0x0);  

    address seller = owner;
    address buyer = msg.sender;

    DrawingPrintToAddress[printIndex] = buyer;  

     
     
    balances[seller]--;
     
    balances[buyer]++;

     
    Transfer(seller, buyer, 1);

     
     
     
     
     

    pendingWithdrawals[owner] += msg.value;
    
    OfferedForSale[printIndex] = Offer(false, collectible.drawingId, printIndex, buyer, msg.value, 0x0, msg.value);

     
    CollectibleBought(drawingId, printIndex, msg.value, seller, buyer);

     
     
    Bid storage bid = Bids[printIndex];
    if (bid.bidder == buyer) {
       
      pendingWithdrawals[buyer] += bid.value;
      Bids[printIndex] = Bid(false, collectible.drawingId, printIndex, 0x0, 0);
    }
  }
  
  function enterBidForCollectible(uint drawingId, uint printIndex) payable {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] != 0x0);  
    require(DrawingPrintToAddress[printIndex] != msg.sender);  
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));

    require(msg.value > 0);  
     
    Bid storage existing = Bids[printIndex];
     
     
    require(msg.value >= existing.value+(existing.value*5/100));
    if (existing.value > 0) {
         
        pendingWithdrawals[existing.bidder] += existing.value;
    }
     
    Bids[printIndex] = Bid(true, collectible.drawingId, printIndex, msg.sender, msg.value);
    CollectibleBidEntered(collectible.drawingId, printIndex, msg.value, msg.sender);
  }

   
  function withdrawBidForCollectible(uint drawingId, uint printIndex) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    require(DrawingPrintToAddress[printIndex] != 0x0);  
    require(DrawingPrintToAddress[printIndex] != msg.sender);  
    Bid storage bid = Bids[printIndex];
    require(bid.bidder == msg.sender);
    CollectibleBidWithdrawn(drawingId, printIndex, bid.value, msg.sender);

    uint amount = bid.value;
    Bids[printIndex] = Bid(false, collectible.drawingId, printIndex, 0x0, 0);
     
    msg.sender.transfer(amount);
  }

   
  function offerCollectibleForSale(uint drawingId, uint printIndex, uint minSalePriceInWei) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    uint lastSellValue = OfferedForSale[printIndex].lastSellValue;
    OfferedForSale[printIndex] = Offer(true, collectible.drawingId, printIndex, msg.sender, minSalePriceInWei, 0x0, lastSellValue);
    CollectibleOffered(drawingId, printIndex, minSalePriceInWei, 0x0, lastSellValue);
  }

  function withdrawOfferForCollectible(uint drawingId, uint printIndex){
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));

    uint lastSellValue = OfferedForSale[printIndex].lastSellValue;

    OfferedForSale[printIndex] = Offer(false, collectible.drawingId, printIndex, msg.sender, 0, 0x0, lastSellValue);
     
    CollectibleNoLongerForSale(collectible.drawingId, printIndex);

  }

  function offerCollectibleForSaleToAddress(uint drawingId, uint printIndex, uint minSalePriceInWei, address toAddress) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    uint lastSellValue = OfferedForSale[printIndex].lastSellValue;
    OfferedForSale[printIndex] = Offer(true, collectible.drawingId, printIndex, msg.sender, minSalePriceInWei, toAddress, lastSellValue);
    CollectibleOffered(drawingId, printIndex, minSalePriceInWei, toAddress, lastSellValue);
  }

  function acceptBidForCollectible(uint drawingId, uint minPrice, uint printIndex) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    address seller = msg.sender;

    Bid storage bid = Bids[printIndex];
    require(bid.value > 0);  
    require(bid.value >= minPrice);  

    DrawingPrintToAddress[printIndex] = bid.bidder;
    balances[seller]--;
    balances[bid.bidder]++;
    Transfer(seller, bid.bidder, 1);
    uint amount = bid.value;

    Offer storage offer = OfferedForSale[printIndex];
     
     
     
     
     
     
    if(offer.lastSellValue < amount && (amount - offer.lastSellValue) >= 100 ){  
      uint profit = amount - offer.lastSellValue;
       
      pendingWithdrawals[seller] += offer.lastSellValue + (profit*60/100); 
       
       
       
       
      pendingWithdrawals[owner] += (profit*40/100);

    }else{
       
       
      pendingWithdrawals[seller] += amount;
    }
     
    OfferedForSale[printIndex] = Offer(false, collectible.drawingId, printIndex, bid.bidder, 0, 0x0, amount);
    CollectibleBought(collectible.drawingId, printIndex, bid.value, seller, bid.bidder);
    Bids[printIndex] = Bid(false, collectible.drawingId, printIndex, 0x0, 0);

  }

   
  function withdraw() {
    require(isExecutionAllowed);
    uint amount = pendingWithdrawals[msg.sender];
     
     
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

   
  function transfer(address to, uint drawingId, uint printIndex) returns (bool success){
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
     
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    makeCollectibleUnavailableToSale(to, drawingId, printIndex, OfferedForSale[printIndex].lastSellValue);
     
    DrawingPrintToAddress[printIndex] = to;
    balances[msg.sender]--;
    balances[to]++;
    Transfer(msg.sender, to, 1);
    CollectibleTransfer(msg.sender, to, drawingId, printIndex);
     
     
    Bid storage bid = Bids[printIndex];
    if (bid.bidder == to) {
       
      pendingWithdrawals[to] += bid.value;
      Bids[printIndex] = Bid(false, drawingId, printIndex, 0x0, 0);
    }
    return true;
  }

   
  function makeCollectibleUnavailableToSale(address to, uint drawingId, uint printIndex, uint lastSellValue) {
    require(isExecutionAllowed);
    require(drawingIdToCollectibles[drawingId].drawingId != 0);
    Collectible storage collectible = drawingIdToCollectibles[drawingId];
    require(DrawingPrintToAddress[printIndex] == msg.sender);
    require((printIndex < (collectible.totalSupply+collectible.initialPrintIndex)) && (printIndex >= collectible.initialPrintIndex));
    OfferedForSale[printIndex] = Offer(false, collectible.drawingId, printIndex, to, 0, 0x0, lastSellValue);
     
    CollectibleNoLongerForSale(collectible.drawingId, printIndex);
  }

  function newCollectible(uint drawingId, string checkSum, uint256 _totalSupply, uint initialPrice, uint initialPrintIndex, string collectionName, uint authorUId, string scarcity){
     
     
     
    require(owner == msg.sender);
     
    require(drawingIdToCollectibles[drawingId].drawingId == 0);
    drawingIdToCollectibles[drawingId] = Collectible(drawingId, checkSum, _totalSupply, initialPrintIndex, false, initialPrice, initialPrintIndex, collectionName, authorUId, scarcity);
  }

  function flipSwitchTo(bool state){
     
    require(owner == msg.sender);
    isExecutionAllowed = state;
  }

  function mintNewDrawings(uint amount){
    require(owner == msg.sender);
    totalSupply = totalSupply + amount;
    balances[owner] = balances[owner] + amount;

    Transfer(0, owner, amount);
  }

}