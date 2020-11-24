 

 

pragma solidity ^0.5.7;


 
 
 
contract IERC173 {
     
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

     
     
     

     
     
    function transferOwnership(address _newOwner) external;
}

 

pragma solidity ^0.5.7;



contract Ownable is IERC173 {
    address internal _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "The owner should be the sender");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0x0), msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

     
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "0x0 Is not a valid owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}


contract Proxy is Ownable {
    event SetImplementation(address _prev, address _new);

    address private iimplementation;

    function implementation() external view returns (address) {
        return iimplementation;
    }

    function setImplementation(address _implementation) external onlyOwner {
        emit SetImplementation(iimplementation, _implementation);
        iimplementation = _implementation;
    }
    
    function() external {
        address _impl = iimplementation;
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