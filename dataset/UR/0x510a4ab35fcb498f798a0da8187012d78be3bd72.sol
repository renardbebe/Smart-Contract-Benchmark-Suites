 

 


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



 
contract CrydrStorageBaseInterface {

   

  event CrydrControllerChangedEvent(address indexed crydrcontroller);


   

  function setCrydrController(address _newController) public;
  function getCrydrController() public constant returns (address);
}



 
contract CrydrStorageBase is CommonModifiersInterface,
                             AssetIDInterface,
                             ManageableInterface,
                             PausableInterface,
                             CrydrStorageBaseInterface {

   

  address crydrController = address(0x0);


   

   

  function setCrydrController(
    address _crydrController
  )
    public
    whenContractPaused
    onlyContractAddress(_crydrController)
    onlyAllowedManager('set_crydr_controller')
  {
    require(_crydrController != address(crydrController));
    require(_crydrController != address(this));

    crydrController = _crydrController;
    CrydrControllerChangedEvent(_crydrController);
  }

  function getCrydrController() public constant returns (address) {
    return address(crydrController);
  }


   

   
  function unpauseContract() public {
    require(isContract(crydrController) == true);
    require(getAssetIDHash() == AssetIDInterface(crydrController).getAssetIDHash());

    super.unpauseContract();
  }
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



 
contract CrydrStorageBlocks is SafeMathInterface,
                               PausableInterface,
                               CrydrStorageBaseInterface,
                               CrydrStorageBlocksInterface {

   

  mapping (address => uint256) accountBlocks;
  mapping (address => uint256) accountBlockedFunds;


   

  function CrydrStorageBlocks() public {
    accountBlocks[0x0] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }


   

  function blockAccount(
    address _account
  )
    public
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));

    accountBlocks[_account] = safeAdd(accountBlocks[_account], 1);
    AccountBlockedEvent(_account);
  }

  function unblockAccount(
    address _account
  )
    public
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));

    accountBlocks[_account] = safeSub(accountBlocks[_account], 1);
    AccountUnblockedEvent(_account);
  }

  function getAccountBlocks(
    address _account
  )
    public
    constant
    returns (uint256)
  {
    require(_account != address(0x0));

    return accountBlocks[_account];
  }

  function blockAccountFunds(
    address _account,
    uint256 _value
  )
    public
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));
    require(_value > 0);

    accountBlockedFunds[_account] = safeAdd(accountBlockedFunds[_account], _value);
    AccountFundsBlockedEvent(_account, _value);
  }

  function unblockAccountFunds(
    address _account,
    uint256 _value
  )
    public
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));
    require(_value > 0);

    accountBlockedFunds[_account] = safeSub(accountBlockedFunds[_account], _value);
    AccountFundsUnblockedEvent(_account, _value);
  }

  function getAccountBlockedFunds(
    address _account
  )
    public
    constant
    returns (uint256)
  {
    require(_account != address(0x0));

    return accountBlockedFunds[_account];
  }
}



 
contract CrydrStorageBalanceInterface {

   

  event AccountBalanceIncreasedEvent(address indexed account, uint256 value);
  event AccountBalanceDecreasedEvent(address indexed account, uint256 value);


   

  function increaseBalance(address _account, uint256 _value) public;
  function decreaseBalance(address _account, uint256 _value) public;
  function getBalance(address _account) public constant returns (uint256);
  function getTotalSupply() public constant returns (uint256);
}



 
contract CrydrStorageBalance is SafeMathInterface,
                                PausableInterface,
                                CrydrStorageBaseInterface,
                                CrydrStorageBalanceInterface {

   

  mapping (address => uint256) balances;
  uint256 totalSupply = 0;


   

  function increaseBalance(
    address _account,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));
    require(_value > 0);

    balances[_account] = safeAdd(balances[_account], _value);
    totalSupply = safeAdd(totalSupply, _value);
    AccountBalanceIncreasedEvent(_account, _value);
  }

  function decreaseBalance(
    address _account,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));
    require(_value > 0);

    balances[_account] = safeSub(balances[_account], _value);
    totalSupply = safeSub(totalSupply, _value);
    AccountBalanceDecreasedEvent(_account, _value);
  }

  function getBalance(address _account) public constant returns (uint256) {
    require(_account != address(0x0));

    return balances[_account];
  }

  function getTotalSupply() public constant returns (uint256) {
    return totalSupply;
  }
}



 
contract CrydrStorageAllowanceInterface {

   

  event AccountAllowanceIncreasedEvent(address indexed owner, address indexed spender, uint256 value);
  event AccountAllowanceDecreasedEvent(address indexed owner, address indexed spender, uint256 value);


   

  function increaseAllowance(address _owner, address _spender, uint256 _value) public;
  function decreaseAllowance(address _owner, address _spender, uint256 _value) public;
  function getAllowance(address _owner, address _spender) public constant returns (uint256);
}



 
contract CrydrStorageAllowance is SafeMathInterface,
                                  PausableInterface,
                                  CrydrStorageBaseInterface,
                                  CrydrStorageAllowanceInterface {

   

  mapping (address => mapping (address => uint256)) allowed;


   

  function increaseAllowance(
    address _owner,
    address _spender,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_owner != address(0x0));
    require(_spender != address(0x0));
    require(_owner != _spender);
    require(_value > 0);

    allowed[_owner][_spender] = safeAdd(allowed[_owner][_spender], _value);
    AccountAllowanceIncreasedEvent(_owner, _spender, _value);
  }

  function decreaseAllowance(
    address _owner,
    address _spender,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_owner != address(0x0));
    require(_spender != address(0x0));
    require(_owner != _spender);
    require(_value > 0);

    allowed[_owner][_spender] = safeSub(allowed[_owner][_spender], _value);
    AccountAllowanceDecreasedEvent(_owner, _spender, _value);
  }

  function getAllowance(
    address _owner,
    address _spender
  )
    public
    constant
    returns (uint256)
  {
    require(_owner != address(0x0));
    require(_spender != address(0x0));
    require(_owner != _spender);

    return allowed[_owner][_spender];
  }
}



 
contract CrydrStorageERC20Interface {

   

  event CrydrTransferredEvent(address indexed from, address indexed to, uint256 value);
  event CrydrTransferredFromEvent(address indexed spender, address indexed from, address indexed to, uint256 value);
  event CrydrSpendingApprovedEvent(address indexed owner, address indexed spender, uint256 value);


   

  function transfer(address _msgsender, address _to, uint256 _value) public;
  function transferFrom(address _msgsender, address _from, address _to, uint256 _value) public;
  function approve(address _msgsender, address _spender, uint256 _value) public;
}



 
contract CrydrStorageERC20 is SafeMathInterface,
                              PausableInterface,
                              CrydrStorageBaseInterface,
                              CrydrStorageBalanceInterface,
                              CrydrStorageAllowanceInterface,
                              CrydrStorageBlocksInterface,
                              CrydrStorageERC20Interface {

  function transfer(
    address _msgsender,
    address _to,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_msgsender != _to);
    require(getAccountBlocks(_msgsender) == 0);
    require(safeSub(getBalance(_msgsender), _value) >= getAccountBlockedFunds(_msgsender));

    decreaseBalance(_msgsender, _value);
    increaseBalance(_to, _value);
    CrydrTransferredEvent(_msgsender, _to, _value);
  }

  function transferFrom(
    address _msgsender,
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(getAccountBlocks(_msgsender) == 0);
    require(getAccountBlocks(_from) == 0);
    require(safeSub(getBalance(_from), _value) >= getAccountBlockedFunds(_from));
    require(_from != _to);

    decreaseAllowance(_from, _msgsender, _value);
    decreaseBalance(_from, _value);
    increaseBalance(_to, _value);
    CrydrTransferredFromEvent(_msgsender, _from, _to, _value);
  }

  function approve(
    address _msgsender,
    address _spender,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(getAccountBlocks(_msgsender) == 0);
    require(getAccountBlocks(_spender) == 0);

    uint256 currentAllowance = getAllowance(_msgsender, _spender);
    require(currentAllowance != _value);
    if (currentAllowance > _value) {
      decreaseAllowance(_msgsender, _spender, safeSub(currentAllowance, _value));
    } else {
      increaseAllowance(_msgsender, _spender, safeSub(_value, currentAllowance));
    }

    CrydrSpendingApprovedEvent(_msgsender, _spender, _value);
  }
}



 
contract JCashCrydrStorage is SafeMath,
                              CommonModifiers,
                              AssetID,
                              Ownable,
                              Manageable,
                              Pausable,
                              BytecodeExecutor,
                              CrydrStorageBase,
                              CrydrStorageBalance,
                              CrydrStorageAllowance,
                              CrydrStorageBlocks,
                              CrydrStorageERC20 {

   

  function JCashCrydrStorage(string _assetID) AssetID(_assetID) public { }
}



contract JNTStorage is JCashCrydrStorage {
  function JNTStorage() JCashCrydrStorage('JNT') public {}
}