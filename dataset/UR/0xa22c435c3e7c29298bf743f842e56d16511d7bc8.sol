 

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

 

interface ManagerInterface {

  function paused()
  public
  constant returns (bool);


  function claimer()
  public
  constant returns (address);

  function totalStores()
  public
  constant returns (uint);


  function getStoreAddress(
    string _appNickname
  )
  external
  constant returns (address);


  function getStoreAddressById(
    uint _appId
  )
  external
  constant returns (address);


  function isStoreActive(
    uint _appId
  )
  public
  constant returns (bool);

}

interface ClaimerInterface {

  function manager()
  public
  constant returns (address);
}


interface StoreInterface {

  function appSet()
  public
  constant returns (bool);


  function manager()
  public
  constant returns (address);

}


 


contract TweedentityRegistry
is HasNoEther
{

  string public fromVersion = "1.0.0";

  address public manager;
  address public claimer;

  event ContractRegistered(
    bytes32 indexed key,
    string spec,
    address addr
  );


  function setManager(
    address _manager
  )
  public
  onlyOwner
  {
    require(_manager != address(0));
    manager = _manager;
    ContractRegistered(keccak256("manager"), "", _manager);
  }


  function setClaimer(
    address _claimer
  )
  public
  onlyOwner
  {
    require(_claimer != address(0));
    claimer = _claimer;
    ContractRegistered(keccak256("claimer"), "", _claimer);
  }


  function setManagerAndClaimer(
    address _manager,
    address _claimer
  )
  external
  onlyOwner
  {
    setManager(_manager);
    setClaimer(_claimer);
  }


   
  function getStore(
    string _appNickname
  )
  public
  constant returns (address)
  {
    ManagerInterface theManager = ManagerInterface(manager);
    return theManager.getStoreAddress(_appNickname);
  }


   

  uint public allSet = 0;
  uint public managerUnset = 10;
  uint public claimerUnset = 20;
  uint public wrongClaimerOrUnsetInManager = 30;
  uint public wrongManagerOrUnsetInClaimer = 40;
  uint public noStoresSet = 50;
  uint public noStoreIsActive = 60;
  uint public managerIsPaused = 70;
  uint public managerNotSetInApp = 1000;

   
  function isReady()
  external
  constant returns (uint)
  {
    if (manager == address(0)) {
      return managerUnset;
    }
    if (claimer == address(0)) {
      return claimerUnset;
    }
    ManagerInterface theManager = ManagerInterface(manager);
    ClaimerInterface theClaimer = ClaimerInterface(claimer);
    if (theManager.claimer() != claimer) {
      return wrongClaimerOrUnsetInManager;
    }
    if (theClaimer.manager() != manager) {
      return wrongManagerOrUnsetInClaimer;
    }
    uint totalStores = theManager.totalStores();
    if (totalStores == 0) {
      return noStoresSet;
    }
    bool atLeastOneIsActive;
    for (uint i = 1; i <= totalStores; i++) {
      StoreInterface theStore = StoreInterface(theManager.getStoreAddressById(i));
      if (theManager.isStoreActive(i)) {
        atLeastOneIsActive = true;
      }
      if (theManager.isStoreActive(i)) {
        if (theStore.manager() != manager) {
          return managerNotSetInApp + i;
        }
      }
    }
    if (atLeastOneIsActive == false) {
      return noStoreIsActive;
    }
    if (theManager.paused() == true) {
      return managerIsPaused;
    }
    return allSet;
  }

}