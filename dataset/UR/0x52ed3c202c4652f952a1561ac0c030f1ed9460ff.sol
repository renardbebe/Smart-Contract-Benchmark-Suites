 

 

 
contract Owned {

     
    address owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    function changeOwner(address newOwner) onlyowner {
        owner = newOwner;
    }

     
    modifier onlyowner() {
        if (msg.sender==owner) _;
    }

     
    function kill() onlyowner {
        if (msg.sender == owner) suicide(owner);
    }
}

 
contract Documents is Owned {

     
    struct Document {
        string hash;
        string link;
        string data;
        address creator;
        uint date;
        uint signsCount;
        mapping (uint => Sign) signs;
    }

     
    struct Sign {
        address member;
        uint date;
    }

     
    mapping (uint => Document) public documentsIds;

     
    uint documentsCount = 0;

     
    event DocumentSigned(uint id, address member);

     
    event DocumentRegistered(uint id, string hash);

      
    function Documents() {
    }

     
    function registerDocument(string hash,
                       string link,
                       string data) {
        address creator = msg.sender;

        uint id = documentsCount + 1;
        documentsIds[id] = Document({
           hash: hash,
           link: link,
           data: data,
           creator: creator,
           date: now,
           signsCount: 0
        });
        documentsCount = id;
        DocumentRegistered(id, hash);
    }

     
    function addSignature(uint id) {
        address member = msg.sender;
        if (documentsCount < id) throw;

        Document d = documentsIds[id];
        uint count = d.signsCount;
        bool signed = false;
        if (count != 0) {
            for (uint i = 0; i < count; i++) {
                if (d.signs[i].member == member) {
                    signed = true;
                    break;
                }
            }
        }

        if (!signed) {
            d.signs[count] = Sign({
                    member: member,
                    date: now
                });
            documentsIds[id].signsCount = count + 1;
            DocumentSigned(id, member);
        }
    }

     
    function getDocumentsCount() constant returns (uint) {
        return documentsCount;
    }

     
    function getDocument(uint id) constant returns (string hash,
                       string link,
                       string data,
                       address creator,
                       uint date) {
        Document d = documentsIds[id];
        hash = d.hash;
        link = d.link;
        data = d.data;
        creator = d.creator;
        date = d.date;
    }

     
    function getDocumentSignsCount(uint id) constant returns (uint) {
        Document d = documentsIds[id];
        return d.signsCount;
    }

     
    function getDocumentSign(uint id, uint index) constant returns (
                        address member,
                        uint date) {
        Document d = documentsIds[id];
        Sign s = d.signs[index];
        member = s.member;
        date = s.date;
	}
}