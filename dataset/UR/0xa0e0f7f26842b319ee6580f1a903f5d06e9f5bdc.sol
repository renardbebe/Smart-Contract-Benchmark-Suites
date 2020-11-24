 

pragma solidity ^0.5.10;

contract Storage {
    event Data(address indexed from, string data);
    
    function store(string memory data) public {
        emit Data(msg.sender, data);
    }
}