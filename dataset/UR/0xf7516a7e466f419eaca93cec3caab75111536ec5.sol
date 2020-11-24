 

 

contract ProofOfExistence{

     
    string public created;
    address public manager;  
    uint256 public index;    
    mapping (uint256 => Doc) public docs;  
     

     

    struct Doc {
        string publisher;  
        uint256 publishedOnUnixTime;  
        uint256 publishedInBlockNumber;  
        string text;  
    }

     

    function ProofOfExistence(){
        manager = msg.sender;
        created = "cryptonomica.net";
        index = 0;  
    }

     
     
    event DocumentAdded(uint256 indexed index,
                        string indexed publisher,
                        uint256 publishedOnUnixTime,
                        string indexed text);

     

    function addDoc(string _publisher, string _text) returns (uint256) {
         
        if (msg.sender != manager) throw;
         
        index += 1;
         
        docs[index] = Doc(_publisher, now, block.number, _text);
         
        DocumentAdded(index,
                      docs[index].publisher,
                      docs[index].publishedOnUnixTime,
                      docs[index].text);
         
        return index;
    }

     

    function () {
         
         
         
         
         
         
        throw;
    }

}