 

pragma solidity ^0.4.21;







 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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


 
 
contract Bidding is Pausable
{
    struct Auction
    {
        uint128 highestBid;
        address highestBidder;
        uint40 timeEnd;
        uint40 lastBidTime;
        uint40 timeStart;
    }

    uint40 public minTime = 60*10;
    uint public minBid = 50 finney;

    address public operatorAddress;

    Auction[] public auctions;

     
    mapping(address => uint) public pendingReturns;
    uint public totalReturns;

    event Bid(address indexed bidder, address indexed prevBider, uint256 value, uint256 addedValue, uint40 auction);
    event Withdraw(address indexed bidder, uint256 value);

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

     
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        require (amount > 0);

         
         
         

        totalReturns -= amount;
        pendingReturns[msg.sender] -= amount;

        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function finish(uint16 auction) public onlyOperator
    {
        auctions[auction].timeEnd = 0;
    }

    function addAuction(uint40 _startTime, uint40 _duration, uint128 _startPrice) public onlyOperator
    {
        auctions.push(Auction(_startPrice, address(0), _startTime + _duration, 0, _startTime));
    }

    function isEnded(uint16 auction) public view returns (bool)
    {
        return auctions[auction].timeEnd < now;
    }

    function isActive(uint16 auction) public view returns (bool)
    {
        return auctions[auction].timeStart <= now && now <= auctions[auction].timeEnd;
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