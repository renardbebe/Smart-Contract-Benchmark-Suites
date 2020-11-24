 

pragma solidity ^0.4.25;

contract artContract{

    address private contractOwner;               
    string public artInfoHash;               
    string public artOwnerHash;                  
    bytes32 public summaryTxHash;                
    bytes32 public recentInputTxHash;            

    constructor() public{                                                           
        contractOwner = msg.sender;
    }
        
    modifier onlyOwner(){                                                           
        require(msg.sender == contractOwner);
        _;
    }

    function setArtInfoHash(string memory _infoHash) onlyOwner public {             
        artInfoHash = _infoHash;
    }    
    
    function setArtOwnerHash(string memory _artHash) onlyOwner public {             
        artOwnerHash = _artHash;
    }    
 
    event setTxOnBlockchain(bytes32);
 
    function setTxHash(bytes32 _txHash) onlyOwner public {                          
        recentInputTxHash = _txHash;                                                
        summaryTxHash = makeHash(_txHash);                                          
        emit setTxOnBlockchain(summaryTxHash);
    }
 
    function getArtInfoHash() public view returns (string memory) {                
        return artInfoHash;
    }

    function getArtOwnerHash() public view returns (string memory) {                
        return artOwnerHash;
    }

    function getRecentInputTxHash() public view returns (bytes32) {                      
        return recentInputTxHash;
    }

    function getSummaryTxHash() public view returns (bytes32) {                      
        return summaryTxHash;
    }

    function makeHash(bytes32 _input) private view returns(bytes32) {          
        return keccak256(abi.encodePacked(_input, summaryTxHash));
    }
}