 

 

pragma solidity ^0.4.24;


 
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


 
contract CrydrViewERC20LoggableInterface {

  function emitTransferEvent(address _from, address _to, uint256 _value) external;
  function emitApprovalEvent(address _owner, address _spender, uint256 _value) external;
}


 
contract CrydrStorageERC20Interface {

   

  event CrydrTransferredEvent(address indexed from, address indexed to, uint256 value);
  event CrydrTransferredFromEvent(address indexed spender, address indexed from, address indexed to, uint256 value);
  event CrydrSpendingApprovedEvent(address indexed owner, address indexed spender, uint256 value);


   

  function transfer(address _msgsender, address _to, uint256 _value) public;
  function transferFrom(address _msgsender, address _from, address _to, uint256 _value) public;
  function approve(address _msgsender, address _spender, uint256 _value) public;
}


 
contract CrydrControllerBaseInterface {

   

  event CrydrStorageChangedEvent(address indexed crydrstorage);
  event CrydrViewAddedEvent(address indexed crydrview, bytes32 standardname);
  event CrydrViewRemovedEvent(address indexed crydrview, bytes32 standardname);


   

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


 
contract JNTPaymentGatewayInterface {

   

  event JNTChargedEvent(address indexed payableservice, address indexed from, address indexed to, uint256 value);


   

  function chargeJNT(address _from, address _to, uint256 _value) public;
}


 
contract JNTPaymentGateway is ManageableInterface,
                              CrydrControllerBaseInterface,
                              JNTPaymentGatewayInterface {

  function chargeJNT(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyAllowedManager('jnt_payable_service')
  {
    CrydrStorageERC20Interface(getCrydrStorageAddress()).transfer(_from, _to, _value);

    emit JNTChargedEvent(msg.sender, _from, _to, _value);
    if (isCrydrViewRegistered('erc20') == true) {
      CrydrViewERC20LoggableInterface(getCrydrViewAddress('erc20')).emitTransferEvent(_from, _to, _value);
    }
  }
}



 
contract JNTPayableServiceInterface {

   

  event JNTControllerChangedEvent(address jntcontroller);
  event JNTBeneficiaryChangedEvent(address jntbeneficiary);
  event JNTChargedEvent(address indexed payer, address indexed to, uint256 value, bytes32 actionname);


   

  function setJntController(address _jntController) external;
  function getJntController() public constant returns (address);

  function setJntBeneficiary(address _jntBeneficiary) external;
  function getJntBeneficiary() public constant returns (address);

  function setActionPrice(string _actionName, uint256 _jntPriceWei) external;
  function getActionPrice(string _actionName) public constant returns (uint256);


   

  function initChargeJNT(address _payer, string _actionName) internal;
}


contract JNTPayableService is CommonModifiersInterface,
                              ManageableInterface,
                              PausableInterface,
                              JNTPayableServiceInterface {

   

  JNTPaymentGateway jntController;
  address jntBeneficiary;
  mapping (string => uint256) actionPrice;


   

  function setJntController(
    address _jntController
  )
    external
    onlyContractAddress(_jntController)
    onlyAllowedManager('set_jnt_controller')
    whenContractPaused
  {
    require(_jntController != address(jntController));

    jntController = JNTPaymentGateway(_jntController);

    emit JNTControllerChangedEvent(_jntController);
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

    emit JNTBeneficiaryChangedEvent(jntBeneficiary);
  }

  function getJntBeneficiary() public constant returns (address) {
    return jntBeneficiary;
  }


  function setActionPrice(
    string _actionName,
    uint256 _jntPriceWei
  )
    external
    onlyAllowedManager('set_action_price')
    onlyValidActionName(_actionName)
    whenContractPaused
  {
    require (_jntPriceWei > 0);

    actionPrice[_actionName] = _jntPriceWei;
  }

  function getActionPrice(
    string _actionName
  )
    public
    constant
    onlyValidActionName(_actionName)
    returns (uint256)
  {
    return actionPrice[_actionName];
  }


   

  function initChargeJNT(
    address _from,
    string _actionName
  )
    internal
    onlyValidActionName(_actionName)
    whenContractNotPaused
  {
    require(_from != address(0x0));
    require(_from != jntBeneficiary);

    uint256 _actionPrice = getActionPrice(_actionName);
    require (_actionPrice > 0);

    jntController.chargeJNT(_from, jntBeneficiary, _actionPrice);

    emit JNTChargedEvent(_from, jntBeneficiary, _actionPrice, keccak256(_actionName));
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

   
  modifier onlyValidActionName(string _actionName) {
    require(bytes(_actionName).length != 0);
    _;
  }
}


 
contract JcashRegistrarInterface {

   

  event ReceiveEthEvent(address indexed from, uint256 value);
  event RefundEthEvent(bytes32 txhash, address indexed to, uint256 value);
  event TransferEthEvent(bytes32 txhash, address indexed to, uint256 value);

  event RefundTokenEvent(bytes32 txhash, address indexed tokenaddress, address indexed to, uint256 value);
  event TransferTokenEvent(bytes32 txhash, address indexed tokenaddress, address indexed to, uint256 value);

  event ReplenishEthEvent(address indexed from, uint256 value);
  event WithdrawEthEvent(address indexed to, uint256 value);
  event WithdrawTokenEvent(address indexed tokenaddress, address indexed to, uint256 value);

  event PauseEvent();
  event UnpauseEvent();


   

   
  function withdrawEth(uint256 _weivalue) external;

   
  function withdrawToken(address _tokenAddress, uint256 _weivalue) external;


   

   
  function refundEth(bytes32 _txHash, address _to, uint256 _weivalue) external;

   
  function refundToken(bytes32 _txHash, address _tokenAddress, address _to, uint256 _weivalue) external;

   
  function transferEth(bytes32 _txHash, address _to, uint256 _weivalue) external;

   
  function transferToken(bytes32 _txHash, address _tokenAddress, address _to, uint256 _weivalue) external;


   

   
  function isProcessedTx(bytes32 _txHash) public view returns (bool);
}


 
contract JcashRegistrar is CommonModifiers,
                           Ownable,
                           Manageable,
                           Pausable,
                           JNTPayableService,
                           JcashRegistrarInterface {

   

  mapping (bytes32 => bool) processedTxs;


   

  event ReceiveEthEvent(address indexed from, uint256 value);
  event RefundEthEvent(bytes32 txhash, address indexed to, uint256 value);
  event TransferEthEvent(bytes32 txhash, address indexed to, uint256 value);
  event RefundTokenEvent(bytes32 txhash, address indexed tokenaddress, address indexed to, uint256 value);
  event TransferTokenEvent(bytes32 txhash, address indexed tokenaddress, address indexed to, uint256 value);

  event ReplenishEthEvent(address indexed from, uint256 value);
  event WithdrawEthEvent(address indexed to, uint256 value);
  event WithdrawTokenEvent(address indexed tokenaddress, address indexed to, uint256 value);

  event PauseEvent();
  event UnpauseEvent();


   

   
  modifier onlyPayloadSize(uint256 size) {
    require(msg.data.length == (size + 4));

    _;
  }

   
  function () external payable {
    if (isManagerAllowed(msg.sender, 'replenish_eth')==true) {
      emit ReplenishEthEvent(msg.sender, msg.value);
    } else {
      require (getPaused() == false);
      emit ReceiveEthEvent(msg.sender, msg.value);
    }
  }


   

   
  function withdrawEth(
    uint256 _weivalue
  )
    external
    onlyAllowedManager('replenish_eth')
    onlyPayloadSize(1 * 32)
  {
    require (_weivalue > 0);

    address(msg.sender).transfer(_weivalue);
    emit WithdrawEthEvent(msg.sender, _weivalue);
  }

   
  function withdrawToken(
    address _tokenAddress,
    uint256 _weivalue
  )
    external
    onlyAllowedManager('replenish_token')
    onlyPayloadSize(2 * 32)
  {
    require (_tokenAddress != address(0x0));
    require (_tokenAddress != address(this));
    require (_weivalue > 0);

    CrydrViewERC20Interface(_tokenAddress).transfer(msg.sender, _weivalue);
    emit WithdrawTokenEvent(_tokenAddress, msg.sender, _weivalue);
  }


   

   
  function refundEth(
    bytes32 _txHash,
    address _to,
    uint256 _weivalue
  )
    external
    onlyAllowedManager('refund_eth')
    whenContractNotPaused
    onlyPayloadSize(3 * 32)
  {
    require (_txHash != bytes32(0));
    require (processedTxs[_txHash] == false);
    require (_to != address(0x0));
    require (_to != address(this));
    require (_weivalue > 0);

    processedTxs[_txHash] = true;
    _to.transfer(_weivalue);

    emit RefundEthEvent(_txHash, _to, _weivalue);
  }

   
  function refundToken(
    bytes32 _txHash,
    address _tokenAddress,
    address _to,
    uint256 _weivalue
  )
    external
    onlyAllowedManager('refund_token')
    whenContractNotPaused
    onlyPayloadSize(4 * 32)
  {
    require (_txHash != bytes32(0));
    require (processedTxs[_txHash] == false);
    require (_tokenAddress != address(0x0));
    require (_tokenAddress != address(this));
    require (_to != address(0x0));
    require (_to != address(this));
    require (_weivalue > 0);

    processedTxs[_txHash] = true;
    CrydrViewERC20Interface(_tokenAddress).transfer(_to, _weivalue);

    emit RefundTokenEvent(_txHash, _tokenAddress, _to, _weivalue);
  }

   
  function transferEth(
    bytes32 _txHash,
    address _to,
    uint256 _weivalue
  )
    external
    onlyAllowedManager('transfer_eth')
    whenContractNotPaused
    onlyPayloadSize(3 * 32)
  {
    require (_txHash != bytes32(0));
    require (processedTxs[_txHash] == false);
    require (_to != address(0x0));
    require (_to != address(this));
    require (_weivalue > 0);

    processedTxs[_txHash] = true;
    _to.transfer(_weivalue);

    if (getActionPrice('transfer_eth') > 0) {
      initChargeJNT(_to, 'transfer_eth');
    }

    emit TransferEthEvent(_txHash, _to, _weivalue);
  }

   
  function transferToken(
    bytes32 _txHash,
    address _tokenAddress,
    address _to,
    uint256 _weivalue
  )
    external
    onlyAllowedManager('transfer_token')
    whenContractNotPaused
    onlyPayloadSize(4 * 32)
  {
    require (_txHash != bytes32(0));
    require (processedTxs[_txHash] == false);
    require (_tokenAddress != address(0x0));
    require (_tokenAddress != address(this));
    require (_to != address(0x0));
    require (_to != address(this));

    processedTxs[_txHash] = true;
    CrydrViewERC20Interface(_tokenAddress).transfer(_to, _weivalue);

    if (getActionPrice('transfer_token') > 0) {
      initChargeJNT(_to, 'transfer_token');
    }

    emit TransferTokenEvent(_txHash, _tokenAddress, _to, _weivalue);
  }


   

   
  function isProcessedTx(
    bytes32 _txHash
  )
    public
    view
    onlyPayloadSize(1 * 32)
    returns (bool)
  {
    require (_txHash != bytes32(0));
    return processedTxs[_txHash];
  }
}