 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


contract RCPreorder is Pausable {
    uint8 constant WEEK1_PERCENT_AMOUNT = 30;
    uint8 constant WEEK2_PERCENT_AMOUNT = 60;
    uint8 constant WEEK3_PERCENT_AMOUNT = 80;
    uint32 constant WEEK1_DURATION = 1 weeks;
    uint32 constant WEEK2_DURATION = 2 weeks;
    uint32 constant WEEK3_DURATION = 3 weeks;
    uint32 constant SECONDS_PER_BLOCK = 15;

    event PackPurchased(address indexed user, uint8 indexed packId, uint256 price);

    struct Purchase {
        uint8 packId;
        address user;
        uint64 commit;
    }

    Purchase[] public purchases;

    mapping (uint8 => uint256) public prices;
    mapping (uint8 => uint256) public leftCount;

    uint256 public startBlock;

    constructor() public {
        paused = true;

         
        owner = msg.sender;
    }

    function purchase(uint8 _packId) external payable whenNotPaused {
        require(_packIsAvialable(_packId));
        require(_isRunning());

        uint256 currentPrice = _computeCurrentPrice(prices[_packId]);
         
        require(msg.value >= currentPrice);

        Purchase memory p = Purchase({
            user: msg.sender,
            packId: _packId,
            commit: uint64(block.number)
        });

        purchases.push(p);
        leftCount[_packId]--;

        emit PackPurchased(msg.sender, _packId, currentPrice);
    }

    function getPackPrice(uint8 _packId) external view returns (uint256) {
        return _computeCurrentPrice(prices[_packId]);
    }

    function getPurchaseCount() external view returns (uint) {
        return purchases.length;
    }

    function run() external onlyOwner {
        startBlock = block.number;
        unpause();
    }

    function addPack(uint8 _id, uint256 _price, uint256 _count) external onlyOwner {
        prices[_id] = _price;
        leftCount[_id] = _count;
    }

    function withdraw() external onlyOwner {
        address(msg.sender).transfer(address(this).balance);
    }

    function unpause() public onlyOwner whenPaused {
        require(startBlock > 0);

         
        super.unpause();
    }

    function _isRunning() internal view returns (bool) {
        uint diff = block.number - startBlock;
        return startBlock > 0 && diff < uint(WEEK3_DURATION / SECONDS_PER_BLOCK);
    }

    function _packIsAvialable(uint8 _id) internal view returns (bool) {
        return leftCount[_id] > 0;
    }

    function _computeCurrentPrice(
        uint256 _basePrice
    )
        internal
        view
        returns (uint256)
    {
        uint diff = block.number - startBlock;

        if (diff < uint(WEEK1_DURATION / SECONDS_PER_BLOCK)) {
             
            return _basePrice * WEEK1_PERCENT_AMOUNT / 100;
        } else if (diff < uint(WEEK2_DURATION / SECONDS_PER_BLOCK)) {
             
            return _basePrice * WEEK2_PERCENT_AMOUNT / 100;
        } else if (diff < uint(WEEK3_DURATION / SECONDS_PER_BLOCK)) {
             
            return _basePrice * WEEK3_PERCENT_AMOUNT / 100;
        }

        return _basePrice;
    }
}