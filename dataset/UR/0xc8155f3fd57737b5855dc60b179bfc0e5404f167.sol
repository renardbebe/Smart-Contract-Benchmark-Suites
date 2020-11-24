 

pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
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

 
contract Ownable {
    
  address public owner;

   
  function Ownable() public{
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) private onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address public escrow;
    
    token public tokenReward;
    
    uint start = 1525132800;
    
    uint period = 31;
    
    
    
    function Crowdsale (
        
        
        ) public {
        escrow = 0x8bB3E0e70Fa2944DBA0cf5a1AF6e230A9453c647;
        tokenReward = token(0xACE380244861698DBa241C4e0d6F8fFc588A6F73);
    }
    
        modifier saleIsOn() {
        require(now > start && now < start + period * 1 days);
        _;
    }
    
    function sellTokens() public saleIsOn payable {
        escrow.transfer(msg.value);
        
        uint price = 400;
        
    
    uint tokens = msg.value.mul(price);
    
    tokenReward.transfer(msg.sender, tokens); 
    
    }
    
    
   function() external payable {
        sellTokens();
    }
    
}