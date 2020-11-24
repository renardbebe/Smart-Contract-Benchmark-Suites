 

 

pragma solidity 0.5.10;

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


contract DepositProxy {

    address payable public account;
    address payable public paymentManager;

    constructor (address payable _account, address payable _paymentManager) public {
        account = _account;
        paymentManager = _paymentManager;
    }

    function () payable external {
        address(account).transfer(msg.value);
        bytes memory empty;
        AbstractAccount(account).executeTransaction(paymentManager, msg.value, empty);
    }

}