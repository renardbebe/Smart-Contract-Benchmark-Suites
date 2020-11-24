 

pragma solidity ^0.4.0;
contract MessaggioInBottiglia {
    address public owner;  
    string public message;  
    string public ownerName;
    
    mapping(address => string[]) public comments;  
    
    modifier onlyOwner() { require(owner == msg.sender); _; }
    
    event newComment(address _sender, string _comment);
    
    constructor() public {  
        owner = msg.sender;
        ownerName = "Gaibrasch Tripfud";
        message = "Questo è messaggio di prova, scritto dal un temibile pirata. Aggiungi un commento se vuoi scopire dove si trova il tesoro nascosto.";
    }
    
    function addComment(string commento) public payable returns(bool){  
        comments[msg.sender].push(commento);
        emit newComment(msg.sender, commento);
        return true;
    }
    
    function destroyBottle() public onlyOwner {  
        selfdestruct(owner);
    }
}