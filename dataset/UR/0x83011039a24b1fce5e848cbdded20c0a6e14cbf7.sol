 

pragma solidity ^0.4.22;

contract AddressProxy {

     
    address public owner;

     
    address public client;

     
    bool public locked;

     
    constructor(address _owner, address _client) public {
        owner = _owner;
        client = _client;
        locked = false;
    }

    modifier auth() {
        require(msg.sender == owner || msg.sender == client);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isUnlocked() {
        require(locked == false);
        _;
    }

    event ChangedOwner(address _newOwner);
    event ChangedClient(address _newClient);

     
    function() payable public {}

     
    function exec(address _location, bytes _data, uint256 _ether) payable external auth() isUnlocked() {
        require(_location.call.value(_ether)(_data));
    }

     
    function sendEther(address _to, uint _amount) external auth() isUnlocked() {
        _to.transfer(_amount);
    }

     
    function execCustom(address _location, bytes _data, uint256 _value, uint256 _gas) payable external auth() isUnlocked() {
        require(_location.call.value(_value).gas(_gas)(_data));
    }

     
    function lock() external auth() {
        locked = true;
    }

     
    function unlock() external onlyOwner() {
        locked = false;
    }

     
    function changeOwner(address _newOwner) external onlyOwner() {
        owner = _newOwner;
        emit ChangedOwner(owner);
    }

     
    function changeClient(address _newClient) external onlyOwner() {
        client = _newClient;
        emit ChangedClient(client);
    }

}