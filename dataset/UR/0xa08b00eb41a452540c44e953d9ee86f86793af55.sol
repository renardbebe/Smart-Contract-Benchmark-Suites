 

pragma solidity 0.4.24;

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface AccountRegistryInterface {
  function accountIdForAddress(address _address) public view returns (uint256);
  function addressBelongsToAccount(address _address) public view returns (bool);
  function createNewAccount(address _newUser) external;
  function addAddressToAccount(
    address _newAddress,
    address _sender
    ) external;
  function removeAddressFromAccount(address _addressToRemove) external;
}

 
contract AccountRegistry is Ownable, AccountRegistryInterface{

  address public accountRegistryLogic;

   
  constructor(
    address _accountRegistryLogic
    ) public {
    accountRegistryLogic = _accountRegistryLogic;
  }

  event AccountRegistryLogicChanged(address oldRegistryLogic, address newRegistryLogic);

   
  modifier nonZero(address _address) {
    require(_address != 0);
    _;
  }

  modifier onlyAccountRegistryLogic() {
    require(msg.sender == accountRegistryLogic);
    _;
  }

   
  uint256 numAccounts;
  mapping(address => uint256) public accountByAddress;

   
  function setRegistryLogic(address _newRegistryLogic) public onlyOwner nonZero(_newRegistryLogic) {
    address _oldRegistryLogic = accountRegistryLogic;
    accountRegistryLogic = _newRegistryLogic;
    emit AccountRegistryLogicChanged(_oldRegistryLogic, accountRegistryLogic);
  }

   
  function accountIdForAddress(address _address) public view returns (uint256) {
    require(addressBelongsToAccount(_address));
    return accountByAddress[_address];
  }

   
  function addressBelongsToAccount(address _address) public view returns (bool) {
    return accountByAddress[_address] > 0;
  }

   
  function createNewAccount(address _newUser) external onlyAccountRegistryLogic nonZero(_newUser) {
    require(!addressBelongsToAccount(_newUser));
    numAccounts++;
    accountByAddress[_newUser] = numAccounts;
  }

   
  function addAddressToAccount(
    address _newAddress,
    address _sender
    ) external onlyAccountRegistryLogic nonZero(_newAddress) {

     
    require(!addressBelongsToAccount(_newAddress));

    accountByAddress[_newAddress] = accountIdForAddress(_sender);
  }

   
  function removeAddressFromAccount(
    address _addressToRemove
    ) external onlyAccountRegistryLogic {
    delete accountByAddress[_addressToRemove];
  }
}