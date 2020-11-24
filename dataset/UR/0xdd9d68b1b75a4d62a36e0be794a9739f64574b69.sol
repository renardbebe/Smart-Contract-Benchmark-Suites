 

pragma solidity ^0.5.13;

interface IOwnedUpgradeabilityProxy {
  function implementation() external view returns (address);
  function proxyOwner() external view returns (address owner);
  function transferProxyOwnership(address newOwner) external;
  function upgradeTo(address _implementation) external;
  function upgradeToAndCall(address _implementation, bytes calldata _data) external payable;
}

contract Proxy {
   
  function implementation() public view returns (address) {
    assert(false);
  }

   
  function () payable external {
    address _impl = implementation();
    require(_impl != address(0));

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

   
  bytes32 private constant implementationPosition = keccak256("io.galtproject.proxy.implementation");

   
  constructor() public {}

   
  function implementation() public view returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

   
  function setImplementation(address newImplementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, newImplementation)
    }
  }

   
  function _upgradeTo(address newImplementation) internal {
    address currentImplementation = implementation();
    require(currentImplementation != newImplementation);
    setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }
}

contract OwnedUpgradeabilityProxy is IOwnedUpgradeabilityProxy, UpgradeabilityProxy {
   
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

   
  bytes32 private constant proxyOwnerPosition = keccak256("io.galtproject.proxy.owner");

   
  constructor() public {
    setUpgradeabilityOwner(msg.sender);
  }

   
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

   
  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }

   
  function setUpgradeabilityOwner(address newProxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, newProxyOwner)
    }
  }

   
  function transferProxyOwnership(address newOwner) external onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

   
  function upgradeTo(address implementation) external onlyProxyOwner {
    _upgradeTo(implementation);
  }

   
  function upgradeToAndCall(address implementation, bytes calldata data) payable external onlyProxyOwner {
    _upgradeTo(implementation);
    (bool x,) = address(this).call.value(msg.value)(data);
    require(x);
  }
}