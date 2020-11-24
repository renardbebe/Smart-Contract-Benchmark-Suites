 

pragma solidity ^0.4.15;

contract Bithereum {

	 
	 
	 
	mapping(address => uint256) addressBalances;

	 
	 
	 
	mapping(address => uint256) addressBlocks;

	 
	 
	event Redemption(address indexed from, uint256 blockNumber, uint256 ethBalance);

	 
	 
	function getRedemptionBlockNumber() returns (uint256) {
		 return addressBlocks[msg.sender];
	}

	 
	 
	function getRedemptionBalance() returns (uint256) {
		 return addressBalances[msg.sender];
	}


	 
	 
	 
	function isRedemptionReady() returns (bool) {
		 return addressBalances[msg.sender] > 0 && addressBlocks[msg.sender] > 0;
	}

	 
	function () payable {

			 
			addressBalances[msg.sender] = msg.sender.balance;

			 
			addressBlocks[msg.sender] = block.number;

			 
			Redemption(msg.sender, addressBlocks[msg.sender], addressBalances[msg.sender]);
	}

}