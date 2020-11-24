 

pragma solidity ^0.4.20;

 
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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

 
contract TokenTimelock is Claimable {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;
   
  ERC20Basic public token;
  
   
  uint256 public tokenBalance;
   
  mapping (address => uint256) public beneficiaryMap;
   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    releaseTime = _releaseTime;
  }

  function isAvailable() public view returns (bool){
    if(now >= releaseTime){
      return true;
    } else { 
      return false; 
    }
  }

   
  function depositTokens(address _beneficiary, uint256 _amount)
      public
      onlyOwner
  {
       
      require(tokenBalance.add(_amount) == token.balanceOf(this));
      tokenBalance = tokenBalance.add(_amount);

       
      beneficiaryMap[_beneficiary] = beneficiaryMap[_beneficiary].add(_amount);
  }

   
  function release() public {
    require(now >= releaseTime);

     
    uint256 amount = beneficiaryMap[msg.sender];
    beneficiaryMap[msg.sender] = 0;

     
    require(amount > 0 && token.balanceOf(this) > 0);

    token.safeTransfer(msg.sender, amount);
  }
}