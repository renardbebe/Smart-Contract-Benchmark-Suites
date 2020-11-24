 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


 
 
contract BiddingBase is Pausable
{
    uint40 public minTime = 60*10;
    uint public minBid = 50 finney - 1 szabo;

    address public operatorAddress;

     
    mapping(address => uint) public pendingReturns;
    uint public totalReturns;

    event Withdraw(address indexed bidder, uint256 value);

     
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        require (amount > 0);

         
         
         

        totalReturns -= amount;
        pendingReturns[msg.sender] -= amount;

        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function destroyContract() public onlyOwner {
 
        selfdestruct(msg.sender);
    }

    function withdrawEthFromBalance() external onlyOwner
    {
        owner.transfer(address(this).balance - totalReturns);
    }

    function setOperator(address _operator) public onlyOwner
    {
        operatorAddress = _operator;
    }

    function setMinBid(uint _minBid) public onlyOwner
    {
        minBid = _minBid;
    }

    function setMinTime(uint40 _minTime) public onlyOwner
    {
        minTime = _minTime;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner);
        _;
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}


 
 
contract BiddingCustom is BiddingBase
{
    struct Auction
    {
        uint128 highestBid;
        address highestBidder;
        uint40 timeEnd;
        uint40 lastBidTime;
        uint40 timeStart;
    }

    Auction[] public auctions;

    event Bid(address indexed bidder, address indexed prevBider, uint256 value, uint256 addedValue, uint40 auction);

    function getAuctions(address bidder) public view returns (
        uint40[5] _timeEnd,
        uint40[5] _lastBidTime,
        uint256[5] _highestBid,
        address[5] _highestBidder,
        uint16[5] _auctionIndex,
        uint256 _pendingReturn)
    {
        _pendingReturn = pendingReturns[bidder];

        uint16 j = 0;
        for (uint16 i = 0; i < auctions.length; i++)
        {
            if (isActive(i))
            {
                _timeEnd[j] = auctions[i].timeEnd;
                _lastBidTime[j] = auctions[i].lastBidTime;
                _highestBid[j] = auctions[i].highestBid;
                _highestBidder[j] = auctions[i].highestBidder;
                _auctionIndex[j] = i;
                j++;
                if (j >= 5)
                {
                    break;
                }
            }
        }
    }

    function finish(uint16 auction) public onlyOperator
    {
        auctions[auction].timeEnd = 1;
    }

    function abort(uint16 auctionIndex) public onlyOperator
    {
        Auction storage auction = auctions[auctionIndex];

        address prevBidder = auction.highestBidder;
        uint256 returnValue = auction.highestBid;

        auction.highestBid = 0;
        auction.highestBidder = address(0);
        auction.timeEnd = 1;

        if (prevBidder != address(0))
        {
            if (!isContract(prevBidder))  
            {
                if (prevBidder.send(returnValue))
                {
                    return;  
                }
            }

            pendingReturns[prevBidder] += returnValue;
            totalReturns += returnValue;
        }
    }

    function addAuction(uint40 _startTime, uint40 _duration, uint128 _startPrice) public onlyOperator
    {
        auctions.push(Auction(_startPrice, address(0), _startTime + _duration, 0, _startTime));
    }

    function isEnded(uint16 auction) public view returns (bool)
    {
        return
            auctions[auction].timeEnd < now &&
            auctions[auction].highestBidder != address(0);
    }

    function isActive(uint16 auctionIndex) public view returns (bool)
    {
        Auction storage auction = auctions[auctionIndex];
        return
            auction.timeStart <= now &&
            (now < auction.timeEnd || auction.timeEnd != 0 && auction.highestBidder == address(0));
    }

    function bid(uint16 auctionIndex, uint256 useFromPendingReturn) public payable whenNotPaused
    {
        Auction storage auction = auctions[auctionIndex];
        address prevBidder = auction.highestBidder;
        uint256 returnValue = auction.highestBid;

        require (useFromPendingReturn <= pendingReturns[msg.sender]);

        uint256 bank = useFromPendingReturn;
        pendingReturns[msg.sender] -= bank;
        totalReturns -= bank;

        uint256 currentBid = bank + msg.value;

        require(currentBid >= auction.highestBid + minBid ||
                currentBid >= auction.highestBid && prevBidder == address(0));
        require(isActive(auctionIndex));

        auction.highestBid = uint128(currentBid);
        auction.highestBidder = msg.sender;
        auction.lastBidTime = uint40(now);

        for (uint16 i = 0; i < auctions.length; i++)
        {
            if (isActive(i) &&  auctions[i].timeEnd < now + minTime)
            {
                auctions[i].timeEnd = uint40(now) + minTime;
            }
        }

        emit Bid(msg.sender, prevBidder, currentBid, currentBid - returnValue, auctionIndex);

        if (prevBidder != address(0))
        {
            if (!isContract(prevBidder))  
            {
                if (prevBidder.send(returnValue))
                {
                    return;  
                }
            }

            pendingReturns[prevBidder] += returnValue;
            totalReturns += returnValue;
        }
    }
}