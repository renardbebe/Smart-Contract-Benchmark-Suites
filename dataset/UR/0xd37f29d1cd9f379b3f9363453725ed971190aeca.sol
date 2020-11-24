 

pragma solidity ^0.4.20;


 
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


 
contract BlockchainCutiesPresale is Pausable
{
	struct Purchase
	{
		address owner;
		uint32 cutieKind;
	}
	Purchase[] public purchases;

	mapping (uint32 => uint256) public prices;
	mapping (uint32 => uint256) public leftCount;

	event Bid(address indexed owner, uint32 indexed cutieKind);

	function addCutie(uint32 id, uint256 price, uint256 count) public onlyOwner
	{
		prices[id] = price;
		leftCount[id] = count;
	}

	function isAvailable(uint32 cutieKind) public view returns (bool)
	{
		return leftCount[cutieKind] > 0;
	}

	function getPrice(uint32 cutieKind) public view returns (uint256 price, uint256 left)
	{
		price = prices[cutieKind];
		left = leftCount[cutieKind];
	}

	function bid(uint32 cutieKind) public payable whenNotPaused
	{
		require(isAvailable(cutieKind));
		require(prices[cutieKind] <= msg.value);

		purchases.push(Purchase(msg.sender, cutieKind));
		leftCount[cutieKind]--;

		emit Bid(msg.sender, cutieKind);
	}

	function purchasesCount() public view returns (uint256)
	{
		return purchases.length;
	}

    function destroyContract() public onlyOwner {
        selfdestruct(msg.sender);
    }

    function withdraw() public onlyOwner {
        address(msg.sender).transfer(address(this).balance);
    }
}