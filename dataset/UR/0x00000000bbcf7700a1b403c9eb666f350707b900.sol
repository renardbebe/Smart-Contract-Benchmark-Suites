 

pragma solidity ^0.4.23;

 

 
contract Proxy {
    
     
    function implementation() public view returns (address);

     
    function() external payable {
        address _impl = implementation();
        
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

 

 
contract UpgradeabilityProxy is Proxy {
     
    event Upgraded(address indexed implementation);

     
    bytes32 private constant implementationPosition = 0xdc8e328a3c0acffa7969856957539d0f8c2deaa0d39abaf20397a9fa3b45bf17;  

     
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
          impl := sload(position)
        }
    }

     
    function _setImplementation(address newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
          sstore(position, newImplementation)
        }
    }

     
    function _upgradeTo(address newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != newImplementation);
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
}

 

 
contract TGBPController is UpgradeabilityProxy {
     
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    event NewPendingOwner(address currentOwner, address pendingOwner);
    
     
    bytes32 private constant proxyOwnerPosition = 0x58709042d6c9a2b64c8e7802bfedabdcd2eaecc68e15ef2e896a5970c608cd16; 
    bytes32 private constant pendingProxyOwnerPosition = 0xa6933dbb41d1bc3d681619c11234027db3b75954220aa88dfdc74750053ed30c; 

     
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

     
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "only Proxy Owner");
        _;
    }

     
    modifier onlyPendingProxyOwner() {
        require(msg.sender == pendingProxyOwner(), "only pending Proxy Owner");
        _;
    }

     
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

     
    function pendingProxyOwner() public view returns (address pendingOwner) {
        bytes32 position = pendingProxyOwnerPosition;
        assembly {
            pendingOwner := sload(position)
        }
    }

     
    function _setUpgradeabilityOwner(address newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

     
    function _setPendingUpgradeabilityOwner(address newPendingProxyOwner) internal {
        bytes32 position = pendingProxyOwnerPosition;
        assembly {
            sstore(position, newPendingProxyOwner)
        }
    }

     
    function transferProxyOwnership(address newOwner) external onlyProxyOwner {
        require(newOwner != address(0));
        _setPendingUpgradeabilityOwner(newOwner);
        emit NewPendingOwner(proxyOwner(), newOwner);
    }

     
    function claimProxyOwnership() external onlyPendingProxyOwner {
        emit ProxyOwnershipTransferred(proxyOwner(), pendingProxyOwner());
        _setUpgradeabilityOwner(pendingProxyOwner());
        _setPendingUpgradeabilityOwner(address(0));
    }

     
    function upgradeTo(address implementation) external onlyProxyOwner {
        _upgradeTo(implementation);
    }
}