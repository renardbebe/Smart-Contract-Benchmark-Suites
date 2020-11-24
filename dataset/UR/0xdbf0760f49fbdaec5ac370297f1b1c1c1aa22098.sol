 

pragma solidity ^0.5.12;

contract Lottery {
    uint16 public randomNumber;

    function generateNumber(uint16 maxValue) public {
        randomNumber = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty,block.coinbase,maxValue)))%maxValue+1);
    }  
}