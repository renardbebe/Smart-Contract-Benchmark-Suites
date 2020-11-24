 

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
        uint256 highestBid;
        address highestBidder;
        uint40 timeEnd;
        uint40 lastBidTime;
    }

    address public operatorAddress;

    struct Purchase
    {
        uint256 bid;
        address winner;
        uint16 auction;
    }
    Purchase[] public purchases;
    Auction[] public auctions;

     
    mapping(address => uint) public pendingReturns;
    uint public totalReturns;

    function getBiddingInfo(uint16 auction, address bidder) public view returns (
        uint40 _timeEnd,
        uint40 _lastBidTime,
        uint256 _highestBid,
        address _highestBidder,
        bool _isEnded,
        uint256 _pendingReturn)
    {
        _timeEnd = auctions[auction].timeEnd;
        _lastBidTime = auctions[auction].lastBidTime;
        _highestBid = auctions[auction].highestBid;
        _highestBidder = auctions[auction].highestBidder;
        _isEnded = isEnded(auction);
        _pendingReturn = pendingReturns[bidder];
    }

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
            if (!isEnded(i))
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
    }

    function finish(uint16 auction) public onlyOperator
    {
        if (auctions[auction].highestBidder != address(0))
        {
            purchases.push(Purchase(auctions[auction].highestBid, auctions[auction].highestBidder, auction));  
        }
        auctions[auction].timeEnd = 0;
    }

    function addAuction(uint40 _duration, uint256 _startPrice) public onlyOperator
    {
        auctions.push(Auction(_startPrice, address(0), _duration + uint40(now), 0));
    }

    function isEnded(uint16 auction) public view returns (bool)
    {
        return auctions[auction].timeEnd < now;
    }

    function bid(uint16 auction, uint256 useFromPendingReturn) public payable whenNotPaused
    {
        if (auctions[auction].highestBidder != address(0))
        {
            pendingReturns[auctions[auction].highestBidder] += auctions[auction].highestBid;
            totalReturns += auctions[auction].highestBid;
        }

        require (useFromPendingReturn <= pendingReturns[msg.sender]);

        uint256 bank = useFromPendingReturn;
        pendingReturns[msg.sender] -= bank;
        totalReturns -= bank;

        uint256 currentBid = bank + msg.value;

        require(currentBid > auctions[auction].highestBid ||
         currentBid == auctions[auction].highestBid && auctions[auction].highestBidder == address(0));
        require(!isEnded(auction));

        auctions[auction].highestBid = currentBid;
        auctions[auction].highestBidder = msg.sender;
        auctions[auction].lastBidTime = uint40(now);
    }

    function purchasesCount() public view returns (uint256)
    {
        return purchases.length;
    }

    function destroyContract() public onlyOwner {
        require(address(this).balance == 0);
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

    modifier onlyOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner);
        _;
    }
}