 

pragma solidity ^0.5.10;

contract AbstractAccount {

  event DeviceAdded(address device, bool isOwner);
  event DeviceRemoved(address device);
  event TransactionExecuted(address recipient, uint256 value, bytes data, bytes response);

  struct Device {
    bool isOwner;
    bool exists;
    bool existed;
  }

  mapping(address => Device) public devices;

  function addDevice(address _device, bool _isOwner) public;

  function removeDevice(address _device) public;

  function executeTransaction(address payable _recipient, uint256 _value, bytes memory _data) public returns (bytes memory _response);
}



 
contract Account is AbstractAccount {

  modifier onlyOwner() {
    require(
      devices[msg.sender].isOwner
    );

    _;
  }

  constructor() public {
    devices[msg.sender].isOwner = true;
    devices[msg.sender].exists = true;
    devices[msg.sender].existed = true;
  }

  function() external payable {
     
  }

  function addDevice(address _device, bool _isOwner) onlyOwner public {
    require(
      _device != address(0)
    );
    require(
      !devices[_device].exists
    );

    devices[_device].isOwner = _isOwner;
    devices[_device].exists = true;
    devices[_device].existed = true;

    emit DeviceAdded(_device, _isOwner);
  }

  function removeDevice(address _device) onlyOwner public {
    require(
      devices[_device].exists
    );

    devices[_device].isOwner = false;
    devices[_device].exists = false;

    emit DeviceRemoved(_device);
  }

  function executeTransaction(address payable _recipient, uint256 _value, bytes memory _data) onlyOwner public returns (bytes memory _response) {
    require(
      _recipient != address(0)
    );

    bool _succeeded;
    (_succeeded, _response) = _recipient.call.value(_value)(_data);

    require(
      _succeeded
    );

    emit TransactionExecuted(_recipient, _value, _data, _response);
  }
}