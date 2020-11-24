 

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

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 
contract ImplementationDirectory is ImplementationProvider, Ownable {
   
  event ImplementationChanged(string contractName, address implementation);

   
  mapping (string => address) internal implementations;

   
  function getImplementation(string contractName) public view returns (address) {
    return implementations[contractName];
  }

   
  function setImplementation(string contractName, address implementation) public onlyOwner {
    require(AddressUtils.isContract(implementation), "Cannot set implementation in directory with a non-contract address");
    implementations[contractName] = implementation;
    emit ImplementationChanged(contractName, implementation);
  }

   
  function unsetImplementation(string contractName) public onlyOwner {
    implementations[contractName] = address(0);
    emit ImplementationChanged(contractName, address(0));
  }
}

 

 
contract AppDirectory is ImplementationDirectory {
   
  event StdlibChanged(address newStdlib);

   
  ImplementationProvider public stdlib;

   
  constructor(ImplementationProvider _stdlib) public {
    stdlib = _stdlib;
  }

   
  function getImplementation(string contractName) public view returns (address) {
    address implementation = super.getImplementation(contractName);
    if(implementation != address(0)) return implementation;
    if(stdlib != address(0)) return stdlib.getImplementation(contractName);
    return address(0);
  }

   
  function setStdlib(ImplementationProvider _stdlib) public onlyOwner {
    stdlib = _stdlib;
    emit StdlibChanged(_stdlib);
  }
}