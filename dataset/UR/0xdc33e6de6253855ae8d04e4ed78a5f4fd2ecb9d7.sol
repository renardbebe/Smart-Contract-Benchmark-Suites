 

pragma solidity ^0.4.24;
 
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract Marriage is owned {
     
    bytes32 public partner1;
    bytes32 public partner2;
    uint256 public marriageDate;
    bytes32 public marriageStatus;
    bytes public imageHash;
    bytes public marriageProofDoc;
    
    constructor() public {
        createMarriage();
    }

     
    function createMarriage() onlyOwner public {
        partner1 = "Edison Lee";
        partner2 = "Chino Kafuu";
        marriageDate = 1527169003;
        setStatus("Married");
        bytes32 name = "Marriage Contract Creation";
        
        majorEventFunc(marriageDate, name, "We got married!");
    }
    
     
    function setStatus(bytes32 status) onlyOwner public {
        marriageStatus = status;
        majorEventFunc(block.timestamp, "Changed Status", status);
    }
    
     
    function setImage(bytes IPFSImageHash) onlyOwner public {
        imageHash = IPFSImageHash;
        majorEventFunc(block.timestamp, "Entered Marriage Image", "Image is in IPFS");
    }
    
     
    function marriageProof(bytes IPFSProofHash) onlyOwner public {
        marriageProofDoc = IPFSProofHash;
        majorEventFunc(block.timestamp, "Entered Marriage Proof", "Marriage proof in IPFS");
    }

     
    function majorEventFunc(uint256 eventTimeStamp, bytes32 name, bytes32 description) public {
        emit MajorEvent(block.timestamp, eventTimeStamp, name, description);
    }

     
    event MajorEvent(uint256 logTimeStamp, uint256 eventTimeStamp, bytes32 indexed name, bytes32 indexed description);
    
     
     
     
    function () public {
        revert();
    }
}