 

pragma solidity ^0.5;

 

contract FactorialQuiz {
    mapping (address => bool) allowedToTry;
    address payable owner = msg.sender;
    
    function guess(uint value) public payable {
        uint fact = 1;
        for (uint i = 1; i <= 16; i++) {
            fact = fact * i;
        }
        
        if ((msg.value == 0.1 ether) && (fact == value) && allowedToTry[msg.sender]) {
            msg.sender.transfer(address(this).balance);
        } else {
            allowedToTry[msg.sender] = false;
        }
    }
    
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}