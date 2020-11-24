 

pragma solidity ^0.4.18;

 

interface UidCheckerInterface {

  function isUid(
    string _uid
  )
  public
  pure returns (bool);

}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 

 



contract Datastore
is HasNoEther
{

  string public fromVersion = "1.0.0";

  uint public appId;
  string public appNickname;

  uint public identities;

  address public manager;
  address public newManager;

  UidCheckerInterface public checker;

  struct Uid {
    string lastUid;
    uint lastUpdate;
  }

  struct Address {
    address lastAddress;
    uint lastUpdate;
  }

  mapping(string => Address) internal __addressByUid;
  mapping(address => Uid) internal __uidByAddress;

  bool public appSet;



   


  event AppSet(
    string appNickname,
    uint appId,
    address checker
  );


  event ManagerSet(
    address indexed manager,
    bool isNew
  );

  event ManagerSwitch(
    address indexed oldManager,
    address indexed newManager
  );


  event IdentitySet(
    address indexed addr,
    string uid
  );


  event IdentityUnset(
    address indexed addr,
    string uid
  );



   


  modifier onlyManager() {
    require(msg.sender == manager || (newManager != address(0) && msg.sender == newManager));
    _;
  }


  modifier whenAppSet() {
    require(appSet);
    _;
  }



   


   
  function setNewChecker(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0));
    checker = UidCheckerInterface(_address);
  }


   
  function setManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0));
    manager = _address;
    ManagerSet(_address, false);
  }


   
  function setNewManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0) && manager != address(0));
    newManager = _address;
    ManagerSet(_address, true);
  }


   
  function switchManagerAndRemoveOldOne()
  external
  onlyOwner
  {
    require(newManager != address(0));
    ManagerSwitch(manager, newManager);
    manager = newManager;
    newManager = address(0);
  }


   
  function setApp(
    string _appNickname,
    uint _appId,
    address _checker
  )
  external
  onlyOwner
  {
    require(!appSet);
    require(_appId > 0);
    require(_checker != address(0));
    require(bytes(_appNickname).length > 0);
    appId = _appId;
    appNickname = _appNickname;
    checker = UidCheckerInterface(_checker);
    appSet = true;
    AppSet(_appNickname, _appId, _checker);
  }



   


   
  function isUpgradable(
    address _address,
    string _uid
  )
  public
  constant returns (bool)
  {
    if (__addressByUid[_uid].lastAddress != address(0)) {
      return keccak256(getUid(_address)) == keccak256(_uid);
    }
    return true;
  }



   


   
  function setIdentity(
    address _address,
    string _uid
  )
  external
  onlyManager
  whenAppSet
  {
    require(_address != address(0));
    require(isUid(_uid));
    require(isUpgradable(_address, _uid));

    if (bytes(__uidByAddress[_address].lastUid).length > 0) {
       
       
      __addressByUid[__uidByAddress[_address].lastUid] = Address(address(0), __addressByUid[__uidByAddress[_address].lastUid].lastUpdate);
      identities--;
    }

    __uidByAddress[_address] = Uid(_uid, now);
    __addressByUid[_uid] = Address(_address, now);
    identities++;
    IdentitySet(_address, _uid);
  }


   
  function unsetIdentity(
    address _address
  )
  external
  onlyManager
  whenAppSet
  {
    require(_address != address(0));
    require(bytes(__uidByAddress[_address].lastUid).length > 0);

    string memory uid = __uidByAddress[_address].lastUid;
    __uidByAddress[_address] = Uid('', __uidByAddress[_address].lastUpdate);
    __addressByUid[uid] = Address(address(0), __addressByUid[uid].lastUpdate);
    identities--;
    IdentityUnset(_address, uid);
  }



   


   
  function getAppNickname()
  external
  whenAppSet
  constant returns (bytes32) {
    return keccak256(appNickname);
  }


   
  function getAppId()
  external
  whenAppSet
  constant returns (uint) {
    return appId;
  }


   
  function getUid(
    address _address
  )
  public
  constant returns (string)
  {
    return __uidByAddress[_address].lastUid;
  }


   
  function getAddress(
    string _uid
  )
  external
  constant returns (address)
  {
    return __addressByUid[_uid].lastAddress;
  }


   
  function getAddressLastUpdate(
    address _address
  )
  external
  constant returns (uint)
  {
    return __uidByAddress[_address].lastUpdate;
  }


   
  function getUidLastUpdate(
    string _uid
  )
  external
  constant returns (uint)
  {
    return __addressByUid[_uid].lastUpdate;
  }



   


  function isUid(
    string _uid
  )
  public
  view
  returns (bool)
  {
    return checker.isUid(_uid);
  }

}