 

pragma solidity ^0.4.24;

contract forwardEth {
    address public owner;
    address public destination;
    
    constructor() public {
        owner = msg.sender;
        destination = msg.sender;
    }
    
    modifier ownerOnly() {
        require(msg.sender==owner);
        _;
    }
    
     
    function setNewOwner(address _newOwner) public ownerOnly {
        owner = _newOwner;
    }
    
     
    function setReceiver(address _newReceiver) public ownerOnly {
        destination = _newReceiver;
    }
    
     
    function() payable public {
         
		
		require(destination.call.value(msg.value)(msg.data));
    }
    
     
    function _destroyContract() public ownerOnly {
        selfdestruct(destination);
    }
}