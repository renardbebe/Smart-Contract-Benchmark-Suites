 

pragma solidity ^0.4.23;

 

 
interface ContractManagerInterface {
   
  event ContractAdded(address indexed _address, string _contractName);

   
  event ContractRemoved(string _contractName);

   
  event ContractUpdated(address indexed _oldAddress, address indexed _newAddress, string _contractName);

   
  event AuthorizationChanged(address indexed _address, bool _authorized, string _contractName);

   
  function authorize(string _contractName, address _accessor) external view returns (bool);

   
  function addContract(string _contractName, address _address) external;

   
  function getContract(string _contractName) external view returns (address _contractAddress);

   
  function removeContract(string _contractName) external;

   
  function updateContract(string _contractName, address _newAddress) external;

   
  function setAuthorizedContract(string _contractName, address _authorizedAddress, bool _authorized) external;
}

 

 
contract ContractManager is ContractManagerInterface {
   
  mapping(string => address) private contracts;
   
  mapping(string => mapping(address => bool)) private authorization;

   
  event ContractAdded(address indexed _address, string _contractName);

   
  event ContractRemoved(string _contractName);

   
  event ContractUpdated(address indexed _oldAddress, address indexed _newAddress, string _contractName);

   
  event AuthorizationChanged(address indexed _address, bool _authorized, string _contractName);

   
  modifier onlyRegisteredContract(string _contractName) {
    require(contracts[_contractName] == msg.sender);
    _;
  }

   
  modifier onlyContractOwner(string _contractName, address _accessor) {
    require(contracts[_contractName] == msg.sender || contracts[_contractName] == address(this));
    require(_accessor != address(0));
    require(authorization[_contractName][_accessor] == true);
    _;
  }

   
  constructor() public {
    contracts["ContractManager"] = address(this);
    authorization["ContractManager"][msg.sender] = true;
  }

   
  function authorize(string _contractName, address _accessor) external onlyContractOwner(_contractName, _accessor) view returns (bool) {
    return true;
  }

   
  function addContract(string _contractName, address _address) external  onlyContractOwner("ContractManager", msg.sender) {
    bytes memory contractNameBytes = bytes(_contractName);

    require(contractNameBytes.length != 0);
    require(contracts[_contractName] == address(0));
    require(_address != address(0));

    contracts[_contractName] = _address;

    emit ContractAdded(_address, _contractName);
  }

   
  function getContract(string _contractName) external view returns (address _contractAddress) {
    require(contracts[_contractName] != address(0));

    _contractAddress = contracts[_contractName];

    return _contractAddress;
  }

   
  function removeContract(string _contractName) external onlyContractOwner("ContractManager", msg.sender) {
    bytes memory contractNameBytes = bytes(_contractName);

    require(contractNameBytes.length != 0);
     
    require(keccak256(_contractName) != keccak256("ContractManager"));
    require(contracts[_contractName] != address(0));
    
    delete contracts[_contractName];

    emit ContractRemoved(_contractName);
  }

   
  function updateContract(string _contractName, address _newAddress) external onlyContractOwner("ContractManager", msg.sender) {
    bytes memory contractNameBytes = bytes(_contractName);

    require(contractNameBytes.length != 0);
    require(contracts[_contractName] != address(0));
    require(_newAddress != address(0));

    address oldAddress = contracts[_contractName];
    contracts[_contractName] = _newAddress;

    emit ContractUpdated(oldAddress, _newAddress, _contractName);
  }

   
  function setAuthorizedContract(string _contractName, address _authorizedAddress, bool _authorized) external onlyContractOwner("ContractManager", msg.sender) {
    bytes memory contractNameBytes = bytes(_contractName);

    require(contractNameBytes.length != 0);
    require(_authorizedAddress != address(0));
    require(authorization[_contractName][_authorizedAddress] != _authorized);
    
    authorization[_contractName][_authorizedAddress] = _authorized;

    emit AuthorizationChanged(_authorizedAddress, _authorized, _contractName);
  }
}