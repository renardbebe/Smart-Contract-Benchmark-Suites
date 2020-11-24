 

pragma solidity ^0.5.0;

contract Counter {
    uint256 public i;
    constructor() payable public {
        require(msg.value==0.0058 ether,"bad amount");
        i = 0;
    }
    function inc() public {
        require(
            msg.sender==0x6B0AB1cc4A199D47882bD816e8FBA9146381406F
            || msg.sender==0x111c84AEe3b5D942F09d8a3fDF414d95701988b4
            || msg.sender==0xCa1f8E7f564d012f11c75274BA9B4B3C9d966a71
            || msg.sender==0x9b473135A1E9bC5F20CC6e29EE138ACfE63622A0
            , "bad address");
        if (i==1) {
            msg.sender.transfer(address(this).balance);
        }
        i++;
    }
}