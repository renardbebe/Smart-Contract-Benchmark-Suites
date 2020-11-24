 

pragma solidity ^0.4.18;

contract EtherAuction {

   
  address public auctioneer;
  uint public auctionedEth = 0;

  uint public highestBid = 0;
  uint public secondHighestBid = 0;

  address public highestBidder;
  address public secondHighestBidder;

  uint public latestBidTime = 0;
  uint public auctionEndTime;

  mapping (address => uint) public balances;

  bool public auctionStarted = false;
  bool public auctionFinalized = false;

  event E_AuctionStarted(address _auctioneer, uint _auctionStart, uint _auctionEnd);
  event E_Bid(address _highestBidder, uint _highestBid);
  event E_AuctionFinished(address _highestBidder,uint _highestBid,address _secondHighestBidder,uint _secondHighestBid,uint _auctionEndTime);

  function EtherAuction(){
    auctioneer = msg.sender;
  }

   
  function startAuction() public payable{
    require(!auctionStarted);
    require(msg.sender == auctioneer);
    require(msg.value == (1 * 10 ** 18));
    
    auctionedEth = msg.value;
    auctionStarted = true;
    auctionEndTime = now + (3600 * 24 * 7);  

    E_AuctionStarted(msg.sender,now, auctionEndTime);
  }

   
  function bid() public payable {
    require(auctionStarted);
    require(now < auctionEndTime);
    require(msg.sender != auctioneer);
    require(highestBidder != msg.sender);  

    address _newBidder = msg.sender;

    uint previousBid = balances[_newBidder];
    uint _newBid = msg.value + previousBid;

    require (_newBid  == highestBid + (5 * 10 ** 16));  

     
    secondHighestBid = highestBid;
    secondHighestBidder = highestBidder;

    highestBid = _newBid;
    highestBidder = _newBidder;

    latestBidTime = now;
     
    balances[_newBidder] = _newBid;

     
    if(auctionEndTime - now < 3600)
      auctionEndTime += 3600;  

    E_Bid(highestBidder, highestBid);

  }
   
  function finalizeAuction() public {
    require (now > auctionEndTime);
    require (!auctionFinalized);
    auctionFinalized = true;

    if(highestBidder == address(0)){
       
      balances[auctioneer] = auctionedEth;
    }else{
       
      balances[secondHighestBidder] -= secondHighestBid;
      balances[auctioneer] += secondHighestBid;

       
      balances[highestBidder] -= highestBid;
      balances[auctioneer] += highestBid;

       
      balances[highestBidder] += auctionedEth;
      auctionedEth = 0;
    }

    E_AuctionFinished(highestBidder,highestBid,secondHighestBidder,secondHighestBid,auctionEndTime);

  }

   
   
   
   
   
  function withdrawBalance() public{
    require (auctionFinalized);

    uint ethToWithdraw = balances[msg.sender];
    if(ethToWithdraw > 0){
      balances[msg.sender] = 0;
      msg.sender.transfer(ethToWithdraw);
    }

  }

   
  function timeRemaining() public view returns (uint){
      require (auctionEndTime > now);
      return auctionEndTime - now;
  }

  function myLatestBid() public view returns (uint){
    return balances[msg.sender];
  }

}