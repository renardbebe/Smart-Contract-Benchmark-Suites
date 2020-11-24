 

pragma solidity ^0.5.10;

contract Storage {
    event Data(bytes32 indexed id, address from, uint timestamp, string data);
    event DataIndexedByFromAddr(address indexed from, bytes32 indexed id, uint timestamp, string data);
    
    function store(string memory data) public {
        bytes32 id = keccak256(abi.encodePacked(data));
        emit Data(id, msg.sender, now, data);
        emit DataIndexedByFromAddr(msg.sender, id, now, data);
    }
}