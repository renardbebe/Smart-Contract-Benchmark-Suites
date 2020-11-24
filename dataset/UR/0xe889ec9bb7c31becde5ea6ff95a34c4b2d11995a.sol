 

 

pragma solidity ^0.5.0;

 
contract ImplementationProvider {
   
  function getImplementation(string memory contractName) public view returns (address);
}

 

pragma solidity ^0.5.0;

 
contract ZOSLibOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
library ZOSLibAddress {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.0;




 
contract ImplementationDirectory is ImplementationProvider, ZOSLibOwnable {
   
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

   
  function getImplementation(string memory contractName) public view returns (address) {
    return implementations[contractName];
  }

   
  function setImplementation(string memory contractName, address implementation) public onlyOwner whenNotFrozen {
    require(ZOSLibAddress.isContract(implementation), "Cannot set implementation in directory with a non-contract address");
    implementations[contractName] = implementation;
    emit ImplementationChanged(contractName, implementation);
  }

   
  function unsetImplementation(string memory contractName) public onlyOwner whenNotFrozen {
    implementations[contractName] = address(0);
    emit ImplementationChanged(contractName, address(0));
  }
}