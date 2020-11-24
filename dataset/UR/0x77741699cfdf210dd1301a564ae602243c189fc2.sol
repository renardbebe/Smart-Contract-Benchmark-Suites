 

pragma solidity ^0.4.23; 
 

contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


contract _ERC20Pool {
    
  using SafeMath for uint64;

   
  ERC20Interface public tokenContract = ERC20Interface(0xB6eD7644C69416d67B522e20bC294A9a9B405B31);
  
   
  address public owner = 0x53CE57325C126145dE454719b4931600a0BD6Fc4;
  
  uint64 public totalTokenSupply;
  mapping (address => uint64) public minerTokens;
  mapping (address => uint64) public minerTokenPayouts;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier hasTokens() {
    require(minerTokens[msg.sender] > 0);
    _;
  }

   
  function addMinerTokens(uint64 totalTokensInBatch, address[] minerAddress, uint64[] minerRewardTokens) public onlyOwner {
    totalTokenSupply += totalTokensInBatch;
    for (uint i = 0; i < minerAddress.length; i ++) {
      minerTokens[minerAddress[i]] = minerTokens[minerAddress[i]].add(minerRewardTokens[i]);
    }
  }
  
   
  function withdraw() public
    hasTokens
  {
    uint64 amount = minerTokens[msg.sender];
    minerTokens[msg.sender] = 0;
    totalTokenSupply = totalTokenSupply.sub(amount);
    minerTokenPayouts[msg.sender] = minerTokenPayouts[msg.sender].add(amount);
    tokenContract.transfer(msg.sender, amount);
  }
  
   
   
  function () public payable {
    revert();
  }
  
   
  function withdrawEther(uint64 amount) public onlyOwner {
    owner.transfer(amount);
  }
  
   
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    if(tokenAddress == 0xB6eD7644C69416d67B522e20bC294A9a9B405B31 ){ 
        revert(); 
    }
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
  
}

 
library SafeMath {
     
     function mul(uint64 a, uint64 b) internal pure returns (uint64) {
     if (a == 0) {
     return 0;
     }
     uint64 c = a * b;
     assert(c / a == b);
     return c;
     }
     
     function div(uint64 a, uint64 b) internal pure returns (uint64) {
      
     uint64 c = a / b;
      
     return c;
     }
     
     function sub(uint64 a, uint64 b) internal pure returns (uint64) {
     assert(b <= a);
     uint64 c = a - b;
     return c;
     }
     
     function add(uint64 a, uint64 b) internal pure returns (uint64) {
     uint64 c = a + b;
     assert(c >= a);
     return c;
     }
}