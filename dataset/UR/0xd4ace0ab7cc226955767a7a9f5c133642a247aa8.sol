 

pragma solidity ^0.4.21;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
  public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
  public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}
 
library SafeMath {
     
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

     
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

}

 
contract Ownable {
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

 
contract AFDTICO is Ownable {
  using SafeERC20 for ERC20Basic;
   
  ERC20Basic public token;
  using SafeMath for uint256;
 
  uint256 public RATE = 2188;  
  uint256 public minimum = 10000000000000000;    
 
  address public constant FAVOREE = 0x57f3495D0eb2257F1B0Dbbc77a8A49E4AcAC82f5;  
  uint256 public raisedAmount = 0;  
  
   
  event BoughtTokens(address indexed to, uint256 value, uint256 tokens);

  constructor(ERC20Basic _token) public {
      token = _token;
  }

   
  function () public payable {

    buyTokens();
  }

   
  function buyTokens() public payable {
    require(msg.value >= minimum);
    uint256 tokens = msg.value.mul(RATE).div(10**10);   
    uint256 balance = token.balanceOf(this);      
    if (tokens > balance){                        
        msg.sender.transfer(msg.value);
    }
    
    else{
        token.transfer(msg.sender, tokens);  
        emit BoughtTokens(msg.sender, msg.value, tokens);
        raisedAmount = raisedAmount.add(msg.value);
    }
 }

   
  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }

  function ratio(uint256 _RATE) onlyOwner public {
      RATE = _RATE;
  }
  
  function withdrawals() onlyOwner public {
      FAVOREE.transfer(raisedAmount);
      raisedAmount = 0;
  }
  
  function adjust_eth(uint256 _minimum) onlyOwner  public {
      minimum = _minimum;
  }
   
  function destroy() onlyOwner public {
     
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(FAVOREE, balance);
     
    selfdestruct(FAVOREE); 
  }
}