 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    if (msg.sender != pendingOwner) {
      throw;
    }
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner {
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

contract Index is Claimable {
  address [] public addresses;

  function getAllAddresses() constant public returns(address []) {
    return addresses;
  }

  function add(address item) onlyOwner {
    addresses.push(item);
  }

  function remove(uint pos) onlyOwner {
    if (pos >= addresses.length) throw;
    delete addresses[pos];
  }
}