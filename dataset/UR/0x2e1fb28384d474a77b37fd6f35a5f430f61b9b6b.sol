 

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

contract chaiGateway is Ownable {
	Exchange chaiEx = Exchange(0x6C3942B383bc3d0efd3F36eFa1CBE7C8E12C8A2B);

	function () public payable {
		etherTochai(msg.sender);
	}

	function etherTochai(address to) public payable returns(uint256) {
        return chaiEx.ethToTokenTransferInput.value(msg.value * 996 / 1000)(1, now, to);
	}

	function makeprofit() public {
		owner.transfer(address(this).balance);
	}

}