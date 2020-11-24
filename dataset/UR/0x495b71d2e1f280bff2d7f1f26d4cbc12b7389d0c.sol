 

pragma solidity ^0.4.24;

 
 
 
 
 
 

 
contract dappVolumeHearts {
	 
	mapping(uint256 => uint256) public totals;
	 
	function getTotalHeartsByDappId(uint256 dapp_id) public view returns(uint256) {
		return totals[dapp_id];
	}
}

 
 
 

contract DappVolumeHearts {

	dappVolumeHearts firstContract;

	using SafeMath for uint256;

	 
	address public contractOwner;
	 
	address public lastAddress;
	 
	address constant public firstContractAddress = 0x6ACD16200a2a046bf207D1B263202ec1A75a7D51;
	 
	mapping(uint256 => uint256) public totals;

	 
	modifier onlyContractOwner {
		require(msg.sender == contractOwner);
		_;
	}

	 
	constructor() public {
		contractOwner = msg.sender;
		lastAddress = msg.sender;
		firstContract = dappVolumeHearts(firstContractAddress);
	}


	 
	function withdraw() public onlyContractOwner {
		contractOwner.transfer(address(this).balance);
	}

	 
	function update(uint256 dapp_id) public payable {
		require(msg.value >= 2000000000000000);
		require(dapp_id > 0);
		totals[dapp_id] = totals[dapp_id].add(msg.value);
		 
		lastAddress.send(msg.value.div(2));
		lastAddress = msg.sender;
	}

	 
	function getTotalHeartsByDappId(uint256 dapp_id) public view returns(uint256) {
		return totals[dapp_id].add(firstContract.getTotalHeartsByDappId(dapp_id));
	}

	 
	function getBalance() public view returns(uint256){
		return address(this).balance;
	}

}

 
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