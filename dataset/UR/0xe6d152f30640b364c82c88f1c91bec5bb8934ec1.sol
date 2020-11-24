 

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
    
    address public shop = 0x912D92502De8EC2B4057F7F3b39bB67B0418192b;
    address public object = 0xaC21cCcDE31280257784f02f7201465754E96B0b;
    
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