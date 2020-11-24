 

pragma solidity ^0.4.4;

contract Random {
  uint64 _seed = 0;

   
   
  function random(uint64 upper) public returns (uint64 randomNumber) {
    _seed = uint64(sha3(sha3(block.blockhash(block.number), _seed), now));
    return _seed % upper;
  }
}