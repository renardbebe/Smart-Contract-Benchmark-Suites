 

pragma solidity ^0.4.24;

 
 
 

contract IdentityEvents {
    event IdentityUpdated(address indexed account, bytes32 ipfsHash);
    event IdentityDeleted(address indexed account);

     
    function emitIdentityUpdated(bytes32 ipfsHash) public {
        emit IdentityUpdated(msg.sender, ipfsHash);
    }

    function emitIdentityDeleted() public {
        emit IdentityDeleted(msg.sender);
    }
}