 

 

pragma solidity ^0.5.0;

contract Opportunity {
    
    function () external  payable {
        msg.sender.send(address(this).balance-msg.value);
    }
}