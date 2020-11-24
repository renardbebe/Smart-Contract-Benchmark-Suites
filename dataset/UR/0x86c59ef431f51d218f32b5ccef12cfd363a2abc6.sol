 

pragma solidity >0.4.99 <0.6.0;

contract Username {
  event Updated(address indexed user, string indexed username);

  mapping(address => string) public username;
  mapping(string => address) public owner;

  function Update(string memory _username) public {
    require(owner[_username] == address(0));
    string memory oldUserName = username[msg.sender];
    owner[_username] = msg.sender;
    owner[oldUserName] = address(0);
    username[msg.sender] = _username;
    emit Updated(msg.sender, _username);
  }
}