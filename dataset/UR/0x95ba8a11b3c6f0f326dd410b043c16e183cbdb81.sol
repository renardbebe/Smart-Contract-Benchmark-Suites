 

 

pragma solidity >=0.4.25 <0.6.0;

 
contract OwnedUpgradeabilityProxy {
     
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    event NewPendingOwner(address currentOwner, address pendingOwner);
    
     
    bytes32 private constant proxyOwnerPosition = 0x6004f6b6eb3de57beb988d207d67d1fd96d97f56565b653b6e80b856d7c1a35f; 
    bytes32 private constant pendingProxyOwnerPosition = 0x76a33b3ea4443d67022b6c5254816af27c5cfd5c856e0422ce98ad937f4d709d; 

     
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
        address currentImplementation;
        bytes32 position = implementationPosition;
        assembly {
            currentImplementation := sload(position)
        }
        require(currentImplementation != implementation);
        assembly {
          sstore(position, implementation)
        }
        emit Upgraded(implementation);
    }
     
    event Upgraded(address indexed implementation);

     
    bytes32 private constant implementationPosition = 0x84b64b507833ba7e4ea61b69390489bd134000b6d1333e6a1617aac294fa83f7;  

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

     
    function() external payable {
        bytes32 position = implementationPosition;
        
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, returndatasize, calldatasize)
            let result := delegatecall(gas, sload(position), ptr, calldatasize, returndatasize, returndatasize)
            returndatacopy(ptr, 0, returndatasize)

            switch result
            case 0 { revert(ptr, returndatasize) }
            default { return(ptr, returndatasize) }
        }
    }
}