 

pragma solidity ^0.4.11;
contract TheButton {
    uint public lastPressed;
    event ButtonPress(address presser, uint pressTime, uint score);
    
     
    function press() {
        ButtonPress(msg.sender, now, (now - lastPressed)%256);
        lastPressed = now;
    }
}