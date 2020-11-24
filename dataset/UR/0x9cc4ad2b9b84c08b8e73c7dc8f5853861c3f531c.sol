 

pragma solidity ^0.4.24;

 

 
interface ImplementationProvider {
   
  function getImplementation(string contractName) public view returns (address);
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