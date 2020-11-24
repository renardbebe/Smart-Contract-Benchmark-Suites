 

pragma solidity ^0.5.1;

contract CommunityChest {
    
    address owner;
    
    event Deposit(uint256 value);
    event Transfer(address to, uint256 value);
    
    constructor () public {
        owner = msg.sender;
    }
    
    function send(address payable to, uint256 value) public onlyOwner {
        to.transfer(value);
        emit Transfer(to, value);
    }

    function deposit() payable public {
        emit Deposit(msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}