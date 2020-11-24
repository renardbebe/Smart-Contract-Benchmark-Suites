 

pragma solidity ^0.4.24;

 
contract Owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != 0x0);
		owner = newOwner;
	}
}

 
contract SafeMath {
	function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);

		return c;
	}
}

contract CURESSale is Owned, SafeMath {
	uint256 public maxGoal = 175000 * 1 ether;			 
	uint256 public minTransfer = 5 * 1 ether;			 
	uint256 public amountRaised = 0;					 
	mapping(address => uint256) public payments;		 
	bool public isFinalized = false;					 

	 
	event PaymentMade(address indexed _from, uint256 _ammount);

	 
	function() payable public {
		buyTokens();
	}

	function buyTokens() payable public returns (bool success) {
		 
		require(!isFinalized);

		uint256 amount = msg.value;

		 
		uint256 collectedEth = safeAdd(amountRaised, amount);
		require(collectedEth <= maxGoal);

		require(amount >= minTransfer);

		payments[msg.sender] = safeAdd(payments[msg.sender], amount);
		amountRaised = safeAdd(amountRaised, amount);

		owner.transfer(amount);

		emit PaymentMade(msg.sender, amount);
		return true;
	}

	 
	 
	function withdraw(uint256 _value) public onlyOwner {
		require(isFinalized);
		require(_value > 0);

		msg.sender.transfer(_value);
	}

	function changeMinTransfer(uint256 min) external onlyOwner {
		require(!isFinalized);

		require(min > 0);

		minTransfer = min;
	}

	 
	function finalize() external onlyOwner {
		require(!isFinalized);

		 
		isFinalized = true;
	}
}