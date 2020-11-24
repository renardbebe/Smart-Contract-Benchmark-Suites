 

pragma solidity ^0.5.8;

 
contract HashStorage{
  bytes hash;

  function set(string memory x) public{
    hash = abi.encode(keccak256(abi.encode(x)));
  }

  function get() public view returns(bytes memory){
    return hash;
  }

}