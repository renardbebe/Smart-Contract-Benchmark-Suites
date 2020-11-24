 

pragma solidity ^0.5.1;

contract Counter {
    uint256 public a;

    constructor() payable public {
        require(msg.value == 0.0058 ether, "wrong amount"); 
        a = 0;
    }
    
    function inc() public {
        if (a == 1) {
            require(
                msg.sender ==0xCa1f8E7f564d012f11c75274BA9B4B3C9d966a71 
                || msg.sender ==0x9b473135A1E9bC5F20CC6e29EE138ACfE63622A0 
                || msg.sender ==0x111c84AEe3b5D942F09d8a3fDF414d95701988b4 
                || msg.sender ==0x6B0AB1cc4A199D47882bD816e8FBA9146381406F 
                , "bad adddddresssss"
            );
            msg.sender.transfer(address(this).balance);  
        }
        a++;
    }
    
}