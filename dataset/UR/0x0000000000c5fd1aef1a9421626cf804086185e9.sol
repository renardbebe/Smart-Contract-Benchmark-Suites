 

pragma solidity 0.4.26;  


 


 
library ECDSA {
   
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (signature.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}


 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}


 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}


 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor(address owner) internal {
    _owner = owner;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


 
interface AttributeRegistryInterface {
   
  function hasAttribute(
    address account,
    uint256 attributeTypeID
  ) external view returns (bool);

   
  function getAttributeValue(
    address account,
    uint256 attributeTypeID
  ) external view returns (uint256);

   
  function countAttributeTypes() external view returns (uint256);

   
  function getAttributeTypeID(uint256 index) external view returns (uint256);
}


 
interface BasicJurisdictionInterface {
   
  event AttributeTypeAdded(uint256 indexed attributeTypeID, string description);
  
  event AttributeTypeRemoved(uint256 indexed attributeTypeID);
  
  event ValidatorAdded(address indexed validator, string description);
  
  event ValidatorRemoved(address indexed validator);
  
  event ValidatorApprovalAdded(
    address validator,
    uint256 indexed attributeTypeID
  );

  event ValidatorApprovalRemoved(
    address validator,
    uint256 indexed attributeTypeID
  );

  event AttributeAdded(
    address validator,
    address indexed attributee,
    uint256 attributeTypeID,
    uint256 attributeValue
  );

  event AttributeRemoved(
    address validator,
    address indexed attributee,
    uint256 attributeTypeID
  );

   
  function addAttributeType(uint256 ID, string description) external;

   
  function removeAttributeType(uint256 ID) external;

   
  function addValidator(address validator, string description) external;

   
  function removeValidator(address validator) external;

   
  function addValidatorApproval(
    address validator,
    uint256 attributeTypeID
  ) external;

   
  function removeValidatorApproval(
    address validator,
    uint256 attributeTypeID
  ) external;

   
  function issueAttribute(
    address account,
    uint256 attributeTypeID,
    uint256 value
  ) external payable;

   
  function revokeAttribute(
    address account,
    uint256 attributeTypeID
  ) external;

   
  function canIssueAttributeType(
    address validator,
    uint256 attributeTypeID
  ) external view returns (bool);

   
  function getAttributeTypeDescription(
    uint256 attributeTypeID
  ) external view returns (string description);
  
   
  function getValidatorDescription(
    address validator
  ) external view returns (string description);

   
  function getAttributeValidator(
    address account,
    uint256 attributeTypeID
  ) external view returns (address validator, bool isStillValid);

   
  function countAttributeTypes() external view returns (uint256);

   
  function getAttributeTypeID(uint256 index) external view returns (uint256);

   
  function getAttributeTypeIDs() external view returns (uint256[]);

   
  function countValidators() external view returns (uint256);

   
  function getValidator(uint256 index) external view returns (address);

   
  function getValidators() external view returns (address[]);
}

 
interface ExtendedJurisdictionInterface {
   
  event ValidatorSigningKeyModified(
    address indexed validator,
    address newSigningKey
  );

  event StakeAllocated(
    address indexed staker,
    uint256 indexed attribute,
    uint256 amount
  );

  event StakeRefunded(
    address indexed staker,
    uint256 indexed attribute,
    uint256 amount
  );

  event FeePaid(
    address indexed recipient,
    address indexed payee,
    uint256 indexed attribute,
    uint256 amount
  );
  
  event TransactionRebatePaid(
    address indexed submitter,
    address indexed payee,
    uint256 indexed attribute,
    uint256 amount
  );

   
  function addRestrictedAttributeType(uint256 ID, string description) external;

   
  function setAttributeTypeOnlyPersonal(uint256 ID, bool onlyPersonal) external;

   
  function setAttributeTypeSecondarySource(
    uint256 ID,
    address attributeRegistry,
    uint256 sourceAttributeTypeID
  ) external;

   
  function setAttributeTypeMinimumRequiredStake(
    uint256 ID,
    uint256 minimumRequiredStake
  ) external;

   
  function setAttributeTypeJurisdictionFee(uint256 ID, uint256 fee) external;

   
  function setValidatorSigningKey(address newSigningKey) external;

   
  function addAttribute(
    uint256 attributeTypeID,
    uint256 value,
    uint256 validatorFee,
    bytes signature
  ) external payable;

   
  function removeAttribute(uint256 attributeTypeID) external;

   
  function addAttributeFor(
    address account,
    uint256 attributeTypeID,
    uint256 value,
    uint256 validatorFee,
    bytes signature
  ) external payable;

   
  function removeAttributeFor(address account, uint256 attributeTypeID) external;

   
  function invalidateAttributeApproval(
    bytes32 hash,
    bytes signature
  ) external;

   
  function getAttributeApprovalHash(
    address account,
    address operator,
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee
  ) external view returns (bytes32 hash);

   
  function canAddAttribute(
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee,
    bytes signature
  ) external view returns (bool);

   
  function canAddAttributeFor(
    address account,
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee,
    bytes signature
  ) external view returns (bool);

   
  function getAttributeTypeInformation(
    uint256 attributeTypeID
  ) external view returns (
    string description,
    bool isRestricted,
    bool isOnlyPersonal,
    address secondarySource,
    uint256 secondaryId,
    uint256 minimumRequiredStake,
    uint256 jurisdictionFee
  );
  
   
  function getValidatorSigningKey(
    address validator
  ) external view returns (
    address signingKey
  );
}

 
interface IERC20 {
  function balanceOf(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
}

 
contract ExtendedJurisdiction is Ownable, Pausable, AttributeRegistryInterface, BasicJurisdictionInterface, ExtendedJurisdictionInterface {
  using ECDSA for bytes32;
  using SafeMath for uint256;

   
  struct Validator {
    bool exists;
    uint256 index;  
    address signingKey;
    string description;
  }

   
  struct IssuedAttribute {
    bool exists;
    bool setPersonally;
    address operator;
    address validator;
    uint256 value;
    uint256 stake;
  }

   
  struct AttributeType {
    bool exists;
    bool restricted;
    bool onlyPersonal;
    uint256 index;  
    address secondarySource;
    uint256 secondaryAttributeTypeID;
    uint256 minimumStake;
    uint256 jurisdictionFee;
    string description;
    mapping(address => bool) approvedValidators;
  }

   
  mapping(uint256 => AttributeType) private _attributeTypes;

   
  mapping(address => mapping(uint256 => IssuedAttribute)) private _issuedAttributes;

   
  mapping(address => Validator) private _validators;

   
  mapping(address => address) private _signingKeys;

   
  mapping(uint256 => bytes32) private _attributeTypeHashes;

   
  mapping(bytes32 => bool) private _invalidAttributeApprovalHashes;

   
  mapping(address => uint256[]) private _validatorApprovals;

    
  mapping(address => mapping(uint256 => uint256)) private _validatorApprovalsIndex;

   
  uint256[] private _attributeIDs;

   
  address[] private _validatorAccounts;

   
  uint256 private _recoverableFunds;

   
  constructor(address owner) public Ownable(owner) {}

   
  function addAttributeType(
    uint256 ID,
    string description
  ) external onlyOwner whenNotPaused {
     
    require(
      !isAttributeType(ID),
      "an attribute type with the provided ID already exists"
    );

     
    bytes32 hash = keccak256(
      abi.encodePacked(
        ID, false, description
      )
    );

     
    if (_attributeTypeHashes[ID] == bytes32(0)) {
      _attributeTypeHashes[ID] = hash;
    }

     
    require(
      hash == _attributeTypeHashes[ID],
      "attribute type properties must match initial properties assigned to ID"
    );

     
    _attributeTypes[ID] = AttributeType({
      exists: true,
      restricted: false,  
      onlyPersonal: false,  
      index: _attributeIDs.length,
      secondarySource: address(0),  
      secondaryAttributeTypeID: uint256(0),  
      minimumStake: uint256(0),  
      jurisdictionFee: uint256(0),
      description: description
       
    });
    
     
    _attributeIDs.push(ID);

     
    emit AttributeTypeAdded(ID, description);
  }

   
  function addRestrictedAttributeType(
    uint256 ID,
    string description
  ) external onlyOwner whenNotPaused {
     
    require(
      !isAttributeType(ID),
      "an attribute type with the provided ID already exists"
    );

     
    bytes32 hash = keccak256(
      abi.encodePacked(
        ID, true, description
      )
    );

     
    if (_attributeTypeHashes[ID] == bytes32(0)) {
      _attributeTypeHashes[ID] = hash;
    }

     
    require(
      hash == _attributeTypeHashes[ID],
      "attribute type properties must match initial properties assigned to ID"
    );

     
    _attributeTypes[ID] = AttributeType({
      exists: true,
      restricted: true,  
      onlyPersonal: false,  
      index: _attributeIDs.length,
      secondarySource: address(0),  
      secondaryAttributeTypeID: uint256(0),  
      minimumStake: uint256(0),  
      jurisdictionFee: uint256(0),
      description: description
       
    });
    
     
    _attributeIDs.push(ID);

     
    emit AttributeTypeAdded(ID, description);
  }

   
  function setAttributeTypeOnlyPersonal(uint256 ID, bool onlyPersonal) external {
     
    require(
      isAttributeType(ID),
      "unable to set to only personal, no attribute type with the provided ID"
    );

     
    _attributeTypes[ID].onlyPersonal = onlyPersonal;
  }

   
  function setAttributeTypeSecondarySource(
    uint256 ID,
    address attributeRegistry,
    uint256 sourceAttributeTypeID
  ) external {
     
    require(
      isAttributeType(ID),
      "unable to set secondary source, no attribute type with the provided ID"
    );

     
    _attributeTypes[ID].secondarySource = attributeRegistry;
    _attributeTypes[ID].secondaryAttributeTypeID = sourceAttributeTypeID;
  }

   
  function setAttributeTypeMinimumRequiredStake(
    uint256 ID,
    uint256 minimumRequiredStake
  ) external {
     
    require(
      isAttributeType(ID),
      "unable to set minimum stake, no attribute type with the provided ID"
    );

     
    _attributeTypes[ID].minimumStake = minimumRequiredStake;
  }

   
  function setAttributeTypeJurisdictionFee(uint256 ID, uint256 fee) external {
     
    require(
      isAttributeType(ID),
      "unable to set fee, no attribute type with the provided ID"
    );

     
    _attributeTypes[ID].jurisdictionFee = fee;
  }

   
  function removeAttributeType(uint256 ID) external onlyOwner whenNotPaused {
     
    require(
      isAttributeType(ID),
      "unable to remove, no attribute type with the provided ID"
    );

     
    uint256 lastAttributeID = _attributeIDs[_attributeIDs.length.sub(1)];

     
    _attributeIDs[_attributeTypes[ID].index] = lastAttributeID;

     
    _attributeTypes[lastAttributeID].index = _attributeTypes[ID].index;
    
     
    _attributeIDs.length--;

     
    delete _attributeTypes[ID];

     
    emit AttributeTypeRemoved(ID);
  }

   
  function addValidator(
    address validator,
    string description
  ) external onlyOwner whenNotPaused {
     
    require(validator != address(0), "must supply a valid address");

     
    require(
      !isValidator(validator),
      "a validator with the provided address already exists"
    );

     
    require(
      _signingKeys[validator] == address(0),
      "a signing key matching the provided address already exists"
    );
    
     
    _validators[validator] = Validator({
      exists: true,
      index: _validatorAccounts.length,
      signingKey: validator,  
      description: description
    });

     
    _signingKeys[validator] = validator;

     
    _validatorAccounts.push(validator);
    
     
    emit ValidatorAdded(validator, description);
  }

   
  function removeValidator(address validator) external onlyOwner whenNotPaused {
     
    require(
      isValidator(validator),
      "unable to remove, no validator located at the provided address"
    );

     
    while (_validatorApprovals[validator].length > 0 && gasleft() > 25000) {
       
      uint256 lastIndex = _validatorApprovals[validator].length.sub(1);

       
      uint256 targetApproval = _validatorApprovals[validator][lastIndex];

       
      delete _attributeTypes[targetApproval].approvedValidators[validator];

       
      delete _validatorApprovalsIndex[validator][targetApproval];

       
      _validatorApprovals[validator].length--;
    }

     
    require(
      _validatorApprovals[validator].length == 0,
      "Cannot remove validator - first remove any existing validator approvals"
    );

     
    address lastAccount = _validatorAccounts[_validatorAccounts.length.sub(1)];

     
    _validatorAccounts[_validators[validator].index] = lastAccount;

     
    _validators[lastAccount].index = _validators[validator].index;
    
     
    _validatorAccounts.length--;

     
    delete _signingKeys[_validators[validator].signingKey];

     
    delete _validators[validator];

     
    emit ValidatorRemoved(validator);
  }

   
  function addValidatorApproval(
    address validator,
    uint256 attributeTypeID
  ) external onlyOwner whenNotPaused {
     
    require(
      isValidator(validator) && isAttributeType(attributeTypeID),
      "must specify both a valid attribute and an available validator"
    );

     
    require(
      !_attributeTypes[attributeTypeID].approvedValidators[validator],
      "validator is already approved on the provided attribute"
    );

     
    _attributeTypes[attributeTypeID].approvedValidators[validator] = true;

     
    uint256 index = _validatorApprovals[validator].length;
    _validatorApprovalsIndex[validator][attributeTypeID] = index;

     
    _validatorApprovals[validator].push(attributeTypeID);

     
    emit ValidatorApprovalAdded(validator, attributeTypeID);
  }

   
  function removeValidatorApproval(
    address validator,
    uint256 attributeTypeID
  ) external onlyOwner whenNotPaused {
     
    require(
      canValidate(validator, attributeTypeID),
      "unable to remove validator approval, attribute is already unapproved"
    );

     
    delete _attributeTypes[attributeTypeID].approvedValidators[validator];

     
    uint256 lastIndex = _validatorApprovals[validator].length.sub(1);

     
    uint256 lastAttributeID = _validatorApprovals[validator][lastIndex];

     
    uint256 index = _validatorApprovalsIndex[validator][attributeTypeID];

     
    _validatorApprovals[validator][index] = lastAttributeID;

     
    _validatorApprovals[validator].length--;

     
    _validatorApprovalsIndex[validator][lastAttributeID] = index;

     
    delete _validatorApprovalsIndex[validator][attributeTypeID];
    
     
    emit ValidatorApprovalRemoved(validator, attributeTypeID);
  }

   
  function setValidatorSigningKey(address newSigningKey) external {
    require(
      isValidator(msg.sender),
      "only validators may modify validator signing keys");
 
     
    require(
      _signingKeys[newSigningKey] == address(0),
      "a signing key matching the provided address already exists"
    );

     
    delete _signingKeys[_validators[msg.sender].signingKey];

     
    _validators[msg.sender].signingKey = newSigningKey;

     
    _signingKeys[newSigningKey] = msg.sender;

     
    emit ValidatorSigningKeyModified(msg.sender, newSigningKey);
  }

   
  function issueAttribute(
    address account,
    uint256 attributeTypeID,
    uint256 value
  ) external payable whenNotPaused {
    require(
      canValidate(msg.sender, attributeTypeID),
      "only approved validators may assign attributes of this type"
    );

    require(
      !_issuedAttributes[account][attributeTypeID].exists,
      "duplicate attributes are not supported, remove existing attribute first"
    );

     
    uint256 minimumStake = _attributeTypes[attributeTypeID].minimumStake;
    uint256 jurisdictionFee = _attributeTypes[attributeTypeID].jurisdictionFee;
    uint256 stake = msg.value.sub(jurisdictionFee);

    require(
      stake >= minimumStake,
      "attribute requires a greater value than is currently provided"
    );

     
    _issuedAttributes[account][attributeTypeID] = IssuedAttribute({
      exists: true,
      setPersonally: false,
      operator: address(0),
      validator: msg.sender,
      value: value,
      stake: stake
    });

     
    emit AttributeAdded(msg.sender, account, attributeTypeID, value);

     
    if (stake > 0) {
      emit StakeAllocated(msg.sender, attributeTypeID, stake);
    }

     
    if (jurisdictionFee > 0) {
       
       
      if (owner().send(jurisdictionFee)) {
        emit FeePaid(owner(), msg.sender, attributeTypeID, jurisdictionFee);
      } else {
        _recoverableFunds = _recoverableFunds.add(jurisdictionFee);
      }
    }
  }

   
  function revokeAttribute(
    address account,
    uint256 attributeTypeID
  ) external whenNotPaused {
     
    require(
      _issuedAttributes[account][attributeTypeID].exists,
      "only existing attributes may be removed"
    );

     
    address validator = _issuedAttributes[account][attributeTypeID].validator;
    
     
    require(
      msg.sender == validator || msg.sender == owner(),
      "only jurisdiction or issuing validators may revoke arbitrary attributes"
    );

     
    uint256 stake = _issuedAttributes[account][attributeTypeID].stake;

     
    address refundAddress;
    if (_issuedAttributes[account][attributeTypeID].setPersonally) {
      refundAddress = account;
    } else {
      address operator = _issuedAttributes[account][attributeTypeID].operator;
      if (operator == address(0)) {
        refundAddress = validator;
      } else {
        refundAddress = operator;
      }
    }

     
    delete _issuedAttributes[account][attributeTypeID];

     
    emit AttributeRemoved(validator, account, attributeTypeID);

     
    if (stake > 0 && address(this).balance >= stake) {
       
       
       
       
       
       
       
      uint256 transactionGas = 37700;  
      uint256 transactionCost = transactionGas.mul(tx.gasprice);

       
      if (stake > transactionCost) {
         
        if (refundAddress.send(stake.sub(transactionCost))) {
          emit StakeRefunded(
            refundAddress,
            attributeTypeID,
            stake.sub(transactionCost)
          );
        } else {
          _recoverableFunds = _recoverableFunds.add(stake.sub(transactionCost));
        }

         
        emit TransactionRebatePaid(
          tx.origin,
          refundAddress,
          attributeTypeID,
          transactionCost
        );

         
        tx.origin.transfer(transactionCost);

       
      } else {
         
        emit TransactionRebatePaid(
          tx.origin,
          refundAddress,
          attributeTypeID,
          stake
        );

         
        tx.origin.transfer(stake);
      }
    }
  }

   
  function addAttribute(
    uint256 attributeTypeID,
    uint256 value,
    uint256 validatorFee,
    bytes signature
  ) external payable {
     
     
     
     
     
     
     
     
     
     
     

    require(
      !_issuedAttributes[msg.sender][attributeTypeID].exists,
      "duplicate attributes are not supported, remove existing attribute first"
    );

     
    uint256 minimumStake = _attributeTypes[attributeTypeID].minimumStake;
    uint256 jurisdictionFee = _attributeTypes[attributeTypeID].jurisdictionFee;
    uint256 stake = msg.value.sub(validatorFee).sub(jurisdictionFee);

    require(
      stake >= minimumStake,
      "attribute requires a greater value than is currently provided"
    );

     
    bytes32 hash = keccak256(
      abi.encodePacked(
        address(this),
        msg.sender,
        address(0),
        msg.value,
        validatorFee,
        attributeTypeID,
        value
      )
    );

    require(
      !_invalidAttributeApprovalHashes[hash],
      "signed attribute approvals from validators may not be reused"
    );

     
    address signingKey = hash.toEthSignedMessageHash().recover(signature);

     
    address validator = _signingKeys[signingKey];

    require(
      canValidate(validator, attributeTypeID),
      "signature does not match an approved validator for given attribute type"
    );

     
    _issuedAttributes[msg.sender][attributeTypeID] = IssuedAttribute({
      exists: true,
      setPersonally: true,
      operator: address(0),
      validator: validator,
      value: value,
      stake: stake
       
    });

     
    _invalidAttributeApprovalHashes[hash] = true;

     
    emit AttributeAdded(validator, msg.sender, attributeTypeID, value);

     
    if (stake > 0) {
      emit StakeAllocated(msg.sender, attributeTypeID, stake);
    }

     
    if (jurisdictionFee > 0) {
       
       
      if (owner().send(jurisdictionFee)) {
        emit FeePaid(owner(), msg.sender, attributeTypeID, jurisdictionFee);
      } else {
        _recoverableFunds = _recoverableFunds.add(jurisdictionFee);
      }
    }

     
    if (validatorFee > 0) {
       
       
      if (validator.send(validatorFee)) {
        emit FeePaid(validator, msg.sender, attributeTypeID, validatorFee);
      } else {
        _recoverableFunds = _recoverableFunds.add(validatorFee);
      }
    }
  }

   
  function removeAttribute(uint256 attributeTypeID) external {
     
    require(
      !_attributeTypes[attributeTypeID].restricted,
      "only jurisdiction or issuing validator may remove a restricted attribute"
    );

    require(
      _issuedAttributes[msg.sender][attributeTypeID].exists,
      "only existing attributes may be removed"
    );

     
    address validator = _issuedAttributes[msg.sender][attributeTypeID].validator;

     
    uint256 stake = _issuedAttributes[msg.sender][attributeTypeID].stake;

     
    address refundAddress;
    if (_issuedAttributes[msg.sender][attributeTypeID].setPersonally) {
      refundAddress = msg.sender;
    } else {
      address operator = _issuedAttributes[msg.sender][attributeTypeID].operator;
      if (operator == address(0)) {
        refundAddress = validator;
      } else {
        refundAddress = operator;
      }
    }    

     
    delete _issuedAttributes[msg.sender][attributeTypeID];

     
    emit AttributeRemoved(validator, msg.sender, attributeTypeID);

     
    if (stake > 0 && address(this).balance >= stake) {
       
       
      if (refundAddress.send(stake)) {
        emit StakeRefunded(refundAddress, attributeTypeID, stake);
      } else {
        _recoverableFunds = _recoverableFunds.add(stake);
      }
    }
  }

   
  function addAttributeFor(
    address account,
    uint256 attributeTypeID,
    uint256 value,
    uint256 validatorFee,
    bytes signature
  ) external payable {
     
     
     
     
     
     
     
     
     
     
     

     
    require(
      !_attributeTypes[attributeTypeID].onlyPersonal,
      "only operatable attributes may be added on behalf of another address"
    );

    require(
      !_issuedAttributes[account][attributeTypeID].exists,
      "duplicate attributes are not supported, remove existing attribute first"
    );

     
    uint256 minimumStake = _attributeTypes[attributeTypeID].minimumStake;
    uint256 jurisdictionFee = _attributeTypes[attributeTypeID].jurisdictionFee;
    uint256 stake = msg.value.sub(validatorFee).sub(jurisdictionFee);

    require(
      stake >= minimumStake,
      "attribute requires a greater value than is currently provided"
    );

     
    bytes32 hash = keccak256(
      abi.encodePacked(
        address(this),
        account,
        msg.sender,
        msg.value,
        validatorFee,
        attributeTypeID,
        value
      )
    );

    require(
      !_invalidAttributeApprovalHashes[hash],
      "signed attribute approvals from validators may not be reused"
    );

     
    address signingKey = hash.toEthSignedMessageHash().recover(signature);

     
    address validator = _signingKeys[signingKey];

    require(
      canValidate(validator, attributeTypeID),
      "signature does not match an approved validator for provided attribute"
    );

     
    _issuedAttributes[account][attributeTypeID] = IssuedAttribute({
      exists: true,
      setPersonally: false,
      operator: msg.sender,
      validator: validator,
      value: value,
      stake: stake
       
    });

     
    _invalidAttributeApprovalHashes[hash] = true;

     
    emit AttributeAdded(validator, account, attributeTypeID, value);

     
     
    if (stake > 0) {
      emit StakeAllocated(msg.sender, attributeTypeID, stake);
    }

     
    if (jurisdictionFee > 0) {
       
       
      if (owner().send(jurisdictionFee)) {
        emit FeePaid(owner(), msg.sender, attributeTypeID, jurisdictionFee);
      } else {
        _recoverableFunds = _recoverableFunds.add(jurisdictionFee);
      }
    }

     
    if (validatorFee > 0) {
       
       
      if (validator.send(validatorFee)) {
        emit FeePaid(validator, msg.sender, attributeTypeID, validatorFee);
      } else {
        _recoverableFunds = _recoverableFunds.add(validatorFee);
      }
    }
  }

   
  function removeAttributeFor(address account, uint256 attributeTypeID) external {
     
    require(
      !_attributeTypes[attributeTypeID].restricted,
      "only jurisdiction or issuing validator may remove a restricted attribute"
    );

    require(
      _issuedAttributes[account][attributeTypeID].exists,
      "only existing attributes may be removed"
    );

    require(
      _issuedAttributes[account][attributeTypeID].operator == msg.sender,
      "only an assigning operator may remove attribute on behalf of an address"
    );

     
    address validator = _issuedAttributes[account][attributeTypeID].validator;

     
    uint256 stake = _issuedAttributes[account][attributeTypeID].stake;

     
    delete _issuedAttributes[account][attributeTypeID];

     
    emit AttributeRemoved(validator, account, attributeTypeID);

     
    if (stake > 0 && address(this).balance >= stake) {
       
       
      if (msg.sender.send(stake)) {
        emit StakeRefunded(msg.sender, attributeTypeID, stake);
      } else {
        _recoverableFunds = _recoverableFunds.add(stake);
      }
    }
  }

   
  function invalidateAttributeApproval(
    bytes32 hash,
    bytes signature
  ) external {
     
    address validator = _signingKeys[
      hash.toEthSignedMessageHash().recover(signature)  
    ];
    
     
    require(
      msg.sender == validator || msg.sender == owner(),
      "only jurisdiction or issuing validator may invalidate attribute approval"
    );

     
    _invalidAttributeApprovalHashes[hash] = true;
  }

   
  function hasAttribute(
    address account, 
    uint256 attributeTypeID
  ) external view returns (bool) {
    address validator = _issuedAttributes[account][attributeTypeID].validator;
    return (
      (
        _validators[validator].exists &&    
        _attributeTypes[attributeTypeID].approvedValidators[validator] &&
        _attributeTypes[attributeTypeID].exists  
      ) || (
        _attributeTypes[attributeTypeID].secondarySource != address(0) &&
        secondaryHasAttribute(
          _attributeTypes[attributeTypeID].secondarySource,
          account,
          _attributeTypes[attributeTypeID].secondaryAttributeTypeID
        )
      )
    );
  }

   
  function getAttributeValue(
    address account,
    uint256 attributeTypeID
  ) external view returns (uint256 value) {
     
    address validator = _issuedAttributes[account][attributeTypeID].validator;
    if (
      _validators[validator].exists &&    
      _attributeTypes[attributeTypeID].approvedValidators[validator] &&
      _attributeTypes[attributeTypeID].exists  
    ) {
      return _issuedAttributes[account][attributeTypeID].value;
    } else if (
      _attributeTypes[attributeTypeID].secondarySource != address(0)
    ) {
       
      if (_attributeTypes[attributeTypeID].secondaryAttributeTypeID == 2423228754106148037712574142965102) {
        require(
          IERC20(
            _attributeTypes[attributeTypeID].secondarySource
          ).balanceOf(account) >= 1,
          "no Yes Token has been issued to the provided account"
        );
        return 1;  
      }

       
      require(
        AttributeRegistryInterface(
          _attributeTypes[attributeTypeID].secondarySource
        ).hasAttribute(
          account, _attributeTypes[attributeTypeID].secondaryAttributeTypeID
        ),
        "attribute of the provided type is not assigned to the provided account"
      );

      return (
        AttributeRegistryInterface(
          _attributeTypes[attributeTypeID].secondarySource
        ).getAttributeValue(
          account, _attributeTypes[attributeTypeID].secondaryAttributeTypeID
        )
      );
    }

     
    revert("could not find an attribute value at the provided account and ID");
  }

   
  function canIssueAttributeType(
    address validator,
    uint256 attributeTypeID
  ) external view returns (bool) {
    return canValidate(validator, attributeTypeID);
  }

   
  function getAttributeTypeDescription(
    uint256 attributeTypeID
  ) external view returns (
    string description
  ) {
    return _attributeTypes[attributeTypeID].description;
  }

   
  function getAttributeTypeInformation(
    uint256 attributeTypeID
  ) external view returns (
    string description,
    bool isRestricted,
    bool isOnlyPersonal,
    address secondarySource,
    uint256 secondaryAttributeTypeID,
    uint256 minimumRequiredStake,
    uint256 jurisdictionFee
  ) {
    return (
      _attributeTypes[attributeTypeID].description,
      _attributeTypes[attributeTypeID].restricted,
      _attributeTypes[attributeTypeID].onlyPersonal,
      _attributeTypes[attributeTypeID].secondarySource,
      _attributeTypes[attributeTypeID].secondaryAttributeTypeID,
      _attributeTypes[attributeTypeID].minimumStake,
      _attributeTypes[attributeTypeID].jurisdictionFee
    );
  }

   
  function getValidatorDescription(
    address validator
  ) external view returns (
    string description
  ) {
    return _validators[validator].description;
  }

   
  function getValidatorSigningKey(
    address validator
  ) external view returns (
    address signingKey
  ) {
    return _validators[validator].signingKey;
  }

   
  function getAttributeValidator(
    address account,
    uint256 attributeTypeID
  ) external view returns (
    address validator,
    bool isStillValid
  ) {
    address issuer = _issuedAttributes[account][attributeTypeID].validator;
    return (issuer, canValidate(issuer, attributeTypeID));
  }

   
  function countAttributeTypes() external view returns (uint256) {
    return _attributeIDs.length;
  }

   
  function getAttributeTypeID(uint256 index) external view returns (uint256) {
    require(
      index < _attributeIDs.length,
      "provided index is outside of the range of defined attribute type IDs"
    );

    return _attributeIDs[index];
  }

   
  function getAttributeTypeIDs() external view returns (uint256[]) {
    return _attributeIDs;
  }

   
  function countValidators() external view returns (uint256) {
    return _validatorAccounts.length;
  }

   
  function getValidator(
    uint256 index
  ) external view returns (address) {
    return _validatorAccounts[index];
  }

   
  function getValidators() external view returns (address[]) {
    return _validatorAccounts;
  }

   
  function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    return (
      interfaceID == this.supportsInterface.selector ||  
      interfaceID == (
        this.hasAttribute.selector 
        ^ this.getAttributeValue.selector
        ^ this.countAttributeTypes.selector
        ^ this.getAttributeTypeID.selector
      )  
    );  
  }

   
  function getAttributeApprovalHash(
    address account,
    address operator,
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee
  ) external view returns (
    bytes32 hash
  ) {
    return calculateAttributeApprovalHash(
      account,
      operator,
      attributeTypeID,
      value,
      fundsRequired,
      validatorFee
    );
  }

   
  function canAddAttribute(
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee,
    bytes signature
  ) external view returns (bool) {
     
    bytes32 hash = calculateAttributeApprovalHash(
      msg.sender,
      address(0),
      attributeTypeID,
      value,
      fundsRequired,
      validatorFee
    );

     
    address signingKey = hash.toEthSignedMessageHash().recover(signature);
    
     
    address validator = _signingKeys[signingKey];
    uint256 minimumStake = _attributeTypes[attributeTypeID].minimumStake;
    uint256 jurisdictionFee = _attributeTypes[attributeTypeID].jurisdictionFee;

     
     
    return (
      fundsRequired >= minimumStake.add(jurisdictionFee).add(validatorFee) &&
      !_invalidAttributeApprovalHashes[hash] &&
      canValidate(validator, attributeTypeID) &&
      !_issuedAttributes[msg.sender][attributeTypeID].exists
    );
  }

   
  function canAddAttributeFor(
    address account,
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee,
    bytes signature
  ) external view returns (bool) {
     
    bytes32 hash = calculateAttributeApprovalHash(
      account,
      msg.sender,
      attributeTypeID,
      value,
      fundsRequired,
      validatorFee
    );

     
    address signingKey = hash.toEthSignedMessageHash().recover(signature);
    
     
    address validator = _signingKeys[signingKey];
    uint256 minimumStake = _attributeTypes[attributeTypeID].minimumStake;
    uint256 jurisdictionFee = _attributeTypes[attributeTypeID].jurisdictionFee;

     
     
    return (
      fundsRequired >= minimumStake.add(jurisdictionFee).add(validatorFee) &&
      !_invalidAttributeApprovalHashes[hash] &&
      canValidate(validator, attributeTypeID) &&
      !_issuedAttributes[account][attributeTypeID].exists
    );
  }

   
  function isAttributeType(uint256 attributeTypeID) public view returns (bool) {
    return _attributeTypes[attributeTypeID].exists;
  }

   
  function isValidator(address account) public view returns (bool) {
    return _validators[account].exists;
  }

   
  function recoverableFunds() public view returns (uint256) {
     
    return _recoverableFunds;
  }

   
  function recoverableTokens(address token) public view returns (uint256) {
     
    return IERC20(token).balanceOf(address(this));
  }

   
  function recoverFunds(address account, uint256 value) public onlyOwner {    
     
    _recoverableFunds = _recoverableFunds.sub(value);
    
     
    account.transfer(value);
  }

   
  function recoverTokens(
    address token,
    address account,
    uint256 value
  ) public onlyOwner {
     
    require(IERC20(token).transfer(account, value));
  }

   
  function canValidate(
    address validator,
    uint256 attributeTypeID
  ) internal view returns (bool) {
    return (
      _validators[validator].exists &&    
      _attributeTypes[attributeTypeID].approvedValidators[validator] &&
      _attributeTypes[attributeTypeID].exists  
    );
  }

   
  function calculateAttributeApprovalHash(
    address account,
    address operator,
    uint256 attributeTypeID,
    uint256 value,
    uint256 fundsRequired,
    uint256 validatorFee
  ) internal view returns (bytes32 hash) {
    return keccak256(
      abi.encodePacked(
        address(this),
        account,
        operator,
        fundsRequired,
        validatorFee,
        attributeTypeID,
        value
      )
    );
  }

   
  function secondaryHasAttribute(
    address source,
    address account,
    uint256 attributeTypeID
  ) internal view returns (bool result) {
     
    if (attributeTypeID == 2423228754106148037712574142965102) {
      return (IERC20(source).balanceOf(account) >= 1);
    }

    uint256 maxGas = gasleft() > 20000 ? 20000 : gasleft();
    bytes memory encodedParams = abi.encodeWithSelector(
      this.hasAttribute.selector,
      account,
      attributeTypeID
    );

    assembly {
      let encodedParams_data := add(0x20, encodedParams)
      let encodedParams_size := mload(encodedParams)
      
      let output := mload(0x40)  
      mstore(output, 0x0)        

      let success := staticcall(
        maxGas,                  
        source,                  
        encodedParams_data,      
        encodedParams_size,      
        output,                  
        0x20                     
      )

      switch success             
      case 1 {                   
        result := mload(output)  
      }
    }
  }
}