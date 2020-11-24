 

pragma solidity ^0.4.19;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract B0xPresale is Ownable {
	using SafeMath for uint;

	mapping (address => Investment[]) public received;   
	address[] public investors;                     	 

	address public receiver1;
	address public receiver2;
	address public receiver3;

	struct Investment {
		uint amount;
		uint blockNumber;
		uint blockTimestamp;
	}

	function() 
		public
		payable
	{
		require(msg.value > 0);
		received[msg.sender].push(Investment({
			amount: msg.value,
			blockNumber: block.number,
			blockTimestamp: block.timestamp
		}));
		investors.push(msg.sender);
	}

	function B0xPresale(
		address _receiver1,
		address _receiver2,
		address _receiver3)
		public
	{
		receiver1 = _receiver1;
		receiver2 = _receiver2;
		receiver3 = _receiver3;
	}

	function withdraw()
		public
	{
		require(msg.sender == owner 
			|| msg.sender == receiver1 
			|| msg.sender == receiver2 
			|| msg.sender == receiver3);

		var toSend = this.balance.mul(3).div(7);
		require(receiver1.send(toSend));
		require(receiver2.send(toSend));
		require(receiver3.send(this.balance));  
	}

	function ownerWithdraw(
		address _receiver,
		uint amount
	)
		public
		onlyOwner
	{
		require(_receiver.send(amount));
	}

	function setReceiver1(
		address _receiver
	)
		public
		onlyOwner
	{
		require(_receiver != address(0) && _receiver != receiver1);
		receiver1 = _receiver;
	}

	function setReceiver2(
		address _receiver
	)
		public
		onlyOwner
	{
		require(_receiver != address(0) && _receiver != receiver2);
		receiver2 = _receiver;
	}

	function setReceiver3(
		address _receiver
	)
		public
		onlyOwner
	{
		require(_receiver != address(0) && _receiver != receiver3);
		receiver3 = _receiver;
	}

	function getInvestorsAddresses()
		public
		view
		returns (address[])
	{
		return investors;
	}

	function getBalance()
		public
		view
		returns (uint)
	{
		return this.balance;
	}
}