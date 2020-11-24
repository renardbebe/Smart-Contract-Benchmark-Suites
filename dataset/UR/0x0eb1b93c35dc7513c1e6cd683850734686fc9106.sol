 

pragma solidity ^0.4.24;

 
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
    bytes4 public constant CONVERT_WT_SIG = bytes4(keccak256("convertWT(uint256)"));
    bytes4 public constant BURN_SIG = bytes4(keccak256("burn(uint256)"));
    bytes4 public constant CONVERT_CARBON_DOLLAR_SIG = bytes4(keccak256("convertCarbonDollar(address,uint256)"));
    bytes4 public constant BURN_CARBON_DOLLAR_SIG = bytes4(keccak256("burnCarbonDollar(address,uint256)"));
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

 
contract Regulator is RegulatorStorage {
    
     
     
    modifier onlyValidator() {
        require (isValidator(msg.sender), "Sender must be validator");
        _;
    }

     
    event LogWhitelistedUser(address indexed who);
    event LogBlacklistedUser(address indexed who);
    event LogNonlistedUser(address indexed who);
    event LogSetMinter(address indexed who);
    event LogRemovedMinter(address indexed who);
    event LogSetBlacklistDestroyer(address indexed who);
    event LogRemovedBlacklistDestroyer(address indexed who);
    event LogSetBlacklistSpender(address indexed who);
    event LogRemovedBlacklistSpender(address indexed who);

     
    function setMinter(address _who) public onlyValidator {
        _setMinter(_who);
    }

     
    function removeMinter(address _who) public onlyValidator {
        _removeMinter(_who);
    }

     
    function setBlacklistSpender(address _who) public onlyValidator {
        require(isPermission(APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG), "Blacklist spending not supported by token");
        setUserPermission(_who, APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG);
        emit LogSetBlacklistSpender(_who);
    }
    
     
    function removeBlacklistSpender(address _who) public onlyValidator {
        require(isPermission(APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG), "Blacklist spending not supported by token");
        removeUserPermission(_who, APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG);
        emit LogRemovedBlacklistSpender(_who);
    }

     
    function setBlacklistDestroyer(address _who) public onlyValidator {
        require(isPermission(DESTROY_BLACKLISTED_TOKENS_SIG), "Blacklist token destruction not supported by token");
        setUserPermission(_who, DESTROY_BLACKLISTED_TOKENS_SIG);
        emit LogSetBlacklistDestroyer(_who);
    }
    

     
    function removeBlacklistDestroyer(address _who) public onlyValidator {
        require(isPermission(DESTROY_BLACKLISTED_TOKENS_SIG), "Blacklist token destruction not supported by token");
        removeUserPermission(_who, DESTROY_BLACKLISTED_TOKENS_SIG);
        emit LogRemovedBlacklistDestroyer(_who);
    }

     
    function setWhitelistedUser(address _who) public onlyValidator {
        _setWhitelistedUser(_who);
    }

     
    function setBlacklistedUser(address _who) public onlyValidator {
        _setBlacklistedUser(_who);
    }

     
    function setNonlistedUser(address _who) public onlyValidator {
        _setNonlistedUser(_who);
    }

     
    function isWhitelistedUser(address _who) public view returns (bool) {
        return (hasUserPermission(_who, BURN_SIG) && !hasUserPermission(_who, BLACKLISTED_SIG));
    }

     
    function isBlacklistedUser(address _who) public view returns (bool) {
        return (!hasUserPermission(_who, BURN_SIG) && hasUserPermission(_who, BLACKLISTED_SIG));
    }

     
    function isNonlistedUser(address _who) public view returns (bool) {
        return (!hasUserPermission(_who, BURN_SIG) && !hasUserPermission(_who, BLACKLISTED_SIG));
    }

     
    function isBlacklistSpender(address _who) public view returns (bool) {
        return hasUserPermission(_who, APPROVE_BLACKLISTED_ADDRESS_SPENDER_SIG);
    }

     
    function isBlacklistDestroyer(address _who) public view returns (bool) {
        return hasUserPermission(_who, DESTROY_BLACKLISTED_TOKENS_SIG);
    }

     
    function isMinter(address _who) public view returns (bool) {
        return hasUserPermission(_who, MINT_SIG);
    }

     

    function _setMinter(address _who) internal {
        require(isPermission(MINT_SIG), "Minting not supported by token");
        setUserPermission(_who, MINT_SIG);
        emit LogSetMinter(_who);
    }

    function _removeMinter(address _who) internal {
        require(isPermission(MINT_SIG), "Minting not supported by token");
        removeUserPermission(_who, MINT_SIG);
        emit LogRemovedMinter(_who);
    }

    function _setNonlistedUser(address _who) internal {
        require(isPermission(BURN_SIG), "Burn method not supported by token");
        require(isPermission(BLACKLISTED_SIG), "Self-destruct method not supported by token");
        removeUserPermission(_who, BURN_SIG);
        removeUserPermission(_who, BLACKLISTED_SIG);
        emit LogNonlistedUser(_who);
    }

    function _setBlacklistedUser(address _who) internal {
        require(isPermission(BURN_SIG), "Burn method not supported by token");
        require(isPermission(BLACKLISTED_SIG), "Self-destruct method not supported by token");
        removeUserPermission(_who, BURN_SIG);
        setUserPermission(_who, BLACKLISTED_SIG);
        emit LogBlacklistedUser(_who);
    }

    function _setWhitelistedUser(address _who) internal {
        require(isPermission(BURN_SIG), "Burn method not supported by token");
        require(isPermission(BLACKLISTED_SIG), "Self-destruct method not supported by token");
        setUserPermission(_who, BURN_SIG);
        removeUserPermission(_who, BLACKLISTED_SIG);
        emit LogWhitelistedUser(_who);
    }
}

 
contract WhitelistedTokenRegulator is Regulator {

    function isMinter(address _who) public view returns (bool) {
        return (super.isMinter(_who) && hasUserPermission(_who, MINT_CUSD_SIG));
    }

     

    function isWhitelistedUser(address _who) public view returns (bool) {
        return (hasUserPermission(_who, CONVERT_WT_SIG) && super.isWhitelistedUser(_who));
    }

    function isBlacklistedUser(address _who) public view returns (bool) {
        return (!hasUserPermission(_who, CONVERT_WT_SIG) && super.isBlacklistedUser(_who));
    }

    function isNonlistedUser(address _who) public view returns (bool) {
        return (!hasUserPermission(_who, CONVERT_WT_SIG) && super.isNonlistedUser(_who));
    }   

     

     
     
    function _setMinter(address _who) internal {
        require(isPermission(MINT_CUSD_SIG), "Minting to CUSD not supported by token");
        setUserPermission(_who, MINT_CUSD_SIG);
        super._setMinter(_who);
    }

    function _removeMinter(address _who) internal {
        require(isPermission(MINT_CUSD_SIG), "Minting to CUSD not supported by token");
        removeUserPermission(_who, MINT_CUSD_SIG);
        super._removeMinter(_who);
    }

     

     
     
    function _setWhitelistedUser(address _who) internal {
        require(isPermission(CONVERT_WT_SIG), "Converting to CUSD not supported by token");
        setUserPermission(_who, CONVERT_WT_SIG);
        super._setWhitelistedUser(_who);
    }

    function _setBlacklistedUser(address _who) internal {
        require(isPermission(CONVERT_WT_SIG), "Converting to CUSD not supported by token");
        removeUserPermission(_who, CONVERT_WT_SIG);
        super._setBlacklistedUser(_who);
    }

    function _setNonlistedUser(address _who) internal {
        require(isPermission(CONVERT_WT_SIG), "Converting to CUSD not supported by token");
        removeUserPermission(_who, CONVERT_WT_SIG);
        super._setNonlistedUser(_who);
    }

}