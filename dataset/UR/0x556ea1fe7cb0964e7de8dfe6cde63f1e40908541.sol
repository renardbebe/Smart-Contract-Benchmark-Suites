 

pragma solidity 0.5.8;


 
contract Proxy {
    
     
    function implementation() public view returns (address);

     
    function() external payable {
        address _impl = implementation();
        require(_impl != address(0), "Proxy: implementation contract not set");
        
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

     
    event Upgraded(address indexed currentImplementation, address indexed newImplementation);

     
    bytes32 private constant implementationPosition = keccak256("DUSD.proxy.implementation");

     
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
        require(currentImplementation != newImplementation, "UpgradeabilityProxy: newImplementation is the same as currentImplementation");
        emit Upgraded(currentImplementation, newImplementation);
        _setImplementation(newImplementation);
    }
}


 
contract DUSDProxy is UpgradeabilityProxy {

     
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    event NewPendingOwner(address currentOwner, address pendingOwner);
    
     
    bytes32 private constant proxyOwnerPosition = keccak256("DUSD.proxy.owner");
    bytes32 private constant pendingProxyOwnerPosition = keccak256("DUSD.pending.proxy.owner");

     
    constructor() public {
        _setUpgradeabilityOwner(0xfe30e619cc2915C905Ca45C1BA8311109A3cBdB1);
    }

     
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "DUSDProxy: the caller must be the proxy Owner");
        _;
    }

     
    modifier onlyPendingProxyOwner() {
        require(msg.sender == pendingProxyOwner(), "DUSDProxy: the caller must be the pending proxy Owner");
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
        require(newOwner != address(0), "DUSDProxy: cannot transfer control of the proxy owner to the zero address");
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