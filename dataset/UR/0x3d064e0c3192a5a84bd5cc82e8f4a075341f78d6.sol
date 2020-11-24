 

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
    uint40 public timeEnd;
    uint40 public lastBidTime;
    uint256 public highestBid;
    address public highestBidder;

    address public operatorAddress;

    struct Purchase
    {
        address winner;
        uint256 bid;
    }
    Purchase[] public purchases;

     
    mapping(address => uint) public pendingReturns;
    uint public totalReturns;

    function getBiddingInfo(address bidder) public view returns (
        uint40 _timeEnd,
        uint40 _lastBidTime,
        uint256 _highestBid,
        address _highestBidder,
        bool _isEnded,
        uint256 _pendingReturn)
    {
        _timeEnd = timeEnd;
        _lastBidTime = lastBidTime;
        _highestBid = highestBid;
        _highestBidder = highestBidder;
        _isEnded = isEnded();
        _pendingReturn = pendingReturns[bidder];
    }

     
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        require (amount > 0);
        
         
         
         

        totalReturns -= amount;
        pendingReturns[msg.sender] -= amount;

        msg.sender.transfer(amount);
    }

    function finish() public onlyOperator
    {
        if (highestBidder != address(0))
        {
            purchases.push(Purchase(highestBidder, highestBid));  
            highestBidder = address(0);
        }
        timeEnd = 0;
    }

    function setBidding(uint40 _duration, uint256 _startPrice) public onlyOperator
    {
        finish();

        timeEnd = _duration + uint40(now);
        highestBid = _startPrice;
    }

    function isEnded() public view returns (bool)
    {
        return timeEnd < now;
    }

    function bid() public payable whenNotPaused
    {
        if (highestBidder != address(0))
        {
            pendingReturns[highestBidder] += highestBid;
            totalReturns += highestBid;
        }

        uint256 bank = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;
        totalReturns -= bank;

        uint256 currentBid = bank + msg.value;

        require(currentBid > highestBid);
        require(!isEnded());


        highestBid = currentBid;
        highestBidder = msg.sender;
        lastBidTime = uint40(now);
    }

    function purchasesCount() public view returns (uint256)
    {
        return purchases.length;
    }

    function destroyContract() public onlyOwner {
        require(isEnded());
        require(address(this).balance == 0);
        selfdestruct(msg.sender);
    }

    function() external payable {
        bid();
    }

    function withdrawEthFromBalance() external onlyOwner
    {
        require(isEnded());
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