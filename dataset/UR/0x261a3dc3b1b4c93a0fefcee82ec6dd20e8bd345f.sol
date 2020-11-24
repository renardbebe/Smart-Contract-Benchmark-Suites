 

pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract VAtomOwner is Ownable {

    mapping (string => string) vatoms;

    function setVAtomOwner(string vatomID, string ownerID) public onlyOwner {
        vatoms[vatomID] = ownerID;
    }

    function getVatomOwner(string vatomID) public constant returns(string) {
        return vatoms[vatomID];
    }
}