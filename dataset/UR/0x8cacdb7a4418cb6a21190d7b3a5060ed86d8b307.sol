 

pragma solidity ^0.4.15;

 
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

 
contract Stoppable is Ownable {
  event Stop();  

  bool public stopped = false;

   
  modifier whenNotStopped() {
    require(!stopped);
    _;
  }

   
  modifier whenStopped() {
    require(stopped);
    _;
  }

   
  function stop() onlyOwner whenNotStopped public {
    stopped = true;
    Stop();
  }
}

contract SpaceRegistry is Stoppable {
    
    event Add();
    mapping(uint => uint) spaces;

    function addSpace(uint spaceId, uint userHash, bytes orderData) 
        onlyOwner whenNotStopped {

        require(spaceId > 0);
        require(userHash > 0);
        require(orderData.length > 0);
        require(spaces[spaceId] == 0);
        spaces[spaceId] = userHash;
        Add();
    }

    function addSpaces(uint[] spaceIds, uint[] userHashes, bytes orderData)
        onlyOwner whenNotStopped {

        var count = spaceIds.length;
        require(count > 0);
        require(userHashes.length == count);
        require(orderData.length > 0);

        for (uint i = 0; i < count; i++) {
            var spaceId = spaceIds[i];
            var userHash = userHashes[i];
            require(spaceId > 0);
            require(userHash > 0);
            require(spaces[spaceId] == 0);
            spaces[spaceId] = userHash;
        }

        Add();
    }

    function getSpaceById(uint spaceId) 
        external constant returns (uint userHash) {

        require(spaceId > 0);
        return spaces[spaceId];
    }

    function isSpaceExist(uint spaceId) 
        external constant returns (bool) {
            
        require(spaceId > 0);
        return spaces[spaceId] > 0;
    }
}