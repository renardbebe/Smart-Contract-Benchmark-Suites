 

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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

contract Lockable is Ownable {

	 
	event Unlocked();
	event Locked();

	 
	bool public isMethodEnabled = false;

	 
	 
	modifier whenUnlocked() {
		require(isMethodEnabled);
		_;
	}

	 
	 
	function unlock() onlyOwner public {
		isMethodEnabled = true;
		emit Unlocked();
	}

	 
	function lock() onlyOwner public {
		isMethodEnabled = false;
		emit Locked();
	}

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

 
contract PermissionedToken is ERC20, Pausable, Lockable {
    using SafeMath for uint256;

     
    event DestroyedBlacklistedTokens(address indexed account, uint256 amount);
    event ApprovedBlacklistedAddressSpender(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ChangedRegulator(address indexed oldRegulator, address indexed newRegulator );

    PermissionedTokenStorage public tokenStorage;
    Regulator public regulator;

     
    constructor (address _regulator) public {
        regulator = Regulator(_regulator);
        tokenStorage = new PermissionedTokenStorage();
    }

     

     
    modifier requiresPermission() {
        require (regulator.hasUserPermission(msg.sender, msg.sig), "User does not have permission to execute function");
        _;
    }

     
    modifier transferFromConditionsRequired(address _from, address _to) {
        require(!regulator.isBlacklistedUser(_to), "Recipient cannot be blacklisted");
        
         
         
         
        bool is_origin_blacklisted = regulator.isBlacklistedUser(_from);

         
        bool sender_can_spend_from_blacklisted_address = regulator.isBlacklistSpender(msg.sender);
        require(!is_origin_blacklisted || sender_can_spend_from_blacklisted_address, "Origin cannot be blacklisted if spender is not an approved blacklist spender");
        _;
    }

     
    modifier userWhitelisted(address _user) {
        require(regulator.isWhitelistedUser(_user), "User must be whitelisted");
        _;
    }

     
    modifier userBlacklisted(address _user) {
        require(regulator.isBlacklistedUser(_user), "User must be blacklisted");
        _;
    }

     
    modifier userNotBlacklisted(address _user) {
        require(!regulator.isBlacklistedUser(_user), "User must not be blacklisted");
        _;
    }

     

     
    function mint(address _to, uint256 _amount) public requiresPermission whenNotPaused {
        _mint(_to, _amount);
    }

     
    function burn(uint256 _amount) public requiresPermission whenNotPaused {
        _burn(msg.sender, _amount);
    }

     
    function approve(address _spender, uint256 _value) 
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused whenUnlocked returns (bool) {
        tokenStorage.setAllowance(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) 
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        _increaseApproval(_spender, _addedValue, msg.sender);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) 
    public userNotBlacklisted(_spender) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        _decreaseApproval(_spender, _subtractedValue, msg.sender);
        return true;
    }

     
    function destroyBlacklistedTokens(address _who, uint256 _amount) public userBlacklisted(_who) whenNotPaused requiresPermission {
        tokenStorage.subBalance(_who, _amount);
        tokenStorage.subTotalSupply(_amount);
        emit DestroyedBlacklistedTokens(_who, _amount);
    }
     
    function approveBlacklistedAddressSpender(address _blacklistedAccount) 
    public userBlacklisted(_blacklistedAccount) whenNotPaused requiresPermission {
        tokenStorage.setAllowance(_blacklistedAccount, msg.sender, balanceOf(_blacklistedAccount));
        emit ApprovedBlacklistedAddressSpender(_blacklistedAccount, msg.sender, balanceOf(_blacklistedAccount));
    }

     
    function transfer(address _to, uint256 _amount) public userNotBlacklisted(_to) userNotBlacklisted(msg.sender) whenNotPaused returns (bool) {
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(msg.sender),"not enough balance to transfer");

        tokenStorage.subBalance(msg.sender, _amount);
        tokenStorage.addBalance(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) 
    public whenNotPaused transferFromConditionsRequired(_from, _to) returns (bool) {
        require(_amount <= allowance(_from, msg.sender),"not enough allowance to transfer");
        require(_to != address(0),"to address cannot be 0x0");
        require(_amount <= balanceOf(_from),"not enough balance to transfer");
        
        tokenStorage.subAllowance(_from, msg.sender, _amount);
        tokenStorage.addBalance(_to, _amount);
        tokenStorage.subBalance(_from, _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

     
    function setRegulator(address _newRegulator) public onlyOwner {
        require(_newRegulator != address(regulator), "Must be a new regulator");
        require(AddressUtils.isContract(_newRegulator), "Cannot set a regulator storage to a non-contract address");
        address old = address(regulator);
        regulator = Regulator(_newRegulator);
        emit ChangedRegulator(old, _newRegulator);
    }

     
    function blacklisted() public view requiresPermission returns (bool) {
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return tokenStorage.allowances(owner, spender);
    }

    function totalSupply() public view returns (uint256) {
        return tokenStorage.totalSupply();
    }

    function balanceOf(address _addr) public view returns (uint256) {
        return tokenStorage.balances(_addr);
    }


     
    
    function _decreaseApproval(address _spender, uint256 _subtractedValue, address _tokenHolder) internal {
        uint256 oldValue = allowance(_tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            tokenStorage.setAllowance(_tokenHolder, _spender, 0);
        } else {
            tokenStorage.subAllowance(_tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(_tokenHolder, _spender, allowance(_tokenHolder, _spender));
    }

    function _increaseApproval(address _spender, uint256 _addedValue, address _tokenHolder) internal {
        tokenStorage.addAllowance(_tokenHolder, _spender, _addedValue);
        emit Approval(_tokenHolder, _spender, allowance(_tokenHolder, _spender));
    }

    function _burn(address _tokensOf, uint256 _amount) internal {
        require(_amount <= balanceOf(_tokensOf),"not enough balance to burn");
         
         
        tokenStorage.subBalance(_tokensOf, _amount);
        tokenStorage.subTotalSupply(_amount);
        emit Burn(_tokensOf, _amount);
        emit Transfer(_tokensOf, address(0), _amount);
    }

    function _mint(address _to, uint256 _amount) internal userWhitelisted(_to) {
        tokenStorage.addTotalSupply(_amount);
        tokenStorage.addBalance(_to, _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
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

 
contract CarbonDollar is PermissionedToken {
    
     

    event ConvertedToWT(address indexed user, uint256 amount);
    event BurnedCUSD(address indexed user, uint256 feedAmount, uint256 chargedFee);
    
     
    modifier requiresWhitelistedToken() {
        require(isWhitelisted(msg.sender), "Sender must be a whitelisted token contract");
        _;
    }

    CarbonDollarStorage public tokenStorage_CD;

     
    constructor(address _regulator) public PermissionedToken(_regulator) {

         
        regulator = CarbonDollarRegulator(_regulator);

        tokenStorage_CD = new CarbonDollarStorage();
    }

     
    function listToken(address _stablecoin) public onlyOwner whenNotPaused {
        tokenStorage_CD.addStablecoin(_stablecoin); 
    }

     
    function unlistToken(address _stablecoin) public onlyOwner whenNotPaused {
        tokenStorage_CD.removeStablecoin(_stablecoin);
    }

     
    function setFee(address stablecoin, uint256 _newFee) public onlyOwner whenNotPaused {
        require(isWhitelisted(stablecoin), "Stablecoin must be whitelisted prior to setting conversion fee");
        tokenStorage_CD.setFee(stablecoin, _newFee);
    }

     
    function removeFee(address stablecoin) public onlyOwner whenNotPaused {
        require(isWhitelisted(stablecoin), "Stablecoin must be whitelisted prior to setting conversion fee");
       tokenStorage_CD.removeFee(stablecoin);
    }

     
    function setDefaultFee(uint256 _newFee) public onlyOwner whenNotPaused {
        tokenStorage_CD.setDefaultFee(_newFee);
    }

     
    function mint(address _to, uint256 _amount) public requiresWhitelistedToken whenNotPaused {
        _mint(_to, _amount);
    }

     
    function convertCarbonDollar(address stablecoin, uint256 _amount) public requiresPermission whenNotPaused  {
        require(isWhitelisted(stablecoin), "Stablecoin must be whitelisted prior to setting conversion fee");
        WhitelistedToken whitelisted = WhitelistedToken(stablecoin);
        require(whitelisted.balanceOf(address(this)) >= _amount, "Carbon escrow account in WT0 doesn't have enough tokens for burning");
 
         
         
        uint256 chargedFee = tokenStorage_CD.computeFee(_amount, computeFeeRate(stablecoin));
        uint256 feedAmount = _amount.sub(chargedFee);
        _burn(msg.sender, _amount);
        require(whitelisted.transfer(msg.sender, feedAmount));
        whitelisted.burn(chargedFee);
        _mint(address(this), chargedFee);
        emit ConvertedToWT(msg.sender, _amount);
    }

      
    function burnCarbonDollar(address stablecoin, uint256 _amount) public requiresPermission whenNotPaused {
        require(isWhitelisted(stablecoin), "Stablecoin must be whitelisted prior to setting conversion fee");
        WhitelistedToken whitelisted = WhitelistedToken(stablecoin);
        require(whitelisted.balanceOf(address(this)) >= _amount, "Carbon escrow account in WT0 doesn't have enough tokens for burning");
 
         
        uint256 chargedFee = tokenStorage_CD.computeFee(_amount, computeFeeRate(stablecoin));
        uint256 feedAmount = _amount.sub(chargedFee);
        _burn(msg.sender, _amount);
        whitelisted.burn(_amount);
        _mint(address(this), chargedFee);
        emit BurnedCUSD(msg.sender, feedAmount, chargedFee);  
    }

     
    function releaseCarbonDollar(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount <= balanceOf(address(this)),"not enough balance to transfer");

        tokenStorage.subBalance(address(this), _amount);
        tokenStorage.addBalance(msg.sender, _amount);
        emit Transfer(address(this), msg.sender, _amount);
        return true;
    }

     
    function computeFeeRate(address stablecoin) public view returns (uint256 feeRate) {
        if (getFee(stablecoin) > 0) 
            feeRate = getFee(stablecoin);
        else
            feeRate = getDefaultFee();
    }

     
    function isWhitelisted(address _stablecoin) public view returns (bool) {
        return tokenStorage_CD.whitelist(_stablecoin);
    }

     
    function getFee(address stablecoin) public view returns (uint256) {
        return tokenStorage_CD.fees(stablecoin);
    }

     
    function getDefaultFee() public view returns (uint256) {
        return tokenStorage_CD.defaultFee();
    }

    function _mint(address _to, uint256 _amount) internal {
        super._mint(_to, _amount);
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

 
contract WhitelistedToken is PermissionedToken {


    address public cusdAddress;

     
    event CUSDAddressChanged(address indexed oldCUSD, address indexed newCUSD);
    event MintedToCUSD(address indexed user, uint256 amount);
    event ConvertedToCUSD(address indexed user, uint256 amount);

     
    constructor(address _regulator, address _cusd) public PermissionedToken(_regulator) {

         
        regulator = WhitelistedTokenRegulator(_regulator);

        cusdAddress = _cusd;

    }

     
    function mintCUSD(address _to, uint256 _amount) public requiresPermission whenNotPaused userWhitelisted(_to) {
        return _mintCUSD(_to, _amount);
    }

     
    function convertWT(uint256 _amount) public requiresPermission whenNotPaused {
        require(balanceOf(msg.sender) >= _amount, "Conversion amount should be less than balance");
        _burn(msg.sender, _amount);
        _mintCUSD(msg.sender, _amount);
        emit ConvertedToCUSD(msg.sender, _amount);
    }

     
    function setCUSDAddress(address _cusd) public onlyOwner {
        require(_cusd != address(cusdAddress), "Must be a new cusd address");
        require(AddressUtils.isContract(_cusd), "Must be an actual contract");
        address oldCUSD = address(cusdAddress);
        cusdAddress = _cusd;
        emit CUSDAddressChanged(oldCUSD, _cusd);
    }

    function _mintCUSD(address _to, uint256 _amount) internal {
        require(_to != cusdAddress, "Cannot mint to CarbonUSD contract");  
        CarbonDollar(cusdAddress).mint(_to, _amount);
        _mint(cusdAddress, _amount);
        emit MintedToCUSD(_to, _amount);
    }
}

 
 
    
 

 
 
    
 
 
 
 
 
 
 

 

 
 
 
 

 
 

 
 

 
 
 
 
 
 
 

 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 

 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 

 
 
 
 
 
 
 
 

 
 
 
 
 
 
 

 
 
 

 