 

pragma solidity ^0.4.8;

contract TrustedDocument {
     
     
    struct Document {
         
         
        uint documentId;
         
        bytes32 fileName;
         
        string documentContentSHA256;
         
         
         
         
        string documentMetadataSHA256;
         
         
        uint blockTime;
         
        uint blockNumber;
         
         
         
         
        uint validFrom;
         
        uint validTo;
         
         
         
         
         
         
         
         
         
        uint updatedVersionId;
    }

     
    address public owner;

     
     
     
     
     
    address public upgradedVersion;

     
    uint public documentsCount;

     
    string public baseUrl;

     
    mapping(uint => Document) private documents;

     
    event EventDocumentAdded(uint indexed documentId);
     
    event EventDocumentUpdated(uint indexed referencingDocumentId, uint indexed updatedDocumentId);
     
    event Retired(address indexed upgradedVersion);

     
    modifier onlyOwner() {
        if (msg.sender == owner) 
        _;
    }

     
     
    modifier ifNotRetired() {
        if (upgradedVersion == 0) 
        _;
    } 

     
    function TrustedDocument() public {
        owner = msg.sender;
        baseUrl = "_";
    }

     
     
     
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

     
    function addDocument(bytes32 _fileName, string _documentContentSHA256, string _documentMetadataSHA256, uint _validFrom, uint _validTo) public onlyOwner ifNotRetired {
         
         
         
        uint documentId = documentsCount+1;
         
        EventDocumentAdded(documentId);
        documents[documentId] = Document(documentId, _fileName, _documentContentSHA256, _documentMetadataSHA256, block.timestamp, block.number, _validFrom, _validTo, 0);
        documentsCount++;
    }

     
    function getDocumentsCount() public view
    returns (uint)
    {
        return documentsCount;
    }

     
     
     
    function retire(address _upgradedVersion) public onlyOwner ifNotRetired {
         
        upgradedVersion = _upgradedVersion;
        Retired(upgradedVersion);
    }

     
    function getDocument(uint _documentId) public view
    returns (
        uint documentId,
        bytes32 fileName,
        string documentContentSHA256,
        string documentMetadataSHA256,
        uint blockTime,
        uint blockNumber,
        uint validFrom,
        uint validTo,
        uint updatedVersionId
    ) {
        Document memory doc = documents[_documentId];
        return (doc.documentId, doc.fileName, doc.documentContentSHA256, doc.documentMetadataSHA256, doc.blockTime, doc.blockNumber, doc.validFrom, doc.validTo, doc.updatedVersionId);
    }

     
     
    function getDocumentUpdatedVersionId(uint _documentId) public view
    returns (uint) 
    {
        Document memory doc = documents[_documentId];
        return doc.updatedVersionId;
    }

     
     
    function getBaseUrl() public view
    returns (string) 
    {
        return baseUrl;
    }

     
     
     
    function setBaseUrl(string _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

     
    function getFirstDocumentIdStartingAtValidFrom(uint _unixTimeFrom) public view
    returns (uint) 
    {
        for (uint i = 0; i < documentsCount; i++) {
           Document memory doc = documents[i];
           if (doc.validFrom>=_unixTimeFrom) {
               return i;
           }
        }
        return 0;
    }

     
    function getFirstDocumentIdBetweenDatesValidFrom(uint _unixTimeStarting, uint _unixTimeEnding) public view
    returns (uint firstID, uint lastId) 
    {
        firstID = 0;
        lastId = 0;
         
        for (uint i = 0; i < documentsCount; i++) {
            Document memory doc = documents[i];
            if (firstID==0) {
                if (doc.validFrom>=_unixTimeStarting) {
                    firstID = i;
                }
            } else {
                if (doc.validFrom<=_unixTimeEnding) {
                    lastId = i;
                }
            }
        }
         
        if ((firstID>0)&&(lastId==0)&&(_unixTimeStarting<_unixTimeEnding)) {
            lastId = documentsCount;
        }
    }

     
    function getDocumentIdWithContentHash(string _documentContentSHA256) public view
    returns (uint) 
    {
        bytes32 documentContentSHA256Keccak256 = keccak256(_documentContentSHA256);
        for (uint i = 0; i < documentsCount; i++) {
           Document memory doc = documents[i];
           if (keccak256(doc.documentContentSHA256)==documentContentSHA256Keccak256) {
               return i;
           }
        }
        return 0;
    }

     
    function getDocumentIdWithName(string _fileName) public view
    returns (uint) 
    {
        bytes32 fileNameKeccak256 = keccak256(_fileName);
        for (uint i = 0; i < documentsCount; i++) {
           Document memory doc = documents[i];
           if (keccak256(doc.fileName)==fileNameKeccak256) {
               return i;
           }
        }
        return 0;
    }

     
     
     
    function updateDocument(uint referencingDocumentId, uint updatedDocumentId) public onlyOwner ifNotRetired {
        Document storage referenced = documents[referencingDocumentId];
        Document memory updated = documents[updatedDocumentId];
         
        referenced.updatedVersionId = updated.documentId;
        EventDocumentUpdated(referenced.updatedVersionId,updated.documentId);
    }
}