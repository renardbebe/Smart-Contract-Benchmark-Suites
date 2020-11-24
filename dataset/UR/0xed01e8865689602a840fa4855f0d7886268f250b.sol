 

pragma solidity ^0.4.24;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Uselesslightbulb is Ownable {

   

  uint weiPrice = 1000000000000000;
  uint count = 0;

  function toggle() public payable {
    require(msg.value >= weiPrice);
    count++; 
  }

  function getCount() external view returns (uint) {
    return count;
  }

  function withdraw() onlyOwner public {
    owner.transfer(address(this).balance);
  }

}