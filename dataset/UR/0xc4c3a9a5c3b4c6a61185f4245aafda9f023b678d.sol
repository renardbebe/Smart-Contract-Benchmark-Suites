 

pragma solidity ^0.5.9;

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    assert(newOwner != address(0));
    owner = newOwner;
  }
}

contract HubrisOne is Ownable {
  uint256 public fees;

  function setHubrisOneFees(uint256 _fees) public onlyOwner {
    fees = _fees;
  }

  function () external payable {}

  function transfer(address payable to) public payable {
      assert(msg.value > fees);
      to.transfer(msg.value - fees);
  }

  function collect() public onlyOwner {
      msg.sender.transfer(address(this).balance);
  }
}