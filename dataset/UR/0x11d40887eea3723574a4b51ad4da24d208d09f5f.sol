 

pragma solidity 0.4.24;
pragma experimental "v0.5.0";
 

 
 
 
 
 
 
contract Storage0 {
     
    mapping(bytes4 => address) internal delegates;
}

contract Mokens is Storage0 {
    constructor(address mokenUpdates) public {
         
        bytes memory calldata = abi.encodeWithSelector(0x584fc325,mokenUpdates);
        assembly {
            let callSuccess := delegatecall(gas, mokenUpdates, add(calldata, 0x20), mload(calldata), 0, 0)
            let size := returndatasize
            returndatacopy(calldata, 0, size)
            if eq(callSuccess,0) {revert(calldata, size)}
        }
    }
    function() external payable {
        address delegate = delegates[msg.sig];
        require(delegate != address(0), "Mokens function does not exist.");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, delegate, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }
}