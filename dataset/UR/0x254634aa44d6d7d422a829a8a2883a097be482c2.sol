 

pragma solidity >=0.4.22 <0.6.0;

contract MyBank {
    uint256 balance;
    address owner;

    constructor () public {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        balance = msg.value;
    }
    
    function withdraw(uint256 valueToRetrieve) public {
        require(msg.sender == owner);
        msg.sender.transfer(valueToRetrieve);
    }
}