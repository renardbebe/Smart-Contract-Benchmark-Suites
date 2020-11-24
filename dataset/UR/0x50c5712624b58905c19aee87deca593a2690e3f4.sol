 

contract Docsign
{
     
    event Added(address indexed _from);

     
    event Created(address indexed _from);


    struct Document {
        uint version;
        string name;
        address creator;
        string hash;
        uint date;
    }
    Document[] public a_document;
    uint length;

     
    function Docsign() {
        Created(msg.sender);
    }

    function Add(uint _version, string _name, string _hash) {
        a_document.push(Document(_version,_name,msg.sender, _hash, now));
        Added(msg.sender);
    }
     
    function getCount() public constant returns(uint) {
        return a_document.length;
    }
    
     
    function() { throw; }

}