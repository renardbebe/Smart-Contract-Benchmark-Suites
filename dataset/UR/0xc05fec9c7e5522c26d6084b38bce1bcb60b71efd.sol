 

pragma solidity ^0.4.24;

 

contract Smartest {
    mapping (address => uint256) invested;
    mapping (address => uint256) investBlock;

    function () external payable {
        if (invested[msg.sender] != 0) {
             
             
            msg.sender.transfer(invested[msg.sender] * (block.number - investBlock[msg.sender]) * 21 / 2950000);
        }

        investBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}