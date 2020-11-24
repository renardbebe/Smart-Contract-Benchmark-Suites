 

pragma solidity ^0.4.24;

contract EternalStorage {

     
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => bytes32) internal bytes32Storage;

     
    mapping(bytes32 => bytes32[]) internal bytes32ArrayStorage;
    mapping(bytes32 => uint256[]) internal uintArrayStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
    mapping(bytes32 => string[]) internal stringArrayStorage;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

    function set(bytes32 _key, uint256 _value) internal {
        uintStorage[_key] = _value;
    }

    function set(bytes32 _key, address _value) internal {
        addressStorage[_key] = _value;
    }

    function set(bytes32 _key, bool _value) internal {
        boolStorage[_key] = _value;
    }

    function set(bytes32 _key, bytes32 _value) internal {
        bytes32Storage[_key] = _value;
    }

    function set(bytes32 _key, string _value) internal {
        stringStorage[_key] = _value;
    }

     
     
     
     
     
     
     
     
     
     
     

    function getBool(bytes32 _key) internal view returns (bool) {
        return boolStorage[_key];
    }

    function getUint(bytes32 _key) internal view returns (uint256) {
        return uintStorage[_key];
    }

    function getAddress(bytes32 _key) internal view returns (address) {
        return addressStorage[_key];
    }

    function getString(bytes32 _key) internal view returns (string) {
        return stringStorage[_key];
    }

    function getBytes32(bytes32 _key) internal view returns (bytes32) {
        return bytes32Storage[_key];
    }


     
     
     
     
     
     
     
     


     
    function deleteArrayAddress(bytes32 _key, uint256 _index) internal {
        address[] storage array = addressArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

     
    function deleteArrayBytes32(bytes32 _key, uint256 _index) internal {
        bytes32[] storage array = bytes32ArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

     
    function deleteArrayUint(bytes32 _key, uint256 _index) internal {
        uint256[] storage array = uintArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

     
    function deleteArrayString(bytes32 _key, uint256 _index) internal {
        string[] storage array = stringArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

     
     
     
     
     
     
     

     
     
     
    function pushArray(bytes32 _key, address _value) internal {
        addressArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, bytes32 _value) internal {
        bytes32ArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, string _value) internal {
        stringArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, uint256 _value) internal {
        uintArrayStorage[_key].push(_value);
    }

     
     
     
     
     
     
     
    
    function setArray(bytes32 _key, address[] _value) internal {
        addressArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, uint256[] _value) internal {
        uintArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, bytes32[] _value) internal {
        bytes32ArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, string[] _value) internal {
        stringArrayStorage[_key] = _value;
    }

     
     
     
     
     
     
     
     

    function getArrayAddress(bytes32 _key) internal view returns(address[]) {
        return addressArrayStorage[_key];
    }

    function getArrayBytes32(bytes32 _key) internal view returns(bytes32[]) {
        return bytes32ArrayStorage[_key];
    }

    function getArrayString(bytes32 _key) internal view returns(string[]) {
        return stringArrayStorage[_key];
    }

    function getArrayUint(bytes32 _key) internal view returns(uint[]) {
        return uintArrayStorage[_key];
    }

     
     
     
     
     
     
     

    function setArrayIndexValue(bytes32 _key, uint256 _index, address _value) internal {
        addressArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, uint256 _value) internal {
        uintArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, bytes32 _value) internal {
        bytes32ArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, string _value) internal {
        stringArrayStorage[_key][_index] = _value;
    }

         
         
         

    function getUintValues(bytes32 _variable) public view returns(uint256) {
        return uintStorage[_variable];
    }

    function getBoolValues(bytes32 _variable) public view returns(bool) {
        return boolStorage[_variable];
    }

    function getStringValues(bytes32 _variable) public view returns(string) {
        return stringStorage[_variable];
    }

    function getAddressValues(bytes32 _variable) public view returns(address) {
        return addressStorage[_variable];
    }

    function getBytes32Values(bytes32 _variable) public view returns(bytes32) {
        return bytes32Storage[_variable];
    }

    function getBytesValues(bytes32 _variable) public view returns(bytes) {
        return bytesStorage[_variable];
    }

}

 
contract Proxy {

     
    function _implementation() internal view returns (address);

     
    function _fallback() internal {
        _delegate(_implementation());
    }

     
    function _delegate(address implementation) internal {
         
        assembly {
             
             
             
            calldatacopy(0, 0, calldatasize)

             
             
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

             
            returndatacopy(0, 0, returndatasize)

            switch result
             
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

    function () public payable {
        _fallback();
    }
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 
contract UpgradeabilityProxy is Proxy {

     
    string internal __version;

     
    address internal __implementation;

     
    event Upgraded(string _newVersion, address indexed _newImplementation);

     
    function _upgradeTo(string _newVersion, address _newImplementation) internal {
        require(
            __implementation != _newImplementation && _newImplementation != address(0),
            "Old address is not allowed and implementation address should not be 0x"
        );
        require(AddressUtils.isContract(_newImplementation), "Cannot set a proxy implementation to a non-contract address");
        require(bytes(_newVersion).length > 0, "Version should not be empty string");
        require(keccak256(abi.encodePacked(__version)) != keccak256(abi.encodePacked(_newVersion)), "New version equals to current");
        __version = _newVersion;
        __implementation = _newImplementation;
        emit Upgraded(_newVersion, _newImplementation);
    }

}

 
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {

     
    address private __upgradeabilityOwner;

     
    event ProxyOwnershipTransferred(address _previousOwner, address _newOwner);

     
    modifier ifOwner() {
        if (msg.sender == _upgradeabilityOwner()) {
            _;
        } else {
            _fallback();
        }
    }

     
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

     
    function _upgradeabilityOwner() internal view returns (address) {
        return __upgradeabilityOwner;
    }

     
    function _setUpgradeabilityOwner(address _newUpgradeabilityOwner) internal {
        require(_newUpgradeabilityOwner != address(0), "Address should not be 0x");
        __upgradeabilityOwner = _newUpgradeabilityOwner;
    }

     
    function _implementation() internal view returns (address) {
        return __implementation;
    }

     
    function proxyOwner() external ifOwner returns (address) {
        return _upgradeabilityOwner();
    }

     
    function version() external ifOwner returns (string) {
        return __version;
    }

     
    function implementation() external ifOwner returns (address) {
        return _implementation();
    }

     
    function transferProxyOwnership(address _newOwner) external ifOwner {
        require(_newOwner != address(0), "Address should not be 0x");
        emit ProxyOwnershipTransferred(_upgradeabilityOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

     
    function upgradeTo(string _newVersion, address _newImplementation) external ifOwner {
        _upgradeTo(_newVersion, _newImplementation);
    }

     
    function upgradeToAndCall(string _newVersion, address _newImplementation, bytes _data) external payable ifOwner {
        _upgradeTo(_newVersion, _newImplementation);
         
        require(address(this).call.value(msg.value)(_data), "Fail in executing the function of implementation contract");
    }

}

 
 
contract SecurityTokenRegistryProxy is EternalStorage, OwnedUpgradeabilityProxy {

}