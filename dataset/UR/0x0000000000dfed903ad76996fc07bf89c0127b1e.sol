 

pragma solidity 0.5.11;  


interface DharmaAccountRecoveryManagerInterface {
   
  event Recovery(
    address indexed wallet, address oldUserSigningKey, address newUserSigningKey
  );

   
  event RecoveryDisabled(address wallet);

  function initiateAccountRecovery(
    address smartWallet, address userSigningKey, uint256 extraTime
  ) external;

  function initiateAccountRecoveryDisablement(
    address smartWallet, uint256 extraTime
  ) external;

  function recover(address wallet, address newUserSigningKey) external;

  function disableAccountRecovery(address wallet) external;

  function accountRecoveryDisabled(
    address wallet
  ) external view returns (bool hasDisabledAccountRecovery);
}


interface DharmaAccountRecoveryManagerV2Interface {
   
  event RecoveryCancelled(
    address indexed wallet, address cancelledUserSigningKey
  );

  event RecoveryDisablementCancelled(address wallet);

  event RoleModified(Role indexed role, address account);

  event RolePaused(Role indexed role);

  event RoleUnpaused(Role indexed role);

  enum Role {
    OPERATOR,
    RECOVERER,
    CANCELLER,
    DISABLER,
    PAUSER
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  function cancelAccountRecovery(
    address smartWallet, address newUserSigningKey
  ) external;

  function cancelAccountRecoveryDisablement(address smartWallet) external;

  function setRole(Role role, address account) external;

  function removeRole(Role role) external;

  function pause(Role role) external;

  function unpause(Role role) external;

  function isPaused(Role role) external view returns (bool paused);

  function isRole(Role role) external view returns (bool hasRole);

  function getOperator() external view returns (address operator);

  function getRecoverer() external view returns (address recoverer);

  function getCanceller() external view returns (address canceller);

  function getDisabler() external view returns (address disabler);

  function getPauser() external view returns (address pauser);
}


interface TimelockerInterface {
   
  event TimelockInitiated(
    bytes4 functionSelector,  
    uint256 timeComplete,     
    bytes arguments,          
    uint256 timeExpired       
  );

   
  event TimelockIntervalModified(
    bytes4 functionSelector,  
    uint256 oldInterval,      
    uint256 newInterval       
  );

   
  event TimelockExpirationModified(
    bytes4 functionSelector,  
    uint256 oldExpiration,    
    uint256 newExpiration     
  );

   
  struct Timelock {
    uint128 complete;
    uint128 expires;
  }

   
  struct TimelockDefaults {
    uint128 interval;
    uint128 expiration;
  }

  function getTimelock(
    bytes4 functionSelector, bytes calldata arguments
  ) external view returns (
    bool exists,
    bool completed,
    bool expired,
    uint256 completionTime,
    uint256 expirationTime
  );

  function getDefaultTimelockInterval(
    bytes4 functionSelector
  ) external view returns (uint256 defaultTimelockInterval);

  function getDefaultTimelockExpiration(
    bytes4 functionSelector
  ) external view returns (uint256 defaultTimelockExpiration);
}


interface TimelockerModifiersInterface {
  function initiateModifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval, uint256 extraTime
  ) external;

  function modifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) external;

  function initiateModifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration, uint256 extraTime
  ) external;

  function modifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) external;
}


interface DharmaSmartWalletRecoveryInterface {
  function recover(address newUserSigningKey) external;
  function getUserSigningKey() external view returns (address userSigningKey);
}


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}


 
contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

   
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

   
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

   
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}


 
contract TimelockerV2 is TimelockerInterface {
  using SafeMath for uint256;

   
  mapping(bytes4 => mapping(bytes32 => Timelock)) private _timelocks;

   
  mapping(bytes4 => TimelockDefaults) private _timelockDefaults;

   
  mapping(bytes4 => mapping(bytes4 => bytes32)) private _protectedTimelockIDs;

   
  bytes4 private constant _MODIFY_TIMELOCK_INTERVAL_SELECTOR = bytes4(
    0xe950c085
  );

   
  bytes4 private constant _MODIFY_TIMELOCK_EXPIRATION_SELECTOR = bytes4(
    0xd7ce3c6f
  );

   
  uint256 private constant _A_TRILLION_YEARS = 365000000000000 days;

   
  constructor() internal {
    TimelockerModifiersInterface modifiers;

    bytes4 targetModifyInterval = modifiers.modifyTimelockInterval.selector;
    require(
      _MODIFY_TIMELOCK_INTERVAL_SELECTOR == targetModifyInterval,
      "Incorrect modify timelock interval selector supplied."
    );

    bytes4 targetModifyExpiration = modifiers.modifyTimelockExpiration.selector;
    require(
      _MODIFY_TIMELOCK_EXPIRATION_SELECTOR == targetModifyExpiration,
      "Incorrect modify timelock expiration selector supplied."
    );
  }

   
  function getTimelock(
    bytes4 functionSelector, bytes memory arguments
  ) public view returns (
    bool exists,
    bool completed,
    bool expired,
    uint256 completionTime,
    uint256 expirationTime
  ) {
     
    (exists, completed, expired, completionTime, expirationTime) = _getTimelock(
      functionSelector, arguments
    );
  }

   
  function getDefaultTimelockInterval(
    bytes4 functionSelector
  ) public view returns (uint256 defaultTimelockInterval) {
    defaultTimelockInterval = _getDefaultTimelockInterval(functionSelector);
  }

   
  function getDefaultTimelockExpiration(
    bytes4 functionSelector
  ) public view returns (uint256 defaultTimelockExpiration) {
    defaultTimelockExpiration = _getDefaultTimelockExpiration(functionSelector);
  }

   
  function _setTimelock(
    bytes4 functionSelector, bytes memory arguments, uint256 extraTime
  ) internal {
     
    require(extraTime < _A_TRILLION_YEARS, "Supplied extra time is too large.");

     
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

     
     
    if (
      functionSelector == _MODIFY_TIMELOCK_INTERVAL_SELECTOR ||
      functionSelector == _MODIFY_TIMELOCK_EXPIRATION_SELECTOR
    ) {
       
      (bytes4 modifiedFunction, uint256 duration) = abi.decode(
        arguments, (bytes4, uint256)
      );

       
      require(
        duration < _A_TRILLION_YEARS,
        "Supplied default timelock duration to modify is too large."
      );

       
      bytes32 currentTimelockID = (
        _protectedTimelockIDs[functionSelector][modifiedFunction]
      );

       
      if (currentTimelockID != timelockID) {
         
        if (currentTimelockID != bytes32(0)) {
          delete _timelocks[functionSelector][currentTimelockID];
        }

         
        _protectedTimelockIDs[functionSelector][modifiedFunction] = timelockID;
      }
    }

     
    uint256 timelock = uint256(
      _timelockDefaults[functionSelector].interval
    ).add(now).add(extraTime);

     
    uint256 expiration = timelock.add(
      uint256(_timelockDefaults[functionSelector].expiration)
    );

     
    Timelock storage timelockStorage = _timelocks[functionSelector][timelockID];

     
    uint256 currentTimelock = uint256(timelockStorage.complete);

     
     
     
     
     
     
    require(
      currentTimelock == 0 || timelock > currentTimelock,
      "Existing timelocks may only be extended."
    );

     
    timelockStorage.complete = uint128(timelock);
    timelockStorage.expires = uint128(expiration);

     
    emit TimelockInitiated(functionSelector, timelock, arguments, expiration);
  }

   
  function _modifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) internal {
     
    _enforceTimelockPrivate(
      _MODIFY_TIMELOCK_INTERVAL_SELECTOR,
      abi.encode(functionSelector, newTimelockInterval)
    );

     
    delete _protectedTimelockIDs[
      _MODIFY_TIMELOCK_INTERVAL_SELECTOR
    ][functionSelector];

     
    _setTimelockIntervalPrivate(functionSelector, newTimelockInterval);
  }

   
  function _modifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) internal {
     
    _enforceTimelockPrivate(
      _MODIFY_TIMELOCK_EXPIRATION_SELECTOR,
      abi.encode(functionSelector, newTimelockExpiration)
    );

     
    delete _protectedTimelockIDs[
      _MODIFY_TIMELOCK_EXPIRATION_SELECTOR
    ][functionSelector];

     
    _setTimelockExpirationPrivate(functionSelector, newTimelockExpiration);
  }

   
  function _setInitialTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) internal {
     
    assembly { if extcodesize(address) { revert(0, 0) } }

     
    _setTimelockIntervalPrivate(functionSelector, newTimelockInterval);
  }

   
  function _setInitialTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) internal {
     
    assembly { if extcodesize(address) { revert(0, 0) } }

     
    _setTimelockExpirationPrivate(functionSelector, newTimelockExpiration);
  }

   
  function _expireTimelock(
    bytes4 functionSelector, bytes memory arguments
  ) internal {
     
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

     
    Timelock storage timelock = _timelocks[functionSelector][timelockID];

    uint256 currentTimelock = uint256(timelock.complete);
    uint256 expiration = uint256(timelock.expires);

     
    require(currentTimelock != 0, "No timelock found for the given arguments.");

     
    require(expiration > now, "Timelock has already expired.");

     
    timelock.expires = uint128(0);
  }

   
  function _enforceTimelock(bytes memory arguments) internal {
     
    _enforceTimelockPrivate(msg.sig, arguments);
  }

   
  function _getTimelock(
    bytes4 functionSelector, bytes memory arguments
  ) internal view returns (
    bool exists,
    bool completed,
    bool expired,
    uint256 completionTime,
    uint256 expirationTime
  ) {
     
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

     
    completionTime = uint256(_timelocks[functionSelector][timelockID].complete);
    exists = completionTime != 0;
    expirationTime = uint256(_timelocks[functionSelector][timelockID].expires);
    completed = exists && now > completionTime;
    expired = exists && now > expirationTime;
  }

   
  function _getDefaultTimelockInterval(
    bytes4 functionSelector
  ) internal view returns (uint256 defaultTimelockInterval) {
    defaultTimelockInterval = uint256(
      _timelockDefaults[functionSelector].interval
    );
  }

   
  function _getDefaultTimelockExpiration(
    bytes4 functionSelector
  ) internal view returns (uint256 defaultTimelockExpiration) {
    defaultTimelockExpiration = uint256(
      _timelockDefaults[functionSelector].expiration
    );
  }

   
  function _enforceTimelockPrivate(
    bytes4 functionSelector, bytes memory arguments
  ) private {
     
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

     
    Timelock memory timelock = _timelocks[functionSelector][timelockID];

    uint256 currentTimelock = uint256(timelock.complete);
    uint256 expiration = uint256(timelock.expires);

     
    require(
      currentTimelock != 0 && currentTimelock <= now, "Timelock is incomplete."
    );

     
    require(expiration > now, "Timelock has expired.");

     
    delete _timelocks[functionSelector][timelockID];
  }

   
  function _setTimelockIntervalPrivate(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) private {
     
    require(
      newTimelockInterval < _A_TRILLION_YEARS,
      "Supplied minimum timelock interval is too large."
    );

     
    uint256 oldTimelockInterval = uint256(
      _timelockDefaults[functionSelector].interval
    );

     
    _timelockDefaults[functionSelector].interval = uint128(newTimelockInterval);

     
    emit TimelockIntervalModified(
      functionSelector, oldTimelockInterval, newTimelockInterval
    );
  }

   
  function _setTimelockExpirationPrivate(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) private {
     
    require(
      newTimelockExpiration < _A_TRILLION_YEARS,
      "Supplied default timelock expiration is too large."
    );

     
    require(
      newTimelockExpiration > 1 minutes,
      "New timelock expiration is too short."
    );

     
    uint256 oldTimelockExpiration = uint256(
      _timelockDefaults[functionSelector].expiration
    );

     
    _timelockDefaults[functionSelector].expiration = uint128(
      newTimelockExpiration
    );

     
    emit TimelockExpirationModified(
      functionSelector, oldTimelockExpiration, newTimelockExpiration
    );
  }
}


 
contract DharmaAccountRecoveryManagerV2 is
  DharmaAccountRecoveryManagerInterface,
  DharmaAccountRecoveryManagerV2Interface,
  TimelockerModifiersInterface,
  TwoStepOwnable,
  TimelockerV2 {
  using SafeMath for uint256;

   
  mapping(uint256 => RoleStatus) private _roles;

   
  mapping(address => bool) private _accountRecoveryDisabled;

   
  constructor() public {
     
    _setInitialTimelockInterval(this.modifyTimelockInterval.selector, 2 weeks);
    _setInitialTimelockInterval(
      this.modifyTimelockExpiration.selector, 2 weeks
    );
    _setInitialTimelockInterval(this.recover.selector, 3 days);
    _setInitialTimelockInterval(this.disableAccountRecovery.selector, 3 days);

     
    _setInitialTimelockExpiration(this.modifyTimelockInterval.selector, 7 days);
    _setInitialTimelockExpiration(
      this.modifyTimelockExpiration.selector, 7 days
    );
    _setInitialTimelockExpiration(this.recover.selector, 3 days);
    _setInitialTimelockExpiration(this.disableAccountRecovery.selector, 3 days);
  }

   
  function initiateAccountRecovery(
    address smartWallet, address userSigningKey, uint256 extraTime
  ) external onlyOwnerOr(Role.OPERATOR) {
    require(smartWallet != address(0), "No smart wallet address provided.");
    require(userSigningKey != address(0), "No new user signing key provided.");

     
    _setTimelock(
      this.recover.selector, abi.encode(smartWallet, userSigningKey), extraTime
    );
  }

   
  function recover(
    address smartWallet, address newUserSigningKey
  ) external onlyOwnerOr(Role.RECOVERER) {
    require(smartWallet != address(0), "No smart wallet address provided.");
    require(
      newUserSigningKey != address(0),
      "No new user signing key provided."
    );

     
    require(
      !_accountRecoveryDisabled[smartWallet],
      "This wallet has elected to opt out of account recovery functionality."
    );

     
    _enforceTimelock(abi.encode(smartWallet, newUserSigningKey));

     
    DharmaSmartWalletRecoveryInterface walletInterface;

     
    address oldUserSigningKey;
    (bool ok, bytes memory data) = smartWallet.call.gas(gasleft() / 2)(
      abi.encodeWithSelector(walletInterface.getUserSigningKey.selector)
    );
    if (ok && data.length == 32) {
      oldUserSigningKey = abi.decode(data, (address));
    }

     
    DharmaSmartWalletRecoveryInterface(smartWallet).recover(newUserSigningKey);

     
    emit Recovery(smartWallet, oldUserSigningKey, newUserSigningKey);
  }

   
  function initiateAccountRecoveryDisablement(
    address smartWallet, uint256 extraTime
  ) external onlyOwnerOr(Role.OPERATOR) {
    require(smartWallet != address(0), "No smart wallet address provided.");

     
    _setTimelock(
      this.disableAccountRecovery.selector, abi.encode(smartWallet), extraTime
    );
  }

   
  function disableAccountRecovery(
    address smartWallet
  ) external onlyOwnerOr(Role.DISABLER) {
    require(smartWallet != address(0), "No smart wallet address provided.");

     
    _enforceTimelock(abi.encode(smartWallet));

     
    _accountRecoveryDisabled[smartWallet] = true;

     
    emit RecoveryDisabled(smartWallet);
  }

   
  function cancelAccountRecovery(
    address smartWallet, address userSigningKey
  ) external onlyOwnerOr(Role.CANCELLER) {
    require(smartWallet != address(0), "No smart wallet address provided.");
    require(userSigningKey != address(0), "No user signing key provided.");

     
    _expireTimelock(
      this.recover.selector, abi.encode(smartWallet, userSigningKey)
    );

     
    emit RecoveryCancelled(smartWallet, userSigningKey);
  }

   
  function cancelAccountRecoveryDisablement(
    address smartWallet
  ) external onlyOwnerOr(Role.CANCELLER) {
    require(smartWallet != address(0), "No smart wallet address provided.");

     
    _expireTimelock(
      this.disableAccountRecovery.selector, abi.encode(smartWallet)
    );

     
    emit RecoveryDisablementCancelled(smartWallet);
  }

   
  function pause(Role role) external onlyOwnerOr(Role.PAUSER) {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(!storedRoleStatus.paused, "Role in question is already paused.");
    storedRoleStatus.paused = true;
    emit RolePaused(role);
  }

   
  function unpause(Role role) external onlyOwner {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(storedRoleStatus.paused, "Role in question is already unpaused.");
    storedRoleStatus.paused = false;
    emit RoleUnpaused(role);
  }

   
  function initiateModifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval, uint256 extraTime
  ) external onlyOwner {
     
    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );

     
    if (functionSelector == this.modifyTimelockInterval.selector) {
      require(
        newTimelockInterval <= 8 weeks,
        "Timelock interval of modifyTimelockInterval cannot exceed eight weeks."
      );
    }

     
    _setTimelock(
      this.modifyTimelockInterval.selector,
      abi.encode(functionSelector, newTimelockInterval),
      extraTime
    );
  }

   
  function modifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) external onlyOwner {
     
    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );

     
    _modifyTimelockInterval(functionSelector, newTimelockInterval);
  }

   
  function initiateModifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration, uint256 extraTime
  ) external onlyOwner {
     
    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );

     
    require(
      newTimelockExpiration <= 30 days,
      "New timelock expiration cannot exceed one month."
    );

     
    if (functionSelector == this.modifyTimelockExpiration.selector) {
      require(
        newTimelockExpiration >= 60 minutes,
        "Expiration of modifyTimelockExpiration must be at least an hour long."
      );
    }

     
    _setTimelock(
      this.modifyTimelockExpiration.selector,
      abi.encode(functionSelector, newTimelockExpiration),
      extraTime
    );
  }

   
  function modifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) external onlyOwner {
     
    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );

     
    _modifyTimelockExpiration(
      functionSelector, newTimelockExpiration
    );
  }

   
  function setRole(Role role, address account) external onlyOwner {
    require(account != address(0), "Must supply an account.");
    _setRole(role, account);
  }

   
  function removeRole(Role role) external onlyOwner {
    _setRole(role, address(0));
  }

   
  function accountRecoveryDisabled(
    address smartWallet
  ) external view returns (bool hasDisabledAccountRecovery) {
     
    hasDisabledAccountRecovery = _accountRecoveryDisabled[smartWallet];
  }

   
  function isPaused(Role role) external view returns (bool paused) {
    paused = _isPaused(role);
  }

   
  function isRole(Role role) external view returns (bool hasRole) {
    hasRole = _isRole(role);
  }

   
  function getOperator() external view returns (address operator) {
    operator = _roles[uint256(Role.OPERATOR)].account;
  }

   
  function getRecoverer() external view returns (address recoverer) {
    recoverer = _roles[uint256(Role.RECOVERER)].account;
  }

   
  function getCanceller() external view returns (address canceller) {
    canceller = _roles[uint256(Role.CANCELLER)].account;
  }

   
  function getDisabler() external view returns (address disabler) {
    disabler = _roles[uint256(Role.DISABLER)].account;
  }

   
  function getPauser() external view returns (address pauser) {
    pauser = _roles[uint256(Role.PAUSER)].account;
  }

   
  function _setRole(Role role, address account) internal {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];

    if (account != storedRoleStatus.account) {
      storedRoleStatus.account = account;
      emit RoleModified(role, account);
    }
  }

   
  function _isRole(Role role) internal view returns (bool hasRole) {
    hasRole = msg.sender == _roles[uint256(role)].account;
  }

   
  function _isPaused(Role role) internal view returns (bool paused) {
    paused = _roles[uint256(role)].paused;
  }

   
  modifier onlyOwnerOr(Role role) {
    if (!isOwner()) {
      require(_isRole(role), "Caller does not have a required role.");
      require(!_isPaused(role), "Role in question is currently paused.");
    }
    _;
  }
}