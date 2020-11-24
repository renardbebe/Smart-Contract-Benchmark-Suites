 

pragma solidity ^0.4.23;

 
contract Datatrust {

     
    event NewAnchor(bytes32 merkleRoot);

     
    function saveNewAnchor(bytes32 _merkleRoot) public {
        emit NewAnchor(_merkleRoot);
    }
}