 

pragma solidity ^0.5.0;


 
contract UserProxy {

     
    function execute(address _target, bytes memory _data) public payable returns (bytes memory response) {
        require(_target != address(0), "user-proxy-target-address-required");
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                     
                    revert(add(response, 0x20), size)
                }
        }
    }

}