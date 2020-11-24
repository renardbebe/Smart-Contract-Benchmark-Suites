 

pragma solidity ^0.5.12;

contract TheOddWins {
    address payable owner;
    uint evenOrOdd = 0;

    constructor() public {
        owner = msg.sender;
    }
    
     
    function () external payable {
        if (tx.origin == msg.sender) {
            require(msg.value == 3*10**17);
            if (evenOrOdd % 2 != 0) {
                uint balance = address(this).balance;
                uint devFee = balance / 100;
                 
                if (owner.send(devFee)) {
                     
                    if (!msg.sender.send(balance - devFee)) {
                        revert();
                    }
                }
            }
            evenOrOdd++;
        }
    }
    
    function shutdown() public {
        selfdestruct(owner);
    }
}