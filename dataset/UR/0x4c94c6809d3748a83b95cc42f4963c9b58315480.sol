 

pragma solidity ^0.4.23;

contract ArtStamp { 
    
     
     
     
    struct Piece {
        string metadata;
        string title;
        bytes32 proof;
        address owner;
         
         
        bool forSale; 
         
         
         
        address witness;
    }

     
     
    struct Signature {
        address signee;
        bool hasSigned;
    }

     
    struct Escrow {
        Signature sender;
        Signature recipient;
        Signature witness;
         
        uint blockNum;
    }
    
     
    mapping (uint => Piece) pieces;

     
    uint piecesLength;

     
    mapping (uint => Escrow) escrowLedger;

     
     
    mapping (bytes32 => bool) dataRecord;

     
     
     


     



     

     
    function getEscrowData(uint i) view public returns (address, bool, address, bool, address, bool, uint){
        return (escrowLedger[i].sender.signee, escrowLedger[i].sender.hasSigned, 
        escrowLedger[i].recipient.signee, escrowLedger[i].recipient.hasSigned, 
        escrowLedger[i].witness.signee, escrowLedger[i].witness.hasSigned, 
        escrowLedger[i].blockNum);
    }

     
    function getNumPieces() view public returns (uint) {
        return piecesLength;
    }

    function getOwner(uint id) view public returns (address) {
        return pieces[id].owner;
    }

    function getPiece(uint id) view public returns (string, string, bytes32, bool, address, address) {
        Piece memory piece = pieces[id];
        return (piece.metadata, piece.title, piece.proof, piece.forSale, piece.owner, piece.witness);
    }
    
    function hashExists(bytes32 proof) view public returns (bool) {
        return dataRecord[proof];
    }

    function hasOwnership(uint id) view public returns (bool)
    {
        return pieces[id].owner == msg.sender;
    }


     




     

    function addPieceAndHash(string _metadata, string _title, string data, address witness) public {
        bytes32 _proof = keccak256(abi.encodePacked(data));
         
        addPiece(_metadata,_title,_proof,witness);
    }
    
    function addPiece(string _metadata, string _title, bytes32 _proof, address witness) public {
        bool exists = hashExists(_proof);
        require(!exists, "This piece has already been uploaded");
        dataRecord[_proof] = true;
        pieces[piecesLength] = Piece(_metadata,  _title, _proof, msg.sender, false, witness);
        piecesLength++;
    }

     
    function editPieceData(uint id, string newTitle, string newMetadata) public {
        bool ownership = hasOwnership(id);
        require(ownership, "You don't own this piece");
        pieces[id].metadata = newMetadata;
        pieces[id].title = newTitle;
    }

    function editMetadata(uint id, string newMetadata) public {
        bool ownership = hasOwnership(id);
        require(ownership, "You don't own this piece");
        pieces[id].metadata = newMetadata;
    }

    function editTitle(uint id, string newTitle) public {
        bool ownership = hasOwnership(id);
        require(ownership, "You don't own this piece");
        pieces[id].title = newTitle;
    }

    function escrowTransfer(uint id, address recipient) public {
        bool ownership = hasOwnership(id);
        require(ownership, "You don't own this piece");

         
        pieces[id].owner = address(this);

         
        escrowLedger[id] = Escrow({
            sender: Signature(msg.sender,false),
            recipient: Signature(recipient,false),
            witness: Signature(pieces[id].witness,false),
            blockNum: block.number});
    }
    

     
     
    uint timeout = 100000; 

     
    function retrievePieceFromEscrow(uint id) public {
         
        require(pieces[id].owner == address(this));

        require(block.number > escrowLedger[id].blockNum + timeout);

        address sender = escrowLedger[id].sender.signee;

        delete escrowLedger[id];

        pieces[id].owner = sender;

    } 

    function signEscrow(uint id) public {
         
        require(pieces[id].owner == address(this));

         
        require(msg.sender == escrowLedger[id].sender.signee ||
            msg.sender == escrowLedger[id].recipient.signee || 
            msg.sender == escrowLedger[id].witness.signee, 
            "You don't own this piece");

        bool allHaveSigned = true;

        if(msg.sender == escrowLedger[id].sender.signee){
            escrowLedger[id].sender.hasSigned = true;
        }  
        allHaveSigned = allHaveSigned && escrowLedger[id].sender.hasSigned;
        
        if(msg.sender == escrowLedger[id].recipient.signee){
            escrowLedger[id].recipient.hasSigned = true;
        }
        allHaveSigned = allHaveSigned && escrowLedger[id].recipient.hasSigned;
        

        if(msg.sender == escrowLedger[id].witness.signee){
            escrowLedger[id].witness.hasSigned = true;
        }        
        
        allHaveSigned = allHaveSigned && 
            (escrowLedger[id].witness.hasSigned || 
            escrowLedger[id].witness.signee == 0x0000000000000000000000000000000000000000);

         
        if(allHaveSigned)
        {
            address recipient = escrowLedger[id].recipient.signee;
            delete escrowLedger[id];
            pieces[id].owner = recipient;
        }
    }



    function transferPiece(uint id, address _to) public
    {
        bool ownership = hasOwnership(id);
        require(ownership, "You don't own this piece");

         
        if(pieces[id].witness != 0x0000000000000000000000000000000000000000){
            escrowTransfer(id, _to);
            return;
        }

        pieces[id].owner = _to;
    }



}