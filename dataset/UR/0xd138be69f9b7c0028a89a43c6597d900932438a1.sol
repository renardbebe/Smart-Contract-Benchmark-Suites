 

pragma solidity ^0.4.23;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
contract DealsRootStorage is Ownable {
  mapping(uint256 => bytes32) roots;
  uint256 public lastTimestamp = 0;

   
  function setRoot(uint256 _timestamp, bytes32 _root) onlyOwner public returns (bool) {
    require(_timestamp > 0);
    require(roots[_timestamp] == 0);

    roots[_timestamp] = _root;
    lastTimestamp = _timestamp;

    return true;
  }

   
  function lastRoot() public view returns (bytes32) {
    return roots[lastTimestamp];
  }

   
  function getRoot(uint256 _timestamp) public view returns (bytes32) {
    return roots[_timestamp];
  }
}