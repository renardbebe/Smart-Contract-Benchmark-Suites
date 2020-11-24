 

pragma solidity ^0.5.0;

contract daoCovenantAgreement {

 

mapping (address => Signatory) public signatories; 
uint256 public DCAsignatories; 

event DCAsigned(address indexed signatoryAddress, uint256 signatureDate);
event DCArevoked(address indexed signatoryAddress);

struct Signatory {  
        address signatoryAddress;  
        uint256 signatureDate;  
        bool signatureRevoked;  
    }

function signDCA() public {
    address signatoryAddress = msg.sender;
    uint256 signatureDate = block.timestamp;  
    bool signatureRevoked = false; 
    DCAsignatories = DCAsignatories + 1; 
    
    signatories[signatoryAddress] = Signatory(
            signatoryAddress,
            signatureDate,
            signatureRevoked);
            
            emit DCAsigned(signatoryAddress, signatureDate);
    }
    
function revokeDCA() public {
    Signatory storage signatory = signatories[msg.sender];
    assert(address(msg.sender) == signatory.signatoryAddress);
    signatory.signatureRevoked = true;
    DCAsignatories = DCAsignatories - 1; 
    
    emit DCArevoked(msg.sender);
    }
    
function tipOpenESQ() public payable {  
    0xBBE222Ef97076b786f661246232E41BE0DFf6cc4.transfer(msg.value);
    }

}