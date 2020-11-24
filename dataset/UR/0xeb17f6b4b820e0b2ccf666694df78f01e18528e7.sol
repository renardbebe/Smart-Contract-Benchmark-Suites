 

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
    
    address owner;
    
    token public tokenReward;
    
    uint start = 1523232000;
    
    uint period = 22;
    
    
    
    function Crowdsale (
        address addressOfTokenUsedAsReward
        ) public {
        owner = msg.sender;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
        modifier saleIsOn() {
        require(now > start && now < start + period * 1 days);
        _;
    }
    
    function sellTokens() public saleIsOn payable {
        owner.transfer(msg.value);
        
        uint price = 400;
        
if(now < start + (period * 1 days ).div(2)) 
{  price = 800;} 
else if(now >= start + (period * 1 days).div(2) && now < start + (period * 1 days).div(4).mul(3)) 
{  price = 571;} 
else if(now >= start + (period * 1 days ).div(4).mul(3) && now < start + (period * 1 days )) 
{  price = 500;}
    
    uint tokens = msg.value.mul(price);
    
    tokenReward.transfer(msg.sender, tokens); 
    
    }
    
    
   function() external payable {
        sellTokens();
    }
    
}