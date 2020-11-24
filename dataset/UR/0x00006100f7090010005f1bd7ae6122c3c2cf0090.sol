 

pragma solidity ^0.4.23;

 

 
contract TrueAUD {
     
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    event NewPendingOwner(address currentOwner, address pendingOwner);
    
     
    bytes32 private constant proxyOwnerPosition = 0x9afdba48695f976525206667656e0eb4a6d66671c0d3ec078f1f48d2307ed49c; 
    bytes32 private constant pendingProxyOwnerPosition = 0x7b9044cf1491ee5d1e688907e48d0439248c6543a740f2f5f828fecf8367c4d1; 

     
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

     
    bytes32 private constant implementationPosition = 0xc20777594ecafd73f44a72aa5ad2de8704211212d04473d4b208539e34ba14eb;  

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

     
    function() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, returndatasize, calldatasize)
            let result := delegatecall(gas, sload(0xc20777594ecafd73f44a72aa5ad2de8704211212d04473d4b208539e34ba14eb), ptr, calldatasize, returndatasize, returndatasize)
            returndatacopy(ptr, 0, returndatasize)

            switch result
            case 0 { revert(ptr, returndatasize) }
            default { return(ptr, returndatasize) }
        }
    }
}