 

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

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
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

 
contract Ownable {
  address public owner;
  address public pendingOwner;


  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
    pendingOwner = address(0);
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    pendingOwner = _newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }


}

 
contract RegulatorStorage is Ownable {
    
     

     
    struct Permission {
        string name;  
        string description;  
        string contract_name;  
        bool active;  
    }

     
    bytes4 public constant MINT_SIG = bytes4(keccak256("mint(address,uint256)"));
    bytes4 public constant MINT_CUSD_SIG = bytes4(keccak256("mintCUSD(address,uint256)"));
    bytes4 public constant DESTROY_BLACKLISTED_TOKENS_SIG = bytes4(keccak256("destroyBlacklistedTokens(address,uint256)"));
    bytes4 public constant APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG = bytes4(keccak256("approveBlacklistedAddressSpender(address)"));
    bytes4 public constant BLACKLISTED_SIG = bytes4(keccak256("blacklisted()"));

     

     
    mapping (bytes4 => Permission) public permissions;
     
    mapping (address => bool) public validators;
     
    mapping (address => mapping (bytes4 => bool)) public userPermissions;

     
    event PermissionAdded(bytes4 methodsignature);
    event PermissionRemoved(bytes4 methodsignature);
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);

     
     
    modifier onlyValidator() {
        require (isValidator(msg.sender), "Sender must be validator");
        _;
    }

     
    function addPermission(
        bytes4 _methodsignature, 
        string _permissionName, 
        string _permissionDescription, 
        string _contractName) public onlyValidator { 
        Permission memory p = Permission(_permissionName, _permissionDescription, _contractName, true);
        permissions[_methodsignature] = p;
        emit PermissionAdded(_methodsignature);
    }

     
    function removePermission(bytes4 _methodsignature) public onlyValidator {
        permissions[_methodsignature].active = false;
        emit PermissionRemoved(_methodsignature);
    }
    
     
    function setUserPermission(address _who, bytes4 _methodsignature) public onlyValidator {
        require(permissions[_methodsignature].active, "Permission being set must be for a valid method signature");
        userPermissions[_who][_methodsignature] = true;
    }

     
    function removeUserPermission(address _who, bytes4 _methodsignature) public onlyValidator {
        require(permissions[_methodsignature].active, "Permission being removed must be for a valid method signature");
        userPermissions[_who][_methodsignature] = false;
    }

     
    function addValidator(address _validator) public onlyOwner {
        validators[_validator] = true;
        emit ValidatorAdded(_validator);
    }

     
    function removeValidator(address _validator) public onlyOwner {
        validators[_validator] = false;
        emit ValidatorRemoved(_validator);
    }

     
    function isValidator(address _validator) public view returns (bool) {
        return validators[_validator];
    }

     
    function isPermission(bytes4 _methodsignature) public view returns (bool) {
        return permissions[_methodsignature].active;
    }

     
    function getPermission(bytes4 _methodsignature) public view returns 
        (string name, 
         string description, 
         string contract_name,
         bool active) {
        return (permissions[_methodsignature].name,
                permissions[_methodsignature].description,
                permissions[_methodsignature].contract_name,
                permissions[_methodsignature].active);
    }

     
    function hasUserPermission(address _who, bytes4 _methodsignature) public view returns (bool) {
        return userPermissions[_who][_methodsignature];
    }
}

 
contract RegulatorProxy is UpgradeabilityProxy, RegulatorStorage {

    
     
    constructor(address _implementation) public UpgradeabilityProxy(_implementation) {}

     
    function upgradeTo(address newImplementation) public onlyOwner {
        _upgradeTo(newImplementation);

    }

       
    function implementation() public view returns (address) {
        return _implementation();
    }
}