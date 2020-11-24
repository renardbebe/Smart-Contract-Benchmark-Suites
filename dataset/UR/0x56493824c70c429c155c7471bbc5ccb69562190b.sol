 

pragma solidity >0.4.99 <0.6.0;

contract Description {
  event Updated(uint256 indexed descriptionIdx, address indexed creator, string data);

  uint256 public descriptionIdx;
  mapping(address => uint256) public description;

  function Update(string memory data) public {
    descriptionIdx += 1;
    emit Updated(descriptionIdx, msg.sender, data);
    description[msg.sender] = descriptionIdx;
  }
}