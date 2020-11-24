 

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

contract FreeTaxManFarmer {
    using SafeMath for uint256;
    
    bool private reentrancy_lock = false;

    struct tokenInv {
      uint256 workDone;
    }
    
    mapping(address => mapping(address => tokenInv)) public userInventory;
    
    modifier nonReentrant() {
        require(!reentrancy_lock);
        reentrancy_lock = true;
        _;
        reentrancy_lock = false;
    }
    
    function pepFarm(address item_shop_address, address token_address, uint256 buy_amount) nonReentrant external {
        for (uint8 i = 0; i < buy_amount; i++) {
            CornFarm(item_shop_address).buyObject(this);
        }
        userInventory[msg.sender][token_address].workDone = userInventory[msg.sender][token_address].workDone.add(uint256(buy_amount * 10**18));
    }
    
    function reapFarm(address token_address) nonReentrant external {
        require(userInventory[msg.sender][token_address].workDone > 0);
        Corn(token_address).transfer(msg.sender, userInventory[msg.sender][token_address].workDone);
        userInventory[msg.sender][token_address].workDone = 0;
    }

}