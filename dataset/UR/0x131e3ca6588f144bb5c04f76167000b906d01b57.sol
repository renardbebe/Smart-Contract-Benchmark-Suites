 

pragma solidity ^0.5.0;

contract Manager {
    function open(bytes32, address) public returns (uint);

}

contract OpenCdps {
    address public owner;
    
    bytes32 ethIlk = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    Manager manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function open(uint _numCDPs) external {
        for (uint i = 0; i < _numCDPs; ++i) {
            manager.open(ethIlk, msg.sender);
        }
    }
    
}