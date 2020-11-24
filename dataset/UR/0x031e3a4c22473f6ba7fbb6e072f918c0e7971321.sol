 

 

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

 

pragma solidity ^0.4.23;


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 

pragma solidity ^0.4.24;




 
contract ImplementationDirectory is ImplementationProvider, Ownable {
   
  event ImplementationChanged(string contractName, address indexed implementation);

   
  event Frozen();

   
  mapping (string => address) internal implementations;

   
  bool public frozen;

   
  modifier whenNotFrozen() {
    require(!frozen, "Cannot perform action for a frozen implementation directory");
    _;
  }

   
  function freeze() onlyOwner whenNotFrozen public {
    frozen = true;
    emit Frozen();
  }

   
  function getImplementation(string contractName) public view returns (address) {
    return implementations[contractName];
  }

   
  function setImplementation(string contractName, address implementation) public onlyOwner whenNotFrozen {
    require(AddressUtils.isContract(implementation), "Cannot set implementation in directory with a non-contract address");
    implementations[contractName] = implementation;
    emit ImplementationChanged(contractName, implementation);
  }

   
  function unsetImplementation(string contractName) public onlyOwner whenNotFrozen {
    implementations[contractName] = address(0);
    emit ImplementationChanged(contractName, address(0));
  }
}