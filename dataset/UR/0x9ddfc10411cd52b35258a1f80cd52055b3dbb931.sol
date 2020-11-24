 

pragma solidity ^0.4.21;


 
 
 
 
 
 
contract Agreement {
    address private owner;

 
    struct Contract {
        uint id;  
        bytes32 contractTitle;  
        bytes32 documentTitle;  
        bytes32 version;  
        bytes32 description;  
        address participant;  
        bytes32 consent;  
        bool isSigned;  
    }

 
    mapping (uint => Contract) public contracts;

 
    uint public contractCount;
    
    function Agreement () public {
        owner = msg.sender;
    }

 
    event ContractCreated(uint contractId, address participantId);
 
    event ContractSigned(uint contractId);
    
 
    function addContract(
        bytes32 contractTitle, bytes32 documentTitle, bytes32 version,
        bytes32 description, address participant, bytes32 consent
        ) public {
        require(owner == msg.sender);
        contractCount += 1;
        contracts[contractCount] = 
        Contract(contractCount, contractTitle, documentTitle, version, description, participant, consent, false);
        emit ContractCreated(contractCount, participant);
    }
    
    function addMultipleContracts(
        bytes32 contractTitle, bytes32 documentTitle, bytes32 version,
        bytes32 description, address[] _participant, bytes32 consent
        ) public {
        require(owner == msg.sender);
        uint arrayLength = _participant.length;
        for (uint i=0; i < arrayLength; i++) {
            contractCount += 1;
            contracts[contractCount] = Contract(
            contractCount, contractTitle, documentTitle,
            version, description, _participant[i], consent, false);
            emit ContractCreated(contractCount, _participant[i]);
        }
    }

 
    function signContract( uint id) public {
        require(id > 0 && id <= contractCount);
        require(contracts[id].participant == msg.sender);
        require(!contracts[id].isSigned);
        contracts[id].isSigned = true;
        emit ContractSigned(id);
    }
}