 

pragma solidity ^0.4.18;

interface CornFarm
{
    function buyObject(address _beneficiary) public payable;
}

interface Corn
{
    function transfer(address to, uint256 value) public returns (bool);
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

contract PepFarmer {
    using SafeMath for uint256;
    
    bool private reentrancy_lock = false;
    
    address public shop = 0x347eD75c305f4ab85757Bfcc5600D9BfCb413898;
    address public object = 0x9648915F9A4B6778C3d3716bC084F0a44E4Cba48;
    
    mapping(address => uint256) public workDone;
    
    modifier nonReentrant() {
        require(!reentrancy_lock);
        reentrancy_lock = true;
        _;
        reentrancy_lock = false;
    }
    
    function pepFarm() nonReentrant external {
        for (uint8 i = 0; i < 100; i++) {
            CornFarm(shop).buyObject(this);
        }
        
        workDone[msg.sender] = workDone[msg.sender].add(uint256(100 ether));
    }
    
    function reapFarm() nonReentrant external {
        require(workDone[msg.sender] > 0);
        Corn(object).transfer(msg.sender, workDone[msg.sender]);
        workDone[msg.sender] = 0;
    }
}