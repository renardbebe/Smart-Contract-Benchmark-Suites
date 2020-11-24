 

 

pragma solidity ^0.4.24;

 
interface ImplementationProvider {
   
  function getImplementation(string contractName) public view returns (address);
}

 

pragma solidity ^0.4.23;


 
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

 

pragma solidity ^0.4.24;


 
contract Package is Ownable {
   
  event VersionAdded(uint64[3] semanticVersion, address contractAddress, bytes contentURI);

  struct Version {
    uint64[3] semanticVersion;
    address contractAddress;
    bytes contentURI; 
  }

  mapping (bytes32 => Version) internal versions;
  mapping (uint64 => bytes32) internal majorToLatestVersion;
  uint64 internal latestMajor;

   
  function getVersion(uint64[3] semanticVersion) public view returns (address contractAddress, bytes contentURI) {
    Version storage version = versions[semanticVersionHash(semanticVersion)];
    return (version.contractAddress, version.contentURI); 
  }

   
  function getContract(uint64[3] semanticVersion) public view returns (address contractAddress) {
    Version storage version = versions[semanticVersionHash(semanticVersion)];
    return version.contractAddress;
  }

   
  function addVersion(uint64[3] semanticVersion, address contractAddress, bytes contentURI) public onlyOwner {
    require(contractAddress != address(0), "Contract address is required");
    require(!hasVersion(semanticVersion), "Given version is already registered in package");
    require(!semanticVersionIsZero(semanticVersion), "Version must be non zero");

     
    bytes32 versionId = semanticVersionHash(semanticVersion);
    versions[versionId] = Version(semanticVersion, contractAddress, contentURI);
    
     
    uint64 major = semanticVersion[0];
    if (major > latestMajor) {
      latestMajor = semanticVersion[0];
    }

     
    uint64 minor = semanticVersion[1];
    uint64 patch = semanticVersion[2];
    uint64[3] latestVersionForMajor = versions[majorToLatestVersion[major]].semanticVersion;
    if (semanticVersionIsZero(latestVersionForMajor)  
       || (minor > latestVersionForMajor[1])  
       || (minor == latestVersionForMajor[1] && patch > latestVersionForMajor[2])  
       ) { 
      majorToLatestVersion[major] = versionId;
    }

    emit VersionAdded(semanticVersion, contractAddress, contentURI);
  }

   
  function hasVersion(uint64[3] semanticVersion) public view returns (bool) {
    Version storage version = versions[semanticVersionHash(semanticVersion)];
    return address(version.contractAddress) != address(0);
  }

   
  function getLatest() public view returns (uint64[3] semanticVersion, address contractAddress, bytes contentURI) {
    return getLatestByMajor(latestMajor);
  }

   
  function getLatestByMajor(uint64 major) public view returns (uint64[3] semanticVersion, address contractAddress, bytes contentURI) {
    Version storage version = versions[majorToLatestVersion[major]];
    return (version.semanticVersion, version.contractAddress, version.contentURI); 
  }

  function semanticVersionHash(uint64[3] version) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(version[0], version[1], version[2]));
  }

  function semanticVersionIsZero(uint64[3] version) internal pure returns (bool) {
    return version[0] == 0 && version[1] == 0 && version[2] == 0;
  }
}

 

pragma solidity ^0.4.24;

 
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

 

pragma solidity ^0.4.23;


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 

pragma solidity ^0.4.24;



 
contract UpgradeabilityProxy is Proxy {
   
  event Upgraded(address indexed implementation);

   
  bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

   
  constructor(address _implementation, bytes _data) public payable {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));
    _setImplementation(_implementation);
    if(_data.length > 0) {
      require(_implementation.delegatecall(_data));
    }
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

 

pragma solidity ^0.4.24;


 
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

   
  constructor(address _implementation, address _admin, bytes _data) UpgradeabilityProxy(_implementation, _data) public payable {
    assert(ADMIN_SLOT == keccak256("org.zeppelinos.proxy.admin"));

    _setAdmin(_admin);
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
    require(newImplementation.delegatecall(data));
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

 

pragma solidity ^0.4.24;





 
contract App is Ownable {
   
  event ProxyCreated(address proxy);

   
  event PackageChanged(string providerName, address package, uint64[3] version);

   
  struct ProviderInfo {
    Package package;
    uint64[3] version;
  }

   
  mapping(string => ProviderInfo) internal providers;

   
  constructor() public { }

   
  function getProvider(string packageName) public view returns (ImplementationProvider provider) {
    ProviderInfo storage info = providers[packageName];
    if (address(info.package) == address(0)) return ImplementationProvider(0);
    return ImplementationProvider(info.package.getContract(info.version));
  }

   
  function getPackage(string packageName) public view returns (Package, uint64[3]) {
    ProviderInfo storage info = providers[packageName];
    return (info.package, info.version);
  }

   
  function setPackage(string packageName, Package package, uint64[3] version) public onlyOwner {
    require(package.hasVersion(version), "The requested version must be registered in the given package");
    providers[packageName] = ProviderInfo(package, version);
    emit PackageChanged(packageName, package, version);
  }

   
  function unsetPackage(string packageName) public onlyOwner {
    require(address(providers[packageName].package) != address(0), "Package to unset not found");
    delete providers[packageName];
    emit PackageChanged(packageName, address(0), [uint64(0), uint64(0), uint64(0)]);
  }

   
  function getImplementation(string packageName, string contractName) public view returns (address) {
    ImplementationProvider provider = getProvider(packageName);
    if (address(provider) == address(0)) return address(0);
    return provider.getImplementation(contractName);
  }

   
   function create(string packageName, string contractName, address admin, bytes data) payable public returns (AdminUpgradeabilityProxy) {
     address implementation = getImplementation(packageName, contractName);
     AdminUpgradeabilityProxy proxy = (new AdminUpgradeabilityProxy).value(msg.value)(implementation, admin, data);
     emit ProxyCreated(proxy);
     return proxy;
  }
}