 

 


 

pragma solidity >=0.5.0 <0.6.0;


 
contract IUserRegistry {

  event UserRegistered(uint256 indexed userId, address address_, uint256 validUntilTime);
  event AddressAttached(uint256 indexed userId, address address_);
  event AddressDetached(uint256 indexed userId, address address_);
  event UserSuspended(uint256 indexed userId);
  event UserRestored(uint256 indexed userId);
  event UserValidity(uint256 indexed userId, uint256 validUntilTime);
  event UserExtendedKey(uint256 indexed userId, uint256 key, uint256 value);
  event UserExtendedKeys(uint256 indexed userId, uint256[] values);

  event ExtendedKeysDefinition(uint256[] keys);

  function registerManyUsersExternal(address[] calldata _addresses, uint256 _validUntilTime)
    external returns (bool);
  function registerManyUsersFullExternal(
    address[] calldata _addresses,
    uint256 _validUntilTime,
    uint256[] calldata _values) external returns (bool);
  function attachManyAddressesExternal(uint256[] calldata _userIds, address[] calldata _addresses)
    external returns (bool);
  function detachManyAddressesExternal(address[] calldata _addresses)
    external returns (bool);
  function suspendManyUsersExternal(uint256[] calldata _userIds) external returns (bool);
  function restoreManyUsersExternal(uint256[] calldata _userIds) external returns (bool);
  function updateManyUsersExternal(
    uint256[] calldata _userIds,
    uint256 _validUntilTime,
    bool _suspended) external returns (bool);
  function updateManyUsersExtendedExternal(
    uint256[] calldata _userIds,
    uint256 _key, uint256 _value) external returns (bool);
  function updateManyUsersAllExtendedExternal(
    uint256[] calldata _userIds,
    uint256[] calldata _values) external returns (bool);
  function updateManyUsersFullExternal(
    uint256[] calldata _userIds,
    uint256 _validUntilTime,
    bool _suspended,
    uint256[] calldata _values) external returns (bool);

  function name() public view returns (string memory);
  function currency() public view returns (bytes32);

  function userCount() public view returns (uint256);
  function userId(address _address) public view returns (uint256);
  function validUserId(address _address) public view returns (uint256);
  function validUser(address _address, uint256[] memory _keys)
    public view returns (uint256, uint256[] memory);
  function validity(uint256 _userId) public view returns (uint256, bool);

  function extendedKeys() public view returns (uint256[] memory);
  function extended(uint256 _userId, uint256 _key)
    public view returns (uint256);
  function manyExtended(uint256 _userId, uint256[] memory _key)
    public view returns (uint256[] memory);

  function isAddressValid(address _address) public view returns (bool);
  function isValid(uint256 _userId) public view returns (bool);

  function defineExtendedKeys(uint256[] memory _extendedKeys) public returns (bool);

  function registerUser(address _address, uint256 _validUntilTime)
    public returns (bool);
  function registerUserFull(
    address _address,
    uint256 _validUntilTime,
    uint256[] memory _values) public returns (bool);

  function attachAddress(uint256 _userId, address _address) public returns (bool);
  function detachAddress(address _address) public returns (bool);
  function detachSelf() public returns (bool);
  function detachSelfAddress(address _address) public returns (bool);
  function suspendUser(uint256 _userId) public returns (bool);
  function restoreUser(uint256 _userId) public returns (bool);
  function updateUser(uint256 _userId, uint256 _validUntilTime, bool _suspended)
    public returns (bool);
  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    public returns (bool);
  function updateUserAllExtended(uint256 _userId, uint256[] memory _values)
    public returns (bool);
  function updateUserFull(
    uint256 _userId,
    uint256 _validUntilTime,
    bool _suspended,
    uint256[] memory _values) public returns (bool);
}

 

pragma solidity >=0.5.0 <0.6.0;


 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity >=0.5.0 <0.6.0;



 
contract Operable is Ownable {

  mapping (address => bool) private operators_;

   
  modifier onlyOperator {
    require(operators_[msg.sender], "OP01");
    _;
  }

   
  constructor() public {
    defineOperator("Owner", msg.sender);
  }

   
  function isOperator(address _address) public view returns (bool) {
    return operators_[_address];
  }

   
  function removeOperator(address _address) public onlyOwner {
    require(operators_[_address], "OP02");
    operators_[_address] = false;
    emit OperatorRemoved(_address);
  }

   
  function defineOperator(string memory _role, address _address)
    public onlyOwner
  {
    require(!operators_[_address], "OP03");
    operators_[_address] = true;
    emit OperatorDefined(_role, _address);
  }

  event OperatorRemoved(address address_);
  event OperatorDefined(
    string role,
    address address_
  );
}

 

pragma solidity >=0.5.0 <0.6.0;




 
contract UserRegistry is IUserRegistry, Operable {

  struct User {
    uint256 validUntilTime;
    bool suspended;
    mapping(uint256 => uint256) extended;
  }

  uint256[] internal extendedKeys_ = [ 0, 1, 2 ];
  mapping(uint256 => User) internal users;
  mapping(address => uint256) internal walletOwners;
  uint256 internal userCount_;

  string internal name_;
  bytes32 internal currency_;

   
  constructor(
    string memory _name,
    bytes32 _currency,
    address[] memory _addresses,
    uint256 _validUntilTime) public
  {
    name_ = _name;
    currency_ = _currency;
    for (uint256 i = 0; i < _addresses.length; i++) {
      registerUserPrivate(_addresses[i], _validUntilTime);
    }
  }

   
  function registerManyUsersExternal(address[] calldata _addresses, uint256 _validUntilTime)
    external onlyOperator returns (bool)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      registerUserPrivate(_addresses[i], _validUntilTime);
    }
    return true;
  }

   
  function registerManyUsersFullExternal(
    address[] calldata _addresses,
    uint256 _validUntilTime,
    uint256[] calldata _values) external onlyOperator returns (bool)
  {
    require(_values.length <= extendedKeys_.length, "UR08");
    for (uint256 i = 0; i < _addresses.length; i++) {
      registerUserPrivate(_addresses[i], _validUntilTime);
      updateUserExtendedPrivate(userCount_, _values);
    }
    return true;
  }

   
  function attachManyAddressesExternal(
    uint256[] calldata _userIds,
    address[] calldata _addresses)
    external onlyOperator returns (bool)
  {
    require(_addresses.length == _userIds.length, "UR03");
    for (uint256 i = 0; i < _addresses.length; i++) {
      attachAddress(_userIds[i], _addresses[i]);
    }
    return true;
  }

   
  function detachManyAddressesExternal(address[] calldata _addresses)
    external onlyOperator returns (bool)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      detachAddressPrivate(_addresses[i]);
    }
    return true;
  }

   
  function suspendManyUsersExternal(uint256[] calldata _userIds)
    external onlyOperator returns (bool)
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      suspendUser(_userIds[i]);
    }
    return true;
  }

   
  function restoreManyUsersExternal(uint256[] calldata _userIds)
    external onlyOperator returns (bool)
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      restoreUser(_userIds[i]);
    }
    return true;
  }

   
  function updateManyUsersExternal(
    uint256[] calldata _userIds,
    uint256 _validUntilTime,
    bool _suspended) external onlyOperator returns (bool)
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      updateUser(_userIds[i], _validUntilTime, _suspended);
    }
    return true;
  }

   
  function updateManyUsersExtendedExternal(
    uint256[] calldata _userIds,
    uint256 _key, uint256 _value) external onlyOperator returns (bool)
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      updateUserExtended(_userIds[i], _key, _value);
    }
    return true;
  }

   
  function updateManyUsersAllExtendedExternal(
    uint256[] calldata _userIds,
    uint256[] calldata _values) external onlyOperator returns (bool)
  {
    require(_values.length <= extendedKeys_.length, "UR08");
    for (uint256 i = 0; i < _userIds.length; i++) {
      updateUserExtendedPrivate(_userIds[i], _values);
    }
    return true;
  }

   
  function updateManyUsersFullExternal(
    uint256[] calldata _userIds,
    uint256 _validUntilTime,
    bool _suspended,
    uint256[] calldata _values) external onlyOperator returns (bool)
  {
    require(_values.length <= extendedKeys_.length, "UR08");
    for (uint256 i = 0; i < _userIds.length; i++) {
      updateUser(_userIds[i], _validUntilTime, _suspended);
      updateUserExtendedPrivate(_userIds[i], _values);
    }
    return true;
  }

   
  function name() public view returns (string memory) {
    return name_;
  }

   
  function currency() public view returns (bytes32) {
    return currency_;
  }

   
  function userCount() public view returns (uint256) {
    return userCount_;
  }

   
  function userId(address _address) public view returns (uint256) {
    return walletOwners[_address];
  }

   
  function validUserId(address _address) public view returns (uint256) {
    uint256 addressUserId = walletOwners[_address];
    if (isValidPrivate(users[addressUserId])) {
      return addressUserId;
    }
    return 0;
  }

   
  function validUser(address _address, uint256[] memory _keys) public view returns (uint256, uint256[] memory) {
    uint256 addressUserId = walletOwners[_address];
    if (isValidPrivate(users[addressUserId])) {
      uint256[] memory values = new uint256[](_keys.length);
      for (uint256 i=0; i < _keys.length; i++) {
        values[i] = users[addressUserId].extended[_keys[i]];
      }
      return (addressUserId, values);
    }
    return (0, new uint256[](0));
  }

   
  function validity(uint256 _userId) public view returns (uint256, bool) {
    User memory user = users[_userId];
    return (user.validUntilTime, user.suspended);
  }

   
  function extendedKeys() public view returns (uint256[] memory) {
    return extendedKeys_;
  }

   
  function extended(uint256 _userId, uint256 _key)
    public view returns (uint256)
  {
    return users[_userId].extended[_key];
  }

   
  function manyExtended(uint256 _userId, uint256[] memory _keys)
    public view returns (uint256[] memory values)
  {
    values = new uint256[](_keys.length);
    for (uint256 i=0; i < _keys.length; i++) {
      values[i] = users[_userId].extended[_keys[i]];
    }
  }

   
  function isAddressValid(address _address) public view returns (bool) {
    return isValidPrivate(users[walletOwners[_address]]);
  }

   
  function isValid(uint256 _userId) public view returns (bool) {
    return isValidPrivate(users[_userId]);
  }

   
  function defineExtendedKeys(uint256[] memory _extendedKeys)
    public onlyOperator returns (bool)
  {
    extendedKeys_ = _extendedKeys;
    emit ExtendedKeysDefinition(_extendedKeys);
    return true;
  }

   
  function registerUser(address _address, uint256 _validUntilTime)
    public onlyOperator returns (bool)
  {
    registerUserPrivate(_address, _validUntilTime);
    return true;
  }

   
  function registerUserFull(
    address _address,
    uint256 _validUntilTime,
    uint256[] memory _values) public onlyOperator returns (bool)
  {
    require(_values.length <= extendedKeys_.length, "UR08");
    registerUserPrivate(_address, _validUntilTime);
    updateUserExtendedPrivate(userCount_, _values);
    return true;
  }

   
  function attachAddress(uint256 _userId, address _address)
    public onlyOperator returns (bool)
  {
    require(_userId > 0 && _userId <= userCount_, "UR01");
    require(walletOwners[_address] == 0, "UR02");
    walletOwners[_address] = _userId;

    emit AddressAttached(_userId, _address);
    return true;
  }

   
  function detachAddress(address _address)
    public onlyOperator returns (bool)
  {
    detachAddressPrivate(_address);
    return true;
  }

   
  function detachSelf() public returns (bool) {
    detachAddressPrivate(msg.sender);
    return true;
  }

   
  function detachSelfAddress(address _address)
    public returns (bool)
  {
    require(
      walletOwners[_address] == walletOwners[msg.sender],
      "UR05");
    detachAddressPrivate(_address);
    return true;
  }

   
  function suspendUser(uint256 _userId)
    public onlyOperator returns (bool)
  {
    require(_userId > 0 && _userId <= userCount_, "UR01");
    require(!users[_userId].suspended, "UR06");
    users[_userId].suspended = true;
    emit UserSuspended(_userId);
    return true;
  }

   
  function restoreUser(uint256 _userId)
    public onlyOperator returns (bool)
  {
    require(_userId > 0 && _userId <= userCount_, "UR01");
    require(users[_userId].suspended, "UR07");
    users[_userId].suspended = false;
    emit UserRestored(_userId);
    return true;
  }

   
  function updateUser(
    uint256 _userId,
    uint256 _validUntilTime,
    bool _suspended) public onlyOperator returns (bool)
  {
    require(_userId > 0 && _userId <= userCount_, "UR01");
    if (users[_userId].validUntilTime != _validUntilTime) {
      users[_userId].validUntilTime = _validUntilTime;
      emit UserValidity(_userId, _validUntilTime);
    }

    if (users[_userId].suspended != _suspended) {
      users[_userId].suspended = _suspended;
      if (_suspended) {
        emit UserSuspended(_userId);
      } else {
        emit UserRestored(_userId);
      }
    }
    return true;
  }

   
  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    public onlyOperator returns (bool)
  {
    require(_userId > 0 && _userId <= userCount_, "UR01");
    users[_userId].extended[_key] = _value;
    emit UserExtendedKey(_userId, _key, _value);
    return true;
  }

   
  function updateUserAllExtended(
    uint256 _userId,
    uint256[] memory _values) public onlyOperator returns (bool)
  {
    require(_values.length <= extendedKeys_.length, "UR08");
    updateUserExtendedPrivate(_userId, _values);
    return true;
  }

   
  function updateUserFull(
    uint256 _userId,
    uint256 _validUntilTime,
    bool _suspended,
    uint256[] memory _values) public onlyOperator returns (bool)
  {
    require(_values.length <= extendedKeys_.length, "UR08");
    updateUser(_userId, _validUntilTime, _suspended);
    updateUserExtendedPrivate(_userId, _values);
    return true;
  }

   
  function registerUserPrivate(address _address, uint256 _validUntilTime)
    private
  {
    require(walletOwners[_address] == 0, "UR03");
    users[++userCount_] = User(_validUntilTime, false);
    walletOwners[_address] = userCount_;

    emit UserRegistered(userCount_, _address, _validUntilTime);
  }

   
  function updateUserExtendedPrivate(uint256 _userId, uint256[] memory _values)
    private
  {
    require(_userId > 0 && _userId <= userCount_, "UR01");
    for (uint256 i = 0; i < _values.length; i++) {
      users[_userId].extended[extendedKeys_[i]] = _values[i];
    }
    emit UserExtendedKeys(_userId, _values);
  }

   
  function detachAddressPrivate(address _address) private {
    uint256 addressUserId = walletOwners[_address];
    require(addressUserId != 0, "UR04");
    emit AddressDetached(addressUserId, _address);
    delete walletOwners[_address];
  }

   
  function isValidPrivate(User storage user) private view returns (bool) {
     
    return !user.suspended && user.validUntilTime > now;
  }
}