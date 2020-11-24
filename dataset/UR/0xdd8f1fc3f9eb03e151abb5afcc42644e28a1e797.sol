 

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

 
 
 
 
 
 
 

contract dappVolumeAd {

 
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
		investmentMin = 1000000000000000;
		adPriceHour = 5000000000000000;
		adPriceHalfDay = 50000000000000000;
		adPriceDay = 100000000000000000;
		adPriceWeek = 500000000000000000;
		adPriceMultiple = 1;
		contractOwner = msg.sender;
		theInvestor = contractOwner;
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
		require(block.timestamp > purchaseTimestamp + purchaseSeconds);
		require(id > 0);

		 
		if (msg.value >= adPriceMultiple.mul(adPriceWeek)) {
			purchaseSeconds = 604800;  
		} else if (msg.value >= adPriceMultiple.mul(adPriceDay)) {
			purchaseSeconds = 86400;  
		} else if (msg.value >= adPriceMultiple.mul(adPriceHalfDay)) {
			purchaseSeconds = 43200;  
		} else {
			purchaseSeconds = 3600;  
		}

		 
		purchaseTimestamp = block.timestamp;
		 
		lastOwner.transfer(msg.value.div(2));
		 
		theInvestor.transfer(msg.value.div(10));
		 
		lastOwner = msg.sender;
		 
		dappId = id;
	}

	 
	function updateInvestor() public payable {
		require(msg.value >= investmentMin);
		theInvestor.transfer(msg.value.div(100).mul(60));  
		theInvestor = msg.sender;  
		investmentMin = investmentMin.mul(2);  
	}

	 
	function getPurchaseTimestampEnds() public view returns (uint _getPurchaseTimestampAdEnds) {
		return purchaseTimestamp.add(purchaseSeconds);
	}

	 
	function getBalance() public view returns(uint256){
		return address(this).balance;
	}

}