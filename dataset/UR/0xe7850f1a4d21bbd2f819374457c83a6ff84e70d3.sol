 

pragma solidity ^0.4.16;

 
contract SuicideSender {
    function suicideSend(address to) payable {
        address temp_addr;
        assembly {
            let free_ptr := mload(0x40)
             
            mstore(free_ptr, or(0x730000000000000000000000000000000000000000ff, mul(to, 0x100)))
             
            temp_addr := create(callvalue, add(free_ptr, 10), 22)
        }
        require(temp_addr != 0);
    }
}