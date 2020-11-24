 

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
    uint constant START_INDEX = 1;
    Space[] spaces;
    mapping(uint => uint) spaceMap;
    mapping(uint => uint[]) userSpaceLookup;
    
    struct Space {
        uint id;
        uint userId;
        bytes userHash;
        uint bottomLeft;
        uint topLeft;
        uint topRight;
        uint bottomRight;
        string txType;
        string txId;
        uint txTime;
        uint created;
    }

    function SpaceRegistry() {
        spaces.length = START_INDEX;
    }

    function addSpace(
        uint id, uint userId, bytes userHash, uint bottomLeft, uint topLeft, 
        uint topRight, uint bottomRight, string txType, string txId, uint txTime) 
        onlyOwner whenNotStopped {

        require(id > 0);
        require(spaceMap[id] == 0);
        require(userId > 0);
        require(userHash.length > 0);
        require(bottomLeft > 0);
        require(topLeft > 0);
        require(topRight > 0);
        require(bottomRight > 0);
        require(bytes(txType).length > 0);
        require(bytes(txId).length > 0);
        require(txTime > 0);
        
        var space = Space({
            id: id,
            userId: userId,
            userHash: userHash,
            bottomLeft: bottomLeft,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            txType: txType,
            txId: txId,
            txTime: txTime,
            created: block.timestamp
        });

        var _index = spaces.push(space) - 1;
        assert(_index >= START_INDEX);
        spaceMap[id] = _index;
        userSpaceLookup[userId].push(id);
        Add();
    }

    function getSpaceByIndex(uint index) external constant returns(
        uint id,
        uint userId,
        bytes userHash,
        uint bottomLeft,
        uint topLeft,
        uint topRight, 
        uint bottomRight,
        string txType,
        string txId, 
        uint txTime,
        uint created) {

        var _index = index + START_INDEX;
        require(spaces.length > _index);
        var space = spaces[_index];
        id = space.id;
        userId = space.userId;
        userHash = space.userHash;
        bottomLeft = space.bottomLeft;
        topLeft = space.topLeft;
        topRight = space.topRight;
        bottomRight = space.bottomRight;
        txType = space.txType;
        txId = space.txId;
        txTime = space.txTime;
        created = space.created;
    }    

    function getSpaceById(uint _id) external constant returns(
        uint id,
        uint userId,
        bytes userHash,
        uint bottomLeft,
        uint topLeft,
        uint topRight, 
        uint bottomRight,
        string txType,
        string txId,
        uint txTime,
        uint created) {

        require(_id > 0);
        id = _id;
        var index = spaceMap[id];
        var space = spaces[index];
        userId = space.userId;
        userHash = space.userHash;
        bottomLeft = space.bottomLeft;
        topLeft = space.topLeft;
        topRight = space.topRight;
        bottomRight = space.bottomRight;
        txType = space.txType;
        txId = space.txId;
        txTime = space.txTime;
        created = space.created;
    }

    function getUserSpaceIds(uint userId) external constant returns(uint[]) {
        require(userId > 0);
        return userSpaceLookup[userId]; 
    }

    function getUserId(uint id) external constant returns(uint) {
        require(id > 0);
        var index = spaceMap[id];
        require(index > 0);
        var space = spaces[index];
        return space.userId; 
    }

    function exists(uint id) external constant returns(bool) {
        require(id > 0);
        return spaceMap[id] != 0;
    }
    
    function spaceCount() constant returns (uint) {
        return spaces.length - START_INDEX;
    }   
}