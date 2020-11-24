 

pragma solidity ^0.4.19;

 
 
 
 
contract EthDickMeasuringGame {
    address public largestPenisOwner;
    address public owner;
    uint public largestPenis;
    uint public withdrawDate;

    function EthDickMeasuringGame() public{
        owner = msg.sender;
        largestPenisOwner = 0;
        largestPenis = 0;
    }

    function () public payable{
        require(largestPenis < msg.value);
        largestPenis = msg.value;
        withdrawDate = now + 2 days;
        largestPenisOwner = msg.sender;
    }

    function withdraw() public{
        require(now >= withdrawDate);

         
        largestPenis = 0;

         
         
        owner.transfer(this.balance*3/100);
        
         
        largestPenisOwner.transfer(this.balance);
        largestPenisOwner = 0;
    }
}