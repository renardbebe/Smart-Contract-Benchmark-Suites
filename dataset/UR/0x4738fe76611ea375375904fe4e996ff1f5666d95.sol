 

pragma solidity ^0.4.24;

 
interface IRegistry {
     
    event ProxyCreated(address proxy);

     
    event VersionAdded(string version, address implementation);

     
    function addVersion(string version, address implementation) external;

     
    function getVersion(string version) external view returns (address);
}

 
contract Proxy {

     
    function implementation() public view returns (address);

     
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



 
contract UpgradeabilityStorage {
     
    IRegistry internal registry;

     
    address internal _implementation;

     
    function implementation() public view returns (address) {
        return _implementation;
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







 
contract Upgradeable is UpgradeabilityStorage {
     
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}







 
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage, Ownable {

     
    constructor(string _version) public {
        registry = IRegistry(msg.sender);
        upgradeTo(_version);
    }

     
    function upgradeTo(string _version) public onlyOwner {
        _implementation = registry.getVersion(_version);
    }

}


 
contract Registry is IRegistry, Ownable {
     
    mapping (string => address) internal versions;

     
    function addVersion(string version, address implementation) external onlyOwner {
        require(versions[version] == 0x0);
        versions[version] = implementation;
        emit VersionAdded(version, implementation);
    }

     
    function getVersion(string version) external view returns (address) {
        return versions[version];
    }

     
    function createProxy(string version) public payable onlyOwner returns (UpgradeabilityProxy) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(version);
        Upgradeable(proxy).initialize.value(msg.value)(msg.sender);
        emit ProxyCreated(proxy);
        return proxy;
    }
}