 

pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor() public {
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

contract Exchange {
	function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) public payable returns(uint256);
}

contract cUSDCGateway is Ownable {
	Exchange cUSDCEx = Exchange(0xB791c10824296881f91BDbC16367BbD9743fd99b);

	function () public payable {
		etherTocUSDC(msg.sender);
	}

	function etherTocUSDC(address to) public payable returns(uint256) {
        return cUSDCEx.ethToTokenTransferInput.value(msg.value * 996 / 1000)(1, now, to);
	}

	function makeprofit() public onlyOwner {
		owner.transfer(address(this).balance);
	}

}