 

pragma solidity 0.5.5;

contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool) {}
}

contract NoTx {

   
  uint256 public REWARD_PER_WIN = 125000000;
  uint256 public CREATOR_REWARD = 1250000;
  address public CREATOR_ADDRESS;
  address public GTT_ADDRESS;

   
  uint256 public lastPayout;
  address public currWinner;

  mapping (uint256 => bool) public didBlockHaveTx;   

  constructor() public {
    CREATOR_ADDRESS = msg.sender;
    currWinner = address(this);
  }

   
  function setTokenAddress(address _gttAddress) public {
    if (GTT_ADDRESS == address(0)) {
      GTT_ADDRESS = _gttAddress;
    }
  }

  function play() public {
    uint256 currentBlock = block.number;
    uint256 lastBlock = currentBlock - 1;

     
    if (!didBlockHaveTx[lastBlock]) {
      payOut(currWinner);

      lastPayout = currentBlock;
    }

     
    if (didBlockHaveTx[currentBlock] == false) {
      didBlockHaveTx[currentBlock] = true;
      currWinner = msg.sender;
    }
  }

  function payOut(address winner) internal {
    IERC20(GTT_ADDRESS).transfer(winner, REWARD_PER_WIN);
    IERC20(GTT_ADDRESS).transfer(CREATOR_ADDRESS, CREATOR_REWARD);
  }
}