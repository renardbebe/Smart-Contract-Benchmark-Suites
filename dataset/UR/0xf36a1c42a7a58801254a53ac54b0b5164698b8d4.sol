 

pragma solidity ^0.4.18;

 

 
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

 

interface StoreInterface {

  function getAppNickname()
  external
  constant returns (bytes32);


  function getAppId()
  external
  constant returns (uint);


  function getAddressLastUpdate(
    address _address
  )
  external
  constant returns (uint);


  function isUpgradable(
    address _address,
    string _uid
  )
  public
  constant returns (bool);


  function isUid(
    string _uid
  )
  public
  view
  returns (bool);


  function setIdentity(
    address _address,
    string _uid
  )
  external;


  function unsetIdentity(
    address _address
  )
  external;

}


 


contract StoreManager
is Pausable, HasNoEther
{

  string public fromVersion = "1.0.0";

  struct Store {
    StoreInterface store;
    address addr;
    bool active;
  }

  mapping(uint => Store) private __stores;
  uint public totalStores;

  mapping(uint => bytes32) public appNicknames32;
  mapping(uint => string) public appNicknames;
  mapping(string => uint) private __appIds;

  address public claimer;
  address public newClaimer;
  mapping(address => bool) public customerService;
  address[] private __customerServiceAddress;

  uint public upgradable = 0;
  uint public notUpgradableInStore = 1;
  uint public addressNotUpgradable = 2;

  uint public minimumTimeBeforeUpdate = 1 hours;



   


  event StoreSet(
    string appNickname,
    address indexed addr
  );


  event ClaimerSet(
    address indexed claimer,
    bool isNew
  );


  event StoreActive(
    string appNickname,
    address indexed store,
    bool active
  );


  event ClaimerSwitch(
    address indexed oldClaimer,
    address indexed newClaimer
  );


  event CustomerServiceSet(
    address indexed addr
  );


  event IdentityNotUpgradable(
    string appNickname,
    address indexed addr,
    string uid
  );


  event MinimumTimeBeforeUpdateChanged(
    uint _newMinimumTime
  );

   


   
  function setAStore(
    string _appNickname,
    address _address
  )
  public
  onlyOwner
  {
    require(bytes(_appNickname).length > 0);
    bytes32 _appNickname32 = keccak256(_appNickname);
    require(_address != address(0));
    StoreInterface _store = StoreInterface(_address);
    require(_store.getAppNickname() == _appNickname32);
    uint _appId = _store.getAppId();
    require(appNicknames32[_appId] == 0x0);
    appNicknames32[_appId] = _appNickname32;
    appNicknames[_appId] = _appNickname;
    __appIds[_appNickname] = _appId;

    __stores[_appId] = Store(
      _store,
      _address,
      true
    );
    totalStores++;
    StoreSet(_appNickname, _address);
    StoreActive(_appNickname, _address, true);
  }


   
  function setClaimer(
    address _address
  )
  public
  onlyOwner
  {
    require(_address != address(0));
    claimer = _address;
    ClaimerSet(_address, false);
  }


   
  function setNewClaimer(
    address _address
  )
  public
  onlyOwner
  {
    require(_address != address(0) && claimer != address(0));
    newClaimer = _address;
    ClaimerSet(_address, true);
  }


   
  function switchClaimerAndRemoveOldOne()
  external
  onlyOwner
  {
    require(newClaimer != address(0));
    ClaimerSwitch(claimer, newClaimer);
    claimer = newClaimer;
    newClaimer = address(0);
  }


   
  function setCustomerService(
    address _address,
    bool _status
  )
  public
  onlyOwner
  {
    require(_address != address(0));
    customerService[_address] = _status;
    bool found;
    for (uint i = 0; i < __customerServiceAddress.length; i++) {
      if (__customerServiceAddress[i] == _address) {
        found = true;
        break;
      }
    }
    if (!found) {
      __customerServiceAddress.push(_address);
    }
    CustomerServiceSet(_address);
  }



   
  function activateStore(
    string _appNickname,
    bool _active
  )
  public
  onlyOwner
  {
    uint _appId = __appIds[_appNickname];
    require(__stores[_appId].active != _active);
    __stores[_appId] = Store(
      __stores[_appId].store,
      __stores[_appId].addr,
      _active
    );
    StoreActive(_appNickname, __stores[_appId].addr, _active);
  }



   


  modifier onlyClaimer() {
    require(msg.sender == claimer || (newClaimer != address(0) && msg.sender == newClaimer));
    _;
  }


  modifier onlyCustomerService() {
    require(msg.sender == owner || customerService[msg.sender] == true);
    _;
  }


  modifier whenStoreSet(
    uint _appId
  ) {
    require(appNicknames32[_appId] != 0x0);
    _;
  }



   


  function __getStore(
    uint _appId
  )
  internal
  constant returns (StoreInterface)
  {
    return __stores[_appId].store;
  }



   


  function isAddressUpgradable(
    StoreInterface _store,
    address _address
  )
  internal
  constant returns (bool)
  {
    uint lastUpdate = _store.getAddressLastUpdate(_address);
    return lastUpdate == 0 || now >= lastUpdate + minimumTimeBeforeUpdate;
  }


  function isUpgradable(
    StoreInterface _store,
    address _address,
    string _uid
  )
  internal
  constant returns (bool)
  {
    if (!_store.isUpgradable(_address, _uid) || !isAddressUpgradable(_store, _address)) {
      return false;
    }
    return true;
  }



   


   
  function getAppId(
    string _appNickname
  )
  external
  constant returns (uint) {
    return __appIds[_appNickname];
  }


   
  function isStoreSet(
    string _appNickname
  )
  public
  constant returns (bool){
    return __appIds[_appNickname] != 0;
  }


   
  function isStoreActive(
    uint _appId
  )
  public
  constant returns (bool){
    return __stores[_appId].active;
  }


   
  function getUpgradability(
    uint _appId,
    address _address,
    string _uid
  )
  external
  constant returns (uint)
  {
    StoreInterface _store = __getStore(_appId);
    if (!_store.isUpgradable(_address, _uid)) {
      return notUpgradableInStore;
    } else if (!isAddressUpgradable(_store, _address)) {
      return addressNotUpgradable;
    } else {
      return upgradable;
    }
  }


   
  function getStoreAddress(
    string _appNickname
  )
  external
  constant returns (address) {
    return __stores[__appIds[_appNickname]].addr;
  }


   
  function getStoreAddressById(
    uint _appId
  )
  external
  constant returns (address) {
    return __stores[_appId].addr;
  }


   
  function getCustomerServiceAddress()
  external
  constant returns (address[]) {
    return __customerServiceAddress;
  }



   


   
  function setIdentity(
    uint _appId,
    address _address,
    string _uid
  )
  external
  onlyClaimer
  whenStoreSet(_appId)
  whenNotPaused
  {
    require(_address != address(0));

    StoreInterface _store = __getStore(_appId);
    require(_store.isUid(_uid));

    if (isUpgradable(_store, _address, _uid)) {
      _store.setIdentity(_address, _uid);
    } else {
      IdentityNotUpgradable(appNicknames[_appId], _address, _uid);
    }
  }


   
  function unsetIdentity(
    uint _appId,
    address _address
  )
  external
  onlyCustomerService
  whenStoreSet(_appId)
  whenNotPaused
  {
    StoreInterface _store = __getStore(_appId);
    _store.unsetIdentity(_address);
  }


   
  function unsetMyIdentity(
    uint _appId
  )
  external
  whenStoreSet(_appId)
  whenNotPaused
  {
    StoreInterface _store = __getStore(_appId);
    _store.unsetIdentity(msg.sender);
  }


   
  function changeMinimumTimeBeforeUpdate(
    uint _newMinimumTime
  )
  external
  onlyOwner
  {
    minimumTimeBeforeUpdate = _newMinimumTime;
    MinimumTimeBeforeUpdateChanged(_newMinimumTime);
  }

}