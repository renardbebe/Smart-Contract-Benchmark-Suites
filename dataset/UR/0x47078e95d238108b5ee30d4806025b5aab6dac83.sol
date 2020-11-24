 

pragma solidity ^0.4.11;

 
 
contract BraggerContract {
     
    address public richest;
    
     
    string public displayString;
    
     
    uint public highestBalance;
    
    address owner;

    function BraggerContract() public payable {
        owner = msg.sender;
        highestBalance = 0;
    }

    function becomeRichest(string newString) public payable {
         
        require(msg.value > highestBalance);
        
         
        require(bytes(newString).length < 500);
        
        highestBalance = msg.value;
        richest = msg.sender;
        displayString = newString;
    }
    
    function withdrawBalance() public {
        owner.transfer(this.balance);
    }
}