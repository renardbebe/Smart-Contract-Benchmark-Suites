 

pragma solidity ^0.5.9;


contract StoredBatches {

    struct Batch {
        string ipfsHash;
    }

    event Update(string ipfsHash);

    address protocol;

    constructor() public {
        protocol = msg.sender;
    }

    modifier onlyProtocol() {
        if (msg.sender == protocol) {
            _;
        }
    }

    Batch[] public batches;


     
    function registerBatch(string memory _ipfsHash) public onlyProtocol {
        batches.push(Batch(_ipfsHash));
        emit Update(_ipfsHash);
    }
}