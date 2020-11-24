 

pragma solidity ^0.5.8;

contract HashStorage3 {
  address public owner = msg.sender;
  Entry[] entries;

  struct Entry {
    string user;
    uint64 timestamp;
    string hash;
  }
  event Add(string user,uint64 timestamp,string hash);

  function add(string memory user, uint64 timestamp, string memory hash) public{
    if (msg.sender != owner) {
      revert('Only owner can call this contract');
    }
    entries.push(Entry(user,timestamp,hash));
     
  }

  function length() public view returns (uint) {
      return entries.length;
  }

  function get(uint at) public view returns(string memory user,uint64 timestamp,string memory hash){
      return (entries[at].user,entries[at].timestamp,entries[at].hash);
  }

}