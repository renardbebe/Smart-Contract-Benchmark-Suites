 

pragma solidity 0.5.5;

contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool) {}
}

contract Auction {

  uint256 public REWARD_PER_WIN = 625000000;
  uint256 public CREATOR_REWARD = 6250000;
  address public CREATOR_ADDRESS;
  address public GTT_ADDRESS;

  address public currWinner;    
  uint256 public currHighest;   
  uint256 public lastHighest;   
  uint256 public lastAuctionStart;

  constructor() public {
    CREATOR_ADDRESS = msg.sender;
    lastAuctionStart = block.number;
    currWinner = address(this);
  }

   
  function setTokenAddress(address _gttAddress) public {
    if (GTT_ADDRESS == address(0)) {
      GTT_ADDRESS = _gttAddress;
    }
  }

  function play() public payable {
    uint256 currentBlock = block.number;

     
    if (lastAuctionStart < currentBlock - 50) {
      payOut();

       
      lastAuctionStart = currentBlock;
      currWinner = address(this);
      lastHighest = currHighest;
      currHighest = 0;
    }

     
    if (msg.sender.balance > currHighest) {
      currHighest = msg.sender.balance;
      currWinner = msg.sender;
    }
  }

  function payOut() internal {
    IERC20(GTT_ADDRESS).transfer(currWinner, REWARD_PER_WIN);
    IERC20(GTT_ADDRESS).transfer(CREATOR_ADDRESS, CREATOR_REWARD);
  }
}