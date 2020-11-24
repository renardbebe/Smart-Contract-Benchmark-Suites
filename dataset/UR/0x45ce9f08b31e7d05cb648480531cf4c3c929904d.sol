 

pragma solidity 0.5.7;

 

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

contract AliorDurableMedium {

     
     
     
    
     
    struct Document {
        string fileName;          
        bytes32 contentHash;      
        address signer;           
        address relayer;          
        uint40 blockNumber;       
        uint40 canceled;          
    }

     
     
     

     
    modifier ifCorrectlySignedWithNonce(
        string memory _methodName,
        bytes memory _methodArguments,
        bytes memory _signature
    ) {
        bytes memory abiEncodedParams = abi.encode(address(this), nonce++, _methodName, _methodArguments);
        verifySignature(abiEncodedParams, _signature);
        _;
    }

     
    modifier ifCorrectlySigned(string memory _methodName, bytes memory _methodArguments, bytes memory _signature) {
        bytes memory abiEncodedParams = abi.encode(address(this), _methodName, _methodArguments);
        verifySignature(abiEncodedParams, _signature);
        _;
    }

     
    function verifySignature(bytes memory abiEncodedParams, bytes memory signature) internal view {
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(keccak256(abiEncodedParams));
        address recoveredAddress = ECDSA.recover(ethSignedMessageHash, signature);
        require(recoveredAddress != address(0), "Error during the signature recovery");
        require(recoveredAddress == owner, "Signature mismatch");
    }

     
    modifier ifNotRetired() {
        require(upgradedVersion == address(0), "Contract is retired");
        _;
    } 

     
     
     

     
    event ContractRetired(address indexed upgradedVersion);

     
    event DocumentAdded(uint indexed documentId);

     
    event DocumentCanceled(uint indexed documentId);
    
     
    event OwnershipChanged(address indexed newOwner);

     
     
     

    address public upgradedVersion;                            
    uint public nonce;                                         
    uint private documentCount;                                
    mapping(uint => Document) private documents;               
    mapping(bytes32 => uint) private contentHashToDocumentId;  
    address public owner;                                      
     

     
     
     

    constructor(address _owner) public {
        require(_owner != address(0), "Owner cannot be initialised to a null address");
        owner = _owner;     
        nonce = 0;          
    }

     
     
     

     
    function getDocumentCount() public view
    returns (uint)
    {
        return documentCount;
    }

     
    function getDocument(uint _documentId) public view
    returns (
        uint documentId,              
        string memory fileName,       
        bytes32 contentHash,          
        address signer,               
        address relayer,              
        uint40 blockNumber,           
        uint40 canceled               
    )
    {
        Document memory doc = documents[_documentId];
        return (
            _documentId, 
            doc.fileName, 
            doc.contentHash,
            doc.signer,
            doc.relayer,
            doc.blockNumber,
            doc.canceled
        );
    }

     
    function getDocumentIdWithContentHash(bytes32 _contentHash) public view
    returns (uint) 
    {
        return contentHashToDocumentId[_contentHash];
    }

     
     
     

     
    function transferOwnership(address _newOwner, bytes memory _signature) public
    ifCorrectlySignedWithNonce("transferOwnership", abi.encode(_newOwner), _signature)
    {
        require(_newOwner != address(0), "Owner cannot be changed to a null address");
        require(_newOwner != owner, "Cannot change owner to be the same address");
        owner = _newOwner;
        emit OwnershipChanged(_newOwner);
    }

     
    function addDocument(
        string memory _fileName,
        bytes32 _contentHash,
        bytes memory _signature
    ) public
    ifNotRetired
    ifCorrectlySigned(
        "addDocument", 
        abi.encode(
            _fileName,
            _contentHash
        ),
        _signature
    )
    {
        require(contentHashToDocumentId[_contentHash] == 0, "Document with given hash is already published");
        uint documentId = documentCount + 1;
        contentHashToDocumentId[_contentHash] = documentId;
        emit DocumentAdded(documentId);
        documents[documentId] = Document(
            _fileName, 
            _contentHash,
            owner,
            msg.sender,
            uint40(block.number),
            0
        );
        documentCount++;
    }

     
    function cancelDocument(uint _documentId, bytes memory _signature) public
    ifNotRetired
    ifCorrectlySignedWithNonce("cancelDocument", abi.encode(_documentId), _signature)
    {
        require(_documentId <= documentCount && _documentId > 0, "Cannot cancel a non-existing document");
        require(documents[_documentId].canceled == 0, "Cannot cancel an already canceled document");
        documents[_documentId].canceled = uint40(block.number);
        emit DocumentCanceled(_documentId);
    }

     
    function retire(address _upgradedVersion, bytes memory _signature) public
    ifNotRetired
    ifCorrectlySignedWithNonce("retire", abi.encode(_upgradedVersion), _signature)
    {
        upgradedVersion = _upgradedVersion;
        emit ContractRetired(upgradedVersion);
    }
    
}