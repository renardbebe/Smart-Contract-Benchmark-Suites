 

pragma solidity ^0.4.0;

 
 
contract AndxorLogger {
    event LogHash(uint256 hash);

    function AndxorLogger() {
    }

     
    function logHash(uint256 value) {
        LogHash(value);
    }
}