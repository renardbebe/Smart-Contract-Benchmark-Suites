 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.1;


 
 
contract Whitelist is Ownable {

  event UsersAddedToWhitelist(address[] users);
  event UsersRemovedFromWhitelist(address[] users);

  mapping(address => bool) public isWhitelisted;

  function addToWhitelist(address[] calldata users) onlyOwner external {
    for (uint i = 0; i < users.length; i++) {
      isWhitelisted[users[i]] = true;
    }
    emit UsersAddedToWhitelist(users);
  }

  function removeFromWhitelist(address[] calldata users) onlyOwner external {
    for (uint i = 0; i < users.length; i++) {
      isWhitelisted[users[i]] = false;
    }
    emit UsersRemovedFromWhitelist(users);
  }
}