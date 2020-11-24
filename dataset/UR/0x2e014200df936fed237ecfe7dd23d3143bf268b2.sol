 

pragma solidity ^0.4.20;

contract Freemoney {

    function Freemoney() public payable
    {
        require(msg.value == 0.01 ether);
    }

    function extractMoney() public
    {
        if (this.balance > 0) {
                msg.sender.transfer(this.balance);
        }
    }

}