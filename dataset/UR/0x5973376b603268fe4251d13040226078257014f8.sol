 

pragma solidity 0.4.24;

 

 
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

 

contract ContractRegistry is Ownable {

  uint8 public constant version = 1;
  mapping (bytes32 => address) private contractAddresses;

  event UpdateContract(string name, address indexed contractAddress);

   
  function isContract(address _address)
    private
    view
    returns (bool)
  {
    uint256 _size;
    assembly { _size := extcodesize(_address) }
    return _size > 0;
  }

  function updateContractAddress(string _name, address _address)
    public
    onlyOwner
    returns (address)
  {
    require(isContract(_address));
    require(_address != contractAddresses[keccak256(_name)]);

    contractAddresses[keccak256(_name)] = _address;
    emit UpdateContract(_name, _address);

    return _address;
  }

  function getContractAddress(string _name)
    public
    view
    returns (address)
  {
    require(contractAddresses[keccak256(_name)] != address(0));
    return contractAddresses[keccak256(_name)];
  }

  function getContractAddress32(bytes32 _name32)
    public
    view
    returns (address)
  {
    require(contractAddresses[_name32] != address(0));
    return contractAddresses[_name32];
  }
}