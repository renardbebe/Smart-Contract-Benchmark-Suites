 

pragma solidity ^0.4.18;
 
 
 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract NVT {
    function transfer(address _to, uint _value) public returns (bool);
}

contract NVTDrop is Ownable{
  mapping(address => bool) getDropped;
  bool public halted = true;
  uint256 public amout = 1 * 10 ** 4;
  address public NVTAddr;
  NVT NVTFace;
  function setNVTface(address _nvt) public onlyOwner {
    NVTFace = NVT(_nvt);
  }
  function setAmout(uint _amout) onlyOwner {
    amout = _amout;
  }

  function () public payable{
    require(getDropped[msg.sender] == false);
    require(halted == false);
    getDropped[msg.sender] = true;
    NVTFace.transfer(msg.sender, amout);
  }



  function getStuckCoin (address _to, uint _amout) onlyOwner{
    _to.transfer(_amout);
  }
  function halt() onlyOwner{
    halted = true;
  }
  function unhalt() onlyOwner{
    halted = false;
  }
}