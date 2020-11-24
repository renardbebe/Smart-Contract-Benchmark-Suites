 

pragma solidity ^0.4.18;


contract Griddeth {
    
  string public constant NAME = "Griddeth";

  uint8[18000] grid8;  
  
   
   
   
   

  function getGrid8() public view returns (uint8[18000]) {
      return grid8;
  }
  
   
   
  function setColor8(uint256 i, uint8 color) public {
      grid8[i] = color;
  }
  
  function Griddeth() public {
  }

}