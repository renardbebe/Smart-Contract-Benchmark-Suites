 

pragma solidity ^0.4.4;

contract YourArray {

  struct MyStruct {
    string[] structArray;
  }

  mapping(address => MyStruct) myStructs;

  function appendString(string appendMe) returns(uint length) {
    return myStructs[msg.sender].structArray.push(appendMe);
  }

  function getCount() constant returns(uint length) {
    return myStructs[msg.sender].structArray.length;
  }

  function getStringAtIndex(uint index) constant returns(string value) {
    return myStructs[msg.sender].structArray[index];
  }
}