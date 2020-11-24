 

pragma solidity ^0.4.4;

 
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

contract Migrations is Ownable {
    uint public last_completed_migration;

    function setCompleted(uint _completed) onlyOwner {
        last_completed_migration = _completed;
    }

    function upgrade(address _newAddress) onlyOwner {
        Migrations upgraded = Migrations(_newAddress);
        upgraded.setCompleted(last_completed_migration);
    }
}