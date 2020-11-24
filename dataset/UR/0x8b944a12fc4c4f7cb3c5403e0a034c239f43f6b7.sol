 

pragma solidity 0.4.25;

 
contract Forwarder {
     
    address constant public destinationAddress = 0x609E7e5Db94b3F47a359955a4c823538A5891D48;
    event LogForwarded(address indexed sender, uint amount);

     
    function() payable public {
        emit LogForwarded(msg.sender, msg.value);
        destinationAddress.transfer(msg.value);
    }
}