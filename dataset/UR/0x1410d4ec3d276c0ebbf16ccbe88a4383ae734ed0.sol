 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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

 
contract CarbonDollarStorage is Ownable {
    using SafeMath for uint256;

     
     
    mapping (address => uint256) public fees;
     
    uint256 public defaultFee;
     
    mapping (address => bool) public whitelist;


     
    event DefaultFeeChanged(uint256 oldFee, uint256 newFee);
    event FeeChanged(address indexed stablecoin, uint256 oldFee, uint256 newFee);
    event FeeRemoved(address indexed stablecoin, uint256 oldFee);
    event StablecoinAdded(address indexed stablecoin);
    event StablecoinRemoved(address indexed stablecoin);

     
    function setDefaultFee(uint256 _fee) public onlyOwner {
        uint256 oldFee = defaultFee;
        defaultFee = _fee;
        if (oldFee != defaultFee)
            emit DefaultFeeChanged(oldFee, _fee);
    }
    
     
    function setFee(address _stablecoin, uint256 _fee) public onlyOwner {
        uint256 oldFee = fees[_stablecoin];
        fees[_stablecoin] = _fee;
        if (oldFee != _fee)
            emit FeeChanged(_stablecoin, oldFee, _fee);
    }

     
    function removeFee(address _stablecoin) public onlyOwner {
        uint256 oldFee = fees[_stablecoin];
        fees[_stablecoin] = 0;
        if (oldFee != 0)
            emit FeeRemoved(_stablecoin, oldFee);
    }

     
    function addStablecoin(address _stablecoin) public onlyOwner {
        whitelist[_stablecoin] = true;
        emit StablecoinAdded(_stablecoin);
    }

     
    function removeStablecoin(address _stablecoin) public onlyOwner {
        whitelist[_stablecoin] = false;
        emit StablecoinRemoved(_stablecoin);
    }


     
    function computeStablecoinFee(uint256 _amount, address _stablecoin) public view returns (uint256) {
        uint256 fee = fees[_stablecoin];
        return computeFee(_amount, fee);
    }

     
    function computeFee(uint256 _amount, uint256 _fee) public pure returns (uint256) {
        return _amount.mul(_fee).div(1000);
    }
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 
contract PermissionedTokenStorage is Ownable {
    using SafeMath for uint256;

     
    mapping (address => mapping (address => uint256)) public allowances;
    mapping (address => uint256) public balances;
    uint256 public totalSupply;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowances[_tokenHolder][_spender] = allowances[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowances[_tokenHolder][_spender] = allowances[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowances[_tokenHolder][_spender] = _value;
    }

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balances[_addr] = balances[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balances[_addr] = balances[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balances[_addr] = _value;
    }

    function addTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = totalSupply.add(_value);
    }

    function subTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = totalSupply.sub(_value);
    }

    function setTotalSupply(uint256 _value) public onlyOwner {
        totalSupply = _value;
    }

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

 
contract PermissionedTokenProxy is UpgradeabilityProxy, Ownable {
    
    PermissionedTokenStorage public tokenStorage;
    Regulator public regulator;

     
    event ChangedRegulator(address indexed oldRegulator, address indexed newRegulator );


     
    constructor(address _implementation, address _regulator) 
    UpgradeabilityProxy(_implementation) public {
        regulator = Regulator(_regulator);
        tokenStorage = new PermissionedTokenStorage();
    }

     
    function upgradeTo(address newImplementation) public onlyOwner {
        _upgradeTo(newImplementation);
    }


     
    function implementation() public view returns (address) {
        return _implementation();
    }
}

 
contract CarbonDollarRegulator is Regulator {

     
    function isWhitelistedUser(address _who) public view returns(bool) {
        return (hasUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG) 
        && hasUserPermission(_who, BURN_CARBON_DOLLAR_SIG) 
        && !hasUserPermission(_who, BLACKLISTED_SIG));
    }

    function isBlacklistedUser(address _who) public view returns(bool) {
        return (!hasUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG) 
        && !hasUserPermission(_who, BURN_CARBON_DOLLAR_SIG) 
        && hasUserPermission(_who, BLACKLISTED_SIG));
    }

    function isNonlistedUser(address _who) public view returns(bool) {
        return (!hasUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG) 
        && !hasUserPermission(_who, BURN_CARBON_DOLLAR_SIG) 
        && !hasUserPermission(_who, BLACKLISTED_SIG));
    }

     
    
     

     
     
    function _setWhitelistedUser(address _who) internal {
        require(isPermission(CONVERT_CARBON_DOLLAR_SIG), "Converting CUSD not supported");
        require(isPermission(BURN_CARBON_DOLLAR_SIG), "Burning CUSD not supported");
        require(isPermission(BLACKLISTED_SIG), "Blacklisting not supported");
        setUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG);
        setUserPermission(_who, BURN_CARBON_DOLLAR_SIG);
        removeUserPermission(_who, BLACKLISTED_SIG);
        emit LogWhitelistedUser(_who);
    }

    function _setBlacklistedUser(address _who) internal {
        require(isPermission(CONVERT_CARBON_DOLLAR_SIG), "Converting CUSD not supported");
        require(isPermission(BURN_CARBON_DOLLAR_SIG), "Burning CUSD not supported");
        require(isPermission(BLACKLISTED_SIG), "Blacklisting not supported");
        removeUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG);
        removeUserPermission(_who, BURN_CARBON_DOLLAR_SIG);
        setUserPermission(_who, BLACKLISTED_SIG);
        emit LogBlacklistedUser(_who);
    }

    function _setNonlistedUser(address _who) internal {
        require(isPermission(CONVERT_CARBON_DOLLAR_SIG), "Converting CUSD not supported");
        require(isPermission(BURN_CARBON_DOLLAR_SIG), "Burning CUSD not supported");
        require(isPermission(BLACKLISTED_SIG), "Blacklisting not supported");
        removeUserPermission(_who, CONVERT_CARBON_DOLLAR_SIG);
        removeUserPermission(_who, BURN_CARBON_DOLLAR_SIG);
        removeUserPermission(_who, BLACKLISTED_SIG);
        emit LogNonlistedUser(_who);
    }
}

 
contract CarbonDollarProxy is PermissionedTokenProxy {
    
    CarbonDollarStorage public tokenStorage_CD;

     
    constructor(address _implementation, address _regulator) public PermissionedTokenProxy(_implementation, _regulator) {
         
        regulator = CarbonDollarRegulator(_regulator);

        tokenStorage_CD = new CarbonDollarStorage();

    }
}