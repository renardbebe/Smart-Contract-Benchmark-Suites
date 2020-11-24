 

pragma solidity >0.4.99 <0.6.0;

contract OriginalPostUsername {
  event UsernameSet(address indexed user, bytes32 username);

  mapping(address => bytes32) public usernames;
  mapping(bytes32 => bool) public usernameUsed;

  function Set(bytes32 _username) public {
    require(!usernameUsed[_username]);
    bytes32 oldUserName = usernames[msg.sender];
    usernameUsed[_username] = true;
    usernameUsed[oldUserName] = false;
    usernames[msg.sender] = _username;
    emit UsernameSet(msg.sender, _username);
  }
}