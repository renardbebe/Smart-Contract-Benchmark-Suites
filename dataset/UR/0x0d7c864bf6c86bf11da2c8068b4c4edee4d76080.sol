 

pragma solidity ^0.4.24;

 
 
 
 
 
 

 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		 
		return a / b;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

 
 
 
 
 
 
 

contract DappVolumeAd {

	 
	using SafeMath for uint256;

	 
	uint256 public dappId;
	uint256 public purchaseTimestamp;
	uint256 public purchaseSeconds;
	uint256 public investmentMin;
	uint256 public adPriceHour;
	uint256 public adPriceHalfDay;
	uint256 public adPriceDay;
	uint256 public adPriceWeek;
	uint256 public adPriceMultiple;
	address public contractOwner;
	address public lastOwner;
	address public theInvestor;

	 
	modifier onlyContractOwner {
		require(msg.sender == contractOwner);
		_;
	}

	 
	constructor() public {
		investmentMin = 4096000000000000000;
		adPriceHour = 5000000000000000;
		adPriceHalfDay = 50000000000000000;
		adPriceDay = 100000000000000000;
		adPriceWeek = 500000000000000000;
		adPriceMultiple = 2;
		contractOwner = msg.sender;
		theInvestor = 0x1C26d2dFDACe03F0F6D0AaCa233D00728b9e58da;
		lastOwner = contractOwner;
	}

	 
	function withdraw() public onlyContractOwner {
		contractOwner.transfer(address(this).balance);
	}

	 
	function setAdPriceMultiple(uint256 amount) public onlyContractOwner {
		adPriceMultiple = amount;
	}

	 
	function updateAd(uint256 id) public payable {
		 
		require(msg.value >= adPriceMultiple.mul(adPriceHour));
		require(block.timestamp > purchaseTimestamp.add(purchaseSeconds));
		require(id > 0);

		 
		theInvestor.send(msg.value.div(10));
		 
		lastOwner.send(msg.value.div(2));

		 
		if (msg.value >= adPriceMultiple.mul(adPriceWeek)) {
			purchaseSeconds = 604800;  
		} else if (msg.value >= adPriceMultiple.mul(adPriceDay)) {
			purchaseSeconds = 86400;  
		} else if (msg.value >= adPriceMultiple.mul(adPriceHalfDay)) {
			purchaseSeconds = 43200;  
		} else {
			purchaseSeconds = 3600;  
		}

		 
		dappId = id;
		 
		purchaseTimestamp = block.timestamp;
		 
		lastOwner = msg.sender;
	}

	 
	function updateInvestor() public payable {
		require(msg.value >= investmentMin);
		 
		theInvestor.send(msg.value.div(100).mul(60));
		 
		investmentMin = investmentMin.mul(2);
		 
		theInvestor = msg.sender;
	}

	 
	function getPurchaseTimestampEnds() public view returns (uint _getPurchaseTimestampAdEnds) {
		return purchaseTimestamp.add(purchaseSeconds);
	}

	 
	function getBalance() public view returns(uint256){
		return address(this).balance;
	}

}