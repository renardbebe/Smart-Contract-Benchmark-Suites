 

pragma solidity 0.5.3;

 

 
contract Stoppable {

   
  modifier onlyOwner { _; }
   

  bool public isOn = true;

  modifier whenOn() { require(isOn, "must be on"); _; }
  modifier whenOff() { require(!isOn, "must be off"); _; }

  function switchOff() external onlyOwner {
    if (isOn) {
      isOn = false;
      emit Off();
    }
  }
  event Off();
}

 

 
contract Switchable is Stoppable {

  function switchOn() external onlyOwner {
    if (!isOn) {
      isOn = true;
      emit On();
    }
  }
  event On();
}

 

contract Validating {

  modifier notZero(uint number) { require(number != 0, "invalid 0 value"); _; }
  modifier notEmpty(string memory text) { require(bytes(text).length != 0, "invalid empty string"); _; }
  modifier validAddress(address value) { require(value != address(0x0), "invalid address");  _; }

}

 

contract HasOwners is Validating {

  mapping(address => bool) public isOwner;
  address[] private owners;

  constructor(address[] memory _owners) public {
    for (uint i = 0; i < _owners.length; i++) _addOwner_(_owners[i]);
    owners = _owners;
  }

  modifier onlyOwner { require(isOwner[msg.sender], "invalid sender; must be owner"); _; }

  function getOwners() public view returns (address[] memory) { return owners; }

  function addOwner(address owner) external onlyOwner {  _addOwner_(owner); }

  function _addOwner_(address owner) private validAddress(owner) {
    if (!isOwner[owner]) {
      isOwner[owner] = true;
      owners.push(owner);
      emit OwnerAdded(owner);
    }
  }
  event OwnerAdded(address indexed owner);

  function removeOwner(address owner) external onlyOwner {
    if (isOwner[owner]) {
      require(owners.length > 1, "removing the last owner is not allowed");
      isOwner[owner] = false;
      for (uint i = 0; i < owners.length - 1; i++) {
        if (owners[i] == owner) {
          owners[i] = owners[owners.length - 1];  
          delete owners[owners.length - 1];
          break;
        }
      }
      owners.length -= 1;
      emit OwnerRemoved(owner);
    }
  }
  event OwnerRemoved(address indexed owner);
}

 

interface Registry {

  function contains(address apiKey) external view returns (bool);

  function register(address apiKey) external;
  function registerWithUserAgreement(address apiKey, bytes32 userAgreement) external;

  function translate(address apiKey) external view returns (address);
}

 

contract ApiKeyRegistry is Switchable, HasOwners, Registry {
  string public version;

   
  mapping (address => address) public accounts;
  mapping (address => bytes32) public userAgreements;

  constructor(address[] memory _owners, string memory _version) HasOwners(_owners) public {
    version = _version;
  }

  modifier isAbsent(address apiKey) { require(!contains(apiKey), "api key already in use"); _; }

  function contains(address apiKey) public view returns (bool) { return accounts[apiKey] != address(0x0); }

  function register(address apiKey) external { registerWithUserAgreement(apiKey, 0); }

  function registerWithUserAgreement(address apiKey, bytes32 userAgreement) public validAddress(apiKey) isAbsent(apiKey) whenOn {
    accounts[apiKey] = msg.sender;
    if (userAgreement != 0 && userAgreements[msg.sender] == 0) {
      userAgreements[msg.sender] = userAgreement;
    }
    emit Registered(apiKey, msg.sender, userAgreements[msg.sender]);
  }
  event Registered(address apiKey, address indexed account, bytes32 userAgreement);

  function translate(address apiKey) external view returns (address) { return accounts[apiKey]; }
}