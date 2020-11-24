 

pragma solidity ^0.4.18;

 

contract LuckyNumber {

    address owner;
    bool contractIsAlive = true;
    
     
    modifier live() {
        require(contractIsAlive);
        _;
    }

     
    function LuckyNumber() public { 
        owner = msg.sender;
    }

     
    function addBalance() public payable live {
    }
    

     
    function getBalance() view external live returns (uint) {
        return this.balance;
    }

     
    function kill() external live { 
        if (msg.sender == owner) {        
            owner.transfer(this.balance);
            contractIsAlive = false;
            }
    }

     
    function takeAGuess(uint8 _myGuess) public payable live {
        require(msg.value == 0.00025 ether);
         uint8 winningNumber = uint8(keccak256(now, owner)) % 10;
        if (_myGuess == winningNumber) {
            msg.sender.transfer((this.balance*9)/10);
            owner.transfer(this.balance);
            contractIsAlive = false;   
        }
    }


} 