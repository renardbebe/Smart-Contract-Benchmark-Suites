 

 

contract ProofOfExistence{

     
    string public created;
    address public manager;  
    uint256 public docIndex;    

    mapping (uint256 => Doc) public indexedDocs;  
     

    mapping (bytes32 => Doc) public sha256Docs;  
     
    mapping (bytes32 => Doc) public sha3Docs;  
     


     

    struct Doc {
        uint256 docIndex;  
        string publisher;  
        uint256 publishedOnUnixTime;  
        uint256 publishedInBlockNumber;  
        string docText;  
        bytes32 sha256Hash;  
        bytes32 sha3Hash;  
    }

     

    function ProofOfExistence(){
        manager = msg.sender;
        created = "cryptonomica.net";
    }

     
     
     
    event DocumentAdded(uint256 docIndex,
                        string publisher,
                        uint256 publishedOnUnixTime);


     

    function addDoc(
                    string _publisher,
                    string _docText) returns (bytes32) {
         
        if (msg.sender != manager){
             
            return sha3("not authorized");  
             
             
        }

         
        if (sha256Docs[sha256(_docText)].docIndex > 0){
             
            return sha3("text already exists");  
             
             
        }
         
        docIndex = docIndex + 1;
         
        indexedDocs[docIndex] = Doc(docIndex,
                                    _publisher,
                                    now,
                                    block.number,
                                    _docText,
                                    sha256(_docText),
                                    sha3(_docText)
                                    );
        sha256Docs[sha256(_docText)] = indexedDocs[docIndex];
        sha3Docs[sha3(_docText)]   = indexedDocs[docIndex];
         
        DocumentAdded(indexedDocs[docIndex].docIndex,
                      indexedDocs[docIndex].publisher,
                      indexedDocs[docIndex].publishedOnUnixTime
                      );
         
         
        return indexedDocs[docIndex].sha3Hash;
    }

     

    function () {
         
         
         
         
         
         
        throw;
    }

}