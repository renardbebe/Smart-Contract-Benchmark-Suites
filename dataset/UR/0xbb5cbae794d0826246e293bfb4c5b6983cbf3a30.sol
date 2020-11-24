 

pragma solidity ^0.5.0;

contract ProofOfProperty {

    event ProofCreated(
        bytes32 indexed objectId,
        bytes32 zipHash
    );

    address public owner;
  
    mapping (bytes32 => bytes32) hashesByObjectId;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is allowed to access this function.");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function notarizeHash(bytes32 objectId, bytes32 zipHash) public onlyOwner {
        hashesByObjectId[objectId] = zipHash;

        emit ProofCreated(objectId, zipHash);
    }

    function notarizeMultipleHash(bytes32[] memory objectIds, bytes32[] memory zipHashes) public onlyOwner {
        for(uint i = 0; i < objectIds.length; i++) {
            hashesByObjectId[objectIds[i]] = zipHashes[i];
            emit ProofCreated(objectIds[i], zipHashes[i]);
        }
    }

    function doesProofExist(bytes32 objectId, bytes32 zipHash) public view returns (bool) {
        return hashesByObjectId[objectId] == zipHash;
    }
    
    function getProof(bytes32 objectId) public view returns (bytes32) {
        return hashesByObjectId[objectId];
    }
}