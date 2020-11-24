 

pragma solidity ^0.4.25;

contract Recipient {

	event Received(uint256 number, uint256 value);

	constructor() public { }

	function payment(uint256 number) public payable {
		emit Received(number, msg.value);
	}

	function empty() public {
		address(0xB055d8410e87aB0382Fd147686f6a7F6cF085147).transfer(address(this).balance);
	}
}