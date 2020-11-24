 

pragma solidity ^0.4.13;

contract Owned {
    function Owned() {
        owner = msg.sender;
    }

    address public owner;

     
     
     
    modifier onlyOwner { if (msg.sender == owner) _; }

    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }

     
     
     
    function execute(address _dst, uint _value, bytes _data) onlyOwner {
        _dst.call.value(_value)(_data);
    }
}

contract ChooseWHGReturnAddress is Owned {

    mapping (address => address) returnAddresses;
    uint public endDate;

     
     
    function ChooseWHGReturnAddress(uint _endDate) {
        endDate = _endDate;
    }

     
     
     
     
     
     
     
     

     
     
     
    function requestReturn(address _returnAddr) {

         
         
        require(now <= endDate);

        require(returnAddresses[msg.sender] == 0x0);
        returnAddresses[msg.sender] = _returnAddr;
        ReturnRequested(msg.sender, _returnAddr);
    }
     
     
     
     
    function getReturnAddress(address _addr) constant returns (address) {
        if (returnAddresses[_addr] == 0x0) {
            return _addr;
        } else {
            return returnAddresses[_addr];
        }
    }

    function isReturnRequested(address _addr) constant returns (bool) {
        return returnAddresses[_addr] != 0x0;
    }

    event ReturnRequested(address indexed origin, address indexed returnAddress);
}