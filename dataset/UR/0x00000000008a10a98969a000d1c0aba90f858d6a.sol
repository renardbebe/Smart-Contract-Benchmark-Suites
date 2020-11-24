 

pragma solidity 0.5.11;  


interface DharmaUpgradeBeaconControllerManagerInterface {
   
  event AdharmaContingencyActivated();
  event AdharmaContingencyExited();

   
  struct AdharmaContingency {
    bool armed;
    bool activated;
    uint256 activationTime;
  }

   
  struct PriorImplementation {
    address implementation;
    bool rollbackBlocked;
  }

  function initiateUpgrade(
    address controller,
    address beacon,
    address implementation,
    uint256 extraTime
  ) external;

  function upgrade(
    address controller, address beacon, address implementation
  ) external;

  function agreeToAcceptControllerOwnership(
    address controller, bool willAcceptOwnership
  ) external;

  function initiateTransferControllerOwnership(
    address controller, address newOwner, uint256 extraTime
  ) external;

  function transferControllerOwnership(
    address controller, address newOwner
  ) external;

  function heartbeat() external;

  function newHeartbeater(address heartbeater) external;

  function armAdharmaContingency(bool armed) external;

  function activateAdharmaContingency() external;

  function rollback(address controller, address beacon, uint256 index) external;

  function blockRollback(
    address controller, address beacon, uint256 index
  ) external;

  function exitAdharmaContingency(
    address smartWalletImplementation, address keyRingImplementation
  ) external;

  function getTotalPriorImplementations(
    address controller, address beacon
  ) external view returns (uint256 totalPriorImplementations);

  function getPriorImplementation(
    address controller, address beacon, uint256 index
  ) external view returns (address priorImplementation, bool rollbackAllowed);

  function contingencyStatus() external view returns (
    bool armed, bool activated, uint256 activationTime
  );

  function heartbeatStatus() external view returns (
    bool expired, uint256 expirationTime
  );
}


interface UpgradeBeaconControllerInterface {
  function upgrade(address beacon, address implementation) external;
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


interface IndestructibleRegistryCheckerInterface {
  function isRegisteredAsIndestructible(
    address target
  ) external view returns (bool registeredAsIndestructible);
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


 
contract Timelocker {
  using SafeMath for uint256;

   
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
     
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

     
    completionTime = uint256(_timelocks[functionSelector][timelockID].complete);
    exists = completionTime != 0;
    expirationTime = uint256(_timelocks[functionSelector][timelockID].expires);
    completed = exists && now > completionTime;
    expired = exists && now > expirationTime;
  }

   
  function getDefaultTimelockInterval(
    bytes4 functionSelector
  ) public view returns (uint256 defaultTimelockInterval) {
    defaultTimelockInterval = uint256(
      _timelockDefaults[functionSelector].interval
    );
  }

   
  function getDefaultTimelockExpiration(
    bytes4 functionSelector
  ) public view returns (uint256 defaultTimelockExpiration) {
    defaultTimelockExpiration = uint256(
      _timelockDefaults[functionSelector].expiration
    );
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

   
  function _enforceTimelock(bytes memory arguments) internal {
     
    _enforceTimelockPrivate(msg.sig, arguments);
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


 
contract DharmaUpgradeBeaconControllerManager is
  DharmaUpgradeBeaconControllerManagerInterface,
  TimelockerModifiersInterface,
  TwoStepOwnable,
  Timelocker {
  using SafeMath for uint256;

   
  mapping(address => mapping (address => PriorImplementation[])) private _implementations;

   
  mapping(address => mapping(address => bool)) private _willAcceptOwnership;

   
  AdharmaContingency private _adharma;

   
  uint256 private _lastHeartbeat;
  address private _heartbeater;

   
  address private constant _SMART_WALLET_UPGRADE_BEACON_CONTROLLER = address(
    0x00000000002226C940b74d674B85E4bE05539663
  );

   
  address private constant _DHARMA_SMART_WALLET_UPGRADE_BEACON = address(
    0x000000000026750c571ce882B17016557279ADaa
  );

   
  address private constant _ADHARMA_SMART_WALLET_IMPLEMENTATION = address(
    0x00000000009f22dA6fEB6735614563B9Af0339fB
  );

   
  address private constant _KEY_RING_UPGRADE_BEACON_CONTROLLER = address(
    0x00000000011dF015e8aD00D7B2486a88C2Eb8210
  );

   
  address private constant _DHARMA_KEY_RING_UPGRADE_BEACON = address(
    0x0000000000BDA2152794ac8c76B2dc86cbA57cad
  );

   
  address private constant _ADHARMA_KEY_RING_IMPLEMENTATION = address(
    0x000000000053d1F0F8aA88b9001Bec1B49445B3c
  );

   
  constructor() public {
     
    address extcodehashTarget;

     
    bytes32 smartWalletControllerHash;
    extcodehashTarget = _SMART_WALLET_UPGRADE_BEACON_CONTROLLER;
    assembly { smartWalletControllerHash := extcodehash(extcodehashTarget) }

     
    bytes32 smartWalletUpgradeBeaconHash;
    extcodehashTarget = _DHARMA_SMART_WALLET_UPGRADE_BEACON;
    assembly { smartWalletUpgradeBeaconHash := extcodehash(extcodehashTarget) }

     
    bytes32 adharmaSmartWalletHash;
    extcodehashTarget = _ADHARMA_SMART_WALLET_IMPLEMENTATION;
    assembly { adharmaSmartWalletHash := extcodehash(extcodehashTarget) }

     
    bytes32 keyRingControllerHash;
    extcodehashTarget = _KEY_RING_UPGRADE_BEACON_CONTROLLER;
    assembly { keyRingControllerHash := extcodehash(extcodehashTarget) }

     
    bytes32 keyRingUpgradeBeaconHash;
    extcodehashTarget = _DHARMA_KEY_RING_UPGRADE_BEACON;
    assembly { keyRingUpgradeBeaconHash := extcodehash(extcodehashTarget) }

     
    bytes32 adharmaKeyRingHash;
    extcodehashTarget = _ADHARMA_KEY_RING_IMPLEMENTATION;
    assembly { adharmaKeyRingHash := extcodehash(extcodehashTarget) }

     
    bool allRuntimeCodeHashesMatchExpectations = (
      smartWalletControllerHash == bytes32(
        0x6586626c057b68d99775ec4cae9aa5ce96907fb5f8d8c8046123f49f8ad93f1e
      ) &&
      smartWalletUpgradeBeaconHash == bytes32(
        0xca51e36cf6ab9af9a6f019a923588cd6df58aa1e58f5ac1639da46931167e436
      ) &&
      adharmaSmartWalletHash == bytes32(
        0xa8d641085d608420781e0b49768aa57d6e19dfeef227f839c33e2e00e2b8d82e
      ) &&
      keyRingControllerHash == bytes32(
        0xb98d105738145a629aeea247cee5f12bb25eabc1040eb01664bbc95f0e7e8d39
      ) &&
      keyRingUpgradeBeaconHash == bytes32(
        0xb65d03cdc199085ae86b460e897b6d53c08a6c6d436063ea29822ea80d90adc3
      ) &&
      adharmaKeyRingHash == bytes32(
        0xc5a2c3124a4bf13329ce188ce5813ad643bedd26058ae22958f6b23962070949
      )
    );

     
    require(
      allRuntimeCodeHashesMatchExpectations,
      "Runtime code hash of supplied upgradeability contracts is incorrect."
    );

     
    IndestructibleRegistryCheckerInterface indestructible;
    indestructible = IndestructibleRegistryCheckerInterface(
      0x0000000000f55ff05D0080fE17A63b16596Fd59f
    );

     
    require(
      indestructible.isRegisteredAsIndestructible(
        _SMART_WALLET_UPGRADE_BEACON_CONTROLLER
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _DHARMA_SMART_WALLET_UPGRADE_BEACON
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _ADHARMA_SMART_WALLET_IMPLEMENTATION
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _KEY_RING_UPGRADE_BEACON_CONTROLLER
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _DHARMA_KEY_RING_UPGRADE_BEACON
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _ADHARMA_KEY_RING_IMPLEMENTATION
      ),
      "Supplied upgradeability contracts are not registered as indestructible."
    );

     
    _setInitialTimelockInterval(
      this.transferControllerOwnership.selector, 4 weeks
    );
    _setInitialTimelockInterval(this.modifyTimelockInterval.selector, 4 weeks);
    _setInitialTimelockInterval(
      this.modifyTimelockExpiration.selector, 4 weeks
    );
    _setInitialTimelockInterval(this.upgrade.selector, 7 days);

     
    _setInitialTimelockExpiration(
      this.transferControllerOwnership.selector, 7 days
    );
    _setInitialTimelockExpiration(this.modifyTimelockInterval.selector, 7 days);
    _setInitialTimelockExpiration(
      this.modifyTimelockExpiration.selector, 7 days
    );
    _setInitialTimelockExpiration(this.upgrade.selector, 7 days);

     
    _heartbeater = tx.origin;
    _lastHeartbeat = now;
  }

   
  function initiateUpgrade(
    address controller,
    address beacon,
    address implementation,
    uint256 extraTime
  ) external onlyOwner {
    require(controller != address(0), "Must specify a controller address.");

    require(beacon != address(0), "Must specify a beacon address.");

     
    require(
      implementation != address(0),
      "Implementation cannot be the null address."
    );

     
    uint256 size;
    assembly {
      size := extcodesize(implementation)
    }
    require(size > 0, "Implementation must have contract code.");

     
    _setTimelock(
      this.upgrade.selector,
      abi.encode(controller, beacon, implementation),
      extraTime
    );
  }

   
  function upgrade(
    address controller, address beacon, address implementation
  ) external onlyOwner {
     
    _enforceTimelock(abi.encode(controller, beacon, implementation));

     
    _exitAdharmaContingencyIfActiveAndTriggerHeartbeat();

     
    _upgrade(controller, beacon, implementation);
  }

   
  function agreeToAcceptControllerOwnership(
    address controller, bool willAcceptOwnership
  ) external {
    require(controller != address(0), "Must specify a controller address.");

     
    _willAcceptOwnership[controller][msg.sender] = willAcceptOwnership;
  }

   
  function initiateTransferControllerOwnership(
    address controller, address newOwner, uint256 extraTime
  ) external onlyOwner {
    require(controller != address(0), "No controller address provided.");

    require(newOwner != address(0), "No new owner address provided.");

     
    require(
      _willAcceptOwnership[controller][newOwner],
      "New owner must agree to accept ownership of the given controller."
    );

     
    _setTimelock(
      this.transferControllerOwnership.selector,
      abi.encode(controller, newOwner),
      extraTime
    );
  }

   
  function transferControllerOwnership(
    address controller, address newOwner
  ) external onlyOwner {
     
    require(
      _willAcceptOwnership[controller][newOwner],
      "New owner must agree to accept ownership of the given controller."
    );

     
    _enforceTimelock(abi.encode(controller, newOwner));

     
    TwoStepOwnable(controller).transferOwnership(newOwner);
  }

   
  function heartbeat() external {
    require(msg.sender == _heartbeater, "Must be called from the heartbeater.");
    _lastHeartbeat = now;
  }

   
  function newHeartbeater(address heartbeater) external onlyOwner {
    require(heartbeater != address(0), "Must specify a heartbeater address.");
    _heartbeater = heartbeater;
  }

   
  function armAdharmaContingency(bool armed) external {
     
    _ensureCallerIsOwnerOrDeadmansSwitchActivated();

     
    _adharma.armed = armed;
  }

   
  function activateAdharmaContingency() external {
     
    _ensureCallerIsOwnerOrDeadmansSwitchActivated();

     
    require(
      _adharma.armed,
      "Adharma Contingency is not armed - are SURE you meant to call this?"
    );

     
    require(!_adharma.activated, "Adharma Contingency is already activated.");

     
    _ensureOwnershipOfSmartWalletAndKeyRingControllers();

     
    _adharma = AdharmaContingency({
      armed: false,
      activated: true,
      activationTime: now
    });

     
    _upgrade(
      _SMART_WALLET_UPGRADE_BEACON_CONTROLLER,
      _DHARMA_SMART_WALLET_UPGRADE_BEACON,
      _ADHARMA_SMART_WALLET_IMPLEMENTATION
    );
    _upgrade(
      _KEY_RING_UPGRADE_BEACON_CONTROLLER,
      _DHARMA_KEY_RING_UPGRADE_BEACON,
      _ADHARMA_KEY_RING_IMPLEMENTATION
    );

     
    emit AdharmaContingencyActivated();
  }

   
  function rollback(
    address controller, address beacon, uint256 index
  ) external onlyOwner {
     
    require(
      _implementations[controller][beacon].length > index,
      "No implementation with the given index available to roll back to."
    );

     
    PriorImplementation memory priorImplementation = (
      _implementations[controller][beacon][index]
    );

     
    require(
      !priorImplementation.rollbackBlocked,
      "Rollbacks to this implementation have been permanently blocked."
    );

     
    _exitAdharmaContingencyIfActiveAndTriggerHeartbeat();

     
    _upgrade(controller, beacon, priorImplementation.implementation);
  }

   
  function blockRollback(
    address controller, address beacon, uint256 index
  ) external onlyOwner {
     
    require(
      _implementations[controller][beacon].length > index,
      "No implementation with the given index available to block."
    );

     
    require(
      !_implementations[controller][beacon][index].rollbackBlocked,
      "Rollbacks to this implementation are aleady blocked."
    );

     
    _implementations[controller][beacon][index].rollbackBlocked = true;
  }

   
  function exitAdharmaContingency(
    address smartWalletImplementation, address keyRingImplementation
  ) external onlyOwner {
     
    require(
      _adharma.activated, "Adharma Contingency is not currently activated."
    );

     
    require(
      now > _adharma.activationTime + 48 hours,
      "Cannot exit contingency with a new upgrade until 48 hours have elapsed."
    );

     
    _ensureOwnershipOfSmartWalletAndKeyRingControllers();

     
    _exitAdharmaContingencyIfActiveAndTriggerHeartbeat();

     
    _upgrade(
      _SMART_WALLET_UPGRADE_BEACON_CONTROLLER,
      _DHARMA_SMART_WALLET_UPGRADE_BEACON,
      smartWalletImplementation
    );
    _upgrade(
      _KEY_RING_UPGRADE_BEACON_CONTROLLER,
      _DHARMA_KEY_RING_UPGRADE_BEACON,
      keyRingImplementation
    );
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

   
  function getTotalPriorImplementations(
    address controller, address beacon
  ) external view returns (uint256 totalPriorImplementations) {
     
    totalPriorImplementations = _implementations[controller][beacon].length;
  }

   
  function getPriorImplementation(
    address controller, address beacon, uint256 index
  ) external view returns (address priorImplementation, bool rollbackAllowed) {
     
    require(
      _implementations[controller][beacon].length > index,
      "No implementation contract found with the given index."
    );

     
    PriorImplementation memory implementation = (
      _implementations[controller][beacon][index]
    );

    priorImplementation = implementation.implementation;
    rollbackAllowed = (
      priorImplementation != address(0) && !implementation.rollbackBlocked
    );
  }

   
  function contingencyStatus() external view returns (
    bool armed, bool activated, uint256 activationTime
  ) {
    AdharmaContingency memory adharma = _adharma;

    armed = adharma.armed;
    activated = adharma.activated;
    activationTime = adharma.activationTime;
  }

   
  function heartbeatStatus() external view returns (
    bool expired, uint256 expirationTime
  ) {
    (expired, expirationTime) = _heartbeatStatus();
  }

   
  function _heartbeatStatus() internal view returns (
    bool expired, uint256 expirationTime
  ) {
    expirationTime = _lastHeartbeat + 90 days;
    expired = now > expirationTime;
  }

   
  function _upgrade(
    address controller, address beacon, address implementation
  ) private {
     
    require(
      implementation != address(0),
      "Implementation cannot be the null address."
    );

     
    uint256 size;
    assembly {
      size := extcodesize(implementation)
    }
    require(size > 0, "Implementation must have contract code.");

     
    (bool ok, bytes memory returnData) = beacon.call("");
    if (ok && returnData.length == 32) {
      address currentImplementation = abi.decode(returnData, (address));

      _implementations[controller][beacon].push(PriorImplementation({
        implementation: currentImplementation,
        rollbackBlocked: false
      }));
    }

     
    UpgradeBeaconControllerInterface(controller).upgrade(
      beacon, implementation
    );
  }

   
  function _exitAdharmaContingencyIfActiveAndTriggerHeartbeat() private {
     
    if (_adharma.activated || _adharma.armed) {

       
      if (_adharma.activated) {
        emit AdharmaContingencyExited();
      }

      delete _adharma;
    }

     
    _lastHeartbeat = now;
  }

   
  function _ensureCallerIsOwnerOrDeadmansSwitchActivated() private view {
     
    if (!isOwner()) {
       
      (bool expired, ) = _heartbeatStatus();

       
      require(
        expired,
        "Only callable by the owner or after 90 days without a heartbeat."
      );
    }
  }

   
  function _ensureOwnershipOfSmartWalletAndKeyRingControllers() private view {
     
    require(
      TwoStepOwnable(_SMART_WALLET_UPGRADE_BEACON_CONTROLLER).isOwner(),
      "This contract no longer owns the Smart Wallet Upgrade Beacon Controller."
    );
    require(
      TwoStepOwnable(_KEY_RING_UPGRADE_BEACON_CONTROLLER).isOwner(),
      "This contract no longer owns the Key Ring Upgrade Beacon Controller."
    );
  }
}