 

pragma solidity >0.4.99 <0.6.0;

contract PostLike {
  event Liked(uint256 indexed postIdx, address indexed user);
  event Unliked(uint256 indexed postIdx, address indexed user);

  mapping(uint256 => uint256) public postLikeCount;
  mapping(address => mapping(uint256 => bool)) public liked;

  function Like(uint256 postIdx) public {
    require(!liked[msg.sender][postIdx]);
    liked[msg.sender][postIdx] = true;
    postLikeCount[postIdx] += 1;
    emit Liked(postIdx, msg.sender);
  }

  function Unlike(uint256 postIdx) public {
    require(liked[msg.sender][postIdx]);
    liked[msg.sender][postIdx] = false;
    postLikeCount[postIdx] -= 1;
    emit Unliked(postIdx, msg.sender);
  }
}