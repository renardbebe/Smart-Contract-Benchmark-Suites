 

pragma solidity ^0.4.25;

 
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

contract CoooinsCoinAd {

	using SafeMath for uint256;

	string public adMessage;
	string public adUrl;
	uint256 public purchaseTimestamp;
	uint256 public purchaseSeconds;
	uint256 public adPriceWeek;
	uint256 public adPriceMonth;
	address public contractOwner;

	event newAd(address indexed buyer, uint256 amount, string adMessage, string adUrl, uint256 purchaseSeconds, uint256 purchaseTimestamp);

	modifier onlyContractOwner {
		require(msg.sender == contractOwner);
		_;
	}

	constructor() public {
		adPriceWeek = 50000000000000000;
		adPriceMonth = 150000000000000000;
		contractOwner = 0x2E26a4ac59094DA46a0D8d65D90A7F7B51E5E69A;
	}

	function withdraw() public onlyContractOwner {
		contractOwner.transfer(address(this).balance);
	}

	function setAdPriceWeek(uint256 amount) public onlyContractOwner {
		adPriceWeek = amount;
	}

	function setAdPriceMonth(uint256 amount) public onlyContractOwner {
		adPriceMonth = amount;
	}

	function updateAd(string message, string url) public payable {
		 
		require(msg.value >= adPriceWeek);
		require(block.timestamp > purchaseTimestamp.add(purchaseSeconds));

		 
		if (msg.value >= adPriceMonth) {
			purchaseSeconds = 2592000;  
		} else {
			purchaseSeconds = 604800;  
		}

		adMessage = message;
		adUrl = url;

		purchaseTimestamp = block.timestamp;

		emit newAd(msg.sender, msg.value, adMessage, adUrl, purchaseSeconds, purchaseTimestamp);
	}

	function getPurchaseTimestampEnds() public view returns (uint _getPurchaseTimestampAdEnds) {
		return purchaseTimestamp.add(purchaseSeconds);
	}

	function getBalance() public view returns(uint256){
		return address(this).balance;
	}

}