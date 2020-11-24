 

pragma solidity ^0.4.18;

 

contract Manageable {
  address public manager;


   
  function Manageable(address _manager) public {
    require(_manager != 0x0);
    manager = _manager;
  }

   
  modifier onlyManager() { 
    require (msg.sender == manager && manager != 0x0);
    _; 
  }
}

 

contract Activatable is Manageable {
  event ActivatedContract(uint256 activatedAt);
  event DeactivatedContract(uint256 deactivatedAt);

  bool public active;
  
   
  modifier isActive() {
    require(active);
    _;
  }

   
  modifier isNotActive() {
    require(!active);
    _;
  }

   
  function activate() public onlyManager isNotActive {
     
    active = true;

     
    ActivatedContract(now);
  }

   
  function deactivate() public onlyManager isActive {
     
    active = false;

     
    DeactivatedContract(now);
  }
}

 

contract Versionable is Activatable {
  string public name;
  string public version;
  uint256 public identifier;
  uint256 public createdAt;

   
  function Versionable (string _name, string _version, uint256 _identifier) public {
    require (bytes(_name).length != 0x0 && bytes(_version).length != 0x0 && _identifier > 0);

     
    name = _name;
    version = _version;
    identifier = _identifier;
    createdAt = now;
  }
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

 

contract ContractManagementSystem is Ownable {
  event UpgradedContract (uint256 contractIdentifier, address indexed oldContractAddress, address indexed newContractAddress);
  event RollbackedContract (uint256 contractIdentifier, address indexed fromContractAddress, address indexed toContractAddress);

  mapping (uint256 => mapping (address => bool)) public managedContracts;
  mapping (uint256 => address) public activeContracts;
  mapping (uint256 => bool) migrationLocks;

   
  modifier onlyWithoutLock(uint256 contractIdentifier) {
    require(!migrationLocks[contractIdentifier]);
    _;
  }

   
  function getActiveContractAddress(uint256 contractIdentifier)
    public
    constant
    onlyWithoutLock(contractIdentifier)
    returns (address activeContract)
  {
     
    require(contractIdentifier != 0x0);
    
     
    activeContract = activeContracts[contractIdentifier];

     
    require(activeContract != 0x0 && Activatable(activeContract).active());
  }

   
  function existsManagedContract(uint256 contractIdentifier, address contractAddress)
    public
    constant
    returns (bool)
  {
     
    require(contractIdentifier != 0x0 && contractAddress != 0x0);

    return managedContracts[contractIdentifier][contractAddress];
  }

   
  function upgradeContract(uint256 contractIdentifier, address newContractAddress)
    public
    onlyOwner
    onlyWithoutLock(contractIdentifier)
  {
     
    require(contractIdentifier != 0x0 && newContractAddress != 0x0);
    
     
    migrationLocks[contractIdentifier] = true;

     
    require(!Activatable(newContractAddress).active());

     
    require(contractIdentifier == Versionable(newContractAddress).identifier());

     
    require (!existsManagedContract(contractIdentifier, newContractAddress));

     
    address oldContractAddress = activeContracts[contractIdentifier];

     
    if (oldContractAddress != 0x0) {
      require(Activatable(oldContractAddress).active());
    }

     
    swapContractsStates(contractIdentifier, newContractAddress, oldContractAddress);

     
    managedContracts[contractIdentifier][newContractAddress] = true;

     
    migrationLocks[contractIdentifier] = false;
    
     
    UpgradedContract(contractIdentifier, oldContractAddress, newContractAddress);
  }

   
  function rollbackContract(uint256 contractIdentifier, address toContractAddress)
    public
    onlyOwner
    onlyWithoutLock(contractIdentifier)
  {
     
    require(contractIdentifier != 0x0 && toContractAddress != 0x0);

     
    migrationLocks[contractIdentifier] = true;

     
    require(contractIdentifier == Versionable(toContractAddress).identifier());

     
    require (!Activatable(toContractAddress).active() && existsManagedContract(contractIdentifier, toContractAddress));

     
    address fromContractAddress = activeContracts[contractIdentifier];

     
    swapContractsStates(contractIdentifier, toContractAddress, fromContractAddress);

     
    migrationLocks[contractIdentifier] = false;

     
    RollbackedContract(contractIdentifier, fromContractAddress, toContractAddress);
  }
  
   
  function swapContractsStates(uint256 contractIdentifier, address newContractAddress, address oldContractAddress) internal {
     
    if (oldContractAddress != 0x0) {
      Activatable(oldContractAddress).deactivate();
    }

     
    Activatable(newContractAddress).activate();

      
    activeContracts[contractIdentifier] = newContractAddress;
  }
}