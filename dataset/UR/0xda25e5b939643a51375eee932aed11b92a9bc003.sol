 

 


pragma solidity ^0.4.18;



 
contract SafeMathInterface {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256);
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256);
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256);
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256);
}



 
contract SafeMath is SafeMathInterface {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract CommonModifiersInterface {

   
  function isContract(address _targetAddress) internal constant returns (bool);

   
  modifier onlyContractAddress(address _targetAddress) {
    require(isContract(_targetAddress) == true);
    _;
  }
}



 
contract CommonModifiers is CommonModifiersInterface {

   
  function isContract(address _targetAddress) internal constant returns (bool) {
    require (_targetAddress != address(0x0));

    uint256 length;
    assembly {
       
      length := extcodesize(_targetAddress)
    }
    return (length > 0);
  }
}



 
contract AssetIDInterface {
  function getAssetID() public constant returns (string);
  function getAssetIDHash() public constant returns (bytes32);
}



 
contract AssetID is AssetIDInterface {

   

  string assetID;


   

  function AssetID(string _assetID) public {
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


   
  function Ownable() public {
    owner = msg.sender;

    OwnerAssignedEvent(owner);
  }


   
  function createOwnershipOffer(address _proposedOwner) external onlyOwner {
    require (proposedOwner == address(0x0));
    require (_proposedOwner != address(0x0));
    require (_proposedOwner != address(this));

    proposedOwner = _proposedOwner;

    OwnershipOfferCreatedEvent(owner, _proposedOwner);
  }


   
   
  function acceptOwnershipOffer() external {
    require (proposedOwner != address(0x0));
    require (msg.sender == proposedOwner);

    address _oldOwner = owner;
    owner = proposedOwner;
    proposedOwner = address(0x0);

    OwnerAssignedEvent(owner);
    OwnershipOfferAcceptedEvent(_oldOwner, owner);
  }


   
  function cancelOwnershipOffer() external {
    require (proposedOwner != address(0x0));
    require (msg.sender == owner || msg.sender == proposedOwner);

    address _oldProposedOwner = proposedOwner;
    proposedOwner = address(0x0);

    OwnershipOfferCancelledEvent(owner, _oldProposedOwner);
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
  event ManagerPermissionGrantedEvent(address indexed manager, string permission);
  event ManagerPermissionRevokedEvent(address indexed manager, string permission);


   

   
  function enableManager(address _manager) external onlyOwner onlyValidManagerAddress(_manager) {
    require(managerEnabled[_manager] == false);

    managerEnabled[_manager] = true;
    ManagerEnabledEvent(_manager);
  }

   
  function disableManager(address _manager) external onlyOwner onlyValidManagerAddress(_manager) {
    require(managerEnabled[_manager] == true);

    managerEnabled[_manager] = false;
    ManagerDisabledEvent(_manager);
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
    ManagerPermissionGrantedEvent(_manager, _permissionName);
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
    ManagerPermissionRevokedEvent(_manager, _permissionName);
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
    PauseEvent();
  }

   
  function unpauseContract() public onlyAllowedManager('unpause_contract') whenContractPaused {
    paused = false;
    UnpauseEvent();
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

    CallExecutedEvent(_target, _suppliedGas, _ethValue, keccak256(_transactionBytecode));
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

    DelegatecallExecutedEvent(_target, _suppliedGas, keccak256(_transactionBytecode));
  }
}



contract CrydrViewBaseInterface {

   

  event CrydrControllerChangedEvent(address indexed crydrcontroller);


   

  function setCrydrController(address _crydrController) external;
  function getCrydrController() public constant returns (address);

  function getCrydrViewStandardName() public constant returns (string);
  function getCrydrViewStandardNameHash() public constant returns (bytes32);
}



 
contract CrydrStorageBalanceInterface {

   

  event AccountBalanceIncreasedEvent(address indexed account, uint256 value);
  event AccountBalanceDecreasedEvent(address indexed account, uint256 value);


   

  function increaseBalance(address _account, uint256 _value) public;
  function decreaseBalance(address _account, uint256 _value) public;
  function getBalance(address _account) public constant returns (uint256);
  function getTotalSupply() public constant returns (uint256);
}



 
contract CrydrStorageAllowanceInterface {

   

  event AccountAllowanceIncreasedEvent(address indexed owner, address indexed spender, uint256 value);
  event AccountAllowanceDecreasedEvent(address indexed owner, address indexed spender, uint256 value);


   

  function increaseAllowance(address _owner, address _spender, uint256 _value) public;
  function decreaseAllowance(address _owner, address _spender, uint256 _value) public;
  function getAllowance(address _owner, address _spender) public constant returns (uint256);
}



 
contract CrydrStorageERC20Interface {

   

  event CrydrTransferredEvent(address indexed from, address indexed to, uint256 value);
  event CrydrTransferredFromEvent(address indexed spender, address indexed from, address indexed to, uint256 value);
  event CrydrSpendingApprovedEvent(address indexed owner, address indexed spender, uint256 value);


   

  function transfer(address _msgsender, address _to, uint256 _value) public;
  function transferFrom(address _msgsender, address _from, address _to, uint256 _value) public;
  function approve(address _msgsender, address _spender, uint256 _value) public;
}



 
contract CrydrStorageBlocksInterface {

   

  event AccountBlockedEvent(address indexed account);
  event AccountUnblockedEvent(address indexed account);
  event AccountFundsBlockedEvent(address indexed account, uint256 value);
  event AccountFundsUnblockedEvent(address indexed account, uint256 value);


   

  function blockAccount(address _account) public;
  function unblockAccount(address _account) public;
  function getAccountBlocks(address _account) public constant returns (uint256);

  function blockAccountFunds(address _account, uint256 _value) public;
  function unblockAccountFunds(address _account, uint256 _value) public;
  function getAccountBlockedFunds(address _account) public constant returns (uint256);
}



 
contract CrydrViewERC20LoggableInterface {

  function emitTransferEvent(address _from, address _to, uint256 _value) external;
  function emitApprovalEvent(address _owner, address _spender, uint256 _value) external;
}



 
contract CrydrViewERC20MintableInterface {
  event MintEvent(address indexed owner, uint256 value);
  event BurnEvent(address indexed owner, uint256 value);

  function emitMintEvent(address _owner, uint256 _value) external;
  function emitBurnEvent(address _owner, uint256 _value) external;
}



 
contract CrydrControllerBaseInterface {

   

  event CrydrStorageChangedEvent(address indexed crydrstorage);
  event CrydrViewAddedEvent(address indexed crydrview, string standardname);
  event CrydrViewRemovedEvent(address indexed crydrview, string standardname);


   

  function setCrydrStorage(address _newStorage) external;
  function getCrydrStorageAddress() public constant returns (address);

  function setCrydrView(address _newCrydrView, string _viewApiStandardName) external;
  function removeCrydrView(string _viewApiStandardName) external;
  function getCrydrViewAddress(string _viewApiStandardName) public constant returns (address);

  function isCrydrViewAddress(address _crydrViewAddress) public constant returns (bool);
  function isCrydrViewRegistered(string _viewApiStandardName) public constant returns (bool);


   

  modifier onlyValidCrydrViewStandardName(string _viewApiStandard) {
    require(bytes(_viewApiStandard).length > 0);
    _;
  }

  modifier onlyCrydrView() {
    require(isCrydrViewAddress(msg.sender) == true);
    _;
  }
}



 
contract CrydrControllerBase is CommonModifiersInterface,
                                ManageableInterface,
                                PausableInterface,
                                CrydrControllerBaseInterface {

   

  address crydrStorage = address(0x0);
  mapping (string => address) crydrViewsAddresses;
  mapping (address => bool) isRegisteredView;


   

  function setCrydrStorage(
    address _crydrStorage
  )
    external
    onlyContractAddress(_crydrStorage)
    onlyAllowedManager('set_crydr_storage')
    whenContractPaused
  {
    require(_crydrStorage != address(this));
    require(_crydrStorage != address(crydrStorage));

    crydrStorage = _crydrStorage;
    CrydrStorageChangedEvent(_crydrStorage);
  }

  function getCrydrStorageAddress() public constant returns (address) {
    return address(crydrStorage);
  }


  function setCrydrView(
    address _newCrydrView, string _viewApiStandardName
  )
    external
    onlyContractAddress(_newCrydrView)
    onlyValidCrydrViewStandardName(_viewApiStandardName)
    onlyAllowedManager('set_crydr_view')
    whenContractPaused
  {
    require(_newCrydrView != address(this));
    require(crydrViewsAddresses[_viewApiStandardName] == address(0x0));

    var crydrViewInstance = CrydrViewBaseInterface(_newCrydrView);
    var standardNameHash = crydrViewInstance.getCrydrViewStandardNameHash();
    require(standardNameHash == keccak256(_viewApiStandardName));

    crydrViewsAddresses[_viewApiStandardName] = _newCrydrView;
    isRegisteredView[_newCrydrView] = true;

    CrydrViewAddedEvent(_newCrydrView, _viewApiStandardName);
  }

  function removeCrydrView(
    string _viewApiStandardName
  )
    external
    onlyValidCrydrViewStandardName(_viewApiStandardName)
    onlyAllowedManager('remove_crydr_view')
    whenContractPaused
  {
    require(crydrViewsAddresses[_viewApiStandardName] != address(0x0));

    address removedView = crydrViewsAddresses[_viewApiStandardName];

     
    crydrViewsAddresses[_viewApiStandardName] == address(0x0);
    isRegisteredView[removedView] = false;

    CrydrViewRemovedEvent(removedView, _viewApiStandardName);
  }

  function getCrydrViewAddress(
    string _viewApiStandardName
  )
    public
    constant
    onlyValidCrydrViewStandardName(_viewApiStandardName)
    returns (address)
  {
    require(crydrViewsAddresses[_viewApiStandardName] != address(0x0));

    return crydrViewsAddresses[_viewApiStandardName];
  }

  function isCrydrViewAddress(
    address _crydrViewAddress
  )
    public
    constant
    returns (bool)
  {
    require(_crydrViewAddress != address(0x0));

    return isRegisteredView[_crydrViewAddress];
  }

  function isCrydrViewRegistered(
    string _viewApiStandardName
  )
    public
    constant
    onlyValidCrydrViewStandardName(_viewApiStandardName)
    returns (bool)
  {
    return (crydrViewsAddresses[_viewApiStandardName] != address(0x0));
  }
}



 
contract CrydrControllerBlockableInterface {

   

  function blockAccount(address _account) public;
  function unblockAccount(address _account) public;

  function blockAccountFunds(address _account, uint256 _value) public;
  function unblockAccountFunds(address _account, uint256 _value) public;
}



 
contract CrydrControllerBlockable is ManageableInterface,
                                     CrydrControllerBaseInterface,
                                     CrydrControllerBlockableInterface {


   

  function blockAccount(
    address _account
  )
    public
    onlyAllowedManager('block_account')
  {
    CrydrStorageBlocksInterface(getCrydrStorageAddress()).blockAccount(_account);
  }

  function unblockAccount(
    address _account
  )
    public
    onlyAllowedManager('unblock_account')
  {
    CrydrStorageBlocksInterface(getCrydrStorageAddress()).unblockAccount(_account);
  }

  function blockAccountFunds(
    address _account,
    uint256 _value
  )
    public
    onlyAllowedManager('block_account_funds')
  {
    CrydrStorageBlocksInterface(getCrydrStorageAddress()).blockAccountFunds(_account, _value);
  }

  function unblockAccountFunds(
    address _account,
    uint256 _value
  )
    public
    onlyAllowedManager('unblock_account_funds')
  {
    CrydrStorageBlocksInterface(getCrydrStorageAddress()).unblockAccountFunds(_account, _value);
  }
}



 
contract CrydrControllerMintableInterface {

   

  function mint(address _account, uint256 _value) public;
  function burn(address _account, uint256 _value) public;
}



 
contract CrydrControllerMintable is ManageableInterface,
                                    PausableInterface,
                                    CrydrControllerBaseInterface,
                                    CrydrControllerMintableInterface {

   

  function mint(
    address _account, uint256 _value
  )
    public
    whenContractNotPaused
    onlyAllowedManager('mint_crydr')
  {
     

    CrydrStorageBalanceInterface(getCrydrStorageAddress()).increaseBalance(_account, _value);

    if (isCrydrViewRegistered('erc20') == true) {
      CrydrViewERC20MintableInterface(getCrydrViewAddress('erc20')).emitMintEvent(_account, _value);
    }
  }

  function burn(
    address _account, uint256 _value
  )
    public
    whenContractNotPaused
    onlyAllowedManager('burn_crydr')
  {
     

    CrydrStorageBalanceInterface(getCrydrStorageAddress()).decreaseBalance(_account, _value);

    if (isCrydrViewRegistered('erc20') == true) {
      CrydrViewERC20MintableInterface(getCrydrViewAddress('erc20')).emitBurnEvent(_account, _value);
    }
  }
}



 
contract CrydrControllerERC20Interface {

   

  function transfer(address _msgsender, address _to, uint256 _value) public;
  function getTotalSupply() public constant returns (uint256);
  function getBalance(address _owner) public constant returns (uint256);

  function approve(address _msgsender, address _spender, uint256 _value) public;
  function transferFrom(address _msgsender, address _from, address _to, uint256 _value) public;
  function getAllowance(address _owner, address _spender) public constant returns (uint256);
}



 
contract CrydrControllerERC20 is PausableInterface,
                                 CrydrControllerBaseInterface,
                                 CrydrControllerERC20Interface {

   

  function transfer(
    address _msgsender,
    address _to,
    uint256 _value
  )
    public
    onlyCrydrView
    whenContractNotPaused
  {
    CrydrStorageERC20Interface(address(getCrydrStorageAddress())).transfer(_msgsender, _to, _value);

    if (isCrydrViewRegistered('erc20') == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress('erc20')).emitTransferEvent(_msgsender, _to, _value);
    }
  }

  function getTotalSupply() public constant returns (uint256) {
    return CrydrStorageBalanceInterface(address(getCrydrStorageAddress())).getTotalSupply();
  }

  function getBalance(address _owner) public constant returns (uint256) {
    return CrydrStorageBalanceInterface(address(getCrydrStorageAddress())).getBalance(_owner);
  }

  function approve(
    address _msgsender,
    address _spender,
    uint256 _value
  )
    public
    onlyCrydrView
    whenContractNotPaused
  {
     
     
     
    var allowance = CrydrStorageAllowanceInterface(getCrydrStorageAddress()).getAllowance(_msgsender, _spender);
    require((allowance > 0 && _value == 0) || (allowance == 0 && _value > 0));

    CrydrStorageERC20Interface(address(getCrydrStorageAddress())).approve(_msgsender, _spender, _value);

    if (isCrydrViewRegistered('erc20') == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress('erc20')).emitApprovalEvent(_msgsender, _spender, _value);
    }
  }

  function transferFrom(
    address _msgsender,
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyCrydrView
    whenContractNotPaused
  {
    CrydrStorageERC20Interface(address(getCrydrStorageAddress())).transferFrom(_msgsender, _from, _to, _value);

    if (isCrydrViewRegistered('erc20') == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress('erc20')).emitTransferEvent(_from, _to, _value);
    }
  }

  function getAllowance(address _owner, address _spender) public constant returns (uint256 ) {
    return CrydrStorageAllowanceInterface(address(getCrydrStorageAddress())).getAllowance(_owner, _spender);
  }
}



 
contract JNTControllerInterface {

   

  event JNTChargedEvent(address indexed payableservice, address indexed from, address indexed to, uint256 value);


   

  function chargeJNT(address _from, address _to, uint256 _value) public;
}



 
contract JNTPayableServiceInterface {

   

  event JNTControllerChangedEvent(address jntcontroller);
  event JNTBeneficiaryChangedEvent(address jntbeneficiary);
  event JNTChargedEvent(address indexed from, address indexed to, uint256 value);


   

  function setJntController(address _jntController) external;
  function getJntController() public constant returns (address);

  function setJntBeneficiary(address _jntBeneficiary) external;
  function getJntBeneficiary() public constant returns (address);


   

  function chargeJNTForService(address _from, uint256 _value) internal;
}



contract JNTPayableService is CommonModifiersInterface,
                              ManageableInterface,
                              PausableInterface,
                              JNTPayableServiceInterface {

   

  JNTControllerInterface jntController;
  address jntBeneficiary;


   

   

  function setJntController(
    address _jntController
  )
    external
    onlyContractAddress(_jntController)
    onlyAllowedManager('set_jnt_controller')
    whenContractPaused
  {
    require(_jntController != address(jntController));

    jntController = JNTControllerInterface(_jntController);
    JNTControllerChangedEvent(_jntController);
  }

  function getJntController() public constant returns (address) {
    return address(jntController);
  }


  function setJntBeneficiary(
    address _jntBeneficiary
  )
    external
    onlyValidJntBeneficiary(_jntBeneficiary)
    onlyAllowedManager('set_jnt_beneficiary')
    whenContractPaused
  {
    require(_jntBeneficiary != jntBeneficiary);
    require(_jntBeneficiary != address(this));

    jntBeneficiary = _jntBeneficiary;
    JNTBeneficiaryChangedEvent(jntBeneficiary);
  }

  function getJntBeneficiary() public constant returns (address) {
    return jntBeneficiary;
  }


   

  function chargeJNTForService(address _from, uint256 _value) internal whenContractNotPaused {
    require(_from != address(0x0));
    require(_from != jntBeneficiary);
    require(_value > 0);

    jntController.chargeJNT(_from, jntBeneficiary, _value);
    JNTChargedEvent(_from, jntBeneficiary, _value);
  }


   

   
  function unpauseContract()
    public
    onlyContractAddress(jntController)
    onlyValidJntBeneficiary(jntBeneficiary)
  {
    super.unpauseContract();
  }


   

  modifier onlyValidJntBeneficiary(address _jntBeneficiary) {
    require(_jntBeneficiary != address(0x0));
    _;
  }
}



 
contract JNTPayableServiceERC20FeesInterface {

   

  event JNTPriceTransferChangedEvent(uint256 value);
  event JNTPriceTransferFromChangedEvent(uint256 value);
  event JNTPriceApproveChangedEvent(uint256 value);


   

  function setJntPrice(uint256 _jntPriceTransfer, uint256 _jntPriceTransferFrom, uint256 _jntPriceApprove) external;
  function getJntPriceForTransfer() public constant returns (uint256);
  function getJntPriceForTransferFrom() public constant returns (uint256);
  function getJntPriceForApprove() public constant returns (uint256);
}



contract JNTPayableServiceERC20Fees is ManageableInterface,
                                       PausableInterface,
                                       JNTPayableServiceERC20FeesInterface {

   

  uint256 jntPriceTransfer;
  uint256 jntPriceTransferFrom;
  uint256 jntPriceApprove;


   

  function JNTPayableServiceERC20Fees(
    uint256 _jntPriceTransfer,
    uint256 _jntPriceTransferFrom,
    uint256 _jntPriceApprove
  )
    public
  {
    jntPriceTransfer = _jntPriceTransfer;
    jntPriceTransferFrom = _jntPriceTransferFrom;
    jntPriceApprove = _jntPriceApprove;
  }


   

   

  function setJntPrice(
    uint256 _jntPriceTransfer, uint256 _jntPriceTransferFrom, uint256 _jntPriceApprove
  )
    external
    onlyAllowedManager('set_jnt_price')
    whenContractPaused
  {
    require(_jntPriceTransfer != jntPriceTransfer ||
            _jntPriceTransferFrom != jntPriceTransferFrom ||
            _jntPriceApprove != jntPriceApprove);

    if (jntPriceTransfer != _jntPriceTransfer) {
      jntPriceTransfer = _jntPriceTransfer;
      JNTPriceTransferChangedEvent(_jntPriceTransfer);
    }
    if (jntPriceTransferFrom != _jntPriceTransferFrom) {
      jntPriceTransferFrom = _jntPriceTransferFrom;
      JNTPriceTransferFromChangedEvent(_jntPriceTransferFrom);
    }
    if (jntPriceApprove != _jntPriceApprove) {
      jntPriceApprove = _jntPriceApprove;
      JNTPriceApproveChangedEvent(_jntPriceApprove);
    }
  }

  function getJntPriceForTransfer() public constant returns (uint256) {
    return jntPriceTransfer;
  }

  function getJntPriceForTransferFrom() public constant returns (uint256) {
    return jntPriceTransferFrom;
  }

  function getJntPriceForApprove() public constant returns (uint256) {
    return jntPriceApprove;
  }
}



contract JCashCrydrController is CommonModifiers,
                                 AssetID,
                                 Ownable,
                                 Manageable,
                                 Pausable,
                                 BytecodeExecutor,
                                 CrydrControllerBase,
                                 CrydrControllerBlockable,
                                 CrydrControllerMintable,
                                 CrydrControllerERC20,
                                 JNTPayableService,
                                 JNTPayableServiceERC20Fees {

   
   

  function JCashCrydrController(string _assetID)
    public
    AssetID(_assetID)
    JNTPayableServiceERC20Fees(10^18, 10^18, 10^18)
  {}


   

   

  function transfer(
    address _msgsender,
    address _to,
    uint256 _value
  )
    public
  {
    CrydrControllerERC20.transfer(_msgsender, _to, _value);
    chargeJNTForService(_msgsender, getJntPriceForTransfer());
  }

  function approve(
    address _msgsender,
    address _spender,
    uint256 _value
  )
    public
  {
    CrydrControllerERC20.approve(_msgsender, _spender, _value);
    chargeJNTForService(_msgsender, getJntPriceForApprove());
  }

  function transferFrom(
    address _msgsender,
    address _from,
    address _to,
    uint256 _value
  )
    public
  {
    CrydrControllerERC20.transferFrom(_msgsender, _from, _to, _value);
    chargeJNTForService(_msgsender, getJntPriceForTransferFrom());
  }
}



 
contract JNTController is CommonModifiers,
                          AssetID,
                          Ownable,
                          Manageable,
                          Pausable,
                          BytecodeExecutor,
                          CrydrControllerBase,
                          CrydrControllerBlockable,
                          CrydrControllerMintable,
                          CrydrControllerERC20,
                          JNTControllerInterface {

   

  function JNTController() AssetID('JNT') public {}


   

  function chargeJNT(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyAllowedManager('jnt_payable_service') {
    CrydrStorageERC20Interface(address(crydrStorage)).transfer(_from, _to, _value);
    JNTChargedEvent(msg.sender, _from, _to, _value);
  }
}