 

pragma solidity ^0.4.19;

 
contract MyFriendships {
    address public me;
    uint public numberOfFriends;
    address public latestFriend;
    
    mapping(address => bool) myFriends;

     
    function MyFriendships() public {
        me = msg.sender;
    }
 
     
    function becomeFriendsWithMe () public {
        require(msg.sender != me);  
        myFriends[msg.sender] = true;
        latestFriend = msg.sender;
        numberOfFriends++;
    }
    
     
    function friendsWith (address addr) public view returns (bool) {
        return myFriends[addr];
    }
}