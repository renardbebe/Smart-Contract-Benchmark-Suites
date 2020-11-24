 

 
contract Proxy {
   
  function implementation() public view returns (address);
  
   
  function version() public view returns (string);

   
  function () payable public {
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
   
  event Upgraded(address indexed implementation, string version);

   
  bytes32 private constant implementationPosition = keccak256("cpc.app.proxy.implementation");
  
    
  string internal _version;

   
  constructor() public {}
  
  
   
    function version() public view returns (string) {
        return _version;
    }

   
  function implementation() public view returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

   
  function _setImplementation(address _newImplementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, _newImplementation)
    }
  }

   
  function _upgradeTo(address _newImplementation, string _newVersion) internal {
    address currentImplementation = implementation();
    require(currentImplementation != _newImplementation);
    _setImplementation(_newImplementation);
    _version = _newVersion;
    emit Upgraded( _newImplementation, _newVersion);
  }
}


 
contract CpcProxy is UpgradeabilityProxy {
   
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

   
  bytes32 private constant proxyOwnerPosition = keccak256("cpc.app.proxy.owner");

   
  constructor(address _implementation, string _version) public {
    _setUpgradeabilityOwner(msg.sender);
    _upgradeTo(_implementation, _version);
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

   
  function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
    require(_newOwner != address(0));
    _setUpgradeabilityOwner(_newOwner);
    emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
  }

   
  function upgradeTo(address _implementation, string _newVersion) public onlyProxyOwner {
    _upgradeTo(_implementation, _newVersion);
  }

   
  function upgradeToAndCall(address _implementation, string _newVersion, bytes _data) payable public onlyProxyOwner {
    _upgradeTo(_implementation, _newVersion);
    require(address(this).call.value(msg.value)(_data));
  }

   
  function _setUpgradeabilityOwner(address _newProxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, _newProxyOwner)
    }
  }
}