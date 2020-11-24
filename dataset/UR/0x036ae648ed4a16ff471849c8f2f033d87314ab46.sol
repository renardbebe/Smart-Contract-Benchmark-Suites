 

pragma solidity 0.4.19;

 
contract Ownable {
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}


 
contract HardCap is Ownable {
  using SafeMath for uint;
  event CapUpdated(uint timestamp, bytes32 symbol, uint rate);
  
  mapping(bytes32 => uint) public caps;
  uint hardcap = 0;

   
  function updateCap(string _symbol, uint _cap) public onlyOwner {
    caps[sha3(_symbol)] = _cap;
    hardcap = hardcap.add(_cap) ;
    CapUpdated(now, sha3(_symbol), _cap);
  }

   
  function updateCaps(uint[] data) public onlyOwner {
    require(data.length % 2 == 0);
    uint i = 0;
    while (i < data.length / 2) {
      bytes32 symbol = bytes32(data[i * 2]);
      uint cap = data[i * 2 + 1];
      caps[symbol] = cap;
      hardcap = hardcap.add(cap);
      CapUpdated(now, symbol, cap);
      i++;
    }
  }

   
  function getCap(string _symbol) public constant returns(uint) {
    return caps[sha3(_symbol)];
  }
  
   
  function getHardCap() public constant returns(uint) {
    return hardcap;
  }

}