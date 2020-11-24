 

pragma solidity >0.4.99 <0.6.0;

contract OriginalPost {
  event Posted(uint256 indexed postIdx, address indexed creator, string data);
  uint256 public postIdx;

  function Post(string memory data) public {
    emit Posted(postIdx, msg.sender, data);
    postIdx += 1;
  }
}