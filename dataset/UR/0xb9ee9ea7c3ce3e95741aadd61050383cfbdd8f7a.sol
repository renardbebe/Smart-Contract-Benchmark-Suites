 

pragma solidity ^0.4.24;

 

 
interface ImplementationProvider {
   
  function getImplementation(string contractName) public view returns (address);
}

 

 
contract Proxy {
   
  function () payable external {
    _fallback();
  }

   
  function _implementation() internal view returns (address);

   
  function _delegate(address implementation) internal {
    assembly {
       
       
       
      calldatacopy(0, 0, calldatasize)

       
       
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

       
      returndatacopy(0, 0, returndatasize)

      switch result
       
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

   
  function _willFallback() internal {
  }

   
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 
contract UpgradeabilityProxy is Proxy {
   
  event Upgraded(address implementation);

   
  bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

   
  constructor(address _implementation) public {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));

    _setImplementation(_implementation);
  }

   
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

   
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

   
  function _setImplementation(address newImplementation) private {
    require(AddressUtils.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

 

 
contract AdminUpgradeabilityProxy is UpgradeabilityProxy {
   
  event AdminChanged(address previousAdmin, address newAdmin);

   
  bytes32 private constant ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;

   
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

   
  constructor(address _implementation) UpgradeabilityProxy(_implementation) public {
    assert(ADMIN_SLOT == keccak256("org.zeppelinos.proxy.admin"));

    _setAdmin(msg.sender);
  }

   
  function admin() external view ifAdmin returns (address) {
    return _admin();
  }

   
  function implementation() external view ifAdmin returns (address) {
    return _implementation();
  }

   
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

   
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

   
  function upgradeToAndCall(address newImplementation, bytes data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    require(address(this).call.value(msg.value)(data));
  }

   
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

   
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

   
  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}

 

 
contract UpgradeabilityProxyFactory {
   
  event ProxyCreated(address proxy);

   
  function createProxy(address admin, address implementation) public returns (AdminUpgradeabilityProxy) {
    AdminUpgradeabilityProxy proxy = _createProxy(implementation);
    proxy.changeAdmin(admin);
    return proxy;
  }

   
  function createProxyAndCall(address admin, address implementation, bytes data) public payable returns (AdminUpgradeabilityProxy) {
    AdminUpgradeabilityProxy proxy = _createProxy(implementation);
    proxy.changeAdmin(admin);
    require(address(proxy).call.value(msg.value)(data));
    return proxy;
  }

   
  function _createProxy(address implementation) internal returns (AdminUpgradeabilityProxy) {
    AdminUpgradeabilityProxy proxy = new AdminUpgradeabilityProxy(implementation);
    emit ProxyCreated(proxy);
    return proxy;
  }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract BaseApp is Ownable {
   
  UpgradeabilityProxyFactory public factory;

   
  constructor(UpgradeabilityProxyFactory _factory) public {
    require(address(_factory) != address(0), "Cannot set the proxy factory of an app to the zero address");
    factory = _factory;
  }

   
  function getProvider() internal view returns (ImplementationProvider);

   
  function getImplementation(string contractName) public view returns (address) {
    return getProvider().getImplementation(contractName);
  }

   
  function create(string contractName) public returns (AdminUpgradeabilityProxy) {
    address implementation = getImplementation(contractName);
    return factory.createProxy(this, implementation);
  }

   
   function createAndCall(string contractName, bytes data) payable public returns (AdminUpgradeabilityProxy) {
    address implementation = getImplementation(contractName);
    return factory.createProxyAndCall.value(msg.value)(this, implementation, data);
  }

   
  function upgrade(AdminUpgradeabilityProxy proxy, string contractName) public onlyOwner {
    address implementation = getImplementation(contractName);
    proxy.upgradeTo(implementation);
  }

   
  function upgradeAndCall(AdminUpgradeabilityProxy proxy, string contractName, bytes data) payable public onlyOwner {
    address implementation = getImplementation(contractName);
    proxy.upgradeToAndCall.value(msg.value)(implementation, data);
  }

   
  function getProxyImplementation(AdminUpgradeabilityProxy proxy) public view returns (address) {
    return proxy.implementation();
  }

   
  function getProxyAdmin(AdminUpgradeabilityProxy proxy) public view returns (address) {
    return proxy.admin();
  }

   
  function changeProxyAdmin(AdminUpgradeabilityProxy proxy, address newAdmin) public onlyOwner {
    proxy.changeAdmin(newAdmin);
  }
}

 

 
contract Package is Ownable {
   
  event VersionAdded(string version, ImplementationProvider provider);

   
  mapping (string => ImplementationProvider) internal versions;

   
  function getVersion(string version) public view returns (ImplementationProvider) {
    ImplementationProvider provider = versions[version];
    return provider;
  }

   
  function addVersion(string version, ImplementationProvider provider) public onlyOwner {
    require(!hasVersion(version), "Given version is already registered in package");
    versions[version] = provider;
    emit VersionAdded(version, provider);
  }

   
  function hasVersion(string version) public view returns (bool) {
    return address(versions[version]) != address(0);
  }

   
  function getImplementation(string version, string contractName) public view returns (address) {
    ImplementationProvider provider = getVersion(version);
    return provider.getImplementation(contractName);
  }
}

 

 
contract PackagedApp is BaseApp {
   
  Package public package;
   
  string public version;

   
  constructor(Package _package, string _version, UpgradeabilityProxyFactory _factory) BaseApp(_factory) public {
    require(address(_package) != address(0), "Cannot set the package of an app to the zero address");
    require(_package.hasVersion(_version), "The requested version must be registered in the given package");
    package = _package;
    version = _version;
  }

   
  function setVersion(string newVersion) public onlyOwner {
    require(package.hasVersion(newVersion), "The requested version must be registered in the given package");
    version = newVersion;
  }

   
  function getProvider() internal view returns (ImplementationProvider) {
    return package.getVersion(version);
  }
}