 

 

pragma solidity ^0.5.7;

contract ProxyStorage {
    address powner;
    address pimplementation;
}

 
 
 
contract IERC173 {
     
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

     
     
     

     
     
    function transferOwnership(address _newOwner) external;
}

 

pragma solidity ^0.5.7;



contract Ownable is ProxyStorage, IERC173 {
    modifier onlyOwner() {
        require(msg.sender == powner, "The owner should be the sender");
        _;
    }

    constructor() public {
        powner = msg.sender;
        emit OwnershipTransferred(address(0x0), msg.sender);
    }

    function owner() external view returns (address) {
        return powner;
    }

     
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "0x0 Is not a valid owner");
        emit OwnershipTransferred(powner, _newOwner);
        powner = _newOwner;
    }
}


contract Proxy is ProxyStorage, Ownable {
    event SetImplementation(address _prev, address _new);

    function implementation() external view returns (address) {
        return pimplementation;
    }

    function setImplementation(address _implementation) external onlyOwner {
        emit SetImplementation(pimplementation, _implementation);
        pimplementation = _implementation;
    }
    
    function() external {
        address _impl = pimplementation;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            if iszero(result) {
                revert(ptr, size)
            }

            return(ptr, size)
        }
    }
}