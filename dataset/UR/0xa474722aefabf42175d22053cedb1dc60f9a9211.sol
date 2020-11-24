 

pragma solidity ^0.4.24;

 

 
contract EternalStorage {

  mapping(bytes32 => uint256) internal uintStorage;
  mapping(bytes32 => string) internal stringStorage;
  mapping(bytes32 => address) internal addressStorage;
  mapping(bytes32 => bytes) internal bytesStorage;
  mapping(bytes32 => bool) internal boolStorage;
  mapping(bytes32 => int256) internal intStorage;

}

 

 
contract Proxy {

   
  function implementation() public view returns (address);

   
  function () payable public {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

 

 
contract UpgradeabilityStorage {
   
  string internal _version;

   
  address internal _implementation;

   
  function version() public view returns (string) {
    return _version;
  }

   
  function implementation() public view returns (address) {
    return _implementation;
  }
}

 

 
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {
   
  event Upgraded(string version, address indexed implementation);

   
  function _upgradeTo(string version, address implementation) internal {
    require(_implementation != implementation);
    _version = version;
    _implementation = implementation;
    emit Upgraded(version, implementation);
  }
}

 

 
contract UpgradeabilityOwnerStorage {
   
  address private _upgradeabilityOwner;

   
  function upgradeabilityOwner() public view returns (address) {
    return _upgradeabilityOwner;
  }

   
  function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
    _upgradeabilityOwner = newUpgradeabilityOwner;
  }
}

 

 
contract OwnedUpgradeabilityProxy is UpgradeabilityOwnerStorage, UpgradeabilityProxy {
   
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

   
  constructor() public {
    setUpgradeabilityOwner(msg.sender);
  }

   
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

   
  function proxyOwner() public view returns (address) {
    return upgradeabilityOwner();
  }

   
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

   
  function upgradeTo(string version, address implementation) public onlyProxyOwner {
    _upgradeTo(version, implementation);
  }

   
  function upgradeToAndCall(string version, address implementation, bytes data) payable public onlyProxyOwner {
    upgradeTo(version, implementation);
    require(address(this).call.value(msg.value)(data));
  }
}

 

 
contract EternalStorageProxy is EternalStorage, OwnedUpgradeabilityProxy {}

 

contract DetailedToken{
	string public name;
	string public symbol;
	uint8 public decimals;
}

 

 
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

 

 



contract IcoTokenUpgradeability is EternalStorageProxy,DetailedToken{
	     

    constructor(string _name,string _symbol,uint8 _decimals)
			public{
				name=_name;
				symbol=_symbol;
				decimals=_decimals;
			}
}