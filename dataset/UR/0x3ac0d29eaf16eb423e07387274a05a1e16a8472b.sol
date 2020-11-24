 

pragma solidity ^0.4.18;

 

contract LuckyNumber {

    address owner;
    uint winningNumber = uint(keccak256(now, owner)) % 10;

    function LuckyNumber() public {  
        owner = msg.sender;
    }

     
    function addBalance() public payable {
    }

     
    function() public payable {
       msg.sender.transfer(msg.value); 
    }
    
     
    function getOwner() view public returns (address)  {
        return owner;
    }

     
    function getBalance() view public returns (uint) {
        return this.balance;
    }

     
    function kill() public { 
        if (msg.sender == owner)   
            selfdestruct(owner);        
    }

     
    function takeAGuess(uint _myGuess) public payable {
        require(msg.value == 0.0001 ether);
        if (_myGuess == winningNumber) {
            msg.sender.transfer((this.balance*9)/10);
            selfdestruct(owner);
        }
    }


} 