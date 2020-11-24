 

pragma solidity ^0.4.18;

 
contract Ownable {
    modifier onlyOwner() {
        checkOwner();
        _;
    }

    function checkOwner() internal;
}

 
contract OwnableImpl is Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function OwnableImpl() public {
        owner = msg.sender;
    }

     
    function checkOwner() internal {
        require(msg.sender == owner);
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract EtherReceiver {
	function receiveWithData(bytes _data) payable public;
}

contract Forwarder is OwnableImpl {
	function withdraw(address to, uint256 value) onlyOwner public {
		to.transfer(value);
	}

	function forward(address to, bytes data) payable public {
		uint256 commission = msg.value / 100;
		EtherReceiver(to).receiveWithData.value(msg.value - commission)(data);
	}
}