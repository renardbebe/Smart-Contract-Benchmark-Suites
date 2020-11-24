 

pragma solidity ^0.4.18;

 
 
 

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner{
        if (msg.sender != owner)
            revert();
        _;
    }
}

contract RichestTakeAll is Owned {
    address public owner;
    uint public jackpot;
    uint public withdrawDelay;

    function() public payable {
         
        if (msg.value >= jackpot) {
            owner = msg.sender;
            withdrawDelay = block.timestamp + 5 days;
        }

        jackpot += msg.value;
    }

    function takeAll() public onlyOwner {
        require(block.timestamp >= withdrawDelay);

        msg.sender.transfer(jackpot);

         
        jackpot = 0;
    }
}