 

 

pragma solidity ^0.4.24;

 

 
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

 

 
contract Authority is Ownable {

  address authority;

   
  modifier onlyAuthority {
    require(msg.sender == authority, "AU01");
    _;
  }

   
  function authorityAddress() public view returns (address) {
    return authority;
  }

   
  function defineAuthority(string _name, address _address) public onlyOwner {
    emit AuthorityDefined(_name, _address);
    authority = _address;
  }

  event AuthorityDefined(
    string name,
    address _address
  );
}

 

 
interface IRule {
  function isAddressValid(address _address) external view returns (bool);
  function isTransferValid(address _from, address _to, uint256 _amount)
    external view returns (bool);
}

 

 
contract IUserRegistry {

  function registerManyUsers(address[] _addresses, uint256 _validUntilTime)
    public;

  function attachManyAddresses(uint256[] _userIds, address[] _addresses)
    public;

  function detachManyAddresses(address[] _addresses)
    public;

  function userCount() public view returns (uint256);
  function userId(address _address) public view returns (uint256);
  function addressConfirmed(address _address) public view returns (bool);
  function validUntilTime(uint256 _userId) public view returns (uint256);
  function suspended(uint256 _userId) public view returns (bool);
  function extended(uint256 _userId, uint256 _key)
    public view returns (uint256);

  function isAddressValid(address _address) public view returns (bool);
  function isValid(uint256 _userId) public view returns (bool);

  function registerUser(address _address, uint256 _validUntilTime) public;
  function attachAddress(uint256 _userId, address _address) public;
  function confirmSelf() public;
  function detachAddress(address _address) public;
  function detachSelf() public;
  function detachSelfAddress(address _address) public;
  function suspendUser(uint256 _userId) public;
  function unsuspendUser(uint256 _userId) public;
  function suspendManyUsers(uint256[] _userIds) public;
  function unsuspendManyUsers(uint256[] _userIds) public;
  function updateUser(uint256 _userId, uint256 _validUntil, bool _suspended)
    public;

  function updateManyUsers(
    uint256[] _userIds,
    uint256 _validUntil,
    bool _suspended) public;

  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    public;

  function updateManyUsersExtended(
    uint256[] _userIds,
    uint256 _key,
    uint256 _value) public;
}

 

 
contract UserRegistry is IUserRegistry, Authority {

  struct User {
    uint256 validUntilTime;
    bool suspended;
    mapping(uint256 => uint256) extended;
  }
  struct WalletOwner {
    uint256 userId;
    bool confirmed;
  }

  mapping(uint256 => User) internal users;
  mapping(address => WalletOwner) internal walletOwners;
  uint256 public userCount;

   
  constructor(address[] _addresses, uint256 _validUntilTime) public {
    for (uint256 i = 0; i < _addresses.length; i++) {
      registerUserInternal(_addresses[i], _validUntilTime);
      walletOwners[_addresses[i]].confirmed = true;
    }
  }

   
  function registerManyUsers(address[] _addresses, uint256 _validUntilTime)
    public onlyAuthority
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      registerUserInternal(_addresses[i], _validUntilTime);
    }
  }

   
  function attachManyAddresses(uint256[] _userIds, address[] _addresses)
    public onlyAuthority
  {
    require(_addresses.length == _userIds.length, "UR01");
    for (uint256 i = 0; i < _addresses.length; i++) {
      attachAddress(_userIds[i], _addresses[i]);
    }
  }

   
  function detachManyAddresses(address[] _addresses) public onlyAuthority {
    for (uint256 i = 0; i < _addresses.length; i++) {
      detachAddress(_addresses[i]);
    }
  }

   
  function userCount() public view returns (uint256) {
    return userCount;
  }

   
  function userId(address _address) public view returns (uint256) {
    return walletOwners[_address].userId;
  }

   
  function validUserId(address _address) public view returns (uint256) {
    if (isAddressValid(_address)) {
      return walletOwners[_address].userId;
    }
    return 0;
  }

   
  function addressConfirmed(address _address) public view returns (bool) {
    return walletOwners[_address].confirmed;
  }

   
  function validUntilTime(uint256 _userId) public view returns (uint256) {
    return users[_userId].validUntilTime;
  }

   
  function suspended(uint256 _userId) public view returns (bool) {
    return users[_userId].suspended;
  }

   
  function extended(uint256 _userId, uint256 _key)
    public view returns (uint256)
  {
    return users[_userId].extended[_key];
  }

   
  function isAddressValid(address _address) public view returns (bool) {
    return walletOwners[_address].confirmed &&
      isValid(walletOwners[_address].userId);
  }

   
  function isValid(uint256 _userId) public view returns (bool) {
    return isValidInternal(users[_userId]);
  }

   
  function registerUser(address _address, uint256 _validUntilTime)
    public onlyAuthority
  {
    registerUserInternal(_address, _validUntilTime);
  }

   
  function registerUserInternal(address _address, uint256 _validUntilTime)
    public
  {
    require(walletOwners[_address].userId == 0, "UR03");
    users[++userCount] = User(_validUntilTime, false);
    walletOwners[_address] = WalletOwner(userCount, false);
  }

   
  function attachAddress(uint256 _userId, address _address)
    public onlyAuthority
  {
    require(_userId > 0 && _userId <= userCount, "UR02");
    require(walletOwners[_address].userId == 0, "UR03");
    walletOwners[_address] = WalletOwner(_userId, false);
  }

   
  function confirmSelf() public {
    require(walletOwners[msg.sender].userId != 0, "UR03");
    require(!walletOwners[msg.sender].confirmed, "UR04");
    walletOwners[msg.sender].confirmed = true;
  }

   
  function detachAddress(address _address) public onlyAuthority {
    require(walletOwners[_address].userId != 0, "UR03");
    delete walletOwners[_address];
  }

   
  function detachSelf() public {
    detachSelfAddress(msg.sender);
  }

   
  function detachSelfAddress(address _address) public {
    uint256 senderUserId = walletOwners[msg.sender].userId;
    require(senderUserId != 0, "UR03");
    require(walletOwners[_address].userId == senderUserId, "UR06");
    delete walletOwners[_address];
  }

   
  function suspendUser(uint256 _userId) public onlyAuthority {
    require(_userId > 0 && _userId <= userCount, "UR02");
    require(!users[_userId].suspended, "UR06");
    users[_userId].suspended = true;
  }

   
  function unsuspendUser(uint256 _userId) public onlyAuthority {
    require(_userId > 0 && _userId <= userCount, "UR02");
    require(users[_userId].suspended, "UR06");
    users[_userId].suspended = false;
  }

   
  function suspendManyUsers(uint256[] _userIds) public onlyAuthority {
    for (uint256 i = 0; i < _userIds.length; i++) {
      suspendUser(_userIds[i]);
    }
  }

   
  function unsuspendManyUsers(uint256[] _userIds) public onlyAuthority {
    for (uint256 i = 0; i < _userIds.length; i++) {
      unsuspendUser(_userIds[i]);
    }
  }

   
  function updateUser(
    uint256 _userId,
    uint256 _validUntilTime,
    bool _suspended) public onlyAuthority
  {
    require(_userId > 0 && _userId <= userCount, "UR02");
    users[_userId].validUntilTime = _validUntilTime;
    users[_userId].suspended = _suspended;
  }

   
  function updateManyUsers(
    uint256[] _userIds,
    uint256 _validUntilTime,
    bool _suspended) public onlyAuthority
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      updateUser(_userIds[i], _validUntilTime, _suspended);
    }
  }

   
  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    public onlyAuthority
  {
    require(_userId > 0 && _userId <= userCount, "UR02");
    users[_userId].extended[_key] = _value;
  }

   
  function updateManyUsersExtended(
    uint256[] _userIds,
    uint256 _key,
    uint256 _value) public onlyAuthority
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      updateUserExtended(_userIds[i], _key, _value);
    }
  }

   
  function isValidInternal(User user) internal view returns (bool) {
     
    return !user.suspended && user.validUntilTime > now;
  }
}