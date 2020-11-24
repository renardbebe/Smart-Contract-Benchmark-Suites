 

pragma solidity >0.4.99 <0.6.0;

contract Username {
  event Updated(address indexed user, bytes32 indexed username);

  mapping(address => bytes32) public username;
  mapping(bytes32 => address) public owner;

  function Update(bytes32 _username) public {
    require(owner[_username] == address(0));
    bytes32 oldUserName = username[msg.sender];
    owner[_username] = msg.sender;
    owner[oldUserName] = address(0);
    username[msg.sender] = _username;
    emit Updated(msg.sender, _username);
  }
}