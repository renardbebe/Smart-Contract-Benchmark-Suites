 

 
pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




 
contract Registry is Ownable {
  mapping (address => address[]) public deployedContracts;

  event Added(address indexed sender, address indexed deployAddress);

  function add(address deployAddress) public {
    deployedContracts[msg.sender].push(deployAddress);
    Added(msg.sender, deployAddress);
  }

  function count(address deployer) constant returns (uint) {
    return deployedContracts[deployer].length;
  }
}