 

 

pragma solidity ^0.4.24;



 
contract OwnableInterface {

   
  function getOwner() public constant returns (address);

   
  modifier onlyOwner() {
    require (msg.sender == getOwner());
    _;
  }
}



 
contract Ownable is OwnableInterface {

   

  address owner = address(0x0);
  address proposedOwner = address(0x0);


   

  event OwnerAssignedEvent(address indexed newowner);
  event OwnershipOfferCreatedEvent(address indexed currentowner, address indexed proposedowner);
  event OwnershipOfferAcceptedEvent(address indexed currentowner, address indexed proposedowner);
  event OwnershipOfferCancelledEvent(address indexed currentowner, address indexed proposedowner);


   
  constructor () public {
    owner = msg.sender;

    emit OwnerAssignedEvent(owner);
  }


   
  function createOwnershipOffer(address _proposedOwner) external onlyOwner {
    require (proposedOwner == address(0x0));
    require (_proposedOwner != address(0x0));
    require (_proposedOwner != address(this));

    proposedOwner = _proposedOwner;

    emit OwnershipOfferCreatedEvent(owner, _proposedOwner);
  }


   
   
  function acceptOwnershipOffer() external {
    require (proposedOwner != address(0x0));
    require (msg.sender == proposedOwner);

    address _oldOwner = owner;
    owner = proposedOwner;
    proposedOwner = address(0x0);

    emit OwnerAssignedEvent(owner);
    emit OwnershipOfferAcceptedEvent(_oldOwner, owner);
  }


   
  function cancelOwnershipOffer() external {
    require (proposedOwner != address(0x0));
    require (msg.sender == owner || msg.sender == proposedOwner);

    address _oldProposedOwner = proposedOwner;
    proposedOwner = address(0x0);

    emit OwnershipOfferCancelledEvent(owner, _oldProposedOwner);
  }


   
  function getOwner() public constant returns (address) {
    return owner;
  }

   
  function getProposedOwner() public constant returns (address) {
    return proposedOwner;
  }
}



 
contract ManageableInterface {

   
  function isManagerAllowed(address _manager, string _permissionName) public constant returns (bool);

   
  modifier onlyAllowedManager(string _permissionName) {
    require(isManagerAllowed(msg.sender, _permissionName) == true);
    _;
  }
}



contract Manageable is OwnableInterface,
                       ManageableInterface {

   

  mapping (address => bool) managerEnabled;   
  mapping (address => mapping (string => bool)) managerPermissions;   


   

  event ManagerEnabledEvent(address indexed manager);
  event ManagerDisabledEvent(address indexed manager);
  event ManagerPermissionGrantedEvent(address indexed manager, bytes32 permission);
  event ManagerPermissionRevokedEvent(address indexed manager, bytes32 permission);


   

   
  function enableManager(address _manager) external onlyOwner onlyValidManagerAddress(_manager) {
    require(managerEnabled[_manager] == false);

    managerEnabled[_manager] = true;

    emit ManagerEnabledEvent(_manager);
  }

   
  function disableManager(address _manager) external onlyOwner onlyValidManagerAddress(_manager) {
    require(managerEnabled[_manager] == true);

    managerEnabled[_manager] = false;

    emit ManagerDisabledEvent(_manager);
  }

   
  function grantManagerPermission(
    address _manager, string _permissionName
  )
    external
    onlyOwner
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == false);

    managerPermissions[_manager][_permissionName] = true;

    emit ManagerPermissionGrantedEvent(_manager, keccak256(_permissionName));
  }

   
  function revokeManagerPermission(
    address _manager, string _permissionName
  )
    external
    onlyOwner
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == true);

    managerPermissions[_manager][_permissionName] = false;

    emit ManagerPermissionRevokedEvent(_manager, keccak256(_permissionName));
  }


   

   
  function isManagerEnabled(
    address _manager
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    returns (bool)
  {
    return managerEnabled[_manager];
  }

   
  function isPermissionGranted(
    address _manager, string _permissionName
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return managerPermissions[_manager][_permissionName];
  }

   
  function isManagerAllowed(
    address _manager, string _permissionName
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return (managerEnabled[_manager] && managerPermissions[_manager][_permissionName]);
  }


   

   
  modifier onlyValidManagerAddress(address _manager) {
    require(_manager != address(0x0));
    _;
  }

   
  modifier onlyValidPermissionName(string _permissionName) {
    require(bytes(_permissionName).length != 0);
    _;
  }
}



 
contract PausableInterface {

   

  event PauseEvent();
  event UnpauseEvent();


   
  function pauseContract() public;

   
  function unpauseContract() public;

   
  function getPaused() public constant returns (bool);


   
  modifier whenContractNotPaused() {
    require(getPaused() == false);
    _;
  }

   
  modifier whenContractPaused {
    require(getPaused() == true);
    _;
  }
}



 
contract Pausable is ManageableInterface,
                     PausableInterface {

   

  bool paused = true;


   
  function pauseContract() public onlyAllowedManager('pause_contract') whenContractNotPaused {
    paused = true;
    emit PauseEvent();
  }

   
  function unpauseContract() public onlyAllowedManager('unpause_contract') whenContractPaused {
    paused = false;
    emit UnpauseEvent();
  }

   
  function getPaused() public constant returns (bool) {
    return paused;
  }
}



 
contract BytecodeExecutorInterface {

   

  event CallExecutedEvent(address indexed target,
                          uint256 suppliedGas,
                          uint256 ethValue,
                          bytes32 transactionBytecodeHash);
  event DelegatecallExecutedEvent(address indexed target,
                                  uint256 suppliedGas,
                                  bytes32 transactionBytecodeHash);


   

  function executeCall(address _target, uint256 _suppliedGas, uint256 _ethValue, bytes _transactionBytecode) external;
  function executeDelegatecall(address _target, uint256 _suppliedGas, bytes _transactionBytecode) external;
}



 
contract BytecodeExecutor is ManageableInterface,
                             BytecodeExecutorInterface {

   

  bool underExecution = false;


   

  function executeCall(
    address _target,
    uint256 _suppliedGas,
    uint256 _ethValue,
    bytes _transactionBytecode
  )
    external
    onlyAllowedManager('execute_call')
  {
    require(underExecution == false);

    underExecution = true;  
    _target.call.gas(_suppliedGas).value(_ethValue)(_transactionBytecode);
    underExecution = false;

    emit CallExecutedEvent(_target, _suppliedGas, _ethValue, keccak256(_transactionBytecode));
  }

  function executeDelegatecall(
    address _target,
    uint256 _suppliedGas,
    bytes _transactionBytecode
  )
    external
    onlyAllowedManager('execute_delegatecall')
  {
    require(underExecution == false);

    underExecution = true;  
    _target.delegatecall.gas(_suppliedGas)(_transactionBytecode);
    underExecution = false;

    emit DelegatecallExecutedEvent(_target, _suppliedGas, keccak256(_transactionBytecode));
  }
}



 
contract AssetIDInterface {
  function getAssetID() public constant returns (string);
  function getAssetIDHash() public constant returns (bytes32);
}



 
contract AssetID is AssetIDInterface {

   

  string assetID;


   

  constructor (string _assetID) public {
    require(bytes(_assetID).length > 0);

    assetID = _assetID;
  }


   

  function getAssetID() public constant returns (string) {
    return assetID;
  }

  function getAssetIDHash() public constant returns (bytes32) {
    return keccak256(assetID);
  }
}



 
contract CrydrLicenseRegistryInterface {

   
  function isUserAllowed(address _userAddress, string _licenseName) public constant returns (bool);
}



 
contract CrydrLicenseRegistryManagementInterface {

   

  event UserAdmittedEvent(address indexed useraddress);
  event UserDeniedEvent(address indexed useraddress);
  event UserLicenseGrantedEvent(address indexed useraddress, bytes32 licensename);
  event UserLicenseRenewedEvent(address indexed useraddress, bytes32 licensename);
  event UserLicenseRevokedEvent(address indexed useraddress, bytes32 licensename);


   

   
  function admitUser(address _userAddress) external;

   
  function denyUser(address _userAddress) external;

   
  function isUserAdmitted(address _userAddress) public constant returns (bool);


   
  function grantUserLicense(address _userAddress, string _licenseName) external;

   
  function revokeUserLicense(address _userAddress, string _licenseName) external;

   
  function isUserGranted(address _userAddress, string _licenseName) public constant returns (bool);
}



 
contract CrydrLicenseRegistry is ManageableInterface,
                                 CrydrLicenseRegistryInterface,
                                 CrydrLicenseRegistryManagementInterface {

   

  mapping (address => bool) userAdmittance;
  mapping (address => mapping (string => bool)) userLicenses;


   

  function isUserAllowed(
    address _userAddress, string _licenseName
  )
    public
    constant
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    returns (bool)
  {
    return userAdmittance[_userAddress] &&
           userLicenses[_userAddress][_licenseName];
  }


   

  function admitUser(
    address _userAddress
  )
    external
    onlyValidAddress(_userAddress)
    onlyAllowedManager('admit_user')
  {
    require(userAdmittance[_userAddress] == false);

    userAdmittance[_userAddress] = true;

    emit UserAdmittedEvent(_userAddress);
  }

  function denyUser(
    address _userAddress
  )
    external
    onlyValidAddress(_userAddress)
    onlyAllowedManager('deny_user')
  {
    require(userAdmittance[_userAddress] == true);

    userAdmittance[_userAddress] = false;

    emit UserDeniedEvent(_userAddress);
  }

  function isUserAdmitted(
    address _userAddress
  )
    public
    constant
    onlyValidAddress(_userAddress)
    returns (bool)
  {
    return userAdmittance[_userAddress];
  }


  function grantUserLicense(
    address _userAddress, string _licenseName
  )
    external
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    onlyAllowedManager('grant_license')
  {
    require(userLicenses[_userAddress][_licenseName] == false);

    userLicenses[_userAddress][_licenseName] = true;

    emit UserLicenseGrantedEvent(_userAddress, keccak256(_licenseName));
  }

  function revokeUserLicense(
    address _userAddress, string _licenseName
  )
    external
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    onlyAllowedManager('revoke_license')
  {
    require(userLicenses[_userAddress][_licenseName] == true);

    userLicenses[_userAddress][_licenseName] = false;

    emit UserLicenseRevokedEvent(_userAddress, keccak256(_licenseName));
  }

  function isUserGranted(
    address _userAddress, string _licenseName
  )
    public
    constant
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    returns (bool)
  {
    return userLicenses[_userAddress][_licenseName];
  }

  function isUserLicenseValid(
    address _userAddress, string _licenseName
  )
    public
    constant
    onlyValidAddress(_userAddress)
    onlyValidLicenseName(_licenseName)
    returns (bool)
  {
    return userLicenses[_userAddress][_licenseName];
  }


   

  modifier onlyValidAddress(address _userAddress) {
    require(_userAddress != address(0x0));
    _;
  }

  modifier onlyValidLicenseName(string _licenseName) {
    require(bytes(_licenseName).length > 0);
    _;
  }
}



 
contract JCashLicenseRegistry is AssetID,
                                 Ownable,
                                 Manageable,
                                 Pausable,
                                 BytecodeExecutor,
                                 CrydrLicenseRegistry {

   

  constructor (string _assetID) AssetID(_assetID) public { }
}



contract JUSDLicenseRegistry is JCashLicenseRegistry {
  constructor () public JCashLicenseRegistry('JUSD') {}
}