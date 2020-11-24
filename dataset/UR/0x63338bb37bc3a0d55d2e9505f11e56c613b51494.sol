 

 

pragma solidity ^0.4.11;


contract FlightDelayAddressResolver {

    address public addr;

    address owner;

    function FlightDelayAddressResolver() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) {
        require(msg.sender == owner);
        owner = _owner;
    }

    function getAddress() constant returns (address _addr) {
        return addr;
    }

    function setAddress(address _addr) {
        require(msg.sender == owner);
        addr = _addr;
    }
}