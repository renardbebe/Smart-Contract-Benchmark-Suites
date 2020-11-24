 

pragma solidity ^0.4.18;

 
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
contract ParetoTreasuryLockup {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;
  
  uint256 public month = 30 days;

  uint256 public maxThreshold = 0;

  function ParetoTreasuryLockup()public {
    token = ERC20Basic(0xea5f88E54d982Cbb0c441cde4E79bC305e5b43Bc);
    beneficiary = 0x005d85FE4fcf44C95190Cad3c1bbDA242A62EEB2;
    releaseTime = now + month;
  }

   
  function release() public {
    require(now >= releaseTime);
    
    uint diff = now - releaseTime;
    if (diff > month){
        releaseTime = now;
    }else{
        releaseTime = now.add(month.sub(diff));
    }
    
    if(maxThreshold == 0){
        
        uint256 amount = token.balanceOf(this);
        require(amount > 0);
        
         
        maxThreshold = (amount.mul(5)).div(100);
    }

    token.safeTransfer(beneficiary, maxThreshold);
    
  }
}