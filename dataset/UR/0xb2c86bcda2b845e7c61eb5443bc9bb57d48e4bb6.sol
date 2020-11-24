 

 

pragma solidity ^0.5.11;


 
contract Proxy {
    event ProxySetImplementation(address _old, address _new);
    event ProxySetOwner(address _old, address _new);
    
    mapping(bytes32 => address) private proxyStorage;

    bytes32 public constant OWNER_SLOT = keccak256("proxy-owner");
    bytes32 public constant IMPLEMENTATION_SLOT = keccak256("proxy-implementation");

    constructor(address _implementation) public {
        emit ProxySetImplementation(address(0), _implementation);
        emit ProxySetOwner(address(0), msg.sender);
        proxyStorage[IMPLEMENTATION_SLOT] = _implementation;
        proxyStorage[OWNER_SLOT] = msg.sender;
    }
    
    modifier onlyOwner {
        require(proxyStorage[OWNER_SLOT] == msg.sender, "only owner");
        _;
    }
    
    function proxySetOwner(address _owner) external onlyOwner {
        emit ProxySetOwner(proxyStorage[OWNER_SLOT], _owner);
        proxyStorage[OWNER_SLOT] = _owner;
    }

    function proxySetImplementation(address _implementation) external onlyOwner {
        emit ProxySetImplementation(proxyStorage[IMPLEMENTATION_SLOT], _implementation);
        proxyStorage[IMPLEMENTATION_SLOT] = _implementation;
    }

    function implementation() external view returns (address) {
        return proxyStorage[IMPLEMENTATION_SLOT];
    }
    
    function proxyOwner() external view returns (address) {
        return proxyStorage[OWNER_SLOT];
    }

     
    function () payable external {
        address _impl = proxyStorage[IMPLEMENTATION_SLOT];
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            if result {
                return(ptr, size)
            }

            revert(ptr, size)
        }
    }
}