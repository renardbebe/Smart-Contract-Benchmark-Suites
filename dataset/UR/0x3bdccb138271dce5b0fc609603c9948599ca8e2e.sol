 

pragma solidity ^0.4.11;

 
 
contract BraggingContract {
     
    address public richest;
    
     
    string public displayString;
    
     
    uint public highestBalance;
    
    address owner;

    function BraggingContract() public payable {
        owner = msg.sender;
        highestBalance = 0;
    }

    function becomeRichest(string newString) public payable {
         
        require(msg.value > 0.002 ether);
        
         
        require(msg.sender.balance > highestBalance);
        
         
        require(bytes(newString).length < 500);
        
        highestBalance = msg.sender.balance;
        richest = msg.sender;
        displayString = newString;
    }
    
    function withdrawTips() public {
        owner.transfer(this.balance);
    }
}