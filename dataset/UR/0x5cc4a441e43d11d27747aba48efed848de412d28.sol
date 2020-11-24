 

pragma solidity ^0.4.13;

contract Prover {
    
    struct Entry {
        bool exists;
        uint256 time;
        uint256 value;
    }
    
     
    mapping (address => mapping (bytes32 => Entry)) public ledger;
    
     
    function addEntry(bytes32 dataHash) payable {
        _addEntry(dataHash);
    }
    function addEntry(string dataString) payable {
        _addEntry(sha3(dataString));
    }
    function deleteEntry(bytes32 dataHash) {
        _deleteEntry(dataHash);
    }
    function deleteEntry(string dataString) {
        _deleteEntry(sha3(dataString));
    }
    
     
    function _addEntry(bytes32 dataHash) internal {
         
        assert(!ledger[msg.sender][dataHash].exists);
         
        ledger[msg.sender][dataHash].exists = true;
        ledger[msg.sender][dataHash].time = now;
        ledger[msg.sender][dataHash].value = msg.value;
    }
    function _deleteEntry(bytes32 dataHash) internal {
         
        assert(ledger[msg.sender][dataHash].exists);
        uint256 rebate = ledger[msg.sender][dataHash].value;
        delete ledger[msg.sender][dataHash];
        if (rebate > 0) {
            msg.sender.transfer(rebate);
        }
    }
    
     
    function proveIt(address claimant, bytes32 dataHash) constant
            returns (bool proved, uint256 time, uint256 value) {
        return status(claimant, dataHash);
    }
    function proveIt(address claimant, string dataString) constant
            returns (bool proved, uint256 time, uint256 value) {
         
        return status(claimant, sha3(dataString));
    }
    function proveIt(bytes32 dataHash) constant
            returns (bool proved, uint256 time, uint256 value) {
        return status(msg.sender, dataHash);
    }
    function proveIt(string dataString) constant
            returns (bool proved, uint256 time, uint256 value) {
         
        return status(msg.sender, sha3(dataString));
    }
    
     
    function status(address claimant, bytes32 dataHash) internal constant
            returns (bool, uint256, uint256) {
         
        if (ledger[claimant][dataHash].exists) {
            return (true, ledger[claimant][dataHash].time,
                    ledger[claimant][dataHash].value);
        }
        else {
            return (false, 0, 0);
        }
    }

     
    function () {
        revert();
    }
    
}