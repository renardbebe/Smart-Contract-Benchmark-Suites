 

pragma solidity ^0.4.23;

 
contract Ownable {
  address public owner;
   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    if (paused) revert();
    _;
  }

   
  modifier whenPaused {
    if (!paused) revert();
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


 

contract News is Pausable {
  string[] public news;

  function addNews(string msg) onlyOwner public {
    news.push(msg);
  }
}