 

pragma solidity 0.4.20;

 
contract DocumentaryContract {

     
    address owner;
    
     
    mapping (address => bool) isEditor;

     
    uint128 doccnt;
    
     
    mapping (uint128 => address) docauthor;		                     
    
     
    mapping (uint128 => bool) isInvisible;		                     
    
     
    mapping (address => uint32) userdoccnt;		                     
    
     
    mapping (address => mapping (uint32 => uint128)) userdocid;		 


     
    event DocumentEvent (
        uint128 indexed docid,
        uint128 indexed refid,
        uint16 state,    
        uint doctime,
        address indexed author,
        string tags,
        string title,
        string text
    );

     
    event TagEvent (
        uint128 docid,
        address indexed author,
        bytes32 indexed taghash,
        uint64 indexed channelid
    );

     
    event InvisibleDocumentEvent (
        uint128 indexed docid,
        uint16 state     
    );
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyEditor {
        require(isEditor[msg.sender] == true);
        _;
    }

    modifier onlyAuthor(uint128 docid) {
        require(docauthor[docid] == msg.sender);
        _;
    }

    modifier onlyVisible(uint128 docid) {
        require(isInvisible[docid] == false);
        _;
    }

    modifier onlyInvisible(uint128 docid) {
        require(isInvisible[docid] == true);
        _;
    }

    function DocumentaryContract() public {
        owner = msg.sender;
        grantEditorRights(owner);
        doccnt = 1;
    }
    
     
    function grantEditorRights(address user) public onlyOwner {
        isEditor[user] = true;
    }

     
    function revokeEditorRights(address editor) public onlyOwner {
        isEditor[editor] = false;
    }

     
    function documentIt(uint128 refid, uint64 doctime, bytes32[] taghashes, string tags, string title, string text) public {
        writeDocument(refid, 0, doctime, taghashes, tags, title, text);
    }
    
     
    function editIt(uint128 docid, uint64 doctime, bytes32[] taghashes, string tags, string title, string text) public onlyAuthor(docid) onlyVisible(docid) {
        writeDocument(docid, 1, doctime, taghashes, tags, title, text);
    }

     
    function writeDocument(uint128 refid, uint16 state, uint doctime, bytes32[] taghashes, string tags, string title, string text) internal {

        docauthor[doccnt] = msg.sender;
        userdocid[msg.sender][userdoccnt[msg.sender]] = doccnt;
        userdoccnt[msg.sender]++;
        
        DocumentEvent(doccnt, refid, state, doctime, msg.sender, tags, title, text);
        for (uint8 i=0; i<taghashes.length; i++) {
            if (i>=5) break;
            if (taghashes[i] != 0) TagEvent(doccnt, msg.sender, taghashes[i], 0);
        }
        doccnt++;
    }
    
     
    function makeInvisible(uint128 docid) public onlyEditor onlyVisible(docid) {
        isInvisible[docid] = true;
        InvisibleDocumentEvent(docid, 1);
    }

     
    function makeVisible(uint128 docid) public onlyEditor onlyInvisible(docid) {
        isInvisible[docid] = false;
        InvisibleDocumentEvent(docid, 0);
    }
    
     
    function getDocCount() public view returns (uint128) {
        return doccnt;
    }

     
    function getUserDocCount(address user) public view returns (uint32) {
        return userdoccnt[user];
    }

     
    function getUserDocId(address user, uint32 docnum) public view returns (uint128) {
        return userdocid[user][docnum];
    }
}