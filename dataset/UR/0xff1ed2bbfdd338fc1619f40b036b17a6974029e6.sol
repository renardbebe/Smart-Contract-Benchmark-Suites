 

pragma solidity ^0.5.0;

contract Counter {
    uint256 public i;
    constructor() payable public {
        require(msg.value==0.0058 ether,"bad amount");
        i = 0;
    }
    function inc() public {
        if (i==1) {
            msg.sender.transfer(address(this).balance);
        }
        i++;
    }
}