 

pragma solidity ^0.4.19;

 
 
 
 
contract EthDickMeasuringContest {
    address public largestPenisOwner;
    address public owner;
    uint public largestPenis;
    uint public withdrawDate;

    function EthDickMeasuringContest() public{
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
        require(msg.sender == largestPenisOwner);

         
        largestPenisOwner = 0;
        largestPenis = 0;

         
         
        owner.transfer(this.balance*3/100);
        
         
         
        msg.sender.transfer(this.balance);
    }
}