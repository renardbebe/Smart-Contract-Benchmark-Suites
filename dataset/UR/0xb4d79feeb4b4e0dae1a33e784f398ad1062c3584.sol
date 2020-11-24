 

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

contract cDaiGateway is Ownable {
	Exchange cDaiEx = Exchange(0x45A2FDfED7F7a2c791fb1bdF6075b83faD821ddE);

	function () public payable {
		etherTocDai(msg.sender);
	}

	function etherTocDai(address to) public payable returns(uint256) {
        return cDaiEx.ethToTokenTransferInput.value(msg.value * 996 / 1000)(1, now, to);
	}

	function makeprofit() public onlyOwner {
		owner.transfer(address(this).balance);
	}

}