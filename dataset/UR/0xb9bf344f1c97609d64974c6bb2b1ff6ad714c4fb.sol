 

pragma solidity >=0.4.22 <0.6.0;

contract Broadcaster {
    event Broadcast(
        string _value
    );

    function broadcast(string memory message) public {
         
         
         
         
         
        emit Broadcast(message);
    }
}