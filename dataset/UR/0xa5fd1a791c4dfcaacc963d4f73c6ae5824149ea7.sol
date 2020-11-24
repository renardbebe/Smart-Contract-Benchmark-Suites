 

 

pragma solidity ^0.4.18;



 
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





 
contract CrydrControllerERC20Interface {

   

  function transfer(address _msgsender, address _to, uint256 _value) public;
  function getTotalSupply() public constant returns (uint256);
  function getBalance(address _owner) public constant returns (uint256);

  function approve(address _msgsender, address _spender, uint256 _value) public;
  function transferFrom(address _msgsender, address _from, address _to, uint256 _value) public;
  function getAllowance(address _owner, address _spender) public constant returns (uint256);
}





contract CrydrViewBaseInterface {

   

  event CrydrControllerChangedEvent(address indexed crydrcontroller);


   

  function setCrydrController(address _crydrController) external;
  function getCrydrController() public constant returns (address);

  function getCrydrViewStandardName() public constant returns (string);
  function getCrydrViewStandardNameHash() public constant returns (bytes32);
}



contract CrydrViewBase is CommonModifiersInterface,
                          AssetIDInterface,
                          ManageableInterface,
                          PausableInterface,
                          CrydrViewBaseInterface {

   

  address crydrController = address(0x0);
  string crydrViewStandardName = '';


   

  function CrydrViewBase(string _crydrViewStandardName) public {
    require(bytes(_crydrViewStandardName).length > 0);

    crydrViewStandardName = _crydrViewStandardName;
  }


   

  function setCrydrController(
    address _crydrController
  )
    external
    onlyContractAddress(_crydrController)
    onlyAllowedManager('set_crydr_controller')
    whenContractPaused
  {
    require(crydrController != _crydrController);

    crydrController = _crydrController;
    CrydrControllerChangedEvent(_crydrController);
  }

  function getCrydrController() public constant returns (address) {
    return crydrController;
  }


  function getCrydrViewStandardName() public constant returns (string) {
    return crydrViewStandardName;
  }

  function getCrydrViewStandardNameHash() public constant returns (bytes32) {
    return keccak256(crydrViewStandardName);
  }


   

   
  function unpauseContract() public {
    require(isContract(crydrController) == true);
    require(getAssetIDHash() == AssetIDInterface(crydrController).getAssetIDHash());

    super.unpauseContract();
  }
}



 
contract CrydrViewERC20Interface {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address _to, uint256 _value) external returns (bool);
  function totalSupply() external constant returns (uint256);
  function balanceOf(address _owner) external constant returns (uint256);

  function approve(address _spender, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint256);
}



contract CrydrViewERC20 is PausableInterface,
                           CrydrViewBaseInterface,
                           CrydrViewERC20Interface {

   

  function transfer(
    address _to,
    uint256 _value
  )
    external
    whenContractNotPaused
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    CrydrControllerERC20Interface(getCrydrController()).transfer(msg.sender, _to, _value);
    return true;
  }

  function totalSupply() external constant returns (uint256) {
    return CrydrControllerERC20Interface(getCrydrController()).getTotalSupply();
  }

  function balanceOf(address _owner) external constant onlyPayloadSize(1 * 32) returns (uint256) {
    return CrydrControllerERC20Interface(getCrydrController()).getBalance(_owner);
  }


  function approve(
    address _spender,
    uint256 _value
  )
    external
    whenContractNotPaused
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    CrydrControllerERC20Interface(getCrydrController()).approve(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    external
    whenContractNotPaused
    onlyPayloadSize(3 * 32)
    returns (bool)
  {
    CrydrControllerERC20Interface(getCrydrController()).transferFrom(msg.sender, _from, _to, _value);
    return true;
  }

  function allowance(
    address _owner,
    address _spender
  )
    external
    constant
    onlyPayloadSize(2 * 32)
    returns (uint256)
  {
    return CrydrControllerERC20Interface(getCrydrController()).getAllowance(_owner, _spender);
  }


   

   
  modifier onlyPayloadSize(uint256 size) {
    require(msg.data.length == (size + 4));
    _;
  }
}



 
contract CrydrViewERC20LoggableInterface {

  function emitTransferEvent(address _from, address _to, uint256 _value) external;
  function emitApprovalEvent(address _owner, address _spender, uint256 _value) external;
}



contract CrydrViewERC20Loggable is PausableInterface,
                                   CrydrViewBaseInterface,
                                   CrydrViewERC20Interface,
                                   CrydrViewERC20LoggableInterface {

  function emitTransferEvent(
    address _from,
    address _to,
    uint256 _value
  )
    external
  {
    require(msg.sender == getCrydrController());

    Transfer(_from, _to, _value);
  }

  function emitApprovalEvent(
    address _owner,
    address _spender,
    uint256 _value
  )
    external
  {
    require(msg.sender == getCrydrController());

    Approval(_owner, _spender, _value);
  }
}



 
contract CrydrViewERC20MintableInterface {
  event MintEvent(address indexed owner, uint256 value);
  event BurnEvent(address indexed owner, uint256 value);

  function emitMintEvent(address _owner, uint256 _value) external;
  function emitBurnEvent(address _owner, uint256 _value) external;
}



contract CrydrViewERC20Mintable is PausableInterface,
                                   CrydrViewBaseInterface,
                                   CrydrViewERC20MintableInterface {

  function emitMintEvent(
    address _owner,
    uint256 _value
  )
    external
  {
    require(msg.sender == getCrydrController());

    MintEvent(_owner, _value);
  }

  function emitBurnEvent(
    address _owner,
    uint256 _value
  )
    external
  {
    require(msg.sender == getCrydrController());

    BurnEvent(_owner, _value);
  }
}



 
contract CrydrViewERC20NamedInterface {

  function name() external constant returns (string);
  function symbol() external constant returns (string);
  function decimals() external constant returns (uint8);

  function getNameHash() external constant returns (bytes32);
  function getSymbolHash() external constant returns (bytes32);

  function setName(string _name) external;
  function setSymbol(string _symbol) external;
  function setDecimals(uint8 _decimals) external;
}



contract CrydrViewERC20Named is ManageableInterface,
                                PausableInterface,
                                CrydrViewERC20NamedInterface {

   

  string tokenName = '';
  string tokenSymbol = '';
  uint8 tokenDecimals = 0;


   

  function CrydrViewERC20Named(string _name, string _symbol, uint8 _decimals) public {
    require(bytes(_name).length > 0);
    require(bytes(_symbol).length > 0);

    tokenName = _name;
    tokenSymbol = _symbol;
    tokenDecimals = _decimals;
  }


   

  function name() external constant returns (string) {
    return tokenName;
  }

  function symbol() external constant returns (string) {
    return tokenSymbol;
  }

  function decimals() external constant returns (uint8) {
    return tokenDecimals;
  }


  function getNameHash() external constant returns (bytes32){
    return keccak256(tokenName);
  }

  function getSymbolHash() external constant returns (bytes32){
    return keccak256(tokenSymbol);
  }


  function setName(
    string _name
  )
    external
    whenContractPaused
    onlyAllowedManager('set_crydr_name')
  {
    require(bytes(_name).length > 0);

    tokenName = _name;
  }

  function setSymbol(
    string _symbol
  )
    external
    whenContractPaused
    onlyAllowedManager('set_crydr_symbol')
  {
    require(bytes(_symbol).length > 0);

    tokenSymbol = _symbol;
  }

  function setDecimals(
    uint8 _decimals
  )
    external
    whenContractPaused
    onlyAllowedManager('set_crydr_decimals')
  {
    tokenDecimals = _decimals;
  }
}



contract JCashCrydrViewERC20 is CommonModifiers,
                                AssetID,
                                Ownable,
                                Manageable,
                                Pausable,
                                BytecodeExecutor,
                                CrydrViewBase,
                                CrydrViewERC20,
                                CrydrViewERC20Loggable,
                                CrydrViewERC20Mintable,
                                CrydrViewERC20Named {

  function JCashCrydrViewERC20(string _assetID, string _name, string _symbol, uint8 _decimals)
    public
    AssetID(_assetID)
    CrydrViewBase('erc20')
    CrydrViewERC20Named(_name, _symbol, _decimals)
  { }
}



contract JNTViewERC20 is JCashCrydrViewERC20 {
  function JNTViewERC20() public JCashCrydrViewERC20('JNT', 'Jibrel Network Token', 'JNT', 18) {}
}