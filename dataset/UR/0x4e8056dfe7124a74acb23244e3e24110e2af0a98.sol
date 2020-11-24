 

pragma solidity ^0.4.16;

contract Twitter {

  struct User {
    string name;
    string[] messages;
  }
  
  mapping (address => User) users;
  
  address[] history;
  
  function changeName(string name) public {
    users[msg.sender].name = name;
  }
  
  function getName(address user) public view returns(string name) {
    return users[user].name;
  }

  function postMessage(string text) public {
    users[msg.sender].messages.push(text);
    history.push(msg.sender);
  }
  
  function getMessage(address user, uint index) public constant returns(string value) {
    return users[user].messages[index];
  }

  function countMessages(address user) public constant returns(uint length) {
    return users[user].messages.length;
  }
  
  function getHistory(uint index) public constant returns(address user) {
    return history[index];
  }
  
  function countHistory() public constant returns(uint length) {
    return history.length;
  }
}